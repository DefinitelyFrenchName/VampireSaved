THE PACKET

Decision kind: expectation
Subject: #180: freeze the donovan_2_ko part of tests/audit_throw_registration.sh (the third hit-registration pair store, reached by an applier KO)
Claim (the working agent's sentence): Freeze the donovan_2_ko rows into tests/expected/throw_registration.tsv (native: contacts f6002 p1=none p2=none and f6018 p1=+9 p2=+8, live-pair writers 0289c6,0289ca,028a94,028a98,028b5a,028b5e; ours merged-m20: the same contacts and steps, live-pair writers 0cfc14,0cfc18,0cfce2,0cfce6,0cfda8,0cfdac, no dead-pair writer), because the third pair store (vs2 0x028B5A/5E) is reached only by the object-hit applier's KO branch (vs2 0x28B08 bmi on +0x52 after its own damage call), which the part produces by poking the victim's HP words to 4 and its +0x138 to 0 two frames into Donovan's Sharirum Luna [6MP], and merged-m19 reads the swap (p1=+8 p2=+9, the stores on the dead pair); NOT tested: a KO reached in real play rather than by pokes, whether Pyron's or Phobos's copy of the third pair (e.g. Pyron's at the placed 0x478988) is reachable at all — their Planet Burning and Zodiac Fire KOs went through the damage routine instead and never reached it — a P2-side attacker, and the rows of the other four parts, which this freeze re-writes from the same run but which are not claimed to change.
Artifacts (read every one, in full):
  - build/agent184/t180/tr_gate.diff
  - build/agent184/t180/tr_ko_second.log
  - build/agent184/t180/tr_ko_m19.log
  - build/agent184/t180/ko_summary.txt
  - build/agent184/t180/ko_other_summary.txt
  - build/agent184/t180/vs2_028a6a.dis
  - tests/expected/throw_registration.tsv
