#!/bin/sh
# audit_df_field_readers_live.sh — WHAT THE #136 CORPUS EXECUTES AGAINST vs2's DARK FORCE POWER FIELDS, cross-checked against the static census (14z-168, GitHub #136 / #157's Dark Force tail): every placed instruction the corpus runs that reads or writes +0x1C3..+0x1C8 of either fighter block is a census row with the right access, and the rows it reaches are frozen.
#
# WHAT: what the #136 corpus actually EXECUTES against vs2's Dark Force POWER fields
#   (+0x1C3..+0x1C8) on our build, cross-checked against the static census: every placed
#   instruction that runs and touches a field is a census row with the right access class,
#   nothing hides in a skipped region, and the host's own accesses are frozen.
# HOW: 30 non-debug read-tap runs on MAME (every naming part of the three tenants with the
#   parity gate's inputs and pins), both fighter blocks' +0x1C2..+0x1C9 tapped, every access
#   attributed by PC and matched to tests/expected/df_field_readers.tsv; liveness per range
#   needs a game write and the END probe; controls delete the first reached census row and
#   delete a range's accesses.
# EXPECTS: no MISSED or MISLABELLED access, no access inside a skipped region, the sampled
#   and host rows frozen with the unsampled count; the deleted-row copy reports a missed PC,
#   the silent range reads DEAD. Unsampled: the tenant as P2, the vs2 EX route, every path
#   the corpus never runs.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/df_field_readers_live.tsv
#   tests/lua/read_tap.lua tests/replays/ tools/audit_df_field_readers.py
#   tools/name_moves.py tools/run_mame.sh tools/setup_mame.sh
#
# MUST-FIRE: shadow-tool: missed-planted — a copy of the census with the FIRST row the corpus reaches deleted must make the cross-check report that access as MISSED and FAIL, so a reader the census cannot see is caught wherever the corpus runs it (in-gate: the planted copy must report exactly one missed pc; mode: the gate cross-checks against the planted copy and FAILs)
# MUST-FIRE: perturbed-copy: range-silent — a copy of a tap log with every access to P2's block range deleted must be reported as a DEAD range, so each run's two tap ranges are each proven live before the cross-check trusts their silence (in-gate: the perturbed copy of the first run must be reported silent in P2; mode: every run's log is perturbed before the liveness check and the gate FAILs)
#
# WHY. tests/test_df_field_readers.sh is a STATIC census: it finds an instruction only
# when the field is a displacement from an address register inside a placed code span,
# and it cannot say which base register holds a fighter block. Rule-checker run
# 2026-09-18-46 (Q4) found it had no control for a false row or a missed reader. This
# gate is that control on the paths the corpus reaches: it taps both fighter blocks'
# +0x1C2..+0x1C9 (tests/lua/read_tap.lua, non-debug, two ranges) and attributes every
# access by the executing pc (CURPC):
#   - a pc inside a placed CODE span must be a census row at that pc, for a field the
#     access touches, whose access class agrees (a read needs read/rmw, a write
#     write/rmw) — else MISSED or MISLABELLED, and the gate FAILs;
#   - a pc inside a placed span the census SKIPS (a data region, a data op) FAILs — the
#     census's region skip would be hiding code;
#   - any other pc is vsavj's own code (the block clears), listed as `host` and frozen.
#
# THE SAMPLE: every committed naming part of the three tenants on OUR build (the #136
# rigs, tests/replays/naming/<tenant>_<n>, 30 parts, the in-Dark-Force parts included),
# with tests/audit_move_parity.sh's own inputs and pokes for our leg (rpl_for, the level
# and the RNG pinned) — that gate's field trace asserts P1's id on the same inputs; this
# one does not re-assert it, and the per-run attribution in the frozen rows is what moves
# if a run lands elsewhere. NOT SAMPLED: the tenant as P2 (the victim rigs), the tenants'
# vs2 EX route on our build (a first version carried tests/audit_df_modes.sh's P+K and EX
# legs; they reached no census row and nothing here proved their cursor landed, so they
# were dropped, 14z-168), and every path the corpus never runs — a census row outside the
# sample is neither confirmed nor refuted here, which is why the `unsampled` count is frozen.
#
# LIVENESS, PER RANGE (added 14z-168 after rule-checker runs 2026-09-18-47 and -48 Q4): a
# run counts only if EACH tapped range shows (a) a game write inside the read window
# (>= 1400; the block clears and the round-start write at 2362 hit both blocks) and (b)
# the END PROBE — a Lua poke of +0x1C9 (tapped, outside the field set) on the run's last
# frame. Nothing in the corpus touches these bytes after 2362, so (a) alone would let a
# range lost mid-match pass as silence. The probe was measured to leave every other log
# line unchanged. The `range-silent` control proves the check fires. NOT SHOWN: that a
# range stays tapped at every frame between 2362 and the end, and huitzil_5 reaches no
# census row (its per-run attribution is empty; P1's id there rests on the parity gate).
#
# FROZEN: tests/expected/df_field_readers_live.tsv — `sampled <access> <field> <pc>
# <region> <base> <blocks> <runs>` per census row reached (blocks: which fighter block,
# P1/P2, the executed accesses touched), `host <R|W> <pc> <blocks> <n runs>`, and
# `unsampled <n>`. Re-freeze at every freeze (placed addresses move), reviewing the diff.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged27] [JOBS=6] [FREEZE=1] tests/audit_df_field_readers_live.sh
#   emulator tier, MAME; 30 tap runs — measured 14z-168 on this MacBook, solo, JOBS=6: ~50 s wall
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged27}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
EXPECT="$REPO/tests/expected/df_field_readers_live.tsv"
JOBS="${JOBS:-6}"
CONTROL="${CONTROL:-}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no WIDE build at $BUILD"; exit 0; }
for f in verify_op.bin patch/placements.json patch/patch.json; do
    [ -f "$BUILD/$f" ] || { echo "SKIP: no $f in $BUILD"; exit 0; }
