THE PACKET

Decision kind: recommendation
Subject: #273: put to the maintainer — the bounded Q1 measured; replicate before deciding — re-check after runs 983, 986, 988 and 989
Claim (the working agent's sentence): Recommend to the maintainer (build/agent199/t273/report.md) that the bounded Q1 be neither adopted nor rejected on this one-reader run, but replicated first (two more readers per arm on the 15 that mattered and the 4 fixtures, 76 pinned spawns), together with the question whether fidelity-14z160's EXPECT OK still stands, since its gate's FREEZE path exits 0 without checking its own failures (stage/2026-09-24-131/a/audit_forced_pick_fidelity.sh.txt:292-296, where bad at :82 only sets fail=1); alternatives offered: adopt V now, keep Q1 and triage at resolution (not measured), or keep Q1 and close #273. Measured per build/agent199/t273/plan.md, written 16 s before the first of the 102 t273 spawns (plan_order.out, from the session transcript), on 50 packets (the 46 agreed Q1 lines of 14z-196..198 and the 4 fixtures), each read once under the unchanged Q1 (arm C) and once under a bounded Q1 (arm V: the working agent's composite, quoted in full in the report — Q1's question kept, #273's sentence inserted with "unnamed premise" spelled out and "name the premise and" added, "there is none" made "there is none that would"), 100 pinned rule-checker spawns each checked prompt IDENTICAL by tools/rulecheck.py's spawn check (collect.out: 100 slot lines ok, every packet spawn_bad=0 missing=-), every copy equal to its run's manifest.tsv by tools/packet_check.py's staged_unchanged, fixtures included (manifest_check.out: 100 copies, 0 BAD), every handback in verdicts_all.txt; the checklist of record is unedited (checklist_diff.txt: 0 lines of git diff against HEAD and the index). Of the 15 that mattered, C caught 12 and V 9 on the same premise (two blind judges, 0 of 30 disagreements, judge/merge.out; each judge's own transcript shows a general-purpose opus agent that read only instructions.md and items.tsv — the text equal to items.tsv now — and wrote only its judge_N.tsv, the content written equal to judge_N.tsv now, judge/judge_check.out), V losing 774, 807 and 908 and catching none C missed; of the 30 that did not matter, Q1 VIOLATED C 26 and V 16 (dropped under V only 11, under C only 1, under both 3; tally.out); the negative fixture fidelity-14z160 is OK under C and Q1 VIOLATED under V, on a premise its own file bears out, so the red is not counted as a cost. NOT TESTED: one reader per arm, no replicates — C itself missed 3 of the 15, so the 3-of-12 difference is within what two readers of one wording could show; only packets where Q1 fired; the mattered split is the 14z-199 rubric's; the two judges are one model kind; four runs answered in more than six lines and are counted as read, while plan.md says to leave them out (the six-line-only counts are in tally.out, same direction); that each of V's Q1 lines names what would change is the working agent's own reading; V is one composite of #273's sentence and another composite was not measured; the judges were blind to the arm label but not to wording, and V's lines often name what would change; the judging deviates from plan.md rule 2 — the judges were given every VIOLATED line of the new run, not only its Q1 line, to also score caught-on-any-question; option (c) is not measured.
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
  - build/agent199/t273/plan_order.py
  - build/agent199/t273/plan_order.out
  - build/agent199/t1/violations_196_198.md
  - build/agent199/tickets/T6.md
  - docs/project/rule_checker.md.lines-150-170 (lines 150-170 of docs/project/rule_checker.md)
  - DECISIONS_HISTORY.md.lines-6637-6649 (lines 6637-6649 of DECISIONS_HISTORY.md)
  - build/agent199/t273/stage/2026-09-24-131/a/audit_forced_pick_fidelity.sh.txt
