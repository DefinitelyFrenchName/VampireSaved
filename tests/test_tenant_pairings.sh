#!/bin/sh
# test_tenant_pairings.sh — TWO PORTED CHARACTERS IN ONE MATCH, every
# ordering (14z-95). The coverage CLAUDE.md §4 mandates and the suite did not
# have.
#
# WHY IT EXISTS. §4 requires "vs each of the 18 (both sides)" for a ported
# character. Until 14z-95 `tests/replays/` contained no pairing of two ported
# characters AT ALL — which is the gap GitHub #99 walked through, and the
# arcade marathon cannot close it: it is a single-credit soak that plays one
# character, and it reaches only two ladder rungs (measured 14z-95).
#
# WHAT IT ASSERTS, per ordering:
#   1. the run completes with no crash (guarded; a watchdog reset or a 68k
#      exception ends the log without END)
#   2. BOTH characters actually loaded, checked on the per-character hitbox
#      base `+0x60.l`
#
# THE SIGNATURE IS +0x60.l, NOT +0x382 — and that choice is load-bearing.
# 14z-87 proved +0x382 is the VOICE-FLAVOR class in match, not the character
# id (`ram.md:85`); the engine reassigns it. GitHub #16 records a live gate
# (`test_pyron_blink`) whose guard reads +0x382 in match and can therefore
# false-REFUSE. `audit_legacy_pairings` already uses +0x60.l for the same
# reason. Measured 14z-95: the base is stable per character AND independent of
# side — Phobos reads 0x4477b0 as P1 and as P2 — so one frozen value serves
# both orderings.
#
# BOTH ORDERINGS, not just both characters: P1 and P2 are different structs
# reached by different code paths, so D-vs-H and H-vs-D are two tests.
#
# The replay is character-agnostic, so ADDING A TENANT IS A ROW IN `CLASSES`
# below plus its frozen base — no new replay.
#
# Usage: ROMDIR=... [MERGED=build/m3b_merged9] tests/test_tenant_pairings.sh
# ~3 min (6 guarded MAME runs, parallel). Needs the MERGED build: the whole
# point is two tenants in ONE image, which no solo build can express.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
BUILD="${MERGED:-build/m3b_merged9}"
[ -d "$BUILD/rompath" ] || { echo "SKIP: no merged build at $BUILD"; exit 0; }
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no WIDE MAME binary"; exit 0; }
export MAME_BIN

RPL="$REPO/tests/replays/94_tenant_vs_tenant.rpl"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0
ok()  { echo "  ok: $1"; }
bad() { echo "FAIL: $1"; fail=1; }

# class : name : frozen +0x60.l hitbox base (measured 14z-95 on merged-m2,
# identical as P1 and as P2 across all three pairings)
CLASSES="13:donovan:0x3fa9d0 10:phobos:0x4477b0 11:pyron:0x49ab7c"
base_of() { for r in $CLASSES; do case "$r" in "$1:"*) echo "${r##*:}"; return;; esac; done; }
name_of() { for r in $CLASSES; do case "$r" in "$1:"*) x="${r#*:}"; echo "${x%%:*}"; return;; esac; done; }

run_pair() { # run_pair <p1class> <p2class> <tag> [nopoke]
    d="$W/$3"; mkdir -p "$d/s1"
    if [ "${4:-}" = nopoke ]; then PK=""
    else PK="1400:ff8782:$1;1450:ff8782:$1;1500:ff8782:$1;1400:ff8b82:$2;1450:ff8b82:$2;1500:ff8b82:$2"
    fi
    DF="$(python3 -c "print(';'.join(f'{f}:ff8400-ff8470;{f}:ff8800-ff8870' for f in range(3000,3400,50)))")"
    ( cd "$d" && MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" \
      POKES="$PK" DUMPS="$DF" FRAMES=4420 GUARD_DEBUG=0 \
      "$REPO/tools/run_replay_guarded.sh" vsavjw "$RPL" out.log s1 >emu 2>&1 ) &
}

echo "== six orderings of three tenants, on $BUILD"
for a in 13 10 11; do for b in 13 10 11; do
    [ "$a" = "$b" ] && continue
    run_pair "$a" "$b" "$a-$b"
done; done
run_pair 13 10 nopoke_ctl nopoke        # verdict control
wait

check() { # check <tag> <p1class> <p2class>
    d="$W/$1"
    if ! grep -q "^END " "$d/out.log" 2>/dev/null; then
        echo "     $(grep -m1 '^CRASH\|^REGS' "$d/out.log" 2>/dev/null || tail -2 "$d/emu")"
        return 1
    fi
    python3 - "$d" "$(base_of "$2")" "$(base_of "$3")" <<'PY'
import glob, sys, struct
d, w1, w2 = sys.argv[1], int(sys.argv[2], 16), int(sys.argv[3], 16)
def base(addr):
    v = {struct.unpack(">I", open(f, "rb").read()[0x60:0x64])[0]
         for f in glob.glob(f"{d}/dump_*_{addr}.bin")}
    return v
b1, b2 = base("ff8400"), base("ff8800")
if b1 != {w1} or b2 != {w2}:
    print(f"       P1 +0x60.l={[hex(x) for x in sorted(b1)]} want {w1:#x}; "
          f"P2={[hex(x) for x in sorted(b2)]} want {w2:#x}")
    sys.exit(1)
PY
}

for a in 13 10 11; do for b in 13 10 11; do
    [ "$a" = "$b" ] && continue
    tag="$a-$b"; label="$(name_of "$a") vs $(name_of "$b")"
    if check "$tag" "$a" "$b"; then ok "$label — match formed, both loaded, no crash"
    else bad "$label — see above"; fi
done; done

echo "== verdict control: without the forced picks the check must REFUSE"
if check nopoke_ctl 13 10 >/dev/null 2>&1; then
    bad "control: an UNPOKED run passed the identity check — the gate cannot"
    echo "     tell a tenant pairing from whatever the replay picks on its own,"
    echo "     so every ok above is vacuous"
else
    ok "control: the unpoked run is correctly rejected"
fi

[ "$fail" = 0 ] && echo "PASS: tenant-vs-tenant, all six orderings (CLAUDE.md §4 coverage)" \
    || { echo "FAIL: tenant pairings"; exit 1; }
