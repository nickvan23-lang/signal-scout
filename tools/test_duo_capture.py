#!/usr/bin/env python3
"""Portable regression checks for Duo capture timeouts and evidence handling.

These use short-lived local subprocesses or mocked simulator responses; they do
not validate iOS layouts, simulator compatibility, or Bluetooth operation.
"""

import importlib.machinery
import importlib.util
import json
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path
from unittest.mock import patch


ROOT = Path(__file__).resolve().parent


def load_module(name, path):
    loader = importlib.machinery.SourceFileLoader(name, str(path))
    spec = importlib.util.spec_from_loader(name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


duo = load_module("duoctl_tested", ROOT / "duoctl" / "duoctl")
capture = load_module("duo_capture_tested", ROOT / "capture_duo.py")


def snapshot(**changes):
    result = {"schemaVersion": 1, "sessionID": "session", "requestID": "request",
              "eventSequence": 6, "observedAtUnixSeconds": 100.1, "processID": 123,
              "sceneID": "scene", "sceneState": "foregroundActive", "available": True,
              "angleDegrees": 90, "status": "partiallyOpen"}
    result.update(changes)
    return result


class HingeStreamTests(unittest.TestCase):
    def read_stream(self, code, timeout=0.15):
        children = []
        original_popen = subprocess.Popen

        def popen(_args, **kwargs):
            process = original_popen([sys.executable, "-c", code], **kwargs)
            children.append(process)
            return process

        started = time.monotonic()
        try:
            with patch.object(duo.subprocess, "Popen", side_effect=popen):
                result = duo.hinge_angle("test-device", timeout=timeout)
        finally:
            self.assertLess(time.monotonic() - started, 2, "silent telemetry exceeded the deadline")
            self.assertEqual(len(children), 1)
            self.assertIsNotNone(children[0].poll(), "motion-stream process was leaked")
            self.assertTrue(children[0].stdout.closed)
        return result

    def test_silent_stream_is_bounded_and_reaped(self):
        self.assertIsNone(self.read_stream("import time; time.sleep(30)"))

    def test_partial_line_does_not_block_or_become_false_readback(self):
        self.assertIsNone(self.read_stream(
            "import sys,time; sys.stdout.write('Angle: 1'); sys.stdout.flush(); time.sleep(30)"
        ))

    def test_valid_angle_returns_without_waiting_for_stream_exit(self):
        self.assertEqual(self.read_stream(
            "import time; print('Angle: 180.0 degrees', flush=True); time.sleep(30)"
        ), 180)

    def test_comma_decimal_telemetry(self):
        self.assertEqual(self.read_stream("print('Angle: 90,25')"), 90.25)

    def test_final_line_without_newline_at_eof(self):
        self.assertEqual(self.read_stream("print('Angle: 0', end='')"), 0)

    def test_unsupported_native_command_preserves_exit_and_stderr(self):
        with self.assertRaisesRegex(duo.DuoError, "status 64:[\\s\\S]*Unknown option '-d'"):
            self.read_stream(
                "import sys; print(\"Error: Unknown option '-d'\",file=sys.stderr); sys.exit(64)"
            )

    def test_nonzero_exit_after_eof_is_not_null_telemetry(self):
        with self.assertRaisesRegex(duo.DuoError, "status 64:[\\s\\S]*unsupported command"):
            self.read_stream(
                "import os,sys,time; print('unsupported command',file=sys.stderr,flush=True); "
                "os.close(1); os.close(2); time.sleep(0.04); sys.exit(64)", timeout=0.5
            )

    def test_nonzero_exit_without_output_is_reported(self):
        with self.assertRaisesRegex(duo.DuoError, "status 2.*no diagnostic output"):
            self.read_stream("import sys; sys.exit(2)")

    def test_helper_command_timeout_has_actionable_error(self):
        with self.assertRaisesRegex(duo.DuoError, "timed out after"):
            duo.run([sys.executable, "-c", "import time; time.sleep(30)"], timeout=0.05)


class CaptureEvidenceTests(unittest.TestCase):
    def test_capture_command_timeout_is_normalized(self):
        with self.assertRaisesRegex(RuntimeError, "timed out after"):
            capture.run([sys.executable, "-c", "import time; time.sleep(30)"], timeout=0.05)

    def test_readiness_recovers_after_display_handoff(self):
        ready = {"activeScreen": "inner"}
        with patch.object(capture, "read_state", side_effect=[RuntimeError("no display"), ready]), \
             patch.object(capture.time, "sleep"):
            self.assertEqual(capture.wait_for_display("test-device"), ready)

    def test_readiness_uses_one_overall_deadline(self):
        with patch.object(capture, "read_state", side_effect=RuntimeError("state timed out")), \
             patch.object(capture.time, "monotonic", side_effect=[0, 0, 61]):
            with self.assertRaisesRegex(RuntimeError, "state timed out"):
                capture.wait_for_display("test-device")

    def test_readiness_deadline_preserves_native_error_after_retry_sleep(self):
        native_error = RuntimeError("hinge telemetry command exited with status 64: Unknown option '-d'")
        with patch.object(capture, "read_state", side_effect=native_error), \
             patch.object(capture.time, "monotonic", side_effect=[0, 0, 10, 60]), \
             patch.object(capture.time, "sleep"):
            with self.assertRaisesRegex(RuntimeError, "status 64: Unknown option '-d'"):
                capture.wait_for_display("test-device")

    def test_missing_wrong_or_nonfinite_hinge_is_not_verified(self):
        for angle in (None, 0, 180, float("nan"), float("inf")):
            with self.subTest(angle=angle):
                state = {"activeScreen": "inner", "orientation": "landscape"}
                with self.assertRaises(RuntimeError):
                    capture.verify_pose(state, "inner", "landscape", 90, snapshot(angleDegrees=angle))
        capture.verify_pose({
            "activeScreen": "inner", "orientation": "landscape",
        }, "inner", "landscape", 90, snapshot(angleDegrees=90.2))

    def test_launch_failure_is_saved_even_when_diagnostics_fail(self):
        with tempfile.TemporaryDirectory() as temp:
            out = Path(temp) / "poses"
            with patch.object(capture, "run", side_effect=RuntimeError("launch timed out")), \
                 patch.object(capture, "read_state", side_effect=RuntimeError("diagnostics timed out")):
                with self.assertRaisesRegex(RuntimeError, "launch timed out"):
                    capture.main(["--device", "test", "--bundle", "app.test", "--out", str(out)])
            failure = json.loads((out / "failure.json").read_text())
            self.assertEqual(failure["stage"], "launch")
            self.assertEqual(failure["completedPoses"], 0)
            self.assertEqual(failure["error"], "launch timed out")
            self.assertTrue((out / "diagnostic-error.txt").is_file())
            self.assertFalse((out / "poses.json").exists())

    def test_readiness_failure_is_saved_before_first_pose(self):
        with tempfile.TemporaryDirectory() as temp:
            out = Path(temp) / "poses"
            def launch_only(args, timeout=60):
                if args[:3] == ["xcrun", "simctl", "help"]:
                    return "--terminate-running-process data"
                if args[:3] == ["xcrun", "simctl", "get_app_container"]:
                    return temp
                return "app.test: 123\n"
            with patch.object(capture, "run", side_effect=launch_only), \
                 patch.object(capture, "AppTelemetry"), \
                 patch.object(capture, "wait_for_display", side_effect=RuntimeError("no active display")), \
                 patch.object(capture, "read_state", side_effect=RuntimeError("no diagnostic display")):
                with self.assertRaisesRegex(RuntimeError, "no active display"):
                    capture.main(["--device", "test", "--bundle", "app.test", "--out", str(out)])
            failure = json.loads((out / "failure.json").read_text())
            self.assertEqual(failure["stage"], "display-readiness")
            self.assertEqual(failure["completedPoses"], 0)

    def test_successful_capture_records_all_verified_poses(self):
        current = {"activeScreen": "cover", "orientation": "portrait", "displayId": 1}
        angle = 0
        sequence = 0
        launch_session = None

        def fake_run(args, timeout=60):
            nonlocal angle, launch_session
            if args[:3] == ["xcrun", "simctl", "help"]:
                return "--terminate-running-process data"
            if args[:3] == ["xcrun", "simctl", "launch"]:
                self.assertIn("--terminate-running-process", args)
                launch_session = args[args.index("--duo-telemetry-session") + 1]
                return "app.test: 123\n"
            if args[:3] == ["xcrun", "simctl", "get_app_container"]:
                return str(container)
            if args[0] == "python3":
                self.assertIn("--display-only", args)
                action = args[5]
                if action in ("open", "close", "half"):
                    current["activeScreen"] = "cover" if action == "close" else "inner"
                    angle = {"close": 0, "open": 180, "half": 90}[action]
                elif action == "rotate":
                    current["orientation"] = args[6]
                return json.dumps(current)
            if args[:3] == ["xcrun", "simctl", "io"]:
                Path(args[-1]).write_bytes(b"mock-screenshot")
                return ""
            if args[0] == "sips":
                width, height = (1398, 2034) if current["activeScreen"] == "cover" else (2007, 2853)
                return f"pixelWidth: {width}\npixelHeight: {height}\n"
            raise AssertionError(f"Unexpected command {args}")

        with tempfile.TemporaryDirectory() as temp:
            out = Path(temp) / "poses"
            container = Path(temp) / "app-data"
            container.mkdir()
            cache = container / "Library" / "Caches" / "SignalScout-Duo"
            real_atomic_json = capture.atomic_json

            def respond_to_request(path, payload):
                nonlocal sequence
                real_atomic_json(path, payload)
                if path == cache / "request.json":
                    sequence += 1
                    self.assertEqual(payload["sessionID"], launch_session)
                    response = snapshot(sessionID=payload["sessionID"], requestID=payload["requestID"],
                                        eventSequence=sequence, observedAtUnixSeconds=time.time(),
                                        angleDegrees=angle, status={0: "closed", 90: "partiallyOpen", 180: "fullyOpen"}[angle])
                    (cache / "snapshot.json").write_text(json.dumps(response))

            with patch.object(capture, "run", side_effect=fake_run), \
                 patch.object(capture, "atomic_json", side_effect=respond_to_request), \
                 patch.object(capture, "wait_for_display"), \
                 patch.object(capture.os, "kill"), patch.object(capture.time, "sleep"):
                capture.main(["--device", "test", "--bundle", "app.test", "--out", str(out)])
            result = json.loads((out / "poses.json").read_text())
            self.assertTrue(result["complete"])
            self.assertEqual(len(result["poses"]), 5)
            self.assertEqual([p["hingeBeforeScreenshot"]["angleDegrees"] for p in result["poses"]], [0, 180, 180, 90, 0])
            self.assertEqual(sequence, 10)
            requests = [json.loads(p.read_text())["requestID"] for p in (out / "telemetry").glob("*/request.json")]
            self.assertEqual(len(set(requests)), 10)
            self.assertEqual(len(list((out / "telemetry").glob("*/snapshot.json"))), 10)
            self.assertFalse((out / "failure.json").exists())


class DisplayOnlyTests(unittest.TestCase):
    def test_display_only_state_does_not_call_rejected_hinge_cli(self):
        display = {"bounds": [[0, 0], [1398, 2034]], "pointScale": 3,
                   "currentOrientation": "rot0", "primary": True,
                   "displayId": 1, "uniqueId": "display"}
        with patch.object(duo, "active_display", return_value=display), \
             patch.object(duo, "hinge_angle", side_effect=duo.DuoError("unsupported")) as hinge:
            state = duo.state("test", include_hinge=False)
            self.assertEqual(state["activeScreen"], "cover")
            self.assertNotIn("hingeAngle", state)
            hinge.assert_not_called()
            with self.assertRaisesRegex(duo.DuoError, "unsupported"):
                duo.state("test")


class AppSnapshotTests(unittest.TestCase):
    def check(self, data, **changes):
        context = {"session_id": "session", "request_id": "request", "process_id": 123,
                   "after_sequence": 5, "issued_at": 100, "received_at": 100.2}
        context.update(changes)
        capture.validate_snapshot(data, **context)

    def test_matching_actual_callback_is_accepted(self):
        self.check(snapshot())

    def test_tiny_radian_conversion_roundoff_is_preserved_at_boundaries(self):
        for angle, degrees, status in ((-0.00001, 0, "closed"), (180.00001, 180, "fullyOpen")):
            with self.subTest(angle=angle):
                data = snapshot(angleDegrees=angle, status=status)
                self.check(data)
                capture.verify_pose({"activeScreen": "inner", "orientation": "landscape"},
                                    "inner", "landscape", degrees, data)
                self.assertEqual(data["angleDegrees"], angle)

    def test_stale_session_request_and_process_are_rejected(self):
        for changes in ({"sessionID": "old-session"}, {"requestID": "old-request"}, {"processID": 456}):
            with self.subTest(changes=changes), self.assertRaises(capture.SnapshotRejected):
                self.check(snapshot(**changes))

    def test_boolean_and_wrong_numeric_types_are_rejected(self):
        cases = [{"schemaVersion": True}, {"schemaVersion": 2}, {"eventSequence": True},
                 {"eventSequence": 6.0}, {"processID": True}, {"processID": 123.0},
                 {"angleDegrees": True}, {"observedAtUnixSeconds": True}, {"available": 1}]
        for changes in cases:
            with self.subTest(changes=changes), self.assertRaises(capture.SnapshotRejected):
                self.check(snapshot(**changes))

    def test_nil_error_inactive_and_nonfinite_snapshots_are_rejected(self):
        cases = [{"available": False, "angleDegrees": None, "status": None},
                 {"status": "error"}, {"sceneID": ""}, {"sceneState": "background"},
                 {"angleDegrees": None}, {"angleDegrees": float("nan")},
                 {"angleDegrees": float("inf")}, {"angleDegrees": 181},
                 {"observedAtUnixSeconds": float("nan")}]
        for changes in cases:
            with self.subTest(changes=changes), self.assertRaises(capture.SnapshotRejected):
                self.check(snapshot(**changes))

    def test_callback_sequence_must_advance(self):
        for sequence in (0, 4, 5):
            with self.subTest(sequence=sequence), self.assertRaises(capture.SnapshotRejected):
                self.check(snapshot(eventSequence=sequence))

    def test_actual_callback_time_cannot_be_replaced_by_new_file_timestamp(self):
        for observed in (99.99, 100.201, None):
            with self.subTest(observed=observed), self.assertRaises(capture.SnapshotRejected):
                self.check(snapshot(observedAtUnixSeconds=observed))
        with self.assertRaisesRegex(capture.SnapshotRejected, "stale"):
            self.check(snapshot(observedAtUnixSeconds=95.1), issued_at=95, received_at=101)

    def test_matching_angle_with_wrong_hinge_status_is_rejected(self):
        with self.assertRaisesRegex(RuntimeError, "status mismatch"):
            capture.verify_pose({"activeScreen": "inner", "orientation": "landscape"},
                                "inner", "landscape", 90, snapshot(status="fullyOpen"))

    def test_scene_and_display_must_remain_same_during_screenshot(self):
        before_state = {"displayId": 1, "displayUUID": "display-a"}
        capture.verify_screenshot_interval(before_state, dict(before_state), snapshot(), snapshot())
        for state, data in (({"displayId": 2, "displayUUID": "display-a"}, snapshot()),
                            ({"displayId": 1, "displayUUID": "display-b"}, snapshot()),
                            (dict(before_state), snapshot(sceneID="other-scene"))):
            with self.subTest(state=state, scene=data["sceneID"]), self.assertRaises(RuntimeError):
                capture.verify_screenshot_interval(before_state, state, snapshot(), data)

    def test_cached_snapshot_cannot_satisfy_a_new_request(self):
        with tempfile.TemporaryDirectory() as temp:
            client = capture.AppTelemetry(Path(temp) / "container", "session", 123, Path(temp))
            raw = json.dumps(snapshot()).encode()
            (client.directory / "snapshot.json").write_bytes(raw)
            with patch.object(capture.os, "kill"), self.assertRaisesRegex(RuntimeError, "another session or request"):
                client.read("cached", timeout=0.02)
            evidence = client.evidence / "cached"
            self.assertEqual((evidence / "observed-001.json").read_bytes(), raw)
            self.assertFalse((evidence / "snapshot.json").exists())
            self.assertFalse(json.loads((evidence / "receipt.json").read_text())["accepted"])

    def test_matching_request_still_requires_a_new_actual_event(self):
        with tempfile.TemporaryDirectory() as temp:
            client = capture.AppTelemetry(Path(temp) / "container", "session", 123, Path(temp))
            client.last_sequence = 6
            event_sequence = 6
            original_atomic = capture.atomic_json

            def observer(path, request):
                original_atomic(path, request)
                if path == client.directory / "request.json":
                    response = snapshot(sessionID=request["sessionID"], requestID=request["requestID"],
                                        eventSequence=event_sequence, observedAtUnixSeconds=time.time())
                    (client.directory / "snapshot.json").write_text(json.dumps(response))

            with patch.object(capture, "atomic_json", side_effect=observer), \
                 patch.object(capture.os, "kill"):
                with self.assertRaisesRegex(RuntimeError, "no new callback event"):
                    client.read("unchanged-sequence", timeout=0.02)
                event_sequence = 7
                accepted = client.read("fresh-callback", timeout=0.2)
            self.assertEqual(accepted["eventSequence"], 7)
            self.assertEqual(client.last_sequence, 7)
            request_a = json.loads((client.evidence / "unchanged-sequence/request.json").read_text())
            request_b = json.loads((client.evidence / "fresh-callback/request.json").read_text())
            self.assertNotEqual(request_a["requestID"], request_b["requestID"])

    def test_dead_process_cannot_supply_telemetry(self):
        with tempfile.TemporaryDirectory() as temp:
            client = capture.AppTelemetry(Path(temp) / "container", "session", 123, Path(temp))
            with patch.object(capture.os, "kill", side_effect=ProcessLookupError()), self.assertRaises(ProcessLookupError):
                client.read("dead", timeout=0.02)
            self.assertFalse((client.directory / "request.json").exists())


if __name__ == "__main__":
    unittest.main(verbosity=2)
