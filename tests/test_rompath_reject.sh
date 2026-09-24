#!/bin/sh
# test_rompath_reject.sh — a REJECTED build does not keep its rompath: the
# builders' EXIT trap (tools/rompath_reject.sh) moves it aside (14z-155, #139).
#
# WHAT: a REJECTED build does not keep its rompath: the builders' EXIT trap
#   (tools/rompath_reject.sh) moves it aside on an explicit exit 1, a set -e failure, a
#   `${VAR:?}` demand (exit 0 under a trap on bash 3.2, still failed), SIGTERM and a missing
#   disarm, while a success keeps it and a failure before the pack has nothing to move; both
#   real builders source it, arm it after the clear and disarm it after every verifier.
# HOW: scripted builders sourcing the REAL helper under sh, bash and dash, plus the wiring
#   read from both builders; controls disable the rename and move a disarm above the audit.
# EXPECTS: every helper case and the wiring as specified; both controls fail. That a real
#   build rejects end to end is not claimed (ROMs needed).
#
# MUST-FIRE: perturbed-copy: rename-disabled — a copy of tools/rompath_reject.sh whose rename never runs must fail the helper cases: a scripted builder exiting 1 after its pack then keeps its rompath
# MUST-FIRE: perturbed-copy: disarm-early — a copy of tools/build_donovan.sh with its disarm moved above the member-identity audit must fail the wiring check: a build that audit rejects would keep its rompath
#
# WHY. Both builders pack <outbase>/rompath first and verify it afterwards, and
# a rejection used to exit 1 while LEAVING the packed zips in place, so a
# rejected build looked finished on disk (#139, the residual #1 deferred on
# 2026-08-16; the EXIT-trap variant maintainer-ruled 2026-09-14).
#
# WHAT IT HOLDS.
#  1. THE HELPER, driven by scripted builders that source the REAL helper under
#     every shell a builder runs in (sh, bash, and dash when present): an
#     explicit `exit 1` after the pack, a `set -e` failure, a `${VAR:?}` demand
#     (exits 0 on macOS bash 3.2 under an EXIT trap, [VSP-176] — the helper must
#     still fail it), SIGTERM, an end WITHOUT the disarm, a failure BEFORE the
#     pack (nothing to move), a success (rompath kept) and a stale
#     rompath.REJECTED removed by the next arming.
#  2. THE WIRING of both real builders: the helper sourced once; armed once,
#     AFTER the rompath is cleared and BEFORE the first pack_build.sh; disarmed
#     once, AFTER every verifier and the fingerprint, and immediately before the
#     final `echo "OK:` line.
#
# WHAT IT DOES NOT CLAIM: that a real build rejects correctly end to end (the
# builders need ROMs). tests/test_m3a_reproducible.sh proves the wired builders'
# SUCCESS path still leaves the rompath it fingerprints; this gate proves the
# trap in the helper they source, and that they source and place it.
#
# Usage: tests/test_rompath_reject.sh      # ci_portable: no ROM, no emulator, ~2 s
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM

HELPER="$REPO/tools/rompath_reject.sh"
DONOVAN="$REPO/tools/build_donovan.sh"
MERGED="$REPO/tools/build_merged.sh"

# THE PERTURBATIONS, one per declared control; the control section and the
# CONTROL=<name> mode call the same function.
perturb_rename_disabled() {  # <out> — the rename condition can never run mv
    sed 's/if mv "\$_rr_dir" "\$_rr_dir.REJECTED"; then/if false; then/' "$HELPER" > "$1"
    cmp -s "$HELPER" "$1" && { echo "perturbation rename-disabled matched nothing"; exit 3; }
    return 0
}
perturb_disarm_early() {  # <out> — the disarm moved above the member-identity audit
    python3 - "$DONOVAN" "$1" <<'PY' || { echo "perturbation disarm-early failed"; exit 3; }
import sys
src = open(sys.argv[1]).read().split("\n")
code = lambda l: not l.lstrip().startswith("#")
d = [i for i, l in enumerate(src) if l.strip() == "rompath_reject_disarm"]
a = [i for i, l in enumerate(src) if code(l) and "audit_romset_identity.py" in l]
assert len(d) == 1 and a, (d, a)
line = src.pop(d[0])
src.insert(a[0], line)
open(sys.argv[2], "w").write("\n".join(src))
PY
}

