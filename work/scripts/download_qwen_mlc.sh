#!/usr/bin/env bash
set -e

echo "Downloading pre-compiled Qwen 2.5 3B Instruct (4-bit MLC Format)..."

# Ensure git LFS is installed
if ! command -v git-lfs &> /dev/null; then
    echo "git-lfs could not be found. Please install it first: brew install git-lfs"
    exit 1
fi

git lfs install

# Target directory
TARGET_DIR="apps/avrai_app/assets/ml_models/Qwen2.5-3B-Instruct-q4f16_1-MLC"

# Create directory if it doesn't exist
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

# Check if already downloaded
if [ -f "mlc-chat-config.json" ]; then
    echo "Model config already exists in $TARGET_DIR. Skipping download."
    echo "To redownload, delete the folder first."
    exit 0
fi

echo "Cloning repository from HuggingFace. This will download ~2.2GB of data..."
git clone https://huggingface.co/mlc-ai/Qwen2.5-3B-Instruct-q4f16_1-MLC .

echo "Download complete! The model is ready for the MlcLlmBackend."
