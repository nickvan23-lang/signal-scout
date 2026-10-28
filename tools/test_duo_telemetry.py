#!/usr/bin/env python3
"""Portable checks for diagnostic child lifetimes, deadlines, and raw evidence."""
import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('duo_diagnostic', Path(__file__).with_name('diagnose_duo_telemetry.py'))
diagnostic = importlib.util.module_from_spec(spec)
spec.loader.exec_module(diagnostic)


class RecorderTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.out = Path(self.temp.name)
        self.recorder = diagnostic.Recorder(self.out, budget=5)

    def run_python(self, code, timeout=1, terminal=False):
        return self.recorder.run('probe', [sys.executable, '-c', code], timeout, terminal)

    def test_stdout_eof_before_success_preserves_child_exit(self):
        result = self.run_python('import os,time; os.close(1); time.sleep(0.1)')
        self.assertEqual(result['returnCode'], 0)
        self.assertFalse(result['timedOut'])
        self.assertNotIn('error', result)
        self.assertGreaterEqual(result['durationSeconds'], 0.09)

    def test_stdout_eof_before_failure_preserves_nonzero_exit(self):
        result = self.run_python('import os,time,sys; os.close(1); time.sleep(0.1); sys.exit(7)')
        self.assertEqual(result['returnCode'], 7)
        self.assertFalse(result['timedOut'])
        self.assertNotIn('error', result)

    def test_pty_eof_before_exit_preserves_child_exit(self):
        result = self.run_python('import os,time; os.close(1); time.sleep(0.1)', terminal=True)
        self.assertEqual(result['returnCode'], 0)
        self.assertFalse(result['timedOut'])

    def test_actual_deadline_after_eof_is_reported_as_timeout(self):
        result = self.run_python('import os,time; os.close(1); time.sleep(30)', timeout=0.15)
        self.assertTrue(result['timedOut'])
        self.assertEqual(result['returnCode'], -9)
        self.assertGreaterEqual(result['durationSeconds'], 0.14)
        self.assertLess(result['durationSeconds'], 1.5)

    def test_process_group_permission_failure_is_cleanup_not_native_error(self):
        with patch.object(diagnostic.os, 'killpg', side_effect=PermissionError('test group cleanup denied')):
            result = self.run_python('import time; time.sleep(30)', timeout=0.15)
        self.assertTrue(result['timedOut'])
        self.assertEqual(result['returnCode'], -9)
        self.assertIn('cleanupWarnings', result)
        self.assertNotIn('error', result)
        self.assertNotIn('cleanupError', result)

    def test_stdout_and_stderr_are_preserved_separately(self):
        result = self.run_python("import sys; print('raw stdout'); print('raw stderr',file=sys.stderr); sys.exit(3)")
        self.assertEqual(result['returnCode'], 3)
        self.assertEqual((self.out / 'probe.stdout').read_text(), 'raw stdout\n')
        self.assertEqual((self.out / 'probe.stderr').read_text(), 'raw stderr\n')
        self.assertFalse(result['timedOut'])


if __name__ == '__main__':
    unittest.main(verbosity=2)
