# STATE — living progress log

**SPLIT 2026-08-20 (14z-99 post-freeze close, maintainer-approved), AMENDED
2026-09-14 (CLAUDE.md [VSP-17] and [VSP-182]): this file holds the RECENT
session groups and the STANDING SECTIONS; the full detail of every older
session lives verbatim in `STATE_HISTORY.md`, under THE LEDGER at its head.**
How to work with it:
- **Lookup**: "STATE 14z-XX" references resolve here first, then in
  STATE_HISTORY.md (its LEDGER first) — section names are preserved verbatim
  in the archive. A reference to `STATE "Decisions pending"` for an entry no
  longer here resolves in `DECISIONS_HISTORY.md` (entries move there verbatim
  when ruled — since 2026-09-14; before that, once they stopped shaping work).
- **Claim-greps MUST include STATE_HISTORY.md** (the CLAUDE.md §5
  retraction-discipline command names it).
- **AN OPEN LIST HOLDS ONLY WHAT IS OPEN (maintainer-ruled 2026-09-14).**
  "Decisions pending" holds undecided items only; nothing closed stays in it,
  however it is marked (struck through, DONE, FIXED, CLOSED). Where each thing
  goes instead:
  - a RULED decision -> its whole entry moves VERBATIM to
    `DECISIONS_HISTORY.md` in the commit that records the ruling; while the
    ruling still constrains work, ONE line stating the rule sits under
    "Standing rulings" here, and the line is deleted when it stops;
  - a BUG, COSMETIC ITEM or EVOLUTION is a TICKET — listed in
    `docs/project/tickets.tsv`, its story on its GitHub issue, never listed
    here; a STATE entry for one that closes moves VERBATIM to
    `STATE_HISTORY.md` under the closing session's key (CLAUDE.md [VSP-182]:
    the four questions, the closing comment);
  - "STANDING PRINCIPLE" and "THE DEADNESS REGISTER" carry the [VSP-21..23]
    anchors and stay; the register keeps its withdrawn rows by [VSP-23].
  `tests/test_state_open_lists.sh` enforces it, with the size budget and the
  group count below.
- **ROLLOVER RULE (part of the session-close ritual)**: after writing the
  close entry, move session groups beyond the newest THREE to the TOP of
  STATE_HISTORY.md's body (below THE LEDGER, above its first `## Session`)
  and add their one-line entries at the top of THE LEDGER there, composed from
  the group's own banner headers. If this file still exceeds ~150 KB, roll the
  oldest kept group early. The standing sections never roll.
- **THE LAST STEP OF THE CLOSE IS THE PUSH (maintainer-ruled 2026-09-10):**
  static tier strict green WITH every control executed (the default `all`), the doc checks green, nothing pending -> `git push
  origin main`; anything red or skipped leaves the commits local and the
  close entry says so.

## Session 14z-153 — **THE WINDOWS BINARIES PUBLISHED (seven assets, every one downloaded back and identical); THE RED THAT DID NOT SAY WHY
## ROOT-CAUSED TO THE HARNESS; THE LAST WINDOWS CR BYTE FIXED; AND THE RELEASE RUN'S `--controls` COST MEASURED OVERNIGHT — +33%, 90% of it Verilator. No shipped ROM byte moved.**

