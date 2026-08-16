# `merged1` — the MERGED build's own legacy class table

Created 14z-91 (maintainer-ruled). `tests/audit_merged_legacy.sh` leg (a)
dispatches through THIS set, not through a tenant's.

## Why it exists

Leg (a) used to reuse a single-tenant set's ratified classes verbatim, with
merged-only exceptions written inline in the audit script. That worked while
there were one or two. The audit's own comment pre-registered the limit:

> this is the THIRD such exception, and a fourth should prompt "does the
> merged build want its own class table?" rather than a longer exception list

After the 14z-91 legacy-regression fix there were EIGHT, so the question was
put and answered: the merged build gets its own table.

## What the eight deviations were

Every one was the merged build diverging **LESS** than the single-tenant
prior — a strict subset of the frozen flicker inventory, none gained:

    04_select_fuzz     [1525,2009]  was [1525,2005,2009,2195]
    11_pick_donovan    []           was [2836]         -> plain window
    12_donovan_vs_cpu  []           was [2836,5713]    -> plain window
    22_don_dualmash    [11862]      was [11862,11918]
    23_don_matchwin    [12313]      was [12313,12733]
    24_don_winmash     [12313]      was [12313,12733]
    28_don_quotewin    [12407]      was [12407,12827]
    41_don_altcolor    []           was [2313]

That direction matters: these frames are cycle-boundary artefacts, and the
merged build's timing is not the solo build's. Fewer divergences from
vanilla is better legacy fidelity, not a weaker gate — a REGRESSION adds
divergence, and this table is exact, so an added frame still fails.

## What this set is NOT

It is not keyed by a build fingerprint. The merged instrument
(`build/merged1`) is rebuilt from scratch by every audit run and is
UNREGISTERED by design — `run_suite.sh` refuses it. So this directory is
selected by the audit's `EXPECT` constant, not by
`tools/build_fingerprint.py`.

## Maintaining it

The basis is the same frozen vanilla `tests/expected/vsavj/masked-v2`; only
the classes are the merged build's. When a deviation appears, the audit
prints the measured shape and a proposed line — that is a RATIFICATION
question, exactly as before. Do not copy a tenant set's line here, and do
not widen a tolerance: the two tables are measurably not interchangeable,
which is the whole reason this one exists.
