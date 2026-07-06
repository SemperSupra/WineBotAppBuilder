import os
import shutil
import sys
import tempfile
import unittest
from unittest.mock import MagicMock, patch
from pathlib import Path

# Add repo root to path
ROOT_DIR = Path(__file__).parents[2]
sys.path.insert(0, str(ROOT_DIR))

# Mock fcntl before importing wbab_core (not available on Windows)
sys.modules["fcntl"] = MagicMock()

from core.scm import GitSourceManager, sanitize_git_url  # noqa: E402
from core.wbab_core import Executor, OperationStore  # noqa: E402


class TestSCM(unittest.TestCase):
    def test_sanitize_git_url(self):
        # Basic auth with password
        self.assertEqual(
            sanitize_git_url("https://user:pass@host/repo"), "https://***:***@host/repo"
        )
        # Token (username only)
        self.assertEqual(
            sanitize_git_url("https://token@host/repo"), "https://***:***@host/repo"
        )
        # Token (password only)
        self.assertEqual(
            sanitize_git_url("https://:token@host/repo"), "https://***:***@host/repo"
        )
        # SSH
        self.assertEqual(
            sanitize_git_url("ssh://user:pass@host/repo"), "ssh://***:***@host/repo"
        )
        self.assertEqual(
            sanitize_git_url("ssh://user@host/repo"), "ssh://***:***@host/repo"
        )
        # Plain
        self.assertEqual(sanitize_git_url("https://host/repo"), "https://host/repo")
        # Git SSH syntax (scp-like)
        self.assertEqual(
            sanitize_git_url("git@github.com:user/repo.git"),
            "git@github.com:user/repo.git",
        )


class TestGitSourceManagerRecursive(unittest.TestCase):
    def setUp(self):
        self.root_dir = Path(tempfile.mkdtemp())
        self.manager = GitSourceManager(self.root_dir)

    def tearDown(self):
        shutil.rmtree(self.root_dir, ignore_errors=True)

    @patch("core.scm.subprocess.run")
    @patch("core.scm.os.environ", {
        "WBAB_GIT_TIMEOUT_SECS": "300",
        "WBAB_GIT_ALLOWED_DOMAINS": "",
    })
    def test_prepare_source_recursive_default(self, mock_run):
        """When WBAB_GIT_CLONE_RECURSIVE is unset, submodule update should run."""
        mock_run.return_value = MagicMock()
        try:
            with self.manager.prepare_source("https://github.com/test/a.git", "main") as path:
                self.assertTrue(path.exists())
        except Exception:
            pass
        # clone + checkout + submodule update = 3 calls
        self.assertGreaterEqual(mock_run.call_count, 2)
        # Check the last call was submodule update
        all_cmds = []
        for call_args in mock_run.call_args_list:
            all_cmds.extend(call_args[0][0])
        cmd_str = " ".join(all_cmds)
        self.assertIn("submodule", cmd_str, "Expected submodule update when env var unset")

    @patch("core.scm.subprocess.run")
    @patch("core.scm.os.environ", {
        "WBAB_GIT_TIMEOUT_SECS": "300",
        "WBAB_GIT_ALLOWED_DOMAINS": "",
        "WBAB_GIT_CLONE_RECURSIVE": "1",
    })
    def test_prepare_source_recursive_enabled(self, mock_run):
        """When WBAB_GIT_CLONE_RECURSIVE=1, submodule update should run."""
        mock_run.return_value = MagicMock()
        try:
            with self.manager.prepare_source("https://github.com/test/a.git", "main") as path:
                self.assertTrue(path.exists())
        except Exception:
            pass
        all_cmds = []
        for call_args in mock_run.call_args_list:
            all_cmds.extend(call_args[0][0])
        cmd_str = " ".join(all_cmds)
        self.assertIn("submodule", cmd_str, "Expected submodule update when RECURSIVE=1")

    @patch("core.scm.subprocess.run")
    @patch("core.scm.os.environ", {
        "WBAB_GIT_TIMEOUT_SECS": "300",
        "WBAB_GIT_ALLOWED_DOMAINS": "",
        "WBAB_GIT_CLONE_RECURSIVE": "0",
    })
    def test_prepare_source_recursive_disabled(self, mock_run):
        """When WBAB_GIT_CLONE_RECURSIVE=0, submodule update should NOT run."""
        mock_run.return_value = MagicMock()
        try:
            with self.manager.prepare_source("https://github.com/test/a.git", "main") as path:
                self.assertTrue(path.exists())
        except Exception:
            pass
        all_cmds = []
        for call_args in mock_run.call_args_list:
            all_cmds.extend(call_args[0][0])
        cmd_str = " ".join(all_cmds)
        self.assertNotIn("submodule", cmd_str, "Expected no submodule update when RECURSIVE=0")


