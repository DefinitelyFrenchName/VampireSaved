#!/bin/sh
# audit_capture_matrix.sh — THE WHOLE CAPTURE-GEOMETRY MATRIX, ours vs native
# vsav2, every reachable (ATTACKER, VICTIM) cell (14z-143, maintainer-directed).
#
# MUST-FIRE: perturbed-copy: perturbed-record-byte — one byte of one record flipped in a copy of our image must break that cell's comparison (mode: section 1 compares that copy and must fail)
# MUST-FIRE: known-bad: fixed-count-comparison — a FIXED 20-record comparison must invent differences at exactly the small-spacing attackers (mode: section 1 uses the fixed count and must fail — the instrument's own negative control)
#
# WHY IT EXISTS. Pyron's attacker row 0x11 was unported for the life of the
# project and was found by an INVENTORY, not by play: at 14z-130 the bank_map
# correction enabled the generic per-character repoint on capture_kf_ptr, and
# auditing what that repoint WOULD write named row 0x11 as a new write. It was
# then measured (14z-131) and ported (14z-143). The maintainer's conclusion,
# and this gate: *"that makes a strong argument for checking the whole
# combination of VS2 tenants thrown ... as well as our VS2 tenants throwing
# others"* — because the targeted gates only ever look at cells already known
# to be wrong. This one looks at ALL of them, and it is CHEAP: the comparison
# is ROM bytes, not an emulator.
#
# WHAT LICENSES A STATIC COMPARISON. 14z-142/143 measured the same cell twice
# with no shared premise — work RAM in a running game, and these ROM bytes —
# and they agreed exactly (deltas AND poses). So the records ARE what the
# engine draws; the three in-emulator gates (audit_don_grab_pose,
# test_hui_grab_victim, audit_pyron_capture_block) remain the anchors that
# keep that licence honest. This gate does not replace them and says so.
#
# THE STRUCTURE (engine_internals "THE CAPTURE-POSE INSTALLER"): a block is a
# 32-word VICTIM OFFSET TABLE then 8-byte records [dx][dy][flags][pose]; the
# positioner resolves capture_kf_ptr[ATTACKER] then adds the VICTIM's word.
#
# *** THE SPACING TRAP, and section 4 controls for it (paid 14z-143). ***
# Sub-block spacing is PER BLOCK and ranges 0x30 (6 records, attacker 0x06) to
# 0x2b0 (86, attacker 0x07). Comparing a FIXED record count overruns every
# block whose spacing is smaller and reports FALSE differences — it "found"
# four differing attackers (0x06/0x08/0x09/0x0D), which are exactly the four
# with spacing under the count used. Each cell is compared over min(spacing)
# of the two blocks, and section 4 proves the naive comparison fails.
#
# SECTIONS
#   1. THE MATRIX: for every reachable attacker, our served sub-block for
#      every victim equals native vsav2's. Reachable is DECLARED, with why.
#   2. THE #104 LEGACY-SAFETY PREMISE, re-measured rather than cited: for all
#      16 legacy attackers, vsavj's and vs2's BASE victim sub-blocks are
#      byte-identical — which is what makes porting vs2's blocks additive
#      instead of a legacy change ([VSP-1]).
#   3. WHAT THE PORT ADDS: vs2 gives victims 0x10/0x11/0x13 their OWN
#      sub-blocks where vsavj aliases them onto the base half. If this ever
#      stops being true the #104 fix has no subject.
#   4. MUST-FIRE CONTROLS: (a) one perturbed record byte in a copy of the
#      image must fail section 1; (b) the FIXED-COUNT comparison must report
#      differences where the per-spacing one reports none — the instrument's
#      own negative control, so a future edit cannot quietly reintroduce it.
#
# EXCLUSIONS, declared rather than skipped silently:
#   * 0x12 Dark Gallon — a VANILLA character on VANILLA data ([VSP-21]); vsavj
#     aliases 0x12 -> 0x02 and so does vs2, so he is compared against VSAVJ.
#   * 0x14-0x17, 0x19-0x1F — no character exists at these ids in either game.
#   * victim PIXELS are never evidence here ([VSP-168]): a legacy victim is
#     VS's art on our leg and VS2's on the native one. This gate compares the
#     logical records only.
#
# Static, no emulator, ~2 s. Needs $ROMDIR and a build dir.
# Usage: ROMDIR=... tests/audit_capture_matrix.sh
# Build dir (code default, [VSP-165]): MERGED=build/m3b_merged26
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; export REPO
cd "$REPO"
MERGED="${MERGED:-build/m3b_merged26}"
: "${ROMDIR:?set ROMDIR}"
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
[ -f "$MERGED/verify_data.bin" ] || { echo "FAIL: no $MERGED/verify_data.bin (set MERGED=)"; exit 1; }
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
CAPM_MODE="${VS_CTL:-}"; export CAPM_MODE

