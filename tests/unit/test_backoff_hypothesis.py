"""Property-based tests for Executor._get_backoff_delay() using Hypothesis."""
import shutil
import sys
import tempfile
import unittest
from unittest.mock import MagicMock
from pathlib import Path

# Add repo root to path
ROOT_DIR = Path(__file__).parents[2]
sys.path.insert(0, str(ROOT_DIR))

# Mock fcntl before importing wbab_core (not available on Windows)
sys.modules["fcntl"] = MagicMock()

from core.wbab_core import Executor, OperationStore  # noqa: E402


class TestBackoffDelayHypothesis(unittest.TestCase):
    """Property-based tests for retry backoff delay."""

    def setUp(self):
        self.root_dir = Path(tempfile.mkdtemp())
        self.store = MagicMock(spec=OperationStore)
        self.audit = MagicMock()
        self.executor = Executor(self.root_dir, self.store, audit=self.audit)

    def tearDown(self):
        shutil.rmtree(self.root_dir, ignore_errors=True)

    def test_backoff_monotonic(self):
        """Property: delay should be non-decreasing as attempts increase."""
        from hypothesis import given, strategies as st

        @given(st.integers(min_value=1, max_value=14))
        def _test(attempts):
            d1 = self.executor._get_backoff_delay(attempts)
            d2 = self.executor._get_backoff_delay(attempts + 1)
            self.assertGreaterEqual(d2, d1)

        _test()

    def test_backoff_bounded(self):
        """Property: delay should always be >= 0 and <= 300 (hardcoded max)."""
        from hypothesis import given, strategies as st

        @given(st.integers(min_value=0, max_value=100))
        def _test(attempts):
            delay = self.executor._get_backoff_delay(attempts)
            self.assertGreaterEqual(delay, 0)
            self.assertLessEqual(delay, 300)

        _test()

    def test_backoff_zero_for_first_two_attempts(self):
        """Property: attempts 0 and 1 always return 0 regardless of settings."""
        from hypothesis import given, strategies as st

        @given(st.integers(max_value=-1))
        def _test_negative(n):
            delay = self.executor._get_backoff_delay(n)
            self.assertEqual(delay, 0)

        @given(st.integers(min_value=0, max_value=1))
        def _test_zero_one(n):
            delay = self.executor._get_backoff_delay(n)
            self.assertEqual(delay, 0)

        _test_negative()
        _test_zero_one()

    def test_backoff_max_cap(self):
        """Property: delay never exceeds 300 (hardcoded max)."""
        from hypothesis import given, strategies as st

        @given(st.integers(min_value=0, max_value=50))
        def _test(attempts):
            delay = self.executor._get_backoff_delay(attempts)
            self.assertLessEqual(delay, 300)

        _test()

    def test_backoff_exponential_until_cap(self):
        """Property: for attempts where 2^n < 300, delay == 2^n (hardcoded base=2)."""
        from hypothesis import given, strategies as st, settings

        @given(st.integers(min_value=2, max_value=8))
        @settings(max_examples=50)
        def _test(attempts):
            delay = self.executor._get_backoff_delay(attempts)
            expected = 2**attempts
            if expected <= 300:
                self.assertEqual(delay, expected)
            else:
                self.assertEqual(delay, 300)

        _test()


if __name__ == "__main__":
    unittest.main()