H="$HELPER"; D="$DONOVAN"
if vs_ctl_is rename-disabled; then perturb_rename_disabled "$W/mode_helper.sh"; H="$W/mode_helper.sh"; fi
if vs_ctl_is disarm-early;    then perturb_disarm_early "$W/mode_donovan.sh"; D="$W/mode_donovan.sh"; fi

# A scripted builder: $1 helper, $2 outbase, $3 case.
cat > "$W/builder.sh" <<'EOF'
set -eu
. "$1"
OUT="$2"; CASE="$3"
[ "$CASE" = stale ] && mkdir -p "$OUT/rompath.REJECTED"
rm -rf "$OUT/rompath"
rompath_reject_arm "$OUT/rompath"
[ "$CASE" = before-pack ] && exit 1
mkdir -p "$OUT/rompath"; echo packed > "$OUT/rompath/vsavjw.zip"
case "$CASE" in
    exit1)  exit 1 ;;
    set-e)  false ;;
    demand) : "${RR_NEVER_SET_BY_ANYONE:?demanded}" ;;
    term)   kill -TERM $$; sleep 2 ;;
    no-ok)  exit 0 ;;
esac
rompath_reject_disarm
echo "OK: scripted build"
EOF

# helper_cases <helper> <shell> <tag>: every case; prints one FAIL line per miss,
# returns the number of misses.
helper_cases() {
    _h="$1"; _sh="$2"; _miss=0
    for spec in "exit1 1 no yes" "set-e 1 no yes" "demand nz no yes" "term 143 no yes" \
                "no-ok 1 no yes" "before-pack 1 no no" "success 0 yes no" "stale 0 yes no"; do
        set -- $spec
        o="$W/o_${3}_$(basename "$_sh")_$1"; rm -rf "$o"; mkdir -p "$o"
        "$_sh" "$W/builder.sh" "$_h" "$o" "$1" > "$o.log" 2>&1; rc=$?
        [ -d "$o/rompath" ] && rp=yes || rp=no
        [ -d "$o/rompath.REJECTED" ] && rj=yes || rj=no
        case "$2" in nz) [ "$rc" != 0 ] && rcok=1 || rcok=0 ;; *) [ "$rc" = "$2" ] && rcok=1 || rcok=0 ;; esac
        if [ "$rcok" = 1 ] && [ "$rp" = "$3" ] && [ "$rj" = "$4" ]; then :; else
            echo "  FAIL  $_sh $1: exit $rc (want $2), rompath $rp (want $3), rompath.REJECTED $rj (want $4)"
            _miss=$((_miss + 1))
        fi
    done
    return "$_miss"
}

# wiring <builder> <clear-line> <source-line> <arm-line>: the placement rules.
wiring() {
    python3 - "$@" <<'PY'
import sys
path, clear, source, arm = sys.argv[1:5]
lines = open(path).read().split("\n")
code = [(i, l.strip()) for i, l in enumerate(lines) if l.strip() and not l.lstrip().startswith("#")]
def where(pred):
    return [i for i, s in code if pred(s)]
errs = []
c, s, a = where(lambda x: x == clear), where(lambda x: x == source), where(lambda x: x == arm)
d = where(lambda x: x == "rompath_reject_disarm")
for name, hits in (("the clear", c), ("the source line", s), ("the arm", a), ("the disarm", d)):
    if len(hits) != 1:
        errs.append(f"{name} occurs {len(hits)} times (want exactly 1)")
packs = where(lambda x: "tools/pack_build.sh" in x)
checks = where(lambda x: any(t in x for t in ("verify_gfx_build.py", "audit_romset_identity.py",
                                               "check_tenant_hud.py", "build_fingerprint.py")))
if not errs:
    c, s, a, d = c[0], s[0], a[0], d[0]
    if not (c < s < a):
        errs.append("the helper is not sourced and armed AFTER the rompath is cleared")
    if not packs or not a < packs[0]:
        errs.append("the arm does not come BEFORE the first pack_build.sh")
    if not checks or not d > max(checks):
        errs.append("the disarm does not come AFTER every verifier and the fingerprint")
    nxt = [x for i, x in code if i > d]
    if not nxt or not nxt[0].startswith('echo "OK:'):
        errs.append("the disarm is not immediately followed by the final `echo \"OK:` line")
for e in errs:
    print(f"        {path}: {e}")
sys.exit(1 if errs else 0)
PY
}

