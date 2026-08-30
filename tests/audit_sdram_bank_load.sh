#!/bin/sh
# audit_sdram_bank_load.sh — MEASURE the per-bank SDRAM load of stock vsavj on
# the stock jtcps2 core, phase by phase (14z-107 (3)).
#
# WHY IT EXISTS. The MiSTer memory-map ruling (maintainer, 2026-08-23) is the
# BANK REPACK at our v1.7.3 pin: vanilla's 32 MB of GFX stays in SDRAM banks
# 2+3, and the ~6.4 MB of tenant art goes into bank 1 ALONGSIDE the QSound
# PCM, reached by the profile-gated promoted tile-code bit. SDRAM banks share
# ONE data bus — extra banks buy overlapped row activation, not bandwidth — so
# the repack's risk is not throughput, it is ROW THRASHING: obj fetches and
# the PCM stream interleaving in bank 1 and knocking each other's open row
# out. This instrument measures the traffic that repack would perturb.
#
# WHAT IT MEASURES, per phase (attract / select / in-match) and per bank:
#   * READ/WRITE command count — the ACCESSES, i.e. the actual traffic;
#   * ACTIVE-command count, which on banks 1-3 is the ROW MISS count, not the
#     traffic: only bank 0 sets JTFRAME_BA0_AUTOPRECH, so
#     jtframe_sdram64_bank.v:170 `row_match = match && actd && !AUTOPRECH[0]`
#     lets a request that hits the open row skip both PRECHARGE and ACTIVE.
#     ROW MISS RATE = ACTIVEs / accesses is therefore the row-thrash metric,
#     and it is THE number the bank repack puts at risk;
#   * data-beat occupancy of the shared 96 MHz / 16-bit bus (burst = 4 words,
#     from the mode register), a FLOOR: turnaround and refresh not counted;
#   * the reporter's own SAME-ROW statistic and longest same-row run. Read it
#     correctly: it counts consecutive ACTIVEs to the SAME row, i.e. a row
#     that was closed and reopened unchanged (refresh precharges all banks),
#     so it is a re-open-churn measure, NOT the row hit rate. The row hit
#     rate is 1 - ACTIVEs/accesses, above.
#   * `WARNING: (test.cpp) SDRAM reads clashed` lines, a direct contention
#     signal from the harness (it prints at most 25).
#
# WHAT IT COULD NOT DO UNTIL SLICE D3, stated up front because the sentence
# stood here for four sessions: a WIDE romset does not load on the STOCK core,
# so a cps2 run bounds the HEADROOM of the repack and does not prove the
# repacked design. `--core cps2w --wide BUILD_DIR` is the other leg, and it is
# what answers docs/project/mister_map.md section 9 open question 1 — whether
# bank 0 absorbs obj bank 5's select-screen traffic — because only a core
# carrying the obj promote can produce that traffic at all.
#
# READ THE PEAK TABLE, NOT ONLY THE PHASE TABLE. Saturation is a property of
# the WORST interval, not of a phase average, and the phase boundaries are
# frozen constants that a different romset can invalidate. The peak table is
# derived from the run's own reporter intervals and needs no boundary to be
# right.
#
# TIER: emulator/manual. Needs ROMDIR + Verilator + ~50 min. NOT ci_portable,
# NOT ci_static; HANDOFF.md indexes it with test_mister_sim_anchor.sh.
#
# THREE UPSTREAM BUGS HAD TO BE FIXED BEFORE `-stats` PRODUCED ANYTHING
# (fork commits 3-5, all in the Verilator harness, no RTL that reaches
# hardware): the SDRAM model dropped the top address bit at AW=23 so the
# upper 8 MB of every bank aliased; the model never advanced
# VerilatedContext::time() so no `#` delay ever fired; and the reporter's own
# two lines are cumulative-and-rounded (and count no accesses at all), so a
# raw counter line was added. See docs/platform/mister.md.
#
# Usage:
#   ROMDIR=... [JTSIM_SCRATCH=...] tests/audit_sdram_bank_load.sh [OUTDIR]
#       [--frames N] [--log FILE] [--tsv FILE] [--rpl FILE]
#   --log FILE   skip the simulation and re-analyse an existing jtsim log
#                (that is how build/sdram_bank_load_14z107.log is re-derived).
#   --tsv FILE   also write the per-interval raw counters as a TSV.
#   --rpl FILE   run (or re-analyse) a DIFFERENT replay. **THE FOUR PHASE
#                BOUNDARIES BELOW ARE MEASURED FOR `05_timeout_idle` AND FOR
#                NOTHING ELSE** — they are absolute simulated frames keyed to
#                that replay's frozen match-start anchor. With any other
#                replay this script REFUSES to print the phase table and
#                reports WHOLE-RUN figures plus the clash count instead
#                (added 14z-108). That is deliberate: a phase table whose
#                labels are wrong is worse than no phase table, and the
#                14z-107 (12) run is on record precisely because it verified
#                its own boundaries before labelling anything.
# The default OUTDIR is a temp dir OUTSIDE the repo (rule 7: RAM/ROM-derived
# output never lands in the tree).
#
# HANDOFF's gate-table note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   (tier manual/emulator (~65 min)) the per-bank SDRAM traffic profile
#   (ACTIVE counts, share, kiB/s, same-row hit rate and mean run, clash
#   warnings) split into attract / select / in-match — the evidence for the
#   MiSTer BANK REPACK ruling. Since D3 it has TWO legs: the default `--core
#   cps2` on stock `vsavj` (the headroom bound) and `--core cps2w --wide
#   build/m3b_merged18` on the WIDE romset, which is what answers
#   `mister_map.md` §9 open question 1 — only a core carrying the obj promote
#   can produce group-C traffic at all. The WIDE leg shifts every phase
#   boundary by the longer transfer and ASSERTS the transfer length from the
#   run's own log. It also prints a PEAK per-bank table derived from the run's
#   own reporter intervals: saturation is a property of the worst interval,
#   not of a phase average, and the peak table depends on no frozen boundary.
#   `--log FILE` re-analyses `build/sdram_bank_load_14z107.log` offline. THE
#   WIDE LEG HAS NOW RUN, 14z-107 (12), ON A BOOTING IMAGE, AND THE ANSWER IS
#   YES WITH ROOM: bank 0 carries 40,717 accesses/frame through the select
#   screen (32.9% of its 123,825 all-miss ceiling), 41,535 in-match, whole-run
#   peak 54,363 (43.9%), data bus 16-18%, and ZERO `SDRAM reads clashed` in
#   3,500 frames — the redirect costs bank 0 about 1,000 accesses/frame,
#   ~2.5%. The run's own anchor landed at 2806 = the frozen 2609 + the
#   197-frame transfer difference, so its phase boundaries were checked rather
#   than assumed. What it does NOT bound: bank 1's group-C half.
#   `05_timeout_idle` picks Demitri, so obj bank 4 is never fetched and ba1's
#   13,890 accesses/frame are PCM alone `--rpl FILE` (14z-108) runs or re-
#   analyses a DIFFERENT replay, and REFUSES the phase table when given one:
#   the four boundaries are absolute simulated frames keyed to
#   `05_timeout_idle`'s frozen match-start anchor, so on any other replay they
#   label phases that are not there. It reports whole-run per-bank rates
#   (download EXCLUDED, its end parsed from the log and refused if absent)
#   plus the `WARNING: (test.cpp) SDRAM reads clashed` count, anchored to the
#   line so this report's own prose about clashes is not scored as evidence.
#   That path is validated on synthetic logs whose answer is known by
#   construction (rates of exactly 10/5/2/3 per frame; 3 warnings counted as
#   3, the same text as prose counted as 0), and the default path still
#   reproduces the frozen 14z-107 table unchanged. `test_mister_gfxc_fetch`
#   now passes `--stats`, so a tenant-match run answers the fetch question and
#   the bank-load question from ONE simulation
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"

