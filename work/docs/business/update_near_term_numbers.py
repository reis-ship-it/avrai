#!/usr/bin/env python3
"""Update AVRAI_BUDGET_NEAR-TERM.numbers with latest from AVRAI_BUDGET.md and Master Plan.

Source of truth: docs/business/AVRAI_BUDGET.md, docs/MASTER_PLAN.md.
Writes to: ~/Library/Mobile Documents/com~apple~Numbers/Documents/AVRAI_BUDGET_NEAR-TERM.numbers
"""

from pathlib import Path
from numbers_parser import Document

NUMBERS_PATH = Path.home() / "Library/Mobile Documents/com~apple~Numbers/Documents/AVRAI_BUDGET_NEAR-TERM.numbers"


def main():
    if not NUMBERS_PATH.exists():
        print(f"ERROR: File not found: {NUMBERS_PATH}")
        return 1

    doc = Document(str(NUMBERS_PATH))

    # ─── Sheet "All Costs" (index 1) ─────────────────────────────────────────
    all_costs = doc.sheets[1].tables[0]

    # ONE-TIME — Legal & Formation. Align with AVRAI_BUDGET.md (2 LLCs: RG Enterprises AL + AVRAI DE).
    all_costs.write(5, 1, 515)
    all_costs.write(5, 2, 340)
    all_costs.write(5, 3, 690)
    all_costs.write(5, 5, "AL $200 + DE $90. DE agent $50–300 yr1, AL agent $0–100 yr1.")

    all_costs.write(6, 1, 2000)
    all_costs.write(6, 2, 1000)
    all_costs.write(6, 3, 3000)

    all_costs.write(9, 1, 1250)
    all_costs.write(9, 2, 500)
    all_costs.write(9, 3, 2000)

    all_costs.write(10, 1, 1250)
    all_costs.write(10, 2, 500)
    all_costs.write(10, 3, 2000)

    all_costs.write(14, 0, "Google Play Developer")
    all_costs.write(14, 1, 25)
    all_costs.write(14, 2, 25)
    all_costs.write(14, 3, 25)
    all_costs.write(14, 4, "Month 1")
    all_costs.write(14, 5, "One-time. Required for Android distribution.")

    all_costs.write(13, 1, 5190)
    all_costs.write(13, 2, 2390)
    all_costs.write(13, 3, 7990)

    # ONE-TIME — Design & Branding. AVRAI_BUDGET: $3,200–$12,000
    all_costs.write(28, 1, 6100)
    all_costs.write(28, 2, 3200)
    all_costs.write(28, 3, 12000)
    all_costs.write(30, 1, 6100)
    all_costs.write(30, 2, 3200)
    all_costs.write(30, 3, 12000)

    # RECURRING — Resilience/Governance Reserve (Master Plan 10.9.x). Placed after Legal block (row 91+).
    start = 91
    all_costs.write(start, 0, "RECURRING — Resilience/Governance Reserve (Master Plan 10.9.x)")
    all_costs.write(start + 1, 0, "Item")
    all_costs.write(start + 1, 1, "Monthly (Low)")
    all_costs.write(start + 1, 2, "Monthly (High)")
    all_costs.write(start + 1, 3, "18 mo Low")
    all_costs.write(start + 1, 4, "18 mo High")
    all_costs.write(start + 1, 5, "Notes")
    all_costs.write(start + 2, 0, "Observability + reliability tooling")
    all_costs.write(start + 2, 1, 50)
    all_costs.write(start + 2, 2, 300)
    all_costs.write(start + 2, 3, 900)
    all_costs.write(start + 2, 4, 5400)
    all_costs.write(start + 2, 5, "Dashboards/alerts, TTD/TTH, recurrence, impact radius")
    all_costs.write(start + 3, 0, "GitHub CI/check overage")
    all_costs.write(start + 3, 1, 20)
    all_costs.write(start + 3, 2, 150)
    all_costs.write(start + 3, 3, 360)
    all_costs.write(start + 3, 4, 2700)
    all_costs.write(start + 3, 5, "Execution + traceability + ML governance guards")
    all_costs.write(start + 4, 0, "ML retraining/simulation compute")
    all_costs.write(start + 4, 1, 100)
    all_costs.write(start + 4, 2, 600)
    all_costs.write(start + 4, 3, 1800)
    all_costs.write(start + 4, 4, 10800)
    all_costs.write(start + 4, 5, "Burst training/simulation as model scope expands")
    all_costs.write(start + 5, 0, "Data pipeline/storage/egress")
    all_costs.write(start + 5, 1, 25)
    all_costs.write(start + 5, 2, 200)
    all_costs.write(start + 5, 3, 450)
    all_costs.write(start + 5, 4, 3600)
    all_costs.write(start + 5, 5, "Training artifacts, experiment logs, recovery queue")
    all_costs.write(start + 6, 0, "Contingency on reserve (10–15%)")
    all_costs.write(start + 6, 1, 19.5)
    all_costs.write(start + 6, 2, 187.5)
    all_costs.write(start + 6, 3, 351)
    all_costs.write(start + 6, 4, 3375)
    all_costs.write(start + 6, 5, "Buffer for reopen events, remediation loops")
    all_costs.write(start + 7, 0, "TOTAL RESILIENCE RESERVE (18 mo)")
    all_costs.write(start + 7, 1, 214.5)
    all_costs.write(start + 7, 2, 1437.5)
    all_costs.write(start + 7, 3, 3861)
    all_costs.write(start + 7, 4, 25875)
    all_costs.write(start + 7, 5, "Planning reserve; activates as workload grows")

    # ─── Sheet "Milestones" (index 2) — Master Plan phases & durations ─────
    # Rows 4–11 = Phase 1–8, rows 12–14 = Phase 9–11
    milestones = doc.sheets[2].tables[0]
    milestones.write(9, 3, "5-6 wks")   # Phase 6
    milestones.write(10, 3, "6-8 wks")  # Phase 7
    milestones.write(11, 3, "8-10 wks") # Phase 8
    milestones.write(12, 1, "Business Operations & Monetization")
    milestones.write(12, 3, "6-8 wks")  # Phase 9
    milestones.write(13, 1, "Feature Completion, Codebase Reorganization & Polish")
    milestones.write(13, 3, "8-12 wks") # Phase 10
    milestones.write(14, 1, "Industry Integrations & Platform Expansion")
    milestones.write(14, 3, "12-20 wks") # Phase 11

    # ─── Sheet "Summary" (index 3). Rows: 4=header, 5=Personnel, 6=Legal, 7=IP, 8=Design, 9=Hardware, 10=Beta, 11=Tools, 12=Infra, 13=Legal recur ─────
    summary = doc.sheets[3].tables[0]
    summary.write(5, 1, 226083)
    summary.write(5, 2, 183250)
    summary.write(5, 3, 358917)
    summary.write(5, 4, "Founder $0 + ML/mobile/backend fractional + design + compliance")

    summary.write(6, 1, 5190)
    summary.write(6, 2, 2390)
    summary.write(6, 3, 7990)
    summary.write(6, 4, "2 LLCs (RG Enterprises AL + AVRAI DE), legal docs, insurance")

    summary.write(7, 1, 21000)
    summary.write(7, 2, 12000)
    summary.write(7, 3, 30000)
    summary.write(7, 4, "5 provisionals (defer 3-5 if tight)")

    summary.write(8, 1, 6100)
    summary.write(8, 2, 3200)
    summary.write(8, 3, 12000)
    summary.write(8, 4, "UI/UX system + logo")

    summary.write(10, 1, 2000)
    summary.write(10, 2, 500)
    summary.write(10, 3, 5500)
    summary.write(10, 4, "User recruitment, landing page")

    summary.write(11, 1, 68477)
    summary.write(11, 2, 68477)
    summary.write(11, 3, 94352)
    summary.write(11, 4, "Cursor Ultra + Extra Credits + Bugbot, GitHub, Claude, Workspace, Apple. High includes resilience reserve (10.9.x).")

    doc.save(str(NUMBERS_PATH))
    print(f"Updated: {NUMBERS_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
