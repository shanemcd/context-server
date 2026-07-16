#!/usr/bin/env bash
# Build a Linux wheel with podman using the repo Containerfile.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

IMAGE_TAG="${IMAGE_TAG:-context-server-wheel}"
OUT_DIR="${OUT_DIR:-$root/dist}"

# Prefer explicit VERSION, else exact git tag when present.
VERSION="${VERSION:-}"
if [[ -z "$VERSION" ]]; then
  VERSION="$(git describe --exact-match --tags HEAD 2>/dev/null || true)"
  VERSION="${VERSION#v}"
fi

mkdir -p "$OUT_DIR"

build_args=()
if [[ -n "$VERSION" ]]; then
  echo "Building wheel image with VERSION=$VERSION..."
  build_args+=(--build-arg "VERSION=$VERSION")
else
  echo "Building wheel image (Cargo.toml version as-is)..."
fi

podman build \
  "${build_args[@]}" \
  -t "$IMAGE_TAG" \
  -f Containerfile \
  .

cid="$(podman create "$IMAGE_TAG")"
cleanup() { podman rm -f "$cid" >/dev/null 2>&1 || true; }
trap cleanup EXIT

podman cp "$cid:/out/." "$OUT_DIR/"
echo "Wheels written to $OUT_DIR:"
ls -la "$OUT_DIR"
