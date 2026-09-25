THE PACKET

Decision kind: recommendation
Subject: 14z-182 #132: recommend closing the ticket 'release/merged-m15 was never packaged' as declined — the gap recorded as intended, nothing packaged
Claim (the working agent's sentence): Recommendation to the maintainer: close #132 as declined (the ticket index's 'ruled not to be done'), recording the gap as intended — merged-m15 (the 14z-130 M13 boot-title freeze) was superseded by merged-m16 (14z-132) before any release, the 14z-134 opener already recorded it 'superseded before release, recorded, not owed', its tag freeze/merged-m15 (1101112c) and its build dir build/m3b_merged22 remain the way back, and no GitHub release exists for any freeze before merged-m18; the alternatives offered are (b) package it now from a worktree at the freeze tag with that commit's packaging tool, in the 25/25/28 layout its neighbours m14 and m16 carry, and (c) package it with today's tool in today's 29-file layout. NOT tested: whether build/m3b_merged22 still rebuilds byte-identical from its tag, and whether the packaging tool at 1101112c runs on this host today — neither is needed by the recommended option; no gameplay is affected by any option.
Artifacts (read every one, in full):
  - build/agent182/t132_measurer_return.txt
