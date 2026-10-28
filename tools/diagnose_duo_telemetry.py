#!/usr/bin/env python3
"""One bounded, raw-output Duo telemetry probe. It does not build or test the app."""
import concurrent.futures
import hashlib
import json
import os
from pathlib import Path
import pty
import selectors
import signal
import subprocess
import sys
import time


class Recorder:
    def __init__(self, out, budget=360):
        self.out = Path(out)
        self.out.mkdir(parents=True, exist_ok=True)
        self.deadline = time.monotonic() + budget
        self.records = []

    def run(self, label, command, timeout=15, terminal=False):
        started = time.monotonic()
        limit = max(0, min(timeout, self.deadline - started))
        record = {"label": label, "command": command, "terminal": terminal,
                  "timeoutSeconds": limit, "timedOut": False, "returnCode": None}
        process = None
        reader = writer = None
        try:
            if limit <= 0:
                raise RuntimeError("Diagnostic time budget exhausted")
            with (self.out / (label + '.stdout')).open('wb') as output, \
                 (self.out / (label + '.stderr')).open('wb') as error:
                if terminal:
                    reader, writer = pty.openpty()
                process = subprocess.Popen(command, stdout=writer if terminal else subprocess.PIPE,
                                           stderr=error, start_new_session=True)
                if terminal:
                    os.close(writer)
                    writer = None
                else:
                    reader = process.stdout.fileno()
                end = started + limit
                with selectors.DefaultSelector() as selector:
                    selector.register(reader, selectors.EVENT_READ)
                    while time.monotonic() < end:
                        ready = selector.select(max(0, min(0.1, end - time.monotonic())))
                        if ready:
                            try:
                                chunk = os.read(reader, 65536)
                            except OSError:  # A closed PTY reports EIO on macOS/Linux.
                                break
                            if not chunk:
                                break
                            output.write(chunk)
                            output.flush()
                        elif process.poll() is not None:
                            break
                if process.poll() is None:
                    record['timedOut'] = True
                    os.killpg(process.pid, signal.SIGKILL)
                record['returnCode'] = process.wait(timeout=5)
        except Exception as error:
            record['error'] = str(error)
            if process is not None and process.poll() is None:
                os.killpg(process.pid, signal.SIGKILL)
                record['returnCode'] = process.wait(timeout=5)
        finally:
            if writer is not None:
                os.close(writer)
            if terminal and reader is not None:
                os.close(reader)
            elif process is not None and process.stdout is not None:
                process.stdout.close()
            record['durationSeconds'] = round(time.monotonic() - started, 3)
            (self.out / (label + '.json')).write_text(json.dumps(record, indent=2) + '\n')
            self.records.append(record)
        return record


def main():
    recorder = Recorder('evidence/telemetry')
    device = None
    try:
        tracked = subprocess.check_output(['git', 'ls-files', '-z', '--',
            'tools/duoctl', 'tools/diagnose_duo_telemetry.py',
            '.github/workflows/duo-telemetry-diagnostic.yml']).decode().split('\0')
        source = {
            'commit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip(),
            'files': {p: hashlib.sha256(Path(p).read_bytes()).hexdigest() for p in tracked if p},
            'scope': 'Simulator telemetry diagnostic only. No app build, app validation, physical BLE test, or verified fold claim.',
        }
        (recorder.out / 'source.json').write_text(json.dumps(source, indent=2) + '\n')
        for label, command in [
            ('xcode-version', ['xcodebuild', '-version']),
            ('simctl-help', ['xcrun', 'simctl', 'help']),
            ('motion-help', ['xcrun', 'devicectl', 'device', 'motion', '--help']),
            ('hinge-help', ['xcrun', 'devicectl', 'device', 'motion', 'hinge-angle', '--help']),
        ]:
            recorder.run(label, command)
        result = recorder.run('devices', ['xcrun', 'simctl', 'list', 'devices', 'available', '-j'])
        if result['returnCode'] != 0:
            raise RuntimeError('Cannot enumerate the installed simulator; inspect devices logs')
        data = json.loads((recorder.out / 'devices.stdout').read_text())
        candidates = [d for runtime, devices in data['devices'].items() if runtime.endswith('iOS-27-1')
                      for d in devices if d['name'] == 'iPhone Duo' and d['isAvailable']]
        if len(candidates) != 1:
            raise RuntimeError('Expected exactly one available iOS 27.1 iPhone Duo')
        device = candidates[0]['udid']
        if candidates[0]['state'] != 'Booted':
            if recorder.run('boot', ['xcrun', 'simctl', 'boot', device], timeout=150)['returnCode'] != 0:
                raise RuntimeError('Duo boot failed or timed out; inspect boot logs')
        if recorder.run('bootstatus', ['xcrun', 'simctl', 'bootstatus', device, '-b'], timeout=60)['returnCode'] != 0:
            raise RuntimeError('Duo boot readiness failed; inspect bootstatus logs')
        # Compile the existing helper before the 15-second observation windows.
        # This is the helper's unchanged build path, not an app build.
        compile_helper = "import runpy; m=runpy.run_path('tools/duoctl/duoctl'); print(m['helper_path']())"
        if recorder.run('helper-build', [sys.executable, '-c', compile_helper], timeout=65)['returnCode'] != 0:
            raise RuntimeError('Existing Duo helper could not be prepared')
        helper_path = Path((recorder.out / 'helper-build.stdout').read_text().strip())
        (recorder.out / 'helper-binary-sha256.txt').write_text(hashlib.sha256(helper_path.read_bytes()).hexdigest() + '\n')
        helper = [sys.executable, 'tools/duoctl/duoctl', '-d', device]
        recorder.run('initial-state', helper + ['state'], timeout=30)
        hinge = ['xcrun', 'devicectl', 'device', 'motion', 'hinge-angle', '-d', device]
        for posture in ('close', 'open', 'half'):
            # Both observers start before the same action: distinguish output
            # buffering from event-only streams without changing the command.
            with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
                piped = pool.submit(recorder.run, posture + '-pipe', hinge, 15, False)
                terminal = pool.submit(recorder.run, posture + '-pty', hinge, 15, True)
                time.sleep(1)
                recorder.run(posture + '-action', helper + [posture], timeout=30)
                piped.result()
                terminal.result()
        recorder.run('final-displays', ['xcrun', 'devicectl', 'device', 'info', 'displays',
                                       '-d', device, '--json-output', '-'])
    except Exception as error:
        (recorder.out / 'diagnostic-error.txt').write_text(str(error) + '\n')
        raise
    finally:
        (recorder.out / 'commands.json').write_text(json.dumps(recorder.records, indent=2) + '\n')
        if device:
            Path('evidence/duo-device.txt').write_text(device + '\n')


if __name__ == '__main__':
    main()
