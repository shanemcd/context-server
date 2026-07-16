#!/usr/bin/env bash
# Print next CalVer tag: YYYY.MMDD.N (Cargo/PEP 440 compatible).
#
# major = year, minor = month*100+day (no leading zeros), patch = same-day N.
# Example: first release on 2026-07-16 -> 2026.716.1
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

year="$(date -u +%Y)"
month=$((10#$(date -u +%m)))
day=$((10#$(date -u +%d)))
minor=$((month * 100 + day))
prefix="${year}.${minor}."

existing="$(git tag -l "${prefix}*" 2>/dev/null | sed -n "s/^${prefix}//p" | sort -n | tail -1 || true)"
if [[ -z "$existing" ]]; then
  echo "${prefix}1"
else
  echo "${prefix}$((existing + 1))"
fi
