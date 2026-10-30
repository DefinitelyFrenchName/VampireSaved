#!/bin/sh
# publish_sheets.sh — put a web build of the proof sheets on the maintainer's own site (GitHub #338).
#
# The web build is `tools/proof_sheets.py web <local run> --to <dir> --release <tag>`, drawn at a tagged release (the
# #338 design, point 8). This script checks it with `proof_sheets.py webcheck` and REFUSES to publish one that fails
# (a full-size picture, a page without credits, a local path, a log), then rsyncs it into <DEPLOY_TARGET>vs-proof-sheets/,
# REPLACING what is there (ruled 2026-10-30, 14z-213: "vs-proof-sheets/ (Recommended)" — "A sibling folder of the
# ledger: <DEPLOY_TARGET>vs-proof-sheets/, replaced at each release"). DEPLOY_TARGET (user@host:path/to/webroot/) and
# DEPLOY_PORT are the same settings tools/publish_ledger.sh's --own-site reads; ssh runs in batch mode and the upload is
# bounded by a timeout. GitHub Pages is not used: the sheets exceed its 1 GB limit.
#
# Usage: tools/publish_sheets.sh <web dir>
# Gate: tests/test_proof_sheets_web.sh (section 4).
set -eu
WEB="${1:?usage: tools/publish_sheets.sh <web dir>}"
TOOLS="$(cd "$(dirname "$0")" && pwd)"
[ -f "$WEB/index.html" ] || { echo "FAIL: $WEB holds no index.html — not a web build"; exit 1; }
[ -n "${DEPLOY_TARGET:-}" ] || { echo "FAIL: DEPLOY_TARGET is not set (user@host:path/to/webroot/) — nothing published"; exit 1; }
python3 "$TOOLS/proof_sheets.py" webcheck "$WEB" || { echo "FAIL: the web build fails webcheck — nothing published"; exit 1; }
_port="${DEPLOY_PORT:-22}"
case "$_port" in *[!0-9]*|"") echo "FAIL: DEPLOY_PORT must be a number, got '$_port'"; exit 1 ;; esac
_dest="${DEPLOY_TARGET%/}/vs-proof-sheets/"
timeout 3600 rsync -rtz --delete --checksum -e "ssh -p $_port -o BatchMode=yes -o ConnectTimeout=20" "$WEB/" "$_dest" \
    || { echo "FAIL: the upload to the own site did not complete"; exit 1; }
echo "published $(find "$WEB" -name '*.html' | wc -l | tr -d ' ') pages to the own site's vs-proof-sheets/"
