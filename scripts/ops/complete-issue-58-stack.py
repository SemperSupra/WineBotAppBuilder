#!/usr/bin/env python3
"""Complete the #58 corrective PR stack with deterministic GitHub CLI actions."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import time
from dataclasses import dataclass
from typing import Any

REPO = "SemperSupra/WineBotAppBuilder"
TRACKER = 58
PARENT_PR = 59
CHILD_PR = 60
PARENT_BRANCH = "corrective/testing-capability-qualification"
EXPECTED_MAIN = "bd79d45ba20cc70cae9da7625c6b3605c7176655"
EXPECTED_PARENT_HEAD = "7a075f729257601d15f527b3686bab736cf68095"
CI_WORKFLOW = "ci.yml"
PRODUCT_WORKFLOW = "product-qualification.yml"
CI_TIMEOUT_SECONDS = 20 * 60
PRODUCT_TIMEOUT_SECONDS = 55 * 60
RUN_DISCOVERY_TIMEOUT_SECONDS = 3 * 60


class WorksetError(RuntimeError):
    """Stop condition for drift, failed evidence, or unsupported authority."""


@dataclass(frozen=True)
class PullRequestState:
    number: int
    state: str
    is_draft: bool
    head_sha: str
    base_ref: str
    mergeable: str
    review_decision: str | None
    url: str


def run(
    args: list[str],
    *,
    check: bool = True,
    timeout: int | None = 120,
    input_text: str | None = None,
) -> subprocess.CompletedProcess[str]:
    proc = subprocess.run(
        args,
        check=False,
        text=True,
        input=input_text,
        capture_output=True,
        timeout=timeout,
    )
    if check and proc.returncode != 0:
        detail = proc.stderr.strip() or proc.stdout.strip() or f"exit {proc.returncode}"
        raise WorksetError(f"{' '.join(args)} failed: {detail}")
    return proc


def gh_json(args: list[str]) -> Any:
    proc = run(["gh", *args])
    return json.loads(proc.stdout)


def current_main_sha() -> str:
    data = gh_json(["api", f"repos/{REPO}/branches/main"])
    return str(data["commit"]["sha"])


def pr_state(number: int) -> PullRequestState:
    data = gh_json(
        [
            "pr",
            "view",
            str(number),
            "--repo",
            REPO,
            "--json",
            "number,state,isDraft,headRefOid,baseRefName,mergeable,reviewDecision,url",
        ]
    )
    return PullRequestState(
        number=int(data["number"]),
        state=str(data["state"]),
        is_draft=bool(data["isDraft"]),
        head_sha=str(data["headRefOid"]),
        base_ref=str(data["baseRefName"]),
        mergeable=str(data["mergeable"]),
        review_decision=data.get("reviewDecision"),
        url=str(data["url"]),
    )


def unresolved_review_threads(number: int) -> int:
    owner, name = REPO.split("/", 1)
    query = """
