#!/usr/bin/env bash
set -euo pipefail

# Generates a standalone release archive of the VioletHUD suite.
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT="${1:-$REPO_DIR/VioletHUD-release.tar.gz}"

echo "Building release package: $OUTPUT"
tar -C "$REPO_DIR" \
    --exclude='.git' \
    --exclude='*.tar.gz' \
    --exclude='*.bak' \
    --exclude='*~' \
    -czf "$OUTPUT" .

echo "Build complete: $(ls -lh "$OUTPUT" | awk '{print $5, $9}')"
