import shutil
import subprocess
import tempfile
from urllib.parse import urlparse, urlunparse
from pathlib import Path
from typing import Optional

def sanitize_git_url(url: str) -> str:
    """Redacts credentials from a git URL."""
    try:
        parsed = urlparse(url)
        # Always redact credentials if present (username or password)
        if parsed.username or parsed.password:
            host = parsed.hostname or ""
            netloc = f"***:***@{host}"
            if parsed.port:
                netloc += f":{parsed.port}"
            sanitized = parsed._replace(netloc=netloc)
            return urlunparse(sanitized)
    except Exception:
        pass
    return url

class GitSourceManager:
    def __init__(self, root_dir: Optional[Path] = None):
        self.root_dir = root_dir or Path.cwd()

    def prepare_source(self, url: str, ref: str) -> Path:
        """
        Clones a git repository to a directory under agent-sandbox/ and checks out the specified ref.
        Returns the path to the directory.
        """
        # Create a secure temporary directory under agent-sandbox/
        sandbox_dir = self.root_dir / "agent-sandbox"
        sandbox_dir.mkdir(parents=True, exist_ok=True)

        temp_dir = Path(tempfile.mkdtemp(prefix="git-source-", dir=sandbox_dir))

        try:
            # Clone the repository
            # Use -- to separate options from arguments (url, destination)
            subprocess.run(
                ["git", "clone", "--quiet", "--", url, str(temp_dir)],
                check=True,
                capture_output=True,
                text=True
            )

            # Checkout the specific ref
            if ref:
                if ref.startswith("-"):
                    raise ValueError(f"Invalid ref: {ref}")
                subprocess.run(
                    ["git", "checkout", "--quiet", ref],
                    cwd=temp_dir,
                    check=True,
                    capture_output=True,
                    text=True
                )

            # Update submodules recursively
            subprocess.run(
                ["git", "submodule", "update", "--init", "--recursive", "--quiet"],
                cwd=temp_dir,
                check=True,
                capture_output=True,
                text=True
            )

            return temp_dir

        except subprocess.CalledProcessError as e:
            # If any git command fails, clean up and re-raise
            self.cleanup(temp_dir)
            # We don't sanitize stderr here because git usually doesn't output the password.
            # But the caller might log the error.
            raise RuntimeError(f"Git operation failed: {e.stderr.strip()}") from e
        except Exception as e:
            self.cleanup(temp_dir)
            raise RuntimeError(f"Failed to prepare git source: {e}") from e

    def cleanup(self, path: Path):
        """Removes the temporary directory."""
        if path.exists():
            shutil.rmtree(path, ignore_errors=True)
