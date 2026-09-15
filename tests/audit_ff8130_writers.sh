#!/bin/sh
# audit_ff8130_writers.sh — who writes RAM:$FF8130 on vanilla vsavj, every write form and both byte lanes: five DIRECT writers (the id fold's store at PRG:0x00A446 and four constant writes), block writes that cover the word, and two writers of the NEIGHBOUR byte $FF8131 that a word-wide tap reports on it (14z-157, #100).
#
# MUST-FIRE: shadow-tool: one-form-scan — section A's inventory built by the #100-shaped scan (the 0x0130 displacement word read at opcode+2 only) instead of the every-offset decoder must fail the five-writer inventory, so the inventory is proven to rest on a decoder that sees a write carrying an immediate word before its displacement
# MUST-FIRE: perturbed-copy: lane-blind — section B's tap logs read with the write MASK ignored must put PRG:0x02033E and PRG:0x020AE8 on the $FF8130 lane and fail the lane assertion, so the lane attribution is proven to rest on the mask
#
# WHY IT EXISTS. Two records disagreed about this byte's writers. #100 (2026-08-18)
# scanned the opcode image for the displacement word 0x0130 right after an opcode
# and found ONE writer, PRG:0x00A446 — the store after the id fold. The 14z-64
# venue-asset audit (docs/game/atlas/venue_assets.md, §2 addendum) named two
# others, 0x02033E and 0x020AE8. Measured 14z-157, at the maintainer's word ("we
# measure, we don't believe or assume"): NEITHER record is the writer set.
#
# SECTION A — STATIC, the vsavj OPCODE view (tests/lib/decrypt_cache.sh). An
# instruction is decoded at EVERY even offset of the first MB and kept when its
# destination is $130(a5) (the A5 = $FF8000 frame) or an absolute $FF8130 and its
# mnemonic is not read-only; every frozen address must decode as frozen AND sit on
# an instruction boundary (linear sweeps started 16/32/64/128 bytes earlier land
# on it). Frozen:
#   PRG:0x00A446  move.b d0,$130(a5)     after move.b $382(a0),d0 / andi.w #$f,d0
#   PRG:0x08E336  move.b #$e,$130(a5)
#   PRG:0x08E342  move.b #$5,$130(a5)
#   PRG:0x090BD2  move.b #$5,$130(a5)
#   PRG:0x090BE4  move.b #$e,$130(a5)
# The #100-shaped scan on the same image returns exactly {0x00A446}: the immediate
# word between opcode and displacement hides the other four. 0x02033E
# (move.b $ac(a5),$131(a5)) and 0x020AE8 (bset.b d2,$131(a5)) write $131(a5), the
# neighbour byte. The block writers section B sees decode as indirect long writes.
#
# SECTION B — MEASURED, tests/lua/tap_writes.lua on vsavj (a memory tap, no
# debugger), TAP=ff8130,2 — the containing WORD, because a byte tap on this 16-bit
# bus sees nothing of a word access ([MFI-13], docs/platform/gotchas.md) — every
# hit bucketed by its write MASK (0xFF00 the $FF8130 lane, 0x00FF the $FF8131 lane,
# 0xFFFF both). Three legs, frozen per PC (lane, hits), measured 14z-157 on the
# reference MAME binary:
#   replay 11_pick_donovan, 3,600 frames (boot, attract, select, VS, match):
#     0x000D34 both 2, 0x000D3A both 2 (boot RAM test: write, compare, restore),
#     0x000DD8 both 1 (boot work-RAM clear from $FF0000),
#     0x016DFC both 4 (lea $100(a5),a6 then 32 longs: $FF8100-$FF817F cleared),
#     0x02033E $FF8131 1 (frame 825, 0x00), 0x020AE8 $FF8131 1 (frame 1699, 0x01)
#   replay 01_attract_long, 7,200 frames: the four block writers, 0x016DFC 18 hits
#   replay 26_don_arcade_mash, 40,500 frames (1P arcade, several CPU matches and
#     their transitions): the four block writers (0x016DFC 72), plus the two
#     $FF8131 writers once each
# In none of the three does any of the five direct writers fire, and 0x02033E /
# 0x020AE8 never touch the $FF8130 lane.
#
# Usage: ROMDIR=... [MAME_BIN=<reference binary, default ~/.cache/vampire-saved/mame-ref/cps2>] tests/audit_ff8130_writers.sh
# Runtime: ~1 min (three MAME legs of 4 s, 7 s and 35 s measured 14z-157, plus the
# first-MB decode), emulator tier.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
if [ -z "${ROMDIR:-}" ]; then
    if [ -n "$MODE" ]; then echo "REFUSED: CONTROL=$MODE needs ROMDIR"; exit 3; fi
    echo "FAIL: set ROMDIR"; exit 1
