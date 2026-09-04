#!/bin/sh
# audit_front_comparator.sh — what $FF8127 is, and what its input byte +0x10
# is (14z-123, the documentation rationalization pass, inferred_claims row 4;
# closes the 14z-118 (16) leftover "Open: what object byte +0x10 is").
#
# WHY. ram.md recorded $FF8127 as a per-frame COMPARATOR written by
# PRG:0x02228E — `d1 = (P1)+0x10; cmp.b (P2)+0x10,d1; beq/bcc -> 0, else 1`
# — but left OPEN what the byte +0x10 it reads actually IS ("an 8-bit
# ordering key … unmapped"). This audit answers it by MEASUREMENT.
#
# WHAT IT MEASURES, on pristine vsavj (this is vanilla mechanics), replay 37
# (2P Jedah vs Victor to a KO):
#   - The writer reads $41C(a5) / $81C(a5) = each fighter's `+0x1C` ANIM NODE
#     POINTER (RAM:$FF841C / $FF881C), then byte +0x10 of the NODE (a ROM
#     byte of the 0x18-stride anim node, not a byte of the fighter object —
#     the ram.md phrase "object byte +0x10" was imprecise). Confirmed by
#     the identity below reproducing $FF8127 from the ROM node bytes.
#   - IDENTITY: front = (P1_node[+0x10] < P2_node[+0x10]) ? 1 : 0, i.e.
#     $FF8127 = which fighter's current pose sorts in FRONT (a per-pose
#     draw-order / depth key). Holds every frame the two fighters run their
#     OWN nodes; it relaxes only inside a CAPTURE (either `+0x134` set),
#     where the node pointer is the attacker-supplied capture pose and the
#     +0x10 read is that pose's, not the victim's own. The capture FLAG
#     (`+0x134`) and the pose-node settle desync by a bounded tail across a
#     throw, so the mask is the capture window widened by +/-8 frames
#     (measured 14z-123: all 14 transition-frame violations fall inside it,
#     zero outside).
#   - VOCABULARY: the node +0x10 bytes seen are a small frozen set
#     (tests/expected/front_comparator.txt) — per-pose priority values.
#
# ASSERTS (per leg): the tap is LIVE (front toggles, thousands of frames);
# the identity holds on EVERY non-capture frame (a single violation outside
# a capture window means the input is not node+0x10 after all — re-measure,
# do not widen); every observed node+0x10 sits in the frozen vocabulary
# (growth = a pose class we had not seen, stop and extend deliberately).
#
# Usage: ROMDIR=... [MAME_BIN=mame] tests/audit_front_comparator.sh
#        ~1 MAME run, ~3 min. Vanilla vsavj — no build dir needed.
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-123 (inferred_claims row 4): what RAM:$FF8127 is — the FRONT/BACK
#   draw- order selector: writer PRG:0x02228E compares byte +0x10 of each
#   fighter's current ANIM NODE (a per-pose depth key, 19-value vocabulary
#   frozen); identity exact on every non-capture frame of replay 37 (5,486/0).
#   Pristine vsavj, reference MAME, ~1 min.
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
# 14z-132: ABSOLUTE. Gates `cd` into work dirs and then compose paths that
# still contain $ROMDIR (e.g. MAME_ROMPATH="...;$ROMDIR"); a RELATIVE value —
# which is how the runners invoke everything (ROMDIR=../ROMS) — then resolves
# against the WORK dir and silently finds no reference members. Kept as a
# VARIABLE (forks set their own); only made absolute, and only if it exists,
# so a gate that means to SKIP on a missing ROMDIR still does.
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/decrypt_cache.sh"
RPL="tests/replays/37_victor_ko_vsavj.rpl"
[ -f "$RPL" ] || { echo "SKIP: no $RPL"; exit 0; }
EXP="tests/expected/front_comparator.txt"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
decrypt_view vsavj "$W/op.bin" "$W/data.bin"