. "$REPO/tests/lib/decrypt_cache.sh"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
decrypt_view vsavj "$W/vj_op.bin" "$W/vj.bin" || { echo "FAIL: vsavj decrypt view"; exit 1; }
decrypt_view vsav2 "$W/v2_op.bin" "$W/v2.bin" || { echo "FAIL: vsav2 decrypt view"; exit 1; }

VJ="$W/vj.bin" V2="$W/v2.bin" OURS="$MERGED/verify_data.bin" MERGED="$MERGED" python3 - <<'PY'
import os, struct, sys
from pathlib import Path
vj  = Path(os.environ["VJ"]).read_bytes()
v2  = Path(os.environ["V2"]).read_bytes()
ours= Path(os.environ["OURS"]).read_bytes()
TJ, T2 = 0x0BE27A, 0x0D8418          # the two games' capture_kf_ptr tables
u32 = lambda b,a: struct.unpack_from(">I",b,a)[0]
u16 = lambda b,a: struct.unpack_from(">H",b,a)[0]

# Reachable ATTACKER ids, declared with the reason each is in or out.
LEGACY  = list(range(0x10))                       # the 15 + the 0x0B gap slot
TENANTS = {0x10: "huitzil", 0x11: "pyron", 0x13: "donovan"}
OBORO   = 0x18                                    # vanilla vsavj, ported alongside 0x08
GALLON  = 0x12                                    # vanilla character, VANILLA data
NO_CHAR = [0x14,0x15,0x16,0x17,0x19,0x1a,0x1b,0x1c,0x1d,0x1e,0x1f]

def spacing(buf, base):
    dis = sorted(set(u16(buf, base+2*i) for i in range(32)))
    return min(dis[i+1]-dis[i] for i in range(len(dis)-1))
def cell(buf, base, v, n):
    o = u16(buf, base+2*v)
    return buf[base+o : base+o+n]

# KNOWN-OPEN DIVERGENCES — frozen as the OBSERVED state, the
# audit_pyron_capture_block EXPECT_MATCH pattern: the gate records a defect
# that is measured and unruled rather than going red forever, and REMOVING a
# row here is what proves a fix landed.
KNOWN = set()   # EMPTY since 14z-144. `set()` not `{}`:
                # a braced literal with no members is a DICT.
# The retired rows, kept as the record of what this gate caught:
    # Donovan (0x13) throwing JEDAH (0x0F) uses the DONOVAN-victim sub-block,
    # not Jedah's. Cause, measured 14z-143: donovan.toml's `throw_victim_keyframes`
    # carries the 14z-64 mirror-victim `fixes = "0x1E:0b30:0d88"`, which rewrites
    # victim entry [0x0F] to the Donovan-victim block. That is CORRECT on the
    # STOCK track, where Donovan occupies slot 0x0F and victim 0x0F IS Donovan.
    # On a WIDE build Donovan is at 0x13 and 0x0F is JEDAH, restored — so the
    # rewrite redirects a LEGACY victim's keyframes. The manifest's own note
    # calls the fix "harmless" on variant builds because "[0x0F] is never a
    # TENANT victim there", which is true and not the question: it is a
    # reachable LEGACY victim. Magnitude: 225 of 408 bytes differ; the last
    # keyframe is (-61,166) against Jedah's (-76,32).
    # PRE-EXISTING since 14z-64, identical on merged23. GAMEPLAY SURFACE, so
    # the fix is the maintainer's call ([VSP-10]) — see STATE "Decisions
    # pending". Shape if ruled: gate the `fixes=` row to the base-slot track
    # so the WIDE blob keeps vs2's own [0x0F].
    # CONFIRMED IN-EMULATOR 14z-143 (`tools/capture_sheet.sh 13 0f`): hold-offset
    # overlap 0 of union 19, ours reproducing the Donovan-victim magnitudes and
    # native Jedah's — the static read predicted the running game exactly, which
    # is the second such agreement and is what licenses this gate ([VSP-180]).
    # ~~(0x13, 0x0f)~~ **FIXED AND REMOVED 14z-144** (maintainer-ruled option
    # (a), 2026-09-09): donovan.toml's row gained `fixes_variant = ""`, the
    # `_variant` twin row_hex() already defined for new_hex, taught to the
    # data_port fixes key — so the mirror-victim rewrite applies on the
    # base-slot track ONLY and every WIDE blob keeps vs2's own [0x0F].
    # Measured on the rebuild: the WIDE program delta is EXACTLY TWO BYTES,
    # the logical word at blob offset 0x1E going 0d88 -> 0b30; the stock twin
    # rebuilt BYTE-IDENTICAL (e86e1d04), which is the control that the
    # base-slot track kept the fix. The analysis above is KEPT, not deleted:
    # it is why the variant twin is empty ([VSP-13]).

