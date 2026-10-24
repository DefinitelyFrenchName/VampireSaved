THE PACKET

Decision kind: recommendation
Subject: #286 closed done: the record-only confirm tier measured (14z-207)
Claim (the working agent's sentence): #286 can close done (closing_comment.md): its done-when (issue286.md: "A record-only commit's --confirm tier is measured and re-runs only gates that open a record file, executing controls only for gates whose real inputs changed. The before/after figures are on this ticket") is measured on the Mac: the record-only probe f3445a70, one phrase changed in each of STATE.md, DECISIONS_HISTORY.md and docs/NEXT_SESSION.md on top of the second commit bbeedfed, ran a strict --confirm tier on that commit's GREEN base, GREEN with PASS 93, 3 changed paths, 45 of 231 gates STALE, 30 re-run, 63 carried, controls executed 0 and carried 345 (record_only_tier/summary.txt, record_only_tier/tier.log); crossed with fork R's ERIS trace of all 231 gates, 10 of the 30 re-run gates open a record file and 20 open none (record_only_tier/reruns_vs_opens.txt), and the maintainer ruled the open-none re-runs an accepted precision cost, quoted in ruling_286.txt ("(c) Accept as precision cost"), so the re-run clause stands as ruled, not as written; the controls clause is met (executed 0). The narrowing behind it, N-K, is fork R's (REPORT.md, its trace: 0 misses over 94,317 reads, the over-narrowed control 90, eris/trace_all.log). The before/after figures go on the ticket in the closing comment (135 re-run and 1,543 s of controls at c81dc932, the 14z-201 final tier, from issue286.md; 45 re-run with 0 controls executed on PILOT after #313, from lane F's report F_REPORT.md; 30 now). Not tested: the trace that classes 'opens a record file' was taken on ERIS at 93ecfae3, an earlier commit than the probe's, with 15 gates exiting non-zero under it for host reasons (REPORT.md); the trace sees file opens only, so a gate reading a record file through git would count as opening none; the open-none classes rest on fork R's reading (REPORT.md), not on a per-gate code read here; 15 of the 45 STALE gates were deferred by cadence and not run, so their open/none split was not measured in this tier.
Artifacts (read every one, in full):
  - build/agent207/R/closing_comment.md
  - build/agent207/R/issue286.md
  - build/agent207/R/record_only_tier/summary.txt
  - build/agent207/R/record_only_tier/tier.log
  - build/agent207/R/record_only_tier/reruns_vs_opens.txt
  - build/agent207/R/ruling_286.txt
  - build/agent207/R/REPORT.md
  - build/agent207/R/eris/trace_all.log
  - build/agent207/R/F_REPORT.md
