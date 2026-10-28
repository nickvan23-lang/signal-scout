#!/usr/bin/env python3
"""Capture Duo displays with bounded commands and independently checked poses."""

import argparse
import json
import math
import os
import re
import subprocess
import time
from pathlib import Path


READINESS_TIMEOUT = 60
STATE_TIMEOUT = 30
HELPER = Path(__file__).parent / "duoctl" / "duoctl"


def run(args, timeout=60):
    try:
        result = subprocess.run(args, capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired as error:
        raise RuntimeError(f"{args}: timed out after {timeout:g}s") from error
    if result.returncode:
        raise RuntimeError(str(args) + ": " + result.stderr[-2000:] + result.stdout[-2000:])
    return result.stdout


def read_state(device, timeout=STATE_TIMEOUT):
    return json.loads(run(["python3", str(HELPER), "-d", device, "state"], timeout=timeout))


def wait_for_display(device):
    deadline = time.monotonic() + READINESS_TIMEOUT
    while True:
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise RuntimeError(f"No active display within {READINESS_TIMEOUT}s")
        try:
            return read_state(device, timeout=min(STATE_TIMEOUT, remaining))
        except (RuntimeError, json.JSONDecodeError):
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise
            time.sleep(min(5, remaining))


def verify_pose(state, screen, orientation, degrees):
    if state.get("activeScreen") != screen or state.get("orientation") != orientation:
        raise RuntimeError("Pose readback mismatch " + str(state))
    angle = state.get("hingeAngle")
    if not isinstance(angle, (int, float)) or not math.isfinite(angle):
        raise RuntimeError("Hinge telemetry unavailable; the requested pose is unverified")
    if abs(angle - degrees) > 1:
        raise RuntimeError(f"Hinge readback mismatch: requested {degrees}, observed {angle}")


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

    try:
        launch = run(["xcrun", "simctl", "launch", args.device, args.bundle])
        match = re.search(r": (\d+)\s*$", launch)
        if not match:
            raise RuntimeError("Cannot verify app PID: " + launch)
        pid = int(match.group(1))
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
            run(["python3", str(HELPER), "-d", args.device, pose], timeout=90)
            try:
                state = json.loads(run([
                    "python3", str(HELPER), "-d", args.device, "rotate", orientation,
                ], timeout=90))
            except RuntimeError:
                if not args.landscape_only:
                    raise
                orientation = "landscape-flipped"
                state = json.loads(run([
                    "python3", str(HELPER), "-d", args.device, "rotate", orientation,
                ], timeout=90))
            verify_pose(state, screen, orientation, degrees)
            os.kill(pid, 0)
            time.sleep(2)
            image = out / (name + ".jpg")
            run([
                "xcrun", "simctl", "io", args.device, "screenshot", "--type=jpeg",
                "--display=" + str(state["displayId"]), str(image),
            ])
            os.kill(pid, 0)
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
            })
            (out / "poses.json").write_text(json.dumps({
                "bundle": args.bundle, "poses": records, "complete": False,
            }, indent=2) + "\n")

        (out / "poses.json").write_text(json.dumps({
            "bundle": args.bundle, "poses": records, "complete": True,
            "scope": "Verified simulator hinge/display readback, screenshot dimensions, "
                     "and liveness of the launched PID. Visual layout, task behavior, "
                     "and physical BLE operation require separate review.",
        }, indent=2) + "\n")
    except Exception as error:
        # Persist the primary failure before diagnostics, which may also fail.
        (out / "failure.json").write_text(json.dumps({
            "error": str(error), "stage": stage, "completedPoses": len(records),
        }, indent=2) + "\n")
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