fails, notes = [], []

# THE EXECUTABLE FORM (CAPM_MODE = the CONTROL name): the perturbed copy of
# our image, or the FIXED-count comparison, is what section 1 runs on.
MODE = os.environ.get("CAPM_MODE", "")
FIXED = 20                                   # the 14z-143 trap, encoded
if MODE == "perturbed-record-byte":
    _c = bytearray(ours); _pa = u32(ours, TJ+4*0x11); _off = u16(ours, _pa+2*0x03)
    _c[_pa+_off+8] ^= 0x01; ours = bytes(_c)

# ── 1. THE MATRIX ───────────────────────────────────────────────────────────
checked = mism = 0
for a in LEGACY + sorted(TENANTS) + [OBORO]:
    po, p2 = u32(ours, TJ+4*a), u32(v2, T2+4*a)
    n = min(spacing(ours, po), spacing(v2, p2))
    if MODE == "fixed-count-comparison": n = 8*FIXED
    d = [v for v in range(32) if cell(ours,po,v,n) != cell(v2,p2,v,n)]
    d = [v for v in d if (a,v) not in KNOWN]
    checked += 32
    if d:
        mism += len(d)
        fails.append(f"1: attacker {a:#04x}: {len(d)} victim cell(s) differ from native "
                     f"vsav2 — {[hex(x) for x in d]}")
notes.append(f"1: KNOWN-OPEN divergences declared and excluded: "
             f"{[(hex(a),hex(v)) for a,v in sorted(KNOWN)]} — removing a row "
             f"here is what proves a fix landed")
if not mism:
    notes.append(f"1: {checked} (attacker,victim) cells over "
                 f"{len(LEGACY)+len(TENANTS)+1} reachable attackers — every one "
                 f"byte-identical to native vsav2")

# Dark Gallon is compared against VANILLA, not vs2 ([VSP-21])
pg_o, pg_j = u32(ours, TJ+4*GALLON), u32(vj, TJ+4*GALLON)
ng = min(spacing(ours,pg_o), spacing(vj,pg_j))
dg = [v for v in range(32) if cell(ours,pg_o,v,ng) != cell(vj,pg_j,v,ng)]
if dg:
    fails.append(f"1: Dark Gallon {GALLON:#04x} differs from VANILLA vsavj at "
                 f"{[hex(x) for x in dg]} — he is a vanilla character on vanilla data")
else:
    notes.append(f"1: Dark Gallon {GALLON:#04x} matches VANILLA vsavj on all 32 victims "
                 f"(vsavj and vs2 both alias 0x12 -> 0x02; vanilla wins ties)")
notes.append(f"1: excluded as characterless in both games: "
             f"{[hex(x) for x in NO_CHAR]}")

# ── 2. THE #104 LEGACY-SAFETY PREMISE ───────────────────────────────────────
bad2 = []
for a in LEGACY:
    pj, p2 = u32(vj,TJ+4*a), u32(v2,T2+4*a)
    n = min(spacing(vj,pj), spacing(v2,p2))
    d = [v for v in range(16) if cell(vj,pj,v,n) != cell(v2,p2,v,n)]
    if d: bad2.append((a,d))
