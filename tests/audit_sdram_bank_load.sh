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
# WHAT IT CANNOT DO, stated up front: a WIDE romset does not load on the stock
# core, so this bounds the HEADROOM of the repack; it does not prove the
# repacked design. The extrapolation is written out in the report it prints.
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
#       [--frames N] [--log FILE] [--tsv FILE]
#   --log FILE   skip the simulation and re-analyse an existing jtsim log
#                (that is how build/sdram_bank_load_14z107.log is re-derived).
#   --tsv FILE   also write the per-interval raw counters as a TSV.
# The default OUTDIR is a temp dir OUTSIDE the repo (rule 7: RAM/ROM-derived
# output never lands in the tree).
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"

RPL="$REPO/tests/replays/05_timeout_idle.rpl"
FRAMES=2800
LOG=""; TSV=""; OUTDIR=""
while [ $# -gt 0 ]; do
    case "$1" in
    --frames) shift; FRAMES="${1:?--frames needs N}" ;;
    --log)    shift; LOG="${1:?--log needs a file}" ;;
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
# tests/test_mister_sim_anchor.sh: MAME 2146 / sim 2507.
DL_END=462          # "ROM file transfered (frame 462)"
ATTRACT_END=1265    # MAME 800-803 start press + 462
SELECT_END=2506     # one frame before the match-start anchor
MATCH_START=2507

if [ -z "$LOG" ]; then
    [ -n "${ROMDIR:-}" ] || { echo "SKIP: ROMDIR unset (this instrument runs the real romset)"; exit 77; }
    command -v verilator >/dev/null 2>&1 || { echo "SKIP: verilator not installed (docs/platform/mister.md Recipe)"; exit 77; }
    [ -e "$REPO/emu/jtcores/.git" ] || { echo "SKIP: emu/jtcores not initialised (tools/setup_jtcores.sh)"; exit 77; }
    if [ -z "$OUTDIR" ]; then OUTDIR="$(mktemp -d)"; fi
    echo "== sim leg (stock jtcps2 under Verilator, -stats; ~50 min) =="
    "$REPO/tools/run_sim_jtcps2.sh" "$RPL" "$OUTDIR" --core cps2 \
        --frames "$FRAMES" --stats || { echo "FAIL: the sim leg did not complete"; exit 1; }
    LOG="$OUTDIR/jtsim.log"
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
if not rows:
    print("FAIL: no well-formed SDRAM_STATS_RAW lines in the log (%d tokens seen)." % seen)
    print("      Was it run with --stats, on a pin at or after fork commit 5?")
    sys.exit(1)

# frame = t / FRAME_PS, both counted from t=0 (the sim's own origin, which is
# also frame_cnt's origin: test.cpp starts simtime and frame_cnt at 0).
for r in rows:
    r["frame"] = r["t"] / FRAME_PS

# --- consistency check: the reporter cadence against the video clock -------
fin = re.findall(r"- \x1b\[33m *(\d+)\n", raw) or re.findall(r"-  *(\d+)\n", raw)
last_frame = int(fin[-1]) if fin else None
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

if tsv:
    with open(tsv, "w") as f:
        f.write("phase\tbank\taccesses\tactives\tsamerow\treads\twrites\t"
                "longest_cum\tseconds\tframes\n")
        for r in tsv_rows:
            f.write("\t".join(str(x) for x in r) + "\n")
    print(f"\n  wrote {tsv}")
PY
