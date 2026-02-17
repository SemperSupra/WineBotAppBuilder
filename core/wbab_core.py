#!/usr/bin/env python3
"""Minimal core baseline for WBAB: planner + executor + idempotent store."""

from __future__ import annotations

import fcntl
import json
import os
import shutil
import sqlite3
import uuid
import subprocess
import time
import tempfile
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional
from core.scm import GitSourceManager, sanitize_git_url


@dataclass
class Plan:
    op_id: str
    verb: str
    args: List[str]
    steps: List[Dict[str, Any]]
    source: Dict[str, str]


class WorkspaceLock:
    """Advisory lock for project workspaces to prevent concurrent modification."""

    def __init__(self, project_path: Path) -> None:
        self.lock_file = project_path / ".wbab.lock"
        self._fd: Optional[int] = None

    def __enter__(self) -> WorkspaceLock:
        self.lock_file.parent.mkdir(parents=True, exist_ok=True)
        self._fd = os.open(self.lock_file, os.O_RDWR | os.O_CREAT)
        try:
            fcntl.flock(self._fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
            # Write PID to lock file for recovery/cancellation
            os.ftruncate(self._fd, 0)
            os.write(self._fd, str(os.getpid()).encode())
        except BlockingIOError:
            os.close(self._fd)
            raise RuntimeError(f"Workspace is locked by another WBAB process: {self.lock_file}")
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        if self._fd is not None:
            try:
                fcntl.flock(self._fd, fcntl.LOCK_UN)
            finally:
                os.close(self._fd)


class OperationStore:
    """SQLite-backed store for idempotent operations."""

    def __init__(self, path: Path) -> None:
        self.path = path
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self._init_db()

    def _get_conn(self) -> sqlite3.Connection:
        # Use a reasonable timeout for concurrent access
        conn = sqlite3.connect(self.path, timeout=30.0)
        conn.row_factory = sqlite3.Row
        return conn

    def _init_db(self) -> None:
        with self._get_conn() as conn:
            conn.execute(
                "CREATE TABLE IF NOT EXISTS metadata (key TEXT PRIMARY KEY, value TEXT)"
            )
            conn.execute(
                "CREATE TABLE IF NOT EXISTS operations (op_id TEXT PRIMARY KEY, payload TEXT)"
            )
            
            # Ensure instance_id exists
            res = conn.execute("SELECT value FROM metadata WHERE key = 'instance_id'").fetchone()
            if not res:
                conn.execute("INSERT INTO metadata (key, value) VALUES ('instance_id', ?)", (str(uuid.uuid4()),))

    def get_instance_id(self) -> str:
        with self._get_conn() as conn:
            res = conn.execute("SELECT value FROM metadata WHERE key = 'instance_id'").fetchone()
            return res["value"] if res else str(uuid.uuid4())

    def get(self, op_id: str) -> Dict[str, Any] | None:
        with self._get_conn() as conn:
            res = conn.execute("SELECT payload FROM operations WHERE op_id = ?", (op_id,)).fetchone()
            if res:
                return json.loads(res["payload"])
        return None

    def upsert(self, op_id: str, payload: Dict[str, Any]) -> None:
        with self._get_conn() as conn:
            conn.execute(
                "INSERT OR REPLACE INTO operations (op_id, payload) VALUES (?, ?)",
                (op_id, json.dumps(payload, sort_keys=True))
            )

    def list_all(self) -> Dict[str, Dict[str, Any]]:
        """Returns all operations. Used primarily for zombie recovery."""
        with self._get_conn() as conn:
            rows = conn.execute("SELECT op_id, payload FROM operations").fetchall()
            return {row["op_id"]: json.loads(row["payload"]) for row in rows}


class AuditLog:
    """SQLite-backed audit log for command/event traceability."""

    def __init__(self, path: Path, source: str = "wbabd") -> None:
        self.path = path
        self.source = source
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self._init_db()

    def _get_conn(self) -> sqlite3.Connection:
        return sqlite3.connect(self.path, timeout=30.0)

    def _init_db(self) -> None:
        with self._get_conn() as conn:
            conn.execute(
                """CREATE TABLE IF NOT EXISTS audit_events (
                    event_id TEXT PRIMARY KEY,
                    ts TEXT,
                    source TEXT,
                    actor TEXT,
                    session_id TEXT,
                    event_type TEXT,
                    op_id TEXT,
                    verb TEXT,
                    status TEXT,
                    step TEXT,
                    details TEXT
                )"""
            )

    def _now(self) -> str:
        return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")

    def emit(
        self,
        event_type: str,
        *,
        op_id: str = "",
        verb: str = "",
        status: str = "",
        step: str = "",
        details: Dict[str, Any] | None = None,
    ) -> None:
        event_id = str(uuid.uuid4())
        ts = self._now()
        actor = os.environ.get("WBABD_ACTOR", "unknown")
        session_id = os.environ.get("WBABD_SESSION_ID", "")
        details_json = json.dumps(details) if details else None

        with self._get_conn() as conn:
            conn.execute(
                """INSERT INTO audit_events 
                   (event_id, ts, source, actor, session_id, event_type, op_id, verb, status, step, details)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                (event_id, ts, self.source, actor, session_id, event_type, op_id, verb, status, step, details_json)
            )


class Planner:
    def plan(
        self,
        op_id: str,
        verb: str,
        args: List[str],
        git_url: Optional[str] = None,
        git_ref: Optional[str] = None,
    ) -> Plan:
        if verb not in {"build", "package", "sign", "smoke", "doctor", "lint", "test"}:
            raise ValueError(f"unsupported verb: {verb}")

        source = {"type": "local"}
        if git_url:
            source = {"type": "git", "url": git_url, "ref": git_ref or ""}

        return Plan(
            op_id=op_id,
            verb=verb,
            args=args,
            steps=[
                {"name": "validate_inputs"},
                {"name": f"execute_{verb}"},
                {"name": "record_result"},
            ],
            source=source,
        )


class Executor:
    def __init__(self, root_dir: Path, store: OperationStore, audit: AuditLog | None = None) -> None:
        self.root_dir = root_dir
        self.store = store
        self.audit = audit

    def recover_zombies(self) -> int:
        """
        Scans the operation store for 'running' operations. If the workspace lock
        is not held by any process, transitions the operation to 'failed'.
        Returns the number of recovered operations.
        """
        count = 0
        ops = self.store.list_all()

        for op_id, op in ops.items():
            if op.get("status") == "running":
                project_dir = Path(op.get("args", ["."])[0])
                if not project_dir.is_absolute():
                    project_dir = self.root_dir / project_dir
                
                lock_file = project_dir / ".wbab.lock"
                is_stale = False
                if not lock_file.exists():
                    is_stale = True
                else:
                    # Try to acquire lock non-blockingly to see if it is held
                    try:
                        fd = os.open(lock_file, os.O_RDWR)
                        try:
                            fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
                            # If we got here, we got the lock, so the previous process is dead
                            is_stale = True
                            fcntl.flock(fd, fcntl.LOCK_UN)
                        except BlockingIOError:
                            # Lock is held by a live process
                            pass
                        finally:
                            os.close(fd)
                    except OSError:
                        # Cannot open file, assume stale or inaccessible
                        is_stale = True

                if is_stale:
                    op["status"] = "failed"
                    op["finished_at"] = int(time.time())
                    op["result"] = {"error": "System aborted (process crash detected)", "step": "system_recovery"}
                    self.store.upsert(op_id, op)
                    if self.audit:
                        self.audit.emit("operation.recovered", op_id=op_id, verb=op.get("verb", ""), status="failed", details={"reason": "stale_lock"})
                    count += 1
        return count

    def cleanup_sandbox(self, max_age_secs: int = 86400) -> int:
        """
        Prunes directories in agent-sandbox/ that are older than max_age_secs
        and not associated with a currently 'running' operation.
        """
        count = 0
        project_root = _get_project_root(self.root_dir)
        sandbox_dir = project_root / "agent-sandbox"
        if not sandbox_dir.exists():
            return 0

        # Get active running directories to avoid pruning them
        active_dirs = set()
        ops = self.store.list_all()
        
        for op in ops.values():
            if op.get("status") == "running":
                p = Path(op.get("args", ["."])[0])
                if p.is_absolute() and str(p).startswith(str(sandbox_dir)):
                    active_dirs.add(str(p))

        now = time.time()
        for item in sandbox_dir.iterdir():
            if not item.is_dir():
                continue
            if str(item) in active_dirs:
                continue
            
            # Use mtime to determine age
            if (now - item.stat().st_mtime) > max_age_secs:
                # Double check for lock file existence/liveness
                lock_file = item / ".wbab.lock"
                if lock_file.exists():
                    try:
                        fd = os.open(lock_file, os.O_RDWR)
                        try:
                            fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
                            # Lock is not held, safe to delete
                            fcntl.flock(fd, fcntl.LOCK_UN)
                        except BlockingIOError:
                            # Lock IS held, do not delete
                            os.close(fd)
                            continue
                        finally:
                            os.close(fd)
                    except OSError:
                        pass
                
                # Recursive delete
                try:
                    subprocess.run(["rm", "-rf", str(item)], check=True)
                    count += 1
                except subprocess.CalledProcessError:
                    pass
        
        if count > 0 and self.audit:
            self.audit.emit("system.cleanup", status="ok", details={"pruned_count": count})
        return count

    def cancel(self, op_id: str) -> Dict[str, Any]:
        """
        Attempts to cancel a running operation by identifying the process holding
        the workspace lock and sending a SIGTERM.
        """
        op = self.store.get(op_id)
        if not op:
            return {"status": "error", "error": "not_found"}
        
        if op.get("status") != "running":
            return {"status": "error", "error": f"cannot cancel operation in status: {op.get('status')}"}

        project_dir = Path(op.get("args", ["."])[0])
        if not project_dir.is_absolute():
            project_dir = self.root_dir / project_dir
        
        lock_file = project_dir / ".wbab.lock"
        if not lock_file.exists():
            op["status"] = "failed"
            op["finished_at"] = self._now()
            op["result"] = {"error": "Cancelled (no workspace lock found)", "step": "cancel"}
            self.store.upsert(op_id, op)
            return {"status": "succeeded", "message": "Operation marked as failed (stale state detected)"}

        # Try to read PID from lock file
        pid = None
        try:
            with open(lock_file, "r") as f:
                content = f.read().strip()
                if content:
                    pid = int(content)
        except (ValueError, OSError):
            pass

        if pid:
            try:
                import signal
                os.kill(pid, signal.SIGTERM)
                # Give it a moment to handle signal if it's the same machine
                time.sleep(0.1)
            except ProcessLookupError:
                # Process already dead
                pass
            except Exception as exc:
                return {"status": "error", "error": f"failed to signal process {pid}: {exc}"}

        op["status"] = "failed"
        op["finished_at"] = self._now()
        op["result"] = {"error": "Cancelled by user", "step": "cancel"}
        self.store.upsert(op_id, op)
        self._audit("operation.cancelled", plan=Plan(op_id, op.get("verb",""), op.get("args",[]), [], {}), status="failed", details={"pid": pid})
        
        return {"status": "succeeded", "message": f"Operation cancelled (SIGTERM sent to PID {pid or 'unknown'})"}

    def _tool_path(self, rel: str) -> Path:
        return self.root_dir / rel

    def _run(self, cmd: List[str]) -> subprocess.CompletedProcess[str]:
        """Runs a command with timeout and streams output to a temporary file."""
        timeout = float(os.environ.get("WBAB_EXECUTION_TIMEOUT_SECS", "3600")) # Default 1 hour
        with tempfile.NamedTemporaryFile(mode="w+", delete=False, prefix="wbab-log-") as tmp:
            tmp_path = tmp.name
            try:
                proc = subprocess.run(
                    cmd,
                    cwd=self.root_dir,
                    stdout=tmp,
                    stderr=subprocess.STDOUT,
                    text=True,
                    check=False,
                    timeout=timeout
                )
                tmp.seek(0)
                output = tmp.read()
                return subprocess.CompletedProcess(
                    args=cmd,
                    returncode=proc.returncode,
                    stdout=output,
                    stderr=""
                )
            except subprocess.TimeoutExpired:
                return subprocess.CompletedProcess(
                    args=cmd,
                    returncode=124, # Standard timeout exit code
                    stdout=f"ERROR: Execution timed out after {timeout} seconds",
                    stderr=""
                )
            finally:
                if os.path.exists(tmp_path):
                    os.remove(tmp_path)

    def _now(self) -> int:
        return int(time.time())

    def _get_backoff_delay(self, attempts: int) -> int:
        """Calculates exponential backoff delay in seconds."""
        if attempts <= 1:
            return 0
        # 2, 4, 8, 16, 32... capped at 5 minutes
        return min(300, 2 ** attempts)

    def _validate_outputs(self, plan: Plan) -> bool:
        """Verifies that the expected outputs of a successful operation still exist."""
        project_dir = Path(plan.args[0]) if plan.args else Path(".")
        if not project_dir.is_absolute():
            project_dir = self.root_dir / project_dir

        if plan.verb == "build":
            return (project_dir / "out").exists()
        if plan.verb == "package":
            return (project_dir / "dist").exists()
        if plan.verb == "sign":
            # For sign, we expect the dist/ dir to have the signed files
            return (project_dir / "dist").exists()
        return True # Default pass for verbs like doctor, lint, test

    def run(self, plan: Plan) -> Dict[str, Any]:
        # Handle Git source provisioning if needed
        if plan.source.get("type") == "git":
            git_mgr = GitSourceManager(self.root_dir)
            url = plan.source["url"]
            safe_url = sanitize_git_url(url)
            ref = plan.source.get("ref", "")
            self._audit("source.fetch", plan=plan, status="started", details={"url": safe_url, "ref": ref})
            try:
                with git_mgr.prepare_source(url, ref) as temp_source_path:
                    self._audit("source.fetch", plan=plan, status="succeeded", details={"path": str(temp_source_path)})
                    
                    # Re-root the project dir into the temp checkout
                    if not plan.args or plan.args[0] == ".":
                        effective_project_dir = temp_source_path
                    else:
                        rel_path = plan.args[0].lstrip("/")
                        effective_project_dir = temp_source_path / rel_path
                    
                    return self._execute_in_workspace(plan, effective_project_dir)
            except Exception as exc:
                self._audit("source.fetch", plan=plan, status="failed", details={"error": str(exc)})
                return {
                    "status": "failed",
                    "op_id": plan.op_id,
                    "verb": plan.verb,
                    "result": {"error": f"Failed to fetch source: {exc}", "step": "source_fetch"}
                }
        else:
            effective_project_dir = Path(plan.args[0]) if plan.args else Path(".")
            return self._execute_in_workspace(plan, effective_project_dir)

    def _execute_in_workspace(self, plan: Plan, effective_project_dir: Path) -> Dict[str, Any]:
        # Path Jailing: Ensure the project directory is within the project root
        project_root = _get_project_root(self.root_dir).resolve()
        try:
            resolved_project_dir = effective_project_dir.resolve()
            if not str(resolved_project_dir).startswith(str(project_root)):
                raise ValueError(f"SecurityError: Project directory '{resolved_project_dir}' is outside of project root '{project_root}'")
        except Exception as exc:
            return {
                "status": "failed",
                "op_id": plan.op_id,
                "verb": plan.verb,
                "result": {"error": f"Path validation failed: {exc}", "step": "path_jailing"}
            }

        effective_project_dir = resolved_project_dir

        # Step 0: Robust Cache Validation
        existing = self.store.get(plan.op_id)
        if existing and existing.get("status") == "succeeded":
            # For git sources, we disable cache unless we implement artifact persistence
            if plan.source.get("type") != "git":
                if self._validate_outputs(plan):
                    self._audit("operation.cached", plan=plan, status="cached")
                    return {
                        "status": "cached",
                        "op_id": plan.op_id,
                        "verb": plan.verb,
                        "result": existing.get("result", {}),
                    }
                else:
                    self._audit("operation.cache_invalidated", plan=plan, status="running",
                            details={"reason": "expected outputs missing from disk"})

        # Step 0.5: Workspace Locking
        try:
            with WorkspaceLock(effective_project_dir):
                # Create a modified plan copy with the resolved absolute path
                new_args = [str(effective_project_dir)]
                if len(plan.args) > 1:
                    new_args.extend(plan.args[1:])

                runtime_plan = Plan(
                    op_id=plan.op_id,
                    verb=plan.verb,
                    args=new_args,
                    steps=plan.steps,
                    source=plan.source
                )

                result = self._run_operation(runtime_plan, existing)

                if plan.source.get("type") == "git" and result["status"] == "succeeded":
                    self._audit("source.artifacts", plan=plan, status="available",
                               details={"location": str(effective_project_dir)})

                return result

        except RuntimeError as exc:
            return {
                "status": "failed",
                "op_id": plan.op_id,
                "verb": plan.verb,
                "result": {"error": str(exc), "step": "acquire_workspace_lock"}
            }

    def _run_operation(self, plan: Plan, existing: Optional[Dict[str, Any]]) -> Dict[str, Any]:
        started = self._now()
        if existing:
            # Check throttling
            last_attempt = existing.get("last_attempt_at", 0)
            attempts = existing.get("attempts", 0)
            backoff = self._get_backoff_delay(attempts)
            if started < (last_attempt + backoff):
                wait_secs = (last_attempt + backoff) - started
                return {
                    "status": "failed",
                    "op_id": plan.op_id,
                    "verb": plan.verb,
                    "result": {
                        "error": f"Retry throttled. Please wait {wait_secs} seconds.",
                        "step": "throttling_check",
                        "retry_after_secs": wait_secs
                    }
                }

            op = existing
            op["verb"] = plan.verb
            op["args"] = plan.args
            op["steps"] = plan.steps
            op["source"] = plan.source
            op["retry_count"] = int(op.get("retry_count", 0)) + 1
        else:
            op = {
                "op_id": plan.op_id,
                "verb": plan.verb,
                "args": plan.args,
                "status": "running",
                "started_at": started,
                "finished_at": None,
                "steps": plan.steps,
                "source": plan.source,
                "retry_count": 0,
            }
        op["status"] = "running"
        op["last_attempt_at"] = started
        op["attempts"] = int(op.get("attempts", 0)) + 1
        op["step_state"] = self._ensure_step_state(op, plan)
        self._persist(plan, op)
        self._audit(
            "operation.started",
            plan=plan,
            status="running",
            details={"attempt": op["attempts"], "retry_count": op["retry_count"]},
        )

        # Step 1: validation (idempotent; skip if previously successful)
        validate_step = "validate_inputs"
        if op["step_state"][validate_step]["status"] != "succeeded":
            self._mark_step_running(op, validate_step)
            self._persist(plan, op)
            self._audit(
                "step.started",
                plan=plan,
                status="running",
                step=validate_step,
                details={"step_attempt": op["step_state"][validate_step]["attempts"]},
            )
            try:
                self._validate_inputs(plan)
            except Exception as exc:
                self._mark_step_failed(op, validate_step, str(exc))
                op["status"] = "failed"
                op["finished_at"] = self._now()
                op["result"] = {"error": str(exc), "step": validate_step}
                self._persist(plan, op)
                self._audit(
                    "step.failed",
                    plan=plan,
                    status="failed",
                    step=validate_step,
                    details={"error": str(exc)},
                )
                self._audit("operation.failed", plan=plan, status="failed", step=validate_step, details=op["result"])
                return {"status": "failed", "op_id": plan.op_id, "verb": plan.verb, "result": op["result"]}
            self._mark_step_succeeded(op, validate_step)
            self._persist(plan, op)
            self._audit("step.succeeded", plan=plan, status="succeeded", step=validate_step)

        # Step 2: execute verb (retryable)
        exec_step = f"execute_{plan.verb}"
        if op["step_state"][exec_step]["status"] != "succeeded":
            self._mark_step_running(op, exec_step)
            self._persist(plan, op)
            cmd = self._command_for(plan.verb, plan.args)
            self._audit(
                "step.started",
                plan=plan,
                status="running",
                step=exec_step,
                details={"step_attempt": op["step_state"][exec_step]["attempts"], "command": cmd},
            )
            proc = self._run(cmd)
            exec_result = {
                "exit_code": proc.returncode,
                "stdout": proc.stdout,
                "stderr": proc.stderr,
                "command": cmd,
            }
            op["execution"] = exec_result
            if proc.returncode != 0:
                self._mark_step_failed(op, exec_step, f"exit_code={proc.returncode}")
                op["status"] = "failed"
                op["finished_at"] = self._now()
                op["result"] = {**exec_result, "step": exec_step}
                self._rollback_artifacts(plan)
                self._persist(plan, op)
                self._audit(
                    "step.failed",
                    plan=plan,
                    status="failed",
                    step=exec_step,
                    details={"exit_code": proc.returncode},
                )
                self._audit("operation.failed", plan=plan, status="failed", step=exec_step, details=op["result"])
                return {"status": "failed", "op_id": plan.op_id, "verb": plan.verb, "result": op["result"]}
            self._mark_step_succeeded(op, exec_step)
            self._persist(plan, op)
            self._audit(
                "step.succeeded",
                plan=plan,
                status="succeeded",
                step=exec_step,
                details={"exit_code": proc.returncode},
            )

        # Step 3: record result (idempotent)
        record_step = "record_result"
        if op["step_state"][record_step]["status"] != "succeeded":
            self._mark_step_running(op, record_step)
            self._persist(plan, op)
            self._audit(
                "step.started",
                plan=plan,
                status="running",
                step=record_step,
                details={"step_attempt": op["step_state"][record_step]["attempts"]},
            )
            execution = op.get("execution", {})
            op["result"] = {
                "exit_code": execution.get("exit_code", 0),
                "stdout": execution.get("stdout", ""),
                "stderr": execution.get("stderr", ""),
                "command": execution.get("command", []),
            }
            self._mark_step_succeeded(op, record_step)
            self._persist(plan, op)
            self._audit("step.succeeded", plan=plan, status="succeeded", step=record_step)

        op["status"] = "succeeded"
        op["finished_at"] = self._now()
        self._persist(plan, op)
        self._audit("operation.succeeded", plan=plan, status="succeeded", details=op["result"])
        return {"status": "succeeded", "op_id": plan.op_id, "verb": plan.verb, "result": op["result"]}

    def _ensure_step_state(self, op: Dict[str, Any], plan: Plan) -> Dict[str, Dict[str, Any]]:
        state = op.get("step_state", {})
        for s in plan.steps:
            state.setdefault(
                s["name"],
                {
                    "status": "pending",
                    "attempts": 0,
                    "started_at": None,
                    "finished_at": None,
                    "last_error": None,
                },
            )
        return state

    def _mark_step_running(self, op: Dict[str, Any], step: str) -> None:
        st = op["step_state"][step]
        st["status"] = "running"
        st["attempts"] = int(st.get("attempts", 0)) + 1
        st["started_at"] = self._now()
        st["last_error"] = None

    def _mark_step_succeeded(self, op: Dict[str, Any], step: str) -> None:
        st = op["step_state"][step]
        st["status"] = "succeeded"
        st["finished_at"] = self._now()
        st["last_error"] = None

    def _mark_step_failed(self, op: Dict[str, Any], step: str, err: str) -> None:
        st = op["step_state"][step]
        st["status"] = "failed"
        st["finished_at"] = self._now()
        st["last_error"] = err

    def _persist(self, plan: Plan, op: Dict[str, Any]) -> None:
        self.store.upsert(plan.op_id, op)

    def _audit(
        self,
        event_type: str,
        *,
        plan: Plan,
        status: str = "",
        step: str = "",
        details: Dict[str, Any] | None = None,
    ) -> None:
        if self.audit is None:
            return
        self.audit.emit(
            event_type,
            op_id=plan.op_id,
            verb=plan.verb,
            status=status,
            step=step,
            details=details,
        )

    def _validate_inputs(self, plan: Plan) -> None:
        if plan.verb == "smoke" and not plan.args:
            raise ValueError("smoke requires installer path argument")

    def _rollback_artifacts(self, plan: Plan) -> None:
        """Removes output directories on failure to prevent artifact pollution."""
        project_dir = Path(plan.args[0]) if plan.args else Path(".")
        if not project_dir.is_absolute():
            project_dir = self.root_dir / project_dir
        
        # We only roll back if we own the directory (safety check)
        for sub in ["out", "dist"]:
            p = project_dir / sub
            if p.exists() and p.is_dir():
                try:
                    shutil.rmtree(p, ignore_errors=True)
                    if self.audit:
                        self.audit.emit("system.rollback", op_id=plan.op_id, verb=plan.verb, details={"path": str(p)})
                except Exception:
                    pass

    def _command_for(self, verb: str, args: List[str]) -> List[str]:
        # Security: Remote RCE Guard - Never run arbitrary host scripts.
        # Construct standard Docker run commands directly.
        # EXCEPTION: Allow mocking for unit tests via WBAB_MOCK_EXECUTION=1
        
        if os.environ.get("WBAB_MOCK_EXECUTION") == "1":
            mock_map = {
                "build": "tools/winbuild-build.sh",
                "package": "tools/package-nsis.sh",
                "sign": "tools/sign-dev.sh",
                "lint": "tools/winbuild-lint.sh",
                "test": "tools/winbuild-test.sh",
                "smoke": "tools/winebot-smoke.sh",
            }
            if verb in mock_map:
                script = self._tool_path(mock_map[verb])
                # Mock scripts in tests expect standard args
                return [str(script), *args]

        tag = os.environ.get("WBAB_TAG", "v0.2.0")
        project_dir = Path(args[0]) if args else Path(".")
        if not project_dir.is_absolute():
            project_dir = self.root_dir / project_dir
        
        # Determine the image based on the verb
        image = ""
        entrypoint_cmd = ""
        
        if verb in {"lint", "test", "build"}:
            image = f"ghcr.io/sempersupra/winebotappbuilder-winbuild:{tag}"
            entrypoint_cmd = f"wbab-{verb}"
        elif verb == "package":
            image = f"ghcr.io/sempersupra/winebotappbuilder-packager:{tag}"
            entrypoint_cmd = "wbab-package"
        elif verb == "sign":
            image = f"ghcr.io/sempersupra/winebotappbuilder-signer:{tag}"
            entrypoint_cmd = "wbab-sign" # Note: sign-real logic would need to be in the container
        elif verb == "doctor":
            # Doctor is a special case that checks host environment, 
            # but for remote daemon, we check daemon host.
            return [str(self._tool_path("tools/wbab")), "doctor"]
        
        if image:
            # Construct direct docker run command
            docker_cmd = [
                "docker", "run", "--rm",
                "-v", f"{project_dir}:/workspace",
                "-w", "/workspace",
                image,
                entrypoint_cmd
            ]
            # Add any extra args if not the project dir
            if len(args) > 1:
                docker_cmd.extend(args[1:])
            return docker_cmd

        if verb == "smoke":
            if not args:
                raise ValueError("smoke requires installer path argument")
            # Smoke still requires host-side compose orchestration for now
            return [str(self._tool_path("tools/winebot-smoke.sh")), *args]
            
        raise ValueError(f"unsupported verb: {verb}")


def _get_project_root(root_dir: Path) -> Path:
    # If root_dir is 'workspace', project root is parent.
    # Otherwise, assume root_dir is already the project root or we are inside it.
    if root_dir.name == "workspace":
        return root_dir.parent
    return root_dir


def default_store_path(root_dir: Path) -> Path:
    env_path = os.environ.get("WBABD_STORE_PATH")
    if env_path:
        return Path(env_path)
    project_root = _get_project_root(root_dir)
    # Prefer new policy-compliant path
    new_path = project_root / "agent-sandbox" / "state" / "core-store.json"
    if new_path.parent.exists() or (project_root / "agent-sandbox").exists():
        return new_path
    return root_dir / ".wbab" / "core-store.json"


def default_audit_path(root_dir: Path) -> Path:
    env_path = os.environ.get("WBABD_AUDIT_LOG_PATH")
    if env_path:
        return Path(env_path)
    project_root = _get_project_root(root_dir)
    # Prefer new policy-compliant path
    new_path = project_root / "agent-sandbox" / "state" / "audit-log.jsonl"
    if new_path.parent.exists() or (project_root / "agent-sandbox").exists():
        return new_path
    return root_dir / ".wbab" / "audit-log.jsonl"