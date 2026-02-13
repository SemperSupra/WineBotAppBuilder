#!/usr/bin/env python3
"""Minimal core baseline for WBAB: planner + executor + idempotent store."""

from __future__ import annotations

import fcntl
import json
import os
import uuid
import subprocess
import time
import tempfile
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional


@dataclass
class Plan:
    op_id: str
    verb: str
    args: List[str]
    steps: List[Dict[str, Any]]


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
    SCHEMA_VERSION = "wbab.store.v1"
    LEGACY_SCHEMA = "legacy.unversioned"

    def __init__(self, path: Path) -> None:
        self.path = path
        self.path.parent.mkdir(parents=True, exist_ok=True)
        # Ensure file exists
        if not self.path.exists():
            # Atomic creation if possible, or simple write with lock
            with open(self.path, "w") as f:
                try:
                    fcntl.flock(f, fcntl.LOCK_EX)
                    f.write(json.dumps(self._new_store(), indent=2, sort_keys=True) + "\n")
                finally:
                    fcntl.flock(f, fcntl.LOCK_UN)
        else:
            # Migration check under lock
            with open(self.path, "r+") as f:
                try:
                    fcntl.flock(f, fcntl.LOCK_EX)
                    content = f.read()
                    data = json.loads(content) if content else self._new_store()
                    migrated = self._migrate(data)
                    if migrated != data:
                        f.seek(0)
                        f.truncate()
                        f.write(json.dumps(migrated, indent=2, sort_keys=True) + "\n")
                finally:
                    fcntl.flock(f, fcntl.LOCK_UN)

    def _new_store(self) -> Dict[str, Any]:
        return {
            "schema_version": self.SCHEMA_VERSION,
            "operations": {},
        }

    def _now_iso(self) -> str:
        return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")

    def _schema_of(self, data: Dict[str, Any]) -> str:
        schema = data.get("schema_version")
        if isinstance(schema, str) and schema.strip():
            return schema
        return self.LEGACY_SCHEMA

    def _migrate(self, data: Dict[str, Any]) -> Dict[str, Any]:
        schema = self._schema_of(data)
        if schema == self.SCHEMA_VERSION:
            normalized = dict(data)
            if not isinstance(normalized.get("operations"), dict):
                normalized["operations"] = {}
            return normalized
        if schema == self.LEGACY_SCHEMA:
            return {
                "schema_version": self.SCHEMA_VERSION,
                "operations": data.get("operations", {}) if isinstance(data.get("operations"), dict) else {},
                "migration": {
                    "from_schema": self.LEGACY_SCHEMA,
                    "migrated_at": self._now_iso(),
                },
            }
        raise ValueError(f"unsupported store schema: {schema}")

    def get(self, op_id: str) -> Dict[str, Any] | None:
        with open(self.path, "r") as f:
            try:
                fcntl.flock(f, fcntl.LOCK_SH)
                content = f.read()
                data = json.loads(content) if content else self._new_store()
                data = self._migrate(data)
                return data.get("operations", {}).get(op_id)
            finally:
                fcntl.flock(f, fcntl.LOCK_UN)

    def upsert(self, op_id: str, payload: Dict[str, Any]) -> None:
        with open(self.path, "r+") as f:
            try:
                fcntl.flock(f, fcntl.LOCK_EX)
                content = f.read()
                data = json.loads(content) if content else self._new_store()
                data = self._migrate(data)
                data.setdefault("operations", {})[op_id] = payload
                f.seek(0)
                f.truncate()
                f.write(json.dumps(data, indent=2, sort_keys=True) + "\n")
            finally:
                fcntl.flock(f, fcntl.LOCK_UN)