RPL="$REPO/tests/replays/05_timeout_idle.rpl"
FRAMES=2800
LOG=""; TSV=""; OUTDIR=""; CORE=cps2; WIDEBUILD=""; RPL_OVERRIDE=0
while [ $# -gt 0 ]; do
    case "$1" in
    --frames) shift; FRAMES="${1:?--frames needs N}" ;;
    --core)   shift; CORE="${1:?--core needs cps2|cps2w}" ;;
    --wide)   shift; WIDEBUILD="${1:?--wide needs a build dir}" ;;
    --log)    shift; LOG="${1:?--log needs a file}" ;;
    --rpl)    shift; RPL="${1:?--rpl needs a file}"; RPL_OVERRIDE=1 ;;
    --tsv)    shift; TSV="${1:?--tsv needs a file}" ;;
    -h|--help) sed -n '2,50p' "$0"; exit 0 ;;
    -*) echo "unknown option '$1'" >&2; exit 2 ;;
    *)  OUTDIR="$1" ;;
    esac
    shift
done

# PHASE BOUNDARIES, in ABSOLUTE simulated frames (the 462 download frames
# included), for tests/replays/05_timeout_idle.rpl at --offset 462. The replay
# is: coin at MAME frame 300, start at 800, one button press at 960, then
# nothing. The round-1 match start is the frozen anchor of
# tests/test_mister_sim_anchor.sh: MAME 2146 / sim **2609**, RE-MEASURED
# 14z-107 (7) on a run whose input script is no longer being replayed by the
# harness's frame writer (it read 2502 under that corruption, and 2507 before
# the SDRAM model fix). MATCH_START sits a few frames INSIDE the match
# deliberately — a few frames before it is not a safe phase boundary.
# THE PUBLISHED 14z-107 (3) TABLE WAS MEASURED WITH THE OLD BOUNDARIES; the
# shift moves ~100 frames of SELECT-phase traffic out of the "in-match" row,
# and both phases were already steady-state, so the per-frame rates it
# reports are unchanged in substance. Re-run to re-derive them exactly.
# RE-CHECKED 14z-107 (8): the joystick fix (fork commit 10 — the harness had
# been holding P1's and P2's buttons 5 and 6 down) re-froze the anchor at the
# SAME 2609, so these four boundaries did not move and the published table
# re-derives from build/sdram_bank_load_14z107.log unchanged. Note the log's
# provenance for the record: it was produced BEFORE that fix, i.e. with those
# four buttons held. That is not a caveat on the traffic numbers — the run
# reaches the same anchor, agrees on every mapped field and draws the same
# arcade opponent — but it is why the boundaries were re-checked rather than
# assumed.
DL_END=462          # "ROM file transfered (frame 462)"
ATTRACT_END=1265    # MAME 800-803 start press + 462
SELECT_END=2608     # one frame before the match-start anchor
MATCH_START=2614    # a few frames inside the match