done
python3 -c "import capstone" 2>/dev/null || { echo "SKIP: python capstone not installed"; exit 0; }
case "$CONTROL" in ""|missed-planted|range-silent) ;; *) echo "REFUSED: no control named '$CONTROL' is declared by this gate"; exit 3 ;; esac
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }

echo "== 1. the static census"
python3 "$REPO/tools/audit_df_field_readers.py" "$BUILD/verify_op.bin" "$BUILD/patch/placements.json" "$BUILD/patch/patch.json" --tsv \
    > "$W/census.tsv" 2> "$W/census.err" || { bad "census: $(tail -1 "$W/census.err")"; echo "FAIL: audit_df_field_readers_live"; exit 1; }
ok "$(grep -c -v -E '^(count|access)' "$W/census.tsv" | tr -d ' ') census rows"

echo "== 2. the tap runs"
OURS_PATH_donovan="D D DR DR"; OURS_PATH_huitzil="D D D"; OURS_PATH_pyron="D D D D"
RTAP="ff85c2,8;ff89c2,8"
tap_run() {  # tap_run <name> <rpl> <pokes> <frames>
    mkdir -p "$W/$1"
    # set +e: MAME can segfault at TEARDOWN after the log is closed (docs/platform/gotchas.md, the
    # tap-installer entry — measured here 14z-168 on donovan_7 and pyron_4 with the ORIGINAL
    # single-range read_tap.lua too), so the verdict rests on the tap's END line, never the exit code
    # the END PROBE: one byte written to +0x1C9 of each block on the run's LAST frame — inside the tapped
    # ranges, outside the field set, after everything measured — so each range is shown tapped to the end
    ( set +e; cd "$W/$1" && MAME_SANDBOX="$W/$1/sb" MAME_ROMPATH="$BUILD/rompath;$ROMDIR" REPLAY="$2" POKES="$3;$4:ff85c9:00;$4:ff89c9:00" RTAP="$RTAP" \
        WINDOW="1400,$4" TRACE_OUT="$W/$1.tap" FRAMES="$4" \
        "$REPO/tools/run_mame.sh" vsavjw -autoboot_script "$REPO/tests/lua/read_tap.lua" > "$W/$1/mame.log" 2>&1
      echo $? > "$W/$1/rc"; rm -rf "$W/$1/sb" ) </dev/null &
}
RUNS=""; n=0
for j in "$REPO"/tests/replays/naming/donovan_[0-9]*.json "$REPO"/tests/replays/naming/huitzil_[0-9]*.json "$REPO"/tests/replays/naming/pyron_[0-9]*.json; do
    name="$(basename "$j" .json)"; t="${name%_*}"
    fr="$(python3 -c "import json;print(json.load(open('$j'))['frames'])")"
    pk="$(python3 -c "import json;print(';'.join(json.load(open('$j'))['pokes']))");$(python3 -c "print(';'.join(f'{f}:ff8116:06' for f in range(2000,$fr)))");$(python3 -c "print(';'.join(f'{f}:ff80d4:0000' for f in range(2363,$fr)))")"
    eval "_path=\$OURS_PATH_$t"
    awk -v path="$_path" '
        /^1104-1106 p2=R$/ && !done { n = split(path, m, " "); t = 1100
            for (i = 1; i <= n; i++) { printf "%d-%d p1=%s\n", t, t + 2, m[i]; t += 60 }; done = 1 }
        /^(1100|1160|1220|1280)-[0-9]+ p1=/ { next }
        { print }' "${j%.json}.rpl" > "$W/$name.rpl"
    tap_run "$name" "$W/$name.rpl" "$pk" "$fr"; RUNS="$RUNS $name"
    n=$((n + 1)); [ $((n % JOBS)) -eq 0 ] && wait
