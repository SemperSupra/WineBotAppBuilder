import unittest
import sys
from pathlib import Path

# Add repo root to path
ROOT_DIR = Path(__file__).parents[2]
sys.path.insert(0, str(ROOT_DIR))

from core.scm import sanitize_git_url  # noqa: E402


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


if __name__ == "__main__":
    unittest.main()
