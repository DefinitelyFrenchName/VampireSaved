#!/usr/bin/env python3
"""checkskills.py — lock the two MiSTer skills to the docs they distil.

  python3 tools/checkskills.py            # check the tree, then self-test
  python3 tools/checkskills.py -v         # ...and list every ID and number
  python3 tools/checkskills.py --root DIR # check a copy of the tree (the gate's
                                          # must-fire controls use this)

WHY THIS EXISTS (14z-114). A skill is a distillation of the docs and loads
BEFORE the work, so a stale skill is a confidently wrong instruction. The
SMS project's `checkskills.py` ID-locked a skill to a second hand-written
human rendition; here the docs themselves are the human rendition, so each
rule is ANCHORED to the paragraph it distils and three things are asserted:

  1. ID-LOCK, both ways.  Every `- [MSC-N]` / `- [MSV-N]` DEFINITION in a
     skill has exactly ONE anchor `**[MSC-N]**` in the source docs, and every
     anchor has a definition. Deleting or rewriting an anchored paragraph
     breaks the lock; so does adding a rule without anchoring it. A plain
     `[MSC-N]` (no bold, not opening a bullet) is a cross-reference and is
     ignored on both sides.
  2. LIFTABILITY (mister_scope.md §1).  The level-1 skill is game-independent:
     "if it names vsav, a tenant, a ceiling of ours, a fingerprint or a build
     dir, it is level 2."  A fixed token list is grepped, case-insensitively.
  3. NUMBERS CITE THE LOG.  Every numeric literal a skill quotes (hex,
     comma-grouped integers, decimals, 4+-digit integers, $-addresses, hash
     fragments) must appear verbatim in a LOG file — never only in the
     synthesis `mister_core.md` (that document's own staleness rule).

The extractors are negative-controlled on synthetic content every run: a
family that has stopped matching passes every claim it no longer finds.
ROM-free, emulator-free, runs anywhere (ci_portable).
"""
import argparse
import re
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent

# --- the skills, one row per prefix ------------------------------------
# path, the docs its anchors may live in, the LOGS its numbers must appear
# in (never the synthesis alone), and the tokens its liftability level
# forbids (case-insensitive substring; empty = level 2, nothing forbidden).
GAME_TOKENS = ["vsav", "vampire", "donovan", "huitzil", "phobos", "pyron", "tenant",
               "roster", "demitri", "jedah", "victor", "bishamon", "anita", "oboro"]
BUILD_TOKENS = ["0xEE73", "0xFFDB", "0x8E57F0", "0x5FFF1E", "32007911",
                "build/", "merged", "m3b_"]
_MISTER_DOCS = ["docs/platform/mister.md", "docs/project/mister_core.md",
                "docs/project/mister_map.md", "docs/project/mister_fit.md",
                "docs/project/mister_field.md", "docs/project/cps2_wide.md",
                "docs/project/release_format.md", "docs/platform/gotchas.md",
                "docs/project/gotchas.md", "HANDOFF.md", "CLAUDE.md"]
_MISTER_LOGS = ["docs/platform/mister.md", "docs/platform/mister_history.md",  # the twin joins the LOG list (14z-123 G4)
                "docs/project/mister_map.md",
                "docs/project/mister_fit.md", "docs/project/mister_field.md",
                "docs/project/release_format.md", "docs/platform/gotchas.md",
                "docs/project/gotchas.md", "release/bitstreams/18269/BITSTREAM.txt",
                "HANDOFF_HISTORY.md"]
_PLATFORM_DOCS = ["docs/platform/gotchas.md", "docs/project/gotchas.md",
                  "docs/project/cps2_wide.md", "HANDOFF.md", "docs/game/atlas/ram.md"]
_PLATFORM_LOGS = ["docs/platform/gotchas.md", "docs/project/gotchas.md",
                  "docs/project/cps2_wide.md", "HANDOFF.md", "docs/checksums.txt",
                  "HANDOFF_HISTORY.md"]
