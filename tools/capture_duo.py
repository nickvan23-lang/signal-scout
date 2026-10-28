#!/usr/bin/env python3
"""Capture Duo displays with bounded commands and independently checked poses."""

import argparse
import json
import math
import os
import re
import subprocess
import time
import uuid
from pathlib import Path


READINESS_TIMEOUT = 60
STATE_TIMEOUT = 30
HELPER = Path(__file__).parent / "duoctl" / "duoctl"
TELEMETRY_TIMEOUT = 10
MAX_OBSERVATION_AGE = 5
ANGLE_NUMERICAL_SLACK = 0.001


def run(args, timeout=60):
    try:
        result = subprocess.run(args, capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired as error:
        raise RuntimeError(f"{args}: timed out after {timeout:g}s") from error
    if result.returncode:
        raise RuntimeError(str(args) + ": " + result.stderr[-2000:] + result.stdout[-2000:])
    return result.stdout


def read_state(device, timeout=STATE_TIMEOUT):
    return json.loads(run(helper_command(device, "state"), timeout=timeout))


def helper_command(device, *arguments):
    return ["python3", str(HELPER), "-d", device, "--display-only", *arguments]


class SnapshotRejected(RuntimeError):
    pass


def finite_number(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value)


def validate_snapshot(snapshot, *, session_id, request_id, process_id, after_sequence,
                      issued_at, received_at):
    if not isinstance(snapshot, dict):
        raise SnapshotRejected("Snapshot is not an object")
    if type(snapshot.get("schemaVersion")) is not int or snapshot["schemaVersion"] != 1:
        raise SnapshotRejected("Unsupported snapshot schema")
    if snapshot.get("sessionID") != session_id or snapshot.get("requestID") != request_id:
        raise SnapshotRejected("Snapshot belongs to another session or request")
    sequence = snapshot.get("eventSequence")
    if type(sequence) is not int or sequence <= 0 or sequence <= after_sequence:
        raise SnapshotRejected("Snapshot has no new callback event")
    if type(snapshot.get("processID")) is not int or snapshot["processID"] != process_id:
        raise SnapshotRejected("Snapshot belongs to another app process")
    if not isinstance(snapshot.get("sceneID"), str) or not snapshot["sceneID"].strip():
        raise SnapshotRejected("Snapshot has no scene identity")
    if snapshot.get("sceneState") != "foregroundActive":
        raise SnapshotRejected("Observed scene is not foreground active")
    if snapshot.get("available") is not True:
        raise SnapshotRejected("App reports hinge telemetry unavailable")
    if snapshot.get("status") not in ("closed", "partiallyOpen", "fullyOpen"):
        raise SnapshotRejected("App reports an unknown hinge status")
    angle = snapshot.get("angleDegrees")
    if not finite_number(angle) or not -ANGLE_NUMERICAL_SLACK <= angle <= 180 + ANGLE_NUMERICAL_SLACK:
        raise SnapshotRejected("App callback has no valid hinge angle")
    observed_at = snapshot.get("observedAtUnixSeconds")
    if not finite_number(observed_at) or observed_at <= 0:
        raise SnapshotRejected("Snapshot has no actual callback timestamp")
    if observed_at < issued_at:
        raise SnapshotRejected("Callback predates the current request")
    if observed_at > received_at:
        raise SnapshotRejected("Callback timestamp is in the future")
    if received_at - observed_at > MAX_OBSERVATION_AGE:
        raise SnapshotRejected("Callback observation is stale")


def atomic_json(path, payload):
    temporary = path.with_name(f".{path.name}.{uuid.uuid4().hex}.tmp")
    try:
        temporary.write_text(json.dumps(payload) + "\n")
        temporary.replace(path)
    finally:
        temporary.unlink(missing_ok=True)


class AppTelemetry:
    def __init__(self, container, session_id, process_id, evidence):
        self.directory = Path(container) / "Library" / "Caches" / "SignalScout-Duo"
        self.directory.mkdir(parents=True, exist_ok=True)
        self.session_id = session_id
        self.process_id = process_id
        self.evidence = Path(evidence) / "telemetry"
        self.evidence.mkdir()
        self.last_sequence = 0

    def read(self, label, timeout=TELEMETRY_TIMEOUT):
        os.kill(self.process_id, 0)
        request = {"sessionID": self.session_id, "requestID": str(uuid.uuid4())}
        evidence = self.evidence / label
        evidence.mkdir()
        issued_at = time.time()
        atomic_json(self.directory / "request.json", request)
        atomic_json(evidence / "request.json", request)
        receipt = {"requestIssuedAtUnixSeconds": issued_at, "previousEventSequence": self.last_sequence,
                   "expectedProcessID": self.process_id, "accepted": False}
        atomic_json(evidence / "receipt.json", receipt)
        deadline = time.monotonic() + timeout
        last_reason = "No snapshot received"
        previous_bytes = None
        observed_files = 0
        while time.monotonic() < deadline:
            os.kill(self.process_id, 0)
            try:
                raw = (self.directory / "snapshot.json").read_bytes()
                received_at = time.time()
                if raw != previous_bytes:
                    observed_files += 1
                    (evidence / f"observed-{observed_files:03}.json").write_bytes(raw)
                    previous_bytes = raw
                snapshot = json.loads(raw)
                validate_snapshot(snapshot, session_id=self.session_id, request_id=request["requestID"],
                                  process_id=self.process_id, after_sequence=self.last_sequence,
                                  issued_at=issued_at, received_at=received_at)
            except (FileNotFoundError, json.JSONDecodeError, UnicodeDecodeError, SnapshotRejected) as error:
                last_reason = str(error)
            else:
                os.kill(self.process_id, 0)
                self.last_sequence = snapshot["eventSequence"]
                (evidence / "snapshot.json").write_bytes(raw)
                receipt.update({"accepted": True, "receivedAtUnixSeconds": received_at,
                                "eventSequence": self.last_sequence,
                                "observedAtUnixSeconds": snapshot["observedAtUnixSeconds"]})
                atomic_json(evidence / "receipt.json", receipt)
                return snapshot
            time.sleep(max(0, min(0.1, deadline - time.monotonic())))
        receipt["lastRejection"] = last_reason
        atomic_json(evidence / "receipt.json", receipt)
        raise RuntimeError(f"{label}: no fresh app hinge callback within {timeout:g}s: {last_reason}")


def wait_for_display(device):
    deadline = time.monotonic() + READINESS_TIMEOUT
    last_error = None
    while True:
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            if last_error is not None:
                raise last_error
            raise RuntimeError(f"No active display within {READINESS_TIMEOUT}s")
        try:
            return read_state(device, timeout=min(STATE_TIMEOUT, remaining))
        except (RuntimeError, json.JSONDecodeError) as error:
            last_error = error
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise
            time.sleep(min(5, remaining))


def verify_pose(state, screen, orientation, degrees, snapshot):
    if state.get("activeScreen") != screen or state.get("orientation") != orientation:
        raise RuntimeError("Pose readback mismatch " + str(state))
    angle = snapshot.get("angleDegrees")
    if not finite_number(angle):
        raise RuntimeError("Hinge telemetry unavailable; the requested pose is unverified")
    if abs(angle - degrees) > 1:
        raise RuntimeError(f"Hinge readback mismatch: requested {degrees}, observed {angle}")
    expected_status = {0: "closed", 90: "partiallyOpen", 180: "fullyOpen"}[degrees]
    if snapshot.get("status") != expected_status:
        raise RuntimeError(f"Hinge status mismatch: requested {expected_status}, observed {snapshot.get('status')}")


def verify_screenshot_interval(before_state, after_state, before_snapshot, after_snapshot):
    if before_snapshot["sceneID"] != after_snapshot["sceneID"]:
        raise RuntimeError("Foreground scene changed during the screenshot interval")
    for key in ("displayId", "displayUUID"):
        if before_state.get(key) != after_state.get(key):
            raise RuntimeError(f"Active {key} changed during the screenshot interval")


def main(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("--device", required=True)
    parser.add_argument("--bundle", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--landscape-only", action="store_true")
    args = parser.parse_args(argv)
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=False)
    records = []
    stage = "launch"
    telemetry = None
    session_id = str(uuid.uuid4())

    try:
        launch_help = run(["xcrun", "simctl", "help", "launch"], timeout=15)
        (out / "simctl-launch-help.txt").write_text(launch_help)
        if "--terminate-running-process" not in launch_help:
            raise RuntimeError("simctl does not advertise launch with a fresh process")
        launch = run(["xcrun", "simctl", "launch", "--terminate-running-process",
                      args.device, args.bundle, "--duo-telemetry-session", session_id])
        match = re.search(r": (\d+)\s*$", launch)
        if not match:
            raise RuntimeError("Cannot verify app PID: " + launch)
        pid = int(match.group(1))
        if pid <= 0:
            raise RuntimeError("Invalid launched app PID")
        stage = "telemetry-container"
        container_help = run(["xcrun", "simctl", "help", "get_app_container"], timeout=15)
        (out / "simctl-container-help.txt").write_text(container_help)
        container = Path(run(["xcrun", "simctl", "get_app_container", args.device, args.bundle, "data"], timeout=15).strip())
        if not container.is_absolute() or not container.is_dir():
            raise RuntimeError("simctl did not return an existing absolute app data container")
        telemetry = AppTelemetry(container, session_id, pid, out)
        atomic_json(out / "session.json", {"sessionID": session_id, "processID": pid, "bundle": args.bundle})
        stage = "display-readiness"
        wait_for_display(args.device)

        poses = [
            ("cover-portrait", "close", "portrait", "cover", 0),
            ("inner-landscape", "open", "landscape", "inner", 180),
            ("inner-portrait", "open", "portrait", "inner", 180),
            ("book-landscape", "half", "landscape", "inner", 90),
            ("cover-return", "close", "portrait", "cover", 0),
        ]
        if args.landscape_only:
            poses = [
                ("cover-landscape", "close", "landscape", "cover", 0),
                ("inner-landscape", "open", "landscape", "inner", 180),
                ("book-landscape", "half", "landscape", "inner", 90),
                ("cover-return", "close", "landscape", "cover", 0),
            ]

        for name, pose, orientation, screen, degrees in poses:
            stage = name
            run(helper_command(args.device, pose), timeout=90)
            try:
                state = json.loads(run(helper_command(args.device, "rotate", orientation), timeout=90))
            except RuntimeError:
                if not args.landscape_only:
                    raise
                orientation = "landscape-flipped"
                state = json.loads(run(helper_command(args.device, "rotate", orientation), timeout=90))
            before = telemetry.read(name + "-before")
            verify_pose(state, screen, orientation, degrees, before)
            os.kill(pid, 0)
            time.sleep(2)
            image = out / (name + ".jpg")
            run([
                "xcrun", "simctl", "io", args.device, "screenshot", "--type=jpeg",
                "--display=" + str(state["displayId"]), str(image),
            ])
            os.kill(pid, 0)
            after_state = read_state(args.device)
            after = telemetry.read(name + "-after")
            verify_pose(after_state, screen, orientation, degrees, after)
            verify_screenshot_interval(state, after_state, before, after)
            sizes = run(["sips", "-g", "pixelWidth", "-g", "pixelHeight", str(image)])
            width = int(re.search(r"pixelWidth: (\d+)", sizes).group(1))
            height = int(re.search(r"pixelHeight: (\d+)", sizes).group(1))
            expected = (1398, 2034) if screen == "cover" else (2007, 2853)
            if sorted([width, height]) != sorted(expected):
                raise RuntimeError("Unexpected screenshot dimensions " + str((width, height)))
            records.append({
                "name": name, "state": state, "processId": pid,
                "launchPIDAlive": True, "screenshot": image.name,
                "width": width, "height": height,
                "stateAfterScreenshot": after_state,
                "hingeBeforeScreenshot": before, "hingeAfterScreenshot": after,
                "rawSnapshots": [f"telemetry/{name}-before/snapshot.json", f"telemetry/{name}-after/snapshot.json"],
                "renderedScreenshotOrientationVerified": False,
            })
            (out / "poses.json").write_text(json.dumps({
                "bundle": args.bundle, "sessionID": session_id, "poses": records, "complete": False,
            }, indent=2) + "\n")

        (out / "poses.json").write_text(json.dumps({
            "bundle": args.bundle, "sessionID": session_id, "poses": records, "complete": True,
            "scope": "Verified fresh app hinge callbacks matched to unique requests before and after each screenshot, "
                     "simulator display readback, panel pixel dimensions, and the launched live app PID. Rendered screenshot orientation, visual layout, task behavior, "
                     "and physical BLE operation require separate review.",
        }, indent=2) + "\n")
    except Exception as error:
        # Persist the primary failure before diagnostics, which may also fail.
        (out / "failure.json").write_text(json.dumps({
            "error": str(error), "stage": stage, "completedPoses": len(records),
        }, indent=2) + "\n")
        if telemetry is not None:
            try:
                telemetry.read("failure-diagnostic", timeout=3)
            except Exception as telemetry_error:
                (out / "telemetry-diagnostic-error.txt").write_text(str(telemetry_error))
        try:
            diagnostic = read_state(args.device)
            (out / "failure-state.json").write_text(json.dumps(diagnostic, indent=2) + "\n")
            run([
                "xcrun", "simctl", "io", args.device, "screenshot", "--type=jpeg",
                "--display=" + str(diagnostic["displayId"]), str(out / "failure.jpg"),
            ], timeout=15)
        except Exception as diagnostic_error:
            (out / "diagnostic-error.txt").write_text(str(diagnostic_error))
        raise


if __name__ == "__main__":
    main()