# THE WIDE IMAGE IS 66,265,152 B RATHER THAN 46,407,744, so its transfer is
# longer and EVERY boundary above moves with it — the four constants are
# absolute simulated frames and the replay is shifted by the transfer length
# (tools/run_sim_jtcps2.sh --offset). Measured 14z-107 (9): "ROM file
# transfered (frame 659)". The shift is applied, not assumed: the run's own log
# is checked against it below, and the PEAK table does not depend on any of
# these four numbers.
WIDE_DL_END=659
if [ -n "$WIDEBUILD" ]; then
    SHIFT=$((WIDE_DL_END - DL_END))
    DL_END=$WIDE_DL_END
    ATTRACT_END=$((ATTRACT_END + SHIFT))
    SELECT_END=$((SELECT_END + SHIFT))
    MATCH_START=$((MATCH_START + SHIFT))
fi

if [ -z "$LOG" ]; then
    [ -n "${ROMDIR:-}" ] || { echo "SKIP: ROMDIR unset (this instrument runs the real romset)"; exit 77; }
    command -v verilator >/dev/null 2>&1 || { echo "SKIP: verilator not installed (docs/platform/mister.md Recipe)"; exit 77; }
    [ -e "$REPO/emu/jtcores/.git" ] || { echo "SKIP: emu/jtcores not initialised (tools/setup_jtcores.sh)"; exit 77; }
    if [ -z "$OUTDIR" ]; then OUTDIR="$(mktemp -d)"; fi
    echo "== sim leg (core $CORE under Verilator, ${WIDEBUILD:+WIDE romset, }-stats; ~50 min) =="
    # --frame-output off is the default, and is passed explicitly because this
    # instrument READS THE LOG: jtframe's frame writer forks a child per
    # changed frame, and a child's exit(0) flushes a COPY of the parent's
    # buffered stdout into the shared log, so `$display` output gets
    # DUPLICATED once per fork (measured 14z-107 (7): 14 forks -> 14 copies of
    # one line). The parser below de-duplicates anyway, but a run that never
    # forks has nothing to de-duplicate.
    "$REPO/tools/run_sim_jtcps2.sh" "$RPL" "$OUTDIR" --core "$CORE" --frame-output off \
        ${WIDEBUILD:+--wide "$WIDEBUILD"} \
        --frames "$FRAMES" --stats || { echo "FAIL: the sim leg did not complete"; exit 1; }
    LOG="$OUTDIR/jtsim.log"
