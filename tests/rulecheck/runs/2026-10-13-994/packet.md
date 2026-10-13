THE PACKET

Decision kind: recommendation
Subject: #273: put to the maintainer — the bounded Q1 measured; replicate before deciding — re-check after runs 983, 986, 988-991 and 993
Claim (the working agent's sentence): Recommend to the maintainer (build/agent199/t273/report.md) that the bounded Q1 be neither adopted nor rejected on this one-reader run, but replicated first (two more readers per arm on the 15 that mattered and the 4 fixtures, 76 pinned spawns), together with the question whether fidelity-14z160's EXPECT OK still stands, since its gate's FREEZE path exits 0 without checking its own failures (stage/2026-09-24-131/a/audit_forced_pick_fidelity.sh.txt:292-296, where bad at :82 only sets fail=1); alternatives offered: adopt V now, keep Q1 and triage at resolution (not measured), or keep Q1 and close #273. Measured per build/agent199/t273/plan.md, written 16 s before the first of the 108 t273 spawns and unchanged since (plan_order.out, from the session transcript: the content written then equals plan.md now), on 50 packets (the 46 agreed Q1 lines of 14z-196..198 and the 4 fixtures), each read once under the unchanged Q1 (arm C) and once under a bounded Q1 (arm V: the working agent's composite, quoted in full in the report — Q1's question kept, #273's sentence inserted with "unnamed premise" spelled out and "name the premise and" added, "there is none" made "there is none that would"), 100 pinned rule-checker spawns each checked prompt IDENTICAL by tools/rulecheck.py's spawn check (collect.out: 100 slot lines ok, every packet spawn_bad=0 missing=-), every copy equal to its run's manifest.tsv by tools/packet_check.py's staged_unchanged, fixtures included (manifest_check.out: 100 copies, 0 BAD), every handback in verdicts_all.txt; the checklist of record is unedited (checklist_diff.txt: 0 lines of git diff against HEAD and the index). Of the 15 that mattered, judged on the Q1 gap that mattered as the 14z-199 classifications record it (judge3/, the items built by judge3/build_items.py from each run's Q1 row, two fresh blind judges agreeing on 29 of 30), C caught 10 and V 8 (9 by one judge), V missing 774 and 908 and catching none C missed; under the first scoring, at least one gap of the original line, C 12 and V 9 (judge/merge.out); a second attempt (judge2/) is void, its builder having taken each run's last classification row instead of its Q1 row; of the corrected judging's judges, judge 5 returned a false report of an injected instruction in its input (its Read equals the file on disk, the text is only in its own reply) and wrote nothing, and judge 6 was stopped, both replaced; every judge's transcript shows a general-purpose opus agent that read only its instructions.md and items.tsv — the text equal to that items.tsv now — and wrote only its judge_N.tsv, the content equal to the file now (judge/judge_check.out); the 46 original runs record the same reader, rule-checker@163e4ce9cf7b (original_readers.txt); of the 30 that did not matter, Q1 VIOLATED C 26 and V 16 (dropped under V only 11, under C only 1, under both 3; tally.out); the negative fixture fidelity-14z160 is OK under C and Q1 VIOLATED under V, so V fails plan.md rule 5 as fixed beforehand; V's finding names a real feature of the fixture's file (FREEZE exits 0 without checking its failures), but whether the red is an over-fire or a gap the fixture's EXPECT and C miss is not tested — no artifact shows the freeze-time assertions failing. NOT TESTED: one reader per arm, no replicates — C itself re-finds the Q1 gap that mattered in only 10 of 15, so a two-in-ten difference is within what two single readers of one wording can show; only packets where Q1 fired; the mattered split is the 14z-199 rubric's; each judging's two judges share one criterion; the two criteria give 10 against 8 and 12 against 9, the same direction; the judges are one model kind; four runs answered in more than six lines and are counted as read, while plan.md says to leave them out (the six-line-only counts are in tally.out, same direction); that each of V's Q1 lines names what would change is the working agent's own reading; V is one composite of #273's sentence and another composite was not measured; the judges were blind to the arm label but not to wording, and V's lines often name what would change; the judging deviates from plan.md rule 2 — the judges were given every VIOLATED line of the new run, not only its Q1 line, to also score caught-on-any-question; option (c) is not measured.
Artifacts (read every one, in full):
  - build/agent199/t273/report.md
  - build/agent199/t273/plan.md
  - build/agent199/t273/inventory.py
  - build/agent199/t273/inventory.tsv
  - build/agent199/t273/build_stage.py
  - build/agent199/t273/build_stage.out
  - build/agent199/t273/collect.py
  - build/agent199/t273/collect.out
  - build/agent199/t273/manifest_check.py
  - build/agent199/t273/manifest_check.out
  - build/agent199/t273/checklist_diff.txt
  - build/agent199/t273/concat_verdicts.sh
  - build/agent199/t273/verdicts_all.txt
  - build/agent199/t273/tally.py
  - build/agent199/t273/tally.tsv
  - build/agent199/t273/tally.out
  - build/agent199/t273/judge/instructions.md
  - build/agent199/t273/judge/items.tsv
  - build/agent199/t273/judge/key.tsv
  - build/agent199/t273/judge/judge_1.tsv
  - build/agent199/t273/judge/judge_2.tsv
  - build/agent199/t273/judge/merge.py
  - build/agent199/t273/judge/merged.tsv
  - build/agent199/t273/judge/merge.out
  - build/agent199/t273/judge/judge_check.py
  - build/agent199/t273/judge/judge_check.out
  - build/agent199/t273/judge2/items.tsv
  - build/agent199/t273/judge3/build_items.py
  - build/agent199/t273/judge3/instructions.md
  - build/agent199/t273/judge3/items.tsv
  - build/agent199/t273/judge3/key.tsv
  - build/agent199/t273/judge3/judge_7.tsv
  - build/agent199/t273/judge3/judge_8.tsv
  - build/agent199/t273/judge3/merge.py
  - build/agent199/t273/judge3/merged.tsv
  - build/agent199/t273/judge3/merge.out
  - build/agent199/t273/original_readers.txt
  - build/agent199/t1/class_A.tsv
  - build/agent199/t1/class_B.tsv
  - build/agent199/t273/plan_order.py
  - build/agent199/t273/plan_order.out
  - build/agent199/t1/violations_196_198.md
  - build/agent199/tickets/T6.md
  - docs/project/rule_checker.md.lines-150-170 (lines 150-170 of docs/project/rule_checker.md)
  - DECISIONS_HISTORY.md.lines-6637-6649 (lines 6637-6649 of DECISIONS_HISTORY.md)
  - build/agent199/t273/stage/2026-09-24-131/a/audit_forced_pick_fidelity.sh.txt
