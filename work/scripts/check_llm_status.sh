#!/usr/bin/env bash
# Check if BERT-SQuAD and Llama (local LLM) model files exist and report status.
# For full runtime status (prefs, active pack), use the app: Settings → On-Device AI.
#
# Usage: ./scripts/check_llm_status.sh

set -e

BERT_DEV="${HOME}/AVRAI/models/macos/BERTSQUADFP16.mlmodel"
APP_SUPPORT="${HOME}/Library/Application Support"

echo "=== BERT-SQuAD ==="
if [[ -f "$BERT_DEV" ]]; then
  echo "  OK: $BERT_DEV"
else
  echo "  MISSING: $BERT_DEV"
  echo "  See: docs/macos_llm_integration/BERT_SQUAD_SETUP_COMPLETE.md"
fi

echo ""
echo "=== Llama (local LLM) ==="
FOUND=0
if [[ -d "$APP_SUPPORT" ]]; then
  for d in $(find "$APP_SUPPORT" -maxdepth 4 -type d -name "local_llm_packs" 2>/dev/null | head -5); do
    echo "  Found pack dir: $d"
    FOUND=1
  done
fi
if [[ $FOUND -eq 0 ]]; then
  echo "  No local_llm_packs dirs found under Application Support."
  echo "  Install via: Settings → On-Device AI → Download/Install"
fi

echo ""
echo "=== Prefs (in-app only) ==="
echo "  Run the app and open Settings → On-Device AI to see:"
echo "  - offline_llm_enabled_v1, local_llm_active_model_dir_v1, local_llm_active_model_id_v1"
echo "  - Local LLM & BERT status card"
