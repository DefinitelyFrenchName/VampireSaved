THE PACKET

Decision kind: recommendation
Subject: #176 finding (2): the delay is the motion-input window (random 14-19 on vsavj, fixed 16 on vs2); answer as facts and re-ask (re-checked after 354)
Claim (the working agent's sentence): Answer the maintainer's questions on #176 finding (2) as facts, and re-ask the decision without concluding anything about feel. The maintainer's words (maintainer_176.txt): "I lean 2 but I need more information and context: what is this delay, when is it applied, how does it affect vanilla characters. When you say VS2 never call the RNG, have you checked the same characters in both games ...". "2" is the option "Record; (2) is host behaviour".
WHAT IT IS. The "channel machine" of the earlier finding is the command-input MOTION TRACKER system (engine_internals_1318_1360.txt). The earlier name "effect-channel" was wrong and will be corrected in the docs. The helpers "lea <step-table>(pc),a3; bra <tracker-dispatcher>" are vsavj 0x29DC2-0x29F42 (vsavj_entries.txt); the trackers are 8-byte structs, "+4 timeout counter".
The delay is that timeout: the window the player has to enter the motion's next step.
- The counter is decremented at vsavj 0x29F96 and vs2 0x292F0, both subq.b #1,$4(a4) (tracker_countdown.txt).
- On a step, vsavj's code reaches 0x2A524 (bsr from 0x29F90) and arms the counter with table[rand&31] from 0x2A55A (tracker_vsavj_window.txt). vs2's same code arms it with move.b #$10,$4(a4), a constant 16 (tracker_vsav2_window.txt).
- The table is 16/32 of 14, 4/32 each of 15 and 16, 3/32 each of 17 and 18, 2/32 of 19; mean 15.344. vs2 still carries the same table, unread by that code (window_table.txt).
- Both games also have a fixed-12 arm (vsavj 0x2A552, vs2 0x29898). It did not fire in these runs, and the second random site 0x2A53E did not either.
MEASURED (tracker_delay.sh/.py/.log): the values written to P1's tracker timeout bytes from frame 2600, seed 5a5a.
- Lei-Lei on vsavj: 107 random arms, 14x53 15x13 16x8 17x13 18x13 19x7.
- Lei-Lei on vs2: 102 arms, all 16.
- Lei-Lei on ours: identical to vsavj (the same tap sha1).
- Phobos on native vs2: 252 arms, all 16.
- Phobos on ours: 265 random arms, 14..19.
Every reader of the RNG word ($FF80D4-D5), tapped unfiltered, is only the routine's own three reads on both games, in these legs:
- from 2600 on Lei-Lei, vsav2 and vsavj (tracker_delay.log);
- over the whole run on Phobos, native and ours (rng_readers.sh, rng_readers.log).
The boot readers at 0x000D32 and 0x000D36, caught before 2600, show the tap sees readers outside the routine. So vs2 does not reach randomness another way at this point: its code writes a constant there.
Summary: vsavj randomises every character's step window; vs2 fixed it at 16 for every character. Ours keeps vsavj's window for the original characters, bit-identical. It also gives the tenants vsavj's window, where native gave them 16.
NO CONCLUSION ABOUT FEEL. One capture was attempted and did not isolate the window: a special came out at every gap, and the detector does not say which special (gapsweep.sh, gapsweep.py, gapsweep.log, gapsweep_note.txt).
THE DECISION RE-ASKED (the maintainer's):
(a) record it as host behaviour, the maintainer's lean. This changes no byte: it keeps what the build does today. The standing principle "vanilla wins ties" (state_vanilla_wins_ties.txt) speaks of a console port against arcade vsav, so here it applies by analogy only.
(b) give the tenants vs2's fixed 16. This would change the tenants' tracker code. It would need a working capture and the usual measurement before any byte moves.
(c) first build a capture that isolates the window, then decide.
The recommendation is (a), because it moves nothing and keeps (b) open as a ticket.
NOT tested:
- whether a player can feel the difference;
- P2's trackers;
- trackers these rigs did not arm;
- turbo speed;
- seeds other than 5a5a;
- other RNG words or timers used elsewhere in either game, which were not searched.
The replays of the "ours" legs carry ours' cursor path: the prologue's p1 inputs at 1100-1280 are rewritten, as the parity gates do (tracker_delay.sh, rng_readers.sh).
Artifacts (read every one, in full):
  - build/agent185/t176/maintainer_176.txt
  - build/agent185/t176/engine_internals_1318_1360.txt
  - build/agent185/t176/vsavj_entries.txt
  - build/agent185/t176/tracker_countdown.txt
  - build/agent185/t176/tracker_vsavj_window.txt
  - build/agent185/t176/tracker_vsav2_window.txt
  - build/agent185/t176/window_table.txt
  - build/agent185/t176/tracker_delay.sh
  - build/agent185/t176/tracker_delay.py
  - build/agent185/t176/tracker_delay.log
  - build/agent185/t176/rng_readers.sh
  - build/agent185/t176/rng_readers.log
  - build/agent185/t176/gapsweep.sh
  - build/agent185/t176/gapsweep.py
  - build/agent185/t176/gapsweep.log
  - build/agent185/t176/gapsweep_note.txt
  - build/agent185/t176/state_vanilla_wins_ties.txt
