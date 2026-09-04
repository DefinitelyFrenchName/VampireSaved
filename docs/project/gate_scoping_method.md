# Gate scoping — how a comparison gate is built, challenged and hardened

**What this document is.** A worked method for building a gate that compares
our build against a reference, told through one case that went wrong in
several instructive ways before it went right (14z-131, Phobos's throws). The
maintainer asked for it because *"it's a typical example of how to close gaps
on tests, strengthen gates, guarantee that tests are properly scoped"*.

It is a METHOD document, not a record of that session — the session record is
STATE 14z-131 and the gates are
`tests/audit_tenant_throw_geometry.sh` and `tests/audit_pyron_capture_block.sh`.

---

## 0. The shape of the case

A tenant (Phobos) performs three throws that had a long correction history.
The question: are they identical to their VS2 originals? The instrument: run
the same replay on our build and on native `vsav2`, and compare what the
victim does.

Every rule below was paid for inside that one question.

---

## 1. The reference is the SOURCE GAME, and the control is not a baseline

**[VSP-167]** **A ported character's reference is the game it came from, and a
"control" leg is an INSTRUMENT CHECK, never a baseline for the thing under
test.** For a tenant the only vanilla reference is `vsav2` — not VS, and not
another character: *every throw is character-specific, so no second character
can tell you what this one should look like.* What a second leg CAN do is
establish that the comparison is readable at all — that the two games agree on
the coordinate convention, the pose-index space, the rig's timing and the poke
path — by running content whose behaviour is already pinned. Label it as an
instrument check; labelling it a "control" invites the reading that it is a
reference, which is a category error a reviewer will (rightly) reject.

And state what the control actually demonstrates. Here the "legacy control"
(Demitri) turned out to be a stronger thing than first claimed and a weaker
one: his capture block IS ported from VS2 by the #104 work, so the leg
demonstrates *ported row → ours matches native*, and does NOT demonstrate that
VS and VS2 natively agree.

## 2. Scope the observable to what the mechanism can actually cause

**[VSP-168]** **Before attributing a difference to a mechanism, check the
mechanism can PRODUCE that observable — and exclude observables it cannot.**
The capture positioner at `PRG:0x02802E` writes only the victim's `+0x10/+0x14`.
It therefore cannot change which sprite is drawn, so a POSE difference is not
evidence about it, and a first analysis that reported one had a second
mechanism in play it had not named.

The same rule excludes cross-generation confounds. A legacy victim in our
build is *VS's* version of that character; on the native leg he is *VS2's*.
Their art is different by construction, so the victim's PIXELS are not
evidence about our port. Compare the LOGICAL slot instead — resolve the pose
pointer through each game's own index table — and say in the gate that pixels
are deliberately not compared, so nobody re-derives it as a finding.

## 3. Compare ORDER and identity, not sets

**[VSP-169]** **A comparison of SETS is blind to order and dwell; compare the
ORDERED sequence of states, and report — never assert — the timing.** The
first cut compared the set of position offsets and the sequence of *distinct*
poses. Two runs can visit the same states in a different order and pass that.
Replaced by the ordered `(pose, dx, dy)` sequence with dwell counts over every
sampled frame, which is what actually says "the same thing happened".

Split the assertion from the observation along the axis the project has
already ruled on: STRUCTURE is asserted (which states, in which order; damage
amount and the state it lands in), TIMING is reported (dwell, frame numbers,
the ours/native ratio). On this engine the host runs ~9% slower than VS2 per
[VSE-83]/#114, so any frame-indexed assertion is a trap and any frame-indexed
*measurement* is a free confirmation of that rate.

## 4. Prove the rig produced the event — every leg, every run

**[VSP-170]** **A comparison gate must refuse to judge a leg that did not
produce the event, and must assert any RESOURCE the event consumes.** Two
distinct ways this bit one gate:

* the ES version of a command throw **degrades silently to the normal version
  when the meter is empty** — same offsets, same poses, same damage, a
  perfectly healthy-looking run that measures the wrong move. The
  discriminator is the resource: the stock must drop, and the non-ES replay
  under the same poke must NOT drop it.
* a first window simply missed the hold, and the honest response was a
  positive control (does ANY attacker set the captured flag on this rig?)
  rather than a conclusion.

So: liveness first, verdicts second, and a leg with no event is VOID — not a
pass and not a failure.

## 5. Widening is a measurement, not a judgement call

**[VSP-171]** **When the sample is a judgement call ("one victim or all
eighteen?"), MEASURE THE COST before arguing about it — and when you widen,
re-check every constant the narrow version froze.** Measured here: one victim
27.7 s, all eighteen 186 s at 6-way parallelism — ~6.7x the time for 18x the
coverage, which ended the discussion.

Widening then paid for itself twice over, and both payments are the point:

* it **found a residue the narrow gate could not see** — 5 of 54 victim/throw
  cells differ by exactly ±1 total damage, on victims the single-victim
  version never ran;
* it **exposed a frozen constant as victim-specific**. The narrow gate froze
  the post-release arc peak as `278`/`380`. Those were *Victor's* numbers; the
  arc is victim-dependent and spans eleven values. The narrow freeze was not
  wrong for Victor — it was wrong ABOUT WHAT IT WAS FREEZING, and only a
  second victim could show that.

A corollary worth stating on its own: when a per-item expectation turns out to
be UNIFORM across the widened set (here the end-of-hold tail, identical for
all eighteen victims), freeze the one shape rather than N literals — and read
the uniformity itself as evidence about the mechanism.

## 6. Do not lose a check while strengthening one

**[VSP-172]** **A rewrite that strengthens one assertion must be diffed
against what it REPLACED, because the check you silently drop is the one that
earned its keep.** Widening this gate dropped the post-release arc comparison
— the single assertion that had just retired a nine-session-old suspicion in a
replay header. It was restored, and its frozen value corrected in the same
pass. Nothing announced its absence; only re-reading the old version did.

## 7. Look before you characterise

**[VSP-173]** **Capture the picture BEFORE writing the sentence about it, not
merely before concluding a defect exists.** A correct measurement plus an
invented direction word is a false claim, and it is the SENTENCE — not the
number — that the next session acts on. One finding here was measured twice by
independent methods and then described as "hurls the victim ~130 px overhead
and drops them behind", which the captures refuted: the raw `dy`/`dx` signs had
been read as up/behind without ever establishing the engine's screen
convention. Put a legacy/known-good pair in the SAME capture sheet so the
reader can validate the comparison by eye in one second, and say plainly which
columns are NOT comparable (here: frame-aligned columns, because our hold runs
longer).

## 8. When the instrument and the artifact both look wrong, suspect the instrument

**[VSP-174]** **A "divergence" that appears on exactly the rows with a special
resolution rule is the resolver, not the build.** Widened to all eighteen
victims, this gate reported that all three TENANT victims diverged — and their
pose pointers came back unresolved. That `?` was the tell: a tenant victim on
our leg is held on the PLACED copy of VS2's table, not vsavj's, and the
analysis had used vsavj's for everyone. With the documented rule applied, the
unresolved count went to zero and every tenant matched. `audit_don_grab_pose`
had already written that rule down; the cost of not reading it first was one
alarming and entirely false result.

---

## The order that falls out of all this

1. Archaeology — read the subsystem doc and the existing gates first
   ([VSP-155], [VSP-14]). Two of the traps above were already written down.
2. Pin the mechanism from the ROM (disassemble the consumer) so you know what
   the observable can and cannot be.
3. Build the rig; prove it produces the event on BOTH legs before reading any
   verdict.
4. Measure statically first where you can — it is free and it predicts what
   the emulator should show.
5. Capture, look, and only then write the characterisation.
6. Compare ordered structure; report timing.
7. Measure the cost of widening, then widen; re-check every constant.
8. Diff the strengthened gate against what it replaced.