query($owner:String!, $name:String!, $number:Int!) {
  repository(owner:$owner, name:$name) {
    pullRequest(number:$number) {
      reviewThreads(first:100) {
        nodes { isResolved }
      }
    }
  }
}
"""
    data = gh_json(
        [
            "api",
            "graphql",
            "-f",
            f"query={query}",
            "-F",
            f"owner={owner}",
            "-F",
            f"name={name}",
            "-F",
            f"number={number}",
        ]
    )
    nodes = data["data"]["repository"]["pullRequest"]["reviewThreads"]["nodes"]
    return sum(1 for node in nodes if not node["isResolved"])


def require_open_pr(
    pr: PullRequestState,
    *,
    expected_head: str | None = None,
    expected_base: str | None = None,
) -> None:
    if pr.state != "OPEN":
        raise WorksetError(f"PR #{pr.number} is {pr.state}, expected OPEN")
    if expected_head is not None and pr.head_sha != expected_head:
        raise WorksetError(
            f"PR #{pr.number} head drift: expected {expected_head}, found {pr.head_sha}"
        )
    if expected_base is not None and pr.base_ref != expected_base:
        raise WorksetError(
            f"PR #{pr.number} base drift: expected {expected_base}, found {pr.base_ref}"
        )
    if pr.review_decision == "CHANGES_REQUESTED":
        raise WorksetError(f"PR #{pr.number} has CHANGES_REQUESTED")
    unresolved = unresolved_review_threads(pr.number)
    if unresolved:
        raise WorksetError(
            f"PR #{pr.number} has {unresolved} unresolved review thread(s)"
        )


def mark_ready(pr: PullRequestState, *, execute: bool) -> None:
    if not pr.is_draft:
        return
    if not execute:
        print(f"DRY-RUN: gh pr ready {pr.number} --repo {REPO}")
        return
    run(["gh", "pr", "ready", str(pr.number), "--repo", REPO])


def wait_for_pr_checks(
    number: int, *, execute: bool, timeout_seconds: int = CI_TIMEOUT_SECONDS
) -> None:
    if not execute:
        print(f"DRY-RUN: wait for PR #{number} checks (timeout={timeout_seconds}s)")
        return
    run(
        [
            "gh",
            "pr",
            "checks",
            str(number),
            "--repo",
            REPO,
            "--watch",
            "--fail-fast",
            "--interval",
            "10",
        ],
        timeout=timeout_seconds,
    )


def latest_workflow_run_id(workflow: str, branch: str) -> int:
    runs = gh_json(
        [
            "run",
            "list",
            "--repo",
            REPO,
            "--workflow",
            workflow,
            "--branch",
            branch,
            "--event",
            "pull_request",
            "--limit",
            "10",
            "--json",
            "databaseId",
        ]
    )
    return max((int(item["databaseId"]) for item in runs), default=0)


def wait_for_new_workflow_run(
    workflow: str,
    branch: str,
    previous_run_id: int,
    *,
    timeout_seconds: int,
    execute: bool,
) -> int:
    if not execute:
        print(
            f"DRY-RUN: wait for new {workflow} run on {branch} "
            f"newer than {previous_run_id}"
        )
        return 0

    deadline = time.monotonic() + RUN_DISCOVERY_TIMEOUT_SECONDS
    while time.monotonic() < deadline:
        run_id = latest_workflow_run_id(workflow, branch)
        if run_id > previous_run_id:
            run(
                [
                    "gh",
                    "run",
                    "watch",
                    str(run_id),
                    "--repo",
                    REPO,
                    "--exit-status",
                    "--interval",
                    "10",
                ],
                timeout=timeout_seconds,
            )
            return run_id
        time.sleep(5)

    raise WorksetError(
        f"no new {workflow} pull-request run appeared on {branch} "
        f"after run {previous_run_id}"
    )


def require_latest_workflow_success(
    workflow: str,
    branch: str,
    *,
    timeout_seconds: int,
    execute: bool,
) -> int:
    run_id = latest_workflow_run_id(workflow, branch)
    if not run_id:
        raise WorksetError(f"no {workflow} pull-request run found on {branch}")
    if not execute:
        print(f"DRY-RUN: require latest {workflow} run {run_id} on {branch} to pass")
        return run_id
    run(
        [
            "gh",
            "run",
            "watch",
            str(run_id),
            "--repo",
            REPO,
            "--exit-status",
            "--interval",
            "10",
        ],
        timeout=timeout_seconds,
    )
    return run_id


def wait_for_mergeability(number: int, expected_head: str) -> PullRequestState:
    last = pr_state(number)
    for _ in range(12):
        require_open_pr(last, expected_head=expected_head)
        if last.mergeable != "UNKNOWN":
            return last
        time.sleep(5)
        last = pr_state(number)
    raise WorksetError(f"PR #{number} mergeability remained UNKNOWN")


def merge_pr(number: int, expected_head: str, *, execute: bool) -> None:
    current = pr_state(number)
    if current.state == "MERGED":
        return
    require_open_pr(current, expected_head=expected_head)
    if current.mergeable == "CONFLICTING":
        raise WorksetError(f"PR #{number} is conflicting")
    if not execute:
        print(
            "DRY-RUN: "
            f"gh pr merge {number} --repo {REPO} --squash "
            f"--match-head-commit {expected_head}"
        )
        return
    run(
        [
            "gh",
            "pr",
            "merge",
            str(number),
            "--repo",
            REPO,
            "--squash",
            "--match-head-commit",
            expected_head,
        ],
        timeout=180,
    )


def tracker_comment(body: str, *, execute: bool) -> None:
    if not execute:
        print("DRY-RUN tracker comment:")
        print(body)
        return
    run(
        ["gh", "issue", "comment", str(TRACKER), "--repo", REPO, "--body-file", "-"],
        input_text=body,
    )


def success_comment(
    main_before: str,
    main_after: str,
    child_head: str,
    combined_parent_head: str,
    ci_run: int,
    product_run: int,
) -> str:
    return f"""## #58 deterministic stack integration — completed

