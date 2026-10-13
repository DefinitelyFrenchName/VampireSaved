THE PACKET

Decision kind: recommendation
Subject: #273: put to the maintainer — the bounded Q1 measured; keep Q1 as it is
Claim (the working agent's sentence): Recommend to the maintainer (build/agent199/t273/report.md) that Q1 of the checklist of record stay as it is and the bounded wording of #273 not be adopted, with two alternatives offered: adopt it anyway with fidelity-14z160 recalibrated, or triage at resolution instead (not measured). Measured per the pre-registered build/agent199/t273/plan.md on 50 packets (the 46 agreed Q1 lines of 14z-196..198 and the 4 fixtures), each read once under the unchanged Q1 (arm C) and once under the bounded Q1 (arm V), 100 pinned rule-checker spawns each checked prompt IDENTICAL by tools/rulecheck.py's spawn check (collect.py), every handback in verdicts_all.txt; the checklist of record is unedited (git diff HEAD of docs/project/rule_checker.md empty). Of the 15 that mattered, C caught 12 and V 9 on the same premise (two blind judges, 0 of 30 disagreements, judge/merge.out), V losing 774, 807 and 908 and catching none C missed; of the 30 that did not matter, Q1 VIOLATED C 26 and V 16 (dropped under V only 11, under C only 1, under both 3; tally.out); the negative fixture fidelity-14z160 is OK under C and Q1 VIOLATED under V. NOT TESTED: one reader per arm, no replicates — C itself missed 3 of the 15, so the 3-of-12 difference is within what two readers of one wording could show; only packets where Q1 fired; the mattered split is the 14z-199 rubric's; the two judges are one model kind; four runs answered in more than six lines and are counted as read, while plan.md says to leave them out (the six-line-only counts are in tally.out, same direction); that each of V's Q1 lines names what would change is the working agent's own reading; option (c) is not measured.
Artifacts (read every one, in full):
  - build/agent199/t273/report.md
  - build/agent199/t273/plan.md
  - build/agent199/t273/inventory.py
  - build/agent199/t273/inventory.tsv
  - build/agent199/t273/build_stage.py
  - build/agent199/t273/build_stage.out
  - build/agent199/t273/collect.py
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
  - build/agent199/t1/violations_196_198.md
  - build/agent199/tickets/T6.md
  - docs/project/rule_checker.md.lines-150-170 (lines 150-170 of docs/project/rule_checker.md)
