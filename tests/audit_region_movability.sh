#!/bin/sh
# audit_region_movability.sh — which regions can actually live in wide_ext?
#
# WHY (M3b, 14z-77). The merge's binding constraint is the CRYPT WINDOW, not
# total size: one tenant already saturates hole_a, and three tenants keeping
# their own region copies need 761,316 bytes of its 264,544
# (tests/test_region_overlap.sh). wide_ext has 2 MB spare, so the merge
# depends entirely on how much can move there.
#
# `region_space` (slice J) makes that a manifest tunable. This audit measures
# what the tunable can actually be USED for, because "not named in near_map or
# a layout_group" turns out NOT to be a sufficient condition for movability:
# moving all ten unconstrained regions at once produced a vec3 ADDRESS ERROR
# (odd A0) at vanilla PC 0x015098, frame 1401. Bisected to ONE region.
#
# FROZEN RESULT (14z-78, donovan-m3a) — **EVERY REGION MEASURED HERE MOVES.**
#   anim         runs     — 0x20F00. Was the ONE crasher and M3b's only
#                          remaining blocker; FIXED 14z-78, see below.
#   aux0_4       runs     — 0xE070 of data
#   x06717c      runs     — 0x154 of CODE. **Code DOES run from the raw
#                          extension**, which is what test_crypt_boundary.sh
#                          predicted and this confirms at runtime.
#   hitbox(+proj) runs    — 0x35C2 of data
#
# HOW anim's CRASH WAS RESOLVED (14z-78). It was never a layout constraint.
# donovan.toml's two select-companion thunks baked `207c000dda1e` (movea.l
# #$000DDA1E,A0) — anim's placed address, hand-computed once into authored
# hex, tracking nothing. Move anim and both bodies still aimed at the vacated
# range, where x2b7ef4 had slid in; the resolver read its bytes as 16-bit
# offsets and took a vec3 address error at vanilla PC 0x015098. Measured: site
# 0x845EC executes at f1401 and f1402 on the working build, and the moved build
# faulted on the SECOND. The fix is `region_subst` (placed[anim]+0xA9AE,
# resolved at emit time) and is inert in the default layout — donovan-m3a stays
# bit-exact at 4b7d0dc7. The class is now a BUILD error: see
# tests/test_thunk_addr_literal.sh.
#
# WHY THAT MATTERS MORE THAN IT LOOKS. anim is 371,712 of the 470,200 bytes
# three tenants needed from a 344,640-byte crypt window. With it movable the
# requirement drops to 98,488 (D 67,314 / H 31,174 / P 0) and the overflow is
# gone — so this audit is what says M3b's binding constraint is CLEARED.
#
# SCOPE, STATED PLAINLY: every case below builds DONOVAN (donovan.toml,
# TENANT_CHAR=0x13, replay 12). The arithmetic above is a three-tenant figure
# but the MEASUREMENT is one tenant's regions. Huitzil's and Pyron's anim are
# UNMEASURED here. Static evidence says they should be fine — huitzil.toml
# already spells its anim reference `region_subst` (:1387) and the 14z-78 sweep
# found no baked placed address in either manifest — but that is an argument,
# not a measurement, and this project's rule is that they are different things.
# Extending this audit to all three is NOT just a loop over manifests: a "runs"
# verdict needs a LIVENESS CONTROL proving the tenant's match actually formed,
# or an unformed match reads as a clean pass (the blind-zero trap, paid for
# twice — see NEXT_SESSION "RIG LESSON"). Donovan needs no such control today
# only because his case USED to crash, which proved the path ran.
#
# 14z-90 (GitHub issue #5): "needs no such control today" was WRONG as an
# argument about THIS script, and the control is now in place for every leg —
# the runner's exit code and an `^END ` line, with anything else scored `dead`
# so it fails rather than passing. Ground truth: tests/test_movability_liveness.sh.
# Measured on the pre-fix scoring with an emulator that never starts: exit 0 and
# the full PASS text, budget claim included.
#
# PROVENANCE OF THE FROZEN VERDICTS, so a rerun does not have to trust the
# above: anim's `runs` was NOT established by this script's verdict. Commit
# 72c4338 established it by a three-way probe comparison — site 0x845EC fires
# twice per select entry (f1401/f1402) on a working build, the baked build
# fired once and faulted, the fixed build reproduced the working signature.
# The other three regions were measured in the 14z-77 batch in which anim
# CRASHED, and a crash cannot come from a dead emulator. So the recorded
# conclusions stand; what was broken was the reproduction contract, which is
# what this fix restores.
#
# The expectations stay frozen in both directions: if anim ever crashes here
# again, a placement-dependent reference has been reintroduced somewhere the
# build-time guard cannot see, and that is news worth stopping for.
#
# 14z-123 (the documentation pass, inferred_claims row 13): H/P anim
# movability is now MEASURED, not inferred. Two more cases build Huitzil and
# Pyron with `region_space = "anim=wide_ext"` injected into their own
# manifests (the four-track recipe of HANDOFF "How to build"), run replay 12
# with the tenant forced by the early-window pokes, and carry the liveness
# control the header above demanded — TWO facts read from P1's fighter block
# at three in-match frames (DUMPS through the guarded runner):
#   (a) `+0x60.l` == the BUILD's own hitbox-base table row for the tenant
#       (prg/vm3j.04d @ 0x3D97A, the audit_continue_switch derivation) —
#       the tenant's match FORMED (never +0x382, the voice-flavor byte);
#   (b) `+0x1C.l` (the anim node pointer) lies INSIDE the placed anim range
#       and that range sits at or above 0x400000 — the MOVED region is the
#       one being walked. A "runs" without (b) would only prove the emulator
#       ran; with it, the verdict is about the region.
# FROZEN RESULT (14z-123, the hui52 / pyron36 manifests, replay 12):
#   hui_anim    runs — anim 0x1E800 placed at 0x400010; +0x60.l 0xE7690 (the
#                      build's row 0x10); +0x1C.l 0x402450/0x4052EE/0x400748 at
#                      f3000/3300/3600 — 3/3 inside the moved range
#   pyron_anim  runs — anim 0x1B500 placed at 0x400010; +0x60.l 0xE11AC (row
#                      0x11); +0x1C.l 0x400212/0x406514/0x40371A — 3/3 inside
# (The first run of this extension scored both DEAD: placements.json stores
# decimal ints and the checker parsed them as hex — 888256 read as 0x888256.
# The control did its job: an unproven leg is `dead`, never `runs`.)
#
# Usage: ROMDIR=... [MAME_BIN=...] [CASES="anim aux4 codereg hitboxes hui_anim pyron_anim"]
#        tests/audit_region_movability.sh
# On-demand: one build + one guarded replay per case (~10 min for the four
# Donovan cases, ~8 min per tenant case).
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-77, RE-FROZEN 14z-78: which regions can live in wide_ext? ALL OF THEM
#   NOW — anim, aux0_4, hitbox(+proj) and x06717c (a CODE region, so code
#   executes from the raw extension). anim was the ONE crasher and M3b's
#   binding constraint; its vec3 (odd A0, vanilla PC 0x015098) was NOT a
#   layout limit but a placed address baked into two donovan.toml thunk bodies
#   — fixed 14z-78 with region_subst, and the class is now a BUILD error
#   (test_thunk_addr_literal). Three tenants need 98,488 of the 344,640-byte
#   crypt window, was 470,200. MEASURED ON ALL THREE (14z-123): H/P anim run
#   from wide_ext too, with a LIVENESS control — the tenant's +0x60.l equals
#   the build's own table row and the anim node pointer sits inside the moved
#   range at three in-match frames; CASES= selects the six cases. Expectations
#   frozen BOTH ways: if anim crashes again that is a REGRESSION. On-demand,
#   ~4.5 min
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
# 14z-132: ABSOLUTE. Gates `cd` into work dirs and then compose paths that
# still contain $ROMDIR (e.g. MAME_ROMPATH="...;$ROMDIR"); a RELATIVE value —
# which is how the runners invoke everything (ROMDIR=../ROMS) — then resolves
# against the WORK dir and silently finds no reference members. Kept as a
# VARIABLE (forks set their own); only made absolute, and only if it exists,
# so a gate that means to SKIP on a missing ROMDIR still does.
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
WIDE_ZIP="${WIDE_ROMSET:-$PWD/build/wide0/rompath/vsavjw.zip}"
if [ ! -x "$MAME_BIN" ] || [ ! -f "$WIDE_ZIP" ]; then
    echo "SKIP: need the WIDE MAME binary and a WIDE overlay romset"
    exit 0