done
wait
# ONE liveness reader and ONE perturbation, shared by the gate, the in-gate control and the mode ([VSP-181])
dead_ranges() {  # dead_ranges <tap>: each tapped block range lacking an in-window game write (>= 1400) or the END probe
    awk '$1=="END" { fr = $2 } $1=="W" { r = ($6 >= "ff85c2" && $6 <= "ff85c8") ? 1 : (($6 >= "ff89c2" && $6 <= "ff89c8") ? 2 : 0)
             if (r && $2 >= 1400) win[r] = 1; if (r) last[r] = $2 }
         END { for (r = 1; r <= 2; r++) { if (!win[r]) printf "P%d(window) ", r; if (last[r] != fr) printf "P%d(end-probe) ", r } }' "$1"
}
silence_p2() {  # silence_p2 <tap in> <tap out>: every access to P2's range deleted
    awk '!(($1 == "W" || $1 == "R") && $6 >= "ff89c2" && $6 <= "ff89c8")' "$1" > "$2"
}
for r in $RUNS; do
    _rc="$(cat "$W/$r/rc" 2>/dev/null || echo none)"
    grep -q '^END ' "$W/$r.tap" 2>/dev/null || bad "$r: the tap has no END line (exit $_rc) — a dead tap is not evidence"
    if [ "$CONTROL" = range-silent ]; then silence_p2 "$W/$r.tap" "$W/$r.sil" && mv "$W/$r.sil" "$W/$r.tap"; fi
    _d="$(dead_ranges "$W/$r.tap")"
    [ -z "$_d" ] || bad "$r: no write in the ${_d}range — that tap range is dead (the block clears must hit both)"