SHELLS="sh bash"; [ -x /bin/dash ] && SHELLS="$SHELLS /bin/dash"

echo "== test_rompath_reject: a rejected build does not keep its rompath =="
echo "== 1. the helper, under $SHELLS =="
for sh in $SHELLS; do
    if out="$(helper_cases "$H" "$sh" main)"; then
        ok "$sh: exit 1 / set -e / an unset-variable demand / TERM / no final OK move rompath aside; before-pack moves nothing; success and a stale REJECTED keep rompath"
    else
        bad "$sh: the helper cases:"; printf '%s\n' "$out"
    fi
done

echo "== 2. the wiring of both real builders =="
if out="$(wiring "$D" 'rm -rf "$OUTBASE/rompath"' '. "$(dirname "$0")/rompath_reject.sh"' 'rompath_reject_arm "$OUTBASE/rompath"')"; then
    ok "tools/build_donovan.sh: sourced and armed after the clear, before the pack; disarmed after every check, before OK"
else
    bad "tools/build_donovan.sh wiring:"; printf '%s\n' "$out"
fi
if out="$(wiring "$MERGED" 'rm -rf "$OUT"; mkdir -p "$OUT"' '. "$REPO/tools/rompath_reject.sh"' 'rompath_reject_arm "$OUT/rompath"')"; then
    ok "tools/build_merged.sh: sourced and armed after the clear, before the pack; disarmed after every check, before OK"
else
    bad "tools/build_merged.sh wiring:"; printf '%s\n' "$out"
fi

echo "== 3. must-fire controls =="
for n in $(vs_ctl_declared "$0"); do
    case "$n" in
    rename-disabled)
        perturb_rename_disabled "$W/ctl_helper.sh"
        if helper_cases "$W/ctl_helper.sh" sh ctl > "$W/ctl_rename.log" 2>&1; then
            vs_ctl_dead "$n" "the helper cases PASSED with the rename disabled — they test nothing" || true; bad "$n"
        elif grep -q "exit1: exit 1 (want 1), rompath yes (want no)" "$W/ctl_rename.log"; then
            vs_ctl_fired "$n" "with the rename disabled, a builder exiting 1 after its pack keeps its rompath"; ok "$n: fires"
        else
            vs_ctl_dead "$n" "failed for the wrong reason" || true; bad "$n:"; sed 's/^/      /' "$W/ctl_rename.log"
        fi ;;
    disarm-early)
        perturb_disarm_early "$W/ctl_donovan.sh"
        if wiring "$W/ctl_donovan.sh" 'rm -rf "$OUTBASE/rompath"' '. "$(dirname "$0")/rompath_reject.sh"' 'rompath_reject_arm "$OUTBASE/rompath"' > "$W/ctl_disarm.log" 2>&1; then
            vs_ctl_dead "$n" "the wiring check PASSED with the disarm above the identity audit" || true; bad "$n"
        elif grep -q "the disarm does not come AFTER every verifier" "$W/ctl_disarm.log"; then
            vs_ctl_fired "$n" "a disarm above the member-identity audit is refused by the wiring check"; ok "$n: fires"
        else
            vs_ctl_dead "$n" "failed for the wrong reason" || true; bad "$n:"; sed 's/^/      /' "$W/ctl_disarm.log"
        fi ;;
    esac
done

if [ "$fail" = 0 ]; then echo "PASS: test_rompath_reject"; else echo "FAIL: test_rompath_reject"; exit 1; fi