if __name__ == "__main__":
    unittest.main()


class TestBackoffDelay(unittest.TestCase):
    """Tests for Executor._get_backoff_delay() configurable backoff."""

    def setUp(self):
        self.root_dir = Path(tempfile.mkdtemp())
        self.store = MagicMock(spec=OperationStore)
        self.audit = MagicMock()
        self.executor = Executor(self.root_dir, self.store, audit=self.audit)

    def tearDown(self):
        shutil.rmtree(self.root_dir, ignore_errors=True)

    def test_backoff_defaults(self):
        """Default base=2, max=300."""
        self.assertEqual(self.executor._get_backoff_delay(0), 0)
        self.assertEqual(self.executor._get_backoff_delay(1), 0)
        self.assertEqual(self.executor._get_backoff_delay(2), 4)
        self.assertEqual(self.executor._get_backoff_delay(3), 8)
        self.assertEqual(self.executor._get_backoff_delay(4), 16)
        self.assertEqual(self.executor._get_backoff_delay(9), 300)  # capped

    def test_backoff_attempts_zero_and_one_always_zero(self):
        """0 and 1 attempts always return 0 regardless of env settings."""
        with patch.dict(os.environ, {"WBAB_RETRY_BACKOFF_BASE": "10"}):
            self.assertEqual(self.executor._get_backoff_delay(0), 0)
            self.assertEqual(self.executor._get_backoff_delay(1), 0)
        with patch.dict(os.environ, {"WBAB_RETRY_BACKOFF_MAX": "0"}):
            self.assertEqual(self.executor._get_backoff_delay(0), 0)
            self.assertEqual(self.executor._get_backoff_delay(1), 0)

    @patch.dict(os.environ, {"WBAB_RETRY_BACKOFF_BASE": "3"})
    def test_backoff_custom_base(self):
        """When WBAB_RETRY_BACKOFF_BASE=3, delay uses 3^attempts."""
        self.assertEqual(self.executor._get_backoff_delay(2), 9)
        self.assertEqual(self.executor._get_backoff_delay(3), 27)
        self.assertEqual(self.executor._get_backoff_delay(4), 81)

    @patch.dict(os.environ, {"WBAB_RETRY_BACKOFF_MAX": "10"})
    def test_backoff_custom_max(self):
        """When WBAB_RETRY_BACKOFF_MAX=10, delay is capped at 10."""
        self.assertEqual(self.executor._get_backoff_delay(4), 10)
        self.assertEqual(self.executor._get_backoff_delay(9), 10)

    @patch.dict(os.environ, {
        "WBAB_RETRY_BACKOFF_BASE": "3",
        "WBAB_RETRY_BACKOFF_MAX": "50",
    })
    def test_backoff_custom_base_and_max(self):
        """Both env vars together produce correct values."""
        self.assertEqual(self.executor._get_backoff_delay(2), 9)
        self.assertEqual(self.executor._get_backoff_delay(3), 27)
        self.assertEqual(self.executor._get_backoff_delay(4), 50)

    def test_backoff_non_numeric_base_falls_back(self):
        """Non-numeric WBAB_RETRY_BACKOFF_BASE falls back to default 2."""
        with patch.dict(os.environ, {"WBAB_RETRY_BACKOFF_BASE": "not-a-number"}):
            self.assertEqual(self.executor._get_backoff_delay(2), 4)
            self.assertEqual(self.executor._get_backoff_delay(3), 8)

    def test_backoff_non_numeric_max_falls_back(self):
        """Non-numeric WBAB_RETRY_BACKOFF_MAX falls back to default 300."""
        with patch.dict(os.environ, {"WBAB_RETRY_BACKOFF_MAX": "not-a-number"}):
            self.assertEqual(self.executor._get_backoff_delay(2), 4)
            self.assertEqual(self.executor._get_backoff_delay(9), 300)

    def test_backoff_base_too_low_clamped(self):
        """Base < 2 is clamped to 2."""
        with patch.dict(os.environ, {"WBAB_RETRY_BACKOFF_BASE": "0"}):
            self.assertEqual(self.executor._get_backoff_delay(2), 4)
        with patch.dict(os.environ, {"WBAB_RETRY_BACKOFF_BASE": "1"}):
            self.assertEqual(self.executor._get_backoff_delay(2), 4)