fi
# ── THE PHASE TABLE IS REPLAY-SPECIFIC, AND IT SAYS SO (added 14z-108) ──────
# ATTRACT_END/SELECT_END/MATCH_START are absolute simulated frames derived
# from `05_timeout_idle`'s frozen match-start anchor. On any other replay they
# label phases that are not there. The 14z-107 (12) run is trustworthy because
# it ASSERTED its own boundaries before using them; the same standard applied
# here means refusing, not guessing.
if [ "$RPL_OVERRIDE" = 1 ]; then
    echo "== WHOLE-RUN figures only: --rpl was given =="
    echo "   The four phase boundaries are measured for 05_timeout_idle and for"
    echo "   nothing else, so the phase table is REFUSED for $(basename "$RPL")."
    echo "   What follows is the whole run plus the clash count, which is what"
    echo "   bounds the repack risk (group-C obj fetches sharing bank 1 with the"
    echo "   QSound stream) without needing a phase label at all."
    python3 - "$LOG" <<'PY2'
import re, sys
raw = open(sys.argv[1], "rb").read().decode("utf-8", "replace")
# Same line format, same semantics as the phase analysis below: the counters
# are CUMULATIVE and `t` is picoseconds from the sim's origin, so a RATE is a
# difference over a frame span. (Both were got wrong in this block's first
# draft, which reported means in the tens of millions and a frame index in the
# billions -- caught by running it against build/sdram_bank_load_14z107.log,
# whose real figures are known. THE INSTRUMENT PROTOCOL.)
FRAME_PS = 512 * 262 * 1_000_000 // 8
BA = r"(\d+),(\d+),(\d+),(\d+),(\d+)"
pat = re.compile(r"SDRAM_STATS_RAW t=(\d+) ba0=" + BA + " ba1=" + BA +
                 " ba2=" + BA + " ba3=" + BA)
seen = {}
for m in pat.finditer(raw):
    g = [int(x) for x in m.groups()]
    b = [g[1 + 5*k: 6 + 5*k] for k in range(4)]
    seen[g[0]] = ([b[k][0] for k in range(4)], [b[k][1] for k in range(4)])
if len(seen) < 2:
    sys.exit("FAIL: fewer than 2 SDRAM_STATS_RAW samples in the log "
             "(was --stats passed to the run?)")
# THE ROM DOWNLOAD IS EXCLUDED, and it has to be. It is WRITES, one command
# per byte, at a constant rate to one bank at a time -- so it produces the
# run's highest "acc/frame" on EVERY bank and the same figure on each, which
# is what the first draft reported as a peak (100614/fr on all four, all of it
# inside frames 16-262). The phase analysis below carries the same warning:
# the download is a command-rate baseline, not bandwidth.
m = re.search(r"ROM file transfered \(frame (\d+)\)", raw)
if not m:
    sys.exit("FAIL: the log does not say when the ROM transfer ended, so the "
             "download cannot be excluded and every figure below would "
             "include it")
xfer = int(m.group(1))
ts = [t for t in sorted(seen) if t / FRAME_PS > xfer]
if len(ts) < 2:
    sys.exit("FAIL: fewer than 2 stats samples AFTER the transfer (frame %d)"
             % xfer)
f0, f1 = ts[0] / FRAME_PS, ts[-1] / FRAME_PS
print("   %d stats samples POST-TRANSFER (download ended frame %d), "
      "simulated frames %.0f..%.0f (%.0f frames)"
      % (len(ts), xfer, f0, f1, f1 - f0))
print("   bank | acc/frame (whole run) |  peak acc/frame | same-row %")
for k in range(4):
    tot = seen[ts[-1]][0][k] - seen[ts[0]][0][k]
    srt = seen[ts[-1]][1][k] - seen[ts[0]][1][k]
    peak = 0.0
    for a, b in zip(ts, ts[1:]):
        df = (b - a) / FRAME_PS
        if df > 0:
            peak = max(peak, (seen[b][0][k] - seen[a][0][k]) / df)
    print("   ba%-3d| %21.0f | %15.0f | %8.1f"
          % (k, tot / (f1 - f0), peak, (100.0 * srt / tot) if tot else 0.0))