fi

# 14z-90 (issue #5): a seam so the liveness control can inject a stub runner
# and prove this audit FAILS on a dead emulator without a ~4.5 min build.
# Production default is the real guarded runner; nothing else sets it.
GUARDED="${GUARDED_RUNNER:-tools/run_replay_guarded.sh}"
BUILDER="${BUILDER_CMD:-tools/build_donovan.sh}"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK" build/manifest/_movability.toml' EXIT
POK="1400:ff8782:13;1450:ff8782:13;1500:ff8782:13"
fail=0

case_probe() {  # case_probe <label> <spec> <expect: crash|runs>
    python3 - "$2" <<'PY'
import sys, pathlib
man = pathlib.Path("build/manifest/donovan.toml").read_text()
anchor = 'hole_b_regions = "aux0_4,hitbox"'
# donovan.toml carries the key TWICE — once in [[tenant]] and once in the
# superseded flat [port] below it. normalise_tenants() prefers [[tenant]], so
# inject into the FIRST occurrence only.
n = man.count(anchor)
assert n >= 1, "manifest shape moved; this probe needs updating"
pathlib.Path("build/manifest/_movability.toml").write_text(
    man.replace(anchor, anchor + '\nregion_space = "%s"' % sys.argv[1], 1))
PY
    if ! KEY_SET=vsavj TENANT_MANIFEST=build/manifest/_movability.toml \
         TENANT_CHAR=0x13 WIDE_ROMSET="$WIDE_ZIP" \
         GEN_FLAGS="--allow-plausible --tripwire-open --profile cps2-wide-v1" \
         "$BUILDER" 6 "$WORK/$1" > "$WORK/$1.build" 2>&1; then
        echo "  FAIL: $1 — the BUILD errored, so runtime says nothing"
        tail -5 "$WORK/$1.build"
        fail=1; return
    fi
    # 14z-90 (issue #5): the verdict used to derive from the ABSENCE of a crash
    # string, with the runner's status thrown away by `|| true`. Every way of
    # producing no output therefore scored `runs`: an empty log, a missing log
    # (grep exits 2, which lands in the else), a crashed or never-started
    # emulator. run_replay_guarded.sh already exits non-zero unless the log
    # ends in a clean END line — that signal was being discarded. The file's
    # own header demands this control for the H/P extension; it was never
    # applied to the existing legs.
    rc=0
    POKES="$POK" MAME_ROMPATH="$WORK/$1/rompath;$ROMDIR" \
        "$GUARDED" vsavjw \
        tests/replays/12_donovan_vs_cpu.rpl "$WORK/$1.rl" "$WORK/$1.box" \
        >/dev/null 2>&1 || rc=$?
    if grep -qE '^(CRASH|PCWEEDS|SOFTRESET)' "$WORK/$1.rl" 2>/dev/null; then
        got=crash
    elif [ "$rc" = 0 ] && grep -q '^END ' "$WORK/$1.rl" 2>/dev/null; then
        got=runs
    else
        # matches neither expectation, so the case always FAILs — a dead rig
        # must never be scored as evidence either way.
        got=dead
    fi
    if [ "$got" = "$3" ]; then
        detail=""
        [ "$got" = crash ] && detail="  ($(grep -m1 '^CRASH' "$WORK/$1.rl"))"
        echo "  ok: $1 -> $got$detail"
    else
        echo "  FAIL: $1 -> $got, expected $3"
        [ "$got" = dead ] && echo "        DEAD RIG: the guarded runner exited" \
            "$rc and/or the log has no END line — this leg measured NOTHING," \
            "so it is evidence for neither verdict (14z-90, issue #5)"
        # A region that STOPS moving is a regression of the 14z-78 fix: some
        # reference has gone back to being placement-dependent. Start with the
        # build-time guard's blind spot — a raw longword in embedded data, which
        # tests/test_thunk_addr_literal.sh section 3 documents as out of scope —
        # then probe the faulting PC's base register on both layouts and compare.
        [ "$got" = crash ] && echo "        REGRESSION: this region moved as of" \
            "14z-78. Suspect a placement-dependent" && echo "        reference the" \
            "thunk guard cannot see; see tests/test_thunk_addr_literal.sh"
        grep -m1 '^CRASH' "$WORK/$1.rl" 2>/dev/null || true
        fail=1
    fi
}