done
if [ "$CONTROL" = range-silent ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: range-silent — every run reads P2's range dead"; echo "FAIL: audit_df_field_readers_live (control mode)"; exit 1
    else echo "CONTROL DEAD: range-silent — the silenced range still read live"; echo "FAIL: audit_df_field_readers_live"; exit 1; fi
fi
[ "$fail" = 0 ] || { echo "FAIL: audit_df_field_readers_live"; exit 1; }
ok "$(echo $RUNS | wc -w | tr -d ' ') runs, both tap ranges live in every one"
_first="$(echo $RUNS | cut -d' ' -f1)"; silence_p2 "$W/$_first.tap" "$W/ctl_range.tap"
_dr="$(dead_ranges "$W/ctl_range.tap")"
if [ "$_dr" = "P2(window) P2(end-probe) " ]; then echo "CONTROL FIRED: range-silent — $_first without P2's accesses reads ${_dr}dead"
else echo "CONTROL DEAD: range-silent — $_first without P2's accesses still reads '$(dead_ranges "$W/ctl_range.tap")'"; fail=1; fi

echo "== 3. the cross-check"
CENSUS="$W/census.tsv"
# ONE cross-check, shared by the gate, the in-gate control and the mode ([VSP-181])
xcheck() {  # xcheck <census.tsv> <out.tsv> — prints problems on stderr, exits 1 on any
    python3 - "$1" "$2" "$W" "$REPO" "$BUILD" $RUNS <<'PY'
import sys, json, re
census_p, out_p, W, REPO, BUILD, runs = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6:]
sys.path.insert(0, f"{REPO}/tools"); import audit_df_field_readers as t
code = t.spans(f"{BUILD}/patch/placements.json", f"{BUILD}/patch/patch.json")
allp = [(r["dst"], r["dst"] + r["len"], n) for n, r in json.load(open(f"{BUILD}/patch/placements.json"))["regions"].items()]
for o in json.load(open(f"{BUILD}/patch/patch.json"))["ops"]:
    if o.get("op") in ("data", "poke16", "poke32"):
        a = o["addr"]; a = int(a, 16) if isinstance(a, str) else a
        allp.append((a, a + max(2, len(bytes.fromhex(o.get("hex", "")))), o["op"]))
rows = {}
for l in open(census_p):
    c = l.rstrip("\n").split("\t")
    if c[0] in ("read", "write", "rmw", "addr"):
        rows.setdefault(int(c[2], 16), []).append((c[0], int(c[1][3:], 16), c[3], c[4]))
FIELD_BYTES = {0x1C3, 0x1C4, 0x1C5, 0x1C6, 0x1C7, 0x1C8}
sampled, host, probs = {}, {}, {}
for r in runs:
    for l in open(f"{W}/{r}.tap"):
        x = l.split()
        if not x or x[0] not in ("R", "W"): continue
        pc, off, mask = int(x[3], 16), int(x[5], 16), int(x[9], 16)
        rel = off - (0xFF8400 if off < 0xFF8800 else 0xFF8800); blk = "P1" if off < 0xFF8800 else "P2"
        touched = {b for b, m in ((rel, 0xFF00), (rel + 1, 0x00FF)) if mask & m} & FIELD_BYTES
        if not touched: continue
        if any(lo <= pc < hi for lo, hi, _ in code):
            want = ("read", "rmw") if x[0] == "R" else ("write", "rmw")
            cand = [c for c in rows.get(pc, []) if any(c[1] <= b <= c[1] + 3 for b in touched)]
            if not cand:
                probs.setdefault(f"MISSED {x[0]} pc {pc:06x} bytes {','.join(hex(b) for b in sorted(touched))} — no census row at that pc", set()).add(r)
            elif not any(c[0] in want for c in cand):
                probs.setdefault(f"MISLABELLED {x[0]} pc {pc:06x} — the census row says {cand[0][0]}", set()).add(r)
            else:
                c = next(c for c in cand if c[0] in want)
                e = sampled.setdefault((pc, c), (set(), set())); e[0].add(r); e[1].add(blk)
        elif any(lo <= pc < hi for lo, hi, _ in allp):
            probs.setdefault(f"SKIPPED-REGION {x[0]} pc {pc:06x} — code runs in a placed span the census skips ({','.join(n for lo, hi, n in allp if lo <= pc < hi)})", set()).add(r)
        else:
            e = host.setdefault((x[0], pc), (set(), set())); e[0].add(r); e[1].add(blk)
with open(out_p, "w") as o:
    for (pc, (acc, field, region, base)), (rs, bs) in sorted(sampled.items()):
        o.write(f"sampled\t{acc}\t+0x{field:x}\t{pc:#08x}\t{region}\t{base}\t{','.join(sorted(bs))}\t{','.join(sorted(rs))}\n")
    for (k, pc), (rs, bs) in sorted(host.items()):
        o.write(f"host\t{k}\t{pc:#08x}\t{','.join(sorted(bs))}\t{len(rs)} runs\n")
    o.write(f"unsampled\t{sum(len(v) for v in rows.values()) - len(sampled)}\n")
for p, rs in sorted(probs.items()):
    print(f"{p} (runs: {','.join(sorted(rs))})", file=sys.stderr)
sys.exit(1 if probs else 0)
PY
}
# ONE planting function: the census copy without the first row the corpus reaches
plant() {  # plant <got.tsv> <census in> <census out>
    _pc="$(awk -F'\t' '$1=="sampled"{print $4; exit}' "$1")"
    [ -n "$_pc" ] || return 1
    awk -F'\t' -v pc="$_pc" '!($3 == pc && !done) {print; next} {done = 1}' "$2" > "$3"
}
xcheck "$CENSUS" "$W/got.tsv" 2> "$W/xcheck.err" || true
if [ -s "$W/xcheck.err" ]; then bad "the corpus executes accesses the census does not account for:"; sed 's/^/        /' "$W/xcheck.err"
else ok "every executed access from placed code is a census row with the right access class"; fi
if [ "$CONTROL" = missed-planted ]; then
    plant "$W/got.tsv" "$CENSUS" "$W/planted.tsv" || { echo "REFUSED: the corpus reaches no census row to plant over"; exit 3; }
    xcheck "$W/planted.tsv" "$W/got.tsv" 2> "$W/xcheck.err" || true
    if [ -s "$W/xcheck.err" ]; then bad "(control) the planted census:"; sed 's/^/        /' "$W/xcheck.err"; fi