# ANCHORED TO THE LINE, not to the words. This report's own output quotes the
# warning text in prose, and build/sdram_bank_load_14z107.log (a REPORT, not a
# raw jtsim.log) proves such a file exists: a bare substring count scores that
# commentary as evidence. Match only a line that BEGINS with the warning,
# which is how test.cpp emits it.
clash = len(re.findall(r"(?m)^WARNING: \(test\.cpp\) SDRAM reads clashed", raw))
print("   'SDRAM reads clashed' WARNINGS: %d%s"
      % (clash, "  (none - no read contention in this run)" if clash == 0
                else "  (test.cpp prints at most 25)"))
PY2
    exit $?
fi

# THE TRANSFER LENGTH IS ASSERTED, NOT ASSUMED. Every phase boundary above is
# an absolute frame, so a transfer of a different length silently mislabels
# all four of them.
xfer="$(sed -n 's/.*ROM file transfered (frame \([0-9]*\)).*/\1/p' "$LOG" | head -1)"
if [ -n "$xfer" ] && [ "$xfer" != "$DL_END" ]; then
    echo "FAIL: the log says the transfer ended at frame $xfer, the phase"
    echo "      boundaries assume $DL_END. Every phase below would be mislabelled."
    exit 1
fi
[ -s "$LOG" ] || { echo "FAIL: no log at $LOG"; exit 1; }

python3 - "$LOG" "$DL_END" "$ATTRACT_END" "$SELECT_END" "$MATCH_START" "${TSV:-}" <<'PY'
import re, sys

log, dl_end, attract_end, select_end, match_start = sys.argv[1:6]
dl_end, attract_end, select_end, match_start = map(int, (dl_end, attract_end, select_end, match_start))
tsv = sys.argv[6] if len(sys.argv) > 6 and sys.argv[6] else None

raw = open(log, "rb").read().decode("utf-8", "replace")

# --- the frame clock -------------------------------------------------------
# jtcps2 video: hdump is 9 bits and wraps at 512, vrender1 wraps at 261 -> 262
# lines (cores/cps1/hdl/jtcps1_timing.v), at pxl_cen = 8 MHz exactly
# (jtframe_cen96 off clk96, cores/cps2/hdl/jtcps2_game.v:110-118). So one frame
# is 512*262/8e6 s.  The reporter fires every 16.666667 ms of simulated time
# (jtframe_sdram_stats_sim.v:112) — a DIFFERENT period, which is why the stats
# index has to be converted rather than counted.
FRAME_PS  = 512 * 262 * 1_000_000 // 8      # 16_768_000_000 ps
STATS_PS  = 16_666_667_000                  # the reporter's own interval
SDRAM_HZ  = 96_000_000                      # JTFRAME_SDRAM96 (cps1/cfg/common.def)
# The SDRAM burst is 4 words for every bank (mode register; the harness prints
# "SDRAM burst mode changed to 4"), so a READ occupies 4 data cycles whatever
# the bank consumes. USEFUL words per access follow the bank lengths:
# BA0/BA2/BA3 = 64 bits (cps1/cfg/common.def), BA1 = jtframe_board.v:213-216's
# default of 32 -- which the harness confirms as "burst per bank = { 4,2,4,4 }".
BUS_BEATS  = 4
USE_WORDS  = {0: 4, 1: 2, 2: 4, 3: 4}

BA = r"(\d+),(\d+),(\d+),(\d+),(\d+)"
pat = re.compile(r"SDRAM_STATS_RAW t=(\d+) ba0=" + BA + " ba1=" + BA +
                 " ba2=" + BA + " ba3=" + BA)
rows = []
for m in pat.finditer(raw):
    g = [int(x) for x in m.groups()]
    b = [g[1 + 5*k : 6 + 5*k] for k in range(4)]
    rows.append({"t": g[0],
                 "count":   [b[k][0] for k in range(4)],
                 "samerow": [b[k][1] for k in range(4)],
                 "longest": [b[k][2] for k in range(4)],
                 "rd":      [b[k][3] for k in range(4)],
                 "wr":      [b[k][4] for k in range(4)]})
seen = raw.count("SDRAM_STATS_RAW")

