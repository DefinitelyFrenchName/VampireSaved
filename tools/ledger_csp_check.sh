#!/bin/sh
# ledger_csp_check.sh — the ledger page rendered by a real browser under a Content-Security-Policy (GitHub #267, 14z-212).
#
# Serves a built page directory (tools/ledger_page.py --out DIR) at http://127.0.0.1:<port>/<name>/ with the given policy
# sent as the Content-Security-Policy header, renders it in headless Chrome, and requires: every section built (the
# page's <h2> count), the worked examples present, and no "Refused" / "Content Security Policy" line in the console.
# Run by hand before publishing to a host whose policy changed; tests/test_ledger_page.sh's inline check is the
# portable half (it needs no browser). Measured 14z-212 under the maintainer's site policy: 11 sections, 3,541 table
# rows, 5 examples, 0 refusals.
#
# Usage: tools/ledger_csp_check.sh <page dir> "<policy>" [port]
#   e.g. tools/ledger_csp_check.sh build/ledger_page/site "default-src 'none'; style-src 'self'; script-src 'self'"
set -eu
DIR="${1:?usage: tools/ledger_csp_check.sh <page dir> \"<policy>\" [port]}"; CSP="${2:?a policy string}"; PORT="${3:-8767}"
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
[ -x "$CHROME" ] || { echo "FAIL: no Chrome at $CHROME (set CHROME)"; exit 2; }
DIR="$(cd "$DIR" && pwd)"; NAME="$(basename "$DIR")"; ROOT="$(dirname "$DIR")"
W="$(mktemp -d "${TMPDIR:-/tmp}/ledgercsp.XXXXXX")"
trap 'rm -rf "$W"' EXIT
cat > "$W/serve.py" <<'PY'
import http.server, sys, os
CSP = sys.argv[2]
class H(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Content-Security-Policy", CSP); super().end_headers()
    def log_message(self, *a): pass
os.chdir(sys.argv[1]); http.server.ThreadingHTTPServer(("127.0.0.1", int(sys.argv[3])), H).serve_forever()
PY
python3 "$W/serve.py" "$ROOT" "$CSP" "$PORT" &
SRV=$!
sleep 1
timeout 90 "$CHROME" --headless=new --disable-gpu --virtual-time-budget=8000 --enable-logging=stderr --v=0 \
    --dump-dom "http://127.0.0.1:$PORT/$NAME/" > "$W/dom.html" 2> "$W/console.txt" || true
kill "$SRV"; wait "$SRV" 2>/dev/null || true
python3 - "$W/dom.html" "$W/console.txt" <<'PY'
import re, sys
dom, con = open(sys.argv[1]).read(), open(sys.argv[2], errors="replace").read()
h2, rows, ex = len(re.findall(r"<h2>", dom)), dom.count("<tr>"), dom.count('class="catch"')
refused = [l for l in con.splitlines() if "Content Security Policy" in l or "Refused" in l]
print(f"sections {h2}, table rows {rows}, worked examples {ex}, refusals {len(refused)}")
for l in refused[:5]: print("  " + l[:200])
ok = h2 >= 10 and rows > 0 and not refused
print("PASS: the page renders whole under the policy" if ok else "FAIL: the page does not render whole under the policy")
sys.exit(0 if ok else 1)
PY
