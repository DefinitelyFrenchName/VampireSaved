> **STATUS: EXECUTED 2026-08-25 (14z-108). This brief is HISTORICAL — kept
> because it is the reproducible statement of what was asked and why, and
> because the four-verdict framing below is reusable. THE ANSWER DID NOT FIT
> ONE OF ITS FOUR BOXES:** `cps2w` **FITS** (+206 ALMs, 44%, nothing near
> overflow) but **DOES NOT RELIABLY CLOSE TIMING** — 4 of 12 fitter seeds
> fail, median +0.038 ns against the control's +0.431. On passing seeds it is
> (a); on failing seeds (c); it is NEVER (b), because the reference core
> closed on every seed tried. Full result: STATE 14z-108, and the two
> platform gotchas it produced (`xjtcore.sh` retries until a seed passes; a
> jtcores bitstream carries a BUILD datestamp). *(14z-118: STATE 14z-108 has
> rolled to STATE_HISTORY; the LOG for every number above is
> `docs/platform/mister.md` "SYNTHESISING" — cite that, not this banner.)*

# BRIEF — Quartus synthesis of jtcps2w (CPS-2 WIDE on MiSTer)

You are running on a Windows 10 box (Ryzen 9 3900X, 32 GB) to answer ONE
question that has never been asked: **does this FPGA core fit a Cyclone V,
and does it close timing?** Everything to date is Verilator functional
simulation. Nothing has ever been synthesised.

## WHAT THIS IS

`cores/cps2w` is a fork of Jotego's CPS-2 core (jtcores) carrying a profile
called CPS-2 WIDE, which extends the hardware so an 18-character Vampire
Savior roster fits: a 6 MB program window, 48 MB of GFX via a 3-bit object
bank, 16 MB QSound, and a repacked SDRAM map. Six RTL slices (D0-D5).
The reference core `cores/cps2` is UNTOUCHED and is your control.

## WHAT TO DO

Install Docker Desktop (WSL2 backend). No Quartus install is needed --
Jotego ships the toolchain as an image (see .github/workflows/q20.yaml).

    git clone --recursive https://github.com/DefinitelyFrenchName/jtcores
    cd jtcores
    git checkout 7b9a0d2d
    git submodule update --init --recursive

    docker run --rm -v ${PWD}:/jtcores jotego/jtcore20x xjtcore.sh cps2w mister
    docker run --rm -v ${PWD}:/jtcores jotego/jtcore20x xjtcore.sh cps2  mister

**RUN BOTH.** `cps2` is not optional. jtcps2 is a large core and may already
be tight upstream; without the reference leg a timing failure on `cps2w`
cannot be attributed to our changes. A measurement without its control is
not a measurement in this project.

Expect 20-60 min per core. The image is many GB.

## WHAT TO REPORT

For EACH core, from the fitter and timing reports (`output_files/*.rpt`):
  * ALM / logic utilisation, used and available, as a percentage
  * Block RAM bits used and available
  * DSP blocks if any
  * **Worst-case slack and fmax on the SLOW timing model** (1100 mV, 85 C),
    per clock domain. The SDRAM clock is 96 MHz -- that is the budget that
    matters.
  * Any failing paths: source, destination, and the slack, verbatim
  * Whether the build produced an .rbf at all

Then say plainly which of these is true:
  (a) cps2w fits and closes timing            -> the answer is yes
  (b) cps2w fits, misses timing, cps2 ALSO misses -> inherited, not ours
  (c) cps2w fits, misses timing, cps2 CLOSES  -> ours, and the slices are
      the place to look
  (d) cps2w does not fit                      -> report the resource that
      overflowed

## HARD CONSTRAINTS

1. **DO NOT MODIFY ANY RTL.** Not to chase timing, not to silence a
   warning. This core is governed by a ratified rule (Rule 1 v2) under
   which every change must be bounded, declarative, profile-gated and
   ratified by the maintainer. Retiming a path is a design decision that
   is not yours or mine to take unsupervised. MEASURE AND REPORT.
2. **DO NOT PUSH ANYTHING.** The pin is `7b9a0d2d`. If you touch the tree
   at all (you should not need to), say so explicitly.
3. **Build-flow fixes are fine** -- mount syntax, submodule fetch, disk
   space, a missing env var. Those are yours to solve. Say what you did.
4. If the build fails for a reason you cannot resolve, report the error
   verbatim rather than working around it.

## CONTEXT YOU DO NOT HAVE

You do not have the project repo (it is private; you do not need it) and you
do not have the session that sent you. You do not need either: synthesis
needs only this fork, and no ROM content is involved. If something seems
to require the game's data, stop -- it does not, and that would be a sign
you are doing something other than what this brief asks.

The session that wrote this is `vampiresaved-c1`. If Remote Control is
connected on this machine it can message you directly.
