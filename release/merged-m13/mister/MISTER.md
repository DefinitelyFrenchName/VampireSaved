# merged-m13 — MiSTer side

This directory is self-sufficient for MiSTer: the romset patch set
(`patches/`, `manifest.json`, `apply_release.py`, `README.md`), the `.mra`
files, the bitstream `jtcps2w.rbf` and its record `BITSTREAM.txt` (seed, slack,
sha256 — verified against the file when this directory was packaged).

## On the SD card
    _Arcade/<the .mra files here>
    _Arcade/cores/jtcps2w.rbf        <- in this directory (verify the sha256 in BITSTREAM.txt after copying)
    games/mame/vsavjw.zip            <- from apply_release.py
    games/mame/vsav.zip              <- your PRISTINE dump (the WIDE set is a clone of it)
    games/mame/vsavj.zip             <- your PRISTINE dump (the STOCK CONTROL MRA)
    games/mame/qsound.zip            <- dl-1425.bin

The WIDE MRA runs the full roster on `jtcps2w.rbf`. The `[STOCK CONTROL]`
MRA runs stock `vsavj` on the SAME bitstream with the profile bit at its
`0xFF` fill: it is the superset invariant on silicon and only needs running
when the BITSTREAM changes (new seed, slice or pin), not per release. Stock
Vampire Savior on Jotego's own `jtcps2.rbf` keeps working from the same
`vsav.zip` — the two coexist on one card (field-verified 2026-08-28).

VERIFY THE BITSTREAM'S sha256 BEFORE FLASHING: a timing-failing fitter seed
emits an .rbf indistinguishable from a passing one.