# --- LOG INTEGRITY (14z-107 (7)) -------------------------------------------
# This instrument reads a LOG, and a log is a shared file description. When
# jtframe's frame writer is on, every forked child's exit(0) flushed a COPY of
# the parent's buffered stdout, so a `$display` line could appear twice — or be
# torn at a buffer boundary and never match. Fork commit 9 fixed that at the
# root (_exit(0)), so at the current pin there is nothing to de-duplicate; this
# check stays because logs OUTLIVE pins and `--log FILE` re-analyses old ones.
# Neither form corrupts the arithmetic
# below (the counters are CUMULATIVE and every phase is a first/last
# difference), but silence about it is how a measurement stops being
# reproducible. So: say so, de-duplicate, and require monotonic time.
byt = {}
dups = 0
for r in rows:
    if r["t"] in byt:
        dups += 1
    else:
        byt[r["t"]] = r
if dups:
    print(f"NOTE: {dups} DUPLICATED stats line(s) removed — the fork-flush "
          "signature of host frame output.\n"
          "      Re-run with --frame-output off (the default since 14z-107 (7)); "
          "docs/platform/gotchas.md.")
rows = [byt[t] for t in sorted(byt)]
if not all(b["t"] > a["t"] for a, b in zip(rows, rows[1:])):
    print("FAIL: stats timestamps are not strictly increasing after de-duplication —")
    print("      the log is not a faithful record of one run.")
    sys.exit(1)

# ...AND THE COUNTERS MUST BE MONOTONIC TOO (14z-107 (10)). The check above
# has always guarded the TIME axis; the counters are cumulative and were
# taken on trust. They cannot be: the reporter writes on block-buffered
# stdout into a log the frame counter also writes, so a line can be TORN and
# still match the regex with one field carrying a spliced value. A phase
# figure survives that (it is a first/last difference over hundreds of
# intervals) but a PEAK does not — one bad row produced a ba3 peak of
# 16,870,809 accesses per frame, 13,624% of the physical ceiling, and it was
# reported without comment. Drop any row that decreases a cumulative counter.
kept, drops = [], 0
for r in rows:
    if kept and any(r[k][b] < kept[-1][k][b]
                    for k in ("count", "samerow", "rd", "wr") for b in range(4)):
        drops += 1
        continue
    kept.append(r)
if drops:
    print(f"NOTE: {drops} stats line(s) dropped as NON-MONOTONIC — a torn line "
          "that still parses.\n      Phase figures are first/last differences "
          "and are unaffected; the PEAK table is not, which is why this check "
          "exists.")
rows = kept

if not rows:
    print("FAIL: no well-formed SDRAM_STATS_RAW lines in the log (%d tokens seen)." % seen)
    print("      Was it run with --stats, on a pin at or after fork commit 5?")
    sys.exit(1)

# frame = t / FRAME_PS, both counted from t=0 (the sim's own origin, which is
# also frame_cnt's origin: test.cpp starts simtime and frame_cnt at 0).
for r in rows:
    r["frame"] = r["t"] / FRAME_PS

# --- consistency check: the reporter cadence against the video clock -------
# test.cpp prints one COLOURED hex digit per frame (":874") and a full count
# every 64 frames (":890"), so the last count is a multiple of 64 and the
# frames after it exist only in the digit stream. Both are needed or the
# implied frame period comes out long. The colour codes are what make either
# pattern unambiguous -- the log also carries the reporter's own
# "... - 12345 (12%)" text, which a colour-blind regex matches by the
# thousand.
fin = re.findall(r"- \x1b\[33m *(\d+)\n", raw)
last_frame = None
if fin:
    tail = raw.rsplit("\x1b[33m%4d\n" % int(fin[-1]), 1)[-1]
    last_frame = int(fin[-1]) + len(re.findall(r"\x1b\[31m[0-9A-F]\x1b\[0m", tail))
print("== instrument check ==")
print(f"  {len(rows)} well-formed reporter intervals of {seen} emitted "
      f"({100.0*(seen-len(rows))/seen:.1f}% lost). THE LOSS IS EXPECTED: the "
      f"reporter\n  writes on stdout (block-buffered into the log) while "
      f"test.cpp's frame counter\n  writes on stderr (unbuffered), so a flush "
      f"can land inside a stats line.")
print(f"  intervals are {STATS_PS/1e9:.6f} ms apart; "
      f"video frame = {FRAME_PS/1e9:.6f} ms")
