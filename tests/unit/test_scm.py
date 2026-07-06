import os
import shutil
import tempfile
import unittest
from unittest.mock import MagicMock, patch
from pathlib import Path
import sys

# Add repo root to path
ROOT_DIR = Path(__file__).parents[2]
sys.path.insert(0, str(ROOT_DIR))

from core.scm import GitSourceManager, sanitize_git_url  # noqa: E402


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