fi
# ABSOLUTE, as in every emulator gate since 14z-132.
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
export ROMDIR
BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame-ref/cps2}"
if [ ! -x "$BIN" ]; then
    if [ -n "$MODE" ]; then echo "REFUSED: CONTROL=$MODE needs the reference MAME binary at $BIN"; exit 3; fi
    echo "FAIL: no reference MAME binary at $BIN (tools/setup_mame.sh with WIDE=0)"; exit 1
fi
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
export SDL_VIDEODRIVER="${SDL_VIDEODRIVER:-dummy}"

# the decrypted view is ROM-derived (rule 7) and comes from the SHARED CACHE
. "$REPO/tests/lib/decrypt_cache.sh"
decrypt_view vsavj "$W/vj_op.bin" "$W/vj_dat.bin" || { echo "FAIL: vsavj decrypt view"; exit 1; }

leg() { # <name> <replay> <frames>
    MAME_BIN="$BIN" MAME_SANDBOX="$W/sb_$1" MAME_ROMPATH="$ROMDIR" \
        REPLAY="$REPO/tests/replays/$2.rpl" TAP=ff8130,2 FRAMES="$3" TRACE_OUT="$W/$1.tap" \
        tools/run_mame.sh vsavj -autoboot_script "$REPO/tests/lua/tap_writes.lua" \
        > "$W/$1.out" 2>&1 < /dev/null || true
    grep -q "^END $3 " "$W/$1.tap" 2>/dev/null \
        || { echo "FAIL: leg $1 ($2) did not reach frame $3 (see its MAME output)"; tail -3 "$W/$1.out"; exit 1; }
}
leg r11 11_pick_donovan 3600
leg attract 01_attract_long 7200
leg arcade 26_don_arcade_mash 40500

python3 - "$W/vj_op.bin" "$W" "$MODE" <<'PY'
import hashlib
import re
import sys

import capstone

OPC, WD = sys.argv[1], sys.argv[2]
MODE = sys.argv[3] if len(sys.argv) > 3 else ""
img = open(OPC, "rb").read()
print("  vsavj opcode view sha1 %s (%d B)" % (hashlib.sha1(img).hexdigest(), len(img)))
md = capstone.Cs(capstone.CS_ARCH_M68K,
                 capstone.CS_MODE_BIG_ENDIAN | capstone.CS_MODE_M68K_000)

TARGETS = ("$130(a5)", "$ff8130", "$ffff8130", "$8130.w")
READ_ONLY = {"cmp", "cmpi", "cmpa", "cmpm", "tst", "btst", "chk", "lea", "pea", "jsr", "jmp"}
LIMIT = 0x100000

EXPECT_A = {
    0x00A446: "move.b d0, $130(a5)",
    0x08E336: "move.b #$e, $130(a5)",
    0x08E342: "move.b #$5, $130(a5)",
    0x090BD2: "move.b #$5, $130(a5)",
    0x090BE4: "move.b #$e, $130(a5)",
}
FOLD = {0x00A43E: "move.b $382(a0), d0", 0x00A442: "andi.w #$f, d0"}
NEIGHBOUR = {0x02033E: "move.b $ac(a5), $131(a5)", 0x020AE8: "bset.b d2, $131(a5)"}
BLOCK = {0x000D34: "move.l d0, (a0)", 0x000D3A: "move.l d2, (a0)+",
         0x000DD8: "move.l d0, (a0)+", 0x016DFC: "move.l d1, (a6)+"}
BW = {0x000D34: ("both", 2), 0x000D3A: ("both", 2), 0x000DD8: ("both", 1)}


def merged(*ds):
    out = {}
    for d in ds:
        out.update(d)
    return out


LEGS = [
    ("r11", "11_pick_donovan", 3600,
     merged(BW, {0x016DFC: ("both", 4), 0x02033E: ("$FF8131", 1), 0x020AE8: ("$FF8131", 1)})),
    ("attract", "01_attract_long", 7200, merged(BW, {0x016DFC: ("both", 18)})),
    ("arcade", "26_don_arcade_mash", 40500,
     merged(BW, {0x016DFC: ("both", 72), 0x02033E: ("$FF8131", 1), 0x020AE8: ("$FF8131", 1)})),
]


def dec(a):
    for i in md.disasm(img[a:a + 10], a, count=1):
        return i
    return None


def txt(i):
    return "%s %s" % (i.mnemonic, i.op_str)


def is_write(i):
    if i is None:
        return False
    d = i.op_str.split(",")[-1].strip().lower()
    return any(t in d for t in TARGETS) and i.mnemonic.split(".")[0] not in READ_ONLY


def every_offset():
    out = {}
    for a in range(0, LIMIT, 2):
        i = dec(a)
        if is_write(i):
            out[a] = i
    return out


