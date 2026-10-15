# SESSION RECORDS — STATE.md, the ticket rules and the session key, in full

The full text of three CLAUDE.md rules, moved here verbatim on 2026-10-15 (#282 item D, the maintainer: *"Rule +
pointer (Recommended)"*). CLAUDE.md keeps each rule's `**[VSP-N]**` anchor and its statement; this file holds its
reasons, history and steps. The close's steps are `docs/project/session_close.md`.

## [VSP-17] STATE.md, the session ritual and its records

*(Moved verbatim from CLAUDE.md 2026-10-15, #282 item D. Its anchor marker stays on CLAUDE.md's statement of the rule, so here the marker reads [VSP-17], unbolded.)*

- [VSP-17] Sessions begin by reading `STATE.md` (current milestone, open decisions,
  standing rulings) and end by updating it. STATE.md is the single source of
  truth for progress; do not rely on chat memory. **SPLIT 2026-08-20
  (maintainer-approved), amended 2026-09-14 and 2026-10-14 (#282: *"At most 2"*): STATE.md
  holds the latest session group — two while a sitting writes its own — and the standing sections; `STATE_HISTORY.md` holds every
  older session record VERBATIM, under THE LEDGER (one line per archived
  session) at its head.** The rollover procedure is a step of the session
  close, whose one copy is `docs/project/session_close.md` (#282 item C, 2026-10-15). "STATE 14z-XX" references
  resolve in STATE.md first, then STATE_HISTORY.md — section names are
  preserved in the archive, and archived entries are never rewritten
  (corrections to them are marked in place).
  **AN OPEN LIST HOLDS ONLY WHAT IS OPEN (maintainer-ruled 2026-09-14).**
  STATE.md's "Decisions pending" and NEXT_SESSION's START HERE never carry a
  closed item, however it is marked — struck through, DONE, FIXED or CLOSED
  alike. A ruled decision moves VERBATIM to `DECISIONS_HISTORY.md` in the
  commit that records the ruling, leaving a one-line statement of the rule
  under STATE.md's "Standing rulings" for as long as it constrains work; the
  line is deleted when it stops. Bugs, cosmetic items and evolutions are
  tickets, listed only in the ticket index ([VSP-182]).
  `tests/test_state_open_lists.sh` enforces this, together with STATE.md's
  size budget and session-group count.
  **THE CLOSE ENDS WITH A PUSH (maintainer-ruled 2026-09-10):** when every
  check of the close is green and nothing is pending, push `main` to GitHub
  as the ritual's last step; a red, a SKIP or an unresolved item leaves the
  commits local and the close says so. Pushing bbh follows the same rule
  under its standing authorisation.

## [VSP-182] Tickets have strict sources of truth

*(Moved verbatim from CLAUDE.md 2026-10-15, #282 item D. Its anchor marker stays on CLAUDE.md's statement of the rule, so here the marker reads [VSP-182], unbolded.)*

- [VSP-182] **TICKETS HAVE STRICT SOURCES OF TRUTH (maintainer-ruled
  2026-09-14).** Every bug, cosmetic item and evolution is a ticket, and each
  question about one has exactly one source of truth. **The list** — which
  tickets exist, their kind and status — is `docs/project/tickets.tsv` (its
  header is the spec of record; the page is generated). **The story** —
  report, discussion, rulings as given, resolution — is the ticket's GitHub
  issue whatever its kind, so a change of kind is a label edit, never a
  move. **The facts** it established live in the subject documents
  ([VSP-12]); what a session did lives in STATE ([VSP-17]). Live documents
  name a ticket by its issue number and never restate its status or
  content.
  **ENOUGH STAYS LOCAL.** Without GitHub, the tree must answer four questions
  about every ticket: what it was and how to reproduce it, what was decided,
  what was learned, and what went wrong. Rulings are decisions, so they are
  recorded locally whichever channel gave them. What was learned and what
  went wrong live in a live document — a subject doc, a gotchas bucket or a
  skill — never only in an archive. Only the conversation, and a third
  party's report text, may exist on GitHub alone.
  **DONE, AWAITING RELEASE (maintainer-ruled 2026-10-08, 14z-195):** when a
  ticket's implementation is complete but it stays open until a release
  ships it, its issue gets a comment saying so — the commit, the gate that
  holds it, and that it closes with the release that carries it — so an
  open ticket with work remaining is never confused with one waiting to ship.
  **CLOSING A TICKET**, in one commit: its facts go where they belong; the
  issue and the tree are checked against each other, the side that is behind
  is updated, a closing comment states the resolution, and the issue is
  closed; its index row records the status and the four answers; any STATE
  entry for it moves VERBATIM to `STATE_HISTORY.md` under the closing
  session's key. **Closed means nothing is left to do** — an option kept open
  becomes its own ticket. **A copy** of past content names its origin and
  date, and goes only into a source of truth or an archive.
  `tests/test_tickets.sh` enforces the form: every issue has a row whose
  state agrees with GitHub's, and each answer is a resolving link or an
  explicit `none`. Whether an answer is enough is judged at close.

## [VSP-162] The 14z-N session key

*(Moved verbatim from CLAUDE.md 2026-10-15, #282 item D. Its anchor marker stays on CLAUDE.md's statement of the rule, so here the marker reads [VSP-162], unbolded.)*

- [VSP-162] **THE `14z-N` SESSION KEY — a naming convention AND the
  archive's INDEX, which is why it is never re-based.** A tag names ONE
  SITTING (a working session, several per day at times — not a calendar day,
  not a milestone, not a build). **Three namespaces, never conflated:**
  sessions `14z-N`; milestones `M0`..`M12`; freeze marks `donovan-m18` /
  `merged-m14`. **Shape:** letter suffixes mark CONTINUATIONS, same-day or
  after a close (`14z-82c`, `14z-110b`, `14z-117b`, `14z-125b`, `14z-126b`);
  parenthetical numbers are PHASES within one sitting (`14z-107 (11)`,
  `14z-118 (14)`).
  **It is a LOOKUP KEY, and that is the load-bearing part.** "STATE 14z-XX"
  resolves in STATE.md, then STATE_HISTORY.md, then DECISIONS_HISTORY.md —
  section names are preserved verbatim across every rollover *precisely so
  the key keeps resolving*. Hundreds of pointers into it live in gate
  headers, annotated tag messages, `patch_notes.md`, gotcha datelines and
  THE LEDGER's lines. **So a tag is never renamed, renumbered or tidied**:
  renaming one silently breaks every citation, and a citation that cannot
  resolve cannot be corrected ([VSP-13]).
  **`14z-` IS A FOSSILISED PREFIX — READ IT AS ONE OPAQUE TOKEN. THE LIVE
  COUNTER IS `-N`.** We are NOT "in session 14" and never have been since
  2026-07-30: `14z-126` is the 126th session of the `14z-` series, nothing
  more. Session 14 itself was ONE sitting, 2026-07-28, the M2a freeze — for
  scale, the MiSTer arc did not open until `14z-106`, 2026-08-22, 104
  sessions later. Anyone reading the prefix as a live continuation of
  session 14 has been misled by its ETYMOLOGY, which is only this:
  **ORIGIN — RECONSTRUCTED FROM THE ARCHIVE 2026-09-01, not lost.** The name
  is a CHAIN OF EXHAUSTED COUNTERS, each continued by suffix rather than
  re-based: plain integers (`Session 3`, `4`, `5-6`, `7`, `9`, `13`) →
  `Session 14` continued through the alphabet (`14b`…`14x`, `14z`, with
  `14w-b`/`14w-c`/`14k-b` where a letter itself continued) → the letters
  exhausted at **`14z`**, so continuation moved to a NUMBER (`14z-2`,
  `14z-3`, … `14z-126`) → and letters resumed one level down (`14z-126b`).
  Each stage FOSSILISED the one before it instead of restarting, which is
  why the head of the name stopped carrying meaning. Dates (pickaxed from
  the archive): Session 14 2026-07-28, `14b` 2026-07-28, `14z` 2026-07-30,
  `14z-2` 2026-07-30, `14z-59` 2026-08-03. **They are also what show a
  "session" is a CONTEXT WINDOW rather than a day** — 25 letter sessions
  inside three days, ~8/day.
  **WHAT IS STILL NOT RECORDED, stated as unverified rather than theorised:**
  why session 14 alone began taking letter continuations, and whether the
  practice was inherited with the SMS working discipline. **THE SEARCH THAT
  BACKS THAT: THIS REPOSITORY ONLY** — the archive, every doc, and the git
  history to the first commit (2026-07-25). No commit or document defines
  the convention; it is only ever used. The answer may exist in the SMS
  material or predate the first commit, neither of which was searched.
