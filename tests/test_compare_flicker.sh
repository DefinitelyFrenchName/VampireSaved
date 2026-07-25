#!/bin/sh
# test_compare_flicker.sh — ground truth for the flicker comparator's verdict
# logic (CLAUDE.md §4: classification code is validated before its verdicts
# are trusted). Synthetic logs, no emulator, fast.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
W="$(mktemp -d)"
trap 'rm -rf "$W"' EXIT
CF() { python3 "$REPO/tools/compare_flicker.py" "$@"; }

mklog() { # mklog <path> <n> [flip_csv]
    python3 - "$@" <<'EOF'
import sys
path, n = sys.argv[1], int(sys.argv[2])
flips = set(int(x) for x in sys.argv[3].split(",")) if len(sys.argv) > 3 else set()
with open(path, "w") as f:
    for i in range(1, n + 1):
        h = f"{i:016x}" if i not in flips else f"{i:016x}DIVERGED"
        f.write(f"{i} {h}\n")
    f.write(f"END {n}\n")
EOF
}

fail=0
ok() { echo "  ok: $1"; }
bad() { echo "FAIL: $1"; fail=1; }

mklog "$W/base.log" 500
mklog "$W/same.log" 500
out=$(CF "$W/base.log" "$W/same.log") && [ "$out" = "EXACT" ] \
    && ok "identical -> EXACT" || bad "identical logs: got '$out'"

mklog "$W/flick1.log" 500 100
out=$(CF "$W/base.log" "$W/flick1.log") \
    && case "$out" in FLICKER\ 1\ 100) ok "single-frame flicker -> FLICKER";; \
       *) bad "single flicker: got '$out'";; esac \
    || bad "single flicker: exit nonzero ('$out')"

mklog "$W/flick2.log" 500 100,101,300
out=$(CF "$W/base.log" "$W/flick2.log") \
    && case "$out" in FLICKER\ 3\ *) ok "2-frame stretch + isolated -> FLICKER";; \
       *) bad "multi flicker: got '$out'";; esac \
    || bad "multi flicker: exit nonzero ('$out')"

mklog "$W/stretch3.log" 500 100,101,102
out=$(CF "$W/base.log" "$W/stretch3.log") && bad "3-frame stretch accepted: '$out'" \
    || case "$out" in FAIL*stretch*) ok "3-frame stretch -> FAIL";; \
       *) bad "3-frame stretch wrong reason: '$out'";; esac

mklog "$W/close.log" 500 100,140
out=$(CF "$W/base.log" "$W/close.log") && bad "40-frame gap accepted: '$out'" \
    || case "$out" in FAIL*converge*) ok "insufficient re-convergence -> FAIL";; \
       *) bad "close flickers wrong reason: '$out'";; esac

mklog "$W/persist.log" 500 "$(seq 200 500 | tr '\n' ',' | sed 's/,$//')"
out=$(CF "$W/base.log" "$W/persist.log") && bad "persistent divergence accepted" \
    || case "$out" in FAIL*) ok "persistent divergence -> FAIL";; \
       *) bad "persistent wrong reason: '$out'";; esac

mklog "$W/tail.log" 500 499
out=$(CF "$W/base.log" "$W/tail.log") \
    && case "$out" in FLICKER*) ok "end-of-log flicker -> FLICKER (no converge window needed)";; \
       *) bad "tail flicker: got '$out'";; esac \
    || bad "tail flicker: exit nonzero ('$out')"

mklog "$W/short.log" 499
out=$(CF "$W/base.log" "$W/short.log") && bad "length mismatch accepted" \
    || case "$out" in FAIL*length*) ok "length mismatch -> FAIL";; \
       *) bad "length wrong reason: '$out'";; esac

[ "$fail" = 0 ] && echo "PASS: flicker comparator verdicts validated" \
    || { echo "FAIL: flicker comparator"; exit 1; }