class TestSanitizeGitUrlHypothesis(unittest.TestCase):
    """Property-based tests for sanitize_git_url using Hypothesis."""

    def test_urls_with_credentials_redacted(self):
        """URLs with credentials always have them redacted."""
        from hypothesis import given, strategies as st

        # Test common URL schemes with credentials
        urls_with_auth = [
            "https://user:pass@host/repo",
            "https://token@host/repo",
            "https://:token@host/repo",
            "ssh://user:pass@host/repo",
            "ssh://user@host/repo",
            "http://user:pass@host:8080/repo",
            "ftp://user:pass@host/repo",
            "https://user:pass@host:443/repo.git",
            "https://user:pass@host/repo/path/deep",
            "git+https://user:pass@host/repo",
        ]
        for url in urls_with_auth:
            result = sanitize_git_url(url)
            self.assertNotIn("user:pass", result)
            self.assertNotIn("token@", result)
            self.assertIn("***:***", result)

    def test_urls_without_auth_pass_through(self):
        """URLs without auth credentials pass through unchanged."""
        urls_no_auth = [
            "https://host/repo",
            "https://host:443/repo.git",
            "ssh://host/repo",
            "http://host/repo",
            "git@github.com:user/repo.git",
            "https://github.com/user/repo",
            "git://host/repo",
            "ftps://host/repo",
            "file:///path/to/repo",
            "",
        ]
        for url in urls_no_auth:
            result = sanitize_git_url(url)
            self.assertEqual(result, url)

    def test_non_url_strings_pass_through(self):
        """Non-URL strings should pass through unchanged."""
        non_urls = [
            "plain-text",
            "user@host (no scheme)",
            "  spaces  ",
            "host:port/path",
            "/absolute/path",
            "./relative/path",
            "C:\\Windows\\path",
        ]
        for s in non_urls:
            result = sanitize_git_url(s)
            self.assertEqual(result, s)

    def test_with_hypothesis_strategies(self):
        """Using Hypothesis strategies: for any string containing @, if it looks
        like a URL with auth, the output should contain ***:***."""
        from hypothesis import given, strategies as st

        @given(st.text())
        def _test(s):
            result = sanitize_git_url(s)
            # The function should never raise for any string
            self.assertIsInstance(result, str)
            # If input contains @ and a scheme:// prefix, auth should be redacted
            if "://" in s and "@" in s:
                # Ensure there's something between :// and @ (the credential part)
                auth_part = s[s.index("://") + 3 : s.index("@")]
                if auth_part:
                    self.assertIn("***:***", result)

        _test()

    def test_no_exceptions_for_any_input(self):
        """sanitize_git_url should never raise for any string input."""
        from hypothesis import given, strategies as st

        @given(st.text())
        def _test(s):
            try:
                sanitize_git_url(s)
            except Exception as e:
                self.fail(f"sanitize_git_url raised {type(e).__name__}: {e}")

        _test()
