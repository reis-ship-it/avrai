#!/usr/bin/env python3
import argparse
import os
import re
import subprocess
import sys

PRD_PATTERN = re.compile(r"\bPRD-\d{3}\b")
MILESTONE_PATTERN = re.compile(r"\bM\d+-P\d+-\d+\b")
MASTER_PLAN_REF_PATTERN = re.compile(r"\b\d+\.\d+\.\d+\b")


def fail(msg: str) -> None:
    print(f"TRACEABILITY CHECK FAILED: {msg}")
    sys.exit(1)


def run_git(*args: str) -> str:
    result = subprocess.run(
        ["git", *args],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        fail(
            "Git command failed: "
            + " ".join(args)
            + f"\nstdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )
    return result.stdout.strip()


def validate_commit_boundaries(
    base_sha: str,
    head_sha: str,
    required_milestone: str,
) -> None:
    if not base_sha or not head_sha:
        fail(
            "Missing PR base/head SHAs for commit boundary validation. "
            "Set --base-sha and --head-sha."
        )

    commit_list = run_git("rev-list", "--reverse", f"{base_sha}..{head_sha}")
    if not commit_list:
        fail("No commits found in PR range for boundary validation.")

    failures: list[str] = []
    non_merge_commits = 0

    for sha in commit_list.splitlines():
        parents_line = run_git("rev-list", "--parents", "-n", "1", sha)
        # parents_line format: "<sha> <parent1> [parent2 ...]"
        # Skip merge commits to avoid forcing metadata on branch sync commits.
        if len(parents_line.split()) > 2:
            continue

        non_merge_commits += 1
        message = run_git("log", "--format=%B", "-n", "1", sha)
        commit_milestones = sorted(set(MILESTONE_PATTERN.findall(message)))
        commit_refs = sorted(set(MASTER_PLAN_REF_PATTERN.findall(message)))

        if not commit_milestones:
            failures.append(
                f"{sha[:8]} missing milestone ID (expected {required_milestone})."
            )
        elif required_milestone not in commit_milestones:
            failures.append(
                f"{sha[:8]} milestone mismatch: found {', '.join(commit_milestones)}; "
                f"expected {required_milestone}."
            )
        elif len(commit_milestones) != 1:
            failures.append(
                f"{sha[:8]} has multiple milestone IDs: {', '.join(commit_milestones)}. "
                "Each non-merge commit must target exactly one milestone."
            )

        if not commit_refs:
            failures.append(
                f"{sha[:8]} missing Master Plan subsection reference (expected X.Y.Z)."
            )

    if non_merge_commits == 0:
        fail("No non-merge commits found in PR range for boundary validation.")

    if failures:
        fail("Commit boundary validation failed:\n- " + "\n- ".join(failures))


def main() -> None:
    parser = argparse.ArgumentParser(description="Validate PR traceability metadata.")
    parser.add_argument("--title", default=os.getenv("PR_TITLE", ""), help="PR title")
    parser.add_argument("--body", default=os.getenv("PR_BODY", ""), help="PR body")
    parser.add_argument(
        "--require-execution-id",
        action="store_true",
        help="Require execution board milestone identifier (Mx-Py-z).",
    )
    parser.add_argument(
        "--require-single-milestone",
        action="store_true",
        help="Require exactly one milestone ID in PR title/body.",
    )
    parser.add_argument(
        "--require-master-plan-ref",
        action="store_true",
        help="Require at least one Master Plan subsection reference (X.Y.Z).",
    )
    parser.add_argument(
        "--validate-commit-boundaries",
        action="store_true",
        help=(
            "Validate every non-merge commit in the PR includes exactly one milestone ID "
            "matching the PR milestone and at least one X.Y.Z reference."
        ),
    )
    parser.add_argument(
        "--base-sha",
        default=os.getenv("PR_BASE_SHA", ""),
        help="PR base commit SHA (required for --validate-commit-boundaries).",
    )
    parser.add_argument(
        "--head-sha",
        default=os.getenv("PR_HEAD_SHA", ""),
        help="PR head commit SHA (required for --validate-commit-boundaries).",
    )
    args = parser.parse_args()

    title_text = args.title.strip()
    body_text = args.body.strip()
    text = (title_text + "\n" + body_text).strip()
    if not text:
        fail("No PR title/body provided.")

    prd_ids = sorted(set(PRD_PATTERN.findall(text)))
    milestone_ids_in_title = sorted(set(MILESTONE_PATTERN.findall(title_text)))
    milestone_ids_in_body = sorted(set(MILESTONE_PATTERN.findall(body_text)))
    master_plan_refs = sorted(set(MASTER_PLAN_REF_PATTERN.findall(text)))

    if not prd_ids:
        fail("Missing PRD requirement ID (expected format: PRD-###).")

    if args.require_execution_id:
        if not milestone_ids_in_title:
            fail(
                "Missing execution milestone ID in PR title "
                "(expected format: Mx-Py-z)."
            )

    if args.require_single_milestone and len(milestone_ids_in_title) != 1:
        fail(
            "Expected exactly one execution milestone ID (Mx-Py-z) in PR title, "
            f"found {len(milestone_ids_in_title)}."
        )

    if args.require_master_plan_ref and not master_plan_refs:
        fail("Missing Master Plan subsection reference (expected format: X.Y.Z).")

    if args.validate_commit_boundaries:
        if len(milestone_ids_in_title) != 1:
            fail(
                "Commit boundary validation requires exactly one PR milestone ID "
                "(Mx-Py-z) in PR title."
            )
        validate_commit_boundaries(
            base_sha=args.base_sha.strip(),
            head_sha=args.head_sha.strip(),
            required_milestone=milestone_ids_in_title[0],
        )

    print("Traceability check passed.")
    print("Found PRD IDs:", ", ".join(prd_ids))
    if milestone_ids_in_title:
        print("Found PR Title Milestone IDs:", ", ".join(milestone_ids_in_title))
    if milestone_ids_in_body:
        print("Found PR Body Milestone IDs:", ", ".join(milestone_ids_in_body))
    if master_plan_refs:
        print("Found Master Plan Refs:", ", ".join(master_plan_refs))


if __name__ == "__main__":
    main()
