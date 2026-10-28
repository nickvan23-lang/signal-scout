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


class HingeStreamTests(unittest.TestCase):
    def read_stream(self, code, timeout=0.15):
        children = []
        original_popen = subprocess.Popen

        def popen(_args, **kwargs):
            process = original_popen([sys.executable, "-c", code], **kwargs)
            children.append(process)
            return process

        started = time.monotonic()
        with patch.object(duo.subprocess, "Popen", side_effect=popen):
            result = duo.hinge_angle("test-device", timeout=timeout)
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

    def test_missing_wrong_or_nonfinite_hinge_is_not_verified(self):
        for angle in (None, 0, 180, float("nan"), float("inf")):
            with self.subTest(angle=angle):
                state = {"activeScreen": "inner", "orientation": "landscape", "hingeAngle": angle}
                with self.assertRaises(RuntimeError):
                    capture.verify_pose(state, "inner", "landscape", 90)
        capture.verify_pose({
            "activeScreen": "inner", "orientation": "landscape", "hingeAngle": 90.2,
        }, "inner", "landscape", 90)

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
            with patch.object(capture, "run", return_value="app.test: 123\n"), \
                 patch.object(capture, "wait_for_display", side_effect=RuntimeError("no active display")), \
                 patch.object(capture, "read_state", side_effect=RuntimeError("no diagnostic display")):
                with self.assertRaisesRegex(RuntimeError, "no active display"):
                    capture.main(["--device", "test", "--bundle", "app.test", "--out", str(out)])
            failure = json.loads((out / "failure.json").read_text())
            self.assertEqual(failure["stage"], "display-readiness")
            self.assertEqual(failure["completedPoses"], 0)

    def test_successful_capture_records_all_verified_poses(self):
        current = {"activeScreen": "cover", "hingeAngle": 0, "displayId": 1}

        def fake_run(args, timeout=60):
            if args[:3] == ["xcrun", "simctl", "launch"]:
                return "app.test: 123\n"
            if args[0] == "python3":
                action = args[4]
                if action in ("open", "close", "half"):
                    current["activeScreen"] = "cover" if action == "close" else "inner"
                    current["hingeAngle"] = {"close": 0, "open": 180, "half": 90}[action]
                elif action == "rotate":
                    current["orientation"] = args[5]
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
            with patch.object(capture, "run", side_effect=fake_run), \
                 patch.object(capture, "wait_for_display"), \
                 patch.object(capture.os, "kill"), patch.object(capture.time, "sleep"):
                capture.main(["--device", "test", "--bundle", "app.test", "--out", str(out)])
            result = json.loads((out / "poses.json").read_text())
            self.assertTrue(result["complete"])
            self.assertEqual(len(result["poses"]), 5)
            self.assertEqual([p["state"]["hingeAngle"] for p in result["poses"]], [0, 180, 180, 90, 0])
            self.assertFalse((out / "failure.json").exists())


if __name__ == "__main__":
    unittest.main(verbosity=2)
