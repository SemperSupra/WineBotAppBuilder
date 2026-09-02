#!/usr/bin/env python3
"""Table-driven contract tests for `wbab plan` JSON output."""

from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parents[2]
WBAB = ROOT_DIR / "tools" / "wbab"
MODE_ENV_VARS = {
    "WBAB_BUILD_MODE",
    "WBAB_BUILD_CMD",
    "WBAB_PACKAGE_MODE",
    "WBAB_PACKAGE_CMD",
    "WBAB_SIGN_MODE",
    "WBAB_SIGN_CMD",
    "WBAB_SIGN_USE_DEV_CERT",
}


def clean_env(extra: dict[str, str] | None = None) -> dict[str, str]:
    env = os.environ.copy()
    for key in MODE_ENV_VARS:
        env.pop(key, None)
    if extra:
        env.update(extra)
    return env


def run_plan(
    verb: str,
    *args: str,
    env: dict[str, str] | None = None,
) -> dict[str, object]:
    proc = subprocess.run(
        [str(WBAB), "plan", verb, *args],
        cwd=ROOT_DIR,
        env=clean_env(env),
        check=False,
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        raise AssertionError(
            f"plan {verb} failed rc={proc.returncode}: {proc.stderr.strip()}"
        )
    try:
        value = json.loads(proc.stdout)
    except json.JSONDecodeError as exc:
        raise AssertionError(f"plan {verb} emitted invalid JSON: {exc}") from exc
    if not isinstance(value, dict):
        raise AssertionError(f"plan {verb} must emit a JSON object")
    return value


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def require_common(plan: dict[str, object], command: str) -> None:
    require(plan.get("version") == "0.1", f"{command}: unexpected plan version")
    require(plan.get("command") == command, f"{command}: wrong command field")
    source = plan.get("source")
    require(isinstance(source, dict), f"{command}: missing source object")
    require(source.get("type") == "local", f"{command}: expected local source")
    steps = plan.get("steps")
    require(isinstance(steps, list) and bool(steps), f"{command}: steps must be non-empty")


def require_project_plan(command: str, expected_policy_keys: set[str]) -> dict[str, object]:
    plan = run_plan(command, ".")
    require_common(plan, command)
    inputs = plan.get("inputs")
    require(isinstance(inputs, dict), f"{command}: missing inputs")
    require(inputs.get("project_dir") == ".", f"{command}: wrong project_dir")
    policy = plan.get("policy")
    require(isinstance(policy, dict), f"{command}: missing policy")
    missing = expected_policy_keys - set(policy)
    require(not missing, f"{command}: missing policy keys {sorted(missing)}")
    return plan


def test_simple_plans() -> None:
    require_project_plan("lint", {"allow_local_build", "toolchain_image", "toolchain_tag"})
    require_project_plan("test", {"allow_local_build", "toolchain_image", "toolchain_tag"})

    smoke = run_plan("smoke", "dist/FakeSetup.exe")
    require_common(smoke, "smoke")
    inputs = smoke.get("inputs")
    require(isinstance(inputs, dict), "smoke: missing inputs")
    require(
        inputs.get("installer") == "dist/FakeSetup.exe",
        "smoke: wrong installer input",
    )
    policy = smoke.get("policy")
    require(isinstance(policy, dict), "smoke: missing policy")
    for key in ("winebot_image", "winebot_tag", "winebot_profile", "winebot_service"):
        require(key in policy, f"smoke: missing policy key {key}")

    doctor = run_plan("doctor")
    require(doctor.get("version") == "0.1", "doctor: unexpected plan version")
    require(doctor.get("command") == "doctor", "doctor: wrong command field")
    steps = doctor.get("steps")
    require(isinstance(steps, list) and bool(steps), "doctor: steps must be non-empty")


def require_mode(
    verb: str,
    expected_mode: str,
    expected_command: str,
    env: dict[str, str] | None = None,
) -> dict[str, object]:
    plan = run_plan(verb, ".", env=env)
    require_common(plan, verb)
    policy = plan.get("policy")
    require(isinstance(policy, dict), f"{verb}: missing policy")
    require(
        policy.get("execution_mode") == expected_mode,
        f"{verb}: expected mode={expected_mode}, got {policy.get('execution_mode')}",
    )
    require(
        policy.get("execution_command") == expected_command,
        f"{verb}: expected command={expected_command}, got {policy.get('execution_command')}",
    )
    return plan


def test_mode_plans() -> None:
    require_mode("build", "real", "wbab-build")
    require_mode("build", "fixture", "wbab-build-fixture", {"WBAB_BUILD_MODE": "fixture"})
    require_mode("build", "custom", "echo custom-build", {"WBAB_BUILD_CMD": "echo custom-build"})

    require_mode("package", "real", "wbab-package")
    require_mode(
        "package",
        "fixture",
        "wbab-package-fixture",
        {"WBAB_PACKAGE_MODE": "fixture"},
    )
    require_mode(
        "package",
        "custom",
        "echo custom-package",
        {"WBAB_PACKAGE_CMD": "echo custom-package"},
    )

    sign = require_mode("sign", "dev-cert", "wbab-sign")
    sign_policy = sign["policy"]
    assert isinstance(sign_policy, dict)
    require("dev_cert_dir" in sign_policy, "sign: missing dev_cert_dir")
    require("dev_cert_autogen" in sign_policy, "sign: missing dev_cert_autogen")
    require_mode("sign", "fixture", "wbab-sign-fixture", {"WBAB_SIGN_MODE": "fixture"})
    require_mode("sign", "custom", "echo custom-sign", {"WBAB_SIGN_CMD": "echo custom-sign"})
    require_mode("sign", "fixture", "wbab-sign-fixture", {"WBAB_SIGN_USE_DEV_CERT": "0"})


def require_rejected(verb: str, env: dict[str, str], expected_fragment: str) -> None:
    proc = subprocess.run(
        [str(WBAB), "plan", verb, "."],
        cwd=ROOT_DIR,
        env=clean_env(env),
        check=False,
        capture_output=True,
        text=True,
    )
    require(proc.returncode == 2, f"{verb}: expected rc=2, got {proc.returncode}")
    require(expected_fragment in proc.stderr, f"{verb}: missing rejection reason {expected_fragment!r}")


def test_fail_closed_modes() -> None:
    require_rejected(
        "build",
        {"WBAB_BUILD_MODE": "fixture", "WBAB_BUILD_CMD": "echo contradiction"},
        "mode=custom",
    )
    require_rejected(
        "package",
        {"WBAB_PACKAGE_MODE": "custom"},
        "requires a command override",
    )
    require_rejected(
        "sign",
        {"WBAB_SIGN_MODE": "fixture", "WBAB_SIGN_USE_DEV_CERT": "1"},
        "conflicts",
    )


def main() -> int:
    test_simple_plans()
    test_mode_plans()
    test_fail_closed_modes()
    print("OK: table-driven wbab plan JSON contracts")
    return 0


if __name__ == "__main__":
    sys.exit(main())