Executor: repository-native local script (`scripts/ops/complete-issue-58-stack.py`)
Authority source: maintainer delegation recorded in the #58 workset baton.
Execution mode: deterministic `gh` CLI; no UI/manual maintainer step.

- initial main: `{main_before}`
- PR #60 head `{child_head}`: squash-merged into parent branch `{PARENT_BRANCH}`
- combined PR #59 head: `{combined_parent_head}`
- combined-head CI run: `{ci_run}` — passed
- combined-head Product Qualification run: `{product_run}` — passed
- PR #59: squash-merged to `main`
- final main: `{main_after}`
- release/publication performed: **no**
- production signing credentials used: **no**

The child-first integration preserves stacked ancestry until the complete candidate is
revalidated, then produces one final squash on `main`. The script fails closed on drift,
failed/missing checks, changes requested, unresolved review threads, conflicts, or an
unexpected authority state.
"""


def failure_comment(stage: str, error: Exception) -> str:
    message = str(error).replace("`", "'")
    return f"""## #58 deterministic stack integration — stopped fail-closed

Executor: `scripts/ops/complete-issue-58-stack.py`
Stage: `{stage}`
Reason: `{message}`

No release/publication or production-signing action was authorized by this workset.
Refresh durable PR/main state before retrying; do not substitute a manual UI click merely
because this deterministic path stopped.
"""


def execute_workset(*, execute: bool, expected_child_head: str) -> None:
    main_before = current_main_sha()
    parent = pr_state(PARENT_PR)
    child = pr_state(CHILD_PR)

    if parent.state == "MERGED":
        if child.state != "MERGED":
            raise WorksetError("PR #59 is merged while PR #60 is not merged")
        print("#58 stack is already integrated; no mutation required")
        return

    if main_before != EXPECTED_MAIN:
        raise WorksetError(
            f"main drift before integration: expected {EXPECTED_MAIN}, found {main_before}"
        )

    require_open_pr(parent, expected_base="main")

    child_was_open = child.state == "OPEN"
    if child_was_open:
        if parent.head_sha != EXPECTED_PARENT_HEAD:
            raise WorksetError(
                "parent head changed before child integration: "
                f"expected {EXPECTED_PARENT_HEAD}, found {parent.head_sha}"
            )
        require_open_pr(
            child,
            expected_head=expected_child_head,
            expected_base=PARENT_BRANCH,
        )

        previous_ci = latest_workflow_run_id(CI_WORKFLOW, PARENT_BRANCH)
        previous_product = latest_workflow_run_id(PRODUCT_WORKFLOW, PARENT_BRANCH)

        mark_ready(child, execute=execute)
        wait_for_pr_checks(CHILD_PR, execute=execute)
        if execute:
            child = wait_for_mergeability(CHILD_PR, expected_child_head)
            if child.mergeable == "CONFLICTING":
                raise WorksetError("PR #60 is conflicting")
        merge_pr(CHILD_PR, expected_child_head, execute=execute)

        if not execute:
            print(
                "DRY-RUN: after PR #60 merges into its parent branch, discover the new "
                "PR #59 head, require fresh CI + Product Qualification, then merge #59"
            )
            return

        child = pr_state(CHILD_PR)
        if child.state != "MERGED":
            raise WorksetError("PR #60 did not reach MERGED")

        parent = pr_state(PARENT_PR)
        require_open_pr(parent, expected_base="main")
        if parent.head_sha == EXPECTED_PARENT_HEAD:
            raise WorksetError("PR #59 head did not advance after merging PR #60")
        combined_parent_head = parent.head_sha

        ci_run = wait_for_new_workflow_run(
            CI_WORKFLOW,
            PARENT_BRANCH,
            previous_ci,
            timeout_seconds=CI_TIMEOUT_SECONDS,
            execute=True,
        )
        product_run = wait_for_new_workflow_run(
            PRODUCT_WORKFLOW,
            PARENT_BRANCH,
            previous_product,
            timeout_seconds=PRODUCT_TIMEOUT_SECONDS,
            execute=True,
        )
    elif child.state == "MERGED":
        if child.head_sha != expected_child_head:
            raise WorksetError(
                f"merged PR #60 head drift: expected {expected_child_head}, "
                f"found {child.head_sha}"
            )
        combined_parent_head = parent.head_sha
        ci_run = require_latest_workflow_success(
            CI_WORKFLOW,
            PARENT_BRANCH,
            timeout_seconds=CI_TIMEOUT_SECONDS,
            execute=execute,
        )
        product_run = require_latest_workflow_success(
            PRODUCT_WORKFLOW,
            PARENT_BRANCH,
            timeout_seconds=PRODUCT_TIMEOUT_SECONDS,
            execute=execute,
        )
    else:
        raise WorksetError(f"PR #60 is {child.state}, expected OPEN or MERGED")

    require_open_pr(
        pr_state(PARENT_PR),
        expected_head=combined_parent_head,
        expected_base="main",
    )
    wait_for_pr_checks(
        PARENT_PR,
        execute=execute,
        timeout_seconds=PRODUCT_TIMEOUT_SECONDS,
    )
    parent = pr_state(PARENT_PR)
    mark_ready(parent, execute=execute)

    if execute:
        parent = wait_for_mergeability(PARENT_PR, combined_parent_head)
        if parent.mergeable == "CONFLICTING":
            raise WorksetError("PR #59 is conflicting after child integration")
    merge_pr(PARENT_PR, combined_parent_head, execute=execute)

    if not execute:
        return

    parent = pr_state(PARENT_PR)
    if parent.state != "MERGED":
        raise WorksetError("PR #59 did not reach MERGED")
    main_after = current_main_sha()
    if main_after == main_before:
        raise WorksetError("main did not advance after merging PR #59")

    tracker_comment(
        success_comment(
            main_before,
            main_after,
            expected_child_head,
            combined_parent_head,
            ci_run,
            product_run,
        ),
        execute=True,
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Complete the exact #58 PR #59/#60 integration stack."
    )
    parser.add_argument(
        "--execute",
        action="store_true",
        help="Perform mutations. Without this flag the script prints the planned actions.",
    )
    parser.add_argument(
        "--expected-child-head",
        help="Exact PR #60 head from the durable #58 baton. Required with --execute.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.execute and not args.expected_child_head:
        print(
            "ERROR: --expected-child-head is required with --execute", file=sys.stderr
        )
        return 2

    try:
        run(["gh", "auth", "status", "--hostname", "github.com"], timeout=30)
        child_head = args.expected_child_head or pr_state(CHILD_PR).head_sha
        execute_workset(execute=args.execute, expected_child_head=child_head)
    except (WorksetError, subprocess.TimeoutExpired, json.JSONDecodeError) as exc:
        if args.execute:
            try:
                tracker_comment(failure_comment("execution", exc), execute=True)
            except Exception:
                pass
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