_GAME_DOCS = ["docs/game/engine_internals.md", "docs/game/gotchas.md",
              "docs/game/atlas/README.md", "docs/game/atlas/ram.md",
              "docs/game/atlas/character_tables.md", "docs/game/atlas/id_space.md",
              "docs/game/atlas/select_screen.md", "docs/game/atlas/sprite_lists.md",
              "docs/game/atlas/venue_assets.md"]
# history twins join the LOG lists as they are created (14z-122/123): a log is a log.
_GAME_LOGS = _GAME_DOCS + ["docs/game/engine_internals_history.md"]
_PORT_DOCS = ["CLAUDE.md", "HANDOFF.md", "STATE.md", "docs/project/gotchas.md",
              "docs/game/gotchas.md", "docs/project/porting_code_regions.md",
              "docs/project/porting_sprite_lists.md", "docs/project/tenant_manifest.md",
              "docs/project/build_dir_triage.md", "docs/project/hardening_register.md",
              "docs/project/patch_index.md", "docs/project/cps2_wide.md",
              "docs/project/oracle_classes.md"]   # CLAUDE.md §4's spec of record (pass 2, 14z-124)
_PORT_LOGS = ["docs/project/gotchas.md", "docs/project/patch_notes.md",
              "docs/project/patch_index.md", "HANDOFF.md", "CLAUDE.md",
              "docs/project/oracle_classes.md",   # the ratified figures moved with the spec (14z-124)
              "STATE.md", "STATE_HISTORY.md",
              # history twins join the LOG lists as they are created
              # (14z-122, the documentation pass): a log is a log.
              "docs/project/build_dir_triage_history.md", "HANDOFF_HISTORY.md"]
SKILLS = {
    "VSP": dict(path=".claude/skills/vampire-saved-port/SKILL.md",
                docs=_PORT_DOCS, logs=_PORT_LOGS, forbid=[],
                # STATE.md rolls over; a VSP anchor may sit only in the two
                # sections that never roll (skills_scope.md §3).
                sections={"STATE.md": ["## STANDING PRINCIPLE", "## THE DEADNESS REGISTER"]}),
    "VSE": dict(path=".claude/skills/vampire-savior-engine/SKILL.md",
                docs=_GAME_DOCS, logs=_GAME_LOGS,   # decision 5: engine_internals counts as a log
                forbid=["tenant", "build/", "merged", "m3b_", "wide_ext", "gen_donovan",
                        "gen_huitzil", "gen_pyron", ".toml", "x101aca", "x088512", "32007911"]),
    "MSC": dict(path=".claude/skills/mister-cps2-wide-core/SKILL.md",
                docs=_MISTER_DOCS, logs=_MISTER_LOGS,
                forbid=GAME_TOKENS + BUILD_TOKENS),
    "MSV": dict(path=".claude/skills/mister-vampire-saved/SKILL.md",
                docs=_MISTER_DOCS, logs=_MISTER_LOGS, forbid=[]),
    "CPH": dict(path=".claude/skills/cps2-hardware/SKILL.md",
                docs=_PLATFORM_DOCS, logs=_PLATFORM_LOGS,
                forbid=GAME_TOKENS + BUILD_TOKENS + ["manifest/", ".toml", "setup_mame", "setup_fbneo"]),
    "CPE": dict(path=".claude/skills/cps2-emulation/SKILL.md",
                docs=_PLATFORM_DOCS, logs=_PLATFORM_LOGS,
                forbid=GAME_TOKENS + BUILD_TOKENS + ["manifest/", ".toml"]),
}
# Cross-references `[PFX-N]` (plain, not bold, not opening a bullet) must
# resolve to a DEFINED rule of that prefix. RH lives outside the repo.
XREF_PREFIXES = set(SKILLS)

