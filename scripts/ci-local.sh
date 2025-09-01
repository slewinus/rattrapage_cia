#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "[CI] Running local pipeline (build → start → test → stop)"
trap 'echo "[CI] Cleanup..."; make -s stop || true' EXIT

make -s ci

echo "[CI] Done."
