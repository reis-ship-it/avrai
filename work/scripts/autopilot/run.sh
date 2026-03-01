#!/usr/bin/env bash
set -euo pipefail

# Single entrypoint for supervised autopilot runs.
python3 autopilot/orchestrator.py run --resume "$@"
