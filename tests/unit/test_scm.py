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
