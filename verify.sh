#!/usr/bin/env bash
# Post-deploy check. This is E34-01's "Verify" line made executable.
#
# The association file is copied from the app repo (blind-drop/web/.well-known/),
# so the two can drift. This script proves the *deployed* file is still byte-exact
# and still served the way Apple demands: application/json, no redirect, 200.
#
#   ./verify.sh https://blinddrop.app
#   ./verify.sh https://blinddrop.vercel.app
set -euo pipefail

BASE="${1:-}"
if [ -z "$BASE" ]; then echo "usage: ./verify.sh <base-url>" >&2; exit 2; fi
BASE="${BASE%/}"
URL="$BASE/.well-known/apple-app-site-association"
LOCAL="$(dirname "$0")/.well-known/apple-app-site-association"
fail=0

read -r code type effective < <(
  curl -sS -o /tmp/aasa.$$ -w '%{http_code} %{content_type} %{url_effective}' "$URL"
)

check() { if [ "$2" = "$3" ]; then echo "  ok    $1"; else echo "  FAIL  $1: expected '$3', got '$2'"; fail=1; fi; }

echo "$URL"
check "status"        "$code"      "200"
check "content-type"  "${type%%;*}" "application/json"
check "no redirect"   "$effective" "$URL"

if diff -q "$LOCAL" /tmp/aasa.$$ >/dev/null 2>&1; then
  echo "  ok    matches the committed file"
else
  echo "  FAIL  deployed file differs from $LOCAL"; diff "$LOCAL" /tmp/aasa.$$ || true; fail=1
fi
rm -f /tmp/aasa.$$

for p in "/" "/j/K7MQ2X"; do
  s=$(curl -sS -o /dev/null -w '%{http_code}' "$BASE$p")
  check "GET $p" "$s" "200"
done

[ "$fail" = 0 ] && echo "all checks passed" || { echo "FAILED"; exit 1; }
