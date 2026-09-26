# merged-m20 — MiSTer side

This directory is self-sufficient for MiSTer: the romset patch set
(`patches/`, `manifest.json`, `apply_release.py`, `apply_release.html`,
`README.md`), the `.mra`
files, the bitstream `jtcps2w.rbf` and its record `BITSTREAM.txt` (seed, slack,
sha256 — verified against the file when this directory was packaged).

## On the SD card
    _Arcade/<the .mra files here>
    _Arcade/cores/jtcps2w.rbf        <- in this directory (verify the sha256 in BITSTREAM.txt after copying)
    games/mame/vsavjw.zip            <- built WITHOUT the QSound BIOS member (see below)

**On MiSTer, build the set with `--no-qsound-bios`.** Your card already carries
`games/mame/qsound.zip` the moment you play any CPS-2 game, and the WIDE MRA's
part chain is `vsavjw.zip|vsav.zip|qsound.zip`, so it picks the BIOS member up
from there: measured 2026-09-20, **all 31 CRC-matched parts resolve — 30 out of
`vsavjw.zip` and `dl-1425.bin` out of `qsound.zip`** — and you do not need
`qsound_hle.zip` among your dumps at all. Keeping the member (the applier's
default) also works and costs nothing but the 24 KB; it is what emulator players
want, because MAME refuses a set without it.

The WIDE MRA runs the full roster on `jtcps2w.rbf`. Apart from the BIOS member it
needs nothing beside `vsavjw.zip`: the applier copies the parent's members in from
your own dumps. The other zips are only for the OTHER things on the card:

    games/mame/vsavj.zip             <- your PRISTINE dump: the STOCK CONTROL MRA only
    games/mame/vsav.zip              <- your PRISTINE dump: the STOCK CONTROL MRA, and
                                        stock Vampire Savior on Jotego's own jtcps2.rbf
    games/mame/qsound.zip            <- dl-1425.bin: the WIDE MRA (with --no-qsound-bios)
                                        and the STOCK CONTROL MRA

The `[STOCK CONTROL]`
MRA runs stock `vsavj` on the SAME bitstream with the profile bit at its
`0xFF` fill: it is the superset invariant on silicon and only needs running
when the BITSTREAM changes (new seed, slice or pin), not per release. Stock
Vampire Savior on Jotego's own `jtcps2.rbf` keeps working from the same
`vsav.zip` — the two coexist on one card (field-verified 2026-08-28).

VERIFY THE BITSTREAM'S sha256 BEFORE FLASHING: a timing-failing fitter seed
emits an .rbf indistinguishable from a passing one.
