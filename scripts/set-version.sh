#!/usr/bin/env bash
# Set package.version in Cargo.toml (and the root entry in Cargo.lock) from
# a CalVer tag (YYYY.MMDD.N) or an explicit argument.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

version="${1:-}"
if [[ -z "$version" ]]; then
  version="$(git describe --exact-match --tags HEAD 2>/dev/null || true)"
fi
if [[ -z "$version" ]]; then
  echo "usage: $0 <YYYY.MMDD.N>  (or run on an exact git tag)" >&2
  exit 1
fi

# Strip optional leading v
version="${version#v}"

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "error: version must look like YYYY.MMDD.N (got: $version)" >&2
  exit 1
fi

python3 - "$version" <<'PY'
import pathlib
import re
import sys

version = sys.argv[1]
root = pathlib.Path(".")

cargo = root / "Cargo.toml"
text = cargo.read_text()
new, n = re.subn(
    r'(?m)^(version\s*=\s*")[^"]*(")',
    rf"\g<1>{version}\2",
    text,
    count=1,
)
if n != 1:
    raise SystemExit("failed to rewrite version in Cargo.toml")
cargo.write_text(new)

lock = root / "Cargo.lock"
if lock.exists():
    lock_text = lock.read_text()
    # Update the root package stanza only (first name = "context-server" block).
    pattern = re.compile(
        r'(name = "context-server"\nversion = ")[^"]*(")',
        re.MULTILINE,
    )
    lock_new, n = pattern.subn(rf"\g<1>{version}\2", lock_text, count=1)
    if n != 1:
        raise SystemExit("failed to rewrite version in Cargo.lock")
    lock.write_text(lock_new)

print(f"set version to {version}")
PY