fi
sed 's/^/  /' "$W/got.tsv"
# THE TAP IS NOT BLIND (reworked 14z-170): until the M19 freeze this required the x028122 meter-adder copy
# sampled reading +0x1C3 — and the ruled gauge fix moved exactly that operand to +0x111 (vsavj's adder's
# field). Liveness is now: the corpus samples +0x1C3 reads from placed code at all (the per-move Power latch,
# vs2's `move.b $1c3(a6),$19c(a6)`, and Phobos's powered specials remain); and the FIX is asserted — no
# x028122 copy is sampled reading +0x1C3 (on merged-m18 all three were: the failing direction).
awk -F'\t' '$1=="sampled" && $2=="read" && $3=="+0x1c3"' "$W/got.tsv" | grep -q . || bad "no +0x1C3 read from placed code was sampled — the corpus or the tap is blind"
awk -F'\t' '$1=="sampled" && $3=="+0x1c3" && $5 ~ /^x028122/' "$W/got.tsv" | grep -q . && bad "an x028122 meter-adder copy is sampled reading +0x1C3 — the M19 gauge fix (the adder tests +0x111, as vsavj's) is not in this build"

echo "== 4. the frozen rows"
if [ "${FREEZE:-0}" = 1 ]; then
    [ "$fail" = 0 ] || { echo "FAIL: audit_df_field_readers_live (not frozen: fix the red first)"; exit 1; }
    { echo "# tests/expected/df_field_readers_live.tsv — the census rows of tools/audit_df_field_readers.py that the #136 corpus executes on"
      echo "# our build ($(basename "$BUILD")), with vsavj's own accesses to the same bytes (tests/audit_df_field_readers_live.sh; tests/lua/read_tap.lua)."
      echo "# Evidence class: in-emulator. First frozen 14z-168; this freeze with FREEZE=1 on $(basename "$BUILD"). Re-freeze at every freeze, reviewing the diff."
      echo "#--"; cat "$W/got.tsv"; } > "$EXPECT"
    echo "  FROZE  $(basename "$EXPECT") ($(wc -l < "$W/got.tsv" | tr -d ' ') rows) — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1 to create it)"; exit 1; }
grep -v '^#' "$EXPECT" > "$W/want.tsv"
if diff "$W/want.tsv" "$W/got.tsv" > "$W/diff.txt"; then ok "every row as frozen"
else bad "differs from the frozen rows"; sed 's/^/        /' "$W/diff.txt"; fi

echo "== 5. must-fire control"
if [ "$CONTROL" = missed-planted ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: missed-planted — the deleted row's access is reported MISSED"; echo "FAIL: audit_df_field_readers_live (control mode)"; exit 1
    else echo "CONTROL DEAD: missed-planted — the cross-check did not notice the deleted row"; echo "FAIL: audit_df_field_readers_live"; exit 1; fi
fi
if plant "$W/got.tsv" "$CENSUS" "$W/ctl.tsv"; then
    xcheck "$W/ctl.tsv" "$W/ctl_got.tsv" 2> "$W/ctl.err" || true
    _m="$(grep -c '^MISSED' "$W/ctl.err" | tr -d ' ')"
    if [ "$_m" = 1 ] && [ "$(grep -c . "$W/ctl.err" | tr -d ' ')" = 1 ]; then echo "CONTROL FIRED: missed-planted — $(cut -c1-60 "$W/ctl.err")"
    else echo "CONTROL DEAD: missed-planted — the planted census reported $_m missed pcs, not exactly one"; fail=1; fi
else echo "CONTROL DEAD: missed-planted — no sampled row to plant over"; fail=1; fi

if [ "$fail" = 0 ]; then echo "PASS: audit_df_field_readers_live"; else echo "FAIL: audit_df_field_readers_live"; exit 1; fi
