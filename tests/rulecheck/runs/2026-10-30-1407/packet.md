THE PACKET

Decision kind: recommendation
Subject: close #337 as done (14z-213), after run 2026-10-30-1406: the mktemp census checks EXIT-trap order (TRAPPED) with a shlex trap reader that names what it cannot read (UNREADTRAP), re-traced on PILOT
Claim (the working agent's sentence): CLAIM: close #337 as done (14z-213), after rule-checker run 2026-10-30-1406: the closing comment closing_comment.md and the row ticket_row_337.tsv state the resolution. The ticket (issue_337_body.md) asked to teach the mktemp census to check EXIT-trap order itself, with known answers in tests/test_tmp_hygiene.sh (a trap before a site naming "$X/…", through a cleanup function, across a continuation, a later trap that must not count) and a planted control, then re-trace the gate on PILOT. It rests on:
1. THE CHANGE: fix.diff — tools/tmp_hygiene.py gains _code_lines (the logical-line reader sh_scan already used, moved out unchanged), _functions, _trap_cmds (every `trap` in command position outside quotes, comments and heredoc bodies, its words read by shlex from the source text: a quoted action across lines, `trap --`, the '\'' idiom; UNREADTRAP for a trap whose action cannot be read), sh_exit_traps, sh_trap_order, the TRAPPED and UNREADTRAP report lines and an EXIT-trap count in the summary; tests/test_tmp_hygiene.sh gains tests/trap_forms.sh (ten forms that must each be named TRAPPED), tests/trap_unread.sh (two that must be named UNREADTRAP), tests/trap_safe.sh (six that must not be named), the count check (10 EXIT traps read in the forms) and the controls planted-trapped and planted-unread-trap. records.diff: tests/controls_concurrent.txt (test_tmp_hygiene's row and its TRACES lines; the same file's test_green_guard row and TRACES line belong to #267), docs/platform/gotchas.md (the mktemp entry's new paragraph), docs/NEXT_SESSION.md (the instrument note).
2. THE TREE, BY THE CENSUS: census_now.txt — exit 0, 0 TRAPPED, 0 UNREADTRAP, "487 mktemp -d substitution(s) and 481 EXIT trap(s) read". pairs.py / pairs.txt (a census-reader measurement: it imports the census's readers) — 552 files, 487 guarded sites, 7 with an EXIT trap set on an earlier line, 0 of those 7 traps naming the site's variable at all. trap_calls.py / trap_calls.txt (census-reader) — of 481 EXIT traps, the 2 whose words match a function defined only in another file are `python3 tools/run_record.py ... write ...` lines whose matching words (record, run) are command arguments.
3. THE TREE, INDEPENDENTLY OF THE CENSUS: trap_words.sh (find + grep -nw trap, no census code) lists 735 lines holding the word trap in the census's shell files (trap_words.txt, kept locally and not in this packet: 80 KB is more than a reader sees whole; trap_account.txt's first line carries its count); trap_account.py classes each: COMMENT 152, READ 478 (a line where the census read a trap command), OTHER 105, UNREAD 0 (trap_account.txt, every OTHER line printed); trap_account_byeye.txt reads the 105 file by file: echo/printf/python strings, sheet ids, a variable c_trap, comments after code, and test_tmp_hygiene.sh's heredoc fixture bodies — none a trap command in its file's code.
4. THE GATE ON BOTH HOSTS: gate_mac.log (the Mac; its header: /bin/sh is /bin/bash via /private/var/select/sh, BASH_VERSION=3.2.57(1)-release, blobs 3c27ccd3 and aeb5eaa3; the session's working tree with the sitting's other uncommitted edits) PASS, every known-answer line ok; control_modes_mac.log: all seven control modes (planted-trapped, planted-unread-trap, planted-unguarded, planted-mktemp, planted-mkdtemp, planted-unsandboxed, shim-blind) exit 1. pilot_tmp_hygiene.log: PASS on PILOT; pilot_retrace.sh made the clone fresh (rm -rf, git clone --no-checkout of PILOT's checkout, fetch of the bundle, checkout 4eb25f40, a commit object of the Mac's tracked working tree, never on main); pilot_state.txt: /bin/sh -> dash, HEAD 4eb25f40, tests/test_tmp_hygiene.sh and tools/tmp_hygiene.py at the Mac's blobs (3c27ccd3, aeb5eaa3) on disk and at HEAD, 0 tracked changes.
5. THE RE-TRACE (the #315 method): pilot_overlap.txt "SAFE 1: test_tmp_hygiene", pilot_classes.tsv the seven control runs, each HONOURED.
6. THE RULING: DECISIONS_HISTORY.md lines 9030-9045, "State it as a limit + ticket" (this ticket's origin).
NOT TESTED: the census reads shell text and does not interpret it — a trap set through eval, or by a command word other than a plain `trap` in command position (builtin trap, command trap: none among the tree's 735 trap lines, per trap_account_byeye.txt), a function the trap calls that is defined in another file (followed in the same file only), an action that reaches X through another variable (rm -rf "$p" where p was built from X), and an rm whose path is assembled elsewhere are not read; which of several earlier traps is in force is not decided (every earlier trap counts, the cautious side), nor is a trap inside a function body read where the function is called (it counts where it is written); a || return guard is read like an exit (cautious: a return runs no trap); the 105 OTHER lines are classed by eye, not by a tool; files the census does not walk (other directories, other extensions) are outside both readings; the PILOT re-trace traced the gate's controls, not the census over PILOT's tree beyond the gate's section 1; shells other than bash 3.2 (the Mac) and dash (PILOT) did not run the gate.
Artifacts (read every one, in full):
  - build/agent213/t337/closure/closing_comment.md
  - build/agent213/t337/closure/ticket_row_337.tsv
  - build/agent213/t337/closure/issue_337_body.md
  - build/agent213/t337/closure/fix.diff
  - build/agent213/t337/closure/records.diff
  - build/agent213/t337/closure/census_now.txt
  - build/agent213/t337/closure/pairs.py
  - build/agent213/t337/closure/pairs.txt
  - build/agent213/t337/closure/trap_calls.py
  - build/agent213/t337/closure/trap_calls.txt
  - build/agent213/t337/closure/trap_words.sh
  - build/agent213/t337/closure/trap_account.py
  - build/agent213/t337/closure/trap_account.txt
  - build/agent213/t337/closure/trap_account_byeye.txt
  - build/agent213/t337/closure/gate_mac.log
  - build/agent213/t337/closure/control_modes_mac.log
  - build/agent213/t337/closure/pilot_tmp_hygiene.log
  - build/agent213/t337/closure/pilot_retrace.sh
  - build/agent213/t337/closure/pilot_state.txt
  - build/agent213/t337/closure/pilot_overlap.txt
  - build/agent213/t337/closure/pilot_classes.tsv
  - DECISIONS_HISTORY.md.lines-9030-9045 (lines 9030-9045 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-30 (14z-212) — #333: EXIT-trap order is stated as a limit, its measures best-effort")