ID = r"\[([A-Z]+-\d+)\]"
DEF_SKILL = re.compile(rf"^- {ID}", re.M)        # `- [MSC-3] ...`
ANCHOR_DOC = re.compile(rf"\*\*{ID}\*\*")         # `**[MSC-3]**` anywhere
NUM_PATTERNS = [
    re.compile(r"0x[0-9A-Fa-f]{3,}"),
    re.compile(r"\$[0-9A-Fa-f]{4,}"),
    re.compile(r"(?<![\d.])\d{1,3}(?:,\d{3})+(?!\d)"),
    re.compile(r"(?<![\d.])\d+\.\d+(?![\d.])"),
    re.compile(r"(?<![\d.,])\d{4,}(?![\d.])"),
    re.compile(r"(?<![0-9A-Za-z])[0-9a-f]{8,}(?![0-9A-Za-z])"),
]


def skill_defs(text):
    return DEF_SKILL.findall(text)


def doc_anchors(text):
    return ANCHOR_DOC.findall(text)


def numbers(text):
    found = set()
    for pat in NUM_PATTERNS:
        for m in pat.finditer(text):
            tok = m.group(0)
            if re.fullmatch(r"\d{4}", tok) and tok.startswith("20"):
                continue  # years
            if re.fullmatch(r"\d\.\d", tok):
                continue  # section numbers (1.3, 2.5)
            if re.fullmatch(r"[0-9a-f]{8,}", tok) and tok.isdigit():
                continue  # long decimal caught by the integer pattern
            found.add(tok)
    # a decimal run inside a hex/$ token is not a number of its own
    return {t for t in found
            if not (t.isdigit() and any(t != u and t in u for u in found))}


XREF = re.compile(r"(?<!\*)\[([A-Z]+-\d+)\](?!\*)")


