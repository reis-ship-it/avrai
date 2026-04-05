#!/usr/bin/env bash
set -e

echo "Downloading Phi-4 Mini Instruct (4-bit GGUF Format) for Desktop nodes..."

# Target directory
TARGET_DIR="apps/avrai_app/assets/ml_models/Phi-4-mini-instruct-GGUF"
MODEL_FILE="Phi-4-mini-instruct-Q4_K_M.gguf"

# Create directory if it doesn't exist
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

# Check if already downloaded
if [ -f "$MODEL_FILE" ]; then
    echo "Model $MODEL_FILE already exists in $TARGET_DIR. Skipping download."
    exit 0
fi

echo "Downloading $MODEL_FILE from HuggingFace (~2.8GB)..."

# Using curl to download just the specific GGUF file instead of cloning the whole repo
# as the repo might contain multiple quantizations (Q8, Q4, FP16, etc.) which would be huge.
curl -L -O "https://huggingface.co/unsloth/Phi-4-mini-instruct-GGUF/resolve/main/$MODEL_FILE"

echo "Download complete! The model is ready for the DesktopPhi4LlmBackend."
