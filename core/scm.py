import shutil
import subprocess
import tempfile
import os
from urllib.parse import urlparse, urlunparse
from pathlib import Path
from typing import Optional, Generator
from contextlib import contextmanager


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

    @contextmanager
    def prepare_source(self, url: str, ref: str) -> Generator[Path, None, None]:
        """
        Clones a git repository to a directory under agent-sandbox/ and checks out the specified ref.
        Yields the path to the directory and ensures cleanup on exit.
        """
        timeout = int(os.environ.get("WBAB_GIT_TIMEOUT_SECS", "300"))

        # Security: Whitelist check
        allowed_domains = os.environ.get("WBAB_GIT_ALLOWED_DOMAINS", "").split(",")
        allowed_domains = [d.strip() for d in allowed_domains if d.strip()]

        if allowed_domains:
            parsed = urlparse(url)
            domain = parsed.hostname or ""
            if domain not in allowed_domains:
                raise ValueError(
                    f"SecurityError: Domain '{domain}' is not in WBAB_GIT_ALLOWED_DOMAINS"
                )

        # Create a secure temporary directory under agent-sandbox/
        sandbox_dir = self.root_dir / "agent-sandbox"
        sandbox_dir.mkdir(parents=True, exist_ok=True)

        temp_dir = Path(tempfile.mkdtemp(prefix="git-source-", dir=sandbox_dir))

        try:
            # Clone the repository
            subprocess.run(
                ["git", "clone", "--quiet", "--", url, str(temp_dir)],
                check=True,
                capture_output=True,
                text=True,
                timeout=timeout,
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
                    text=True,
                    timeout=timeout,
                )

            # Update submodules recursively
            subprocess.run(
                ["git", "submodule", "update", "--init", "--recursive", "--quiet"],
                cwd=temp_dir,
                check=True,
                capture_output=True,
                text=True,
                timeout=timeout,
            )

            yield temp_dir

        except subprocess.TimeoutExpired as e:
            raise RuntimeError(
                f"Git operation timed out after {timeout} seconds"
            ) from e
        except subprocess.CalledProcessError as e:
            raise RuntimeError(f"Git operation failed: {e.stderr.strip()}") from e
        except Exception as e:
            raise RuntimeError(f"Failed to prepare git source: {e}") from e
        finally:
            self.cleanup(temp_dir)

    def cleanup(self, path: Path):
        """Removes the temporary directory."""
        if path.exists():
            shutil.rmtree(path, ignore_errors=True)
