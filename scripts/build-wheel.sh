#!/usr/bin/env bash
# Build a Linux wheel with podman using the repo Containerfile.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

IMAGE_TAG="${IMAGE_TAG:-context-server-wheel}"
OUT_DIR="${OUT_DIR:-$root/dist}"

mkdir -p "$OUT_DIR"

echo "Building wheel image..."
podman build \
  -t "$IMAGE_TAG" \
  -f Containerfile \
  .

cid="$(podman create "$IMAGE_TAG")"
cleanup() { podman rm -f "$cid" >/dev/null 2>&1 || true; }
trap cleanup EXIT

podman cp "$cid:/out/." "$OUT_DIR/"
echo "Wheels written to $OUT_DIR:"
ls -la "$OUT_DIR"