def one_form():
    """The #100-shaped scan: the displacement word 0x0130 read at opcode+2 only."""
    out = {}
    for a in range(2, LIMIT, 2):
        if img[a:a + 2] == b"\x01\x30":
            i = dec(a - 2)
            if is_write(i):
                out[a - 2] = i
    return out


def lands(a, back):
    p = a - back
    while p < a:
        i = dec(p)
        p += i.size if i else 2
    return p == a


def checker(quiet):
    fails = []

    def need(ok, what):
        if not quiet:
            print(("  ok   " if ok else "  FAIL ") + what)
        if not ok:
            fails.append(what)
    return fails, need


EVERY, ONE = every_offset(), one_form()


def section_a(scan, quiet=False):
    fails, need = checker(quiet)
    got = {a: txt(i) for a, i in scan.items()}
    need(got == EXPECT_A,
         "the direct writers of $FF8130 in the first MB are exactly the five frozen ones (got %s)"
         % ", ".join("%06X %s" % kv for kv in sorted(got.items())))
    need(sorted(ONE) == [0x00A446],
         "the #100-shaped scan reproduces its record: one writer, PRG:0x00A446 (got %s)"
         % ["%06X" % a for a in sorted(ONE)])
    for a, want in sorted(merged(EXPECT_A, FOLD, NEIGHBOUR, BLOCK).items()):
        i = dec(a)
        need(i is not None and txt(i) == want and all(lands(a, b) for b in (16, 32, 64, 128)),
             "PRG:0x%06X decodes as `%s` on an instruction boundary" % (a, want))
    return fails


LOGRE = re.compile(r"^frame (\d+) PC ([0-9a-f]+) off ([0-9a-f]+) data ([0-9a-f]+) mask ([0-9a-f]+)")


def lane(mask, blind):
    if blind:
        return "both"          # the mask ignored: every hit reads as a write to the whole word
    hi, lo = bool(mask & 0xFF00), bool(mask & 0x00FF)
    return {(True, True): "both", (True, False): "$FF8130", (False, True): "$FF8131"}.get((hi, lo), "none")


def section_b(blind=False, quiet=False):
    fails, need = checker(quiet)
    for name, replay, frames, want in LEGS:
        hits, end = [], None
        for line in open("%s/%s.tap" % (WD, name)):
            m = LOGRE.match(line)
            if m:
                hits.append((int(m.group(2), 16), int(m.group(3), 16), lane(int(m.group(5), 16), blind)))
            elif line.startswith("END "):
                end = int(line.split()[1])
        need(end == frames, "%s: the tap ran to frame %d" % (replay, frames))
        need(all(off == 0xFF8130 for _, off, _ in hits), "%s: every hit is on the tapped word" % replay)
        per = {}
        for pc, _, ln in hits:
            per.setdefault(pc, []).append(ln)
        got = {pc: ("/".join(sorted(set(ls))), len(ls)) for pc, ls in per.items()}
        need(got == want, "%s: writers by lane and hit count as frozen (got %s)"
             % (replay, ", ".join("%06X %s x%d" % (pc, ln, n) for pc, (ln, n) in sorted(got.items()))))
        need(not (set(per) & set(EXPECT_A)), "%s: none of the five direct writers fires" % replay)
        low_hit = {pc for pc, ls in per.items() if set(ls) & {"both", "$FF8130"}}
        need(not (low_hit & set(NEIGHBOUR)),
             "%s: PRG:0x02033E and PRG:0x020AE8 never write the $FF8130 lane" % replay)
    return fails


print("== A. static: the writers of $FF8130 in the opcode image")
fa = section_a(ONE if MODE == "one-form-scan" else EVERY)
print("== B. measured: the word tap, by write-mask lane")
fb = section_b(blind=(MODE == "lane-blind"))
if MODE == "":
    if section_a(ONE, quiet=True):
        print("CONTROL FIRED: one-form-scan — the #100-shaped scan finds %d of the 5 direct writers and the inventory fails"
              % len(set(ONE) & set(EXPECT_A)))
    else:
        print("CONTROL DEAD: one-form-scan — the #100-shaped scan passed the five-writer inventory")
        sys.exit(1)
    if any("never write the $FF8130 lane" in f for f in section_b(blind=True, quiet=True)):
        print("CONTROL FIRED: lane-blind — with the mask ignored, PRG:0x02033E and PRG:0x020AE8 read as writers of $FF8130 and the lane assertion fails")
    else:
        print("CONTROL DEAD: lane-blind — ignoring the mask did not fail the lane assertion")
        sys.exit(1)
if fa or fb:
    print("FAIL: audit_ff8130_writers — %d assertion(s) failed" % (len(fa) + len(fb)))
    sys.exit(1)
print("PASS: audit_ff8130_writers — RAM:$FF8130 has five direct writers (the id fold's store and four constant writes), none firing in boot, attract, select, match or a 1P arcade run; block clears cover it; PRG:0x02033E and PRG:0x020AE8 write $FF8131")
PY
