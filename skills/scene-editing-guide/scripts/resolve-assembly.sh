#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $(basename "$0") <cs-file-path>" >&2
  exit 2
fi

file="$1"
if [ ! -f "$file" ]; then
  echo "Error: file not found: $file" >&2
  exit 1
fi

dir="$(cd "$(dirname "$file")" && pwd)"
asmdef=""
shopt -s nullglob
while [ -n "$dir" ] && [ "$dir" != "/" ]; do
  candidates=("$dir"/*.asmdef)
  if (( ${#candidates[@]} > 0 )); then
    asmdef="${candidates[0]}"
    break
  fi
  dir="$(dirname "$dir")"
done
shopt -u nullglob

if [ -z "$asmdef" ]; then
  if printf '%s\n' "$file" | grep -q '/Editor/'; then
    echo "Assembly-CSharp-Editor"
  else
    echo "Assembly-CSharp"
  fi
  exit 0
fi

# Normalize to a single line so both pretty-printed and compact JSON match uniformly
content=$(tr -d '\n\r' < "$asmdef")

name=$(printf '%s\n' "$content" | grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | grep -o '"[^"]*"$' | tr -d '"')
if [ -z "$name" ]; then
  echo "Error: missing 'name' in $asmdef" >&2
  exit 1
fi

echo "$name"
