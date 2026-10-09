#!/usr/bin/env bash
# Tests tools/district_listing.sh against listings that must fail (an error exit, nothing listed, a
# listing cut short, no count) and one that must pass. The gate runs this before its district tours.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
check="$ROOT/tools/district_listing.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
failures=0
expect() { # $1 pass|fail, $2 name, $3 exit code, $4 listing text
  printf '%b' "$4" > "$tmp/$2.log"
  if out=$("$check" "$tmp/$2.log" "$3" 2>/dev/null); then got=pass; else got=fail; fi
  if [ "$got" != "$1" ]; then echo "FAIL $2: expected $1, got $got"; failures=$((failures + 1)); return; fi
  if [ "$1" = pass ] && [ "$out" != "$(printf 'kestrel\nloop')" ]; then echo "FAIL $2: listed '$out'"; failures=$((failures + 1)); return; fi
  echo "ok $2"
}
expect pass good 0 'Godot Engine\nDISTRICT kestrel\nDISTRICT loop\nDISTRICTS 2\n'
expect fail error_exit 1 'DISTRICT kestrel\nDISTRICT loop\nDISTRICTS 2\n'
expect fail timed_out 124 ''
expect fail nothing 0 'Godot Engine\n'
expect fail cut_short 0 'DISTRICT kestrel\n'
expect fail too_few 0 'DISTRICT kestrel\nDISTRICTS 2\n'
expect fail no_count 0 'DISTRICT kestrel\nDISTRICT loop\n'
[ $failures -eq 0 ]