def check(root, verbose=False):
    root = Path(root)
    fails = []
    cache = {}

    def read(rel):
        if rel not in cache:
            p = root / rel
            cache[rel] = p.read_text(encoding="utf-8") if p.exists() else None
        return cache[rel]

    # pass 1: every skill's definitions (for cross-reference resolution)
    defined = {}
    for prefix, cfg in SKILLS.items():
        text = read(cfg["path"])
        defined[prefix] = set(skill_defs(text)) if text else set()

    for prefix, cfg in SKILLS.items():
        text = read(cfg["path"])
        if text is None:
            fails.append(f"{prefix}: skill {cfg['path']} does not exist")
            continue
        if not re.match(r"^---\nname: [a-z0-9-]+\ndescription: .+\n---\n", text):
            fails.append(f"{prefix}: {cfg['path']} lacks the name/description frontmatter")
        defs = skill_defs(text)
        if verbose:
            print(f"  {prefix}: {len(defs)} rules defined in {cfg['path']}")
        if not defs:
            fails.append(f"{prefix}: the skill defines NO rules — has the syntax changed?")
        dupes = sorted({i for i in defs if defs.count(i) > 1})
        if dupes:
            fails.append(f"{prefix}: duplicate definition(s): {', '.join(dupes)}")
        foreign = sorted({i for i in defs if not i.startswith(prefix + "-")})
        if foreign:
            fails.append(f"{prefix}: DEFINES foreign-prefix rule(s) {', '.join(foreign)}")

        # 1. ID-lock against this skill's anchor docs
        anchors = {}
        for rel in cfg["docs"]:
            t = read(rel)
            if t is None:
                fails.append(f"{prefix}: anchor doc missing: {rel}")
                continue
            for i in doc_anchors(t):
                if i.startswith(prefix + "-"):
                    anchors.setdefault(i, []).append(rel)
            # anchors confined to named sections of a rolling file
            for hdr_list in [cfg.get("sections", {}).get(rel)] if cfg.get("sections", {}).get(rel) else []:
                spans = []
                for hdr in hdr_list:
                    s = t.find("\n" + hdr)
                    if s < 0:
                        fails.append(f"{prefix}: {rel} has no section '{hdr}'")
                        continue
                    e = t.find("\n## ", s + 1)
                    spans.append((s, len(t) if e < 0 else e))
                for m in ANCHOR_DOC.finditer(t):
                    i = m.group(1)
                    if i.startswith(prefix + "-") and not any(s <= m.start() < e for s, e in spans):
                        fails.append(f"{prefix}: {i} anchored in {rel} OUTSIDE the standing sections "
                                     f"({', '.join(hdr_list)}) — that file rolls over")
        key = lambda i: int(i.split("-")[1])
        only_skill = sorted(set(defs) - set(anchors), key=key)
        only_docs = sorted(set(anchors) - set(defs), key=key)
        if only_skill:
            fails.append(f"{prefix}: defined in the skill, ANCHORED NOWHERE: {', '.join(only_skill)}")
        if only_docs:
            fails.append(f"{prefix}: anchored in the docs, NOT DEFINED in the skill: {', '.join(only_docs)}")
        for i in sorted((i for i, locs in anchors.items() if len(locs) > 1), key=key):
            fails.append(f"{prefix}: {i} anchored in more than one place: {', '.join(anchors[i])}")

        # 2. liftability (the frontmatter names sibling skills; lint the body)
        body = text.split("\n---\n", 1)[-1]
        for tok in cfg["forbid"]:
            for n, line in enumerate(body.splitlines(), 1):
                if tok.lower() in line.lower():
                    fails.append(f"{prefix}: level-1 skill names '{tok}' at line {n} — that is level 2")
                    break

        # 3. numbers cite the log
        log_text = ""
        for rel in cfg["logs"]:
            t = read(rel)
            if t is None:
                fails.append(f"{prefix}: log missing: {rel}")
            else:
                log_text += "\n" + t
                # HISTORY FILES CARRY NO ANCHORS (14z-122, the documentation
                # rationalization pass): a `<name>_history.md` twin is a LOG
                # (numbers moved there still resolve) but an anchored
                # paragraph may never move there — the anchor migrates to the
                # surviving reference sentence, or the paragraph stays.
                # STATE_HISTORY/DECISIONS_HISTORY are session archives, not
                # twins, and are exempt (tools/doc_anchor_census.py walks
                # them as reviewed OUT-OF-LIST rows).
                if (re.search(r"_(history|HISTORY)\.md$", rel)
                        and rel not in ("STATE_HISTORY.md", "DECISIONS_HISTORY.md")):
                    for i in doc_anchors(t):
                        if i.startswith(prefix + "-"):
                            fails.append(f"{prefix}: {i} anchored in HISTORY file {rel} "
                                         "— history carries no anchors")
        missing = sorted(t for t in numbers(text) if t not in log_text)
        if verbose:
            print(f"  {prefix}: {len(numbers(text))} numeric tokens quoted")
        if missing:
            fails.append(f"{prefix}: number(s) quoted but in NO log: {', '.join(missing)}")

        # 4. cross-references resolve
        for ref in sorted(set(XREF.findall(body))):
            rp = ref.split("-")[0]
            if rp in XREF_PREFIXES and rp != prefix and ref not in defined.get(rp, set()):
                fails.append(f"{prefix}: cross-reference [{ref}] names a rule {rp} does not define")
    return fails


SYN_SKILL = ("---\nname: x\ndescription: y\n---\n"
             "- [XX-1] rule one, see [YY-9] and 0x600000 and 2609\n- [XX-2] rule two\n")
SYN_DOC = "text **[XX-1]** anchor one. Also **[XX-2]** anchor two. plain [XX-3] is a ref\n"
SYN_LOG = "the log says 0x600000 and 2609\n"


