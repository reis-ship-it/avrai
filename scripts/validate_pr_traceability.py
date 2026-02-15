#!/usr/bin/env python3
import argparse
import os
import re
import sys

PRD_PATTERN = re.compile(r"\bPRD-\d{3}\b")
CARD_PATTERN = re.compile(r"\bCARD-\d+\b")
MILESTONE_PATTERN = re.compile(r"\bM\d+-P\d+-\d+\b")


def fail(msg: str) -> None:
    print(f"TRACEABILITY CHECK FAILED: {msg}")
    sys.exit(1)


def main() -> None:
    parser = argparse.ArgumentParser(description="Validate PR traceability metadata.")
    parser.add_argument("--title", default=os.getenv("PR_TITLE", ""), help="PR title")
    parser.add_argument("--body", default=os.getenv("PR_BODY", ""), help="PR body")
    parser.add_argument(
        "--require-execution-id",
        action="store_true",
        help="Require execution board identifier (milestone or legacy card)",
    )
    parser.add_argument(
        "--allow-legacy-card",
        action="store_true",
        help="Allow legacy CARD-<number> IDs to satisfy execution ID requirement",
    )
    args = parser.parse_args()

    text = (args.title + "\n" + args.body).strip()
    if not text:
        fail("No PR title/body provided.")

    prd_ids = sorted(set(PRD_PATTERN.findall(text)))
    card_ids = sorted(set(CARD_PATTERN.findall(text)))
    milestone_ids = sorted(set(MILESTONE_PATTERN.findall(text)))

    if not prd_ids:
        fail("Missing PRD requirement ID (expected format: PRD-###).")

    if args.require_execution_id:
        has_execution_id = bool(milestone_ids) or (
            args.allow_legacy_card and bool(card_ids)
        )
        if not has_execution_id:
            fail(
                "Missing execution board ID (expected format: Mx-Py-z; "
                "legacy CARD-<number> allowed only when configured)."
            )

    print("Traceability check passed.")
    print("Found PRD IDs:", ", ".join(prd_ids))
    if milestone_ids:
        print("Found Milestone IDs:", ", ".join(milestone_ids))
    if card_ids:
        print("Found Legacy Card IDs:", ", ".join(card_ids))


if __name__ == "__main__":
    main()