if last_frame:
    implied = rows[-1]["t"] / last_frame / 1e9
    print(f"  last frame marker {last_frame}; last report at "
          f"{rows[-1]['t']/1e9:.3f} ms -> implied frame period {implied:.4f} ms "
          f"({'OK' if abs(implied - FRAME_PS/1e9) < 0.05 else 'MISMATCH — check the video timing'})")
    print(f"  last report maps to frame {rows[-1]['frame']:.1f}")

clash = raw.count("SDRAM reads clashed")
print(f"  'SDRAM reads clashed' warnings: {clash}"
      + ("  (test.cpp prints at most 25)" if clash >= 25 else ""))

def window(f0, f1):
    """counters differenced over [f0, f1] in ABSOLUTE frames."""
    sel = [r for r in rows if f0 <= r["frame"] <= f1]
    if len(sel) < 2:
        return None
    a, b = sel[0], sel[-1]
    dt = (b["t"] - a["t"]) / 1e12          # seconds
    out = {"n": len(sel), "f0": a["frame"], "f1": b["frame"], "dt": dt,
           "act": [b["count"][k]   - a["count"][k]   for k in range(4)],
           "sr":  [b["samerow"][k] - a["samerow"][k] for k in range(4)],
           "rd":  [b["rd"][k]      - a["rd"][k]      for k in range(4)],
           "wr":  [b["wr"][k]      - a["wr"][k]      for k in range(4)],
           "lmax": [b["longest"][k] for k in range(4)],
           "lgrew": [b["longest"][k] > a["longest"][k] for k in range(4)]}
    out["acc"] = [out["rd"][k] + out["wr"][k] for k in range(4)]
    out["tot"] = sum(out["acc"])
    out["tot_act"] = sum(out["act"])
    out["beats"] = sum(out["acc"][k] * BUS_BEATS for k in range(4))
    out["frames"] = (out["f1"] - out["f0"]) or 1
    return out

phases = [
    ("ROM download",  0.0,             float(dl_end)),
    ("attract",       float(dl_end+1), float(attract_end)),
    ("select+VS",     float(attract_end+1), float(select_end)),
    ("in-match",      float(match_start),   rows[-1]["frame"]),
]

print()
print("== per bank: ACCESSES (rd+wr), row MISSES, share, bandwidth ==")
print(f"{'phase':<13} {'frames':>11} {'ba':>3} {'access/fr':>10} {'share':>7} "
      f"{'kiB/s':>9} {'ACT/fr':>9} {'rowmiss':>8} {'reopen':>7} {'lngst':>6}")
tsv_rows = []
for name, f0, f1 in phases:
    w = window(f0, f1)
    if w is None:
        print(f"{name:<13}  (no reporter interval inside {f0:.0f}-{f1:.0f})")
        continue
    span = "%.0f-%.0f" % (w["f0"], w["f1"])
    fr = w["frames"]
    for k in range(4):
        acc, act, sr = w["acc"][k], w["act"][k], w["sr"][k]
        share = 100.0 * acc / w["tot"] if w["tot"] else 0.0
        kibs = acc * USE_WORDS[k] * 2 / w["dt"] / 1024 if w["dt"] else 0.0
        miss = 100.0 * act / acc if acc else float("nan")
        srp = 100.0 * sr / act if act else float("nan")
        grew = "+" if w["lgrew"][k] else " "
        print("%-13s %11s %3d %10.0f %6.1f%% %9.0f %9.0f %7.1f%% %6.1f%% %6d%s" % (
            name if k == 0 else "", span if k == 0 else "", k, acc/fr, share,
            kibs, act/fr, miss, srp, w["lmax"][k], grew))
        tsv_rows.append((name, k, acc, act, sr, w["rd"][k], w["wr"][k],
                         w["lmax"][k], round(w["dt"], 6), round(fr, 1)))
    util = 100.0 * w["beats"] / (SDRAM_HZ * w["dt"]) if w["dt"] else 0.0
    tot_kibs = sum(w["acc"][k]*USE_WORDS[k]*2 for k in range(4)) / w["dt"] / 1024
    print("%-13s %11s %3s %10.0f %6.1f%% %9.0f %9.0f    data-bus %.1f%% of "
          "%.0f MHz x 16 bit" % ("", "", "ALL", w["tot"]/fr, 100.0, tot_kibs,
                                 w["tot_act"]/fr, util, SDRAM_HZ/1e6))
    print()

