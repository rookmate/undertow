#!/usr/bin/env bash
# Checks the game's district listing (`godot -- --list-districts`) for the gate's tours:
#   tools/district_listing.sh <listing log> <its exit code>
# Prints the district ids, one per line, and exits 0 only if the listing succeeded, named at least one
# district, and ended with "DISTRICTS <n>" matching the ids before it (so a listing cut short fails).
# Otherwise says why on stderr and exits 1. tools/test_district_listing.sh tests it.
set -uo pipefail
log="${1:?usage: district_listing.sh <log> <exit code>}"
code="${2:?usage: district_listing.sh <log> <exit code>}"
if [ "$code" -ne 0 ]; then echo "the listing exited with $code" >&2; exit 1; fi
districts=$(sed -n 's/^DISTRICT //p' "$log")
expected=$(sed -n 's/^DISTRICTS //p' "$log")
listed=$(printf '%s\n' "$districts" | grep -c .)
if [ -z "$districts" ]; then echo "no districts listed" >&2; exit 1; fi
if [ "$listed" != "$expected" ]; then echo "$listed districts listed, ${expected:-no count} expected" >&2; exit 1; fi
printf '%s\n' "$districts"