FIELDS="ff841c:l:p1node,ff881c:l:p2node,ff8127:b:front,ff8534:b:p1cap,ff8934:b:p2cap"
( cd "$W" && FIELDS="$FIELDS" FIELD_OUT="$W/field.txt" REPLAY="$REPO/$RPL" \
    FRAMES=9600 MAME_SANDBOX="$W/sbx" \
    "$REPO/tools/run_mame.sh" vsavj \
    -autoboot_script "$REPO/tests/lua/field_trace.lua" >"$W/run.log" 2>&1 ) \
  || { echo "FAIL: replay run died"; tail -5 "$W/run.log"; exit 1; }
[ -s "$W/field.txt" ] || { echo "FAIL: empty field trace"; exit 1; }

FREEZE="${FREEZE:-0}" python3 - "$W/field.txt" "$W/data.bin" "$REPO/$EXP" <<'PY'
import sys, os, collections
field, datap, exp = sys.argv[1], sys.argv[2], sys.argv[3]
data = open(datap, "rb").read()
rows = []
for ln in open(field):
    if ln.startswith("F "):
        p = ln.split()
        rows.append({k: int(v) for k, v in (t.split("=") for t in p[2:])})

CAPW = 8   # the capture-transition settle tail (measured 14z-123)
cap = [bool(d["p1cap"] or d["p2cap"]) for d in rows]
def near_cap(i):
    return any(cap[j] for j in range(max(0, i - CAPW), min(len(rows), i + CAPW + 1)))

valid = agree = viol_cap = viol_free = capframes = toggles = 0
prev = None
vocab = set()
examples = []
for i, d in enumerate(rows):
    p1, p2 = d["p1node"] & 0xffffffff, d["p2node"] & 0xffffffff
    if not (0 < p1 < 0x400000 and 0 < p2 < 0x400000):
        continue
    b1, b2 = data[p1 + 0x10], data[p2 + 0x10]
    vocab.add(b1); vocab.add(b2)
    valid += 1
    capframes += cap[i]
    pred = 1 if b1 < b2 else 0
    if d["front"] == pred:
        agree += 1
    elif near_cap(i):
        viol_cap += 1
    else:
        viol_free += 1
        if len(examples) < 6:
            examples.append((i, p1, p2, b1, b2, d["front"]))
    if prev is not None and prev != d["front"]:
        toggles += 1
    prev = d["front"]

print(f"  frames with both nodes valid: {valid}; toggles {toggles}; "
      f"capture frames {capframes}")
print(f"  identity front==(node1[+0x10]<node2[+0x10]): agree {agree}, "
      f"violate-in-capture(+/-8) {viol_cap}, violate-FREE {viol_free}")
print(f"  node+0x10 vocabulary: {sorted(vocab)}")

if os.environ.get("FREEZE") == "1":
    open(exp, "w").write(" ".join(str(v) for v in sorted(vocab)) + "\n")
    print(f"  FROZE {exp}")
    sys.exit(0)

fail = 0
if valid < 3000 or toggles < 5:
    print(f"  FAIL: tap not live (valid {valid}, toggles {toggles})"); fail = 1
if viol_free != 0:
    print(f"  FAIL: {viol_free} identity violations OUTSIDE any capture — "
          f"$FF8127's input is not node+0x10 as documented. Examples "
          f"(frame,p1node,p2node,b1,b2,front): {examples}"); fail = 1
want = set(int(x) for x in open(exp).read().split())
grew = sorted(vocab - want)
if grew:
    print(f"  FAIL: node+0x10 vocabulary GREW by {grew} — a new pose class; "
          f"re-measure and refreeze deliberately (FREEZE=1)"); fail = 1
if not fail:
    print("  PASS: $FF8127 = per-pose front/back draw-order selector; "
          "input byte +0x10 is the fighter's ANIM NODE byte; identity holds "
          "on every non-capture frame; vocabulary within frozen set")
sys.exit(fail)
PY
