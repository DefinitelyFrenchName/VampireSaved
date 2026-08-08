# PING #9 ARTIFACT — DO NOT REBUILD IN PLACE

Fingerprint: **64128aa7465e15378c0082afcc953aa9730744ce**
Cut: 2026-08-08 (session 14z-68h)
Launch: `tools/run_hui_behavior.sh` (this is its default)

Reproducible from the tree:
```sh
TENANT_MANIFEST=build/manifest/huitzil.toml TENANT_CHAR=0x10 \
GEN_FLAGS="--profile cps2-wide-v1 --allow-plausible --tripwire-open" \
    tools/build_donovan.sh 6 <somewhere-else>
```
(verified: rebuilds to the same fingerprint). Rebuild experiments go
to build/scratch or hui11+ so bug reports stay attributable to these
exact zips — the ping-#7 lesson.

## CORRECTION (post-cut, 14z-68i): DO NOT SPEND TIME ON THIS BUILD

The maintainer's first look ("in the yellows but it's just the
outline") led to a bigger finding: **the win-screen PORTRAIT and
QUOTE are BULLETA's**, not Huitzil's — he sits on her variant row
(0x10) and the win-screen record family still aliases rows
0x10-0x1F onto 0x00-0x0F. The gold palette is being painted onto
HER art, which is why the screen cannot be judged.

The palette fix itself is verified sound (palette RAM matches vs2's
gold ramp on all five rows in the correct destination rows; the
tiles are byte-identical to vs2's originals) — but you cannot see
that until the portrait is his. Next build will carry the tenant
win-screen records; test then.

## (original note) THE ONE THING TO CHECK: the win screen's PALETTE

Win a match as Huitzil and look at the victory portrait.

- **Expected now: GOLD** — his normal palette family, matching your
  VS2 capture.
- **Before (ping #8): pink/lavender.**

That is the whole point of this build. I verified it in-emulator
(the win-screen palette RAM reads vs2's gold ramp `fffd ffb8 fd96
fc86 fb75 f964 f753 f542` at both sample frames), but the reason
you are testing is that a measurement agreeing with itself is not
the same as the screen being right.

## STILL BROKEN — please do NOT spend time re-reporting these

- **The garbled blue-grey blocks on the win pose** (eye / thigh /
  foot). This is a SEPARATE art defect from the palette — tiles the
  anim walk missed. Untouched here, known, next on the list.
- **The 236P freeze ray still does not draw a beam**, and the ES
  big-beam / grab lightning / 214 explosion family with it. Deeply
  decoded this session but parked behind a tooling gap.
- **The child companion's shadow is still rectangular.** Now
  measured and attributed (a bank-0 piece family, uniform -0x16A8
  tile-code delta) but not yet fixed.
- Dark Force style (inverted colours + afterimages) and FG pacing:
  untouched.

## What else changed since ping #8 (hui9, 9e3105e0)

All behaviourally inert, but listed so a surprise is attributable:
- the ported companion-spawner region now starts at its true machine
  boundary (it previously excluded its own record-base load);
- two newcomer-id mask widenings (vsavj loaded a WORD where vs2
  loads a LONG, so ids >= 16 branched on a stale register bit);
- a generator facility for authored union rows (inert — nothing
  declares one).

Gates at cut: boot (masked-v2 EXACT), ex, grab, air, pairs, walk,
fx_flow, ladder, m3a-reproducible — all PASS. Frozen references
(donovan-m3a 4b7d0dc7 / m5_stock 6c93cfa8) rebuild bit-exact.