class AuditLog:
    """Append-only JSONL audit log for command/event traceability."""

    SCHEMA_VERSION = "wbab.audit.v1"

    def __init__(self, path: Path, source: str = "wbabd") -> None:
        self.path = path
        self.source = source
        self.path.parent.mkdir(parents=True, exist_ok=True)

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
        payload: Dict[str, Any] = {
            "schema_version": self.SCHEMA_VERSION,
            "event_id": str(uuid.uuid4()),
            "ts": self._now(),
            "source": self.source,
            "actor": os.environ.get("WBABD_ACTOR", "unknown"),
            "session_id": os.environ.get("WBABD_SESSION_ID", ""),
            "event_type": event_type,
            "op_id": op_id,
            "verb": verb,
        }
        if status:
            payload["status"] = status
        if step:
            payload["step"] = step
        if details:
            payload["details"] = details
        with self.path.open("a", encoding="utf-8") as f:
            f.write(json.dumps(payload, sort_keys=True) + "\n")


class Planner:
    def plan(self, op_id: str, verb: str, args: List[str]) -> Plan:
        if verb not in {"build", "package", "sign", "smoke", "doctor", "lint", "test"}:
            raise ValueError(f"unsupported verb: {verb}")
        return Plan(
            op_id=op_id,
            verb=verb,
            args=args,
            steps=[
                {"name": "validate_inputs"},
                {"name": f"execute_{verb}"},
                {"name": "record_result"},
            ],
        )


class Executor:
    def __init__(self, root_dir: Path, store: OperationStore, audit: AuditLog | None = None) -> None:
        self.root_dir = root_dir
        self.store = store
        self.audit = audit

    def _tool_path(self, rel: str) -> Path:
        return self.root_dir / rel

    def _run(self, cmd: List[str]) -> subprocess.CompletedProcess[str]:
        """Runs a command and streams output to a temporary file to avoid OOM."""
        with tempfile.NamedTemporaryFile(mode="w+", delete=False, prefix="wbab-log-") as tmp:
            tmp_path = tmp.name
            try:
                proc = subprocess.run(
                    cmd,
                    cwd=self.root_dir,
                    stdout=tmp,
                    stderr=subprocess.STDOUT,
                    text=True,
                    check=False
                )
                tmp.seek(0)
                # Capture the full log but return it in the result. 
                # In extremely high-scale scenarios, we might only return the tail.
                output = tmp.read()
                return subprocess.CompletedProcess(
                    args=cmd,
                    returncode=proc.returncode,
                    stdout=output,
                    stderr=""
                )
            finally:
                if os.path.exists(tmp_path):
                    os.remove(tmp_path)

    def _now(self) -> int:
        return int(time.time())

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
        project_dir = Path(plan.args[0]) if plan.args else Path(".")
        if not project_dir.is_absolute():
            project_dir = self.root_dir / project_dir

        # Step 0: Robust Cache Validation
        existing = self.store.get(plan.op_id)
        if existing and existing.get("status") == "succeeded":
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
            with WorkspaceLock(project_dir):
                return self._run_operation(plan, existing)
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
            op = existing
            op["verb"] = plan.verb
            op["args"] = plan.args
            op["steps"] = plan.steps
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

    def _command_for(self, verb: str, args: List[str]) -> List[str]:
        if verb == "lint":
            return [str(self._tool_path("tools/winbuild-lint.sh")), *(args or ["."])]
        if verb == "test":
            return [str(self._tool_path("tools/winbuild-test.sh")), *(args or ["."])]
        if verb == "build":
            return [str(self._tool_path("tools/winbuild-build.sh")), *(args or ["."])]
        if verb == "package":
            return [str(self._tool_path("tools/package-nsis.sh")), *(args or ["."])]
        if verb == "sign":
            return [str(self._tool_path("tools/sign-dev.sh")), *(args or ["."])]
        if verb == "smoke":
            if not args:
                raise ValueError("smoke requires installer path argument")
            return [str(self._tool_path("tools/winebot-smoke.sh")), *args]
        if verb == "doctor":
            return [str(self._tool_path("tools/wbab")), "doctor"]
        raise ValueError(f"unsupported verb: {verb}")


def default_store_path(root_dir: Path) -> Path:
    env_path = os.environ.get("WBABD_STORE_PATH")
    if env_path:
        return Path(env_path)
    return root_dir / ".wbab" / "core-store.json"


def default_audit_path(root_dir: Path) -> Path:
    env_path = os.environ.get("WBABD_AUDIT_LOG_PATH")
    if env_path:
        return Path(env_path)
    return root_dir / ".wbab" / "audit-log.jsonl"