if bad2:
    fails.append(f"2: the #104 legacy-safety premise FAILS — porting vs2's blocks "
                 f"changes legacy-vs-legacy geometry at "
                 f"{[(hex(a),[hex(v) for v in d]) for a,d in bad2]}")
else:
    notes.append("2: premise holds — all 16 legacy attackers x 16 base victims are "
                 "byte-identical between vsavj and vsav2, so #104 is ADDITIVE")

# ── 3. WHAT THE PORT ADDS ───────────────────────────────────────────────────
aliased_in_vj = own_in_v2 = 0
for a in LEGACY:
    pj, p2 = u32(vj,TJ+4*a), u32(v2,T2+4*a)
    nj, n2_ = spacing(vj,pj), spacing(v2,p2)
    for v in (0x10,0x11,0x13):
        # CONTENT, not offsets: vsavj aliases 14 of these by offset and the
        # Zabel pair (attackers 0x04 and its 0x0B byte-copy) by MATERIALIZED
        # COPY — a distinct offset holding identical bytes. An offset test
        # calls those six "own data" and the port's subject looks moved
        # (measured 14z-143, this gate's first red).
        if cell(vj,pj,v,nj) == cell(vj,pj,v & 0xF,nj): aliased_in_vj += 1
        if cell(v2,p2,v,n2_) != cell(v2,p2,v & 0xF,n2_): own_in_v2 += 1
want = len(LEGACY)*3
if aliased_in_vj != want or own_in_v2 != want:
    fails.append(f"3: the port's subject moved — vsavj aliases {aliased_in_vj}/{want} "
                 f"tenant-victim cells and vs2 gives {own_in_v2}/{want} their own")
else:
    notes.append(f"3: vsavj aliases all {want} tenant-victim cells onto the base half; "
                 f"vsav2 gives all {want} their own data — the #104 subject")

# ── 4. MUST-FIRE CONTROLS ───────────────────────────────────────────────────
ours = Path(os.environ["OURS"]).read_bytes()   # the REAL image, whatever the mode swapped in
ctl = bytearray(ours)
pa = u32(ours, TJ+4*0x11); off = u16(ours, pa+2*0x03)
ctl[pa+off+8] ^= 0x01                       # one byte of one record
n = min(spacing(bytes(ctl),pa), spacing(v2,u32(v2,T2+4*0x11)))
if cell(bytes(ctl),pa,0x03,n) == cell(v2,u32(v2,T2+4*0x11),0x03,n):
    print("CONTROL DEAD: perturbed-record-byte — a perturbed record byte still compares equal")
    fails.append("4a: CONTROL DID NOT FIRE — a perturbed record byte still compares equal")
else:
    print("CONTROL FIRED: perturbed-record-byte — one flipped record byte breaks the cell comparison")

naive = []
for a in LEGACY:
    pj, p2 = u32(vj,TJ+4*a), u32(v2,T2+4*a)
    if [v for v in range(16) if cell(vj,pj,v,8*FIXED) != cell(v2,p2,v,8*FIXED)]:
        naive.append(a)
small = [a for a in LEGACY if spacing(vj,u32(vj,TJ+4*a)) < 8*FIXED]
if not naive:
    print("CONTROL DEAD: fixed-count-comparison — the fixed-count comparison found no false differences")
    fails.append("4b: CONTROL DID NOT FIRE — the fixed-count comparison found no "
                 "false differences, so this gate cannot show it is avoiding the trap")
elif sorted(naive) != sorted(small):
    print("CONTROL DEAD: fixed-count-comparison — the false positives are not exactly the small-spacing attackers")
    fails.append(f"4b: the fixed-count comparison's false positives {[hex(a) for a in naive]} "
                 f"are not exactly the small-spacing attackers {[hex(a) for a in small]}")
else:
    print(f"CONTROL FIRED: fixed-count-comparison — a FIXED {FIXED}-record comparison invents "
          f"differences at exactly the attackers whose spacing is smaller "
          f"({[hex(a) for a in naive]}); per-block spacing is what avoids it")

for n_ in notes: print("  " + n_)
if fails:
    print()
    for f in fails: print("FAIL: " + f)
    print(f"\nFAIL: audit_capture_matrix ({len(fails)} failure(s))")
    sys.exit(1)
print(f"\nPASS: audit_capture_matrix ({os.environ['MERGED']})")
PY