| | |
|---|---|
| opened with | the opener read (HANDOFF, STATE, NEXT_SESSION in full), ROM audit **76/76**, `main` == `origin/main` at `666b14d9`; the maintainer: *"publish the Windows binaries"* — the one item waiting on their word |
| **REBUILT, NOT REUSED** | the 2026-09-12 records predated the `tree`/`jobs`/`env` capture, so an entry from them would rest on memory. The box's clone fast-forwarded `a145562c` -> `666b14d9`. Over SSH (MSYS2 MINGW64, the script as ONE `{ …; } </dev/null` block so no child can eat the rest of a stdin script; the ssh detached on the Mac with `nohup … &!`, so the MSYS2 job ran inside a live session): preflight READY (24 jobs, 31 GB, 1.3 GB per job); FBNeo from a clean worktree of the pin in 4 min 39 s (30 DLLs bundled, 83 MB); MAME through its own mirror in 9 min 25 s (static, 16 system imports, nothing bundled, 120 MB). Both records: `tree 666b14d9e8dc`, `jobs 24`, the `env` lines, no uncommitted-changes flag |
| **THE GATE ON THE BOX** | `MERGED=build/fromrelease tests/test_release_binaries.sh`: **`PASS: test_release_binaries (windows-x86_64)`** in 112 s — FBNeo booted with every descriptor member `(OK)`; MAME's `-verifyroms` flagged exactly the 20 WIDE members and the release binary reproduced `05_timeout_idle`'s frozen masked expectation; both must-fire controls FIRED, each on FBNeo (MAME bundles nothing to perturb). Log kept at `build/test_release_binaries-windows-14z153.log` on both hosts |
| **ON THE MAC** | the two folders copied with `scp -r musicmaking:C:/msys64/home/alexr/vampire-saved/release/emulators/<kind>/windows-x86_64`, every sha256 row re-verified here (FBNeo 31, MAME 1). `package_release_platforms.py` re-run with the MRAs staged out first (it clears its destination): **5 tracked files, 10 lines — the availability lists in the three READMEs and the two `EMULATOR.md`**, plus the ignored `bin/windows-x86_64/` dirs. `test_release_asset_shape` PASS (2 controls fired), `test_release_roundtrip` PASS (8 controls fired). The four Windows records carry no CR, no U+FFFD, and the build-resource and release copies are identical |
| **PUBLISHED** | `tools/upload_release_assets.sh freeze/merged-m18` from the Mac, no `--prune` (the previous freeze's assets went at 14z-149): **7 assets, every one downloaded back and compared file for file** — fbneo-recipe 25, fbneo-macos-arm64 48, **fbneo-windows-x86_64 55 (29.5 MB)**, mame-recipe 25, mame-macos-arm64 26, **mame-windows-x86_64 25 (23.8 MB)**, mister 28; no stale asset named; the release notes rewritten listing all seven. The five existing assets were re-cut and re-uploaded because the README inside each changed its availability list |
| **THE REGISTER** | `docs/project/build_environments.md`'s Windows entry REPLACED by the one `tools/record_build_environment.py` composed from the rebuilt records and the PASS log — package versions identical to the manual capture of 2026-09-13 — with a `published` row. The decision in "Decisions pending" marked DONE in place; HANDOFF's prebuilt row and NEXT_SESSION corrected |
| **NOTED, NOT FIXED** | `tools/bundle_win_dlls.py`'s console output prints U+FFFD for its em dash on MSYS2 — native python piping cp1252, the class 14z-152 fixed in the gate's verdict text with `sys.stdout.reconfigure`. Build-log cosmetics only: no record and no verdict carries it |
| **(2) PUSHED, THEN THREE ITEMS IN THE RECOMMENDED ORDER** | the maintainer: *"push the BINARY.txt records"* — `b48e8cc0` pushed; then NEXT_SESSION's three items, cheapest local first and the multi-hour controls last |
| **(2a) THE RED THAT DID NOT SAY WHY — THE HARNESS LOST ITS REASON, NOT THE KEPT LOG** | reproduced as prescribed: two clean worktrees at `b48e8cc0`, the MFI guide made stale in one (its `gen_skill_guide.py --check` exit 1, the control's 0), bbh's `selftest/test_fidelity_vampire.sh` run directly, every line kept: **stale 33 lines, exit 1, ending after F11's skills-lock line; control 38, PASS** — with the wrapper's three lines, 35 and 40, 14z-152's figures exactly. The tier's kept-log code copies the gate's whole output, so it lost nothing. **CAUSE:** F11's four captures `x="$(cmd 2>&1; echo "exit=$?")"` had no `(set +e; …)` — under errexit the capture's subshell dies before its `echo`, and the assignment ends the script with the reason inside the variable (demonstrated on this Mac's `/bin/sh`: no "reached", rc 1). F4/F6/F7/F10 were already protected. **FIXED in bbh `f4094c2`, pushed:** the same stale run now prints `FAIL  F11 skill-guide differs or not current` with its diff, then F2 and the verdict (42 lines); the control is unchanged. **AND A LINT, because the class had now cost three times** (recorded 14z-136, the environment capture 14z-152, this): `selftest/test_capture_status.sh`, must-fire `unprotected-capture` (fired; the mode FAILS; an undeclared name REFUSED, exit 3), its pattern validated against the PRE-fix file (exactly lines 417/418/421/422) and clean over every harness script; bbh selftest **32 / 2 / 0**. Logs `build/bbhfid_14z153/`. **NOTED, not changed:** on that red path the two tools' STALE lines differ in their regenerate hint (`tools/gen_skill_guide.py` vs `bbh skill-guide`) — F11's identity had only ever been exercised on PASS. This tree's gates carry no instance (census) |
| **(2b) THE CR BYTE — LOCATED AND FIXED** | exactly ONE CR in the Windows gate log — byte 811 of 1459, ending line 7 (`-verifyroms: … none NOT FOUND`): the gate's `-verifyroms` Python heredoc printing through native text-mode stdout, because 14z-152's `reconfigure` sits in the self-containment block only. The same line added to that block of `tests/test_release_binaries.sh`. **Measured on both hosts:** macOS PASS, both controls fired, 0 CR — inert; Windows (the diff applied to the box's clone for the run) PASS, both controls fired, **1458 bytes, 0 CR**. The box's clone carries that change uncommitted until this commit is pulled there |
| **(2c) THE CONTROLS' COST — CENSUSED AND ESTIMATED, ~~NOT RUN~~ (then RUN overnight at the maintainer's word — see (2e))** | "34" was 14z-147's pass-3 GATE count, never a mode count: `ci_emulator.tsv` declares **39 controls in 36 gates** (fbneo 1, mame 30, mister 4, prereq 4). Joined to M18's release-run seconds: **~5.5 h serial for the modes alone, 4.6 h of it the four Verilator gates**; seven control-bearing gates have no M18 timing. `--controls` re-runs a gate once per control only after that gate PASSES, and its cadence is RULED (14z-148 (a)) as every RELEASE run — so the measurement belongs to the next release run, and a multi-hour run was not started unasked |
| **GOTCHAS** | two appended the moment paid: platform (a native Windows python's CRLF is per PROCESS), project (a status capture under `set -e` ends the script); `docs/GOTCHAS.md` regenerated |
| **(2d) THE PRE-COMMIT TIER WENT RED ON A FINDER FILE — the gate measured the host** | strict tier **149 / 0 / 1**: `test_release_asset_shape` §5 `left out of every asset: .DS_Store`. The file was `release/merged-m18/.DS_Store`, gitignored, written by Finder at 22:16 local — two hours AFTER the upload (20:28) and after the gate's last green (20:26) — so no published zip holds it (the served file counts also add up with none). Removed: the gate PASSES, both controls fire, both modes FAIL; the whole strict tier re-run before the commit. ~~**OPEN, with a recommendation:**~~ **RULED AND DONE — see (3).** Finder recreates these whenever `release/` is browsed, and `tools/upload_release_assets.sh` lists a platform directory with `find -type f`, so a `.DS_Store` INSIDE one would be zipped into its asset — teach the uploader and the shape gate to ignore `.DS_Store` explicitly rather than deleting by hand before each run. Not done tonight: the tree stays still under item 3's run |
| **(2e) THE RELEASE RUN'S CONTROLS — MEASURED OVERNIGHT, at the maintainer's word** (*"commit, push, and run item 3, you'll have all night ahead of you"*) | `d86e3a46` committed and pushed FIRST (the runner fails a run whose tracked files change), the box's clone brought to it (its untracked Windows records moved aside — they differed from the committed ones only by the `asset` line — and the committed rows re-verified against the binaries there, 31 + 1), then `tests/run_all_emulator.sh --scope all --lane all --strict --controls --jobs 4 --log build/emu_controls_14z153`, DETACHED, 2026-09-13T22:03:40Z -> 2026-09-14T03:40:20Z: **5 h 37 min wall. PASS 210 / SKIP 1 / FAIL 0 / TIMEOUT 0 / MISSING 0** — the SKIP is the approved `audit_mask_window_ff42a2`, and the runner's NOT GREEN is `--strict` counting it; **fired 39 / declared 39, executed 39, every control honoured**; `test_mister_prg_window`, M18's one red, PASS; no tracked file changed during the run. **THE COST, serial:** gates 13.62 h; **controls 4.51 h = +33%** — mister 4.08 h (4 controls, each a FULL re-run of its gate: the tenant and obj oracles ~75 min each, prg_window 57 min, sdram_census 38 min), fbneo 628 s (`test_dualtrack@stray-byte-growth` 628 s against its gate's 634), mame 903 s for 30 controls (several stop at their first perturbed input — `audit_guard_corpus@known-crash` 21 s against 1,830 s), prereq 43 s. The 5.5 h estimate was high mainly because it assumed every control costs its whole gate. Wall time is NOT compared with M18's ~7 h release run: a different machine load, and four jobs hide the serial sum. Recorded beside the emulator-tier command in HANDOFF; rows `build/emu_controls_14z153/results.tsv` |
| **A TODO FROM THE MAINTAINER, re-targeted the same night** | run the same `--controls` tier on another host to compare its speed — first asked for the Windows box, then moved to **the dedicated Linux server once it exists**, because on the box the whole POSIX tier would have to run under WSL2 (native Windows is HANDOFF's highest porting cost; only `test_release_binaries` was ever ported to MSYS2, and the rest natively is unmeasured). Carried in NEXT_SESSION |
| **CLOSE (2026-09-14)** | the close tier's figures are in the close commit's message (`build/static_14z153_close.log`, run DETACHED after every edit of the close). STATE rolled — the 14z-150 group to the archive with its ledger line (STATE was 154 KB with four groups); the NEXT_SESSION opener archived verbatim and rewritten. This sitting's commits: `b48e8cc0` (the Windows records), bbh `f4094c2` (the fidelity fix + lint), `d86e3a46` (the CR fix, three gotchas), and this close. **The close ends with a push** ([VSP-17]) |
| **(3) `.DS_Store` IS IGNORED — RULED (maintainer, 2026-09-14: *"they must be ignored (and we should remove them from the github as well through our next push, no need to remove them form all the history"*)** | MEASURED FIRST: **none was ever committed** — no `.DS_Store` tracked in this tree or in bbh, none at `origin/main`, and both `.gitignore` files already carry the rule, so there was nothing to remove from GitHub. THE CENSUS of every release listing that can see a dotfile found exactly three, each a `find`: the uploader's asset list (which WOULD have zipped one inside a platform directory into a published asset), `test_release_asset_shape` §5 (the 14z-153 red) and `test_release_roundtrip` §4's inventory; globs and `ls` skip dotfiles, the packager copies only named files, the rule-7 scan walks the gate's own temporary package, `test_release_binaries` checks only record rows. **THE CHANGE: one definition, `tests/lib/os_metadata.sh` (`vs_drop_os_metadata`, the exact basename only), and the three `find`s pipe through it;** `release_format.md` "Never ships" names it. **GROUND TRUTH `tests/test_release_os_metadata.sh`** (ci_portable, ~3 s): the filter over look-alikes; the REAL uploader, `--dry-run`, in a throwaway git repo over a synthetic release with four planted `.DS_Store` — all 3 assets cut, no list and no zip carrying one (17 members read back); the wiring of the three listings; must-fire `filter-disabled` FIRED, its mode FAILS (four leaked into three assets), an undeclared name REFUSED 3. **And the two edited gates measured with a REAL `.DS_Store` planted at the release root and inside `fbneo/`: both PASS** (§5 "no file … left out"; the inventory clean, its `stray-file` control still firing), the planted files removed. Registered: `ci_portable.txt`, the gate index regenerated (327 scripts, 0 problems), the must-fire census 91 declaring. A mode bit of mine: the new gate was written 0644 and first ran `permission denied` — `chmod +x` |
| **(3b) THE FIDELITY QUESTION — ANALYSED, ~~AWAITING A RULING~~ RULED: REQUIRE THEM TO MATCH — see (3c)** | the maintainer, on whether F11 should also require the two tools' stale-guide lines to match: *"I am unsure, what is the cost/benefit/risk analysis?"* Given: the lines differ by design (each names its own regenerate command); requiring a match moves NO verdict (a stale guide is red either way, and red with its reason since bbh `f4094c2`); the benefit is only proof, ahead of a real stale guide, that the two detectors agree — each already has its own stale-guide ground truth (`test_skill_guides`, bbh `test_skills`); the cheapest form masks the command name in F11's comparison plus one synthetic stale case on a copy (~30 lines, no verdict text moved, no re-baseline); forcing either tool's text to match would make it wrong for its own users. Recommended as low-priority harness hygiene, doing nothing defensible. Carried in NEXT_SESSION |
| **(4) THE STATE.md DISCIPLINE PASS — SCHEDULED FIRST THING NEXT SESSION** (maintainer, 2026-09-14) | the ask: *"we again have many open items (decisions, bugs, etc.) that are still listed as open with a mention that they are actually closed. This is a bad pattern that we must avoid by actually updating the correct documents, github issues, etc. and removing the closed items from the open ones"*; then *"that document discipline, especially for STATE.md is supposed to be documented and enforced, either in CLAUDE.md or in skills"*; then *"do it first thing in next session"*. THE CENSUS behind it, all read-only: STATE.md 146.7 KB = session groups 41.5 KB + THE LEDGER 48.0 KB (184 lines) + standing sections 55.4 KB; at least 11 closed-but-listed entries in the open lists; 0 open GitHub issues; STATE.md's own header, the port skill's [VSP-10]/[VSP-17] and nothing in CLAUDE.md WRITE the in-place pattern down, and no gate enforces any of it. **This sitting's own record carries the pattern too** (the ~~OPEN~~ DONE rows above and in "Decisions pending"), which is the point. The plan — the law (wording approved first), the header rule, the skill, a gate `test_state_open_lists`, then the clean-up — is NEXT_SESSION's first item |
| **(3c) THE FIDELITY RULING, IMPLEMENTED** (maintainer, 2026-09-14: *"Let's require them to match. If and only if this raises issues, we'll reconsider."*) | "Match" implemented as the analysis framed it: bbh's F11 now also runs the RED path — a copy of exactly the files the guided skills read (listed from the consumer config, 16 files today) with one GUIDE.md hand-edited; both generators must exit 1, report it STALE and print IDENTICAL text once ONE thing is masked, the regenerate command each names for itself (`tools/gen_skill_guide.py` / `bbh skill-guide`) — neither tool's text changed. Prototyped on a scratch copy first (the masked diff empty, the command the only difference). **bbh `b27b6ee`** (the check + its header) and **`03f5916`** (the dated re-baseline line quoting the ruling), both pushed; the fidelity run PASS with the new row; `test_capture_status` PASS (every new capture `(set +e; …)`); bbh selftest **32 / 2 / 0**. This tree unchanged by it: `test_bbh_fidelity` PASS at `03f5916`, 41 lines against 40 (the one row added), its LAST RE-BASELINE line the new one. The 11 doc checks over this sitting's edits all PASS |

## Session 14z-152 — **THE LOOP MOVED ONTO THE MAINTAINER'S BOX OVER SSH, AND ALL THREE PLATFORMS' RELEASE GATES WENT GREEN: the Windows FBNeo red was the gate,
## the Linux self-containment check was blind on a build host and was re-anchored, qmake6 is a Linux prerequisite, and a register records where a build is known to work. No shipped ROM byte moved.**

| | |
|---|---|
| opened with | the opener read (HANDOFF, STATE, NEXT_SESSION in full), ROM audit **76/76**, `main` == `origin/main` at `fb530857`; the maintainer asked whether a Claude Code session should run ON the Windows box. **RULED: SSH from this session — "my preference is SSH, no doubt"** (nothing to transfer, the macOS inertness re-check of a shared-script fix stays in one session, one committer) |
| **THE WINDOWS FBNeo RED WAS THE GATE** | the maintainer's MSYS2 run: MAME green in full (`05_timeout_idle` reproduced on the release binary, the first time outside macOS), FBNeo red on `lacks 'CPS-2 WIDE v1 profile active'`. The kept log carried all 31 `(OK)` lines and NO core line; `strings` found the message in the `.exe` once. **ROOT CAUSE, in the pinned source:** `src/burner/sdl/main.cpp` connects `bprintf` only `#if defined(BUILD_SDL2) && !defined(SDL_WINDOWS)`, so every emulator-core message is dropped on Windows. The member loads run inside `Cps2Init`, which the vsavjw entry's `Cps2WideInit` calls after `Cps2Wide = 1` (both asserted from the patch) → `tests/lib/fbneo_boot_log.sh` (every descriptor member `(OK)`; the profile line wherever the core's `*** Starting emulation` line reaches the log — keyed on the evidence, never the OS name) + `tests/test_fbneo_boot_log.sh` over the RECORDED Windows and macOS logs. The binary check now matches the FULL message (`CPS-2 WIDE v1` alone is the driver's name); `OS=windows` → `HOSTOS` in the gate and `collect_build_report.sh`, the 14z-151 (6a) collision still living in two scripts. `8b908cd4` |
| **WORDING, MEASURED BEFORE FIXING** | the `ok:` lines said "signed" under the gate's own "no code signature exists" note, and the dash printed U+FFFD. Probe on MSYS2: native python pipes cp1252 (the dash as byte 0x97) WITH CRLF; `PYTHONIOENCODING` fixes the encoding only → `sys.stdout.reconfigure(encoding="utf-8", newline="\n")`. Windows gate re-PASS reading `unsigned (no signature exists on windows)`, zero U+FFFD. `32268250`. ~~One CR byte remains in that output, unlocated; no verdict depends on it~~ **LOCATED AND FIXED 14z-153:** the `-verifyroms` Python block's PASS line, printed through native text-mode stdout; that block reconfigured too, 0 CR on the box |
| **SSH, SET UP AND MEASURED** | a dedicated passphrase-less key (the maintainer's choice), `ssh musicmaking` = `MUSICMAKING.local` (the router's `.home` name answers a stale address); MSYS2 and WSL2 driven by scripts on stdin, never quoted through cmd.exe. **The WSL2 Linux user is `koneko`, not `alexr`.** Detached jobs: a WSL2 job survives a disconnect ONLY while a Windows-side WSL window is open — my first "it survives" was RETRACTED within the hour by repeating the test with that confounder removed (the `sleep` gone, the VM rebooted); MSYS2 unsettled |
| **THE LINUX MAME BUILD NEEDS `qmake6`** | the first WSL2 attempt had died on `Hangup` (its terminal closed); relaunched detached, it died on `char8_t` 167 files in. `make -n` showed a bare `-I` immediately before `-std=c++20`: MAME's `sdl_cfg.lua` adds `-I$(shell qmake6 -query QT_INSTALL_HEADERS)` for linux UNCONDITIONALLY. `qt6-base-dev-tools` does NOT ship `qmake6` (its package listed before anything was installed); the `qmake6` package does — installed by the maintainer; the build then finished EXIT 0 in 40 s with zero Qt libraries in `cps2`'s closure. `setup_mame.sh` and the preflight refuse a Linux host without it; both guides, the gotchas and HANDOFF corrected — and `WINDOWS_BUILD.md`'s apt line still named `libsdl3-dev` and missed `libsdl2-ttf-dev`/`libfontconfig-dev` |
| **THE LINUX GATE'S DEAD CONTROL WAS A REAL BLIND SPOT** | the first Linux run: FBNeo's boot and MAME's frozen expectation PASS; `absolute-reference` DEAD. Measured: on a build host every bundled library also resolves system-wide (18/18 MAME, 17/17 FBNeo — my first count read 0/18 because `ldconfig -p` puts a TAB before each soname; corrected with a positive control), so "resolved under /usr/lib = host runtime" passed a folder with libSDL2 removed. **RULED: option 1 now — an EXTERNAL list plus ruled exceptions, never the bundler's policy ([VSP-166]) — and option 3 the goal (a clean-machine resolution at release time on top); all five exception groups ACCEPTED.** `tools/check_host_libs.py` (R1 a direct NEEDED soname not shipped must be on the list; R2 a shipped one must resolve inside; R3 nothing not found; empty inputs REFUSE), `tests/expected/linux_host_provided.tsv` (manylinux_2_39 from auditwheel 6.4.2 + 13 ruled), `tests/test_host_libs.sh`, all measured on the real folders before landing. **The Linux gate then PASSED end to end at `a145562c`**, the control firing on `cps2 needs libSDL2-2.0.so.0: not in this folder and not on the host-provided list` |
| **KNOWN-GOOD BUILD ENVIRONMENTS** (the maintainer: "knowing in what exact circumstances is the build known to be a success is the true minimum bar") | `docs/project/build_environments.md` (INDEX); `tests/lib/host_env.sh` (every prerequisite's version from brew / dpkg-query / pacman, NOT INSTALLED when absent — measured with positive controls on all three hosts; its first version DIED under `set -e` on an absent package, caught by its own test before the builder ever ran it); the builder records `tree`, `jobs` and the `env` lines and `CHECK=1` prints them (verified on all three hosts); `tools/record_build_environment.py` composes an entry only from a PASS log and records that carry the capture; `tests/test_build_environment_entry.sh`. macOS and Windows entries captured after their builds. **The Linux entry was written BY THE TOOL:** rebuilt on WSL2 with the capturing builder at `a145562c` (both records: `tree a145562c008e`, `jobs 8`, 21 `env` lines, none NOT INSTALLED), the gate re-PASSED on the rebuilt binaries with both controls firing, and `record_build_environment.py` composed the entry — the whole pipeline proven on a real host, its package versions identical to the manual capture of the afternoon. A proof run, never published |
| **A RED OF MINE, AND ONE THING NOT ROOT-CAUSED** (~~not root-caused~~ **ROOT-CAUSED AND FIXED 14z-153: the HARNESS lost the reason, not the kept log** — F11's status captures had no `(set +e; …)`; see STATE 14z-153) | editing the anchored `[MFI-23]` paragraph left the MFI skill GUIDE stale → a strict tier went 147/0/2 (`test_skill_guides`, `test_bbh_fidelity`), regenerated, both PASS — the GENERATED-index rule, broken by me for a skill guide. **OPEN:** that run's kept `test_bbh_fidelity` log did not carry the harness's own FAIL reason (35 lines against 40 on the fresh PASS: the F11 guide line, F2 and the harness's final line all absent) — a red that did not say why. Reproduce in a clean tree |
| **THIS MAC'S MEMORY** | the harness killed one static tier and two watchers for low memory (46% free, Chrome and a second Claude session); every later tier ran DETACHED with a PID watcher |
| strict static tiers | `static_14z152_fbneo_log` 148/0/0 (154/154 honoured); `wording2` 148/0/0 (154/154); `linuxrule` 147/0/2 (the stale guide); `envreg` **150/0/0, fired 158/158, honoured 158, lies 0** |
| **CLOSE (2026-09-13)** | **Strict static tier 150 / 0 / 0 GREEN, `fired 158 / declared 158`, `executed 158 honoured 158 lies 0 refused 0 died 0`** (`build/static_14z152_close.log`, run DETACHED). CI green on `8b908cd4`, `32268250` and `a145562c`. Four commits, the close the fourth; STATE 143.9 KB, three session groups, nothing rolled. **All three platforms' release gates PASS on real hosts** — macOS here, Windows on MSYS2, Linux on WSL2 — and no shipped ROM byte moved. The NEXT_SESSION opener archived verbatim and rewritten. Waiting on the maintainer: publishing the Windows binaries; the clean-machine Linux check waits on the dedicated server. ~~OPEN: the red that did not print its reason.~~ (ROOT-CAUSED AND FIXED 14z-153, in the harness.) **The close ends with a push** ([VSP-17]) |

## Session 14z-151 — **CI HAD BEEN RED FOR 43 CONSECUTIVE RUNS AND NEITHER CAUSE WAS THE TREE; AND THE RELEASE'S PUBLISHED
## ASSETS WERE CUT ALONG THE WRONG SEAM — RE-RULED, RE-CUT, AND GATED. No build byte moved.**

| | |
|---|---|
| opened with | the opener read (HANDOFF, STATE, NEXT_SESSION in full), ROM audit **76/76**, `main` == `origin/main` at `9f2891af`; the maintainer with two items — the release packaging is "not self consistent", and *"We again have a lot of CI errors on github following the pushes and releases, can you check why?"* |
| **CI: 43 RED RUNS, TWO CAUSES, NEITHER OF THEM THE ARTIFACT** | the last green run was 2026-09-07 (14z-139); every push since failed. **CAUSE 1, and it had been red since 14z-140:** `test_docs_site` asked `git check-ignore docs/site` — the ignore pattern is `docs/site/`, which matches DIRECTORIES ONLY, and git cannot know an ABSENT path is a directory, so a fresh checkout answers "not ignored". **The gate was measuring the HOST**: this Mac has the directory from a local render, CI never does. REPRODUCED by moving `docs/site` aside (the exact CI line), fixed by asking about `docs/site/`, re-proven three ways — green with the directory present, green with it absent, still FAILING in a synthetic root where the rule is genuinely missing. **CAUSE 2, since 14z-147c:** `test_mister_wide_gate` declares five must-fire controls that ARE Verilator benches and the runner has no Verilator, so they cannot fire and [VSP-181] calls that FAIL — correctly. The fix is to give CI the tool, not to soften the verdict: the job installs verilator and ASSERTS >= 5.0 (the benches need `--binary --timing`), so a too-old apt version says so at the install step instead of surfacing as a confusing "Verilator build failed" inside the gate. Measured here: the full gate is 34 s with its seven controls firing |
| **WHAT THE RED COST, and it is the argument for fixing it** | CI was not useless while red — it caught the 14z-150 markdown autolink. A permanently red pipeline is how a real red hides, and 43 runs is how long nobody looked |
| **THE RELEASE SEAM, RE-RULED** | measured first: on disk `release/merged-m18/<platform>/` is already self-sufficient ([VSP-100], 14z-113), but the 14z-149 ASSET cut excluded `emulator/bin/**` from the platform zips and shipped the binaries as bare directories — 25 files, no README, no applier, no patches. The maintainer: the prebuilt packages *"dont include the parts and doc to patch the roms, so you have to also download that, but doing so makes you download patches for emulators, which you might want to apply although you shouldn't since your prebuilt binary is already patched, it's very confusing"*, and the stance must be one or the other — fully separate, or per platform with everything in. **RULED: per platform, everything in; and a prebuilt asset DROPS the driver patch and the recipe** |
| **THE NEW CUT** | `<name>-<platform>-<os-arch>.zip` = README + patch set + manifest + applier + the prebuilt binary and its `BINARY.txt`, **no patch, no `EMULATOR.md`**; `<name>-<platform>-recipe.zip` = the same plus the patch and the recipe, **no binary**; `<name>-mister.zip` unchanged. ONE download plus your own dumps is playable. Measured on M18: 2.2 MiB recipe, 19 / 18 MiB prebuilt, 3.4 MiB mister. **THE FILE LIST IS COMPUTED ONCE per asset and drives BOTH the zip and the verification of what GitHub serves back** — an exclusion pattern on one side and a `find` on the other is the shape this tree has paid for before. Refusals, not hopes: an empty asset, a prebuilt with no binary, a recipe with no patch, an asset without its README or applier |
| **THE GATE, AND IT EARNED ITS PLACE ON ITS FIRST ADVERSE RUN** | `tests/test_release_asset_shape.sh` (ci_portable, ~5 s, two must-fire controls) over the lists the real tool cuts under `--dry-run`, with completeness asserted BOTH ways. Run under the FRESH-CLONE condition (binaries moved aside, records left) it went RED and was right: the tool's `--dry-run` output directory ACCUMULATED, so lists from the previous run read as current — the same trap the static runner's kept logs were given at 14z-150, in a different hat. Fixed in the tool (only this run's output survives), and `--dry-run` now writes nothing into the tree at all, which is what lets a gate run it |
| **THE CONTROL THAT WOULD HAVE REPEATED TODAY'S OWN DIAGNOSIS** | `route-mixed` first perturbed a PREBUILT list, so on a host with no binaries it could not fire — a declared control CI cannot run, which is exactly cause 2 above. Rewritten to force both routes into ANY list, so it fires on every host |
| **REGENERATED, NOT HAND-EDITED** | `release/merged-m18/` rebuilt by `package_release_platforms.py`: **106 files, 5 changed — the three READMEs and the two `EMULATOR.md`** and nothing else. Every patch, manifest, applier, MRA, bitstream and binary byte-identical. `test_release_roundtrip` green (round-trip, refusals, rule-7 scan, the six README sections, four controls fired); `test_release_binaries` green (record, self-containment, signature, `-verifyroms` flagging exactly the 20 WIDE members, MAME reproducing `05_timeout_idle`'s frozen masked expectation) |
| **CI GREEN — 2026-09-12, THE FIRST SINCE 2026-09-07** | the maintainer: *"Push first then re-cut"*. Pushed `b0b7e71e`, run 34656640142 **success**: `PASS 72 / SKIP 0 / FAIL 0`, `fired 103 / declared 103`, `executed 103 honoured 103 lies 0` — the same figures as the local tier. `test_docs_site` PASS 10 s, `test_mister_wide_gate` PASS **80 s** (it was 0 s while it skipped its benches), `test_release_asset_shape` PASS 1 s. **The job went 6 min -> 18 min 21 s, and the cost is legible rather than mysterious:** the mister gate now really builds eight Verilator benches, and because it PASSES its seven control modes are now executed too, each a fresh run of it. Worth a cadence decision if it grows again; the tier's own `--exec-controls` knob is where that lives |
| **THE RE-CUT, PUBLISHED** | five assets on `freeze/merged-m18`, each uploaded, downloaded back and every served file cmp'd against the tree's: fbneo-recipe 25 files, fbneo-macos-arm64 48, mame-recipe 25, mame-macos-arm64 26, mister 28. **A re-cut leaves the OLD NAMES behind and `--prune` cannot see them — it prunes the PREVIOUS freeze, not this one**: `merged-m18-fbneo.zip` and `merged-m18-mame.zip`, the exact confusing pair, would have gone on being served. The tool now NAMES every `<name>-*.zip` on the tag it did not build and says what to do; it does NOT delete, because binaries are per HOST and the Windows/Linux boxes will publish into this same release — deleting what a run did not build would let one machine erase another's. Deleted by hand here, notes rewritten, page down to five |
| **ONE NUMBER NOT ROOT-CAUSED, recorded rather than waved past** | the last RED run (34652118325, same commit `9f2891af`) printed `declared 105`, where the tree's OWN reader (`vs_ctl_declared` over `ci_portable.txt`) counts **101** at that commit and **103** at HEAD — exactly the +2 this session's gate adds, so NOTHING WAS LOST and that is measured, twice, by two independent counts. What is unexplained is the runner's 105 on a run with two RED gates; at HEAD the runner and the reader agree exactly (103 = 103). It is a READOUT arithmetic question, not a verdict: every gate verdict in both runs is consistent. The cheap way to settle it is to run the old worktree's tier and compare per-gate, ~20 min; not spent unasked |
| **(4) THE HARNESS README'S UNREADABLE COLUMN, AND THE 45 SIBLINGS THE REPORT DID NOT MENTION** | the maintainer, reading bbh's README: it *"has a table with a status column holding values H1 to H10 and zero explanation of what they mean. Either add the explanation if it adds value to the reader at the global readme file level, or remove it."* They are the EXTRACTION-PLAN slice names — a document in THIS repository, never defined in that one. **REMOVED, not explained:** the header said `status`, a slice is not a status, and every piece listed has landed, so a truthful column would repeat one word twelve times ([BBH-9]: a reference page says what is TRUE; how it came to be known belongs in a `_history.md` twin). And not only where it was reported ([BBH-8]): the same token sat in `config.md` (18), `drivers/README.md` (5), `hygiene.md` (3), `gate_contract.md`, `conventions.md` and the EXAMPLE consumer's provenance register, whose `since` column a consumer would have copied and been unable to fill. Where the tag carried meaning the THING is named instead. Kept: the history twins and the GENERATED guide, regenerated from the edited paragraphs. bbh `276b086`, pushed; check-skills 91 rules, selftests 31/2/0 |
| **(5) AND VERIFYING THAT FOUND THE THREE-TIME FLAKE — IT IS A STOPWATCH INSIDE TEXT COMPARED EXACTLY** | `test_bbh_fidelity` failed once here and passed alone, which is the pattern NEXT_SESSION called unexplained since 14z-149. **Run SIX times with every log kept: 1 red, and its whole content was one character.** bbh's F1 diffs the two static runners line for line; the output carries each gate's DURATION, not verdict text, so `norm()` masked it — in the COLUMN form (`PASS    1s`) ONLY. The controls readout appends it as a SUFFIX, `(1s)`, and the regex demands a space before the digits and a space or EOL after the `s`: `(` and `)` are neither. One runner's stub gate straddled a second boundary, the other's did not, and two IDENTICAL verdicts differed. **Fixed in the harness (`529f9d2`, pushed), PROVEN DETERMINISTICALLY rather than by hoping the flake stays away** — the two real lines differ under the old mask and are identical under the new — then corroborated 8/8 green. **NOT CLAIMED: that the two 2026-09-11 occurrences were this**; their logs are gone, this is the leading and only measured explanation. [BBH-81] states the general form: an extraction is proved by diffing the verdict TEXT, and a comparison carrying a stopwatch reading is measuring the machine's load |
| **(6) THE WINDOWS AND LINUX HALVES MET A REAL HOST, AND EVERY CLAIM WE HAD WRITTEN ON A MAC GOT TESTED** | the maintainer set both tracks up on the Windows box (MSYS2 native + WSL2) while the Linux server is pending. 14z-150 shipped those halves with a gate honest about never having run and an opener that said "EXPECT TO FIX SOMETHING". Seven defects in one sitting, each one only a real host could surface, and NOT ONE of them was in a shipped ROM byte |
| **(6a) OUR OWN SCRIPT OVERWROTE `$OS`** (the FBNeo link death: `cannot find -lGL`) | `OS` is an EXPORTED Windows variable holding `Windows_NT`, and a POSIX assignment to an already-exported name KEEPS the export — so the per-OS block's `OS=windows` replaced it for every child. **Both** build systems key on that exact value (`makefile.sdl2`, MAME's `makefile`), so FBNeo built AS IF FOR LINUX: `-lGL` is the X11 name, and every object had also been compiled without `-DSDL_WINDOWS`. MAME had not been reached and would have configured GENIEOS=linux. Renamed `HOSTOS`; demonstrated with `sh -c 'OS=windows; env \| grep ^OS='` rather than argued. Same family as the `CONTROL` collision of 14z-147 |
| **(6b) THE MSYS/NATIVE NAMESPACE SPLIT, three times** | `ldd` answers `/mingw64/bin/x.dll`; the recipe's python and both emulators are NATIVE and read that as the current drive's `\mingw64\bin`. It bit the bundler (a DLL "which does not exist" that was there all along), and it would have bitten the gate's `-rompath`, `-autoboot_script`, MAME's sandbox dirs, the env vars the Lua INSIDE MAME opens, and the staged `roms/` SYMLINKS a native program cannot follow. ONE translator now, `tests/lib/native_path.sh` (`cygpath -w`, MSYS2's own answer), applied at the single `exec` in `run_mame.sh`. **Inertness MEASURED** ([CPE-24]): VS_NATIVE=0 here, `05_timeout_idle` reproduces its frozen masked expectation exactly, `test_release_binaries` PASSES in full |
| **(6c) THE PLATFORM CLAIMS WE HAD ONLY EVER CHECKED ON macOS** | MSYS2 spells SDL3 LOWERCASE and SDL2 capitalised (`target not found` on the first command of the guide) — and on Windows MAME needs NO SDL at all. **MAME's OSD is a different one per platform** (`makefile`, "specify OSD layer"): linux `sdl` (SDL2 + SDL2_ttf + **fontconfig**, the Linux red), windows `windows`, macosx `sdl3`. The macOS answer had been written down as MAME's answer in five places, one of which sent Linux readers to COMPILE SDL3 FROM SOURCE for a library that build never opens. Plus: Linux is the one platform defaulting the Qt5 debugger ON, and the obvious `apt install qtbase5-dev` would LINK Qt5 into a binary we then ship — `USE_QTDEBUG=0` instead, already the default elsewhere, so the three binaries stay one instrument |
| **(6d) A GUARD THAT WAS RIGHT TO EXIST AND WRONG TO BE FLAT** | `REFUSING: the closure is EMPTY` on a correct build: MAME's Windows link is `-static` (its `genie.lua`, mingw*), so it imports system DLLs and nothing else. An empty closure has TWO OPPOSITE causes — the tools said nothing (broken instrument) or they listed imports that were all system (genuinely standalone) — and the discriminator is whether ANY import was reported. Both bundlers now count it; the gate gained the case, stubs and all |
| **(6e) TWO ERGONOMIC FAILURES, which is what a first run is FOR** | the gate's SKIP named a missing file and not the route (it now prints the three applier commands, resolving the release name from the tree), and the lever I handed them for the WSL2 thrash — `MAME_JOBS=8` — was being OVERRIDDEN by the release builder with `nproc`, so the one variable a person reaches for while their machine pages did nothing. Both fixed; the builder honours either spelling now |
| **(6f) WSL2 HALVES THE RAM AND KEEPS ALL THE CORES** | MAME ~10x slower under WSL2 than native on the SAME machine, CPU pinned. Microsoft's documented defaults: all logical processors, 50% of memory, swap 25%. 24 jobs against 16 GB = 0.6 GB each; **confirmed on the box at 1-2 MB/s of sustained swap**. FBNeo unaffected — smaller translation units. Not fixed by changing the default (`nproc` is right on a host whose memory matches its cores): the PREFLIGHT now prints GB-per-job and warns under ~1.2, naming the lever per entry point. A pinned CPU is what thrashing looks like |
| **(6g) WHAT IS NOW WRITTEN DOWN** | five platform gotchas appended the moment each was paid for ([VSP-12]) — the `$OS` collision, the namespace split, the MSYS2 package casing, the per-platform OSD + Qt, and the WSL2 memory arithmetic with how to read `vmstat`/PSI; `WINDOWS_BUILD.md` gained the drive-mount table (MSYS2 `/c` vs WSL2 `/mnt/c`), the romset-travels-between-hosts note (members identical, CONTAINER not — Python stamps the creating OS) and a non-optional `MERGED=`; `WSL2_SETUP.md` gained the capacity section; the fleet memory note now records what each machine can carry |
| **(7) A DECISIONS PASS, WHILE THE MAINTAINER'S BUILDS RAN** | STATE was 188 KB against a ~150 KB rollover rule, and the rule could not have fixed it: the two session groups are 28 KB while the STANDING sections are 113 KB and THE LEDGER 46 KB, neither of which ever rolls. **So the lever was the decisions, not the sessions** — 15 rulings from 14z-133b..14z-149 that had stopped shaping work moved BYTE-VERBATIM to `DECISIONS_HISTORY.md` under its own lifecycle rule (23 blocks, resolutions and their original entries together). **188 -> 128 KB, and five genuinely open items remain**: the capture matrix's in-emulator widening, the living-docs generalisation (ruled, unscheduled), the community cross-check's naming rigs, Zabel j.LK, and the rebuild-from-docs option. **TWO WERE MARKED IMPLEMENTED IN PLACE FIRST, after VERIFYING rather than trusting the entry** ([VSP-13]): the Verilator lane's `--jobs N` scratch clones and `ci_emulator.tsv`'s per-gate timeout column both landed at 14z-134 while their entries still read "not started" — a stale status is what a future session acts on |
| **(8) THE RELEASE GATE MET WINDOWS, AND EVERY RED WAS THE GATE** | five rounds against the maintainer's MSYS2 box, each one a real finding and none of them the artifact. **(a)** both must-fire controls perturb a BUNDLED LIBRARY and MAME's Windows build is `-static`, so the setup returned non-zero and `set -e` ended the run BEFORE ANY ASSERTION — the worst shape a gate can fail in; each control now CHOOSES its subject (MAME where it bundles, FBNeo where it does not) and names it in the readout, proven here AND against a simulated static-MAME directory. **(b)** the self-containment check reported 121 bundled DLLs as "outside this folder" while naming a path inside it — `ldd` answers in MSYS form and the comparing python is NATIVE, two namespaces; both sides go through one translator now, and `cygpath -m` (forward slashes) replaced `-w` everywhere because that spelling survives a path passing through a shell AND a native program. **(c)** the suite leg's rompath reached `build_fingerprint.py` — native python again — as POSIX: `vsavjw.zip not found`, then `unregistered build fingerprint`. **(d)** the boot left `config/ recordings/ roms/ savestates/ screenshots/` INSIDE the release directory and the next run flagged them: FBNeo resolves `roms/` against ITS OWN directory on Windows, so the gate now runs the emulator from a COPY with the zips staged beside it — never run the artifact in place. **(e)** `cmp: command not found` -> the suite called the run NONDETERMINISTIC, a verdict about a missing tool: MSYS2 ships no `diffutils`, now in the list with the preflight probing both names |
| **WHAT WINDOWS HAS ALREADY PROVEN** | FBNeo and MAME both BUILD there; MAME's `-verifyroms` passes on an applier-built romset — 20 members flagged, exactly the rewritten set, none missing — so the patched driver reads our set correctly on a platform it had never run on. **Still unproven anywhere but macOS: the FBNeo boot leg and MAME reproducing a frozen expectation.** The gate now keeps `build/fbneo_boot_<os>.log` whatever the verdict, so the next run comes back with the reason instead of the symptom |
| **CLOSE (2026-09-13)** | **Strict static tier 147 / 0 / 0 GREEN, `fired 151 / declared 151`, `executed 151 honoured 151 lies 0 refused 0 died 0`** (`build/static_14z151_close.log`, run detached). Twenty-two commits, all pushed; CI green; the M18 release page re-cut to five self-sufficient assets; the harness pushed twice. **NO BUILD BYTE MOVED ALL SESSION** — M18's patches, MRAs and published romset are untouched, which is the honest headline for a day spent entirely on the things around the artifact. **THE PGREP SELF-MATCH TRAP BIT AGAIN** ([[pgrep-waiter-self-match]] is a memory note and I still wrote one): a waiter using `pgrep -f "run_all_static.sh --strict"` matches its OWN command line and loops forever — the maintainer asking "it's been 40 minutes" is what surfaced it, not the waiter. Wait on a PID. **The close ends with a push** ([VSP-17]) |
| **BOTH OUTWARD ACTIONS DONE ON THE MAINTAINER'S WORD** | pushed, then re-cut, in that order. Nothing is pending; the tree, the release page and CI agree. The Windows/Linux build session (NEXT_SESSION item 1) is unaffected — it adds os-arch assets to this same release, and the tool's new notice is written for exactly that case |

---

# STANDING SECTIONS (current state — never archived)
## Standing rulings

One line per ruling that still constrains work; the full entry lives where the line says. A line is deleted when its ruling stops constraining work (CLAUDE.md [VSP-17]).

- **Static-tier controls at the CLOSE (2026-09-14):** a mid-session commit runs `tests/run_all_static.sh --strict --exec-controls none` plus `CONTROL=<name>` for every gate it adds or changes; the session close runs every control (the default). Full entry: `DECISIONS_HISTORY.md` "Ruled 2026-09-14 (14z-154)".
- **Release scope (2026-09-02):** at release every test whose SUBJECT is the released artifact runs, its legacy content included (a reference leg on vsav2 or pristine vsavj is not the subject); anything red or skipped is a hard fail unless approved at release time, so a release-scope gate fails loudly on a missing prerequisite. Full entry: `DECISIONS_HISTORY.md` "Moved 2026-09-14 (14z-154)".
- **A red gate is a question (2026-09-02):** before fixing the gate, fixing what it caught or deleting it, establish which side's expectation rests on a measurement; a frozen number whose provenance cannot be named is a claim. Full entry: `DECISIONS_HISTORY.md` "Moved 2026-09-14 (14z-154)".
- **The host engine's clock wins (2026-09-02, #114):** a ported character ticks like vsavj, so a tenant gate asserts hit counts and damage, never vs2's frame numbers; Lightning Sword LP one hit short at the mash ceiling is accepted. Full entry: `DECISIONS_HISTORY.md` "Moved 2026-09-14 (14z-154)".
- **No static substituted-wheel gate (2026-09-02):** declined — the pattern matches 26 legitimate gates; the defence is [VSP-163] (assert `+0x60` against `bases.tsv`, or force the pick). Full entry: `DECISIONS_HISTORY.md` "Moved 2026-09-14 (14z-154)".
- **Oboro's intro stays (2026-08-28):** never delay round start or cut the intro for a cosmetic reason. Full entry: `DECISIONS_HISTORY.md` "Moved 2026-09-14 (14z-154)".

## STANDING PRINCIPLE (maintainer, 2026-08-05): vanilla wins ties

**[VSP-21]** "vsav vanilla is always better when we can." **When a console port and
arcade vsav differ and both would work, take vanilla.** A console port's
choice is not evidence that vanilla is wrong; it is evidence of what that
port's designers preferred.

This is a general rule, not a one-off: the PS1 capture is a reference for
what is POSSIBLE and for data we cannot otherwise obtain (cell placement,
the adjacency of NEW cells), not a style guide for content vsav already
defines. Paired with the maintainer's other statement — "as long as we can
select characters it's good" — the test is: does keeping vanilla still let
the feature work? If yes, keep vanilla.

Applied immediately, twice:
- **`Bishamon DL` and `Aulbath DR` stay vanilla** (Anakaris / Sasquatch).
  PS1 sets both to "no move"; neither is needed for reachability, so
  vanilla stands.
- **Horizontal wrap stays vanilla.** Vsav wraps left/right (cell `0x01`
  Left goes to `0x05`, measured and confirmed in-emulator); the PS1 report
  of "no wrapping" reflects untested extremes. We touch none of those
  cells, so nothing to decide.

Judgment applied under the same rule, open to veto: the three inbound edges
from `0x0B` (`D`/`DL`/`DR` into the new row) DO diverge from vanilla, and
strictly they are not required — Phobos and Donovan are already reachable
via `Bishamon D` and `Aulbath D`, and Pyron through them. They are kept
because without them, pressing Down on the cell directly above the new row
does nothing while three medallions are visible below it, which is the UX
failure "as long as we can select characters" is meant to exclude. Dropping
them would reduce the legacy footprint from 5 bytes to 2.

## Decisions pending (human)

- **THE LINUX SELF-CONTAINMENT ANCHOR — DECIDED 2026-09-13: option 1 now, option 3
  the goal (not scheduled).** The everyday check is `tools/check_host_libs.py`
  against an EXTERNAL list plus five ruled exception groups (DECIDED and
  implemented at `a145562c`). The goal adds a clean-machine resolution at release
  time, on the dedicated Linux server kept free of `-dev` packages — to be built
  when that server exists. The WSL2 Ubuntu 26.04 Linux binaries are a PROOF run,
  never published (DECIDED).

- **THE CAPTURE-GEOMETRY MATRIX IS NOW SWEPT STATICALLY, and the maintainer
  asked for exactly this (2026-09-08).** Their words: *"that makes a strong
  argument for checking the whole combination of VS2 tenants thrown ... as
  well as our VS2 tenants throwing others"*, noting *"some of it has been
  done already but only in targeted cases known to be wrong"*.
  **DONE, and it is CHEAP because the comparison is ROM bytes:**
  `tests/audit_capture_matrix.sh` (ci_static, ~2 s) compares **640
  (attacker, victim) cells over 20 reachable attackers** against native
  `vsav2`, where the three in-emulator gates covered three. It found the
  Donovan/Jedah cell above on its first run.
  **WHAT IT DOES NOT CLAIM:** behaviour. It compares the DATA the engine
  reads; that the engine reads it identically in both games is what
  `audit_don_grab_pose`, `test_hui_grab_victim` and
  `audit_pyron_capture_block` anchor. **OPEN, and cheap:** widen the
  in-emulator anchors from 3 cells to a sampled row per tenant, now that the
  static pass says which cells are worth an emulator run.

- **THE LIVING-DOCUMENTATION FRAMEWORK'S GENERALIZATION — RULED AT THE PLAN
  STAGE (maintainer, 2026-09-08), NOT SCHEDULED.** Asked after L3 landed:
  *"Can this living documentation be generalized as a basic structure +
  self-test + claude skill like we have done with the BBH?"* The answer is
  yes, and `harness_scope.md` §2.7 had already parked exactly this question —
  the eight doc tools were decided OUT of bbh with the words *"a sibling
  package later if that effort wants one"*, conditioned on L1-L4 finishing,
  which they now have. **Three of the eight already lifted and are the proof
  the pattern works**: `bbh gate-index` (H5), `bbh check-skills` and `bbh
  skill-guide` (H10), each with fidelity exact.
  **SEQUENCING RULED THE SAME DAY: the OPEN ITEMS COME FIRST** (maintainer:
  *"Agreed"* to the recommendation that extracting a second package is
  infrastructure built on infrastructure, and that bbh's usefulness is still
  untested by a second consumer).
  **THE THREE DESIGN RULINGS, in the maintainer's words:**
  1. **INDEPENDENT BUT COMPATIBLE** — *"living documentation framework should
     be useable independently but fully compatible with BBH and relies on
     mostly the same principles."* So: NOT a bbh subpackage and NOT a
     dependency on it, but the same shape (one entry point, config-driven,
     a fake corpus, selftests, a skill) and the same principles. This settles
     the three-way question about `check-skills` / `skill-guide` /
     `gate-index` in the direction of compatibility rather than reclamation —
     the two packages may both carry a mechanism as long as they agree.
  2. **THE SITE GENERATOR IS IN SCOPE** — *"only a visualisation for humans
     but it's basically a free really-nice-to-have."* `mk_docs_site.py` +
     `md_subset.py` + `_pagestyle.py`, ~1,500 lines, measured at 2-4
     project-noun hits each: the most portable piece in the set.
  3. **FIDELITY: THE PRINCIPLE YES, THE FORM OPEN** — *"I don't know if
     byte-identical is warranted for the living documentation scope but on
     principle I agree."* So the extraction must be PROVEN against this
     tree, but the comparison class is a scoping question, not a given.
     Recorded so the scope document argues it rather than inheriting bbh's
     F-series by reflex: a renderer's HTML may reasonably be compared
     structurally where a checker's verdicts must be exact.
  **MEASURED at the ask (2026-09-08), the coupling census over 13 tools /
  ~5,800 lines:** near-zero coupling `doc_anchor_census` 0, `gen_skill_guide`
  1, `_pagestyle` 2, `md_subset` 3, `mk_docs_site` 4, `gen_gotchas_index` 4;
  config-driven `gen_gate_index` 5, `checkdocs` 18, `gen_annotations` 20,
  `checkskills` 21, `checkdocshape` 26; content-bound `audit_rule5` 24 (its
  389 measured pairs) and `checkdocs_rom` **99** (the checks ARE the claims —
  only the `Image`/`says`/`@check`/`@table`/`PARAPHRASE`/`--uncovered`
  framework is generic). **And it is CHEAPER than bbh was**: bbh needed a
  FAKE MACHINE so every class had a ROM-free producer; this needs a FAKE
  CORPUS, which is a directory of markdown. Cost: 2-3 sessions plus one for
  the skill. Deliverable when scheduled: `docs/project/<name>_scope.md` in
  the form of the other three scope documents.

- **THE COMMUNITY CROSS-CHECK — our data vs the best community reverse
  engineering (maintainer backlog item, 2026-08-31, 14z-124). ~~RECORDED, not
  started~~ PHASE 1 DELIVERED 14z-125 (the maintainer's order: "start with item
  2 to get proper confirmed data"): all 15 vanilla characters derived, the
  standing-normal join MEASURED in-emulator, and every comparable column
  classified — ~96% agreement per move under one stated convention each
  (`docs/project/tables/community_crosscheck.md`, gates
  `test_community_crosscheck` + `test_vanilla_frame_join`). STILL OPEN, and
  named on the page: **~~the residual ~4% outliers are not yet arbitrated
  in-emulator~~ ARBITRATED 14z-125b — two of the three families closed (the
  damage residue is the WORKBOOK double-counting records that share the engine's
  +0x10 dedup key, confirmed by a hit rig 75/78; the duration bytes are the
  engine's, 334/380, but a frame-rate trace cannot resolve a one-frame
  convention, so startup +1 / recovery +2 stay named conventions). ~~STILL OPEN:
  Jedah's crouching recovery (+3, not +2)~~ **CLOSED 2026-09-02 — ARBITRATED IN
  ENGINE TICKS, AND THE RESIDUE IS THE WORKBOOK'S.** The instrument the entry
  said did not exist does: a write tap fires per WRITE, and `PRG:0x027F70`
  (`subq.b #$1,$20(a6)`) IS one engine tick, so the multi-tick frames that
  defeated the frame-rate trace are fully visible. **18 of 18 derived totals
  equal the engine's measured tick count EXACTLY** (JE, LI, DE crouching
  normals; no tolerance). Our `startup` and `active` are not flagged and agree
  with the workbook's own conventions, and the total is now ground truth — so
  our recovery is right and the workbook's sits one frame below its own
  convention for those seven moves. `tools/tick_durations.py` +
  `tests/test_tick_durations.sh` (with a must-fire control). **THE SEVEN AERIAL OUTLIERS — PARTLY RESOLVED 2026-09-02.**
  `tick_durations.py` separates the move from the jump for chains that LOOP
  (BI 5/6 exact; the miss is the flagged `J.HP`, ours 28 vs the engine's 27; BU
  `J.LK`/`J.LP` exact). NOT separable yet: aerials whose last node HOLDS with no
  further pointer write before landing (VI, FE, SA) — those still report
  AIRTIME, and identical numbers across a character's moves are the tell.
  **THE LIKELY CAUSE IS NOW NAMED, from the community corpus that arrived
  2026-09-02:** mizuumi distinguishes NEUTRAL-jump from FORWARD-jump variants of
  the same button (`8J.LP` vs `9J.LP`, `J.HP8` vs `9J.HP`) where our slot map
  carries ONE chain per aerial button. If the flagged moves are exactly those
  whose variants differ, we are collapsing a variant, not miscounting. Needs a
  two-direction jump rig; not yet measured.
  ~~`red damage` needs the [VSE-40] scaler to be comparable at all~~ **WRONG and
  RETRACTED 14z-125b: the workbook's `red damage` is our `+8` PLUS `+9`, the
  move's total — 266/281 (94%) once compared as the sum;**
  specials / supers / throws / the `CL.` and `6`-prefixed rows need their own
  vsavj naming rigs (the bulk of the workbook's 730 rows); seven workbook
  columns have no counterpart in the tree. The WIKI half — the 146
  player-struct offsets against `ram.md` — was DEFERRED by the maintainer this
  session to item 1's session, whose lead `+0x1B3` sits in the same table; note
  the page carries NO per-move frame data, so it was never a second frame-data
  source. The original entry follows.** Two sources the maintainer will provide: a
  WEBPAGE, and an EXCEL of frame data for the VANILLA characters. What we
  have: frame data DERIVED for the three tenants only (`docs/project/tables/
  chars/<tenant>_anim.md` "Frame data (derived): startup / active /
  recovery", read off anim-node durations + attack records by the charmap,
  phase 2, 14z-120/121; move identities measured on native vs2 by
  `test_move_naming`), and NOTHING collected for vanilla characters; the
  derivation has never been checked against an independent source. Plan:
  (1) inputs — the URL and the `.xlsx`, kept OUTSIDE the tree (third-party
  work; we commit only our comparison and cite the source); (2) derive the
  same figures for the vanilla characters from vsavj's own 32-row bank
  (does `tools/charmap_gen.py` walk a vanilla character? if not, extend it —
  the bank is per-character by law) and compare per move: startup / active /
  recovery, damage, hit counts; (3) every mismatch is MEASURED in-emulator
  on vanilla (a replay + field_trace) — the emulator is the arbiter, not the
  sheet and not our derivation; (4) if the sources cover vs2, compare the
  tenants' derived figures the same way. Deliverable:
  `docs/project/tables/community_crosscheck.md` + a gate freezing the
  agreements and naming the measured disagreements. Cost: T3, one to two
  sessions. **INPUTS RECEIVED 2026-08-31 + THE RULE, maintainer's words:**
  "measurement is king, not a source that we don't know how it was measured;
  however, community information is precious: if it aligns perfectly or
  with a constant offset, then we know the measure is good; if we find an
  inconsistent pattern, then we must search whether the measurement is
  correctly done or not." So every column's deltas are classified EXACT /
  CONSTANT OFFSET (a convention difference — state it) / INCONSISTENT (a
  defect in somebody's measurement — re-measure OURS in-emulator first).
  The sheet: `../community/vsav-framedata.xlsx` — 15 sheets = the 15
  vanilla characters (FE AN AU BI BU DE GA JE LE LI MO QB SA VI ZA; ~37-68
  moves each), per move `startup / active / recovery / on hit / renda on
  hit / on block / renda on block / throw tech / red damage / white damage /
  gauge whiff / gauge block` (AN adds gauge hit / cancel / guard);
  multi-hit actives as text (`2(4)3,2`, `3{(3)3}x6`); NO vs2 characters, no
  Oboro / Dark Gallon. **Sheet names = the first two letters of the
  JAPANESE character name (maintainer-confirmed 2026-08-31), mapped to our
  ids:** BU Bulleta `0x00` · DE Demitri `0x01` · GA Gallon `0x02` · VI
  Victor `0x03` · ZA Zabel `0x04` · MO Morrigan `0x05` · AN Anakaris `0x06`
  · FE Felicia `0x07` · BI Bishamon `0x08` · AU Aulbath `0x09` · SA
  Sasquatch `0x0A` · QB Q-Bee `0x0C` · LE Lei-Lei `0x0D` · LI Lilith `0x0E`
  · JE Jedah `0x0F` (the two to not confuse: LE = Lei-Lei, LI = Lilith).
  The webpage:
  https://mizuumi.wiki/w/Vampire_Savior/Reverse_Engineering ("arguably the
  best source of deep information on Vampire Savior") — BLOCKED for any
  fetcher by a bot challenge (WebFetch 403; curl with a browser UA gets the
  challenge page) — **RESOLVED 2026-08-31: the maintainer saved it as a PDF**
  (`../community/Vampire Savior_Reverse Engineering - Mizuumi Wiki.pdf`,
  74 pages; text extracted with `pypdf` in a scratch venv — poppler is not
  installed — to `../community/mizuumi_reverse_engineering.txt`, 74 K
  chars, 421 address tokens). Both sources stay out of the tree.
  **FIRST-PASS INVENTORY of the wiki page (14z-124; an inventory, NOT an
  adoption — nothing in the atlas changes until measured):** sections =
  the CPS2 memory map, the IVT, RAM maps by base (`$FF8000` globals, `$FF8280`
  stage/camera, `$FF8400/$FF8800` the player struct — CPS2 AND the PS1
  `MIPS 0x8D8400` mirror), graphics/palettes/raster matrices, ROM function
  and per-character data/function tables, per-character move
  "Conditions" (pp. 25-63), data structures, palettes, backgrounds, HUD.
  Method not stated (credits "Thanks Jed"; disassembly-shaped comments);
  region unstated — but `0x275CE` / `0x28D50` / `0x2246E` sit exactly at our
  vsavj addresses. Their player struct: 146 offsets, 52 also named in our
  `ram.md`, 94 only theirs (candidates), ~50 only ours. CONVERGENCES with
  our measurements: `+0x110/+0x111/+0x176` the vsavj DF fields (they name
  `+0x17B` "Dark Force Flight" — Huitzil's form), `+0x189` DF timer
  reduction, `+0x3B4` "CPU Opponent Flag"; and the 14z-123 advancing guard
  field for field under VS's OWN NAME, **Tech Hit**: `0x275CE` "Tech-Hit
  Checks", `0x28D50` "Tech-Hit Chance Tables" (our RNG table), `+0x170`
  Tech Hit Input Counter, `+0x171` Tech Hit Active State (0x10 frames — the
  consumer we never traced), `+0x1AB` Tech-Hit Timer, `+0x1B0` Push-block
  Push-back Timer, `+0x126/+0x127` Mash to Escape. DIRECT LEAD for the DF
  backlog item: **`+0x1B3` "Dark Force Startup"** and `+0x1B5` "Dark Force
  type-2 (HP+HK)" (we had read `+0x1B5` as set by JUMPING — a disagreement),
  `+0x147` "Invincibility Timer" (ours: the multi-hit re-hit gate —
  compatible), `+0x143` Throw Invulnerability Timer; ROM `0x26FD2` DF
  Activate / `0x2706E` DF Deactivate bracket our activation body `0x027000`.
  DISAGREEMENTS to measure: `+0x161` "Oboro Fight Flag" vs our live-measured
  Sasquatch DF accumulator (`audit_df_accumulator`, 9 frozen lines — ours is
  a measurement, theirs a name; the byte may serve both); `0x2246E` "System
  Timer Reducers" vs our "class-0xFF block handler" (14z-123). Naming to
  adopt after measurement: "Tech Hit" beside "advancing guard". **BOTH
  RESOLVED 14z-126 (the opcode listing): `0x2246E` IS the System Timer
  Reducer (one `subq.b` per tick on `+0x147/+0x174/+0x143/+0x158/+0x1AB`);
  the block window is OPENED by the block-entry handler `0x2395A`-`0x23966`
  — 14z-123's write tap had named the decrementer, corrected in `ram.md`,
  engine_internals and `test_advancing_guard.sh`; and `+0x161` is a
  per-character DF WORK BYTE written by Sasquatch's (the measured
  accumulator), Bishamon's, Anakaris's and Aulbath's handlers — mizuumi's
  "Oboro Fight Flag" is Bishamon/Oboro's use of it: both names true. Four
  wiki rows adopted into `ram.md` with the mechanism measured or read
  (`+0x134`, `+0x145`, `+0x143`, `+0x1B3`); the other ~90 candidates stay
  unadopted [C].**

- **ZABEL j.LK PROXIMITY GUARD — A LEGACY-CONTENT PATCH, ITS OWN SESSION
  (maintainer, 2026-08-30, 14z-122). RULED as the SECOND of two future items;
  not started.** The maintainer's report, in substance: Zabel's j.LK does not
  trigger proximity guard properly — "afaik it does, but not all the time it
  should, and definitely unlike any normal of any character". The ask: a
  SURGICAL patch for BOTH vanilla vsav and the WIDE build that corrects this
  and nothing else — no side effects. What that implies for the session that
  takes it: (1) it is a deliberate change to LEGACY behaviour, so by
  definition outside the superset invariant's "untouched" set — it needs its
  own ratified expectation class and its own build flag (CLAUDE.md §1/§4; a
  stock `vsav` patch is a NEW track, not the stock twin); (2) [VSP-20]
  first — a hand-played MAME recording of the whiff BEFORE any theory;
  (3) [VSP-14] — archaeology on "proximity guard" across STATE_HISTORY and
  the engine docs before measuring; (4) measure vanilla's proximity-guard
  test against every other normal (the maintainer's own comparison class)
  so the fix is bounded by a measured difference, not an impression.
  Recommendation: a data-side fix on Zabel's j.LK record (the guard-range or
  a record flag) if the difference is in his data; a code-side change only if
  the engine special-cases the move. Nothing decided beyond "its own session".
- **THE LIVING-DOCUMENTATION EFFORT, and the option it creates (maintainer
  direction, 2026-08-24). STARTED 14z-135 (2026-09-06): scope
  `docs/project/living_docs_scope.md`; RULED at the plan stage the same day
  that it takes ALL THREE forms put to the maintainer — a rendered navigable
  site, routing enforcement in the markdown, fact tables with provenance —
  in the order L1 routing → L4 site → L2 fact census → L3 ROM re-derivation,
  AFTER the harness slices and the harness skill.** ~~Recorded as DIRECTION,
  not as a task — nothing is scheduled and MiSTer stays the current arc.~~ In their words: an important
  documentation effort is coming, "not replacing your logs, but creating a
  living documentation that can easily be referenced by you or me, doesn't go
  stale or lost in a statistically never read file." The SailorMoonS project's
  documentation AND WORK DISCIPLINE are the reference; formats, document types
  and visualisations are to be chosen as the best fit for THIS project rather
  than copied. Motivation: the emulator side is now essentially fully mapped.
  **The option it opens:** after the MiSTer core is finished, potentially
  "go back to the canvas, with all the documentation, and redo the project
  from the docs, because it might create a cleaner, more consistent extended
  codebase." Explicitly a possibility to preserve, not a commitment.
  **Two things worth holding on to when it is scheduled:**
  1. **Staleness is defeated by ENFORCEMENT, not by format.** What keeps the
     SMS docs alive is `tools/checkdocs.py` re-deriving documented addresses
     from the cartridge, `--check` modes on every generator, `health.sh` in
     CI, and the rule that no number reaches a doc without a run that produced
     it in that session ("an unquoted address is a claim nobody can falsify").
     The prose should be shaped so it CAN be checked. Being lost in an unread
     file is a SEPARATE problem with a separate fix — routing: "if you want to
     know X, read Y" tables at every entry point, and every synthesis document
     naming its journal twin and vice versa.
  2. **A rebuild here is unusually provable, and its feasibility is
     MEASURABLE TODAY.** The harness compares ROM BEHAVIOUR, not source
     structure, so a rebuilt artifact has a real acceptance test that already
     exists: bit-identical to vanilla on the legacy corpus, field-identical to
     the current build on tenant content, same replays, same frozen
     expectations. What decides it is not the docs but **how much of the build
     is DATA versus CODE** — the artifact encodes hundreds of measured facts
     (reconciliation rows, planted tripwires, pc-rel escapes, the ~70 re-point
     defaults, the op-count freezes), and a rebuild that does not carry them
     re-pays every debugging session that produced them. CLAUDE.md rule 5
     already requires behavioural values to live in documented tables rather
     than in code, so feasibility is essentially the degree to which rule 5
     has been honoured — which can be MEASURED rather than estimated.
     RECOMMENDATION when the effort is scheduled: make the first structural
     deliverable the EXTRACTION of measured facts from manifests/generators
     into reviewable tables with provenance. It makes the current codebase
     auditable whether or not the rebuild happens, and it is the precondition
     that turns the rebuild from a hope into an option.

## THE DEADNESS REGISTER (opened 14z-71, maintainer's standing instruction)

**[VSP-23]** Every claim of the form **"legacy never reaches this, so we may reuse
it"**. Each is measured by ABSENCE, which is the weakest kind of evidence
we accept, so each is listed here with its guard. **These are the FIRST
PLACES TO CHECK for any unexplained regression in vanilla assets, engine
behaviour or rendering** — before anything else is suspected.

| Reused resource | Claim | Guard | Fallback if wrong |
|---|---|---|---|
| ~~palette-seq ids 0x1E-0x21 (`0x39ACC0`)~~ **CLAIM FALSE, ROW WITHDRAWN 14z-79 (they are Bulleta's DF block)** | vanilla only ever requests 0x26/0x27 | `tests/audit_palette_seq_ids.sh` (10,504 sampled calls) | none — the palette path never transits work RAM, so the audit is the ONLY guard |
| effect-class row 16 (`0x080AEC`) | vanilla never dispatches class 16 | `tests/audit_effect_class_rows.sh` §1, 0 reads vs a 1760-hit control | none needed: the row was a stub (`rts`), so a wrong claim costs at most the old no-op |
| ~~drawer list-type 6 (`0x01B6AA`)~~ **CLAIM FALSE (measured 14z-89) — LEGACY LISTS DO REACH TYPE 6** | vanilla has no type-6 sprite lists | `audit_effect_class_rows.sh` §1/§4 + `tests/test_beam_list_type6.sh` | **THE FALLBACK HELD — this is what a safe-and-loud design buys.** 14z-89 measured the tripwire ARMED on legacy content on huitzil-m13: `21_don_mash` 387 times and `26_don_arcade_mash` 948 times, PC-attributed to inside the thunk body (0x0FD060). Rendering stayed correct throughout (the fallback runs vsav's own type-6 code, reproduced instruction-for-instruction), so nothing rendered wrong and no playtest ever saw it — exactly the outcome the register's "prefer designs where being wrong is safe and loud" rule was written for. WHY IT WAS MISSED: the deadness measurement was sound but its COVERAGE was four replays (`02/07/09/30`), and the gate has always run on that default set; the two replays that arm it are long mash/arcade rigs nobody pointed it at. COST TODAY: `$FF010C/$FF010D` is a live work-RAM counter vanilla does not keep, so both replays diverge permanently from the vanilla masked basis — they are `.pending` on huitzil-m13 pending the maintainer's ruling. ~~OPEN: does the fallback need to stop counting (make the tripwire diagnostic-only / move it out of work RAM), or is the counter acceptable? See "Decisions pending — 14z-89"~~ **ANSWERED 14z-91: the counter was REMOVED** — the `beam_list_type6` `RAM:$FF010C` counter deleted, which cleared all six `.pending` legacy replays (`HANDOFF.md` Build registry, the 14z-91 row (C)) |

**[VSP-22]** Rules for adding a row: the claim must be measured with a POSITIVE CONTROL
on the same instrument and leg (a blind instrument and a real zero look
identical — paid for three times in 14z-71); it must name its guard; and
it must say what happens if the claim is wrong. Prefer designs where being
wrong is *safe and loud* over designs that are merely well-measured.

## Open bugs

- **OPEN (cosmetic):** win QUOTE TEXT — **all THREE tenants still show their
  SHELL's quote** (corrected 2026-08-27 by the maintainer; this entry used to
  say "Huitzil's", which understated the scope). Root-caused, not built: the
  first-level table at the quote bank base ALIASES its variant half
  (`0x10->0x00`, `0x11->0x01`, `0x13->0x03`) — *corrected 14z-116: this entry
  said "consumer bias `lea -4(a0,d0.w)` -> reads index `0x60+id-1`", which is
  the 14z-73 reading of the PORTRAIT fetch and was retracted in
  `engine_internals.md` the same session; it is not the quote mechanism.*
  MEASURED 14z-116 (see the session entry and the win-quote entry in
  `DECISIONS_HISTORY.md`, moved there 14z-134): a
  data-only fix is impossible, the relocation perturbs legacy work RAM, and
  ~330 glyph TILES have to travel. NOTE the
  win-quote ART is already native and complete (14z-62e/62j, group C bank 5) —
  what remains is the TEXT. See the cosmetic backlog below.

### THE COSMETIC BACKLOG (parked, 2026-08-27 — the maintainer's own list)

Ruled a single later pass over "the purely cosmetic things that remain related
to the port", opened when #112 was accepted as cosmetic. Nothing here is
scheduled, and none of it is competitive-2P surface (see the standing
"cosmetic is optional" scope: cosmetic + single-player-only surfaces are
nice-to-have). Collected so the pass does not start from a blank page:

| item | status | what is known |
|---|---|---|
| **Win-quote TEXT for all three tenants** (each still shows its shell's quote) | **FORGONE FOR NOW (maintainer 14z-116); parked WITH A CONSTRAINT — if ever done, the CLEAN way only, vanilla untouched** | the first-level table aliases the variant half; a data-only fix is IMPOSSIBLE (zero free bytes at either hop, re-derived by `tools/scan_quote_window.py`), the bank relocation perturbs `RAM:$FFF230` on legacy win screens, and ~330 glyph tiles must travel. Art side already native (14z-62e/62j) |
| **Arcade ladder OPPONENT-ROULETTE TAG for a tenant opponent** (1P, tenant-plays-1P only — the CPU draws a tenant only on a tenant's ladder row) | measured 14z-123, not fixed | the tag shows the BASE character's name and mini-art (Phobos `0x10` → "BULLETA", a 4-bit-folded consumer, PC not attributed) drawn in pool row `PRG:0x3A3CA0 + id*32`'s own colours (a brown ramp for `0x10`; `0x13` is a grey ramp). The VS screen itself is correct (pixel-identical to the 2P path). Fix shape if ever wanted: author three pool rows (`0x3A3EA0/0x3A3EC0/0x3A3F00`, 32 bytes each, in a table vanilla never indexes past `0x0F` — legacy-invisible by construction) plus un-fold the tag's name/art consumer (its own measurement). Gate `tests/test_ladder_tenant_vs_palette.sh` |
| **Arcade ladder MAP NAMES and PICTURES** | not investigated | the map screen is the one that follows the win screen (a documented rig trap, STATE_HISTORY 14z-99); stage banners decode via `tools/decode_stage_banners.py`, venue byte `$FF8100` |
| **Character SELECT WHEEL polish** | not investigated | the wheel is functionally correct and emulator-identical; this is look-and-feel only. Layout facts in `docs/game/atlas/select_screen.md`, the 21-cell roster and its inbound edges |
| **#112 Press of Death black foot** (Donovan's EX foot super) | **ROOT-CAUSED 14z-126b; FIX RULED (C) DO-NOTHING (maintainer, 2026-09-02) WITH OPTION (B) EXPLICITLY KEPT OPEN for the future — see the three #112 entries in `DECISIONS_HISTORY.md` (moved 14z-134)**; DECIDED cosmetic, parked; **maintainer 2026-08-28: too risky for a small cosmetic gain** | whole draw path measured VANILLA. ~~why a tenant runs that vanilla sequence is unknown~~ **REFUTED 14z-126b: it does NOT run one** — at every instance on merged-m14 the drawing objects' `+0x1C` point into Donovan's PLACED region and no work-RAM field holds a vsavj record pointer (positive control fired 15/15); `0x28394E` is never stored anywhere (all 7 candidate sites disassembled to instruction-boundary noise); and all 9,755 tenant sprite pointers are relocated (now gated). WHAT REMAINS: the records' TILE CODES — the effect map's coverage, the builder's own "render garbled, never crash" note. The BLACK case does not reproduce on the current build (needs a rebuild from `freeze/merged-m9` or a fresh recording) |
| **MARIONETTE — a vs2 character, PARKED UNTIL FURTHER NOTICE (maintainer, 2026-08-28)** | not ported, not planned | **Assets live in VS2, not in VS.** She is not in Vampire Savior at all, so nothing in our romset is missing or broken by her absence. The maintainer's framing, and it is the right one: **Marionette and Shadow are both just MIRROR-MATCH MECHANISMS** — the shared machinery at `PRG:0x009BB2` copies the opponent's id and palette, so "playing as" either is playing the opponent's character. That makes porting her a low-value item: it adds a second route to a mirror match, not a character. **Not before everything else.** If it is ever revisited, note that vs2's arming counter is the SAME single `#$5` check as vsavj's (`PRG:0x01F8D6`), so whatever arms her in vs2 is a different mechanism and has not been located |

**THE ARCADE HIDDEN-CHARACTER ROSTER — CONFIRMED BY THE MAINTAINER
2026-08-28.** Exactly THREE exist in the arcade game: **Oboro Bishamon,
Dark Gallon and Shadow.** *(First stated as four including Marionette, then
corrected by the maintainer within the hour: **Marionette is a Vampire
Savior 2 character, not a Vampire Savior one**, and the "7 START presses"
code belongs to vs2. Recorded because the ROM agreed with the correction
before it arrived — see the Shadow row.)* *The alternate Lilith, Aulbath and
Victor are CONSOLE-PORT ONLY* — which independently confirms the 14z-116
table measurement (the only variant datasets in any of the three ROMs are
our three tenants plus two Oboros; there is no Lilith/Victor/Aulbath
alternate anywhere). Status of each on our build, all measured 14z-116:
- **Oboro `0x18`** — shipping, ours, gated (`test_oboro_select.sh`), field-confirmed 14z-105. **CAUTION for the maintainer's floated idea of removing the hold-START hook "since Oboro and Dark Gallon were already in VS" (2026-08-28): that is true of DARK GALLON and NOT of OBORO.** Measured 14z-116: the only immediate writes of a character id in vsavj are `0x02`, `0x04`, `0x0B` and `0x12` — **no vanilla path anywhere writes `0x18` to `$382`.** vsavj ships Oboro's DATA complete (record `0x0B3450`, own palette block, 20 distinct bank rows) but no player-facing select path, which is precisely why 14z-105 added one. Removing the hook would make Oboro UNREACHABLE again; Dark Gallon would survive untouched, since that path is vanilla's own.
- **Dark Gallon `0x12`** — vanilla's own path (Gallon + START + 2-3 punches *or* 2-3 kicks, `PRG:0x020B9C`); our Oboro hook displaces that block's first instruction and re-executes it, so it is preserved BY CONSTRUCTION. Statically certain, **never played** — the maintainer is field-testing it.
- **FIELD VERDICT ON M9 (maintainer, MiSTer, 2026-08-28): "everything seems
  right... the new character wheel already looks almost perfect on CRT,
  Shadow works as intended, Dark Gallon is properly selectable with hold
  start + 3 punches at the same time. All seems perfectly fine."** So the
  E2 wheel is CRT-confirmed, Shadow is confirmed working on silicon, and
  **DARK GALLON IS CONFIRMED PLAYABLE** — which also validates the 14z-116
  static decode of `PRG:0x020C18` (the trigger accepts `0x300`/`0x500`/
  `0x600`/`0x700`, i.e. two OR three punches; the board used three).
  **TWO THINGS HE COULD NOT TEST IN ~2 HOURS OF TRYING, AND BOTH ARE
  STRUCTURALLY IMPOSSIBLE — the time was spent on things that cannot
  happen. Measured, so nobody spends another two hours:**
  1. **A tenant from RANDOM SELECT.** Already measured this session: the
     "?" draw is a fixed 15-entry table (`PRG:0x020C88`) holding no
     variant-half id, bound `cmpi.b #$f`. It is not luck, it cannot occur.
  2. **SHADOW vs a tenant, in 1P arcade.** NEW measurement: scanning ladder
     table A (`PRG:0x00B268`, 36 rows x 8 groups, reachable indices 0-5 —
     the scan bound `$FF8138` is 6) for a tenant candidate returns **rows
     16, 17 and 19 ONLY — i.e. classes `0x10`/`0x11`/`0x13`, the tenants'
     own rows.** A tenant appears as a CPU opponent *only when the player is
     a tenant* (which is exactly the shape of the #99 field crash: Donovan
     1P -> CPU Phobos). **Shadow's own pool is rows 32-34** (`0x800 +
     $3BD*8`) **and contains no tenant in any group.** So Shadow can never
     draw one from the ladder, however long you play.
  **HOW TO TEST IT ON THE BOARD:** 2P VERSUS — P2 picks the tenant with the
  sticks, P1 does the Shadow code. That is exactly what the emulator rig
  does (`tests/replays/113_shadow_vs_tenant.rpl`), and it is the only route
  either implementation has to that matchup.
  **-> DONE, AND GREEN (maintainer, MiSTer, 2026-08-28): "Shadow works
  perfectly even with the VS2 tenants in 2P vs, so that's a win."** The
  board agrees with the emulator leg on the one case that mattered, so the
  Shadow-vs-tenant question is CLOSED on both implementations.
- **NO LEGACY CHARACTER EVER MEETS A TENANT IN 1P ARCADE — RULED NOT A
  PROBLEM (maintainer, 2026-08-28): "not a problem since we're way focused
  on 2p vs". CLOSED, no work planned.** Kept as a measured fact because it
  explains field observations rather than because it needs fixing.** Rows `0x00-0x0F`
  contain no reachable tenant candidate at all, so a 1P run as Morrigan (or
  anyone vanilla) can never be scheduled against Donovan, Phobos or Pyron.
  The port authored the tenants' OWN rows (what they fight) and never added
  them to anyone else's. This is the same family as the random-select item
  and arguably more noticeable in play — a player's whole arcade experience
  never shows the new characters unless they pick one. **Not built, not
  scoped, no recommendation without a ruling**, and it is a GAMEPLAY-FEEL
  change (who you fight, and the ladder is already a lottery), so it is the
  maintainer's call per CLAUDE.md 5.
- **TENANT CPU AI LOOKS "LACKLUSTER" — maintainer observation (2026-08-28),
  UNPROVEN, DEPRIORITISED.** Verbatim: *"when I do fight against any of the
  VS2 tenants it seems their AI is lackluster to say the least and I'm
  pretty sure that's a side effect of the port although I can't prove it...
  but once again, we're 2P vs focused."* Recorded rather than investigated,
  with the archaeology a future session would start from so it is not
  re-derived: the four per-class AI action-script tables
  (`PRG:0x0BF01A/09A/11A/19A`) are **16 classes THEN THE SAME 16 REPEATED**
  (Capcom's aliasing guard), which is what made CPU-Phobos play DEMITRI's
  AI and was the root cause of #99; 14z-111 fixed it by making each
  tenant's OWN vs2 AI script block a data root (option A, zero code). So
  the tenants do have their own scripts now — but whether those scripts are
  as *deep* as a legacy character's on this engine has never been measured,
  and "feels weaker" is not a measurement. **If it is ever picked up, the
  first question is whether the ported script blocks are COMPLETE** (a
  truncated block would present exactly like this), not whether the tables
  are aliased. CPU-side only — 2P versus never reads them ([VSE-75]).
- **SHADOW vs A TENANT — MEASURED AND GREEN (14z-116).** The maintainer's
  question ("the big problem is not selecting him, it's knowing whether the
  game breaks", INCLUDING "does Shadow take the SHELL character instead of
  the tenant") was answered by a RUN, not by disassembly. Rig:
  `tests/replays/113_shadow_vs_tenant.rpl`, gate `tests/test_shadow_tenant.sh`
  (emulator tier, ~6 min, two runs, must-fire control). **RESULT: Shadow
  takes the TENANT.** P1 armed the code (5 START presses on "?"), beat P2
  Donovan, and at the round end flipped `0x00 -> 0x13` with the loader
  installing **Donovan's own record `0x003FA9D0`** — not Victor's
  `0x0009769E`, the shell `0x13` aliases, which is exactly the quiet failure
  the gate is written to catch. HUD reads "Donovan", art is his, and the run
  is **guard-clean END 21120** across several further morphs.
  **TWO CORRECTIONS TO MY OWN EARLIER STATIC PASS, both from this run:**
  (1) `PRG:0x009BB2` is NOT match init — it is the ROUND/MATCH-END path
  (`$13A`/`$13C` are the winner/loser pointers), so **Shadow does not keep a
  pick, he takes the character he just beat, round by round**; (2) arming
  alone leaves you playing the roulette's pick rendering NORMALLY (measured:
  Bulleta, no silhouette), so what produces the black-silhouette
  presentation on this Japan set is still unestablished — it blocks nothing.
- **Shadow** — present and vanilla: exactly 5 START presses on the "?" cell then any attack button (`select_screen.md`), which matches the community code instruction for instruction. The mechanism copies the OPPONENT's id and palette **UNMASKED** at `PRG:0x009BB2`, and every table the copied id then indexes is 32 rows with our tenant rows populated, **so Shadow-copying a TENANT is structurally expected to work**. Never run — this is the `coverage_matrix` "morphing INTO a tenant" cell, and it now has a mechanism attached rather than an unknown.


## Integration notes — SMS docs (imported 2026-07-24)

Conventions live in CLAUDE.md §4/§5 now; taxonomy files exist as of this
session. Still to mine when relevant (park, don't re-derive):
- SMS `coltest.lua` pattern (scripted char-select navigation → saved match
  state) for generating the 18×18 matrix states in M4.
- `trace.lua`/`trace_plan.lua` config shape for the CPS-2 input logger.