def selftests():
    bad = []
    if skill_defs(SYN_SKILL) != ["XX-1", "XX-2"]:
        bad.append("skill extractor no longer matches the definition syntax")
    if doc_anchors(SYN_DOC) != ["XX-1", "XX-2"]:
        bad.append("doc extractor no longer matches the anchor syntax (or counts a plain ref)")
    if "YY-9" in skill_defs(SYN_SKILL):
        bad.append("a cross-reference was read as a definition")
    probe = "see 0x600000, 2609, 66,265,152, 0.125, $FF8058, 46fc74af, 12 MB, 2026"
    if numbers(probe) != {"0x600000", "2609", "66,265,152", "0.125", "$FF8058", "46fc74af"}:
        bad.append(f"number extractor drifted: {numbers(probe)}")

    global SKILLS, XREF_PREFIXES
    saved = (SKILLS, XREF_PREFIXES)
    try:
        SKILLS = {"XX": dict(path="skill.md", docs=["doc.md"], logs=["log.md"], forbid=["vsav"])}
        XREF_PREFIXES = {"XX", "YY"}
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)

            def write(skill=SYN_SKILL, doc=SYN_DOC, log=SYN_LOG):
                (root / "skill.md").write_text(skill)
                (root / "doc.md").write_text(doc)
                (root / "log.md").write_text(log)

            write()
            # YY-9 is a cross-ref to a prefix with no skill: must not fail on its own
            SKILLS["YY"] = dict(path="yy.md", docs=["doc.md"], logs=["log.md"], forbid=[])
            (root / "yy.md").write_text("---\nname: y\ndescription: y\n---\n- [YY-9] nine\n")
            (root / "doc.md").write_text(SYN_DOC + "**[YY-9]** y anchor\n")
            if check(root):
                bad.append(f"a matched synthetic tree FAILS — the checks are wrong: {check(root)}")
            (root / "yy.md").write_text("---\nname: y\ndescription: y\n---\n- [YY-8] eight\n")
            (root / "doc.md").write_text(SYN_DOC + "**[YY-8]** y anchor\n")
            if not any("cross-reference [YY-9]" in f for f in check(root)):
                bad.append("a dangling cross-reference was not caught")
            del SKILLS["YY"]
            write(skill=SYN_SKILL + "- [XX-3] unanchored\n")
            if not any("ANCHORED NOWHERE" in f for f in check(root)):
                bad.append("an unanchored rule was not caught")
            write(doc=SYN_DOC + "**[XX-4]** orphan\n")
            if not any("NOT DEFINED" in f for f in check(root)):
                bad.append("an orphan anchor was not caught")
            write(doc=SYN_DOC + "again **[XX-1]**\n")
            if not any("more than one place" in f for f in check(root)):
                bad.append("a duplicate anchor was not caught")
            write(skill=SYN_SKILL + "- [XX-2] again\n")
            if not any("duplicate definition" in f for f in check(root)):
                bad.append("a duplicate definition was not caught")
            write(skill=SYN_SKILL + "- [ZZ-1] wrong tier\n")
            if not any("foreign-prefix" in f for f in check(root)):
                bad.append("a foreign-prefix definition was not caught")
            write(skill=SYN_SKILL.replace("rule two", "rule two about VSAV"))
            if not any("level-1 skill names" in f for f in check(root)):
                bad.append("a forbidden token in a level-1 skill was not caught")
            write(skill=SYN_SKILL.replace("rule two", "rule two quotes 0x123456"))
            if not any("in NO log" in f for f in check(root)):
                bad.append("a number missing from every log was not caught")
            SKILLS["XX"] = dict(path="skill.md", docs=["doc.md"],
                                logs=["log.md", "log_history.md"], forbid=["vsav"])
            write()
            (root / "log_history.md").write_text("archived. **[XX-2]** moved here\n")
            if not any("anchored in HISTORY file" in f for f in check(root)):
                bad.append("an anchor in a history-file log was not caught")
            SKILLS["XX"] = dict(path="skill.md", docs=["doc.md"], logs=["log.md"], forbid=["vsav"])
    finally:
        SKILLS, XREF_PREFIXES = saved
    return bad


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("-v", "--verbose", action="store_true")
    ap.add_argument("--root", default=str(REPO), help="tree to check (default: this repo)")
    ap.add_argument("--no-selftest", action="store_true")
    args = ap.parse_args()

    fails = check(args.root, args.verbose)
    if not args.no_selftest:
        fails += [f"SELF-TEST: {b}" for b in selftests()]
    if fails:
        for line in fails:
            print(f"  FAIL  {line}")
        print(f"\n{len(fails)} problem(s) between the skills and the docs")
        sys.exit(1)
    n = sum(len(skill_defs((Path(args.root) / c["path"]).read_text())) for c in SKILLS.values())
    print(f"ALL PASS ({n} rules across {len(SKILLS)} skills: every rule anchored once, "
          "every anchor defined, level 1 game-free, every number in a log)")


if __name__ == "__main__":
    main()
