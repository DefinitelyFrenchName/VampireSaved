#!/bin/sh
# test_classify_hitclass_probe.sh — ground truth for the hit-class probe
# classifier (14z-93). No ROMs, no emulator, ~1s.
#
# WHY THIS EXISTS. `tools/classify_hitclass_probe.py` is the verdict logic
# behind the tenant fire census: it decides whether a run's zero means "the
# tenant stayed inside vanilla's 64 entries", "no rig produced the event at
# all", or "the rig died and this is not a measurement". CLAUDE.md §4 —
# *"Verdict logic is itself tested. A test's classification code must be
# validated against known ground-truth scenarios before its verdicts are
# trusted — SMS shipped a wrong conclusion from a verdict bug, not a game
# bug."* Every case below names the way the classifier could be wrong.
#
# The four statuses are not stylistic: DEAD, CRASH and CAPPED each turn a
# zero (or a total) into something that is NOT the number the audit is
# reporting, and collapsing any of them into OK is how a decayed instrument
# reads as a result.
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-93: ground truth for the hit-class probe's VERDICT LOGIC
#   (tools/classify_hitclass_probe.py), which decides whether a census zero
#   means "the tenant stayed inside vanilla's 64 entries", "no rig produced
#   the event" or "the rig died". 15 cases: the three real verdicts, the four
#   states that are NOT a zero (DEAD / CRASH / CAPPED / absent log), and the
#   ways it could be quietly wrong — D0 is the RAW index here (index*4 at the
#   obj_hook sites, so a "fix" that divides would make 0x44 vanish), the low
#   WORD is the index and a stale high word must be masked, while a LARGE low
#   word is a real trap and must not be. Written first and it CAUGHT ITS
#   AUTHOR: the high-word fixture encoded the wrong width. No ROMs, ~1s; in
#   ci_portable
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
CLS="python3 tools/classify_hitclass_probe.py"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0

# mk <name> <body>  — write a synthetic guarded-run log
mk() { printf '%s\n' "$2" > "$W/$1"; }

# ck <name> <want-rc> <want-substring> <what it proves>
ck() {
    rc=0; out="$($CLS "$W/$1" 2>&1)" || rc=$?
    if [ "$rc" = "$2" ] && (printf '%s' "$out" | grep -q -- "$3"); then
        echo "  ok $1: $4"
    else
        echo "  FAIL $1: rc=$rc want $2; got [$out] want [$3] — $4"
        fail=1
    fi
}

echo "== 1: the three real verdicts =="

# The load-bearing case. 0x44 = 68 = one of Huitzil's projectile types.
mk ext 'PROBE 3210 D0=00000044 D1=00000000 A0=00ff9400 A6=00ff9500 RET 0001a7a4
PROBE 3211 D0=0000000b D1=00000000 A0=00ff9400 A6=00ff9500 RET 0001a7a4
END 5000'
ck ext 0 'OK total=2 ext=1 trap=0' 'an index in 64-79 is counted as EXTENSION, not folded into the total'

# The in-domain case — the shape legacy measured (0x02/0x04/0x09/0x0b).
mk indomain 'PROBE 100 D0=00000002 D1=0 A0=0 A6=0 RET 0001a7a4
PROBE 101 D0=0000000b D1=0 A0=0 A6=0 RET 0001a7a4
PROBE 102 D0=00000004 D1=0 A0=0 A6=0 RET 0001a7a4
END 4000'
ck indomain 0 'OK total=3 ext=0 trap=0' 'entries below 64 read as in-domain, NOT as absence'

# The loud case: past vs2's map too, so the thunk's planted ILLEGAL fires.
# It must NOT be reported as `ext` — "keep the thunk" and "a type has no
# class in either engine" are different conclusions.
mk trapped 'PROBE 90 D0=00000051 D1=0 A0=0 A6=0 RET 0001a7a4
PROBE 91 D0=00000044 D1=0 A0=0 A6=0 RET 0001a7a4
END 100'
ck trapped 0 'total=2 ext=1 trap=1' 'an index >= 80 is TRAP, counted apart from the vs2 extension'

# The no-rig case. This is the one that must never be reported as a fact
# about the thunk: rig 88 measured 0 map entries because it never produced
# a pool-vs-pool contact, not because the tenant stays in range.
mk norig 'END 6000'
ck norig 0 'OK total=0 ext=0 trap=0' 'a complete run with no lookups is a real zero the caller must interpret'

echo "== 2: the states that are NOT a zero =="

# A leg that never finished. Two empty files compare equal; a dead rig and
# a real zero print the same "0" unless this is caught.
mk dead 'PROBE 10 D0=00000002 D1=0 A0=0 A6=0 RET 0001a7a4'
ck dead 1 'DEAD' 'no END line = DEAD, so the run is not a measurement'