# 14z-123: a tenant case — inject region_space into the tenant's OWN manifest
# (after its `id = 0xNN` line inside [[tenant]]), build with the four-track
# recipe, run replay 12 with the tenant forced, then the liveness control:
# +0x60.l == the build's table row, and +0x1C.l inside the placed anim range
# (>= 0x400000). Anything short of both is `dead`, never `runs`.
case_tenant() {  # case_tenant <label> <manifest> <char 0xNN> <region> <expect>
    python3 - "$2" "$3" "$4" <<'PY'
import sys, pathlib, re
man = pathlib.Path(sys.argv[1]).read_text()
anchor = "\nid = %s\n" % sys.argv[2]
assert man.count(anchor) == 1, "tenant id line not unique; this probe needs updating"
assert "region_space" not in man, "manifest already sets region_space; this probe needs updating"
pathlib.Path("build/manifest/_movability.toml").write_text(
    man.replace(anchor, anchor + 'region_space = "%s=wide_ext"\n' % sys.argv[3], 1))
PY
    if ! TENANT_MANIFEST=build/manifest/_movability.toml TENANT_CHAR="$3" \
         WIDE_ROMSET="$WIDE_ZIP" \
         GEN_FLAGS="--profile cps2-wide-v1 --allow-plausible --tripwire-open" \
         "$BUILDER" 6 "$WORK/$1" > "$WORK/$1.build" 2>&1; then
        echo "  FAIL: $1 — the BUILD errored, so runtime says nothing"
        tail -5 "$WORK/$1.build"
        fail=1; return
    fi
    tid="$(printf '%02x' "$3")"
    rc=0
    POKES="1400:ff8782:$tid;1450:ff8782:$tid;1500:ff8782:$tid" \
    DUMPS="3000:ff8400-ff847f;3300:ff8400-ff847f;3600:ff8400-ff847f" \
    MAME_ROMPATH="$WORK/$1/rompath;$ROMDIR" \
        "$GUARDED" vsavjw \
        tests/replays/12_donovan_vs_cpu.rpl "$WORK/$1.rl" "$WORK/$1.box" \
        >/dev/null 2>&1 || rc=$?
    if grep -qE '^(CRASH|PCWEEDS|SOFTRESET)' "$WORK/$1.rl" 2>/dev/null; then
        got=crash
    elif [ "$rc" = 0 ] && grep -q '^END ' "$WORK/$1.rl" 2>/dev/null; then
        # END alone is the 14z-90 control (the emulator ran). The region
        # verdict needs the two block facts:
        if live="$(python3 - "$WORK/$1" "$3" "$4" <<'PY'
import glob, json, re, struct, sys
d, char, region = sys.argv[1], int(sys.argv[2], 16), sys.argv[3]
data = open(f"{d}/prg/vm3j.04d", "rb").read()
raw = data[0x3D97A:0x3D97A + 32*4]
sw = bytearray()
for i in range(0, len(raw), 2):
    sw += raw[i+1:i+2] + raw[i:i+1]
tbl = struct.unpack(">32I", bytes(sw))
want = tbl[char]
pl = json.load(open(f"{d}/patch/placements.json"))
pl = pl.get("regions", pl)
r = pl[region]
# placements.json stores INTS (decimal); a hex string is tolerated in case
# the writer ever changes — parsed as hex only when it carries the prefix.
def _n(v): return v if isinstance(v, int) else int(str(v), 16 if str(v).startswith("0x") else 10)
dst, ln = _n(r["dst"]), _n(r["len"])
dumps = sorted(glob.glob(f"{d}.box/dump_*_ff8400.bin") + glob.glob(f"{d}.box/../dump_*_ff8400.bin"))
if not dumps:
    import os
    dumps = sorted(glob.glob(os.path.join(os.path.dirname(d), "dump_*_ff8400.bin")))
if not dumps:
    print("no fighter-block dumps"); sys.exit(1)
bases, nodes = set(), []
for f in dumps:
    b = open(f, "rb").read()
    bases.add(int.from_bytes(b[0x60:0x64], "big"))
    nodes.append(int.from_bytes(b[0x1C:0x20], "big"))
inside = [n for n in nodes if dst <= n < dst + ln]
ok = bases == {want} and dst >= 0x400000 and len(inside) >= 1
print(f"+0x60.l {sorted(hex(b) for b in bases)} (table row {want:#x}); "
      f"{region} placed {dst:#x}+{ln:#x}; +0x1C.l {[hex(n) for n in nodes]} "
      f"({len(inside)}/{len(nodes)} inside the moved range)")
sys.exit(0 if ok else 1)
PY
)"; then got=runs; else got=dead; fi
        echo "        liveness: $live"
    else
        got=dead
    fi
    if [ "$got" = "$5" ]; then
        echo "  ok: $1 -> $got"
    else
        echo "  FAIL: $1 -> $got, expected $5"
        [ "$got" = dead ] && echo "        DEAD RIG or UNPROVEN: the runner exited $rc," \
            "or the block facts did not hold — this leg is evidence for neither verdict"
        grep -m1 '^CRASH' "$WORK/$1.rl" 2>/dev/null || true
        fail=1
    fi
}

