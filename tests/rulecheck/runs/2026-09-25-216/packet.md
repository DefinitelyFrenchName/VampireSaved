THE PACKET

Decision kind: recommendation
Subject: 14z-182 #136 full-scope re-derivation: every scope item of the issue body and thread mapped to a gate or ticket; three findings put to the maintainer
Claim (the working agent's sentence): Recommendation to the maintainer: #136's scope, re-derived from the issue body and all 11 comments (not only the last list 14z-181 closed against), maps item by item to a gate that measures it or a ticket that carries it (build/agent182/t136_scope_map.md) EXCEPT three findings — GAP 1: 'movement physics, measured live' has no ours-vs-native gate for any tenant (Phobos's walk and air gates compare against frozen values, Donovan and Pyron have none; the parity table compares x/y only inside move events); GAP 2: the throw-damage scaler question the thread left 'unmeasured' has no ticket and no gate; GAP 3: coverage_matrix.md:30 heads its row COVERED while its body still lists three items as uncovered that 14z-181 covered — so the recommendation is to open a ticket for GAP 1 and one for GAP 2 (#136 stays closed: an item left open is its own ticket), and to correct the coverage row now. NOT tested: the in-DF mapping from the parity table's NOT-IN-DF rows to df_moves.tsv is by event NAME, not by an assertion any gate makes; the movement search is by keyword over tests/*.sh file text (a gate measuring movement under other words would be missed); whether the gates named as homes are currently green is taken from their last recorded runs, not re-run this session (only the attribution gate was); no behaviour a player could feel is concluded.
Artifacts (read every one, in full):
  - build/agent182/t136_scope_map.md
  - build/agent182/t136_scope_reader1.txt
  - build/agent182/t136_homes_reader2.txt
  - build/agent182/t136_parts_measurer3.txt
  - build/agent182/t136_df_measurer4.txt
  - build/agent182/t136_movement_measurer5.txt
