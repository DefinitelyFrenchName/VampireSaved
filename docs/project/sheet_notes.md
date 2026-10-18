# Capture sheet notes — what each sheet's gate is for, and what it does not cover

**STATUS: live since 14z-205 (2026-10-18, #291; the maintainer: *"Such an explanation would be a great addition to all
other capture sheets"*).** One `## <gate>` section per gate, read by `tools/proof_sheets.py page`, which shows a gate's
section above its pictures; a gate with no section shows none. A section says, in plain words, WHY the gate compares
the legs it compares and WHAT a reader of the pictures might expect it to check that it does NOT. The facts stay in the
gate's header and the subject documents; a section names a ticket by its number and never restates its status.
`tests/test_proof_sheets.sh` holds the rendering and refuses a section whose gate does not exist.

Format: paragraphs, `- ` bullets, `**bold**`, `` `code` `` and `#N` (rendered as a link to the issue).

## audit_dmg_legacy_sweep

**Why the gate looks the way it does.** It was built for #191, not for the superset invariant. #191 began as a tenant
question: Donovan took 9 HP from Demitri's 2HK on our build but 8 on native vs2, and the worry was that the +1 was ours.
To settle that, the gate compared vsavj with vs2 on every legacy victim. It showed the two original games already
differ: vs2 lowered Demitri's own attack records (10/14/20 → 9/13/18), and swapping those records swaps the damage both
ways. That's why #191 closed as not-ours. Our build appears in the gate only through Donovan's legs (ours against native
vs2).

**What isn't covered.** Under the superset invariant, Demitri's 2HK/5HP/623HP on every legacy victim must be identical
on our build and on vsavj. Nothing checks that for these legs today (#295):
- This gate doesn't run them on our build.
- The whole-RAM legacy oracle covers 53 replays, and none is one of these. These legs also use forced picks and HP pins,
  which the oracle's replays don't.