CASES="${CASES:-anim aux4 codereg hitboxes hui_anim pyron_anim}"
want() { case " $CASES " in *" $1 "*) return 0;; *) return 1;; esac; }

echo "== can a region live in wide_ext? (frozen 14z-78; H/P anim 14z-123) =="
want anim     && case_probe anim     "anim=wide_ext"                          runs
want aux4     && case_probe aux4     "aux0_4=wide_ext"                        runs
want codereg  && case_probe codereg  "x06717c=wide_ext"                       runs
want hitboxes && case_probe hitboxes "hitbox=wide_ext,hitbox_proj=wide_ext"   runs
want hui_anim   && case_tenant hui_anim   build/manifest/huitzil.toml 0x10 anim runs
want pyron_anim && case_tenant pyron_anim build/manifest/pyron.toml   0x11 anim runs

[ "$fail" = 0 ] || { echo "FAIL: region movability audit"; exit 1; }
echo "PASS: code runs from the raw extension, and every region measured here"
echo "      moves — including anim, which was the merge's binding constraint"
echo "      until 14z-78. On that basis three tenants need 98,488 of the"
echo "      344,640-byte crypt window (was 470,200); the overflow is gone."
echo "      H/P anim: MEASURED 14z-123 with the liveness control (the tenant's"
echo "      +0x60.l base and an anim node pointer inside the moved range)"