# Absent file: a leg whose log was never opened at all.
ck missing_file 1 'DEAD total=0' 'an absent log is DEAD, not a silent zero'

# The cap. GUARD_PROBE_MAX clears the breakpoint mid-run; `total` becomes a
# floor. The audit's `grep -q ^END` check cannot see this — a capped busy
# tenant rig would report a confident undercount.
mk capped 'PROBE 10 D0=00000002 D1=0 A0=0 A6=0 RET 0001a7a4
PROBE 11 D0=00000044 D1=0 A0=0 A6=0 RET 0001a7a4
PROBE-CAP
END 9000'
ck capped 2 'CAPPED total=2 ext=1 trap=0' 'PROBE-CAP is reported, so a truncated total is never printed as a count'

# A crash is a FINDING on the fix build, not a dead rig — an unhandled
# over-index is exactly what a wild jump looks like.
mk crash 'PROBE 10 D0=00000044 D1=0 A0=0 A6=0 RET 0001a7a4
CRASH 3120 PC 000f7997 vec3'
ck crash 3 'CRASH total=1 ext=1 trap=0' 'a crashed run is CRASH, never folded into DEAD'

echo "== 3: verdict controls — the ways it could be quietly wrong =="

# THE INDEX SCALE. At the obj_hook sites D0 = type*4 and the census divides
# by four; here D0 is the RAW index. If someone "fixes" this tool to divide,
# 0x0b becomes 2 and — worse — a real 0x44 becomes 0x11 and the extension
# hit VANISHES. Pin the raw reading.
mk scale 'PROBE 10 D0=00000040 D1=0 A0=0 A6=0 RET 0001a7a4
END 100'
ck scale 0 'OK total=1 ext=1' 'D0 is the RAW index: 0x40 is the first extension entry, not 0x10'

mk scale2 'PROBE 10 D0=0000003f D1=0 A0=0 A6=0 RET 0001a7a4
END 100'
ck scale2 0 'OK total=1 ext=0' 'the boundary is exclusive below: 0x3F is vanilla''s last entry'

# THE INDEX WIDTH. The guard prints the whole 32-bit register; the body does
# `cmpi.w #80,d0` and indexes with `D0.w`, so the low WORD is the index and
# the HIGH word is stale. Reading 32 bits would manufacture an over-index
# out of leftover bits and produce a false "load-bearing" verdict.
mk highword 'PROBE 10 D0=dead000b D1=0 A0=0 A6=0 RET 0001a7a4
END 100'
ck highword 0 'OK total=1 ext=0 trap=0 vals=b' 'the stale HIGH word is masked off — D0.w is the index'

# The converse, and it is not symmetric: a low word that is itself large is
# a REAL over-index — on hardware `cmpi.w #80,d0` would send it to the
# planted ILLEGAL. Masking must not swallow this one.
mk wideword 'PROBE 10 D0=0000be0b D1=0 A0=0 A6=0 RET 0001a7a4
END 100'
ck wideword 0 'OK total=1 ext=0 trap=1 vals=be0b' 'a large low word is a real TRAP, not masked away'

# Non-PROBE lines must not be counted. The guard interleaves its own
# bookkeeping, and a loose regex would inflate every total.
mk noise 'PROBE 10 D0=00000002 D1=0 A0=0 A6=0 RET 0001a7a4
PROBEXX 11 D0=00000044
SNAP 12 D0=00000044
# PROBE 13 D0=00000044
END 100'
ck noise 0 'OK total=1 ext=0 trap=0' 'only real PROBE lines are counted'

# Distinct values are reported for attribution, deduplicated and sorted.
mk vals 'PROBE 1 D0=0000000b D1=0 A0=0 A6=0 RET 0001a7a4
PROBE 2 D0=00000002 D1=0 A0=0 A6=0 RET 0001a7a4
PROBE 3 D0=0000000b D1=0 A0=0 A6=0 RET 0001a7a4
END 100'
ck vals 0 'vals=2,b' 'distinct indices are deduplicated and sorted for attribution'

# --bound is honoured: the same log judged against vs2's 80-entry ceiling
# has no over-index at all. Guards against the bound being hardcoded twice.
rc=0; out="$($CLS "$W/ext" --bound 80)" || rc=$?
if [ "$rc" = 0 ] && printf '%s' "$out" | grep -q 'ext=0'; then
    echo "  ok bound: --bound is honoured (0x44 is inside vs2's 80 entries)"
else
    echo "  FAIL bound: got [$out]"; fail=1
fi

echo
if [ "$fail" = 0 ]; then
    echo "PASS: the classifier's verdicts are ground-truthed."
else
    echo "FAIL: classifier verdicts are NOT trustworthy — do not read a census."
fi
exit "$fail"