# --- THE PEAK, which is what saturation actually means ---------------------
# A phase average hides a spike, and the phase boundaries are frozen constants
# that a different romset can invalidate. This table is derived from the run's
# own consecutive reporter intervals and depends on no boundary at all.
#   The all-miss ceiling: one transaction costs STW = 13 SDRAM clocks
#   (jtframe_sdram64_bank.v), so a bank can serve
#   96e6 * FRAME_PS/1e12 / 13 transactions in one video frame.
CEIL = SDRAM_HZ * (FRAME_PS/1e12) / 13
print("== PEAK interval, per bank — the saturation answer ==")
print(f"  all-miss ceiling = {CEIL:,.0f} transactions per video frame "
      f"(STW 13 at {SDRAM_HZ/1e6:.0f} MHz)")
print(f"  AFTER the ROM download (frame > {dl_end}), which is one command per")
print( "  byte and saturates every bank by construction — it is a command-rate")
print( "  baseline, not a load the running game ever produces.")
print(f"{'ba':>3} {'peak acc/fr':>12} {'% ceiling':>10} {'at frame':>9} "
      f"{'peak ACT/fr':>12} {'% ceiling':>10} {'at frame':>9}")
for k in range(4):
    best_acc = (0.0, 0.0); best_act = (0.0, 0.0)
    for a, b in zip(rows, rows[1:]):
        if a["frame"] <= dl_end: continue
        df = (b["t"] - a["t"]) / FRAME_PS
        # A PEAK IS A RATIO, SO GUARD ITS DENOMINATOR. The reporter's lines
        # are block-buffered into a log that the frame counter also writes,
        # so a torn line can leave two surviving rows a few nanoseconds
        # apart; dividing by that produces a "peak" of millions per frame
        # (measured 14z-107 (10): ba3 at 16,870,809/frame, 13,624% of the
        # ceiling). One interval is ~0.994 video frames, so anything under
        # half a frame is not an interval.
        if df < 0.5: continue
        acc = ((b["rd"][k]-a["rd"][k]) + (b["wr"][k]-a["wr"][k])) / df
        act = (b["count"][k]-a["count"][k]) / df
        if acc > best_acc[0]: best_acc = (acc, b["frame"])
        if act > best_act[0]: best_act = (act, b["frame"])
    print("%3d %12.0f %9.1f%% %9.0f %12.0f %9.1f%% %9.0f" % (
        k, best_acc[0], 100.0*best_acc[0]/CEIL, best_acc[1],
        best_act[0], 100.0*best_act[0]/CEIL, best_act[1]))
print()

print("NOTES")
print("  * access/fr = READ+WRITE commands per video frame. ACT/fr = ACTIVE")
print("    commands per frame; rowmiss = ACT/access. Bank 0 sets")
print("    JTFRAME_BA0_AUTOPRECH so its row closes on every access and its")
print("    rowmiss is 100% BY CONSTRUCTION; banks 1-3 keep the row open, so")
print("    THEIR rowmiss is the real row-thrash number.")
print("  * 'reopen' is the reporter's own same-row statistic, ACTIVE-to-ACTIVE:")
print("    a row closed and reopened UNCHANGED (refresh precharges all banks).")
print("    It is churn, not the hit rate. 'lngst' is the CUMULATIVE longest")
print("    such run at the END of the phase; '+' means it grew inside it.")
print("  * kiB/s is USEFUL data (4 words per access on BA0/2/3, 2 on BA1).")
print("    data-bus % charges every access the full 4-word mode-register")
print("    burst; it is still a FLOOR — turnaround and refresh are not counted.")
print("  * The ROM download is WRITES, one command per byte, and it is the")
print("    only phase where ACTIVE tracks traffic (the prog path passes")
print("    match=0, jtframe_sdram64.v:331, so every byte re-activates).")
print("    Its kiB/s and data-bus figures are therefore INFLATED — they charge")
print("    each single-byte write a full 4-word burst. Read the download row")
print("    as a command-rate baseline, not as bandwidth.")

if tsv:
    with open(tsv, "w") as f:
        f.write("phase\tbank\taccesses\tactives\tsamerow\treads\twrites\t"
                "longest_cum\tseconds\tframes\n")
        for r in tsv_rows:
            f.write("\t".join(str(x) for x in r) + "\n")
    print(f"\n  wrote {tsv}")
PY
