# pairing.sh — run one 2P pairing on a build and assert BOTH characters
# loaded. Source from a test; requires $REPO, $ROMDIR, $MAME_BIN, and $BUILD
# (a dir with rompath/vsavjw.zip).
#
# Lifted verbatim out of tests/test_tenant_pairings.sh (14z-97) when the
# second caller appeared — tests/audit_roster_pairings.sh, which runs the full
# CLAUDE.md §4 mandate ("vs each of the 18, both sides") rather than the six
# tenant-vs-tenant orderings. Same one-source move, and the same reason, as
# tests/lib/masked_compare.sh a few hours earlier: a second copy does not stay
# a copy, it stays at the vocabulary of the day it was written.
#
# ── THE THREE THINGS THAT ARE LOAD-BEARING, all measured, all easy to undo ──
#
# 1. THE SIGNATURE IS `+0x60.l`, NOT `+0x382`. 14z-87 proved `+0x382` is the
#    VOICE-FLAVOR class in match, not the character id (`ram.md:85`): the
#    engine reassigns it. GitHub #16 records a live gate (`test_pyron_blink`)
#    whose guard reads `+0x382` in match and can therefore false-REFUSE.
#    `audit_legacy_pairings` uses `+0x60.l` for the same reason. Measured
#    14z-95: the base is stable per character AND independent of side —
#    Phobos reads 0x4477b0 as P1 and as P2 — so one value serves both.
#
# 2. BOTH ORDERINGS ARE SEPARATE TESTS. P1 and P2 are different structs
#    reached by different code paths, so A-vs-B and B-vs-A are two runs.
#
# 3. THE NO-POKE CONTROL IS NOT OPTIONAL. Without it every pass is vacuous:
#    the check would be satisfied by whatever the replay picks on its own.
#    Callers must run `pairing_run ... nopoke` and require it to be REJECTED.
#
# The replay is character-agnostic by design, so a new pairing is a class pair
# and an expected base — no new replay.

PAIRING_RPL_DEFAULT="tests/replays/94_tenant_vs_tenant.rpl"

# pairing_hex <class> — normalise "0x13" or "13" to "13", REFUSING anything
# that is not bare hex.
#
# THIS GUARD IS NOT DECORATION. replay.lua parses POKES with
# `spec:match("^(%d+):(%x+):(%x+)$")` and simply SKIPS a spec that does not
# match — and "0x13" does not, because `x` is not a hex digit. So a class
# written the readable way silently produces NO POKE, the run proceeds with
# whatever the replay picks on its own, and the failure surfaces as "the
# character did not load" — a true statement about the wrong cause. Refusing
# loudly here is the difference between a five-second fix and an afternoon.
pairing_hex() {
    case "$1" in
        0x*|0X*) _ph="${1#0[xX]}" ;;
        *)       _ph="$1" ;;
    esac
    case "$_ph" in
        ""|*[!0-9a-fA-F]*)
            echo "pairing: refusing class '$1' — POKES needs bare hex" >&2
            return 1 ;;
    esac
    printf '%s' "$_ph"
}

# pairing_run <workdir> <p1class> <p2class> <tag> [nopoke]
#   Starts ONE guarded run in the background. The caller batches and waits.
pairing_run() {
    _pr_w="$1"; _pr_p1="$(pairing_hex "$2")"; _pr_p2="$(pairing_hex "$3")"
    _pr_tag="$4"; _pr_mode="${5:-}"
    _pr_d="$_pr_w/$_pr_tag"; mkdir -p "$_pr_d/s1"
    if [ "$_pr_mode" = nopoke ]; then
        _pr_pk=""
    else
        # Three pokes per side across the pre-match window: the character id
        # is written more than once during select/commit, so a single poke can
        # be overwritten. Frames match test_tenant_pairings' measured window.
        _pr_pk="1400:ff8782:$_pr_p1;1450:ff8782:$_pr_p1;1500:ff8782:$_pr_p1"
        _pr_pk="$_pr_pk;1400:ff8b82:$_pr_p2;1450:ff8b82:$_pr_p2;1500:ff8b82:$_pr_p2"
    fi
    _pr_df="$(python3 -c "print(';'.join(f'{f}:ff8400-ff8470;{f}:ff8800-ff8870' for f in range(3000,3400,50)))")"
    ( cd "$_pr_d" && MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" \
      POKES="$_pr_pk" DUMPS="$_pr_df" FRAMES="${PAIRING_FRAMES:-4420}" GUARD_DEBUG=0 \
      "$REPO/tools/run_replay_guarded.sh" vsavjw \
      "$REPO/${PAIRING_RPL:-$PAIRING_RPL_DEFAULT}" out.log s1 >emu 2>&1 ) &
}

# pairing_check <workdir> <tag> <want_p1_base> <want_p2_base>
#   0 = the run completed AND both sides carry the expected base.
#   Prints the reason on failure. Bases are hex strings ("0x3fa9d0").
pairing_check() {
    _pc_d="$1/$2"; _pc_w1="$3"; _pc_w2="$4"
    # A DEAD LEG IS A FAILURE, NOT A PASS (#29). An absent or END-less log is
    # how several audits in this tree went quiet: the loop counted a missing
    # measurement as nothing-to-report instead of nothing-measured.
    if [ ! -f "$_pc_d/out.log" ]; then
        echo "       no log at all — the run never produced one (dead leg)"
        return 1
    fi
    if ! grep -q "^END " "$_pc_d/out.log" 2>/dev/null; then
        echo "       $(grep -m1 '^CRASH\|^REGS' "$_pc_d/out.log" 2>/dev/null \
                       || tail -2 "$_pc_d/emu" 2>/dev/null || echo 'no END line')"
        return 1
    fi
    python3 - "$_pc_d" "$_pc_w1" "$_pc_w2" <<'PY'
import glob, sys, struct
d, w1, w2 = sys.argv[1], int(sys.argv[2], 16), int(sys.argv[3], 16)
def base(addr):
    return {struct.unpack(">I", open(f, "rb").read()[0x60:0x64])[0]
            for f in glob.glob(f"{d}/dump_*_{addr}.bin")}
b1, b2 = base("ff8400"), base("ff8800")
if not b1 or not b2:
    print("       no RAM dumps — the probe did not fire")
    sys.exit(1)
if b1 != {w1} or b2 != {w2}:
    print(f"       P1 +0x60.l={[hex(x) for x in sorted(b1)]} want {w1:#x}; "
          f"P2={[hex(x) for x in sorted(b2)]} want {w2:#x}")
    sys.exit(1)
PY
}
