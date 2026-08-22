#!/usr/bin/env python3
"""gen_donovan_patch.py — generate the donovan-m2 patch (a patch_prg.py op
list) from the extraction manifest, staged per the M2a bring-up ladder.

Stages (cumulative; each later stage includes all earlier ops):
  1  null relocation, zero Donovan bytes: Jedah's own player-path hitbox
     block copied into hole A (data raw inside the encrypted zone) with the
     pair repointed, plus two hand-authored jmp-back trampolines — one
     re-encrypted in hole A, one raw in hole B — behind two dispatch
     entries. Proves allocator/copy/repoint/encrypt with zero R1 ambiguity;
     Jedah must play identically.
  2  + Donovan passive data: hitbox + hitbox_proj blobs, per-char value
     rows (params/rec8/words/bytes/byte2d + oracle-classified gap values),
     4 hitbox-family repoints.
  3  + Donovan anim + sprite sub-table clusters (internal fixups), 4 anim
     table repoints.
  4  + Donovan code (engine refs resolved via reconciliation.toml — any
     unresolved/unverified ref FAILS with the full R1 report), 14 dispatch
     repoints.
  5  + aux pokes from donovan.toml (select screen / quotes / AI ...).

Every bank repoint pokes slot 0x0F AND the aliasing variant row 0x1F, after
asserting they are vanilla-equal. Every destination range is asserted to be
0xFF fill in vanilla vsavj before use. Output is deterministic.

Usage:
    python3 tools/gen_donovan_patch.py <extract_dir> <out_dir> \
        --vsavj $ROMDIR/vsavj.zip --stage N \
        [--port build/manifest/donovan.toml] \
        [--recon build/manifest/reconciliation.toml] \
        [--bank-map build/manifest/bank_map.toml]
"""

import argparse
import hashlib
import json
import struct
import sys
from pathlib import Path


# REFUSE TO RUN WITH ASSERTIONS DISABLED (14z-94, GitHub #79). This file's
# collision, band-bound and placement checks are `assert` statements, and
# `python -O` / PYTHONOPTIMIZE=1 removes them ENTIRELY — an invalid graphics
# placement would then exit 0, and the gate that is supposed to catch it would
# print PASS because the expected raise never happened. Converting each assert
# would fix today's checks and not tomorrow's; refusing the mode fixes the
# class. A safety check that can be switched off by an environment variable is
# not a safety check.
if not __debug__:
    raise SystemExit(
        f"{__file__}: refusing to run under python -O / PYTHONOPTIMIZE — its "
        f"safety checks are assertions and would be stripped (GitHub #79)")
sys.path.insert(0, str(Path(__file__).resolve().parent))
from gfx_tiles import cell_at, attr_block  # noqa: E402  (GitHub #47)
import cps2_decrypt as cps  # noqa: E402
from _minitoml import loads as toml_loads  # noqa: E402

VSAVJ_ORIGIN = 0x0BD0FA


def stage_regions(manifest_regions, stage):
    """Which regions each stage places (cumulative, deterministic order):
    2: hitbox family; 3: anim + sprite sub-table clusters; 4: code + the
    ported absent-support routines (x* extra regions)."""
    names = sorted(manifest_regions)
    want = []
    if stage >= 2:
        want += [n for n in names if n.startswith("hitbox")]
    if stage >= 3:
        want += [n for n in names if n == "anim" or n.startswith("aux")]
    if stage >= 4:
        want += [n for n in names if n == "code" or n.startswith("x")]
    return want


def _int(v):
    return v if isinstance(v, int) else int(v, 0)


def load_vsavj(zpath):
    words, keybytes, prgs, sha1s = cps.load_set(zpath)
    return bytes(cps.words_to_logical_bytes(words))


def tenant_context(t, port, profile=None, override=None):
    """Resolve ONE `[[tenant]]` row into the flat per-tenant dict.

    M3b slice A (14z-76): this is the unit the multi-tenant generator will
    build N of. It is a PURE function of (tenant row, base [port], profile,
    override) — it reads no module state and writes none, so a caller can
    loop it. Everything that makes a tenant a tenant (id resolution, the
    reserved/variant guards, mirror_variant, the gfx-bank override) lives
    here rather than in `main()`'s scope.

    The one semantic point worth restating: `mirror_variant` exists because a
    BASE-half slot's variant row aliases it in vanilla (slot 0x0F and its
    mirror 0x1F). A tenant that IS a variant id has no mirror, and one at
    0x13 must never touch 0x03 (Victor) — so the default is derived from the
    id rather than assumed true.
    """
    # PROFILE-GATED ID (M3a, 14z-61). De-substitution — moving the tenant off
    # a legacy character's slot onto its own variant id — is ROSTER work, and
    # the dual-track ruling (14z-59g) puts roster work on the WIDE track: the
    # stock build stays the frozen compatibility artifact. It has no choice in
    # the matter either, since a tenant at a variant id needs its tiles OUT of
    # the host character's gfx band, and only the extension has that room.
    # So one manifest still produces both tracks, with the id per profile.
    # "profile=id[,profile=id...]" — the manifest parser is minimal, so this
    # follows near_map's k=v string shape rather than a TOML sub-table.
    by_profile = {}
    for kv in str(t.get("id_by_profile", "")).split(","):
        if kv.strip():
            k, _, v = kv.partition("=")
            by_profile[k.strip()] = _int(v.strip())
    tid = by_profile.get(profile, _int(t["id"]))
    if override is not None:
        tid = override
    if tid >= 0x10 and not profile:
        raise SystemExit(
            f"gen_donovan_patch: tenant id {tid:#04x} is a VARIANT id, which "
            f"requires a build profile — its tiles cannot share the host "
            f"character's gfx band, and a stock build has nowhere else to put "
            f"them. Build with --profile, or declare a base-half id for the "
            f"stock track via [tenant.id_by_profile].")
    if tid in (0x12, 0x18):
        raise SystemExit(
            f"gen_donovan_patch: tenant id {tid:#04x} is RESERVED "
            f"(docs/game/atlas/id_space.md): 0x12 is the Gallon select variant "
            f"vanilla writes as an immediate, 0x18 is Oboro Bishamon.")
    p = dict(port.get("port", {}))
    p["src_set"] = t["src_set"]
    p["src_char"] = t["src_char"]
    p["dst_slot"] = tid
    p["mirror_variant"] = t.get("mirror_variant", tid < 0x10)
    # `recon_overlay` joined this list in 14z-80: it is per-tenant
    # configuration and the N-tenant loop asks the CONTEXT for it. While it
    # was missing, the loop read only `tenant[0]`'s overlay and every later
    # tenant silently built against the shared map alone.
    for k in ("alloc_wrap", "near_map", "hole_b_regions", "region_space",
              "gfx_bank", "name", "port_param32", "recon_overlay"):
        if k in t:
            p[k] = t[k]
    # A variant-id tenant's tiles live in the WIDE extension (that is WHY
    # a variant id requires a profile), so its gfx bank defaults to the
    # first group-C bank rather than the manifest's base-slot bank. The
    # base-slot bank (the host's band) stays whatever the manifest says.
    if tid >= 0x10:
        p["gfx_bank"] = _int(t.get("gfx_bank_variant", 4))
    return p


def manifest_owner(doc):
    """The tenant a manifest FILE belongs to (None for a legacy `[port]`)."""
    ten = doc.get("tenant") or []
    return ten[0].get("name") if ten else None


def stamp_owner(doc, owner):
    """Stamp per-FILE tenant ownership onto every manifest row (M3b slice C).

    A manifest file scopes to exactly ONE tenant. That is already how
    `recon_overlay` works — a whole override TOML scoped to one tenant's
    builds — so the LOADER is what knows a row's owner, and stamping it here
    is what lets the merge add tenants without editing a single manifest and
    keeps each vertical independently buildable (and re-freezable) as its own
    reproduction oracle.

    Rows then carry their owner into the gates, which is the difference
    between "is THE tenant a variant id?" (a global test against one scalar,
    meaningless once N tenants share a build) and "is THIS ROW's owning
    tenant a variant id?".

    `_owner` is generator-internal — leading underscore, like `_tenants` — and
    is stamped on the parsed document only. The manifest files on disk are
    untouched, so the tests and tools that parse them see nothing new. An
    explicit `_owner` already on a row wins, so an authored merged manifest
    can override the per-file default later without changing this function.
    """
    for v in doc.values():
        if isinstance(v, dict):
            v.setdefault("_owner", owner)
        elif isinstance(v, list):
            for row in v:
                if isinstance(row, dict):
                    row.setdefault("_owner", owner)
    return doc


def merge_manifests(docs, profile=None):
    """Merge N owner-stamped manifest documents into one (M3b slice F).

    With ONE document this is the identity, which is what makes the slice
    inert; the frozen fingerprints prove it.

    The policy, and why each half of it is what it is:

    * ARRAY-OF-TABLES rows CONCATENATE, in file order. Ownership already
      distinguishes them (slice C), so the gates and table addresses stay
      correct without the merge having to understand any section.
    * Rows that are byte-identical across files EXCEPT for `_owner` DEDUP to
      one row marked shared (`_owner=None`). This is the `[[space]]`,
      `[[obj_hook]]`, `[[select_wheel]]` and `*_bank_variant_id` shape: all
      three tenants declare them identically because they are properties of
      the ENGINE, not of a character. Emitting N copies of an engine patch
      is last-write-wins at best and a double-apply at worst.
    * SINGLETON tables (`[table_fix]`, `[init_shim]`, ...) cannot merge by
      concatenation — TOML cannot even express two. Identical ones dedup;
      DIFFERING ones are a COLLISION, and this function refuses rather than
      picking. `[table_fix]` is the known case: its `rows_hex` differs by
      exactly the tenant's own row, so the resolution is a per-row union,
      not a choice between two strings — and a silent pick would drop a
      tenant's OBJ bank word with nothing to catch it.

    Returns (merged_doc, collisions) — collisions is a list of human-readable
    strings. The caller decides whether a collision is fatal, so a tool can
    MEASURE the merge without being able to perform it.
    """
    if len(docs) == 1:
        return docs[0], []
    # Every tenant on a variant id => the base-track value is unreachable and
    # one class of span disagreement resolves. `tenant_ids_under` returns None
    # when it cannot tell, and `all()` over an empty list is True, so require
    # a non-empty list explicitly: an unknown must not read as "all variant".
    _ids = tenant_ids_under(docs, profile)
    all_variant = bool(_ids) and all(0x10 <= i <= 0x1F for i in _ids)
    merged, collisions = {}, []
    for doc in docs:
        for key, val in doc.items():
            if key not in merged:
                merged[key] = [dict(r) for r in val] if isinstance(val, list) \
                    else (dict(val) if isinstance(val, dict) else val)
                continue
            cur = merged[key]
            if isinstance(val, list) and isinstance(cur, list):
                for row in val:
                    twin = next((c for c in cur if _same_row(c, row)), None)
                    if twin is None:
                        cur.append(dict(row))
                    else:
                        # SHARED, and WHO shared it is kept (14z-80g). Dedup
                        # used to record only "nobody owns this", which is
                        # right for an engine row and wrong for a row whose
                        # ADDRESS is derived from the tenant's slot: two
                        # tenants declaring the same `slot_table` row are NOT
                        # writing the same word, they are writing their own
                        # entries, and the merged row has to remember which
                        # tenants they were. `row_here()` reads this.
                        twin.setdefault("_owners", [twin.get("_owner")])
                        twin["_owners"].append(row.get("_owner"))
                        twin["_owner"] = None      # shared engine row
            elif isinstance(val, dict) and isinstance(cur, dict):
                if _same_row(cur, val):
                    cur.setdefault("_owners", [cur.get("_owner")])
                    cur["_owners"].append(val.get("_owner"))
                    cur["_owner"] = None
                elif key in _SINGLETON_MERGE:
                    merged[key], why = _SINGLETON_MERGE[key](
                        cur, val, {"tenant_ids": tenant_row_ids(docs)})
                    collisions += why
                else:
                    collisions.append(
                        f"[{key}]: {val.get('_owner')} and {cur.get('_owner')} "
                        f"declare DIFFERENT singleton tables; keys differing: "
                        f"{sorted(_row_diff_keys(cur, val))}")
            elif cur != val:
                collisions.append(f"{key}: incompatible shapes across files")
    collisions += _span_collisions(merged, all_variant)
    return merged, collisions


# Which key(s) identify the BYTES a row writes, per section. Two rows that
# agree on these and disagree on their payload are patching the same span
# with different intent — invisible to the row-identity dedup above, because
# the rows are not identical, and invisible to the op-overlap assertion in
# patch_prg.py when the rows land in different regions' blobs.
_SPAN_KEYS = {
    "port_patch": ("region", "src_addr"),
    "aux_poke":   ("op", "addr"),
    "code_word":  ("addr",),
    "data_port":  ("dst",),
}


def _span_collisions(merged, all_variant=False):
    """Rows from different owners writing the SAME bytes differently.

    `all_variant` says every tenant takes a variant id under the build's
    profile, which makes the base-track (`new_hex`) value unreachable. That
    turns one class of disagreement from a blocker into something the merge
    can RESOLVE — see the branch below. It defaults False so a caller that
    does not know fails closed.

    This is the shape NEXT_SESSION flagged before the merge existed: the
    `x05c800` / `x088512` / `x06800c` / `x0692f6` OBJ-bank rows are declared
    by more than one tenant at the same `(region, src_addr)`, and differ only
    in whether they write the host band's word or the WIDE group-C one. They
    are properties of the SHARED SOURCE BYTES, not of a character, so the
    merge must resolve them to ONE row — it cannot apply both.
    """
    out = []
    _resolved = []          # duplicate rows the base-track branch collapsed
    for sect, keys in _SPAN_KEYS.items():
        rows = merged.get(sect)
        if not isinstance(rows, list):
            continue
        seen = {}
        for r in rows:
            if not all(k in r for k in keys):
                continue
            ident = tuple(f"{r[k]:#x}" if isinstance(r[k], int) else str(r[k])
                          for k in keys)
            # A slot_rows data_port (14z-99, #104) never writes its dst —
            # dst is a content ANCHOR and the written surface is the placed
            # blob + the named slot_ptr_table rows. Keying it by dst alone
            # made capture_kf_jedah "collide" with throw_victim_keyframes
            # (both anchor 0xB19F8 — Jedah's block — while writing disjoint
            # bytes). Extend the identity with the slot_rows string; two
            # slot_rows rows poking the SAME table row with different blobs
            # would dodge this scan, and are caught downstream by
            # patch_prg's op-overlap assertion (two ops on one word is a
            # named build error).
            if sect == "data_port" and str(r.get("slot_rows", "")).strip():
                ident = ident + (str(r["slot_rows"]),)
            prev = seen.get(ident)
            if prev is None:
                seen[ident] = r
            elif _row_diff_keys(prev, r) - {"note", "name", "stage"}:
                diff = sorted(_row_diff_keys(prev, r) - {"note", "name"})
                # A disagreement confined to the BASE-track value, where the
                # owners agree on the variant one, does not reach a merged
                # build: a tenant at a variant id requires the WIDE profile
                # (tenant_context's refusal), so a merged build is a WIDE
                # build and takes `new_hex_variant` at every one of these
                # rows. Say so rather than reporting a blocker that is not
                # one — six of the twelve measured collisions are this.
                vs = {prev.get("new_hex_variant"), r.get("new_hex_variant")}
                if diff == ["new_hex"] and len(vs) == 1 and None not in vs:
                    if all_variant:
                        # RESOLVED (14z-78d), not merely explained. Every
                        # tenant takes a variant id under this profile, so the
                        # base-track value is unreachable and the owners agree
                        # on the one that IS used. Collapse `new_hex` onto the
                        # agreed variant value: the row then writes the same
                        # bytes down either path, so a future reader that
                        # takes the base track cannot silently get the host
                        # band's word. Marked shared — it is a property of the
                        # source bytes, not of a character.
                        prev["new_hex"] = prev["new_hex_variant"]
                        r["new_hex"] = r["new_hex_variant"]
                        prev["_owner"] = None
                        _resolved.append(r)
                        continue
                    out.append(
                        f"[[{sect}]] {'/'.join(ident)}: {_who(prev)} and "
                        f"{_who(r)} differ on new_hex ONLY, and agree on "
                        f"new_hex_variant={vs.pop()} — BASE-TRACK ONLY, and it "
                        f"would dissolve on a WIDE build, but not every tenant "
                        f"takes a variant id here, so the base value IS "
                        f"reachable and this is a real disagreement")
                else:
                    out.append(
                        f"[[{sect}]] {'/'.join(ident)}: {_who(prev)} and "
                        f"{_who(r)} write the SAME bytes differently ({diff})")
    # Drop the collapsed duplicates. Done after the scan so the loop above is
    # not mutating the list it walks — and by IDENTITY, because two rows that
    # now compare equal are exactly what this is deduping.
    for sect in _SPAN_KEYS:
        rows = merged.get(sect)
        if isinstance(rows, list) and _resolved:
            merged[sect] = [x for x in rows
                            if not any(x is y for y in _resolved)]
    return out


def _who(row):
    """A row's owner for a message; deduped engine rows report as shared."""
    return row.get("_owner") or "shared"


def tenant_row_ids(docs):
    """Every id a tenant of these documents could occupy (M3b slice H).

    Both the plain `id` and every `id_by_profile` value, because the merge
    runs before the profile picks between them. Used to decide whether a
    difference sits on a row some tenant OWNS — and will therefore be
    overwritten — or on a vanilla row, where a difference is a real
    disagreement.
    """
    ids = set()
    for doc in docs:
        for t in doc.get("tenant") or []:
            if "id" in t:
                ids.add(_int(t["id"]))
            for kv in str(t.get("id_by_profile", "")).split(","):
                if kv.strip():
                    ids.add(_int(kv.partition("=")[2].strip()))
    return ids


def tenant_ids_under(docs, profile):
    """The id each tenant ACTUALLY takes under `profile` (M3b, 14z-78d).

    `tenant_row_ids` deliberately returns every id a tenant COULD occupy,
    which is the right question for "will some tenant overwrite this row".
    It is the wrong question for "is the base-track value reachable": it
    includes Donovan's base 0x0F, so it can never answer yes.

    Same selection `tenant_context` makes, and it has to be a separate
    function because the merge runs BEFORE `normalise_tenants` resolves ids.
    Returns None if any tenant's id cannot be determined, so callers fail
    closed rather than assuming the variant track.
    """
    ids = []
    for doc in docs:
        for t in doc.get("tenant") or []:
            pick = None
            for kv in str(t.get("id_by_profile", "")).split(","):
                k, _, v = kv.partition("=")
                if k.strip() and k.strip() == (profile or "") and v.strip():
                    pick = _int(v.strip())
            if pick is None and "id" in t:
                pick = _int(t["id"])
            if pick is None:
                return None
            ids.append(pick)
    return ids


def merge_init_shim(a, b, ctx=None):
    """Merge two `[init_shim]` declarations (M3b slice G, MAINTAINER-RATIFIED
    2026-08-10). Returns (merged, collisions).

    F2 FIXED (14z-82; the gap was MEASURED 14z-81): on a multi-tenant build
    the emitter no longer plants the shim on iteration 0 — every DECLARING
    tenant's dispatch row is collected during its own iteration and ONE
    merged shim is assembled at engine_here (the site_thunk
    assemble-after-the-loop shape, 14z-80h), with flavor_chain_multi giving
    each block its OWNER's handler exit and a tripwire fall-through.
    Asserted post-fix by tests/audit_merged_legacy.sh section 0
    (HENT == SHIM, PENT != SHIM). Single-tenant builds keep the historical
    iteration-0 emission byte-for-byte.

    The shim is emitted ONCE per build at ONE site, so a merged build has one
    seeder and one flavor writer. The three parts resolve differently:

    * MACHINERY (`dispatch`, `seed_entry`, `latch_disp`, `flavor_disp`,
      `flavor_hold_flag`, `objram_clear`) must AGREE. Disagreement is a real
      collision — there is one hook and it cannot be two things.
    * `latch_mode = "phase"` wins if ANY tenant declares it. It is not a
      preference: Phobos NEEDS the gate (without it his ecosystem drains pool
      0 and the round-2 char re-init re-runs the seeder over LIVE pools —
      14z-65 measured the f4890 wipe, orphaned queues, and a freed slot
      dispatched into palette space), and the seeder is shared, so a build
      containing him carries the gate for everyone.
    * FLAVOR (`flavor_default` / `flavor_held`) is PER TENANT and stays so:
      D1 (VS2 default) means 0x01 for Donovan and 0x00 for Phobos, because
      the engine branch each character tests differs (14z-66 measured it
      against native). They collect into `_flavor_by_owner`, which the
      emitter turns into an id-dispatched write.

    A tenant that declares NO flavor gets NO write — so Pyron, who declares no
    shim at all, keeps a `+0x3C2` the engine never touches for him. That is
    the ratified conservative half, and it is by construction rather than by
    a check that could be forgotten.
    """
    MACHINERY = ("dispatch", "seed_entry", "latch_disp", "flavor_disp",
                 "flavor_hold_flag", "objram_clear")
    why = []
    for k in MACHINERY:
        if a.get(k) != b.get(k):
            why.append(f"[init_shim]: {_who(a)} and {_who(b)} disagree on "
                       f"'{k}' ({a.get(k)!r} vs {b.get(k)!r}) — the shim is "
                       f"ONE hook and cannot be two things")
    out = dict(a)
    out["_owner"] = None
    if "phase" in (a.get("latch_mode"), b.get("latch_mode")):
        out["latch_mode"] = "phase"
    flav = dict(a.get("_flavor_by_owner") or _flavor_of(a))
    flav.update(b.get("_flavor_by_owner") or _flavor_of(b))
    out["_flavor_by_owner"] = flav
    out.pop("flavor_default", None)
    out.pop("flavor_held", None)
    return out, why


def _flavor_of(shim):
    """`{owner: (default, held)}` for one declaration; {} if it declares none."""
    if "flavor_default" not in shim:
        return {}
    return {shim.get("_owner"): (_int(shim["flavor_default"]),
                                 _int(shim.get("flavor_held", 0)))}


def merge_table_fix(a, b, ctx=None):
    """Merge two `[table_fix]` declarations (M3b slice H). -> (merged, why).

    `rows_hex` is the VANILLA vsavj OBJ bank table, and the generator writes
    each tenant's own row over it from that tenant's declared `gfx_bank`. So
    the three manifests differ only where a tenant baked its own row into the
    baseline as well — positions the generator overwrites regardless.

    That makes the union safe, but ONLY at those positions: a difference
    anywhere else means the two files disagree about a VANILLA row, which no
    later write would correct. Those stay collisions.

    The word index of a differing position is the character ID whose row it
    is, which is what lets this be checked rather than assumed.
    """
    why = []
    for k in ("region", "pad_len", "table_off", "stage"):
        if a.get(k) != b.get(k):
            why.append(f"[table_fix]: {_who(a)} and {_who(b)} disagree on "
                       f"'{k}' ({a.get(k)!r} vs {b.get(k)!r})")
    ra, rb = a.get("rows_hex", ""), b.get("rows_hex", "")
    if len(ra) != len(rb):
        why.append(f"[table_fix]: {_who(a)} and {_who(b)} declare tables of "
                   f"different length ({len(ra) // 4} vs {len(rb) // 4} rows)")
        return dict(a, _owner=None), why
    owned = (ctx or {}).get("tenant_ids") or set()
    for i in range(0, len(ra), 4):                    # one word = one row
        if ra[i:i + 4] != rb[i:i + 4] and (i // 4) not in owned:
            why.append(
                f"[table_fix]: {_who(a)} and {_who(b)} disagree on bank-table "
                f"row {i // 4:#04x} ({ra[i:i+4]} vs {rb[i:i+4]}) — the "
                f"generator only overwrites a row a TENANT owns, so this one "
                f"would ship whichever file happened to win")
    out = dict(a)
    out["_owner"] = None
    out["note"] = "merged vanilla bank table; tenant rows written per tenant"
    return out, why


_SINGLETON_MERGE = {"init_shim": merge_init_shim, "table_fix": merge_table_fix}


# ── 14z-81b: multi-owner obj_hook dispatch ───────────────────────────────────
# A type resolved by MORE THAN ONE tenant's view cannot dispatch through one
# table entry: the copies are internally tenant-reconciled (per-tenant anim
# literals; cross-tenant pointers are planted tripwires), so tenant B running
# tenant A's copy consumes A's tripwire addresses as DATA — the merged
# Huitzil vec3 crash (STATE 14z-81b). Such an entry points at a generated
# owner-id dispatch instead. The OWNER-READ per (site, type) is MEASURED,
# never assumed (tests/audit_objhook_owner_census.sh + the 14z-81b tick
# trace, which is where each shape below comes from):
#   d30 — the object's +0x30 word IS the owning player struct (type 117:
#         measured P1 across 2,752 dispatches)
#   h30 — +0x30 is the CREATOR OBJECT; ITS +0x30 is the player (type 119)
#   d32 — the player lives at +0x32 (type 115: its own handler's first
#         instruction is `movea.w ($32,A6),A4`, and its +0x30 reads ZERO at
#         dispatch time — the measured reason d30 cannot serve it)
# WITHDRAWN 14z-81c, THE SAME DAY IT SHIPPED — the map below is EMPTY on
# purpose. The stub design was implemented, measured green for Huitzil
# (both former crashers guard-clean), and then TWO failure modes of
# dispatch-time owner reads were measured in the same battery:
#   1. STALE/RECYCLED PARENT CHAINS — donovan/12_vs_cpu, f2886: a type-119
#      object's creator hop walked to P2 through a recycled slot and the
#      stub tripwired an object that first-wins had served correctly.
#   2. TRANSIENT IDS AT SPAWN INSTANTS — (0x382,P2) legitimately holds the
#      CPU's REAL pick (0x06) on vs-CPU rigs, and +0x30/+0x32/type bytes
#      are re-written WITHIN the spawn frame (the type-115 census).
# Two counterexamples from six replays means the failure space is not
# enumerated; a mis-dispatch is SILENT-WRONG, which is worse than the
# known loud crash. The robust design is spawn-time tenant tagging (each
# tenant's own copy stamps its spawns — no runtime owner read at all);
# design + censuses in STATE 14z-81b/c. The measured rows, kept for that
# session (they are real measurements of the healthy single-tenant paths):
#   (0x05E542, 115): "d32"   (0x05E542, 117): "d30"   (0x05E542, 119): "h30"
OBJ_HOOK_OWNER_READ = {}


# ── 14z-85: SPAWN-TIME OWNER TAG for the 0x54470 family (59-75) ─────────────
# The robust design the withdrawal note above names, ruled OPTION (a) by the
# maintainer (2026-08-13). Every frozen 59-75 stamp site is detoured through
# a thunk that ALSO writes the stamping tenant's id into the object's tag
# byte — a fact baked at BUILD time, read at dispatch by obj_hook entries
# 64-75 (owner_dispatch_stub shape "tag" below). The tag byte is MEASURED
# free on the family's OWN pool ($FF9400, 0x100-stride slots, walker
# 0x54458 — NOT the $FFB800/0x80 pool of the 0x5E542 family, which is what
# the first 14z-84 census measured by mistake): 804 live-slot observations,
# zero writes to +0x7F across 19,357 tapped pool writes, three legs incl.
# live family content (types 0x42/0x45) — 14z-85 census, suite-captured in
# tests/audit_pool_free_byte.sh. Zero/unclaimed tags fall through every
# compare into the tripwire: an untagged family object is a stamp site the
# tag emission missed, loud by design. Nothing clears +0x7F (zero writers
# measured), so stale tags in reused slots are unread — stubs run only for
# family types, and every family spawn re-tags.
OWNER_TAG_SITE = 0x54470
OWNER_TAG_TYPES = range(59, 76)       # tag emission: the whole family
# owner stubs (EXTENDED 14z-85c, maintainer-ruled): originally 64-75 (the
# multi-resolver entries). Now the whole family — a SINGLE-resolver entry
# whose type is stamped by a NON-resolver tenant (59/61/62/63: donovan's
# copies, but H and P carry stamp sites in co-ported code — dead paths
# today, solo builds tripwire them and playtest green) also gets a stub,
# so a future live spawn tripwires under its OWN tag instead of silently
# running donovan's copy. Types with no foreign stampers (60: no stamp
# sites at all) keep the direct pointer.
OWNER_TAG_STUB_TYPES = range(59, 76)
OWNER_TAG_OFF = 0x7F                  # slot offset, measured free (14z-85)


def owner_dispatch_stub(shape, tenants, tripwire):
    """68k bytes for one MULTI-OWNER obj_hook table entry.

    `tenants` = [(char_id, handler_addr)] in declaration order; `tripwire` =
    the planted-ILLEGAL address for every path that cannot NAME its owner
    (walk dead-ends, and a player id no tenant claims).

    Shape "tag" (14z-85) performs NO runtime owner read at all — it compares
    the object's spawn-time tag byte (+OWNER_TAG_OFF, written by the stamping
    tenant's own detoured stamp site) against each tenant id; a zero or
    unclaimed tag falls through every compare into the tripwire.

    Entry contract, MEASURED from the vanilla walker 0x5E52A-54 (14z-81b):
    A6 = object, D0 = 0, A1/D1 are not read by the walker or defined for
    handlers (clobber-safe, no saves needed — so no stack writes, no ghost
    bytes). Every exit re-establishes the vanilla handler entry state
    exactly: A0 = the handler's own address, D0 = 0, CCR = moveq's Z
    (movea does not touch CCR; `jmp (a0)` enters the handler as the vanilla
    `jsr (A0)` would have).

    Player compares use the SIGN-EXTENDED forms ($FFFF8400/$FFFF8800):
    the owner words are loaded with `movea.w`, unlike the init shim's
    absolute `cmpa.l #$FF8400,A6` — both measured in live registers.
    """
    out = bytearray()
    fix = []                       # (offset of displacement byte, label)
    labels = {}

    def _beq(lbl):
        out.extend(b"\x67\x00")
        fix.append((len(out) - 1, lbl))

    def _bne(lbl):
        out.extend(b"\x66\x00")
        fix.append((len(out) - 1, lbl))

    CMP_P1 = bytes.fromhex("b3fcffff8400")     # cmpa.l #$ffff8400,a1
    CMP_P2 = bytes.fromhex("b3fcffff8800")
    if shape == "tag":
        # 14z-85: dispatch on the SPAWN-TIME tag — no owner read, no player
        # hop. A6 = object (walker contract); the compares touch no register,
        # and the exits below re-establish the vanilla entry state exactly.
        for i, (cid, _h) in enumerate(tenants):
            out += bytes.fromhex("0c2e")       # cmpi.b #id,(OWNER_TAG_OFF,a6)
            out += bytes([0x00, cid & 0xFF])
            out += OWNER_TAG_OFF.to_bytes(2, "big")
            _beq("t%d" % i)
        # zero tag (missed stamp site) or unclaimed tag: LOUD by design
        out += b"\x4e\xf9" + tripwire.to_bytes(4, "big")   # jmp tripwire
    else:
        if shape == "d30":
            out += bytes.fromhex("326e0030")       # movea.w (0x30,a6),a1
        elif shape == "d32":
            out += bytes.fromhex("326e0032")       # movea.w (0x32,a6),a1
        elif shape == "h30":
            out += bytes.fromhex("326e0030")       # movea.w (0x30,a6),a1
            out += bytes.fromhex("2209")           # move.l a1,d1
            out += bytes.fromhex("08010000")       # btst #0,d1
            _bne("tw")                             # odd word: not a pointer
            out += bytes.fromhex("b2fc0000")       # cmpa.w #0,a1
            _beq("tw")                             # unlinked: cannot hop
            out += bytes.fromhex("32690030")       # movea.w (0x30,a1),a1
        else:
            raise ValueError(f"unknown owner-read shape {shape!r}")
        out += CMP_P1
        _beq("got")
        out += CMP_P2
        _beq("got")
        labels["tw"] = len(out)
        out += b"\x4e\xf9" + tripwire.to_bytes(4, "big")   # jmp tripwire
        labels["got"] = len(out)
        for i, (cid, _h) in enumerate(tenants):
            out += bytes.fromhex("0c29")           # cmpi.b #id,(0x382,a1)
            out += bytes([0x00, cid & 0xFF])
            out += bytes.fromhex("0382")
            _beq("t%d" % i)
        out += b"\x4e\xf9" + tripwire.to_bytes(4, "big")   # player, unclaimed id
    for i, (_cid, h) in enumerate(tenants):
        labels["t%d" % i] = len(out)
        out += bytes.fromhex("7000")                   # moveq #0,d0
        out += b"\x20\x7c" + h.to_bytes(4, "big")      # movea.l #handler,a0
        out += bytes.fromhex("4ed0")                   # jmp (a0)
    for off, lbl in fix:
        disp = labels[lbl] - (off + 1)                 # base = opcode + 2
        assert 0 < disp < 0x80, (lbl, disp)
        out[off] = disp
    return bytes(out)


def load_type_stamps(path):
    """Parse the FROZEN type-stamp inventory (build/manifest/type_stamps.toml,
    14z-82) — the minimal TOML subset the file uses (rows of `k = v`).

    The inventory is produced by tools/audit_type_stamps.py, HUMAN-REVIEWED,
    and gated by tests/test_type_stamp_census.sh; this loader trusts its
    shape and fails loudly on anything it does not recognise, because a
    half-read inventory silently narrows the renumber worklist — the exact
    census-gap class the dynamic audit exists to prevent."""
    rows = []
    cur = None
    for ln in Path(path).read_text().splitlines():
        s = ln.strip()
        if s.startswith("[["):
            cur = {"_kind": s.strip("[]")}
            rows.append(cur)
        elif cur is not None and "=" in s and not s.startswith("#"):
            k, _, v = s.partition("=")
            cur[k.strip()] = v.split("#")[0].strip().strip('"')
    return rows


# the per-form byte layout of a stamp site: (verified span length, offset of
# the TYPE byte inside it). stamp_l_*: op(2) + $01xxTTss(4) -> TT at +4;
# stamp_b_d16: op(2) + imm word 00TT(2) + d16(2) -> TT at +3 (d16==2 rows
# only — a d16==3 row writes the owner/substate byte, never the type).
_STAMP_FORMS = {
    "stamp_l_ind": (6, 4), "stamp_l_post": (6, 4), "stamp_l_pre": (6, 4),
    "stamp_l_d16": (8, 4), "stamp_b_d16": (6, 3),
}


def flavor_write(default, held, flav_d, hold_flag, mid=b""):
    """The VS2/VH2 flavor write for ONE tenant: 40 bytes (+ `mid`), CCR-only.

    `move.b #default,(flavor,A6)`, then the per-player Start bitmask test —
    holding YOUR Start through match load selects the other game's flavor
    (`move.b #held`). `mid` is the objram_clear marker, which sits between the
    default write and the P1/P2 test in the single-tenant layout and must stay
    there byte-for-byte.
    """
    return (bytes([0x1D, 0x7C, 0x00, default])                 # move.b #def,
            + flav_d.to_bytes(2, "big")                        #   (flavor,A6)
            + mid
            + bytes([0xBD, 0xFC, 0x00, 0xFF, 0x84, 0x00])      # cmpa.l #$FF8400,A6
            + bytes([0x66, 0x0A])                              # bne.s p2bit
            + bytes([0x08, 0x39, 0x00, 0x00])                  # btst #0,
            + hold_flag.to_bytes(4, "big")                     #   (flag).l
            + bytes([0x60, 0x08])                              # bra.s join
            + bytes([0x08, 0x39, 0x00, 0x01])                  # p2bit: btst #1,
            + hold_flag.to_bytes(4, "big")                     #   (flag).l
            + bytes([0x67, 0x06])                              # join: beq.s out
            + bytes([0x1D, 0x7C, 0x00, held])                  # move.b #held,
            + flav_d.to_bytes(2, "big"))                       #   (flavor,A6)


def flavor_tail(flav_map, flav_d, hold_flag, newt, objclr, tenants, fail):
    """The shim's flavor tail: one write, or an id-DISPATCHED chain.

    ONE declaring tenant -> exactly the bytes the single-tenant shim has
    always emitted, so the frozen references cannot move. This is the whole
    reason the two cases are not unified.

    MORE THAN ONE -> a chain of 54-byte blocks, one per declaring tenant:

        cmpi.b #id,(0x382,A6)   ; this player's character id
        bne.s   <next block>    ; +46, uniform — no branch-distance limit
        <40-byte flavor write>
        jmp     <handler>       ; each block exits directly, so the chain
                                ; needs no long backward branch at any N

    A tenant with NO entry matches nothing and FALLS THROUGH to the trailing
    `jmp`, so nothing is written for it. That is how Pyron stays untouched
    (maintainer-ratified 14z-77) — by construction, not by a check.

    UNVERIFIED ASSUMPTION, and it is load-bearing for N>1: that `(0x382,A6)`
    already holds the character id when this shim runs at char-init. It is
    strongly implied — the dispatch this shim is hosted on is itself indexed
    by the id, and `+0x382` is the id field for both player structs
    (docs/game/atlas/ram.md) — but it has NOT been measured at this point in
    the frame. The N>1 path is unreachable until the loop lands, so nothing
    ships on it yet. MEASURE IT FIRST: read `$FF8782` at the shim's own
    address with the FBNeo write tap or a MAME breakpoint on a tenant build.
    """
    if len(flav_map) <= 1:
        (default, held), = flav_map.values() or [(0, 0)]
        return (flavor_write(default, held, flav_d, hold_flag, objclr)
                + bytes([0x4E, 0xF9]) + newt.to_bytes(4, "big"))
    # N>1 through THIS function is dead since the 14z-82 F2 fix — the merged
    # shim is assembled at engine_here via flavor_chain_multi (per-owner
    # HANDLER exits, tripwire fall-through), because this chain's uniform
    # `jmp newt` could only ever exit into tenant-0's handler. Kept for the
    # historical record and the single-tenant assert path.
    if objclr:
        fail.append("init_shim: objram_clear with more than one declaring "
                    "tenant would arm the clear for ALL of them — it is "
                    "Donovan-gated by construction today. Decide its scope "
                    "before enabling it on a merged build.")
    by_name = {t.get("name"): t for t in tenants}
    out = b""
    for name, (default, held) in sorted(flav_map.items()):
        who = by_name.get(name)
        if who is None:
            fail.append(f"init_shim: flavor declared for {name!r}, which is "
                        f"not a tenant of this build")
            continue
        tid = _int(who["dst_slot"]) & 0xFF
        out += (bytes([0x0C, 0x2E, 0x00, tid, 0x03, 0x82])   # cmpi.b #id,(0x382,A6)
                + bytes([0x66, 0x2E])                        # bne.s next (+46)
                + flavor_write(default, held, flav_d, hold_flag)
                + bytes([0x4E, 0xF9]) + newt.to_bytes(4, "big"))   # jmp handler
    # no tenant matched -> no flavor write at all
    return out + bytes([0x4E, 0xF9]) + newt.to_bytes(4, "big")


def flavor_chain_multi(flav_map, flav_d, hold_flag, handlers, fallthrough):
    """14z-82 F2: the MERGED shim's tail — the one-shim-N-rows design.

    One 54-byte block per declaring tenant:

        cmpi.b #id,(0x382,A6)   ; this player's character id
        bne.s   <next block>    ; +46, uniform
        <40-byte flavor write>
        jmp     <THE OWNER'S OWN handler>

    The same shim is planted on EVERY declaring tenant's dispatch row
    (assembled at engine_here, after all handlers are placed — the 14z-80h
    shape), so the block that matches exits into the right tenant's
    char-init: seeder + phase gate + flavor now run for every declaring
    tenant, which is the F2 defect closed. The id read here is the one
    test_shim_charid.sh measured valid on BOTH player structs at char-init.

    `handlers` = {owner: (char_id, placed_handler)}. Fall-through = jmp to
    a planted TRIPWIRE: the shim is reachable only from declaring tenants'
    id-indexed dispatch rows, so an unmatched id is a routing bug worth
    naming loudly — never a silent detour into tenant-0's handler (that
    silent detour IS the F2 class).
    """
    out = b""
    for name, (default, held) in sorted(flav_map.items()):
        tid, handler = handlers[name]
        out += (bytes([0x0C, 0x2E, 0x00, tid & 0xFF, 0x03, 0x82])
                + bytes([0x66, 0x2E])                        # bne.s next (+46)
                + flavor_write(default, held, flav_d, hold_flag)
                + bytes([0x4E, 0xF9]) + handler.to_bytes(4, "big"))
    return out + bytes([0x4E, 0xF9]) + fallthrough.to_bytes(4, "big")


def _row_diff_keys(a, b):
    """Keys on which two rows differ, ignoring the ownership stamp."""
    return {k for k in set(a) | set(b)
            if k not in ("_owner", "_owners") and a.get(k) != b.get(k)}


def _same_row(a, b):
    """Same row apart from who owns it — i.e. a shared engine declaration."""
    return not _row_diff_keys(a, b)


def normalise_tenants(port, profile=None, override=None):
    """`[[tenant]]` supersedes `[port]`.

    A tenant is one ported character occupying one character id. Rather than
    rewrite the sites that read `port["port"]`, a tenant row is NORMALISED
    into the `[port]` shape the generator already understands — so a manifest
    carrying a single tenant at the old slot must produce a BYTE-IDENTICAL
    image, which is how this refactor is verified (the Phase C discipline: a
    refactor that moves zero bytes).

    M3b slice A: the per-tenant resolution moved out to `tenant_context()`
    and this function now builds a LIST of them, published as
    `port["_tenants"]`.

    THE >1 REFUSAL IS GONE (14z-80): `main()` now ITERATES over that list.
    It stood from the beginning of M3 as the honest statement that the
    manifest could express a merge the generator could not perform; the
    control in tests/test_tenant_id.sh that required it to fire is flipped
    in the same commit, which is the honest record of when multi-tenant
    builds arrived.

    `port["port"]` still holds `_tenants[0]` for the sites OUTSIDE the loop
    that need a build-level default (`tenant.json`, `owner_of()`'s fallback
    for an unowned legacy `[port]` manifest). Inside the loop every read
    goes through `T`.
    """
    tenants = port.get("tenant", [])
    if not tenants:
        return port                      # legacy [port] manifest, untouched
    contexts = [tenant_context(t, port, profile, override) for t in tenants]
    port = dict(port)
    port["_tenants"] = contexts
    port["port"] = contexts[0]
    return port


def row_owner(row, tenants, default=None):
    """The tenant context that owns a row (M3b slice C).

    `default` — this build's tenant — serves rows with no owner, i.e. a
    legacy `[port]`-only manifest, which has no tenant name to stamp.
    """
    name = row.get("_owner")
    if name is not None:
        for t in tenants:
            if t.get("name") == name:
                return t
    return default


def is_variant_tenant(tenant):
    """Is this tenant on a VARIANT id (0x10-0x1F) rather than a base slot?"""
    return _int(tenant["dst_slot"]) >= 0x10


def row_applies(row, tenant, only_variant=False, only_base=False):
    """Does a gated manifest row apply, given its OWNING tenant?

    `only_base_slot` (14z-62c): the row writes TENANT CONTENT over the HOST
    slot's own bytes in place — legitimate only while the tenant OCCUPIES
    that slot. On a variant-id build the host is a live legacy character
    again and the write would corrupt him.

    `only_variant_slot` (14z-63): the row writes a VARIANT-half table row
    (e.g. the HUD tables' aliased row 0x13) — meaningful only when the tenant
    IS at a variant id; on the base-slot track the variant half must stay the
    vanilla alias.

    `only_variant`/`only_base` let a SECTION declare the same property for
    rows that carry no key because the whole section is variant-only by
    construction (`select_records`, `win_pal_variant`).
    """
    var = is_variant_tenant(tenant)
    if (row.get("only_base_slot") or only_base) and var:
        return False
    if (row.get("only_variant_slot") or only_variant) and not var:
        return False
    return True


def row_hex(row, key, tenant):
    """`<key>`, or its `_variant` twin when the row's OWNER is at a variant id.

    (14z-62d) A row whose replacement value depends on WHERE the tenant
    lives — the OBJ bank setters write the host band's word at a base-half
    slot and the WIDE group-C word at a variant id.
    """
    vk = key + "_variant"
    if is_variant_tenant(tenant) and vk in row:
        return row[vk]
    return row[key]


def load_bank_map(path):
    doc = toml_loads(Path(path).read_text())
    return {t["name"]: t for t in doc["table"]}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("extract_dir", type=Path)
    ap.add_argument("out_dir", type=Path)
    ap.add_argument("--vsavj", type=Path, required=True)
    ap.add_argument("--stage", type=int, required=True, choices=range(1, 7))
    root = Path(__file__).resolve().parent.parent
    # REPEATABLE (M3b slice F): one manifest FILE per tenant. Ownership comes
    # from the file (slice C), so the merged build is `--port a --port b ...`
    # and no manifest row changes. Default preserved exactly.
    ap.add_argument("--port", type=Path, action="append", dest="port",
                    help="port manifest; repeat once per tenant")
    # REPEATABLE, AND PAIRED WITH --port (M3b, 14z-78c). Each tenant has its
    # OWN extraction — regions.json plus the region_*.bin blobs — so a
    # multi-tenant build needs one extract dir per manifest, in the same
    # order. The positional stays the FIRST tenant's extraction, which is what
    # keeps every existing invocation (and the frozen references) unchanged.
    ap.add_argument("--extract", type=Path, action="append", dest="extract",
                    help="additional tenant's extract dir; repeat in the same "
                         "order as --port (the positional is the first)")
    ap.add_argument("--recon", type=Path,
                    default=root / "build/manifest/reconciliation.toml")
    ap.add_argument("--bank-map", type=Path,
                    default=root / "build/manifest/bank_map.toml")
    ap.add_argument("--allow-plausible", action="store_true",
                    help="use reconciliation rows with status=plausible "
                         "(experiment builds; behavior gates arbitrate)")
    ap.add_argument("--tenant-id", type=lambda v: int(v, 0), default=None,
                    help="override the tenant's character id for this build. "
                         "Used while a de-substitution is IN PROGRESS: the "
                         "manifest keeps the id the frozen reference was built "
                         "with, so that reference stays reproducible, and the "
                         "move is explicit on the command line until it lands.")
    ap.add_argument("--profile", default=None,
                    help="build profile name; enables address spaces gated on "
                         "it (e.g. cps2-wide-v1). Without it, profile-gated "
                         "spaces do not exist and a stock-size build cannot "
                         "accidentally depend on them.")
    ap.add_argument("--tripwire-open", action="store_true",
                    help="route refs with missing/open reconciliation rows "
                         "to per-target planted-ILLEGAL tripwires instead of "
                         "failing — the guard's fault PC then names exactly "
                         "which unresolved target actually fires")
    ap.add_argument("--type-stamps", type=Path,
                    default=Path("build/manifest/type_stamps.toml"),
                    help="the FROZEN type-stamp inventory (14z-82) that the "
                         "per-tenant type-renumber pass consumes on multi-"
                         "tenant builds; single-tenant builds never read it")
    args = ap.parse_args()
    out = args.out_dir
    out.mkdir(parents=True, exist_ok=True)

    # ── THE SIDE-FILE NAMESPACE IS SHARED; THE CONTENT IS NOT (14z-80) ──────
    # Region blobs and palette blocks leave the generator as side files named
    # after the REGION (`fixed_x026142.bin`) or the palette (`palette_block_
    # sprite.bin`), referenced by a data_file/code_file op. Those names are
    # per tenant in content but not in spelling: 14z-77h froze SEVEN generic
    # region names shared across the three tenants. Under the N-tenant loop
    # tenant B's write therefore CLOBBERS tenant A's file while tenant A's op
    # still names that path — and the patcher then writes B's bytes at A's
    # address.
    #
    # That is invisible to every existing net: patch_prg's overlap assertion
    # compares op ADDRESSES (which differ), and the four fingerprints cannot
    # see it because it cannot happen with one tenant.
    #
    # So a side file written inside the loop takes a per-tenant SPELLING —
    # and tenant 0 keeps the historical one, which is what makes this inert
    # for every single-tenant build and every frozen reference. The ops carry
    # the path, so the patcher needs no change. `write_out()` keeps a
    # collision backstop underneath: any name still written twice with
    # different bytes is a NAMED build error, never a silent clobber.
    _written = {}

    def write_out(name, data, who=None):
        """Write a side file into `out`, refusing a differing rewrite."""
        blob = data.encode() if isinstance(data, str) else bytes(data)
        digest = hashlib.sha1(blob).hexdigest()
        prev = _written.get(name)
        if prev is not None and prev[0] != digest:
            raise SystemExit(
                "gen_donovan_patch: side file '%s' written twice with "
                "DIFFERENT content (first by %s, now by %s). Its name is "
                "shared across tenants but its bytes are not, so the second "
                "write would serve its bytes at the FIRST tenant's address. "
                "Route it through side_name()." % (name, prev[1], who or "?"))
        _written[name] = (digest, who or "?")
        (out / name).write_bytes(blob)
        return name

    # PER-FILE TENANT OWNERSHIP (M3b slice C): every row a file declares
    # belongs to that file's tenant. Stamped here, at the one place that
    # knows which file a row came from — then the documents MERGE (slice F).
    _ports = args.port or [root / "build/manifest/donovan.toml"]
    # EXTRACTIONS PAIR 1:1 WITH MANIFESTS (14z-78c). The positional is the
    # first tenant's; --extract adds the rest, in --port order. Checked here
    # rather than at first use, because the failure it prevents — tenant N
    # built against tenant M's regions — produces a plausible build rather
    # than an error.
    _extracts = [args.extract_dir] + list(args.extract or [])
    if len(_extracts) != len(_ports):
        raise SystemExit(
            "gen_donovan_patch: %d extract dir(s) but %d --port manifest(s). "
            "Each tenant needs its OWN extraction; pass --extract once per "
            "additional --port, in the same order.\n  extracts: %s\n  ports:    %s"
            % (len(_extracts), len(_ports),
               ", ".join(str(e) for e in _extracts),
               ", ".join(str(p) for p in _ports)))
    # `extract_dir` and `man` (this tenant's regions.json) are bound INSIDE
    # the N-tenant loop below: they are per-ITERATION data, not shared setup.
    _docs = []
    for _pp in _ports:
        _d = toml_loads(_pp.read_text())
        stamp_owner(_d, manifest_owner(_d))
        _docs.append(_d)
    port, _collisions = merge_manifests(_docs, args.profile)
    if _collisions:
        raise SystemExit(
            "gen_donovan_patch: the manifests collide and the merge will not "
            "guess:\n  " + "\n  ".join(_collisions) +
            "\nResolve each in the manifests (or teach merge_manifests() the "
            "per-section union) before building them together.")
    # Dotted table names are BANNED in this manifest (14z-62c): tomllib
    # nests them, the subset parser detaches them as orphan top-level keys
    # — the same manifest builds DIFFERENT bytes per host python. The
    # 14z-2 [[data_port.fix]] row was silently dropped this way on every
    # build from this machine, frozen references included.
    _dotted = [k for k in port if "." in k]
    if _dotted:
        raise SystemExit(f"gen_donovan_patch: dotted table name(s) in the "
                         f"manifest: {_dotted} — banned (host-dependent "
                         f"parse, 14z-62c). Use the flat equivalents.")
    port = normalise_tenants(port, args.profile, args.tenant_id)
    bank = load_bank_map(args.bank_map)
    vj = load_vsavj(args.vsavj)
    recon_base = {}
    if args.recon.is_file():
        for m in toml_loads(args.recon.read_text()).get("map", []):
            recon_base[_int(m["vsav2"])] = m
    recon = recon_base   # rebound per tenant inside the loop (see recon_for)

    # PER-TENANT RECON OVERLAY (14z-65): the shared map's rows are frozen
    # for the reference tenant's reproducibility — his build consumes OPEN
    # rows as tripwires, so resolving a row he references changes HIS
    # bytes. A tenant manifest may declare recon_overlay = "<toml>" whose
    # rows override the shared map for THAT tenant's builds only.
    #
    # 14z-80 — THE SCOPING THE COMMENT HERE PROMISED, and it was NOT
    # cosmetic. This read used to be `port["recon_overlay"] or
    # tenant[0]["recon_overlay"]`, i.e. the FIRST tenant's, applied to a
    # single shared map. Under the loop that silently dropped every later
    # tenant's overlay: measured on the first donovan+huitzil run, which
    # died on `x022400+0xb74: bank_ref 0xd96b8 needs a verified
    # reconciliation row` — a row huitzil's own overlay resolves. Now each
    # tenant gets the shared map plus ITS OWN overlay, and no other
    # tenant's, which is also what makes the frozen single-tenant builds
    # identical (each sees exactly what it saw alone).
    _ov_cache = {}

    def recon_for(tenant):
        """The reconciliation map for one tenant: shared rows + its overlay."""
        ov = port.get("recon_overlay") or tenant.get("recon_overlay")
        if not ov:
            return recon_base
        if ov not in _ov_cache:
            ovp = root / ov
            if not ovp.is_file():
                raise SystemExit(f"recon_overlay {ov} not found")
            merged = dict(recon_base)
            for m in toml_loads(ovp.read_text()).get("map", []):
                merged[_int(m["vsav2"])] = m
            _ov_cache[ov] = merged
        return _ov_cache[ov]

    # ── M5: the per-node sfx helper goes live ONLY with the record array ─────
    # 14z-52 measured exactly why this coupling has to be structural. The
    # ported dispatcher resolves slot 0x0F through the per-char pointer table;
    # without THIS character's own array, that row still points at JEDAH's
    # (~40 live entries) while Donovan's scripts index up to 43. An un-stubbed
    # helper would therefore read PAST the array and enqueue whatever follows
    # — including the vsavj 0x700-0x7FF MUSIC range. That is the original
    # 214P/214K "music instead of sfx" bug, and it is a shipping-grade defect.
    #
    # So the un-stub is driven by the SAME manifest row that places the array,
    # not by a profile name and not by a hand-edited reconciliation status. If
    # the array is not placed — a stock-size build, where the row is
    # profile-gated away — the helper stays stubbed BY CONSTRUCTION. There is
    # no ordering of edits that can produce a live helper with no array.
    #
    # Runs BEFORE the loop and mutates the row OBJECTS in `recon_base`, which
    # `recon_for()` copies by reference — so the un-stub reaches every tenant's
    # map. Checked rather than assumed (14z-80): no unstub address is shadowed
    # by either tenant overlay, so building the base map first is inert.
    unstubbed = []
    for _st in port.get("sound_table", []):
        if args.stage < _int(_st.get("stage", 0)):
            continue
        if _st.get("profile") and _st["profile"] != args.profile:
            continue
        for _spec in str(_st.get("unstub", "")).split(","):
            _spec = _spec.strip()
            if not _spec:
                continue
            _v2, _vj = (_int(x) for x in _spec.split("="))
            _row = recon.get(_v2)
            if _row is None:
                fail_early = f"sound_table {_st['name']}: unstub {_v2:#x} has no recon row"
                raise SystemExit(fail_early)
            _row["vsavj"] = _vj
            _row["kind"] = "engine"
            _row["status"] = "verified"
            unstubbed.append((_st["name"], _v2, _vj))

    # ── tenant identity (M3b slice B, 14z-76) ────────────────────────────────
    # ONE source of truth. `T` is the CURRENT ITERATION's tenant context
    # (tenant_context()); the loop below rebinds it, and every closure here
    # reads it rather than capturing a value. `row_ident()` derives the
    # (row, mirror row, mirror?) triple that EVERY per-character table write
    # needs, and takes an explicit tenant so a caller can pass one that is
    # not the current iteration's. The three scalars are re-derived per
    # iteration, inside the loop.
    T = (port.get("_tenants") or [port["port"]])[0]

    def row_ident(tenant=None):
        """(row, mirror_row, mirror?) for a tenant; defaults to this build's."""
        tt = T if tenant is None else tenant
        r = _int(tt["dst_slot"])
        return r, r | 0x10, tt.get("mirror_variant", True)

    def owner_of(row):
        """The tenant context that owns a MANIFEST row (M3b slice C).

        Every gate (slice C) and every manifest-row table address (slice D)
        asks this instead of the `dst_slot` scalar, so both are already
        asking the right question now that the N-tenant loop is here
        (14z-80); `row_here()` below answers the separate question of
        WHICH iteration emits the row.
        """
        return row_owner(row, port.get("_tenants") or [], T)

    def row_here(row):
        """Does this MANIFEST ROW belong to the CURRENT loop iteration?

        THE ITERATION GATE (M3b, 14z-80). `row_applies()` asks whether a row
        is meaningful for its OWNER's slot track; it says nothing about which
        iteration should emit it. Run the body N times without this and every
        SHARED row (`_owner=None` — the rows every tenant's manifest declares
        identically, deduped by merge_manifests) is emitted N times: an op
        collision at best, last-write-wins at worst.

        An OWNED row belongs to its owner's iteration. An UNOWNED (shared)
        row — the rows every manifest declares identically, which
        merge_manifests dedups to one — splits by WHAT IT KEYS ON, and the
        split is not cosmetic (14z-80b shipped it as "unowned => iteration 0"
        and that was measurably wrong):

          TENANT-DERIVED — the row's EFFECT depends on which tenant applies
            it, so identical TEXT does not mean identical effect and it must
            be applied once per DECLARING tenant (`_owners`, kept by the
            dedup). Two keys mark it:
              `region`/`regions` — every tenant keeps its OWN COPY of the
                shared source spans (14z-78b), so the row patches N blobs.
                Emitted on iteration 0 alone, the six shared `port_patch`
                OBJ bank setters patched only Donovan's copies of
                x05c800/x088512 and left Huitzil's and Pyron's holding vs2's
                bank 3 — the wrong graphics bank, silently (measured
                14z-80e: 6/6 unpatched).
              `slot_table` — the ADDRESS is `table + stride*dst_slot`, i.e.
                a different word per tenant. Emitted on iteration 0 the
                shared `obj_bank_word_slot`/`win_pos_x_slot` rows (declared
                by Huitzil and Pyron) wrote DONOVAN'S entries, colliding
                with his own rows at 0x282FA and 0x5F24C — two of the ten
                op collisions — while H and P got none (14z-80g).
            The declaring set matters here and only here: those two rows are
            H's and P's, so applying them on Donovan's iteration is wrong in
            both directions.

          ENGINE-SITE (everything else: obj_hook, select_wheel, site_thunk).
            One address in the one shared image, so it must be emitted
            ONCE — iteration 0, or, when its content needs every tenant's
            placements, the last (see `engine_here()`).

        LIMIT ON THE SECOND CLASS, and it is the next slice: a shared
        engine-site row emitted on iteration 0 sees only tenant 0's
        `placed`/`regions`. `obj_hook`'s extended table resolves each ported
        handler through exactly those, so the OTHER tenants' extra handlers
        fall to their tripwires. Loud at runtime, not silent. The fix is a
        union pass AFTER the loop; that section carries a pointer here.
        """
        o = row.get("_owner")
        if o is not None:
            return o == T.get("name")
        if any(k in row for k in ("region", "regions", "slot_table")):
            # once per DECLARING tenant; `_owners` is absent on a
            # single-document build, where the one iteration is the answer
            owners = row.get("_owners")
            return True if not owners else (T.get("name") in owners)
        if ("thunk_hex" in row
                and ("tt" in str(row["thunk_hex"]).lower()
                     or "tu" in str(row["thunk_hex"]).lower())):
            # 14z-84: a shared ENGINE-SITE thunk whose body SUBSTITUTES the
            # tenant id (the *_bank_variant_id class) — identical TEXT,
            # per-tenant EFFECT. One site cannot take N thunks, so each
            # declaring tenant's iteration builds ITS substituted body and
            # the chain pass emits one thunk gating ALL of them. This used
            # to fall through to `_ti == 0`, so the merged gate compared
            # tenant 0's id alone: H/P hover never flipped the select/VS
            # name drawers to bank 5 and their bank-5 codes drew host
            # sprite art (the first full-roster playtest's name/portrait
            # garble, measured from the merged image's placed bodies).
            owners = row.get("_owners")
            return True if not owners else (T.get("name") in owners)
        return _ti == 0

    def tenant_rows(section):
        """The rows of a manifest LIST section belonging to this iteration.

        Every list-section read inside the loop body goes through here, so a
        MISSED site is findable by grepping `port.get("` below the loop
        header rather than by reasoning about it — which is what
        tests/test_tenant_loop.sh does.
        """
        return [r for r in port.get(section, []) if row_here(r)]

    # ── THE ENGINE-LEVEL UNION (14z-80f) ────────────────────────────────────
    # An ENGINE table — `obj_hook`'s extended secondary-object dispatch — is
    # one table at one address in the one shared image, and its entries point
    # at handlers that DIFFERENT TENANTS port. It can therefore neither be
    # emitted per tenant (N copies at one address) nor emitted before the
    # tenants exist (iteration 0 knows only tenant 0's placements). So it runs
    # ONCE, on the LAST iteration, resolving through every tenant's view.
    #
    # Measured before the fix, on a 3-tenant build: 15 extra types fell to
    # tripwires and TWELVE of them are handlers Huitzil places (types 64-75).
    # Every one of his secondary objects would have dispatched to an ILLEGAL
    # the moment it spawned.
    tenant_views = []   # per tenant: name, regions, placed, recon, src_set
    # Sites declared by MORE THAN ONE tenant cannot take one thunk each. The
    # set is known from the merged manifest before anything is emitted; the
    # bodies are collected during the loop (each built with its own tenant's
    # placements) and chained after it.
    _st_multi = {a for a in
                 [_int(r["site"]) for r in port.get("site_thunk", [])
                  if "site" in r]
                 if [_int(r["site"]) for r in port.get("site_thunk", [])
                     if "site" in r].count(a) > 1}
    # 14z-84: a DEDUPED shared thunk with a tenant-id placeholder is also a
    # multi-tenant site — one manifest row, N substituted bodies (row_here
    # now yields it on every declaring iteration). Without this the site
    # counted once and the single-thunk path gated tenant 0's id alone.
    _st_multi |= {_int(r["site"]) for r in port.get("site_thunk", [])
                  if "site" in r and r.get("_owner") is None
                  and len(r.get("_owners") or []) > 1
                  and ("tt" in str(r.get("thunk_hex", "")).lower()
                       or "tu" in str(r.get("thunk_hex", "")).lower())}
    _st_multi_bodies = {}

    def engine_here():
        """Is this the iteration on which engine-level sections emit?"""
        return _ti == len(_tenant_list) - 1

    def engine_rows(section):
        """Rows of an engine-level section — once, on the last iteration."""
        return list(port.get(section, [])) if engine_here() else []

    def resolve_ported(tgt):
        """(placed address, tenant name) for a SOURCE target any tenant ported.

        Scans the accumulated views in tenant order, so a span two tenants
        both copied resolves to the FIRST tenant's copy.

        KNOWN DEFECT (14z-81b, MEASURED — the merged Huitzil vec3 crash):
        first-wins is WRONG for a multi-owner obj_hook type. The premise
        this docstring used to assert ("the copies are byte-equal clones,
        specialised only through data pointers") is false in the way that
        matters: the copies are INTERNALLY TENANT-RECONCILED — per-tenant
        anim literals, and cross-tenant pointers rewritten to planted
        TRIPWIRES — so tenant B executing tenant A's copy consumes A's
        tripwire addresses as data. Types 114-120 (site 0x5E542's
        extension, the x088512 pool family) are resolved by every tenant's
        view and need an owner dispatch instead (design + measurements:
        STATE 14z-81b; regression gate: tests/audit_merged_vec3.sh).
        Single-tenant builds are unaffected (one view, first-wins trivially
        correct).
        """
        for v in tenant_views:
            for nm, r in v["regions"].items():
                if (r["len"] > 0 and r["src"] <= tgt < r["src"] + r["len"]
                        and nm in v["placed"]):
                    return v["placed"][nm] + (tgt - r["src"]), v["name"]
        return None, None

    def resolve_ported_all(tgt):
        """EVERY tenant's resolution of a SOURCE target — [(addr, name)].

        `resolve_ported()` returns the first; the obj_hook union needs ALL,
        because a type resolved by more than one tenant's view is
        MULTI-OWNER and must dispatch on the object's OWNER (14z-81b) —
        first-wins there is the merged Huitzil vec3 crash.
        """
        out = []
        for v in tenant_views:
            for nm, r in v["regions"].items():
                if (r["len"] > 0 and r["src"] <= tgt < r["src"] + r["len"]
                        and nm in v["placed"]):
                    out.append((v["placed"][nm] + (tgt - r["src"]),
                                v["name"]))
                    break
        return out

    def resolve_recon(tgt):
        """A verified reconciliation row for `tgt` from ANY tenant's map.

        The overlays are per tenant (recon_for), so a row Huitzil's overlay
        resolves is invisible to Donovan's map — and an engine table must see
        both.
        """
        for v in tenant_views:
            m = v["recon"].get(tgt)
            if m and (m.get("status") == "verified"
                      or (args.allow_plausible
                          and m.get("status") == "plausible")):
                return m
        return None

    def side_name(name):
        """The per-tenant spelling of a side file written INSIDE the loop.

        Tenant 0 keeps the historical name, so every single-tenant build —
        including all four frozen references — emits the identical file set.
        Later tenants get `<stem>.<tenant><ext>`, because the content is per
        tenant while the name (a region name, a palette name) is not: seven
        region names are shared across the three tenants (14z-77h).
        """
        if _ti == 0:
            return name
        stem, dot, ext = name.partition(".")
        return "%s.%s%s%s" % (stem, T.get("name", "t%d" % _ti), dot, ext)

    def singleton(section):
        """The same test for a TOML singleton (`[table_fix]`, `[init_shim]`…).

        A singleton is either owned by one tenant's file or was merged from
        several (merge_init_shim/merge_table_fix), which stamps it unowned —
        so it emits once, on iteration 0, carrying every tenant's content.
        """
        d = port.get(section)
        if not isinstance(d, dict) or not row_here(d):
            return None
        return d

    # WHERE THE PER-TENANT READS NOW COME FROM (slice D, closed 14z-80).
    # Three classes, and the loop resolved two of them:
    #
    #   EXTRACTION-SIDE — driven by `man` (regions.json) and the region
    #     blobs, which are the output of ONE tenant's extraction. RESOLVED:
    #     they are per-iteration data and the loop rebinds them (`man`,
    #     `extract_dir`, `regions`, `placed`), so the stage-1 scaffold, the
    #     OBJ bank-table fixup, `man["values"]` and `engine_dispatch`'s
    #     alias probe all see their own tenant's.
    #
    #   BAKED INTO EMITTED MACHINE CODE — `charid_sites`, the win-pal thunk
    #     rebase, TT/TU substitution, the overlay T-select thunk. Each takes
    #     its id from the row's owner or from `T` (slice E), so a per-tenant
    #     site is correct. The shared-SITE case — `win_pal_variant` at
    #     0x5F1B6 and the `select_pal_variant_id` site_thunk at 0x5F146, one
    #     address every tenant patches — is CLOSED (14z-80h): both bodies are
    #     compare-chain elements already, so N tenants chain by
    #     concatenation and N=1 is byte-identical. See the chain passes.
    #
    #   OUTPUT NAMING — RESOLVED: `tenant.json` stays tenant 0 for its four
    #     consumers and the array goes to `tenants.json`; side files take a
    #     per-tenant spelling via `side_name()`.
    # dst_slot/var_slot/mirror are derived per ITERATION (see the loop).
    # Slice D: the select CELLS every tenant occupies. The wheel skips a
    # tenant's own cell because its P1/P2 rows come from that tenant's
    # `select_records` host_ring row — true of each tenant independently,
    # so this is a SET, not the build's one slot.
    _tenant_cells = {_int(t["dst_slot"]) for t in (port.get("_tenants") or [T])}
    # ── address-space model (Phase C) ────────────────────────────────────────
    # Placement used to be two hard-coded holes. It is now a declarative,
    # ORDERED list of spaces, because the roster does not fit in two holes and
    # "which hole?" is the wrong question once the WIDE extension exists.
    #
    # A space is {name, start, end, cur, class, profile, fallback}:
    #   class   "crypt" = inside the CPS-2 encryption window, so CODE placed
    #                     here must be re-encrypted; "raw" = outside it.
    #   profile when set, the space only exists for that build profile, so a
    #           stock-size build cannot accidentally allocate into space that
    #           only a patched emulator provides.
    #   fallback name of the next space to try on overflow.
    #
    # Manifests may declare [[space]] entries; a manifest with only the legacy
    # [hole_a]/[hole_b] sections synthesises the identical two-space list, so
    # existing builds are byte-for-byte unchanged (asserted by
    # tests/test_phasec_spaces.sh).
    spaces = {}
    order = []
    decl = port.get("space", [])
    if decl:
        for s in decl:
            nm = s["name"]
            spaces[nm] = {"name": nm, "start": _int(s["start"]),
                          "end": _int(s["end"]), "cur": _int(s["start"]),
                          "class": s.get("class", "raw"),
                          "profile": s.get("profile"),
                          "fallback": s.get("fallback")}
            order.append(nm)
    else:
        spaces["hole_a"] = {"name": "hole_a", "start": _int(port["hole_a"]["start"]),
                            "end": _int(port["hole_a"]["end"]),
                            "cur": _int(port["hole_a"]["start"]),
                            "class": "crypt", "profile": None, "fallback": "hole_b"}
        spaces["hole_b"] = {"name": "hole_b", "start": _int(port["hole_b"]["start"]),
                            "end": _int(port["hole_b"]["end"]),
                            "cur": _int(port["hole_b"]["start"]),
                            "class": "raw", "profile": None, "fallback": None}
        order = ["hole_a", "hole_b"]

    # Legacy call sites say alloc("a"/"b", ...); keep that vocabulary.
    ALIAS = {"a": "hole_a", "b": "hole_b"}

    # Drop spaces belonging to a profile we are not building for. Doing this
    # by CONSTRUCTION (rather than by remembering not to use them) is what
    # makes a stock build incapable of depending on the WIDE extension.
    for nm in list(spaces):
        pr = spaces[nm]["profile"]
        if pr and pr != args.profile:
            del spaces[nm]
            order.remove(nm)

    ops = []
    notes = []
    fail = []
    fragments = []  # (dst, len, provenance, what) for the atlas fragment
    all_placements = {}  # every tenant's placed regions, for placements.json

    def vj_u32(addr):
        return int.from_bytes(vj[addr:addr + 4], "big")

    gap_free = []  # (start, end) inside already-claimed group spans
    # pcrel_far_tramps / dc_tables are per-tenant memos — bound in the loop.

    def alloc(hole, size, what, fallback=True):
        """Place `size` bytes, returning the destination address.

        `hole` names a space ("a"/"b" are the legacy aliases). On overflow the
        space's declared `fallback` chain is followed, so growing the address
        space is a manifest edit rather than a code edit.
        """
        # gap-fit first: reuse dead space inside layout-group spans
        for gi, (gs, ge) in enumerate(gap_free):
            if ge - gs >= size:
                gap_free[gi] = ((gs + size + 0xF) & ~0xF, ge)
                return gs
        nm = ALIAS.get(hole, hole)
        sp = spaces.get(nm)
        if sp is None:
            fail.append(f"no address space '{hole}' for {what}"
                        + (f" (profile '{args.profile}')" if args.profile else
                           " (is it profile-gated? pass --profile)"))
            return None
        start = sp["cur"]
        if start + size > sp["end"]:
            nxt = sp["fallback"] if fallback else None
            if nxt and nxt in spaces:
                return alloc(nxt, size, what, fallback=True)
            fail.append(f"space {nm} overflow allocating 0x{size:X} for {what} "
                        f"(free 0x{max(0, sp['end'] - start):X})")
            return None
        # Beyond the base image is legal ONLY in a profile-gated space: the
        # patcher grows the image and emits the appended members (the "image"
        # block written below). Extension bytes are 0xFF fill by construction,
        # so there is nothing to verify there — but in BASE space the
        # 0xFF-fill check still guards every byte.
        if start + size > len(vj):
            if not sp["profile"]:
                fail.append(
                    f"space {nm} allocation 0x{start:06X}+0x{size:X} for {what} "
                    f"lies beyond the 0x{len(vj):X}-byte program image, and {nm} "
                    f"is not profile-gated — a stock build cannot grow the image.")
                return None
        else:
            for i in range(start, start + size):
                if vj[i] != 0xFF:
                    fail.append(f"dest 0x{i:06X} for {what} is not 0xFF fill")
                    return None
        sp["cur"] = (start + size + 0xF) & ~0xF
        return start

    def table_entry_addr(tname, slot):
        t = bank[tname]
        es = (t["span"] // 32) if t["kind"] == "byte2d" else (t["stride"] // 32)
        return _int(t["vsavj"]) + slot * es, es

    def repoint(tname, value, what, tenant=None):
        """poke32 a bank pointer entry at the tenant's row (+ variant mirror).

        M3b slice B: row identity comes from `tenant` (default: this build's),
        not from main()'s scalars — so every one of this function's call sites
        is correct under the N-tenant loop, which passes its own (14z-80).
        """
        _row, _var, _mir = row_ident(tenant)
        a, es = table_entry_addr(tname, _row)
        assert es == 4
        ops.append({"op": "poke32", "addr": f"{a:#x}", "val": f"{value:#010x}"})
        notes.append(f"poke32 {a:#08x} <- {value:#010x}  {tname}[{_row:#x}] {what}")
        if _mir:
            av, _ = table_entry_addr(tname, _var)
            if vj_u32(av) != vj_u32(a):
                fail.append(f"{tname}: slot {_var:#x} does not alias "
                            f"{_row:#x} in vanilla ({vj_u32(av):#x} vs "
                            f"{vj_u32(a):#x}) — mirror assumption broken")
            else:
                ops.append({"op": "poke32", "addr": f"{av:#x}",
                            "val": f"{value:#010x}"})
                notes.append(f"poke32 {av:#08x} <- {value:#010x}  "
                             f"{tname}[{_var:#x}] variant mirror")

    def poke_bytes(addr, data, what):
        """Raw bytes at addr; odd-aligned edges are merged with vanilla
        neighbor bytes into word-aligned data ops."""
        start, blob = addr, data
        if start % 2:
            start -= 1
            blob = vj[start:start + 1] + blob
        if (start + len(blob)) % 2:
            blob = blob + vj[start + len(blob):start + len(blob) + 1]
        ops.append({"op": "data", "addr": f"{start:#x}", "hex": blob.hex()})
        notes.append(f"data   {start:#08x} +{len(blob):#x}  {what}")

    # ── THE N-TENANT LOOP (M3b, 14z-80) ─────────────────────────────────────
    # Everything above is SHARED across tenants and accumulates: the address
    # spaces (one cursor, so tenants cannot allocate over each other),
    # `gap_free`, and the ops/notes/fail/fragments ledgers. Everything below
    # is PER TENANT and is rebound on each iteration.
    #
    # The extractions pair 1:1 with the manifests (14z-78c), and each
    # manifest declares exactly one tenant, so `_extracts[_ti]` is THIS
    # tenant's extraction. A manifest declaring two tenants would break that
    # pairing silently, hence the check.
    _tenant_list = port.get("_tenants") or [port["port"]]
    if len(_tenant_list) != len(_extracts):
        raise SystemExit(
            "gen_donovan_patch: %d tenant(s) across %d manifest(s)/extraction(s)"
            " — each manifest must declare exactly ONE [[tenant]], so that a"
            " tenant and its extraction pair by position."
            % (len(_tenant_list), len(_extracts)))

    # ── 14z-82: PER-TENANT TYPE NUMBERS for multi-owner obj_hook types ──────
    # The merged union gives a multi-owner type ONE table entry, routing
    # every tenant into tenant-0's internally tenant-reconciled copy (the
    # merged Huitzil vec3, STATE 14z-81b). The withdrawn owner-read stub
    # proved dispatch-time state is transient at spawn instants (14z-81c),
    # so the fix routes on facts baked at BUILD time: each NON-FIRST
    # resolver tenant that stamps a family type gets its OWN type number —
    # its copies' stamp immediates are rewritten and the union grows a
    # per-tenant entry resolving to that tenant's copy. The FIRST resolver
    # keeps the original numbers (maintainer-decided scope, 14z-82): the
    # guard-clean tenant's bytes stay untouched, and the census-gap
    # detector is dynamic instead (tests/audit_type_dispatch_range.sh:
    # zero original-range dispatches on later tenants' replays).
    #
    # Scope: site 0x5E542's extension (types 114-120) ONLY. Site 0x54470's
    # 64-75 stay FIRST-WINS with their loud notes — deferred WITH a
    # measurement attached (the frozen inventory's 59-75 rows + the same
    # dispatch-range probe pointed at that site).
    #
    # Everything here is derived from PLACEMENT-INDEPENDENT inputs (the
    # tenants' regions.json + the frozen stamp inventory), so it runs
    # before the loop; and it is EMPTY at N=1 by construction — no type is
    # multi-resolver with one view — which is the frozen-fingerprint
    # inertness argument, the same one that held for the withdrawn stub.
    # 14z-82 F2: on a multi-tenant build the [init_shim] singleton serves
    # EVERY declaring tenant — the per-iteration handlers are collected in
    # `_shim_multi` and ONE shim (per-owner flavor + per-owner handler
    # exits, flavor_chain_multi) is assembled at engine_here, then planted
    # on each declaring tenant's dispatch row. None at N=1: the historical
    # single-tenant emission is untouched (the frozen-fingerprint argument).
    _shim_multi = {} if len(_tenant_list) > 1 else None
    _shim_cfg_all = port.get("init_shim") \
        if isinstance(port.get("init_shim"), dict) else None

    RENUMBER_SITE = 0x5E542
    RENUMBER_TYPES = range(114, 121)
    TYPE_RENUMBER = {}       # (site, orig_type, tenant name) -> new index
    TYPE_RENUMBER_ORDER = []  # [(site, new_index, orig_type, tenant, tgt)]
    TYPE_STAMP_WORK = []      # [(tenant, src_addr, span, tt_off, exp_bytes,
                              #   orig_type, form)]
    OWNER_TAG_WORK = []       # 14z-85: [(tenant, src_addr, span, exp_bytes,
                              #   type, form)] — the 59-75 detour worklist
    OWNER_TAG_STAMPERS = {}   # type -> {tenant names with stamp sites}
    OWNER_TAG_THUNKS = {}     # (tenant, exp_bytes) -> placed thunk address
    OWNER_TAG_MAP = []        # rows for patch/tag_map.json (gates + atlas)
    if len(_tenant_list) >= 2:
        _tnames = [t.get("name") for t in _tenant_list]
        if None in _tnames or len(set(_tnames)) != len(_tnames):
            raise SystemExit("gen_donovan_patch: multi-tenant builds need "
                             "unique [[tenant]] name fields (type-renumber "
                             "keys on them)")
        _tregions = []   # per tenant: {name: (src, len, kind)}
        for _ed in _extracts:
            _rj = json.loads((Path(_ed) / "regions.json").read_text())
            _tregions.append({k: (v["src"], v["len"], v.get("kind", "?"))
                              for k, v in _rj["regions"].items()})

        def _owning_tenants(addr, code_only=True):
            outn = []
            for _tn, _regs in zip(_tnames, _tregions):
                for _rn, (_s, _l, _k) in _regs.items():
                    if _s <= addr < _s + _l and (not code_only
                                                 or _k != "data"):
                        outn.append(_tn)
                        break
            return outn

        _oh_rows = [r for r in port.get("obj_hook", [])
                    if _int(r["site"]) == RENUMBER_SITE]
        if _oh_rows:
            if not args.type_stamps.is_file():
                raise SystemExit(
                    f"gen_donovan_patch: multi-tenant build with obj_hook "
                    f"site {RENUMBER_SITE:#x} needs the frozen type-stamp "
                    f"inventory ({args.type_stamps}) — run tools/"
                    f"audit_type_stamps.py + review + freeze first (14z-82)")
            _inv = load_type_stamps(args.type_stamps)
            _src_sets = {t["src_set"] for t in _tenant_list}
            if len(_src_sets) != 1:
                raise SystemExit("gen_donovan_patch: type-renumber assumes "
                                 "one shared src_set; got %s" % _src_sets)
            _src_img = (root / f"build/out/{_tenant_list[0]['src_set']}"
                               f"_opcodes.bin").read_bytes()
            _ph = _oh_rows[0]
            _stab = _int(_ph["src_table"])
            _n_van = _int(_ph["vanilla_entries"])
            _n_src = _int(_ph["src_entries"])
            _next = _n_src + len([e for e in port.get("obj_hook_extra", [])
                                  if _int(e["site"]) == RENUMBER_SITE])
            # stamps per (type, tenant), from the frozen inventory
            _stamps_by = {}
            for _row in _inv:
                if _row["_kind"] != "stamp":
                    continue
                _sa = int(_row["src_addr"], 0)
                _ty = int(_row["type"], 0)
                if _ty not in RENUMBER_TYPES:
                    continue
                _fm = _row["form"]
                if _fm not in _STAMP_FORMS:
                    raise SystemExit(
                        f"gen_donovan_patch: frozen stamp 0x{_sa:06X} has "
                        f"unhandled form {_fm!r} — extend _STAMP_FORMS "
                        f"deliberately, never skip (a skipped stamp keeps "
                        f"an ORIGINAL number alive in a renumbered tenant)")
                if _fm == "stamp_b_d16" and int(_row.get("d16", "0"), 0) != 2:
                    continue   # +0x03 owner/substate writes are not stamps
                _span, _ttoff = _STAMP_FORMS[_fm]
                _exp = _src_img[_sa:_sa + _span]
                # the inventory's imm must match the image (drift = the
                # census gate failed to run; refuse to guess)
                _imm = int(_row["imm"], 0)
                _imm_bytes = _imm.to_bytes(4, "big") if _fm.startswith(
                    "stamp_l") else _imm.to_bytes(2, "big")
                if _imm_bytes not in _exp:
                    raise SystemExit(
                        f"gen_donovan_patch: frozen stamp 0x{_sa:06X} imm "
                        f"{_imm:#x} not present in source bytes "
                        f"{_exp.hex()} — inventory vs image drift")
                for _tn in _owning_tenants(_sa):
                    _stamps_by.setdefault((_ty, _tn), []).append(
                        (_sa, _span, _ttoff, _exp, _fm))
            for _k in range(_n_van, _n_src):
                _ty = _k
                if _ty not in RENUMBER_TYPES:
                    continue
                _tgt = int.from_bytes(_src_img[_stab + _k * 4:
                                               _stab + _k * 4 + 4], "big")
                _resolvers = _owning_tenants(_tgt, code_only=False)
                if len(_resolvers) < 2:
                    continue
                for _tn in _resolvers[1:]:
                    _st = _stamps_by.get((_ty, _tn))
                    if not _st:
                        continue   # no stamp -> keeps first-wins (type 120)
                    TYPE_RENUMBER[(RENUMBER_SITE, _ty, _tn)] = _next
                    TYPE_RENUMBER_ORDER.append(
                        (RENUMBER_SITE, _next, _ty, _tn, _tgt))
                    for _sa, _span, _ttoff, _exp, _fm in _st:
                        TYPE_STAMP_WORK.append(
                            (_tn, _sa, _span, _ttoff, _exp, _ty, _fm))
                    _next += 1
            if _next > 256:
                raise SystemExit(
                    f"gen_donovan_patch: type-renumber ran past the 256-"
                    f"entry ceiling (next index {_next}) — the walker "
                    f"indexes a BYTE (move.b (2,a6),d0)")
            # fail closed on reviewed compares: a family-typed compare in a
            # RENUMBERED tenant's code regions must carry an explicit
            # action (today: all reviewed rows are action="none" because
            # none reads the type byte — d16 0x54/0x14/0xA8 or register)
            for _row in _inv:
                if _row["_kind"] != "compare":
                    continue
                _ty = int(_row["type"], 0)
                if _ty not in RENUMBER_TYPES:
                    continue
                for _tn in _owning_tenants(int(_row["src_addr"], 0)):
                    if (RENUMBER_SITE, _ty, _tn) in TYPE_RENUMBER \
                            and _row.get("action") != "none":
                        fail.append(
                            f"type_stamps compare 0x{int(_row['src_addr'],0):06X}"
                            f" (type {_ty}, tenant {_tn}) has action="
                            f"{_row.get('action')!r} — a renumbered type's "
                            f"compare needs an explicit reviewed action")
            # overlap backstop: no port_patch/imm_poison row may touch a
            # rewritten stamp's span (pass-ordering surprises become loud)
            _spans = {}
            for _tn, _sa, _span, _to, _e, _ty, _fm in TYPE_STAMP_WORK:
                _spans.setdefault((_sa, _sa + _span), _tn)
            for _sect, _key in (("port_patch", "old_hex"),
                                ("imm_poison", None)):
                for _rw in port.get(_sect, []):
                    if "src_addr" not in _rw:
                        continue
                    _ra = _int(_rw["src_addr"])
                    _rl = len(bytes.fromhex(_rw[_key])) if _key else 4
                    for (_lo, _hi), _tn in _spans.items():
                        if _ra < _hi and _lo < _ra + _rl:
                            fail.append(
                                f"{_sect} at 0x{_ra:06X} overlaps the "
                                f"type-stamp rewrite span 0x{_lo:06X}-"
                                f"0x{_hi:06X} ({_tn}) — resolve the "
                                f"collision explicitly")

        # ── 14z-85: OWNER-TAG derivation for the 0x54470 family (59-75) ──────
        # Same shape as the renumber pass above: placement-independent inputs
        # (frozen inventory + regions.json), derived pre-loop, EMPTY at N=1 by
        # construction (this whole block is inside the >= 2 gate) — the solo
        # fingerprints stay bit-identical. Every declaring tenant's family
        # stamp site is detoured (in-loop, beside the renumber rewrite) so a
        # fresh family object ALWAYS carries its stamper's tag — including
        # tenants that stamp a type whose handler they do not place (dead
        # paths today; their spawn would tripwire under its OWN tag instead
        # of silently running a stale one).
        _tag_rows = [r for r in port.get("obj_hook", [])
                     if _int(r["site"]) == OWNER_TAG_SITE]
        if _tag_rows:
            if not args.type_stamps.is_file():
                raise SystemExit(
                    f"gen_donovan_patch: multi-tenant build with obj_hook "
                    f"site {OWNER_TAG_SITE:#x} needs the frozen type-stamp "
                    f"inventory ({args.type_stamps}) — the owner-tag pass "
                    f"detours every frozen 59-75 stamp site (14z-85)")
            _inv2 = load_type_stamps(args.type_stamps)
            _src_sets2 = {t["src_set"] for t in _tenant_list}
            if len(_src_sets2) != 1:
                raise SystemExit("gen_donovan_patch: owner-tag assumes one "
                                 "shared src_set; got %s" % _src_sets2)
            _src_img2 = (root / f"build/out/{_tenant_list[0]['src_set']}"
                                f"_opcodes.bin").read_bytes()
            for _row in _inv2:
                if _row["_kind"] != "stamp":
                    continue
                _sa = int(_row["src_addr"], 0)
                _ty = int(_row["type"], 0)
                if _ty not in OWNER_TAG_TYPES:
                    continue
                _fm = _row["form"]
                if _fm not in _STAMP_FORMS:
                    raise SystemExit(
                        f"gen_donovan_patch: frozen stamp 0x{_sa:06X} has "
                        f"unhandled form {_fm!r} — extend _STAMP_FORMS "
                        f"deliberately, never skip (a skipped stamp spawns "
                        f"UNTAGGED family objects that tripwire at dispatch)")
                if _fm == "stamp_b_d16" and int(_row.get("d16", "0"), 0) != 2:
                    continue   # +0x03 owner/substate writes are not stamps
                _span, _ttoff = _STAMP_FORMS[_fm]
                if _span != 6:
                    raise SystemExit(
                        f"gen_donovan_patch: owner-tag stamp 0x{_sa:06X} "
                        f"form {_fm} span {_span} != 6 — the jsr detour "
                        f"replaces exactly 6 bytes; extend deliberately")
                _exp = _src_img2[_sa:_sa + _span]
                _imm = int(_row["imm"], 0)
                _imm_bytes = _imm.to_bytes(4, "big") if _fm.startswith(
                    "stamp_l") else _imm.to_bytes(2, "big")
                if _imm_bytes not in _exp:
                    raise SystemExit(
                        f"gen_donovan_patch: frozen stamp 0x{_sa:06X} imm "
                        f"{_imm:#x} not present in source bytes "
                        f"{_exp.hex()} — inventory vs image drift")
                for _tn in _owning_tenants(_sa):
                    OWNER_TAG_WORK.append((_tn, _sa, _span, _exp, _ty, _fm))
                    OWNER_TAG_STAMPERS.setdefault(_ty, set()).add(_tn)
            # overlap backstop, exactly as the renumber's: no port_patch/
            # imm_poison row may touch a detoured span
            _tspans = {}
            for _tn, _sa, _span, _e, _ty, _fm in OWNER_TAG_WORK:
                _tspans.setdefault((_sa, _sa + _span), _tn)
            for _sect, _key in (("port_patch", "old_hex"),
                                ("imm_poison", None)):
                for _rw in port.get(_sect, []):
                    if "src_addr" not in _rw:
                        continue
                    _ra = _int(_rw["src_addr"])
                    _rl = len(bytes.fromhex(_rw[_key])) if _key else 4
                    for (_lo, _hi), _tn in _tspans.items():
                        if _ra < _hi and _lo < _ra + _rl:
                            fail.append(
                                f"{_sect} at 0x{_ra:06X} overlaps the "
                                f"owner-tag detour span 0x{_lo:06X}-"
                                f"0x{_hi:06X} ({_tn}) — resolve the "
                                f"collision explicitly")

    for _ti, T in enumerate(_tenant_list):
        extract_dir = _extracts[_ti]
        man = json.loads((extract_dir / "regions.json").read_text())
        recon = recon_for(T)
        dst_slot, var_slot, mirror = row_ident()
        # Memos keyed by ADDRESS, not (tenant, address) — so they are bound
        # HERE, per tenant. Sharing `pcrel_far_tramps` would hand tenant B a
        # trampoline placed near tenant A and trip the d16 check below;
        # sharing `dc_tables` would hand it A's placed copy.
        pcrel_far_tramps = {}  # resolved target -> near jmp trampoline (14z-65)
        dc_tables = {}         # (table src, len) -> placed DATA copy (14z-69)

        # ── stage 1: null relocation (scaffolding proof; emitted only for the
        # stage 1-3 ladder builds — stage 4+ needs the space and overrides every
        # repoint anyway) ────────────────────────────────────────────────────────
        def vsavj_ptr_bounds(table_names, slot):
            seeds, all_ptrs = [], set()
            for tn in table_names:
                base = _int(bank[tn]["vsavj"])
                for c in range(32):
                    v = vj_u32(base + c * 4)
                    if 0x1000 < v < 0x400000:
                        all_ptrs.add(v)
                    if c == slot:
                        seeds.append(v)
            start = min(seeds)
            above = [p for p in all_ptrs if p > max(seeds)]
            return seeds, start, (min(above) if above else max(seeds) + 0x4000)

        seeds, jh_start, jh_end = vsavj_ptr_bounds(["hitbox_base", "hitbox_comp"],
                                                   dst_slot)
        if args.stage > 3:
            jh_len = 0  # skip scaffolding
        else:
            jh_len = jh_end - jh_start
        notes.append(f"# stage 1: Jedah hitbox block 0x{jh_start:06X}+0x{jh_len:X} "
                     f"(base {seeds[0]:#x} comp {seeds[1]:#x})")
        dst = alloc("a", jh_len, "jedah hitbox copy") if jh_len else None
        if dst is not None:
            delta = dst - jh_start
            poke_bytes(dst, vj[jh_start:jh_start + jh_len], "jedah hitbox copy (null reloc)")
            fragments.append((dst, jh_len, "VSAV", "stage1 jedah hitbox copy"))
            # OWNERSHIP (14z-65): at stage >= 2 the passive-data pass repoints
            # these same rows to the real ported data — the scaffold repoints
            # emitted anyway and relied on last-write-wins (the op-overlap
            # assertion now forbids that). The COPY still emits so stage-2/3
            # ladder builds keep their allocator layout (and their bytes,
            # since the final row values were identical either way).
            if args.stage == 1:
                repoint("hitbox_base", seeds[0] + delta, "null reloc")
                repoint("hitbox_comp", seeds[1] + delta, "null reloc")
            else:
                notes.append("# stage-1 scaffold repoints skipped: the stage-2+ "
                             "passive-data pass owns the hitbox rows (14z-65)")

        # trampolines: dispatch_00 via hole A (re-encrypted), dispatch_01 via
        # hole B (outside the encrypted range -> stored raw)
        for tname, hole in ((("dispatch_00", "a"), ("dispatch_01", "b"))
                            if args.stage <= 3 else ()):
            a, _ = table_entry_addr(tname, dst_slot)
            target = vj_u32(a)
            tdst = alloc(hole, 6, f"{tname} trampoline")
            if tdst is None:
                continue
            code = bytes([0x4E, 0xF9]) + target.to_bytes(4, "big")  # jmp abs.l
            ops.append({"op": "code", "addr": f"{tdst:#x}", "hex": code.hex()})
            notes.append(f"code   {tdst:#08x} jmp {target:#08x}  {tname} trampoline "
                         f"(hole {hole})")
            fragments.append((tdst, 6, "GEN", f"stage1 {tname} trampoline"))
            repoint(tname, tdst, f"-> trampoline (hole {hole})")

        # ── stages 2+: Donovan regions ───────────────────────────────────────────
        placed = {}   # region name -> dest addr
        # This tenant's view, published for the engine-level union. It holds
        # LIVE references to `placed` and to this tenant's regions — `placed`
        # is a fresh dict per iteration and is filled in below, so by the time
        # the union runs (last iteration) every view, including the current
        # one, is complete. Copying here instead would publish an empty map.
        tenant_views.append({"name": T.get("name", "t%d" % _ti),
                             "regions": man.get("regions", {}),
                             "placed": placed,
                             "recon": recon,
                             "src_set": man.get("src_set")})
        if args.stage >= 2:
            regions = man["regions"]
            bank_doc = toml_loads(args.bank_map.read_text())
            src_bank_origin = _int(bank_doc["origins"][man["src_set"]])
            src_zip = args.vsavj.parent / f"{man['src_set']}.zip"
            src_data_img = load_vsavj(src_zip)  # raw data view of the source set

            def table_addr_src(tname):
                t = bank[tname]
                es = (t["span"] // 32) if t["kind"] == "byte2d" else (t["stride"] // 32)
                src_slot = _int(T["src_char"])
                return (src_bank_origin + (_int(t["vsavj"]) - VSAVJ_ORIGIN)
                        + src_slot * es)
            want = stage_regions(regions, args.stage)
            # [table_fix] (stage-gated): a ported region carrying a truncated
            # engine table grows to cover it; the blob pad + table rewrite
            # happen in the blob pass below. Must run BEFORE allocation so
            # the placement reserves the padded length.
            tf = singleton("table_fix")
            if tf and args.stage >= _int(tf.get("stage", 0)):
                tfr = regions.get(tf["region"])
                if tfr and tfr["len"] < _int(tf["pad_len"]):
                    notes.append(f"# table_fix: region {tf['region']} len "
                                 f"{tfr['len']:#x} -> {_int(tf['pad_len']):#x} "
                                 f"({tf['note']})")
                    tfr["len"] = _int(tf["pad_len"])
            # [[pcrel_escape_fix]] (14z-66): engine-style cloned regions carry
            # PC-RELATIVE word-form branches (bra/bsr/Bcc.w) escaping the
            # region — INVISIBLE to the sibling oracle (both games preserve
            # spacing, so the displacement bytes diff clean) and unrewritable
            # in place (no Bcc abs.l exists). Found when the x02592a jump-clone
            # froze mid-anim: its `bpl.w 0x271C4` kept the vs2 displacement and
            # branched into unrelated placed bytes. Reserve a trampoline pad
            # ADJACENT to the region (the branch must reach it with a word
            # displacement); the blob pass rewrites each escape to a
            # `jmp <resolved>.l` trampoline in the pad. Must run before
            # allocation so placement reserves the pad.
            pcrel_fixes = {}
            for pf in tenant_rows("pcrel_escape_fix"):
                if args.stage < _int(pf.get("stage", 4)):
                    continue
                pfr = regions.get(pf["region"])
                if pfr:
                    pcrel_fixes[pf["region"]] = pfr["len"]
                    pfr["len"] += _int(pf.get("pad", 0x120))

            # allocate every wanted region first (deterministic order: code
            # first so it stays in the encrypted hole, then data)
            hole_b_set = set(x.strip() for x in
                             T.get("hole_b_regions", "").split(",") if x)
            # region_space (M3b slice J): per-region space assignment,
            # "name=space,...". Generalises hole_b_regions, which stays working
            # and stays the frozen manifests' spelling.
            #
            # WHY IT HAS TO EXIST. Today the choice is `hole_b if listed else
            # hole_a` with no reach analysis at all, so every region lands in the
            # crypt window by default. Measured 14z-77
            # (tests/test_region_overlap.sh): one tenant already SATURATES it —
            # three tenants keeping their own copies would need 761,316 bytes of
            # hole_a's 264,544 and 171,614 of hole_b's 80,096, while wide_ext sits
            # 2,051,556 bytes empty. The merge cannot proceed until a region can
            # be told where to live, and that is a manifest tunable rather than a
            # code edit (CLAUDE.md build conventions).
            #
            # Note this does NOT decide whether a region MAY move: PC-reach is a
            # real constraint for near_map satellites and layout-group members,
            # and whether ported CODE runs from the raw extension at all is a
            # separate measurement. This key is what makes that measurable.
            region_space = {}
            for kv in str(T.get("region_space", "")).split(","):
                if kv.strip():
                    _rn, _, _sp = kv.partition("=")
                    region_space[_rn.strip()] = _sp.strip()

            def space_of(name):
                """The space a region is assigned to (default: the crypt hole)."""
                return region_space.get(name, "b" if name in hole_b_set else "a")
            # layout groups: regions that PC-reference each other must keep
            # their SOURCE-relative spacing (PC-relative displacements — both
            # direct and via word jump tables — are invisible to the oracle
            # because the sibling games preserve spacing too). Allocate the
            # whole span; recycle the inter-region gaps via gap_free.
            grouped = set()
            for grp in tenant_rows("layout_group"):
                members = [m for m in grp["regions"].split(",")
                           if m in regions and m in want]
                if not members:
                    continue
                base_src = min(regions[m]["src"] for m in members)
                span_end = max(regions[m]["src"] + regions[m]["len"]
                               for m in members)
                span = span_end - base_src
                gbase = alloc("a", span, f"layout group ({grp['regions']})")
                if gbase is None:
                    continue
                covered = sorted((regions[m]["src"] - base_src,
                                  regions[m]["src"] - base_src + regions[m]["len"])
                                 for m in members)
                pos = 0
                for cs, ce in covered:
                    if cs - pos >= 0x20:
                        gap_free.append((gbase + pos + 0xF & ~0xF, gbase + cs))
                    pos = ce
                for m in members:
                    placed[m] = gbase + (regions[m]["src"] - base_src)
                    grouped.add(m)
                    fragments.append((placed[m], regions[m]["len"], "VS2",
                                      f"donovan {m} (grouped, vsav2 0x{regions[m]['src']:06X})"))
                notes.append(f"# layout group at {gbase:#x}+{span:#x}: "
                             + ", ".join(f"{m}@{placed[m]:#x}" for m in members)
                             + f"; {sum(ge-gs for gs, ge in gap_free):#x} gap bytes recycled")
            # near_map: satellite regions that must land within d16 reach of an
            # anchor region (PC-rel table-entry rewrites) — placed after it
            near_map = {}
            for pair in T.get("near_map", "").split(","):
                if "=" in pair:
                    sat, anchor = pair.split("=")
                    near_map[sat.strip()] = anchor.strip()
            for name in sorted(want, key=lambda n: (regions[n]["kind"] != "code", n)):
                if name in grouped or name in near_map:
                    continue
                r = regions[name]
                d = alloc(space_of(name), r["len"], f"region {name}")
                if d is not None:
                    placed[name] = d
                    fragments.append((d, r["len"], "VS2",
                                      f"donovan {name} (vsav2 0x{r['src']:06X})"))
            for name, anchor in near_map.items():
                if name not in want or name not in regions:
                    continue
                r = regions[name]
                want_at = placed.get(anchor)
                if want_at is None:
                    fail.append(f"near_map: anchor {anchor} unplaced for {name}")
                    continue
                best = None
                for gi, (gs, ge) in enumerate(gap_free):
                    if ge - gs >= r["len"] and abs(gs - want_at) < 0x6000:
                        if best is None or abs(gs - want_at) < abs(gap_free[best][0] - want_at):
                            best = gi
                if best is not None:
                    gs, ge = gap_free[best]
                    placed[name] = gs
                    gap_free[best] = ((gs + r["len"] + 0xF) & ~0xF, ge)
                else:
                    # follow the ANCHOR's space: a near_map satellite must land
                    # within d16 reach of it, so allocating elsewhere can only
                    # fail the distance assertion below (loudly, which is right).
                    d = alloc(space_of(anchor), r["len"],
                              f"region {name} (near {anchor})")
                    if d is None:
                        continue
                    if abs(d - want_at) >= 0x6000:
                        fail.append(f"near_map: {name} landed {d:#x}, too far "
                                    f"from {anchor} at {want_at:#x}")
                    placed[name] = d
                if name in placed:
                    fragments.append((placed[name], r["len"], "VS2",
                                      f"donovan {name} (near {anchor}, vsav2 "
                                      f"0x{r['src']:06X})"))

            def region_of(target):
                for name, r in regions.items():
                    if r["len"] > 0 and r["src"] <= target < r["src"] + r["len"]:
                        return name
                return None

            patched_clones = {}  # target -> placed clone address

            def patched_clone_for(tgt, m, where):
                """vs2-only entry points whose vsavj "twin" is a FALSE byte-match
                (e.g. vs2 0x5C77E = the UNMASKED set-anim entry; vsavj embeds
                `andi.w #$ff,d0` mid-routine with no unmasked entry — Donovan's
                sword anim numbers 0x124-0x201 truncate through it, round-26
                sword-swing root cause). Synthesize the true equivalent: clone
                the vanilla routine bytes and apply the row's patch (old->new,
                deletion allowed), placed once in hole a."""
                if tgt not in patched_clones:
                    src = _int(m["clone_src"])
                    ln = _int(m["clone_len"])
                    body = bytearray(
                        (root / "build/out/vsavj_opcodes.bin").read_bytes()[src:src + ln])
                    old = bytes.fromhex(m["patch_old"])
                    new = bytes.fromhex(m.get("patch_new", ""))
                    i = bytes(body).find(old)
                    if i < 0 or bytes(body).find(old, i + 1) >= 0:
                        fail.append(f"{where}: patched_clone {tgt:#x}: patch_old "
                                    f"not found or not unique in clone span")
                        return None
                    body[i:i + len(old)] = new
                    cd = alloc("a", len(body), f"patched clone {tgt:#x}")
                    if cd is None:
                        return None
                    ops.append({"op": "code", "addr": f"{cd:#x}",
                                "hex": bytes(body).hex()})
                    notes.append(f"code   {cd:#08x} +{len(body):#x}  patched clone "
                                 f"of {src:#x} for vs2 {tgt:#x} ({m.get('note','')[:40]})")
                    fragments.append((cd, len(body), "GEN",
                                      f"patched clone {src:#06x} (vs2 {tgt:#06x})"))
                    patched_clones[tgt] = cd
                return patched_clones[tgt]

            tripwires = {}  # unresolved target -> planted-ILLEGAL address

            def tripwire_for(tgt, where):
                if tgt not in tripwires:
                    d = alloc("a", 2, f"tripwire {tgt:#x}")
                    if d is None:
                        return None
                    ops.append({"op": "code", "addr": f"{d:#x}", "hex": "4afc"})
                    notes.append(f"code   {d:#08x} ILLEGAL  TRIPWIRE for "
                                 f"unresolved {tgt:#x}")
                    tripwires[tgt] = d
                notes.append(f"# {where}: unresolved {tgt:#x} -> tripwire "
                             f"{tripwires[tgt]:#x}")
                return tripwires[tgt]

            # ported code assumes VIRGIN pool slots (vs2 spawns before any
            # recycling); our timeline hands it dirty ones — uninitialized
            # bytes (+5 substate, +0x3C mode, ...) then feed jump tables.
            # Wrap the mapped allocators with a zero-fill (category byte at +8
            # preserved; only HIS calls are wrapped, vanilla allocs untouched).
            alloc_wrap_set = {_int(x) for x in
                              T.get("alloc_wrap", "").split(",") if x}
            alloc_wrappers = {}

            def alloc_wrapper_for(tgt, where):
                if tgt in alloc_wrappers:
                    return alloc_wrappers[tgt]
                m = recon.get(tgt)
                if not (m and m.get("status") == "verified"):
                    fail.append(f"{where}: alloc_wrap target {tgt:#x} has no "
                                f"verified alloc mapping")
                    return None
                real = _int(m["vsavj"])
                wd = alloc("a", 44, f"alloc wrapper {tgt:#x}")
                if wd is None:
                    return None
                code = (bytes([0x4E, 0xB9]) + real.to_bytes(4, "big")  # jsr real
                        + bytes([0x67, 0x20])                          # beq.s done
                        + bytes([0x48, 0xE7, 0xC0, 0x80])              # movem.l d0-d1/a0,-(sp)
                        + bytes([0x10, 0x2C, 0x00, 0x08])              # move.b (8,A4),d0
                        + bytes([0x20, 0x4C])                          # movea.l A4,A0
                        + bytes([0x32, 0x3C, 0x00, 0x1F])              # move.w #31,d1
                        + bytes([0x42, 0x98])                          # clr.l (a0)+
                        + bytes([0x51, 0xC9, 0xFF, 0xFC])              # dbra d1,-4
                        + bytes([0x19, 0x40, 0x00, 0x08])              # move.b d0,(8,A4)
                        + bytes([0x4C, 0xDF, 0x01, 0x03])              # movem.l (sp)+
                        + bytes([0xB8, 0xFC, 0x00, 0x00])              # cmpa.w #0,A4
                        + bytes([0x4E, 0x75]))                         # rts
                ops.append({"op": "code", "addr": f"{wd:#x}", "hex": code.hex()})
                notes.append(f"code   {wd:#08x} slot-clearing alloc wrapper for "
                             f"{tgt:#x} -> {real:#x} (0x80 cleared, +8 preserved)")
                fragments.append((wd, 44, "GEN", f"alloc wrapper {tgt:#x}"))
                alloc_wrappers[tgt] = wd
                return wd

            sound_stubs = {}

            def sound_stub_for(tgt, m, where):
                """kind="sound_stub" (14z-85g): a vs2 sound-farm stub whose
                vs2 ID has no faithful same-id vsavj meaning, but whose
                SAMPLE CONTENT exists on vsavj under a different id (the
                trap-detonation precedent: vs2 0x73A == vsavj 0x199 —
                identical bytes at the same QSound address, same pitch;
                CORRECTED 14z-95/GitHub #93: identical for 20,480 of
                20,481 bytes — the INCLUSIVE endpoint 0x6C5000, which
                packing law #3 says is PLAYED, differs between the two
                games' original sample ROMs, vsav 0xFF vs vsav2 0x00.
                Content checks behind future sound_stub rows must
                include the endpoint byte).
                Synthesize the vsavj twin of the vs2 stub shape with the
                row's `sfx_id`: save-regs / move.l #id,d1 / clr d2,d3 /
                jsr helper / jmp restore. The save (0x330E) and restore
                (0x3306) pair is byte-identical at the SAME address in
                both games (verified recon rows), and the helper is the
                per-node sfx helper vsavj 0x4CE2."""
                if tgt not in sound_stubs:
                    sid = _int(m["sfx_id"])
                    # optional per-row helper override (14z-86, the voice
                    # batch): stubs whose id sits in the authored voice
                    # range must jsr the range-gated alias thunk instead
                    # of vanilla 0x4CE2 (whose +0x300 facing alias would
                    # land on a LIVE foreign row)
                    helper = _int(m.get("helper", 0x4CE2))
                    body = (bytes.fromhex("4eb90000330e")        # jsr save
                            + bytes([0x22, 0x3C]) + sid.to_bytes(4, "big")
                            + bytes.fromhex("74007600")          # clr d2,d3
                            + bytes.fromhex("4eb9")              # jsr helper
                            + helper.to_bytes(4, "big")
                            + bytes.fromhex("4ef900003306"))     # jmp restore
                    sd = alloc("a", len(body), f"sound stub {tgt:#x}")
                    if sd is None:
                        return None
                    ops.append({"op": "code", "addr": f"{sd:#x}",
                                "hex": body.hex()})
                    notes.append(f"code   {sd:#08x} sound stub for {tgt:#x} "
                                 f"(vsavj sfx id {sid:#x})")
                    fragments.append((sd, len(body), "GEN",
                                      f"sound stub {tgt:#x} id {sid:#x}"))
                    sound_stubs[tgt] = sd
                return sound_stubs[tgt]

            farm_ports = {}

            def farm_port_for(tgt, m, where):
                """vsav2-added predicate-farm entries are pure PC-relative
                (`lea (d16,PC),A3; bra.w common`) and cannot relocate as bytes.
                Synthesize the absolute equivalent: copy the 8-byte parameter
                block, then `lea <param>.l,A3; jmp <vsavj common>.l`."""
                if tgt not in farm_ports:
                    param = bytes.fromhex(m["param_hex"])
                    pd = alloc("a", len(param), f"farm param {tgt:#x}")
                    sd = alloc("a", 12, f"farm stub {tgt:#x}")
                    if pd is None or sd is None:
                        return None
                    ops.append({"op": "data", "addr": f"{pd:#x}", "hex": param.hex()})
                    stub = (bytes([0x47, 0xF9]) + pd.to_bytes(4, "big")
                            + bytes([0x4E, 0xF9]) + _int(m["common"]).to_bytes(4, "big"))
                    ops.append({"op": "code", "addr": f"{sd:#x}", "hex": stub.hex()})
                    notes.append(f"code   {sd:#08x} farm-port stub for {tgt:#x} "
                                 f"(param at {pd:#08x}, common {_int(m['common']):#x})")
                    fragments.append((sd, 12, "GEN", f"farm-port stub {tgt:#x}"))
                    farm_ports[tgt] = sd
                return farm_ports[tgt]

            def relocate_target(ref, where):
                """New vsavj address for a ref target, or None + fail note."""
                cls = ref.get("class", "internal")
                tgt = ref["target"]
                # a placed region always wins: refs whose sibling-drift delta
                # got them classified 'engine' still relocate internally when
                # the target lives inside ported/extracted code or data
                host0 = region_of(tgt)
                if host0 and host0 in placed:
                    return tgt + (placed[host0] - regions[host0]["src"])
                if cls == "internal":
                    host = region_of(tgt)
                    if host and host in placed:
                        return tgt + (placed[host] - regions[host]["src"])
                    if host:
                        fail.append(f"{where}: ref -> {tgt:#x} in region {host} "
                                    f"not placed at this stage")
                        return None
                    fail.append(f"{where}: internal ref -> {tgt:#x} outside regions")
                    return None
                if cls == "bank_ref":
                    m = recon.get(tgt)
                    if m and m.get("status") == "verified":
                        return _int(m["vsavj"])
                    # auto-verify by the bank delta rule: (a) candidate carries
                    # byte-identical content (shared constants), or (b) candidate
                    # is exactly a known bank-table base (the cross-set layout
                    # identity is the atlas's core verified fact; per-char table
                    # CONTENTS legitimately differ)
                    cand = VSAVJ_ORIGIN + (tgt - src_bank_origin)
                    if 0 <= cand < len(vj) and src_data_img[tgt:tgt + 16] == vj[cand:cand + 16]:
                        notes.append(f"# bank_ref {tgt:#x} -> {cand:#x} "
                                     f"(delta rule, 16B byte-identical)")
                        return cand
                    if any(_int(t["vsavj"]) == cand for t in bank.values()):
                        notes.append(f"# bank_ref {tgt:#x} -> {cand:#x} "
                                     f"(delta rule, known table base)")
                        return cand
                    fail.append(f"{where}: bank_ref {tgt:#x} (delta-rule candidate "
                                f"{cand:#x}) failed byte-identity — needs a "
                                f"verified reconciliation row")
                    return None
                if cls in ("engine", "pcrel16", "code_neighbor"):
                    if tgt in alloc_wrap_set:
                        return alloc_wrapper_for(tgt, where)
                    m = recon.get(tgt)
                    if m and m.get("kind") == "farm_port":
                        return farm_port_for(tgt, m, where)
                    if m and m.get("kind") == "sound_stub":
                        # profile-gated stub (14z-86, the voice batch): a
                        # row whose `profile` the build does not carry
                        # falls back to the SILENCE stub — its authored
                        # Z80 id rows and its alias thunk exist only on
                        # profile builds (a stock build jsr'ing the
                        # pinned thunk address would run off the 4MB
                        # image)
                        if m.get("profile") and m["profile"] != args.profile:
                            return 0x2A7E0
                        return sound_stub_for(tgt, m, where)
                    if m and m.get("kind") == "patched_clone":
                        return patched_clone_for(tgt, m, where)
                    ok = m and (m.get("status") == "verified"
                                or (args.allow_plausible
                                    and m.get("status") == "plausible"))
                    if ok:
                        return _int(m["vsavj"])
                    if args.tripwire_open:
                        return tripwire_for(tgt, where)
                    fail.append(f"{where}: {cls} ref {tgt:#x} unresolved "
                                f"(reconciliation row missing/unverified)")
                    return None
                fail.append(f"{where}: unknown ref class {cls} -> {tgt:#x}")
                return None

            for name in sorted(placed):
                r = regions[name]
                # extract_dir, not args.extract_dir: the blob must come from the
                # extraction of the tenant being placed (14z-78c pairing).
                blob = bytearray((extract_dir / f"region_{name}.bin").read_bytes())
                # [table_fix] pad + whole-table rewrite (see the config note in
                # donovan.toml): zero-pad the blob to the reserved length and
                # write the documented row values at the table offset.
                if (tf and tf["region"] == name
                        and args.stage >= _int(tf.get("stage", 0))):
                    rows = bytearray(bytes.fromhex(tf["rows_hex"]))
                    toff = _int(tf["table_off"])
                    if len(blob) < r["len"]:
                        blob.extend(b"\x00" * (r["len"] - len(blob)))
                    # The rows above are the VANILLA vsavj table. The tenant's own
                    # row is then written explicitly from its declared gfx bank.
                    # Until now nothing wrote a tenant row at all: the build
                    # worked only because the tenant sat in Jedah's slot, whose
                    # vanilla row (0x0F = 0x4000) already names the bank the tiles
                    # were placed in. That coincidence dies the moment the tenant
                    # moves — row 0x13's vanilla value is 0x2000 — so make it
                    # explicit rather than inherited.
                    # Slice H: a row per TENANT, not one for the build. The
                    # region is shared (all three declare x026142), so under the
                    # loop it is placed once and this one table must carry every
                    # tenant's bank word. Reading `T`/`_tenants` rather than
                    # `port["port"]` also closes the same latent trap slice E
                    # found: that dict stays `_tenants[0]` forever.
                    from gfx_tiles import bank_word as _bw
                    for _ten in (port.get("_tenants") or [T]):
                        _tid = _int(_ten["dst_slot"])
                        _tbank = _int(_ten.get("gfx_bank", 2))
                        if (_tid + 1) * 2 > len(rows):
                            fail.append(f"table_fix: tenant id {_tid:#04x} is "
                                        f"beyond the {len(rows) // 2}-row bank "
                                        f"table; the table must be widened "
                                        f"before a tenant can live there")
                            continue
                        _was = int.from_bytes(rows[_tid * 2:_tid * 2 + 2], "big")
                        rows[_tid * 2:_tid * 2 + 2] = _bw(_tbank).to_bytes(2, "big")
                        notes.append(f"# {name}+{toff + _tid * 2:#x}: bank table "
                                     f"row {_tid:#04x} <- {_bw(_tbank):#06x} "
                                     f"(bank {_tbank}, WIDE encoding; vanilla row "
                                     f"was {_was:#06x}) — tenant-driven")
                    blob[toff:toff + len(rows)] = bytes(rows)
                    notes.append(f"# {name}+{toff:#x}: table_fix {len(rows)} "
                                 f"bytes ({tf['note']})")
                # [[region_fix]] (14z-27): guarded byte patches inside an
                # extractor region blob (old-verified against the extracted
                # source bytes) — for value-level porting decisions the
                # extraction faithfully copies but the host engine needs
                # differently (e.g. hit-class remaps).
                for rf in tenant_rows("region_fix"):
                    if rf["region"] != name or args.stage < _int(rf.get("stage", 0)):
                        continue
                    roff = _int(rf["off"])
                    rold = bytes.fromhex(rf["old_hex"])
                    rnew = bytes.fromhex(rf["new_hex"])
                    if bytes(blob[roff:roff + len(rold)]) != rold:
                        fail.append(f"region_fix {name}+{roff:#x}: old bytes "
                                    f"mismatch ({bytes(blob[roff:roff+len(rold)]).hex()})")
                        continue
                    blob[roff:roff + len(rnew)] = rnew
                    notes.append(f"# {name}+{roff:#x}: region_fix "
                                 f"{rold.hex()} -> {rnew.hex()} ({rf.get('note','')})")
                for ref in r.get("refs", []):
                    if ref["width"] == 16:
                        # pcrel16 (14z-65): a PC-relative word displacement whose
                        # target drifted between the siblings — it reaches
                        # OUTSIDE its co-moving span (measured: x055478's
                        # `jmp (d16,PC)` into x057456, the regions' separation
                        # differs by the 6-byte sibling insertion). The 68k base
                        # is the extension word's own address. Rewrite the
                        # displacement against actual placement.
                        site_src = r["src"] + ref["off"]
                        disp_src = (ref["target"] ^ 0x8000) - 0x8000
                        tgt_abs = (site_src + disp_src) & 0xFFFFFF
                        host = region_of(tgt_abs)
                        if host is None or host not in placed:
                            fail.append(f"{name}+{ref['off']:#x}: pcrel16 target "
                                        f"{tgt_abs:#x} not in a placed region")
                            continue
                        new_tgt = tgt_abs + (placed[host] - regions[host]["src"])
                        new_site = placed[name] + ref["off"]
                        disp = new_tgt - new_site
                        if not (-0x8000 <= disp <= 0x7FFF):
                            fail.append(f"{name}+{ref['off']:#x}: pcrel16 "
                                        f"displacement {disp:#x} out of i16 range "
                                        f"— bring the regions closer "
                                        f"(layout_group/near_map)")
                            continue
                        blob[ref["off"]:ref["off"] + 2] = \
                            (disp & 0xFFFF).to_bytes(2, "big")
                        notes.append(f"# {name}+{ref['off']:#x}: pcrel16 -> "
                                     f"{host}@{tgt_abs:#x} (disp {disp_src:#x} -> "
                                     f"{disp & 0xFFFF:#x} after placement)")
                        continue
                    newt = relocate_target(ref, f"{name}+{ref['off']:#x}")
                    if newt is None:
                        continue
                    span = ref["width"] // 8
                    blob[ref["off"]:ref["off"] + span] = newt.to_bytes(span, "big")
                # ported code carries the source game's char id in immediates —
                # src_char there, dst_slot here (scan-confirmed sites only; the
                # literal was 0x13 until 14z-65, silently missing any other
                # tenant's sites)
                # Slice E: read the tenant from `T`, not `port["port"]`. The two
                # are the same dict today; under the loop `T` rebinds per tenant
                # while `port["port"]` stays `_tenants[0]` forever, so this blob
                # would take the FIRST tenant's ids — silently, since the ported
                # code would simply gate on the wrong character.
                src_id = _int(T["src_char"])
                _cid = _int(T["dst_slot"])
                for off in r.get("charid_sites", []):
                    if blob[off:off + 2] == bytes([0x00, src_id]):
                        blob[off:off + 2] = bytes([0x00, _cid])
                        notes.append(f"# {name}+{off:#x}: char-id imm "
                                     f"{src_id:#x} -> {_cid:#x}")
                # PC-relative escapes (word-table entries / direct d16) from
                # source-only regions: rewrite each displacement against actual
                # placement; unresolved targets -> a shared per-region tripwire
                # (within d16 reach), so an exercised-but-unported state is LOUD
                pr_trip = None
                for ref in r.get("pcrel_refs", []):
                    tgt = ref["target"]
                    host = region_of(tgt)
                    if host and host in placed:
                        resolved = tgt + (placed[host] - regions[host]["src"])
                    else:
                        if pr_trip is None:
                            # must sit within d16 reach of the region: gap-fit
                            # near the region's placement
                            want = placed[name]
                            best = None
                            for gi, (gs, ge) in enumerate(gap_free):
                                if ge - gs >= 2 and abs(gs - want) < 0x7000:
                                    if best is None or abs(gs - want) < abs(gap_free[best][0] - want):
                                        best = gi
                            if best is not None:
                                gs, ge = gap_free[best]
                                pr_trip = gs
                                gap_free[best] = ((gs + 2 + 0xF) & ~0xF, ge)
                            else:
                                pr_trip = alloc("a", 2, f"pcrel tripwire {name}")
                            if pr_trip is not None:
                                ops.append({"op": "code", "addr": f"{pr_trip:#x}",
                                            "hex": "4afc"})
                                notes.append(f"code   {pr_trip:#08x} ILLEGAL  "
                                             f"shared pcrel TRIPWIRE for {name}")
                        resolved = pr_trip
                    if resolved is None:
                        continue
                    pc_base = placed[name] + ref["base_off"]
                    disp = resolved - pc_base
                    if not (-0x8000 <= disp < 0x8000):
                        # NEAR JMP TRAMPOLINE (14z-65): a pcrel word-table entry
                        # resolving beyond d16 reach (Huitzil's copy of the
                        # per-game x088512 zone dispatches into vsavj engine
                        # code) bounces through a 6-byte jmp abs.l within reach.
                        # Only valid for CODE targets — these entries are
                        # dispatch tables; a far pcrel DATA read would need its
                        # data copied near instead (no such case yet; the
                        # trampoline jmp would fault loudly, not read wrong
                        # data). Donovan-inert: this branch was a hard fail
                        # before, so no frozen build ever reached it.
                        tr = pcrel_far_tramps.get(resolved)
                        if tr is None:
                            want = placed[name]
                            best = None
                            for gi, (gs, ge) in enumerate(gap_free):
                                if ge - gs >= 6 and abs(gs - want) < 0x7000:
                                    if best is None or abs(gs - want) < \
                                            abs(gap_free[best][0] - want):
                                        best = gi
                            if best is not None:
                                gs, ge = gap_free[best]
                                tr = gs
                                gap_free[best] = ((gs + 6 + 0xF) & ~0xF, ge)
                            else:
                                tr = alloc("a", 6, f"pcrel far trampoline {name}")
                            if tr is None:
                                fail.append(f"{name}+{ref['off']:#x}: no room "
                                            f"for a pcrel far trampoline")
                                continue
                            ops.append({"op": "code", "addr": f"{tr:#x}",
                                        "hex": "4ef9" + f"{resolved:08x}"})
                            notes.append(f"code   {tr:#08x} jmp {resolved:#08x}"
                                         f"  pcrel far trampoline ({name})")
                            fragments.append((tr, 6, "GEN",
                                              f"pcrel far trampoline ({name} -> "
                                              f"{resolved:#x})"))
                            pcrel_far_tramps[resolved] = tr
                        disp = tr - pc_base
                        if not (-0x8000 <= disp < 0x8000):
                            fail.append(f"{name}+{ref['off']:#x}: pcrel far "
                                        f"trampoline still out of d16 range "
                                        f"({disp:#x})")
                            continue
                    blob[ref["off"]:ref["off"] + 2] = \
                        (disp & 0xFFFF).to_bytes(2, "big")
                n_pr = len(r.get("pcrel_refs", []))
                if n_pr:
                    notes.append(f"# {name}: {n_pr} pcrel escape entries "
                                 f"rewritten (tripwire at "
                                 f"{pr_trip:#x})" if pr_trip else
                                 f"# {name}: {n_pr} pcrel escape entries rewritten")

                # poisoned immediates (donovan.toml [[imm_poison]]): unreachable
                # movea.l #imm operands whose target is deliberately unported —
                # repointed at a shared poison table (odd-value words) so any
                # future writer that makes the branch reachable faults loudly
                # (vec3, A0 = the poison block) instead of silently reading
                # unrelated vsavj bytes
                for ip in tenant_rows("imm_poison"):
                    if ip["region"] != name:
                        continue
                    off = _int(ip["src_addr"]) - r["src"]
                    old = _int(ip["old_imm"]).to_bytes(4, "big")
                    if not (0 <= off < r["len"]) or blob[off:off + 4] != old:
                        fail.append(f"imm_poison {ip['note']}: bytes at "
                                    f"{name}+{off:#x} != {old.hex()}")
                        continue
                    if "poison_addr" not in port:
                        pa = alloc("a", 16, "imm_poison table")
                        if pa is None:
                            continue
                        ops.append({"op": "data", "addr": f"{pa:#x}",
                                    "hex": "0001" * 8})
                        notes.append(f"data   {pa:#08x} +0x10  imm_poison table "
                                     f"(odd-entry words -> vec3 on use)")
                        fragments.append((pa, 16, "GEN", "imm_poison table"))
                        port["poison_addr"] = pa
                    blob[off:off + 4] = port["poison_addr"].to_bytes(4, "big")
                    notes.append(f"# {name}+{off:#x}: imm_poison {old.hex()} -> "
                                 f"{port['poison_addr']:#x} ({ip['note']})")

                # targeted port patches (donovan.toml [[port_patch]]): documented
                # byte edits on ported code, old bytes verified. Rows may carry
                # a minimum stage (e.g. the M2b gfx-bank patches are stage-6
                # only, keeping stage-5 builds byte-identical to the freeze).
                for pp in tenant_rows("port_patch"):
                    if pp["region"] != name:
                        continue
                    if args.stage < _int(pp.get("stage", 0)):
                        continue
                    off = _int(pp["src_addr"]) - r["src"]
                    old = bytes.fromhex(pp["old_hex"])
                    # new_hex_variant (14z-62d), by the row's OWNER (slice C).
                    _nh = row_hex(pp, "new_hex", owner_of(pp))
                    new = bytes.fromhex(_nh)
                    if not (0 <= off < r["len"]) or blob[off:off + len(old)] != old:
                        fail.append(f"port_patch {pp['note']}: bytes at "
                                    f"{name}+{off:#x} != {pp['old_hex']}")
                        continue
                    # LENGTHS MUST MATCH (GitHub #20). The write below is sized
                    # by len(new) while only len(old) bytes were VERIFIED, so a
                    # hex-count typo either clobbers unverified bytes past the
                    # checked window or leaves a tail of the old ones — and the
                    # note/atlas line records the wrong span either way (rule 4).
                    # (The bytearray does NOT resize here: the slice is sized by
                    # len(new), so the issue's "grows the region blob" mechanism
                    # is not what happens. The defect is the unverified write.)
                    if len(new) != len(old):
                        fail.append(f"port_patch {pp['note']}: new_hex is "
                                    f"{len(new)} bytes, old_hex is {len(old)} — "
                                    f"lengths must match")
                        continue
                    blob[off:off + len(new)] = new
                    notes.append(f"# {name}+{off:#x}: port_patch {pp['old_hex']} "
                                 f"-> {_nh} ({pp['note']})")

                # 14z-82: the per-tenant TYPE-NUMBER rewrite. For every frozen
                # stamp site inside THIS tenant's copy of THIS region whose
                # type this tenant renumbers, rewrite exactly the TT byte of
                # the stamp immediate. The full source span is verified first
                # (opcode + immediate + addressing words): a mismatch means a
                # prior pass touched a stamp site, which is a build error to
                # investigate, never to overwrite. Emits nothing (not even a
                # note) when the map is empty — N=1 stays byte-identical.
                for _tn, _sa, _span, _ttoff, _exp, _oty, _fm in TYPE_STAMP_WORK:
                    if _tn != T.get("name"):
                        continue
                    _soff = _sa - r["src"]
                    if not (0 <= _soff < r["len"]):
                        continue
                    _newt = TYPE_RENUMBER[(RENUMBER_SITE, _oty, _tn)]
                    if bytes(blob[_soff:_soff + _span]) != _exp:
                        fail.append(
                            f"type_renumber {name}+{_soff:#x} ({_fm} type "
                            f"{_oty}): bytes "
                            f"{bytes(blob[_soff:_soff + _span]).hex()} != "
                            f"source {_exp.hex()} — a prior pass touched a "
                            f"stamp site; investigate, do not overwrite")
                        continue
                    blob[_soff + _ttoff] = _newt
                    notes.append(f"# {name}+{_soff:#x}: type_renumber {_fm} "
                                 f"type {_oty} -> {_newt} ({_tn}'s own "
                                 f"number; site {RENUMBER_SITE:#x})")

                # 14z-85: the OWNER-TAG detour. Every frozen 59-75 stamp site
                # inside THIS tenant's copy of THIS region is replaced (both
                # family forms are exactly 6 bytes = one jsr <abs.l>) with a
                # jump to a per-(tenant, instruction) thunk that writes the
                # tenant's id into the object's tag byte (+OWNER_TAG_OFF,A4 —
                # A4 is the slot pointer at every family stamp site), then
                # executes the ORIGINAL stamp LAST (jsr/rts set no flags, so
                # the site's CCR result is reproduced exactly), then returns.
                # The stack push happens in TENANT code only — no legacy path
                # executes these sites, so the bit-exact legacy gate is
                # untouched by construction. Emits nothing when the worklist
                # is empty — N=1 stays byte-identical.
                for _tn, _sa, _span, _exp, _oty, _fm in OWNER_TAG_WORK:
                    if _tn != T.get("name"):
                        continue
                    _soff = _sa - r["src"]
                    if not (0 <= _soff < r["len"]):
                        continue
                    if bytes(blob[_soff:_soff + _span]) != _exp:
                        fail.append(
                            f"owner_tag {name}+{_soff:#x} ({_fm} type "
                            f"{_oty}): bytes "
                            f"{bytes(blob[_soff:_soff + _span]).hex()} != "
                            f"source {_exp.hex()} — a prior pass touched a "
                            f"stamp site; investigate, do not overwrite")
                        continue
                    _tk = OWNER_TAG_THUNKS.get((_tn, _exp))
                    if _tk is None:
                        _body = (bytes([0x19, 0x7C, 0x00, dst_slot & 0xFF,
                                        0x00, OWNER_TAG_OFF])  # move.b #id,(d16,A4)
                                 + _exp                        # original stamp, CCR-last
                                 + b"\x4e\x75")                # rts
                        _tk = alloc("a", len(_body),
                                    f"owner-tag thunk {_tn} {_fm}")
                        if _tk is None:
                            fail.append(f"owner_tag: no space for {_tn}'s "
                                        f"{_fm} thunk")
                            continue
                        ops.append({"op": "code", "addr": f"{_tk:#x}",
                                    "hex": _body.hex()})
                        notes.append(
                            f"code   {_tk:#08x} owner-tag thunk ({_tn} id "
                            f"{dst_slot & 0xFF:#x} -> (+{OWNER_TAG_OFF:#x},"
                            f"A4), then {_fm} {_exp.hex()}, rts)")
                        fragments.append((_tk, len(_body), "GEN",
                                          f"owner-tag thunk {_tn}"))
                        OWNER_TAG_THUNKS[(_tn, _exp)] = _tk
                    blob[_soff:_soff + 6] = b"\x4e\xb9" + _tk.to_bytes(4, "big")
                    notes.append(f"# {name}+{_soff:#x}: owner_tag {_fm} type "
                                 f"{_oty} -> jsr {_tk:#x} ({_tn} id "
                                 f"{dst_slot & 0xFF:#x})")
                    OWNER_TAG_MAP.append(
                        {"src_addr": _sa, "region": name, "tenant": _tn,
                         "type": _oty, "form": _fm, "tag": dst_slot & 0xFF,
                         "thunk": _tk, "tag_write_pc": _tk})

                # data_in_code (14z-66): a small DATA table embedded in a CODE
                # region placed in the crypt hole is stored re-encrypted, so
                # opcode fetches through it decrypt fine but runtime DATA READS
                # see garbage (the 14z-20 class in region form — found via the
                # FG capture-pose random table: draws like 0xFF over-ran every
                # victim's capture table). Each row relocates the table's
                # SOURCE-DATA-VIEW bytes to a RAW hole and reroutes the
                # region's reader through a 12-byte helper there. The only
                # supported reader shape is `lea (d16,pc),a1 + move.b
                # (a1,d0.w),d0` (8 bytes -> jsr helper + nop): lea sets no
                # flags and the helper's move.b sets NZ exactly like the
                # displaced one, so the reroute is ghost-clean.
                for dc in tenant_rows("data_in_code"):
                    if dc["region"] != name:
                        continue
                    if args.stage < _int(dc.get("stage", 4)):
                        continue
                    t_src, t_len = _int(dc["table"]), _int(dc["table_len"])
                    rd_src = _int(dc["reader"])
                    rd_off = rd_src - r["src"]
                    dold = bytes.fromhex(dc["reader_old_hex"])
                    shape = dc.get("shape", "indexed")
                    _lw = int.from_bytes(dold[0:2], "big") if len(dold) >= 2 else 0
                    _rw = int.from_bytes(dold[4:6], "big") if len(dold) == 8 else 0
                    _an = (_lw >> 9) & 7
                    # shape "indexed": lea (d16,pc),An then a read whose EA is
                    # (An,Xn.w) (mode 6, reg An) — the read op + its brief
                    # extension word are copied verbatim into the helper, so any
                    # size/index register works as long as it consumes the lea'd
                    # An.
                    # shape "postinc" (14z-69): the reader is a `move (An)+`
                    # walk that may sit ARBITRARILY FAR from the lea, in another
                    # basic block (measured: 0x3E bytes away inside a bsr
                    # subroutine), so the 8-byte jsr+nop rewrite cannot reach
                    # it. Only the POINTER needs redirecting: the 4-byte lea
                    # becomes `bsr.w helper` and the helper reloads An with the
                    # relocated table address. Same ghost-clean argument — lea
                    # sets no flags, bsr/rts set none either.
                    if shape in ("pointer", "postinc", "indexed-far"):
                        shape = "pointer"
                        if len(dold) != 4 or (_lw & 0xF1FF) != 0x41FA:
                            fail.append(f"data_in_code {dc['note']}: pointer "
                                        f"reader_old_hex must be the 4-byte "
                                        f"lea(d16,pc),An alone")
                            continue
                    # shape "pointer-inline" (14z-74, Pyron's air dive): the site
                    # is `lea (d16,pc),An` followed by a NOP the original build
                    # left there. lea.l #imm32,An is exactly those 6 bytes, so the
                    # pointer can be redirected IN PLACE — no helper, no
                    # allocation, and none of the bsr.w reach constraint that
                    # makes "pointer" fail when the near gaps are empty. Same
                    # ghost-clean argument as the other shapes: LEA and NOP both
                    # set no flags, so nothing downstream can observe the swap.
                    elif shape == "pointer-inline":
                        if (len(dold) != 6 or (_lw & 0xF1FF) != 0x41FA
                                or int.from_bytes(dold[4:6], "big") != 0x4E71):
                            fail.append(f"data_in_code {dc['note']}: "
                                        f"pointer-inline reader_old_hex must be "
                                        f"lea(d16,pc),An followed by a NOP")
                            continue
                    elif (len(dold) != 8 or (_lw & 0xF1FF) != 0x41FA
                            or (_rw & 0x0038) != 0x0030 or (_rw & 7) != _an
                            or (_rw >> 12) not in (1, 2, 3)):
                        fail.append(f"data_in_code {dc['note']}: reader_old_hex "
                                    f"must be lea(d16,pc),An + a move read via "
                                    f"(An,Xn.w)")
                        continue
                    _n = len(dold)
                    if not (0 <= rd_off < r["len"]) or blob[rd_off:rd_off + _n] != dold:
                        fail.append(f"data_in_code {dc['note']}: bytes at "
                                    f"{name}+{rd_off:#x} != reader_old_hex")
                        continue
                    disp = int.from_bytes(dold[2:4], "big", signed=True)
                    if rd_src + 2 + disp != t_src:
                        fail.append(f"data_in_code {dc['note']}: lea targets "
                                    f"{rd_src + 2 + disp:#x}, row says {t_src:#x}")
                        continue
                    tbl_bytes = src_data_img[t_src:t_src + t_len]
                    dc_hole = dc.get("hole", "b")
                    # one DATA copy per (table, len): the same stream is read
                    # from several sites (x06cac0 reads 0x6D91C from three).
                    ta = dc_tables.get((t_src, t_len))
                    if ta is None:
                        ta = alloc(dc_hole, t_len, f"data_in_code table")
                        if ta is None:
                            continue
                        dc_tables[(t_src, t_len)] = ta
                        ops.append({"op": "data", "addr": f"{ta:#x}",
                                    "hex": tbl_bytes.hex()})
                        fragments.append((ta, t_len, "VS2",
                                          f"data_in_code table ({dc['note']})"))
                    if shape == "pointer":
                        # helper: lea.l #table,An ; rts  — reached by a 4-byte
                        # bsr.w, so it must land within d16 of the SITE. Prefer
                        # a near gap, exactly like the pcrel far trampolines.
                        site = placed[name] + rd_off
                        ha = None
                        for gi, (gs, ge) in enumerate(gap_free):
                            if ge - gs >= 8 and abs(gs - site) < 0x7000:
                                ha = gs
                                gap_free[gi] = ((gs + 8 + 0xF) & ~0xF, ge)
                                break
                        if ha is None:
                            # the TABLE goes to a raw hole (data reads must see
                            # it verbatim), but the HELPER is pure code and has
                            # to be within bsr.w reach of the site — so it comes
                            # from the CRYPT hole that holds the placed regions
                            # themselves, not from the row's table hole (which
                            # defaults to "b" at 0x3EC720+, ~0x32xxxx away).
                            ha = alloc(dc.get("helper_hole", "a"), 8,
                                       "data_in_code pointer helper")
                        if ha is None:
                            continue
                        disp = ha - (site + 2)
                        if not (-0x8000 <= disp < 0x8000):
                            fail.append(f"data_in_code {dc['note']}: pointer "
                                        f"helper out of bsr.w reach ({disp:#x})")
                            continue
                        helper = ((0x41F9 | (_an << 9)).to_bytes(2, "big")
                                  + ta.to_bytes(4, "big") + bytes.fromhex("4e75"))
                        ops.append({"op": "code", "addr": f"{ha:#x}",
                                    "hex": helper.hex()})
                        blob[rd_off:rd_off + 4] = (bytes.fromhex("6100")
                                                   + (disp & 0xFFFF).to_bytes(2, "big"))
                        fragments.append((ha, 8, "GEN",
                                          f"data_in_code pointer helper "
                                          f"({dc['note']})"))
                        notes.append(f"# {name}+{rd_off:#x}: data_in_code "
                                     f"[pointer] bsr.w -> helper {ha:#08x}, "
                                     f"table {ta:#08x} (DATA view of "
                                     f"{man['src_set']} {t_src:#08x}; "
                                     f"{dc['note']})")
                        continue
                    elif shape == "pointer-inline":
                        # lea (d16,pc),An + nop  ->  lea.l #table,An  (6 bytes)
                        blob[rd_off:rd_off + 6] = (
                            (0x41F9 | (_an << 9)).to_bytes(2, "big")
                            + ta.to_bytes(4, "big"))
                        notes.append(f"# {name}+{rd_off:#x}: data_in_code "
                                     f"[pointer-inline] lea.l #{ta:#08x},a{_an} "
                                     f"in place (DATA view of {man['src_set']} "
                                     f"{t_src:#08x}; {dc['note']})")
                        continue
                    ha = alloc(dc_hole, 12, f"data_in_code helper")
                    if ha is None:
                        continue
                    helper = ((0x41F9 | (_an << 9)).to_bytes(2, "big")
                              + ta.to_bytes(4, "big")
                              + dold[4:8] + bytes.fromhex("4e75"))
                    ops.append({"op": "code", "addr": f"{ha:#x}",
                                "hex": helper.hex()})
                    blob[rd_off:rd_off + 8] = (bytes.fromhex("4eb9")
                                               + ha.to_bytes(4, "big")
                                               + bytes.fromhex("4e71"))
                    notes.append(f"# {name}+{rd_off:#x}: data_in_code reroute -> "
                                 f"helper {ha:#08x}, table {ta:#08x} (DATA view "
                                 f"of {man['src_set']} {t_src:#08x}; "
                                 f"{dc['note']})")
                    fragments.append((ha, 12, "GEN",
                                      f"data_in_code helper ({dc['note']})"))

                # pcrel_escape_fix blob pass (14z-66; see the pre-allocation
                # comment). Rewrites every word-form pcrel branch escaping the
                # ORIGINAL span to a trampoline in the pad: resolved targets
                # (another placed region, or a verified recon row) get
                # `jmp <resolved>.l`; unresolved ones get an ILLEGAL trampoline
                # under --tripwire-open (loud, attributable) and a hard fail
                # without it. Trampolines dedup per resolved target.
                if name in pcrel_fixes:
                    orig_len = pcrel_fixes[name]
                    if len(blob) < r["len"]:
                        blob.extend(b"\x00" * (r["len"] - len(blob)))
                    tramp_off = orig_len
                    tramp_of = {}
                    n_esc = n_trip = 0
                    # 14z-74 (maintainer-approved D5): the [table_fix] bank-word
                    # table is DATA, not code — but this scan treats any
                    # `0x6000`-form word as a bra.w/bsr.w and rewrites the word
                    # AFTER it to a trampoline displacement. table_fix writes that
                    # table earlier in this same loop iteration, so every row
                    # holding 0x6000 silently clobbered the row following it.
                    # Measured: Huitzil's rows 0x01/0x0A/0x0C emerged as
                    # 0074/0068/006a (garbage bank words, baked into manifests as
                    # fixed points of the bug), and Pyron's TENANT row 0x11 lost
                    # its 0x1000 -> 0x0066. Huitzil escaped only because his own
                    # row 0x10 = 0x1000 is not a branch form. Exclude the table.
                    tf_span = None
                    if (tf and tf["region"] == name
                            and args.stage >= _int(tf.get("stage", 0))):
                        _to = _int(tf["table_off"])
                        tf_span = (_to, _to + len(bytes.fromhex(tf["rows_hex"])))
                    i = 0
                    while i + 4 <= orig_len:
                        if tf_span and tf_span[0] <= i < tf_span[1]:
                            i = tf_span[1]
                            continue
                        w = int.from_bytes(blob[i:i + 2], "big")
                        if (w & 0xF000) == 0x6000 and (w & 0xFF) == 0:
                            disp = int.from_bytes(blob[i + 2:i + 4], "big")
                            if disp >= 0x8000:
                                disp -= 0x10000
                            tgt = r["src"] + i + 2 + disp
                            if not (r["src"] <= tgt < r["src"] + orig_len):
                                res = None
                                host = region_of(tgt)
                                if host and host in placed:
                                    res = tgt + (placed[host]
                                                 - regions[host]["src"])
                                else:
                                    row = recon.get(tgt)
                                    if (row and row.get("status") == "verified"
                                            and _int(row.get("vsavj", 0))):
                                        res = _int(row["vsavj"])
                                key = res if res is not None else ("trip", tgt)
                                ta = tramp_of.get(key)
                                if ta is None:
                                    if tramp_off + 6 > r["len"]:
                                        fail.append(f"pcrel_escape_fix {name}: "
                                                    f"trampoline pad overflow")
                                        break
                                    ta = tramp_off
                                    if res is not None:
                                        blob[ta:ta + 6] = (b"\x4e\xf9"
                                                           + res.to_bytes(4, "big"))
                                    elif args.tripwire_open:
                                        blob[ta:ta + 6] = b"\x4a\xfc" * 3
                                        notes.append(
                                            f"# {name}+{ta:#x}: ESCAPE TRIPWIRE "
                                            f"for unresolved pcrel target "
                                            f"{tgt:#x}")
                                        n_trip += 1
                                    else:
                                        fail.append(f"pcrel_escape_fix {name}: "
                                                    f"unresolved escape target "
                                                    f"{tgt:#x} at +{i:#x}")
                                        break
                                    tramp_of[key] = ta
                                    tramp_off += 6
                                ndisp = ta - (i + 2)
                                blob[i + 2:i + 4] = (ndisp & 0xFFFF).to_bytes(2, "big")
                                n_esc += 1
                            i += 4
                            continue
                        i += 2
                    notes.append(f"# pcrel_escape_fix {name}: {n_esc} escapes -> "
                                 f"{len(tramp_of)} trampolines ({n_trip} "
                                 f"tripwired), pad {orig_len:#x}..{r['len']:#x}")

                # M2b gfx remap (donovan.toml [gfx_remap], stage-gated): walk
                # the OBJ records in this region (tools/obj_records.py format,
                # decoded session 14) and shift main-band tile words by the
                # placement delta. Effect/low codes stay untouched (per-record
                # effect map is a later step; they render garbled, never crash
                # — tile codes cannot fault).
                gr = singleton("gfx_remap")
                if (gr and gr["region"] == name
                        and args.stage >= _int(gr.get("stage", 0))):
                    b_lo, b_hi = _int(gr["band_lo"]), _int(gr["band_hi"])
                    delta = _int(gr["delta"])
                    assert delta % 16 == 0, "gfx_remap delta must be 16-aligned"
                    # This pass runs AFTER ref relocation: in-region record
                    # pointers and coordinate-list pointers are already
                    # PLACED (dst) addresses. Scan with the dst base; a valid
                    # cptr lands inside a placed aux region.
                    base = placed[name]
                    aux_dst = [(placed[an], placed[an] + regions[an]["len"])
                               for an in placed if an.startswith("aux")]
                    seen_rec = set()
                    n_rw = 0
                    # Format-aware walk (tools/obj_records.py header doc):
                    # format 2/8 = 4-byte (tile,attr) entries, count at +4;
                    # format 0 = 2-byte tile-only entries, count at +2, one
                    # attr in the header (the char-select blink lesson).
                    # Two passes: collect entries, then rewrite — band codes
                    # get +delta; NON-band codes (shared-effect art the main
                    # objects draw at their own bank — the residual-blink
                    # class, playtest round 5) get shelf-packed rectangle
                    # targets in the freed Jedah-band tail [eff_lo, eff_hi],
                    # emitted as effect_map.json for the tile placement step.
                    def _entries(o):
                        fmt = int.from_bytes(blob[o:o + 2], "big")
                        cptr = int.from_bytes(blob[o + 6:o + 10], "big")
                        if (fmt > 0x20 or fmt % 2
                                or not any(lo <= cptr < hi
                                           for lo, hi in aux_dst)):
                            return None
                        if fmt == 0:
                            # subq #1 before dbra: entries = COUNT (session
                            # 14b corruption catch — count+1 clobbers the
                            # next record's format word via the effect map)
                            count = int.from_bytes(blob[o + 2:o + 4], "big")
                            if not (0 < count <= 0x100):
                                return None
                            attr = int.from_bytes(blob[o + 4:o + 6], "big")
                            return [(o + 10 + 2 * k, attr)
                                    for k in range(count)]
                        budget = int.from_bytes(blob[o + 2:o + 4], "big")
                        count = int.from_bytes(blob[o + 4:o + 6], "big")
                        if not (0 < count + 1 <= budget <= 0x100):
                            return None
                        return [(o + 10 + 4 * k, None) for k in range(count + 1)]

                    collected = []
                    for i in range(0, r["len"] - 4, 2):
                        v = int.from_bytes(blob[i:i + 4], "big")
                        if not (base <= v < base + r["len"]) or v in seen_rec:
                            continue
                        ent = _entries(v - base)
                        if ent is None:
                            continue
                        seen_rec.add(v)
                        collected.append(ent)
                    # sweep pass (14z-11, mirrors obj_records.walk): offset-
                    # computed records (the aux-chain X-ray overlays) have no
                    # in-region pointer — scan every even offset as a head
                    # with the same validation so their band words remap too.
                    for i in range(0, r["len"] - 10, 2):
                        v = base + i
                        if v in seen_rec:
                            continue
                        ent = _entries(i)
                        if ent is None:
                            continue
                        # sweep-only strictness (mirrors obj_records):
                        # small pieces, modest budget, band-coherent entries
                        if int.from_bytes(blob[i:i + 2], "big") != 0:
                            if int.from_bytes(blob[i + 2:i + 4], "big") > 0x40:
                                continue
                        _codes = []
                        _ok = True
                        for _toff, _ha in ent:
                            _t = int.from_bytes(blob[_toff:_toff + 2], "big")
                            _a = (_ha if _ha is not None else
                                  int.from_bytes(blob[_toff + 2:_toff + 4],
                                                 "big"))
                            if max(attr_block(_a)) > 8:
                                _ok = False
                                break
                            _codes.append(_t)
                        if not _ok or not _codes:
                            continue
                        if sum(1 for _t in _codes
                               if 0x8000 <= _t <= 0xEEBB) * 2 < len(_codes):
                            continue
                        seen_rec.add(v)
                        collected.append(ent)

                    # session 14z-10: PROTECTED-TILE POLICY. Vanilla content
                    # references tile positions inside the "Jedah band" window
                    # (manifest protected_tiles.json, runtime-audited: the VS
                    # curtain c625, the 0xE4xx-0xE8xx shared block, round-UI
                    # codes — the round-27..29 garble class). One rectangle
                    # first-fit allocator over the hole-punched pool serves
                    # BOTH the effect shelf AND band blocks whose remapped
                    # span would land on a protected position. Blocks never
                    # cross a 16-column row (measured invariant, preserved).
                    eff_lo, eff_hi = _int(gr["eff_lo"]), _int(gr["eff_hi"])
                    prot_doc = json.loads(
                        (root / "build/manifest/protected_tiles.json").read_text())
                    protected = {int(x, 16) for x in prot_doc["protected"]}
                    pool_ranges = [(int(a, 16), int(b, 16))
                                   for a, b in prot_doc["pool"]]
                    free = set()
                    for a_, b_ in pool_ranges:
                        free.update(range(a_, b_))
                    free -= protected
                    # effect_tail.json bank2 placements (Anita feet) live in
                    # the same code space — their spans are not free
                    _et = json.loads((root / "build/manifest/effect_tail.json"
                                      ).read_text())
                    for _k, _v in _et.get("bank2_place", {}).items():
                        _c, _bx, _by = _k.split(",")
                        _h = int(_v, 16)
                        for _dy in range(int(_by)):
                            for _dx in range(int(_bx)):
                                free.discard(cell_at(_h, _dx, _dy))

                    def span_of(head, bx, by):
                        return [cell_at(head, dx, dy)
                                for dy in range(by) for dx in range(bx)]

                    def fit_block(bx, by):
                        for a_, b_ in pool_ranges:
                            for p in range(a_, b_):
                                if (p & 0xF) + bx > 16:
                                    continue
                                cells = span_of(p, bx, by)
                                if any(c not in free for c in cells):
                                    continue
                                for c in cells:
                                    free.discard(c)
                                return p
                        return None

                    blocks = {}
                    nonexc_band_srcs = set()
                    for ent in collected:
                        for toff, hdr_attr in ent:
                            t = int.from_bytes(blob[toff:toff + 2], "big")
                            a = (hdr_attr if hdr_attr is not None else
                                 int.from_bytes(blob[toff + 2:toff + 4], "big"))
                            bx, by = attr_block(a)
                            if b_lo <= t <= b_hi:
                                if any(c in protected
                                       for c in span_of(t + delta, bx, by)):
                                    blocks.setdefault((t, bx, by, True), None)
                                else:
                                    nonexc_band_srcs.update(span_of(t, bx, by))
                                    # their delta targets WILL be written by
                                    # the band loop — never allocate there
                                    # (the pool in the manifest is static;
                                    # the sweep grows the inventory)
                                    for c in span_of(t + delta, bx, by):
                                        free.discard(c)
                            else:
                                blocks.setdefault((t, bx, by, False), None)
                    for key in sorted(blocks,
                                      key=lambda k: (-k[2], -k[1], k[0])):
                        t, bx, by, _isb = key
                        nt = fit_block(bx, by)
                        if nt is None:
                            fail.append(f"gfx_remap: protected-pool overflow "
                                        f"placing block {t:#x} {bx}x{by}")
                            continue
                        blocks[key] = nt

                    n_eff = 0
                    n_exc = 0
                    for ent in collected:
                        for toff, hdr_attr in ent:
                            t = int.from_bytes(blob[toff:toff + 2], "big")
                            a = (hdr_attr if hdr_attr is not None else
                                 int.from_bytes(blob[toff + 2:toff + 4], "big"))
                            bx, by = attr_block(a)
                            if b_lo <= t <= b_hi:
                                nt = blocks.get((t, bx, by, True))
                                if nt is not None:
                                    blob[toff:toff + 2] = nt.to_bytes(2, "big")
                                    n_exc += 1
                                else:
                                    blob[toff:toff + 2] = (t + delta).to_bytes(
                                        2, "big")
                                    n_rw += 1
                            else:
                                nt = blocks.get((t, bx, by, False))
                                if nt is not None:
                                    blob[toff:toff + 2] = nt.to_bytes(2, "big")
                                    n_eff += 1
                    pairs = []
                    exc_srcs = set()
                    for (t, bx, by, isb), nt in blocks.items():
                        if nt is None:
                            continue
                        src_span = span_of(t, bx, by)
                        dst_span = span_of(nt, bx, by)
                        pairs.extend([s, d] for s, d in zip(src_span, dst_span))
                        if isb:
                            exc_srcs.update(src_span)
                    write_out(side_name("effect_map.json"),
                              json.dumps(pairs).encode(), "gfx_remap")
                    # band srcs relocated by exception AND not otherwise needed
                    # at src+delta must be skipped by build_gfx's band loop
                    # (their delta target is a protected position!)
                    skip = sorted(exc_srcs - nonexc_band_srcs)
                    write_out(side_name("tile_exceptions.json"),
                              json.dumps({"skip_band_src": skip}).encode(),
                              "gfx_remap")
                    notes.append(f"# {name}: gfx_remap +{delta:#x} on {n_rw} "
                                 f"band tile words, {n_exc} exception words, "
                                 f"{n_eff} effect words ({len(blocks)} blocks "
                                 f"pooled; {len(skip)} band srcs skipped; "
                                 f"{len(protected)} protected) in "
                                 f"{len(seen_rec)} records")

                # [effect_tail] (build/manifest/effect_tail.json, session 14j):
                # the x2b7ef4 companion-effect records draw at BANK 1; the
                # engine effect page shifted (+0x47 class relocs) and vs2's
                # elemental-sword band (0x0E17-0x0F02) has no vsav home —
                # placed at the padding run 0x3640+. Per-block code remap.
                if name == "x2b7ef4" and args.stage >= 6:
                    et = json.loads((Path(__file__).resolve().parent.parent
                                     / "build/manifest/effect_tail.json"
                                     ).read_text())
                    bmap = {}
                    for k, d_ in et["reloc"].items():
                        tt, bx, by = k.split(",")
                        bmap[(int(tt, 16), int(bx), int(by))] = int(tt, 16) + d_
                    for k, v in et["place"].items():
                        tt, bx, by = k.split(",")
                        bmap[(int(tt, 16), int(bx), int(by))] = int(v, 16)
                    base = placed[name]
                    # The records' coordinate lists live in vs2's GLOBAL
                    # coordinate pool (0x30xxxx) — same-value across the
                    # sibling pair, so the diff never relocated them (the
                    # classic sibling-coincidence gotcha; latent since M2a:
                    # these companion-effect entries have been reading X/Y
                    # from unrelated vsavj bytes). Fix: content-match each
                    # list into VSAVJ's own pool; Donovan-specific lists are
                    # appended to a GEN fragment in hole B.
                    POOL_LO, POOL_HI = 0x300000, 0x361000
                    # bank-2-attributed records (sword/statue class, session
                    # 14k-b): drawn by #\$4000-patched objects — their entries
                    # use the BAND-TAIL placements (vs2 bank-3 content), not
                    # the bank-1 maps. Keyed by SOURCE record address.
                    # 14z-67: band-tail placements exist only for a tenant
                    # with a [gfx_remap] band (Donovan). A delta-0 tenant
                    # (H/P) has no band tail and never draws these records
                    # (they are the DONOVAN companions' art riding in the
                    # shared region) — skip the b2 rewrite so no effect_map
                    # is fabricated for a build that places no shelf.
                    b2_recs = ({int(x, 16) for x in et.get("bank2_recs", [])}
                               if singleton("gfx_remap") else set())
                    # 14z-67 (ping #7: the fuchsia-explosion / missing-ray /
                    # missing-electricity class): 2,007 of the 5,714 bank-1
                    # tiles these records reference are NOT byte-identical in
                    # vsav's effect page, and effect_tail's Donovan-era maps
                    # cover only 385 of them. On a delta-0 GROUP-C tenant the
                    # clean fix is bank 5: keep every tile word NATIVE (skip
                    # the bmap rewrite entirely), emit the full referenced
                    # bank-1 code list as effect_c5.json (build_gfx places
                    # the art at native codes in group C's upper bank), and
                    # flip the ported piece-spawner setters #$2000 -> #$3000
                    # (manifest port_patch rows — tenant-only by
                    # construction: only ported content reaches them).
                    c5_mode = (not singleton("gfx_remap")
                               and _int(T.get("gfx_bank", 2)) >= 4)
                    c5_tiles = set()
                    b2map = {}
                    for k, v_ in et.get("bank2_place", {}).items():
                        tt, bx, by = k.split(",")
                        b2map[(int(tt, 16), int(bx), int(by))] = int(v_, 16)
                    b2_pairs = []
                    extra_lists = bytearray()
                    extra_map = {}
                    n_et = n_b2 = n_cfix = n_cport = 0
                    seen2 = set()
                    for i in range(0, r["len"] - 4, 2):
                        v = int.from_bytes(blob[i:i + 4], "big")
                        if not (base <= v < base + r["len"]) or v in seen2:
                            continue
                        o = v - base
                        fmt = int.from_bytes(blob[o:o + 2], "big")
                        cptr = int.from_bytes(blob[o + 6:o + 10], "big")
                        if (fmt > 0x20 or fmt % 2
                                or not (POOL_LO <= cptr < POOL_HI)):
                            continue
                        if fmt == 0:
                            cnt = int.from_bytes(blob[o + 2:o + 4], "big")
                            if not (0 < cnt <= 0x100):
                                continue
                            hdr_at = int.from_bytes(blob[o + 4:o + 6], "big")
                            offs = [(o + 10 + 2 * k, hdr_at) for k in range(cnt)]
                            npairs = cnt
                        elif fmt in (2, 8):
                            budget = int.from_bytes(blob[o + 2:o + 4], "big")
                            cnt = int.from_bytes(blob[o + 4:o + 6], "big")
                            if not (0 < cnt + 1 <= budget <= 0x100):
                                continue
                            offs = [(o + 10 + 4 * k, None) for k in range(cnt + 1)]
                            npairs = cnt + 1
                        else:
                            continue
                        seen2.add(v)
                        src_v = v - base + r["src"]
                        is_b2 = src_v in b2_recs
                        # coordinate-list fixup
                        lst = src_data_img[cptr:cptr + 4 * npairs]
                        hit = vj.find(bytes(lst), 0x300000, 0x361000)
                        if hit != -1:
                            blob[o + 6:o + 10] = hit.to_bytes(4, "big")
                            n_cfix += 1
                        else:
                            key2 = bytes(lst)
                            if key2 not in extra_map:
                                extra_map[key2] = len(extra_lists)
                                extra_lists += lst
                            blob[o + 6:o + 10] = (0xEE000000
                                                  + extra_map[key2]).to_bytes(
                                                      4, "big")
                            n_cport += 1
                        for toff, hdr_at in offs:
                            t = int.from_bytes(blob[toff:toff + 2], "big")
                            a_ = (hdr_at if hdr_at is not None else
                                  int.from_bytes(blob[toff + 2:toff + 4], "big"))
                            key = (t, *attr_block(a_))
                            if is_b2:
                                nt = b2map.get(key)
                                if nt is not None:
                                    blob[toff:toff + 2] = nt.to_bytes(2, "big")
                                    n_b2 += 1
                                    bx2, by2 = key[1], key[2]
                                    for dy in range(by2):
                                        for dx in range(bx2):
                                            b2_pairs.append([
                                                cell_at(t, dx, dy),
                                                cell_at(nt, dx, dy)])
                                continue
                            if c5_mode:
                                # native codes kept; art follows to bank 5
                                if t < 0x10000:
                                    bx5, by5 = key[1], key[2]
                                    for dy in range(by5):
                                        for dx in range(bx5):
                                            c5_tiles.add(
                                                cell_at(t, dx, dy))
                                continue
                            nt = bmap.get(key)
                            if nt is not None:
                                blob[toff:toff + 2] = nt.to_bytes(2, "big")
                                n_et += 1
                    if extra_lists:
                        la = alloc("b", len(extra_lists),
                                   "companion-effect coordinate lists")
                        _efl = write_out(side_name("effect_lists.bin"),
                                         extra_lists, "effect lists")
                        ops.append({"op": "data_file", "addr": f"{la:#x}",
                                    "path": _efl})
                        fragments.append((la, len(extra_lists), "VS2",
                                          "companion-effect coord lists"))
                        # resolve the 0xEE-tagged placeholders
                        for i in range(0, r["len"] - 4, 2):
                            vv = int.from_bytes(blob[i:i + 4], "big")
                            if (vv >> 24) == 0xEE:
                                blob[i:i + 4] = (la + (vv & 0xFFFFFF)).to_bytes(
                                    4, "big")
                    if b2_pairs:
                        # only reachable with [gfx_remap] present (b2_recs
                        # gating above), whose pass wrote effect_map.json
                        emj = json.loads((out / side_name("effect_map.json")).read_text())
                        known = {tuple(p) for p in emj}
                        for p in b2_pairs:
                            if (p[0], p[1]) not in known:
                                emj.append(p)
                                known.add((p[0], p[1]))
                        _written.pop(side_name("effect_map.json"), None)
                        write_out(side_name("effect_map.json"),
                                  json.dumps(emj).encode(), "b2_pairs")
                    if c5_mode:
                        write_out(side_name("effect_c5.json"),
                            json.dumps(sorted(c5_tiles)))
                        notes.append(f"# {name}: effect-c5 — {len(c5_tiles)} "
                                     f"bank-1 codes kept NATIVE (art -> group C "
                                     f"bank 5); {n_cfix} coord lists matched, "
                                     f"{n_cport} ported "
                                     f"({len(extra_lists)}B fragment)")
                        if len(c5_tiles) < 1000 or (n_cfix + n_cport) < 100:
                            fail.append(f"effect-c5: {len(c5_tiles)} codes / "
                                        f"{n_cfix + n_cport} coord lists — "
                                        f"below expectation, walker drifted")
                    else:
                        notes.append(f"# {name}: effect_tail — {n_et} bank-1 "
                                     f"words, {n_b2} bank-2 words (tail "
                                     f"placements), {n_cfix} coord lists "
                                     f"matched, {n_cport} ported "
                                     f"({len(extra_lists)}B fragment)")
                        if n_et < 100 or (n_cfix + n_cport) < 100:
                            fail.append(f"effect_tail: {n_et} tile words / "
                                        f"{n_cfix + n_cport} coord lists — "
                                        f"below expectation, walker drifted")
                    if singleton("gfx_remap") and n_rw < 10000:
                        fail.append(f"gfx_remap: only {n_rw} tile words rewritten "
                                    f"(expected ~14k) — walker or band drifted")
                d = placed[name]
                op = "code_file" if r["kind"] == "code" else "data_file"
                raw_from = r.get("raw_from")
                if raw_from is not None and 0 < raw_from < len(blob):
                    # 14z-69i: the region's own pc-relative DATA TABLES live in
                    # the forced tail. Emitting them inside the code op stores
                    # them ENCRYPTED, and CPS-2 decrypts opcode fetches only —
                    # so the machine's runtime data reads saw garbage (measured:
                    # 7/7 pointers, x06cac0). Split the emission: code up to the
                    # first table, raw data from there. The pointers themselves
                    # need no rewriting — inside the region they already resolve
                    # to the right address.
                    head = write_out(side_name(f"fixed_{name}.bin"),
                                     blob[:raw_from], f"region {name}")
                    ops.append({"op": op, "addr": f"{d:#x}", "path": head})
                    notes.append(f"{op:9s} {d:#08x} +{raw_from:#x}  donovan "
                                 f"{name} code (from vsav2 0x{r['src']:06X})")
                    tail_name = side_name(f"fixed_{name}_tables.bin")
                    # from the SOURCE DATA IMAGE, not from `blob`: blob holds the
                    # region's OPCODE-view (plaintext) content, but an (An)-based
                    # read is a DATA-space read and returns the raw stored bytes
                    # (docs/platform/gotchas.md "PC-relative reads are
                    # PROGRAM-space; (An)-based reads are DATA-space"). To make
                    # the copy read like vs2's original, store vs2's raw bytes.
                    # Safe for this span by construction: it is the forced tail,
                    # a dead zone, so no pointer fixups were applied to it.
                    write_out(tail_name,
                              src_data_img[r["src"] + raw_from:
                                           r["src"] + r["len"]],
                              f"region {name} tables")
                    ops.append({"op": "data_file", "addr": f"{d + raw_from:#x}",
                                "path": tail_name})
                    notes.append(f"data_file {d + raw_from:#08x} "
                                 f"+{len(blob) - raw_from:#x}  donovan {name} "
                                 f"RAW TABLES (unencrypted; vs2 "
                                 f"0x{r['src'] + raw_from:06X})")
                    fragments.append((d + raw_from, len(blob) - raw_from, "VS2",
                                      f"{name} raw pc-rel data tables"))
                else:
                    fixed = write_out(side_name(f"fixed_{name}.bin"), blob,
                                      f"region {name}")
                    ops.append({"op": op, "addr": f"{d:#x}", "path": fixed})
                    notes.append(f"{op:9s} {d:#08x} +{r['len']:#x}  donovan {name} "
                                 f"(from vsav2 0x{r['src']:06X})")

            # [palette] (stage-gated): place the character's sprite-palette
            # block (all confirm-button variants) raw in hole B and repoint
            # the engine's per-char palette pointer table row (slot 0x0F —
            # replaced-slot content, superset-clean). Decoded session 14:
            # uploader vsavj 0x1C3FE (vs2 twin 0x1AE6E), table indexed by
            # the pre-scaled char id, 12 rows to palette RAM 0x90C140.
            # `[palette]` may be a singleton OR a list, so it takes the
            # iteration gate in both shapes rather than through rows().
            pals = port.get("palette")
            if isinstance(pals, dict):
                pals = [pals]
            for pal in [p for p in (pals or []) if row_here(p)]:
                if args.stage < _int(pal.get("stage", 0)):
                    continue
                psrc, plen = _int(pal["src"]), _int(pal["len"])
                pname = pal.get("name", "sprite")
                pblock = bytes(src_data_img[psrc:psrc + plen])
                expect = bytes.fromhex(pal["src_head_hex"])
                if pblock[:len(expect)] != expect:
                    fail.append(f"palette {pname}: src block head at {psrc:#x} "
                                f"!= {pal['src_head_hex']} (image drift?)")
                    continue
                pa = alloc(pal.get("hole", "b"), plen, f"{pname} palette block")
                if pa is None:
                    fail.append(f"palette {pname}: no room")
                    continue
                fn = write_out(side_name(f"palette_block_{pname}.bin"), pblock,
                               f"palette {pname}")
                ops.append({"op": "data_file", "addr": f"{pa:#x}", "path": fn})
                fragments.append((pa, plen, "VS2", f"{pname} palette block"))
                # The row FOLLOWS THE TENANT (14z-62c — the manifest used to
                # hardcode row 0x0F, so a variant-id build silently repointed
                # JEDAH's palette row: replay-11 RAM diff caught his cached
                # block pointer at $FFB8C1 holding the ported address, and his
                # match palettes/fades diverging from vanilla). extra_tables is
                # the hand-rolled 0x1F MIRROR (0x38C258 == 0x38C218 + 0x40 —
                # measured, NOT a separate table); a variant-id tenant has no
                # mirror, so extras are emitted only on the base half.
                if "row" in pal:
                    fail.append(f"palette {pname}: the manifest declares a fixed "
                                f"'row' — the row follows the tenant now "
                                f"(14z-62c); delete the key")
                    continue
                # Slice D: the row is the OWNING tenant's, not the build's.
                prow, _pvar, _pmir = row_ident(owner_of(pal))
                if prow >= 0x10:
                    ta = _int(pal["table"]) + 4 * prow
                    aa = _int(pal["table"]) + 4 * (prow & 0x0F)
                    if vj_u32(ta) != vj_u32(aa):
                        fail.append(f"palette {pname}: variant row {ta:#x} does "
                                    f"not alias its base-half counterpart — "
                                    f"table shape moved")
                        continue
                tables = [_int(pal["table"])]
                if prow < 0x10:
                    tables += [_int(x) for x in
                               str(pal.get("extra_tables", "")).split(",") if x]
                for tb in tables:
                    ta = tb + 4 * prow
                    ops.append({"op": "poke32", "addr": f"{ta:#x}",
                                "val": f"{pa:#010x}"})
                    notes.append(f"data     {pa:#08x} +{plen:#x}  {pname} "
                                 f"palette block (vsav2 0x{psrc:06X}); poke32 "
                                 f"{ta:#08x} (table {tb:#x} row {prow:#x})")

            # per-char value rows -> vsavj slot 0x0F rows
            # param32_a/b (movement velocity pairs) are NOT ported BY DEFAULT
            # (session 14w-b): with Donovan's true vs2 velocities his
            # 21_don_mash soak crashes at ~10050 (correct movement reaches a
            # state with a broken pointer — return address into anim data;
            # separate landmine, queued). He has played every clean round at
            # Jedah's speeds; keep that until the crash path is decoded. The
            # addressing fix (rec8 pairs) stays — it is what protects
            # FELICIA's walk-back from the old mis-stride write.
            # 14z-66: the skip became a PER-TENANT default (port_param32 in
            # [[tenant]]): the 14w-b crash is a Donovan-port landmine, not a
            # property of velocity porting — Huitzil opts in after his own
            # soak battery re-examined the hazard (playtest round-1 item 2:
            # he moved at the row-0x10 ALIAS content = Bulleta's speeds).
            # Donovan's manifest carries no flag -> his bytes are unchanged.
            VALUE_SKIP = set() if T.get("port_param32", False) \
                else {"param32_a", "param32_b", "jump_params"}
            # Explicit-ownership claims (14z-65): a [[sound_table]] row that WILL
            # emit repoints its ptr_table row ITSELF (the measured, id-allowlisted
            # port). The generic value-row repoint below must not also write that
            # row: on WIDE builds both wrote tail_data_ptr[tenant] (0x0BF466) and
            # the shipped bytes were correct only because the sound op was emitted
            # later — silent last-write-wins, found by the 14z-65 overlap audit.
            # Claims use the sound_table section's EXACT gating, so a stock build
            # (sound_table skipped there) keeps the generic repoint unchanged.
            claimed_ptr_tables = {
                _int(st["ptr_table"]): f"sound_table {st['name']}"
                for st in (tenant_rows("sound_table") if args.stage >= 6 else [])
                if args.stage >= _int(st.get("stage", 0))
                and not (st.get("profile") and st["profile"] != args.profile)
            }
            for v in man["values"]:
                if v["table"] in VALUE_SKIP:
                    notes.append(f"# {v['table']}: velocity pair NOT ported "
                                 f"(14w-b crash guard; Jedah speeds retained)")
                    continue
                t = bank[v["table"]]
                a, es = table_entry_addr(v["table"], dst_slot)
                if v["kind"] in ("data_ptr", "code_ptr"):
                    owner = claimed_ptr_tables.get(_int(t["vsavj"]))
                    if owner:
                        notes.append(f"# {v['table']}: ptr row owned by {owner} "
                                     f"— generic repoint suppressed (14z-65)")
                        continue
                    ptr = _int(v["ptr"])
                    host = region_of(ptr)
                    if host is None:
                        fail.append(f"{v['table']}: ptr {ptr:#x} outside all regions")
                    elif host in placed:
                        repoint(v["table"], ptr + (placed[host] - regions[host]["src"]),
                                f"donovan {host}")
                    else:
                        notes.append(f"# {v['table']}: region {host} not placed at "
                                     f"stage {args.stage} — repoint deferred")
                    continue
                data = bytes.fromhex(v["value"])
                poke_bytes(a, data, f"{v['table']}[{dst_slot:#x}] value")
                # value-table variant rows are dead data in vanilla (variant ids
                # resolve to base slots except 0x18), not aliases — poke
                # unconditionally so any 5-bit-indexed path sees Donovan's value
                if mirror:
                    av, _ = table_entry_addr(v["table"], var_slot)
                    poke_bytes(av, data, f"{v['table']}[{var_slot:#x}] mirror")
            # oracle-classified gap value tables
            # GAP TABLES DISABLED (session 14w): the auto_tables "gap"
            # heuristic assumed untyped gaps between per-char tables were
            # more per-char rows and wrote slot-0x0F "values" + 0x1F "dark
            # mirrors" into them. They are JUMP-PHYSICS PARAMETER tables
            # (index 0x1F = the wall-jump-back velocity — vanilla
            # 0xFFFF4800 became 0xFFFFEC00 and broke Felicia's triangle
            # jump in pure legacy matches, playtest rounds 18/19; found by
            # per-op restore bisection). 31 of the 42 gap writes changed
            # vanilla engine bytes with unverified semantics. NOTHING may
            # be written to a gap without a decoded consumer. Donovan's
            # own physics come from his ported regions, not these rows.
            for a_t in (man["auto_tables"] if False else []):
                if a_t["verdict"] == "pointers":
                    # per-entry union semantics: a ROM-plausible entry hosted by
                    # an extracted region repoints; anything else copies verbatim
                    t = bank[a_t["table"]]
                    a, es = table_entry_addr(a_t["table"], dst_slot)
                    raw = bytes.fromhex(a_t["entry_guess"]) if "entry_guess" in a_t \
                        else None
                    if raw is None:
                        sa = table_addr_src(a_t["table"])
                        raw = src_data_img[sa:sa + es]
                    v = int.from_bytes(raw, "big")
                    host = region_of(v) if v < 0x400000 else None
                    if host and host in placed:
                        repoint(a_t["table"], v + (placed[host] - regions[host]["src"]),
                                f"gap ptr -> donovan {host}")
                    else:
                        poke_bytes(a, raw, f"{a_t['table']}[{dst_slot:#x}] gap "
                                   f"entry (verbatim)")
                        if mirror:
                            av, _ = table_entry_addr(a_t["table"], var_slot)
                            poke_bytes(av, raw, f"{a_t['table']}[{var_slot:#x}] mirror")
                    continue
                if a_t["verdict"] != "values":
                    notes.append(f"# gap table {a_t['table']}: {a_t['verdict']} — "
                                 f"NOT ported (needs consumer disasm)")
                    continue
                t = bank[a_t["table"]]
                a, es = table_entry_addr(a_t["table"], dst_slot)
                data = bytes.fromhex(a_t["entry_guess"])
                poke_bytes(a, data, f"{a_t['table']}[{dst_slot:#x}] gap value")
                if mirror:
                    av, _ = table_entry_addr(a_t["table"], var_slot)
                    poke_bytes(av, data, f"{a_t['table']}[{var_slot:#x}] mirror")

        # ── engine_dispatch rows (14z-65): out-of-window dispatch rows were
        # assumed vanilla-alias-correct — measured WRONG for Huitzil:
        # dispatch_07 is per-char even in engine space (his 0x23AFE vs
        # Bulleta's 0x2D68E), so the vanilla row-0x10 alias served BULLETA's
        # substate dispatcher — one link of the specials-never-trigger chain.
        # Rule: when the SOURCE game's row for src_char differs from its row
        # for the alias char (dst_slot & 0x0F), the alias is wrong — repoint
        # the tenant's row at the recon-verified vsavj twin. Donovan-inert
        # (measured: all his engine_dispatch rows equal their alias rows).
        if args.stage >= 4:
            def _src_u32(a):
                return int.from_bytes(src_data_img[a:a + 4], "big")
            for e in man.get("engine_dispatch", []):
                tn = e["table"]
                t = bank[tn]
                es = (t["span"] // 32) if t["kind"] == "byte2d" else (t["stride"] // 32)
                base_src = src_bank_origin + (_int(t["vsavj"]) - VSAVJ_ORIGIN)
                own = _src_u32(base_src + _int(T["src_char"]) * es)
                alias = _src_u32(base_src + (dst_slot & 0x0F) * es)
                if own == alias:
                    continue
                m_ = recon.get(own)
                ok = m_ and (m_.get("status") == "verified"
                             or (args.allow_plausible
                                 and m_.get("status") == "plausible"))
                if not ok:
                    fail.append(f"engine_dispatch {tn}: the tenant's row "
                                f"{own:#x} differs from the alias char's "
                                f"{alias:#x} — needs a verified reconciliation "
                                f"row (the vanilla alias serves the WRONG "
                                f"handler)")
                    continue
                repoint(tn, _int(m_["vsavj"]),
                        f"engine twin of {own:#x} (alias char row {alias:#x} "
                        f"differs)")

        # THE ENGINE-LEVEL UNION (14z-80f). Every tenant's manifest declares
        # these rows identically, so merge_manifests dedups them to one — and
        # the table built below resolves each ported handler through the
        # tenant that PLACED it, which is why this runs via engine_rows() on
        # the LAST iteration and resolves through resolve_ported() /
        # resolve_recon() rather than this iteration's `placed`/`recon`.
        #
        # WHAT IT COST TO GET WRONG, measured on the 3-tenant build before the
        # fix: 15 extra types fell to tripwires and TWELVE were Huitzil's
        # (types 64-75), so every one of his secondary objects would have
        # dispatched to a planted ILLEGAL the moment it spawned.
        for ph in (engine_rows("obj_hook") if args.stage >= 4 else []):
            site = _int(ph["site"])
            vtab = _int(ph["vanilla_table"])
            n_van = _int(ph["vanilla_entries"])
            stab = _int(ph["src_table"])
            n_src = _int(ph["src_entries"])
            # engine-site safety: the bytes we replace must be exactly the
            # expected dispatch sequence (movea.l (d8,PC,D0.w),A0; moveq; jsr)
            vj_pt_site = None  # site is in plaintext space; compare via opcodes view
            expect = bytes.fromhex("207b001270004e90")
            # patch_prg works on stored words; for the check we use the decrypted
            # analysis image if available, else trust the config (test gate covers)
            opc = root / "build/out/vsavj_opcodes.bin"
            if opc.is_file():
                got = open(opc, "rb").read()[site:site + 8]
                if got != expect:
                    fail.append(f"obj_hook: engine bytes at {site:#x} != expected "
                                f"dispatch sequence ({got.hex()})")
            # BOTH source tables are read PC-relatively by the engine, i.e.
            # through 68k PROGRAM space -> CPS2-decrypted; copy entries from the
            # decrypted views. The extended table is accessed An-relative by the
            # thunk (a DATA read) and is therefore emitted raw. (docs/GOTCHAS.md)
            vj_pt = (root / "build/out/vsavj_opcodes.bin").read_bytes()
            src_pt = (root / f"build/out/{man['src_set']}_opcodes.bin").read_bytes()
            table = bytearray()
            for k in range(n_van):
                table += vj_pt[vtab + k * 4:vtab + k * 4 + 4]
            ported = 0
            for k in range(n_van, n_src):
                tgt = int.from_bytes(src_pt[stab + k * 4:stab + k * 4 + 4], "big")
                # UNION over every tenant (14z-80f), not this iteration's
                # regions: types 64-75 are Huitzil's, 59-63 Donovan's, and
                # ONE table has to carry them all.
                res = resolve_ported_all(tgt)
                m = resolve_recon(tgt)
                # 14z-85c (maintainer-ruled): a tag stub is warranted when
                # the entry is MULTI-resolver (64-75: two tenants' copies)
                # OR when a NON-resolver tenant stamps the type (59/61/62/
                # 63: donovan's copies, but H/P carry stamp sites in
                # co-ported code — dead today; a live spawn must tripwire
                # under its OWN tag, never silently run donovan's copy).
                _want_tag_stub = (
                    site == OWNER_TAG_SITE and k in OWNER_TAG_STUB_TYPES
                    and len(_tenant_list) >= 2 and res
                    and (len({a for a, _ in res}) > 1
                         or (OWNER_TAG_STAMPERS.get(k, set())
                             - {n for _, n in res})))
                if len({a for a, _ in res}) > 1 or _want_tag_stub:
                    # 14z-81b: MULTI-RESOLVER type — more than one tenant's
                    # view places its handler. With a MEASURED owner-read
                    # (OBJ_HOOK_OWNER_READ) the entry dispatches on the
                    # object's owner; without one it stays FIRST-WINS with a
                    # loud note, because a tripwire here would break types
                    # that are multi-resolver only through region CO-PORTING
                    # (site 0x54470's 64-75: Huitzil's twelve, whose handler
                    # regions Pyron also ports — measured 14z-81b when the
                    # first cut of this branch tripwired all of them).
                    # FIRST-WINS ON AN UNMEASURED TYPE IS DECLARATION-ORDER
                    # LUCK, not correctness — the note names each one so the
                    # census rig can retire it into a stub.
                    shape = OBJ_HOOK_OWNER_READ.get((site, k))
                    if shape is None and _want_tag_stub:
                        # 14z-85: the ruled owner-tag dispatch (option (a)) —
                        # the tag was baked at spawn by the detoured stamp
                        # sites (OWNER_TAG_WORK), so no runtime owner read.
                        shape = "tag"
                    ids = {t.get("name"): _int(t["dst_slot"])
                           for t in (port.get("_tenants") or [])}
                    newt = None
                    if shape is None:
                        newt = res[0][0]
                        _ren = [(tn2, TYPE_RENUMBER[(site, k, tn2)])
                                for _a, tn2 in res
                                if (site, k, tn2) in TYPE_RENUMBER]
                        if _ren:
                            # 14z-82: NOT first-wins luck — the original
                            # entry serves the FIRST resolver BY DESIGN;
                            # every later stamping tenant dispatches its
                            # OWN appended number (see the renumber rows
                            # below), so this entry is unreachable for
                            # them by construction.
                            notes.append(
                                f"#   obj_hook@{site:#x} type {k} original "
                                f"entry serves FIRST resolver {res[0][1]} "
                                f"{res[0][0]:#x} by design (14z-82); "
                                f"renumbered: "
                                + ", ".join(f"{tn2}->{ni}"
                                            for tn2, ni in _ren))
                        else:
                            notes.append(
                                f"#   obj_hook@{site:#x} type {k} MULTI-RESOLVER "
                                f"({', '.join(n for _, n in res)}) with no "
                                f"measured owner-read -> FIRST-WINS "
                                f"({res[0][1]} {res[0][0]:#x}); order-dependent "
                                f"— measure it "
                                f"(tests/audit_objhook_owner_census.sh) and "
                                f"extend OBJ_HOOK_OWNER_READ")
                    else:
                        tw = tripwire_for(tgt, f"obj_hook@{site:#x} type {k} "
                                               f"owner-dispatch fallback") \
                            if args.tripwire_open else None
                        tens = [(ids[n], a) for a, n in res if n in ids]
                        if tw is None:
                            fail.append(f"obj_hook@{site:#x}: type {k}'s "
                                        f"owner-dispatch needs a tripwire "
                                        f"for its unknown-owner paths — "
                                        f"build with --tripwire-open")
                            newt = 0
                        elif len(tens) != len(res):
                            fail.append(f"obj_hook@{site:#x} type {k}: a "
                                        f"resolving view has no tenant id "
                                        f"({[n for _, n in res]} vs "
                                        f"{sorted(ids)})")
                            newt = 0
                        else:
                            stub = owner_dispatch_stub(shape, tens, tw)
                            sd = alloc("a", len(stub),
                                       f"objhook owner stub type {k}")
                            if sd is None:
                                newt = 0
                            else:
                                ops.append({"op": "code", "addr": f"{sd:#x}",
                                            "hex": stub.hex()})
                                notes.append(
                                    f"code   {sd:#08x} obj_hook type {k} "
                                    f"OWNER-DISPATCH ({shape}; "
                                    + ", ".join(f"{n} {a:#x}" for a, n in res)
                                    + f"; unknown owner -> tripwire {tw:#x})")
                                fragments.append((sd, len(stub), "GEN",
                                                  f"obj_hook owner stub "
                                                  f"type {k}"))
                                newt = sd
                                if shape == "tag":
                                    _extra = sorted(
                                        OWNER_TAG_STAMPERS.get(k, set())
                                        - {n for _, n in res})
                                    if _extra:
                                        notes.append(
                                            f"#   obj_hook@{site:#x} type "
                                            f"{k}: stamp sites also exist "
                                            f"in {', '.join(_extra)} (no "
                                            f"handler copy placed) — a live "
                                            f"spawn there would tripwire "
                                            f"under its OWN tag; solo "
                                            f"builds already tripwire this "
                                            f"type for them and playtest "
                                            f"green (dead paths)")
                    ported += 1
                elif res:
                    newt = res[0][0]
                    ported += 1
                elif m:
                    newt = _int(m["vsavj"])
                    ported += 1
                else:
                    newt = None
                if newt is None:
                    # unported extra type: point at a tripwire so a use is LOUD
                    newt = tripwire_for(tgt, f"obj_hook@{site:#x} type {k}") \
                        if args.tripwire_open else None
                    if newt is None:
                        fail.append(f"obj_hook@{site:#x}: extra type {k} handler "
                                    f"{tgt:#x} not ported/placed")
                        newt = 0
                table += newt.to_bytes(4, "big")
            # AUTHORED union rows (14z-68): types that exist in NEITHER table.
            # The src table only carries the ids the source game itself used;
            # a tenant that needs its own type — so a SHARED type's rewritten
            # machine can be reached without touching the shared row — declares
            # it here as {index, src}. `src` is a SOURCE-game address resolved
            # exactly like a ported extra (placed region first, then recon), so
            # an unported target tripwires instead of silently dispatching into
            # the host. Indexes must continue the table with no gap: a row that
            # is not the next index is a build error, because the engine indexes
            # this table by type*4 and a hole would dispatch to whatever the
            # allocator left there.
            for ex in [e for e in engine_rows("obj_hook_extra")
                       if _int(e["site"]) == site]:
                idx = _int(ex["index"])
                cur = len(table) // 4
                if idx != cur:
                    fail.append(f"obj_hook@{site:#x}: extra row index {idx} is not "
                                f"the next table index ({cur}) — no gaps allowed")
                    continue
                tgt = _int(ex["src"])
                # union over every tenant, as above (14z-80f)
                newt, _by = resolve_ported(tgt)
                m = resolve_recon(tgt)
                if newt is not None:
                    pass
                elif m:
                    newt = _int(m["vsavj"])
                else:
                    newt = tripwire_for(tgt, f"obj_hook@{site:#x} authored type {idx}") \
                        if args.tripwire_open else None
                    if newt is None:
                        fail.append(f"obj_hook@{site:#x}: authored type {idx} handler "
                                    f"{tgt:#x} not ported/placed")
                        newt = 0
                table += newt.to_bytes(4, "big")
                notes.append(f"#   obj_hook authored type {idx} -> {newt:#08x} "
                             f"(from {args.src_set if hasattr(args, 'src_set') else 'src'} "
                             f"{tgt:#x}; {ex.get('note', '')})")
            # 14z-82: the RENUMBERED per-tenant entries. Appended after the
            # ported and authored rows, in the pre-loop assignment order —
            # the running index must match the assignment exactly (the
            # no-gap discipline: the engine indexes this table by type*4).
            # Each resolves through the OWNING tenant's view only, which is
            # the whole point: tenant B's objects dispatch tenant B's copy.
            for _site2, _idx2, _oty2, _tn2, _tgt2 in TYPE_RENUMBER_ORDER:
                if _site2 != site:
                    continue
                cur = len(table) // 4
                if _idx2 != cur:
                    fail.append(f"obj_hook@{site:#x}: renumbered type "
                                f"{_oty2} ({_tn2}) assigned index {_idx2} "
                                f"but the table is at {cur} — assignment/"
                                f"emission drift, no gaps allowed")
                    continue
                _own = [a for a, n in resolve_ported_all(_tgt2) if n == _tn2]
                if not _own:
                    fail.append(f"obj_hook@{site:#x}: renumbered type "
                                f"{_oty2}: {_tn2} does not place handler "
                                f"{_tgt2:#x} — resolver-set drift since "
                                f"the pre-loop computation")
                    continue
                table += _own[0].to_bytes(4, "big")
                notes.append(f"#   obj_hook renumbered type {_idx2} = "
                             f"{_tn2}'s {_oty2} -> {_own[0]:#08x} (its OWN "
                             f"copy; stamps rewritten in-region, 14z-82)")
            _n_renum = sum(1 for _s2, *_r2 in TYPE_RENUMBER_ORDER
                           if _s2 == site)
            # ── 14z-91: RELOCATE THE WALKER; THE SITE IS NEVER PATCHED ──
            # This used to emit the table into free space plus an 18-byte
            # thunk, and overwrite the 6 vanilla bytes at `site` with
            # `jmp thunk` (the table cannot grow in place — live code follows
            # both). Ghost-clean or not, that hook cost cycles on EVERY
            # dispatch, and site 0x05E542 dispatches 270,991 times across the
            # legacy corpus: enough to tip VBL-edge frames into losing a
            # main-loop iteration. Measured cause of the 24_don_winmash legacy
            # regression (tools/probe_hook_removal.sh), which reaches gameplay
            # state and so is a superset-invariant failure, not a class.
            #
            # Instead copy the whole 0x2C-byte WALKER and append the extended
            # table at copy+walker_len. The walker's own dispatch is
            # `movea.l (0x12,PC,D0.w),A0` at walker+0x18, and 0x18+2+0x12 =
            # 0x2C = walker_len, so the copy's instruction points at the
            # copy's table BY CONSTRUCTION — asserted below rather than
            # assumed. Then rewrite only the 4-byte OPERAND of each
            # `jsr <walker>`; the 4EB9 opcode word is never touched.
            #
            # Zero legacy cost BY CONSTRUCTION, not by census: identical
            # opcodes in identical order, and `jsr abs.l` costs the same
            # whatever its operand while `movea.l (d8,PC,Dn.w)` costs the same
            # wherever PC points. The single state difference is the pushed
            # return address (copy+0x20 vs walker+0x20) — measured by
            # tests/audit_walker_ghost.sh at A7 = 0xff7ff6 CONSTANT over
            # 279,577 dispatches in all 49 corpus replays, i.e. inside the
            # masked dead-stack window $FF7F00-$FF7FFF.
            walker = _int(ph["walker"])
            wlen = _int(ph["walker_len"])
            callers = [int(c, 0) for c in str(ph["callers"]).split(",") if c.strip()]
            cold = bytes.fromhex(ph["caller_old_hex"])
            if site != walker + 0x18:
                fail.append(f"obj_hook@{site:#x}: site is not walker+0x18 "
                            f"(walker {walker:#x}) — the relocation's layout "
                            f"assumption does not hold for this row")
            if vtab != walker + wlen:
                fail.append(f"obj_hook@{site:#x}: vanilla_table {vtab:#x} is not "
                            f"walker+{wlen:#x} ({walker + wlen:#x}); the copy's "
                            f"pc-relative dispatch would not land on its own table")
            wbytes = vj_pt[walker:walker + wlen]
            if wbytes != bytes.fromhex(ph["walker_old_hex"]):
                fail.append(f"obj_hook@{site:#x}: walker bytes at {walker:#x} are "
                            f"{wbytes.hex()}, manifest pins "
                            f"{ph['walker_old_hex']} — relocating the wrong bytes")
            # ONE contiguous block: the walker copy followed immediately by
            # its table, emitted as a `code` op.
            #
            # `code` IS THE RIGHT KIND AT ANY ADDRESS, and this is the trap
            # worth naming. The old design emitted the table as `data`, which
            # was correct only because the thunk read it An-relatively (a DATA
            # read). The relocated walker reads it PC-relatively — through
            # AS_OPCODES — so it must arrive at the CPU as plaintext the same
            # way the code around it does. patch_prg's `code` op runs
            # crypt_words_at(decrypt=False), which is ADDRESS-AWARE: inside the
            # CPS-2 window it re-encrypts so the CPU's decryption yields our
            # bytes, and above it "words outside the key's encrypted range are
            # returned unchanged, matching how the CPU would fetch them"
            # (tools/cps2_decrypt.py:325-330). So `code` is correct whether the
            # allocator lands this in crypt hole_a or raw hole_b, and the
            # fallback chain is safe to follow — which matters, because hole_a
            # is FULL on a 3-tenant merge.
            wdst = alloc("a", wlen + len(table),
                         "obj_walker relocated walker + ext table")
            if wdst is not None:
                ops.append({"op": "code", "addr": f"{wdst:#x}",
                            "hex": (wbytes + table).hex()})
                notes.append(f"code   {wdst:#08x} +{wlen + len(table):#x}  "
                             f"obj_walker: {walker:#x} relocated verbatim + its "
                             f"extended type table at +{wlen:#x} ({n_van} vanilla "
                             f"+ {n_src - n_van} ported, {ported} placed"
                             + (f", {_n_renum} renumbered" if _n_renum else "")
                             + f"); dispatch site {site:#x} left VANILLA")
                fragments.append((wdst, wlen, "GEN", "obj_walker relocated walker"))
                fragments.append((wdst + wlen, len(table), "GEN",
                                  "obj_walker ext type table"))
                for _c in callers:
                    if vj_pt[_c:_c + 6] != cold:
                        fail.append(f"obj_hook@{site:#x}: caller {_c:#x} reads "
                                    f"{vj_pt[_c:_c + 6].hex()}, expected "
                                    f"{cold.hex()} (jsr {walker:#x}) — the frozen "
                                    f"caller inventory does not match this image")
                        continue
                    # operand only: the 4EB9 opcode word stays vanilla
                    ops.append({"op": "code", "addr": f"{_c + 2:#x}",
                                "hex": f"{wdst:08x}"})
                    fragments.append((_c + 2, 4, "GEN", "obj_walker caller repoint"))
                notes.append(f"code   {len(callers)} caller operand(s) of "
                             f"jsr {walker:#x} -> {wdst:#08x} "
                             f"({', '.join(f'{c:#08x}' for c in callers)})")

        sh = singleton("state_hook") if args.stage >= 4 else None
        if sh:
            # +0x14E engine state-dispatch extension (donovan.toml [state_hook];
            # design + measured constants: docs/project/tables/reconciliation.md
            # "Session 8"). Four parts, all GEN except the records (VS2):
            #   1. 12 palette-seq records -> hole B (raw; byte-identical in
            #      vhunt2 — verified at config time, asserted here)
            #   2. ghost-clean base-swap thunks on the 4 seq-table consumers
            #      (movea.l #base is exactly 6 bytes = jmp thunk; no pushes;
            #      CCR-safe: andi.w follows at every site)
            #   3. 12 synthesized case stubs (vs2's are uniform; targets are
            #      the structurally-verified vsavj twins ret_equiv/seq_set)
            #   4. the state thunk: vanilla states jmp back to the untouched
            #      move.w+jsr (ghost-clean); extended states dispatch via a
            #      long table, preserving D0 (the stubs compare it to +0x14F)
            site = _int(sh["site"])
            first_ext = _int(sh["first_ext"])
            n_ext = _int(sh["n_ext"])
            seq_id0 = _int(sh["seq_first_id"])
            opc_img = (root / "build/out/vsavj_opcodes.bin").read_bytes()
            expect_site = (bytes([0x70, 0x00, 0x10, 0x2E])
                           + _int(sh["state_off"]).to_bytes(2, "big"))
            if opc_img[site:site + 6] != expect_site:
                fail.append(f"state_hook: engine bytes at {site:#x} != "
                            f"moveq/move.b prefix ({opc_img[site:site+6].hex()})")
            src_data = (root / f"build/out/{man['src_set']}_data.bin").read_bytes()
            rlen = _int(sh["records_len"])
            recs = src_data[_int(sh["records_src"]):_int(sh["records_src"]) + rlen]
            # sibling-oracle identity check on the records (config-time finding,
            # re-asserted every build)
            orc_p = root / f"build/out/{man['oracle_set']}_data.bin"
            if "records_orc" in sh and orc_p.is_file():
                orc_data = orc_p.read_bytes()
                tw = _int(sh["records_orc"])
                if orc_data[tw:tw + rlen] != recs:
                    fail.append("state_hook: seq records differ from the "
                                "sibling twin — misbounded or wrong address")
            rdst = alloc("b", rlen, "state_hook seq records")
            if rdst is not None:
                ops.append({"op": "data", "addr": f"{rdst:#x}", "hex": recs.hex()})
                notes.append(f"data   {rdst:#08x} +{rlen:#x}  state_hook palette-"
                             f"seq records (ids {seq_id0:#x}-{seq_id0+n_ext-1:#x})")
                fragments.append((rdst, rlen, "VS2", "state_hook seq records"))
                # PRIVATE seq-set entry (session 12: the session-9 base-swap
                # consumer thunks hijacked vanilla ids 0x2CD+ — vsavj's table
                # has its own live records there; the attract intro's fades
                # use them and WEDGED. Only Donovan's stubs may see the VS2
                # records: wrapper loads the swapped base and enters the
                # engine seq-set AFTER its movea — vanilla flows untouched.)
                alt_base = rdst - seq_id0 * 32
                sw = alloc("a", 12, "state_hook private seq entry")
                if sw is not None:
                    wk = (b"\x20\x7c" + alt_base.to_bytes(4, "big")
                          + b"\x4e\xf9"
                          + (_int(sh["seq_set"]) + 6).to_bytes(4, "big"))
                    ops.append({"op": "code", "addr": f"{sw:#x}", "hex": wk.hex()})
                    notes.append(f"code   {sw:#08x} state_hook private seq entry "
                                 f"(records base {rdst:#08x} - {seq_id0:#x}*32 -> "
                                 f"engine {_int(sh['seq_set']) + 6:#x})")
                    fragments.append((sw, 12, "GEN", "state_hook private seq entry"))
                    sh["_seq_entry"] = sw
            # 14z-46: per-stub seq ids (vs2's cases are NOT consecutive — the
            # original synthesis held only for the first three). Config
            # seq_ids: one entry per ext state; -1 = dead state (never
            # written by the ported code, vs2 case non-uniform) -> safe
            # no-op stub (jmp ret_equiv). Live ids are re-verified against
            # vs2's OWN dispatch table at build time.
            seq_ids = ([-1 if x.strip() == "-" else int(x.strip(), 0)
                        for x in sh["seq_ids"].split(",")]
                       if "seq_ids" in sh else
                       [seq_id0 + k for k in range(n_ext)])
            if len(seq_ids) != n_ext:
                fail.append(f"state_hook: seq_ids has {len(seq_ids)} entries, "
                            f"n_ext = {n_ext}")
            if "src_dispatch_table" in sh:
                src_opc = (root / f"build/out/{man['src_set']}_opcodes.bin").read_bytes()
                stab = _int(sh["src_dispatch_table"])
                sidx0 = _int(sh["src_first_idx"])
                for k, sid in enumerate(seq_ids):
                    if sid < 0:
                        continue
                    w = int.from_bytes(src_opc[stab + 2*(sidx0+k):stab + 2*(sidx0+k) + 2], "big")
                    case = src_opc[stab + w:stab + w + 0x20]
                    m = case.find(b"\x30\x3c")
                    real = int.from_bytes(case[m+2:m+4], "big") if m >= 0 else None
                    if real != sid:
                        fail.append(f"state_hook: seq_ids[{k}] = {sid:#x} but the "
                                    f"src case (idx {sidx0+k}) carries "
                                    f"{real if real is None else hex(real)}")
                    lo = seq_id0
                    if not (lo <= sid < lo + rlen // 32):
                        fail.append(f"state_hook: seq_ids[{k}] = {sid:#x} outside "
                                    f"the ported record block "
                                    f"[{lo:#x},{lo + rlen//32:#x})")
            stubs = alloc("a", 32 * n_ext, "state_hook case stubs")
            et = alloc("a", 4 * n_ext, "state_hook ext table")
            mt = alloc("a", 50, "state_hook thunk")
            if None not in (stubs, et, mt):
                blob = b""
                for k in range(n_ext):
                    if seq_ids[k] < 0:
                        piece = b"\x4e\xf9" + _int(sh["ret_equiv"]).to_bytes(4, "big")
                        piece += b"\x4e\x71" * ((32 - len(piece)) // 2)
                    else:
                        piece = (b"\xb0\x2e" + _int(sh["prev_state_off"]).to_bytes(2, "big")
                                 + b"\x66\x06"
                                 + b"\x4e\xf9" + _int(sh["ret_equiv"]).to_bytes(4, "big")
                                 + b"\x42\x2e" + _int(sh["clr_b_off"]).to_bytes(2, "big")
                                 + b"\x42\x6e" + _int(sh["clr_w_off"]).to_bytes(2, "big")
                                 + b"\x30\x3c" + seq_ids[k].to_bytes(2, "big")
                                 + b"\x72\x01"
                                 + b"\x4e\xf9" + sh["_seq_entry"].to_bytes(4, "big"))
                    blob += piece
                assert len(blob) == 32 * n_ext
                ops.append({"op": "code", "addr": f"{stubs:#x}", "hex": blob.hex()})
                ext = b"".join((stubs + 32 * k).to_bytes(4, "big")
                               for k in range(n_ext))
                ops.append({"op": "data", "addr": f"{et:#x}", "hex": ext.hex()})
                tk = (b"\x70\x00"
                      + b"\x10\x2e" + _int(sh["state_off"]).to_bytes(2, "big")
                      + b"\x0c\x40" + first_ext.to_bytes(2, "big")
                      + b"\x65\x20"
                      + b"\x0c\x40" + (first_ext + 2 * n_ext).to_bytes(2, "big")
                      + b"\x64\x1a"
                      + b"\x32\x00"
                      + b"\x04\x41" + first_ext.to_bytes(2, "big")
                      + b"\xd2\x41"
                      + b"\x20\x7c" + et.to_bytes(4, "big")
                      + b"\x20\x70\x10\x00"
                      + b"\x4e\x90"
                      + b"\x4e\xf9" + _int(sh["site_after"]).to_bytes(4, "big")
                      + b"\x4e\xf9" + _int(sh["site_resume"]).to_bytes(4, "big"))
                assert len(tk) == 50
                ops.append({"op": "code", "addr": f"{mt:#x}", "hex": tk.hex()})
                ops.append({"op": "code", "addr": f"{site:#x}",
                            "hex": (b"\x4e\xf9" + mt.to_bytes(4, "big")).hex()})
                notes.append(f"code   {site:#08x} ENGINE HOOK: +{_int(sh['state_off']):#x} "
                             f"state dispatch -> thunk {mt:#08x} (vanilla ids "
                             f"ghost-clean via jmp-back; ids {first_ext:#x}-"
                             f"{first_ext + 2*n_ext - 2:#x} -> {n_ext} synthesized "
                             f"stubs at {stubs:#08x}, ext table {et:#08x})")
                fragments.append((stubs, 32 * n_ext, "GEN", "state_hook case stubs"))
                fragments.append((et, 4 * n_ext, "GEN", "state_hook ext table"))
                fragments.append((mt, 50, "GEN", "state_hook thunk"))
                fragments.append((site, 6, "GEN", "state_hook engine site"))

        rh = singleton("reaction_hook") if args.stage >= 4 else None
        if rh:
            # Hit-reaction dispatch extension (donovan.toml [reaction_hook];
            # measured constants + design in the toml comment / reconciliation
            # Session 11). Cases are verbatim position-independent vs2 bytes
            # from the config (reviewable hex). Ghost-clean: the preceding
            # tst/bne pair becomes `jmp thunk`; vanilla ids jmp back to the
            # UNTOUCHED original dispatch.
            sp = _int(rh["site_prefix"])
            opc_img = (root / "build/out/vsavj_opcodes.bin").read_bytes()
            expect = bytes.fromhex(rh["site_prefix_expect"])
            if opc_img[sp:sp + len(expect)] != expect:
                fail.append(f"reaction_hook: bytes at {sp:#x} != expected "
                            f"tst/bne pair ({opc_img[sp:sp+8].hex()})")
            first_ext = _int(rh["first_ext"])
            n_ext = _int(rh["n_ext"])
            cases = [bytes.fromhex(rh[f"case_{first_ext + 2*k:x}"])
                     for k in range(n_ext)]
            blob = b"".join(cases)
            cb = alloc("a", len(blob), "reaction_hook cases")
            et = alloc("a", 4 * n_ext, "reaction_hook ext table")
            th = alloc("a", 50, "reaction_hook thunk")
            if None not in (cb, et, th):
                ops.append({"op": "code", "addr": f"{cb:#x}", "hex": blob.hex()})
                offs = []
                o = 0
                for c in cases:
                    offs.append(cb + o)
                    o += len(c)
                ext = b"".join(a.to_bytes(4, "big") for a in offs)
                ops.append({"op": "data", "addr": f"{et:#x}", "hex": ext.hex()})
                tk = (bytes([0x4A, 0x29]) + _int(rh["tst_disp"]).to_bytes(2, "big")
                      + bytes([0x67, 0x06])
                      + bytes([0x4E, 0xF9]) + _int(rh["bne_target"]).to_bytes(4, "big")
                      + bytes([0x0C, 0x40]) + first_ext.to_bytes(2, "big")
                      + bytes([0x65, 0x1A])
                      + bytes([0x0C, 0x40]) + (first_ext + 2 * n_ext).to_bytes(2, "big")
                      + bytes([0x64, 0x14])
                      + bytes([0x32, 0x00])
                      + bytes([0x04, 0x41]) + first_ext.to_bytes(2, "big")
                      + bytes([0xD2, 0x41])
                      + bytes([0x20, 0x7C]) + et.to_bytes(4, "big")
                      + bytes([0x20, 0x70, 0x10, 0x00])
                      + bytes([0x4E, 0xD0])
                      + bytes([0x4E, 0xF9]) + _int(rh["dispatch"]).to_bytes(4, "big"))
                assert len(tk) == 50, len(tk)
                ops.append({"op": "code", "addr": f"{th:#x}", "hex": tk.hex()})
                ops.append({"op": "code", "addr": f"{sp:#x}",
                            "hex": (b"\x4e\xf9" + th.to_bytes(4, "big")).hex()})
                notes.append(f"code   {sp:#08x} ENGINE HOOK: hit-reaction "
                             f"dispatch -> thunk {th:#08x} (vanilla ids jmp back "
                             f"to untouched {_int(rh['dispatch']):#x}; ids "
                             f"{first_ext:#x}-{first_ext + 2*n_ext - 2:#x} -> "
                             f"{n_ext} verbatim vs2 cases at {cb:#08x})")
                fragments.append((cb, len(blob), "VS2", "reaction_hook cases"))
                fragments.append((et, 4 * n_ext, "GEN", "reaction_hook ext table"))
                fragments.append((th, 50, "GEN", "reaction_hook thunk"))
                fragments.append((sp, 6, "GEN", "reaction_hook engine site"))

        if args.stage >= 4:
            shim_cfg = singleton("init_shim")
            keeper_cfgs = {k["table"]: k for k in tenant_rows("dispatch_keeper")}
            for d in man["dispatch"]:
                newt = None
                tgt = d["src_target"]
                host = region_of(tgt)
                if host in placed:
                    newt = tgt + (placed[host] - man["regions"][host]["src"])
                if newt is None:
                    fail.append(f"{d['table']}: dispatch target {tgt:#x} unplaced")
                    continue
                kc = keeper_cfgs.get(d["table"])
                if kc:
                    # SATELLITE RESPAWN KEEPER (14z-65, the Anita pattern made
                    # a mechanism): vs2 re-runs char-init EVERY ROUND (measured:
                    # native f2886+f8812) — that is how Huitzil's pods respawn.
                    # vsavj has no per-round char-init, so the boundary pool
                    # scrub leaves the tenant satellite-less (and a surviving
                    # reference dispatches the freed slot: the f4983 crash).
                    # Donovan's own ported code carries a per-frame companion
                    # keeper; this thunk gives a tenant the same behavior by
                    # reusing HIS OWN ported spawn code: on the per-frame row,
                    # if the intro is done (idle byte == 0) and the satellite
                    # ptr word is zero, jsr the ported spawn entry, then fall
                    # into the normal handler.
                    se = _int(kc["spawn_entry"])
                    sh = region_of(se)
                    if sh not in placed:
                        fail.append(f"dispatch_keeper: spawn_entry {se:#x} "
                                    f"unplaced")
                        continue
                    sp = se + (placed[sh] - man["regions"][sh]["src"])
                    kd = alloc("a", 24, "satellite respawn keeper")
                    if kd is None:
                        continue
                    idle = _int(kc.get("idle_check", 0x0A))
                    ptrw = _int(kc.get("ptr_check", 0x2A))
                    thunk = (bytes([0x4A, 0x2E]) + idle.to_bytes(2, "big")  # tst.b (idle,A6)
                             + bytes([0x66, 0x0C])                          # bne.s skip
                             + bytes([0x4A, 0x6E]) + ptrw.to_bytes(2, "big")  # tst.w (ptr,A6)
                             + bytes([0x66, 0x06])                          # bne.s skip
                             + bytes([0x4E, 0xB9]) + sp.to_bytes(4, "big")  # jsr spawn
                             + bytes([0x4E, 0xF9]) + newt.to_bytes(4, "big"))  # skip: jmp handler
                    assert len(thunk) == 24
                    ops.append({"op": "code", "addr": f"{kd:#x}",
                                "hex": thunk.hex()})
                    notes.append(f"code   {kd:#08x} satellite respawn keeper "
                                 f"(idle A6+{idle:#x}==0 & ptr A6+{ptrw:#x}==0 "
                                 f"-> jsr {sp:#x}) -> handler {newt:#08x}")
                    fragments.append((kd, 24, "GEN", "satellite respawn keeper"))
                    repoint(d["table"], kd, "handler via respawn keeper")
                    continue
                if (_shim_multi is not None and _shim_cfg_all
                        and d["table"] == _shim_cfg_all["dispatch"]
                        and T.get("name") in
                        (_shim_cfg_all.get("_flavor_by_owner") or {})):
                    # 14z-82 F2: multi-tenant build — collect this DECLARING
                    # tenant's placed handler; the one merged shim is
                    # assembled and planted at engine_here (all handlers
                    # placed by then). A tenant with no declared flavor
                    # (Pyron) falls through to the direct repoint below,
                    # untouched by the ratified decision.
                    _shim_multi[T.get("name")] = newt
                    continue
                if shim_cfg and d["table"] == shim_cfg["dispatch"]:
                    # synthesized pool-seeding + flavor-default init shim (see
                    # donovan.toml). A5 is NOT guaranteed to hold the $FF8000
                    # base at dispatch time, and the seeder itself is
                    # A5-relative — save A5, load the base, seed if the pool
                    # latch is clear, restore; then seed the VS2/VH2 flavor
                    # latch in THIS player's struct (A6) — vsavj never writes
                    # it, and Donovan's QCB+K handler + projectile read it
                    # (maintainer decision 2026-07-27: default = VS2):
                    #   move.l A5,-(SP); lea $FF8000.l,A5; tst.l (latch,A5)
                    #   bne.s +6; jsr seed_entry; movea.l (SP)+,A5
                    #   move.b #flavor_default,(flavor_disp,A6); jmp handler
                    # Slice G: the flavor tail is one unconditional write for a
                    # single declaring tenant (today's bytes, so the frozen
                    # references are untouched) and an id-DISPATCHED chain for
                    # more than one — see flavor_tail().
                    _flav_map = shim_cfg.get("_flavor_by_owner")
                    if _flav_map is None:
                        _flav_map = _flavor_of(dict(shim_cfg, _owner=T.get("name")))
                    _flav_n = len(_flav_map)
                    _shimlen = 76 if shim_cfg.get("objram_clear") else 68
                    if _flav_n > 1:
                        _shimlen += 54 * _flav_n - 40   # chain replaces the tail
                    if shim_cfg.get("latch_mode") == "phase":
                        _shimlen += 12
                    sd = alloc("a", _shimlen, "init seed shim")
                    if sd is None:
                        continue
                    latch = _int(shim_cfg["latch_disp"])
                    flav_d = _int(shim_cfg["flavor_disp"])
                    # Start-hold flavor selector (stage 5; community-confirmed
                    # protocol, docs/game/atlas/character_tables.md): the byte at
                    # flavor_hold_flag is a per-player Start bitmask (bit 0 =
                    # P1, bit 1 = P2; live through match load — measured).
                    # Holding YOUR Start through match load selects the other
                    # game's flavor (latch <- flavor_held). All ops CCR-only —
                    # no register clobbers before the handler.
                    hold_flag = _int(shim_cfg["flavor_hold_flag"])
                    # OBJ-RAM stale-tail clear (session 14z-7, manifest flag
                    # objram_clear): zero the full 8KB sprite list once per
                    # Donovan char-init. The VS-screen/fade leftovers in the
                    # tail priority buckets are re-DISPLAYED by effects that
                    # extend the list (Victor 236HP curtain) — vanilla chars
                    # leave benign dark tiles there, Donovan leaves his VS
                    # portrait pieces (the round-27 shock garble). Clearing at
                    # init (screen blanked) makes the exposed tail transparent.
                    # Register-safe: d0/a0 saved; CCR irrelevant (next op sets).
                    # 14z-7 v2: char-init runs DURING the VS screen (measured:
                    # clear at f2362, VS draws past f2364 and re-pollutes) — so
                    # the shim only ARMS a marker in the dead-stack scratch
                    # ($FF7F00, legacy-masked; worst-case clobber = one missed
                    # or one spurious clear, both benign). Donovan's per-frame
                    # sword routine consumes it at round start (first frame
                    # after the VS screen) and clears the OBJ list there — see
                    # the objram_clear blob below.
                    objclr = b""
                    if shim_cfg.get("objram_clear"):
                        objclr = bytes.fromhex("13fc005000ff7f00")  # move.b #$50,$ff7f00.l (countdown)
                    # PHASE-GATED LATCH (14z-65, manifest opt-in latch_mode =
                    # "phase"): the pool-head latch alone is FALSE mid-match —
                    # a tenant whose ecosystem drains pool 0 makes the round-2
                    # char re-init re-run the seeder over LIVE pools (measured:
                    # f4890 wipe, orphaned queues, a freed slot dispatched into
                    # palette space). $FF800C.l == 0x00040000 EXACTLY at the
                    # char-load phase (measured: 0x40000 at first init, 0x60000
                    # mid-round, 0 at the round-2 scrub) — seed only then.
                    # ABSENT for Donovan's manifest: his frozen shim bytes are
                    # unchanged until his own re-freeze adopts the mode.
                    phase_gate = b""
                    if shim_cfg.get("latch_mode") == "phase":
                        phase_gate = (bytes([0x0C, 0xB9, 0x00, 0x04, 0x00, 0x00,
                                             0x00, 0xFF, 0x80, 0x0C])  # cmpi.l #$40000,$FF800C.l
                                      + bytes([0x66, 0x0C]))           # bne.s past tst/bne/jsr
                    shim = (bytes([0x2F, 0x0D])                       # move.l A5,-(SP)
                            + bytes([0x4B, 0xF9, 0x00, 0xFF, 0x80, 0x00])  # lea $FF8000.l,A5
                            + phase_gate
                            + bytes([0x4A, 0xAD]) + latch.to_bytes(2, "big")  # tst.l (latch,A5)
                            + bytes([0x66, 0x06])                     # bne.s skip seed
                            + bytes([0x4E, 0xB9])
                            + _int(shim_cfg["seed_entry"]).to_bytes(4, "big")
                            + bytes([0x2A, 0x5F])                     # movea.l (SP)+,A5
                            + flavor_tail(_flav_map, flav_d, hold_flag, newt,
                                          objclr, port.get("_tenants") or [T],
                                          fail))
                    if len(_flav_map) <= 1:
                        assert len(shim) == 68 + len(objclr) + len(phase_gate), \
                            len(shim)
                    else:
                        assert len(shim) == 22 + len(phase_gate) + len(objclr) \
                            + 54 * len(_flav_map) + 6, len(shim)
                    ops.append({"op": "code", "addr": f"{sd:#x}", "hex": shim.hex()})
                    notes.append(f"code   {sd:#08x} init shim (pool latch A5+"
                                 f"{latch:#x}, seeder "
                                 f"{_int(shim_cfg['seed_entry']):#x}; flavor "
                                 f"(A6+{flav_d:#x}) "
                                 + ", ".join(
                                     f"{_n}<-{_dv:#04x}/held {_hv:#04x}"
                                     for _n, (_dv, _hv) in sorted(_flav_map.items()))
                                 + f" [Start bitmask {hold_flag:#x}, bit=player]"
                                 + (f", id-dispatched on (A6+0x382)"
                                    if len(_flav_map) > 1 else "")
                                 + f") -> handler {newt:#08x}")
                    fragments.append((sd, len(shim), "GEN",
                                      "pool-seed + flavor(+Start-hold) init shim"))
                    repoint(d["table"], sd, "donovan handler via seed shim")
                else:
                    repoint(d["table"], newt, "donovan handler")

        # ── objram_clear round-start blob (14z-7 v2, pairs with the init-shim
        # marker): detour the ported sword routine's per-frame exit
        # (vs2 0x65F00 `jmp $13C0E` -> placed x065e5a+0xA6, relocated target
        # 0x1551A) through a blob that, when the $FF7F00 marker is armed,
        # clears the full 8KB OBJ list once (both display halves are
        # CPU-visible; the active list rebuilds next frame, the stale
        # VS-screen tail — Donovan's portrait pieces, the round-27 Victor-
        # shock garble — stays cleared). Donovan-gated by construction: the
        # blob only runs from HIS routine; legacy paths never execute it and
        # $FF7F00 is inside the masked dead-stack window.
        if args.stage >= 6 and (singleton("init_shim") or {}).get("objram_clear"):
            if "x065e5a" not in placed:
                fail.append("objram_clear: region x065e5a not placed")
            else:
                site = placed["x065e5a"] + (0x65F00 - 0x65E5A)
                ret = 0x1551A
                # v3: the sword object lives from char-init, so its routine
                # runs DURING the VS screen — gate the consume on the match-
                # active flag ($FF8004.l == 0x40000, the established overlay-
                # thunk gate) so the clear fires on the first real match frame.
                # v4: single-shot clears kept racing pre-match drawers (VS
                # screen redraws through ~f2470; the sword exit path first
                # runs ~f2460) — the marker is now a COUNTDOWN (0x50 frames,
                # decremented only while match-active): the clear lands ~80
                # frames into the round, deterministically past every
                # pre-match drawer, replay-timing independent. It runs in the
                # object-update phase, so the same frame's list rebuild
                # repaints all ACTIVE entries — no visible blank; only stale
                # tail buckets stay cleared.
                blob = (bytes.fromhex("4a3900ff7f00")      # tst.b $ff7f00.l
                        + bytes.fromhex("672c")            # beq.s done
                        + bytes.fromhex("0cb90004000000ff8004")  # cmpi.l #$40000,$ff8004.l
                        + bytes.fromhex("6620")            # bne.s done (marker kept)
                        + bytes.fromhex("533900ff7f00")    # subq.b #1,$ff7f00.l
                        + bytes.fromhex("6618")            # bne.s done (still counting)
                        + bytes.fromhex("48e78080")        # movem.l d0/a0,-(sp)
                        + bytes.fromhex("41f900708000")    # lea $708000.l,a0
                        + bytes.fromhex("303c07ff")        # move.w #$7ff,d0
                        + bytes.fromhex("4298")            # clr.l (a0)+
                        + bytes.fromhex("51c8fffc")        # dbra d0,.-2
                        + bytes.fromhex("4cdf0101")        # movem.l (sp)+,d0/a0
                        + bytes.fromhex("4ef9") + ret.to_bytes(4, "big"))  # done: jmp
                # branch checks: all three branches land on the final jmp
                assert 8 + 0x2C == len(blob) - 6, (hex(len(blob)))
                assert 0x14 + 0x20 == len(blob) - 6, (hex(len(blob)))
                assert 0x1C + 0x18 == len(blob) - 6, (hex(len(blob)))
                bd = alloc("a", len(blob), "objram round-start clear blob")
                if bd is None:
                    fail.append("objram_clear: no room for blob")
                else:
                    ops.append({"op": "code", "addr": f"{bd:#x}", "hex": blob.hex()})
                    ops.append({"op": "code", "addr": f"{site:#x}",
                                "hex": "4ef9" + f"{bd:08x}"})
                    notes.append(f"code   {bd:#08x} +{len(blob):#x}  objram clear "
                                 f"blob; sword-exit site {site:#08x} detoured")
                    fragments.append((bd, len(blob), "GEN", "objram clear blob"))
                    fragments.append((site, 6, "GEN", "objram clear detour site"))

        if args.stage >= 5:
            for p in tenant_rows("aux_poke"):
                # only_base_slot / only_variant_slot, resolved against the row's
                # OWNING tenant (slice C) — see row_applies() for both rationales.
                _own = owner_of(p)
                _oid = _int(_own["dst_slot"])
                if not row_applies(p, _own):
                    if p.get("only_base_slot"):
                        notes.append(f"# aux {p['name']}: SKIPPED (host-slot "
                                     f"content; tenant is at variant id "
                                     f"{_oid:#04x})")
                    else:
                        notes.append(f"# aux {p['name']}: SKIPPED (variant-half "
                                     f"row; tenant is at base slot {_oid:#04x})")
                    continue
                ops.append({"op": p["op"], "addr": f"{_int(p['addr']):#x}",
                            "val": f"{_int(p['val']):#x}"})
                notes.append(f"{p['op']} {_int(p['addr']):#08x} <- {_int(p['val']):#x} "
                             f" aux {p['name']}")

        # ── data_port: bulk source-set data placed over verified vanilla spans ──
        # Every row must state its full mechanism in the manifest. Guards:
        # sibling-oracle byte identity (orc), destination old-content head
        # (dst_old_head — proves we overwrite exactly the span we think we do),
        # explicit destination bound (dst_end), and old-verified in-blob fixes.
        if args.stage >= 6:
            for dp in tenant_rows("data_port"):
                if args.stage < _int(dp.get("stage", 0)):
                    continue
                nm = dp["name"]
                # only_base_slot (14z-62c), resolved against the row's OWNER
                # (slice C): in-place tenant content over the HOST slot's bytes
                # — skipped on variant-id builds, where the host is a live legacy
                # character again (same rationale as the aux_poke gate above).
                _own = owner_of(dp)
                _ovar = is_variant_tenant(_own)
                if not row_applies(dp, _own):
                    notes.append(f"# data_port {nm}: SKIPPED (host-slot content; "
                                 f"tenant is at variant id "
                                 f"{_int(_own['dst_slot']):#04x})")
                    continue
                src, dst, ln = _int(dp["src"]), _int(dp["dst"]), _int(dp["len"])
                _img = dp.get("src_image", man["src_set"])
                sdat = (root / f"build/out/{_img}_data.bin").read_bytes()
                blob = bytearray(sdat[src:src + ln])
                if len(blob) != ln:
                    fail.append(f"data_port {nm}: src read short")
                    continue
                if "orc" in dp:
                    odat = (root / f"build/out/{man['oracle_set']}_data.bin"
                            ).read_bytes()
                    tw = _int(dp["orc"])
                    if odat[tw:tw + ln] != bytes(blob):
                        fail.append(f"data_port {nm}: sibling twin at {tw:#x} "
                                    f"differs — misbounded or wrong address")
                        continue
                # slot_ptr_table (14z-62c): the destination span is the HOST
                # slot's block, reached through a per-char POINTER TABLE row. On
                # a base-half build the block is replaced in place exactly as
                # before. On a variant-id build the host's block must stay
                # vanilla, so the (fixed) blob is placed by the space model and
                # the TENANT's table row is repointed instead — the same
                # place+repoint shape as sound_table, after asserting the
                # variant row is a vanilla alias of its base-half counterpart.
                spt = _int(dp["slot_ptr_table"]) if "slot_ptr_table" in dp else None
                if spt is None or not _ovar:
                    if dst + ln > _int(dp["dst_end"]):
                        fail.append(f"data_port {nm}: {ln:#x} bytes overrun "
                                    f"dst_end {_int(dp['dst_end']):#x}")
                        continue
                    vdat = (root / "build/out/vsavj_data.bin").read_bytes()
                    oh = bytes.fromhex(dp["dst_old_head"])
                    if vdat[dst:dst + len(oh)] != oh:
                        fail.append(f"data_port {nm}: dest old-content mismatch "
                                    f"at {dst:#x} ({vdat[dst:dst+len(oh)].hex()})")
                        continue
                # In-blob fixes ride a FLAT `fixes = "off:old:new[,...]"` string
                # (14z-62c). The nested `[[data_port.fix]]` shape is BANNED: the
                # subset parser (no-tomllib hosts) silently detached it as an
                # orphan top-level key, so the 14z-2 mirror-victim fix never
                # applied on this machine — including in both FROZEN references
                # — while a tomllib host would have applied it. A manifest
                # feature that parses differently per host makes fingerprints
                # host-dependent; hard-fail both shapes.
                if "fix" in dp:
                    fail.append(f"data_port {nm}: nested [[data_port.fix]] is "
                                f"banned (host-dependent parse, 14z-62c) — use "
                                f"the flat fixes=\"off:old:new,...\" key")
                    continue
                ok = True
                nfix = 0
                for _fx in str(dp.get("fixes", "")).split(","):
                    if not _fx.strip():
                        continue
                    _off_s, _old_s, _new_s = _fx.strip().split(":")
                    off = _int(_off_s)
                    old = bytes.fromhex(_old_s)
                    new = bytes.fromhex(_new_s)
                    if bytes(blob[off:off + len(old)]) != old:
                        fail.append(f"data_port {nm}: fix@{off:#x} old bytes "
                                    f"mismatch ({bytes(blob[off:off+len(old)]).hex()})")
                        ok = False
                        break
                    if len(new) != len(old):
                        # Same law as port_patch above (GitHub #20). This is the
                        # key the #92 arcade-ladder fix rides, so it is now a
                        # guarded path rather than a hypothetical one.
                        fail.append(f"data_port {nm}: fix@{off:#x} new is "
                                    f"{len(new)} bytes, old is {len(old)} — "
                                    f"lengths must match")
                        ok = False
                        break
                    blob[off:off + len(new)] = new
                    nfix += 1
                if not ok:
                    continue
                # slot_rows (14z-99, GitHub #104): place the blob and repoint
                # EXPLICIT rows of slot_ptr_table at it — the capture-keyframe
                # fix, where the repointed rows are LEGACY attackers' (the
                # owner-row branch below serves a tenant's own row and cannot
                # express this). Every entry is "row:expected_vanilla_ptr",
                # verified against the pristine image (the #18 discipline), so
                # a drifted table, a wrong-table typo, or a row some other fix
                # already moved dies loudly instead of silently double-poking.
                # The rows are LEGACY-DEREFERENCED pointers: the licence is the
                # 14z-91 walker-relocation precedent — byte-identical content
                # at the new address (test_capture_pose_sources freezes that
                # premise), proven by legacy A/B at the probe build.
                # Declared identically by every tenant: merge dedup emits ONE
                # blob on the merged build; each solo carries its own copy.
                srows = str(dp.get("slot_rows", "")).strip()
                if srows:
                    if spt is None:
                        fail.append(f"data_port {nm}: slot_rows needs "
                                    f"slot_ptr_table")
                        continue
                    # anchor the DECLARED dst (the vanilla block this fix
                    # supersedes) by content — dst_end is deliberately not
                    # checked: nothing is written at dst in this mode, and the
                    # placed blob is LONGER than the vanilla block by design.
                    vdat = (root / "build/out/vsavj_data.bin").read_bytes()
                    oh = bytes.fromhex(dp["dst_old_head"])
                    if vdat[dst:dst + len(oh)] != oh:
                        fail.append(f"data_port {nm}: dest old-content mismatch "
                                    f"at {dst:#x} "
                                    f"({vdat[dst:dst+len(oh)].hex()})")
                        continue
                    entries = []
                    rows_ok = True
                    for e in srows.split(","):
                        r_s, exp_s = e.strip().split(":")
                        r, exp = _int(r_s), _int(exp_s)
                        got = vj_u32(spt + 4 * r)
                        if got != exp:
                            fail.append(f"data_port {nm}: slot_rows row "
                                        f"{r:#x} holds {got:#x}, expected "
                                        f"{exp:#x} — wrong table or drift")
                            rows_ok = False
                            break
                        entries.append(r)
                    if not rows_ok:
                        continue
                    pdst = alloc(dp.get("hole", "b"), ln,
                                 f"data_port {nm} block")
                    if pdst is None:
                        continue
                    ops.append({"op": "data", "addr": f"{pdst:#x}",
                                "hex": bytes(blob).hex()})
                    notes.append(f"data   {pdst:#08x} +{ln:#x}  data_port {nm} "
                                 f"PLACED (slot_rows; vanilla block {dst:#x} "
                                 f"untouched) <- {man['src_set']} {src:#08x} "
                                 f"({nfix} fixes)")
                    for r in entries:
                        ra = spt + 4 * r
                        ops.append({"op": "poke32", "addr": f"{ra:#x}",
                                    "val": f"{pdst:#x}"})
                        notes.append(f"poke32 {ra:#08x} <- {pdst:#x}  "
                                     f"data_port {nm} ptr-table {spt:#x} "
                                     f"row {r:#04x} (slot_rows)")
                    fragments.append((pdst, ln, "VS2",
                                      f"data_port {nm} placed block "
                                      f"({man['src_set']} {src:#06x}, "
                                      f"slot_rows)"))
                    continue
                if spt is not None and _ovar:
                    # Slice D: the repointed row is the OWNER's.
                    _orow = _int(_own["dst_slot"])
                    row_at = spt + 4 * _orow
                    alias_at = spt + 4 * (_orow & 0x0F)
                    if vj_u32(row_at) != vj_u32(alias_at):
                        fail.append(f"data_port {nm}: variant row {row_at:#x} "
                                    f"({vj_u32(row_at):#x}) does not alias its "
                                    f"base-half counterpart "
                                    f"({vj_u32(alias_at):#x}) — table shape moved")
                        continue
                    # the declared dst documents the BASE-HALF slot's block the
                    # in-place mode overwrites; anchor that this table is the
                    # one that points at it (any base-half row — the manifest's
                    # dst belonged to the ORIGINAL slot, not the tenant's alias)
                    if dst not in [vj_u32(spt + 4 * i) for i in range(16)]:
                        fail.append(f"data_port {nm}: no base-half row of "
                                    f"slot_ptr_table {spt:#x} points at the "
                                    f"declared dst {dst:#x} — wrong table?")
                        continue
                    pdst = alloc(dp.get("hole", "b"), ln, f"data_port {nm} block")
                    if pdst is None:
                        continue
                    ops.append({"op": "data", "addr": f"{pdst:#x}",
                                "hex": bytes(blob).hex()})
                    ops.append({"op": "poke32", "addr": f"{row_at:#x}",
                                "val": f"{pdst:#x}"})
                    notes.append(f"data   {pdst:#08x} +{ln:#x}  data_port {nm} "
                                 f"PLACED (tenant at {_orow:#04x}; host block "
                                 f"{dst:#x} untouched) <- {man['src_set']} "
                                 f"{src:#08x} ({nfix} fixes)")
                    notes.append(f"poke32 {row_at:#08x} <- {pdst:#x}  data_port "
                                 f"{nm} ptr-table {spt:#x} row {_orow:#04x}")
                    fragments.append((pdst, ln, "VS2",
                                      f"data_port {nm} placed block "
                                      f"({man['src_set']} {src:#06x})"))
                    continue
                ops.append({"op": "data", "addr": f"{dst:#x}",
                            "hex": bytes(blob).hex()})
                notes.append(f"data   {dst:#08x} +{ln:#x}  data_port {nm} <- "
                             f"{man['src_set']} {src:#08x} "
                             f"({nfix} fixes)")
                fragments.append((dst, ln, "VS2",
                                  f"data_port {nm} ({man['src_set']} {src:#06x})"))

        # ── sound_table (14z-52): port a per-char QSound record array with an
        # ID ALLOWLIST. The engine's own dispatcher skips a record whose id
        # word is 0 (`tst.w d1; beq`), so ids that have no faithful vsavj
        # meaning are zeroed rather than translated — silence beats the wrong
        # sound, and vsavj's 0x700-0x7FF ids are MUSIC TRACKS where vs2 put
        # the newcomer voice bank (14z-52 measurement, docs/project/m5/). The blob is
        # hole-allocated and the per-char pointer row is repointed, so the
        # array length is bounded by OUR measurement (max index used + 1),
        # not by the length of the slot's vanilla array.
        if args.stage >= 6:
            for st in tenant_rows("sound_table"):
                if args.stage < _int(st.get("stage", 0)):
                    continue
                # Profile-gated CONTENT, the companion to profile-gated space: a
                # row that lives in the WIDE extension must not be emitted into a
                # stock-size build, where it would either fail to allocate or —
                # worse — silently land somewhere else.
                if st.get("profile") and st["profile"] != args.profile:
                    continue
                nm = st["name"]
                src = _int(st["src"])
                n = _int(st["entries"])
                keep = {_int(x) for x in str(st["keep_ids"]).split(",") if x.strip()}
                # remap_ids (14z-85g): "srcid:dstid,..." — rewrite a record's
                # id to a MEASURED-EQUIVALENT vsavj id before the allowlist
                # pass (the trap-detonation precedent: vs2 0x73A keys the
                # same sample bytes vsavj keys at 0x199 — same content, same
                # pitch, only the id space differs). The target must be in
                # keep_ids: a remap the zero pass would then kill is a
                # contradiction, loud by construction.
                remap = {}
                for _sp in str(st.get("remap_ids", "")).split(","):
                    _sp = _sp.strip()
                    if not _sp:
                        continue
                    _a, _b = (_int(x) for x in _sp.split(":"))
                    if _b not in keep:
                        fail.append(f"sound_table {nm}: remap target "
                                    f"{_b:#x} is not in keep_ids — the "
                                    f"allowlist pass would re-zero it")
                        break
                    remap[_a] = _b
                else:
                    pass
                if any(f.startswith(f"sound_table {nm}: remap target")
                       for f in fail):
                    continue
                sdat = (root / f"build/out/{man['src_set']}_data.bin").read_bytes()
                blob = bytearray(sdat[src:src + n * 8])
                if len(blob) != n * 8:
                    fail.append(f"sound_table {nm}: src read short")
                    continue
                zeroed = []
                remapped = []
                for i in range(n):
                    o = i * 8
                    sid = int.from_bytes(blob[o:o + 2], "big")
                    alt = int.from_bytes(blob[o + 2:o + 4], "big")
                    if sid in remap:
                        remapped.append((i, sid, remap[sid]))
                        sid = remap[sid]
                        blob[o:o + 2] = sid.to_bytes(2, "big")
                    if alt in remap:
                        alt = remap[alt]
                        blob[o + 2:o + 4] = alt.to_bytes(2, "big")
                    if sid and sid not in keep:
                        zeroed.append((i, sid))
                        blob[o:o + 2] = b"\x00\x00"
                    if alt and alt not in keep:
                        blob[o + 2:o + 4] = b"\x00\x00"
                dst = alloc(st.get("hole", "a"), len(blob), f"sound_table {nm}")
                if dst is None:
                    continue
                # The row FOLLOWS THE TENANT (14z-62c; ptr_row used to be a
                # manifest constant 0x0F, so a variant-id build repointed
                # JEDAH's sfx array at Donovan's). ptr_old documents the
                # base-half slot's vanilla pointer; a variant row is instead
                # anchored on being a vanilla ALIAS of its base-half
                # counterpart.
                if "ptr_row" in st:
                    fail.append(f"sound_table {nm}: the manifest declares a "
                                f"fixed 'ptr_row' — the row follows the tenant "
                                f"now (14z-62c); delete the key")
                    continue
                ptr_row = _int(owner_of(st)["dst_slot"])   # slice D: the OWNER's
                ptr_at = _int(st["ptr_table"]) + ptr_row * 4
                old_ptr = vj_u32(ptr_at)
                if ptr_row >= 0x10:
                    alias = vj_u32(_int(st["ptr_table"]) + (ptr_row & 0x0F) * 4)
                    if old_ptr != alias:
                        fail.append(f"sound_table {nm}: variant ptr row holds "
                                    f"{old_ptr:#x}, not the base-half alias "
                                    f"{alias:#x} — table shape moved")
                        continue
                elif "ptr_old" in st and old_ptr != _int(st["ptr_old"]):
                    fail.append(f"sound_table {nm}: ptr row holds {old_ptr:#x}, "
                                f"manifest expects {_int(st['ptr_old']):#x}")
                    continue
                ops.append({"op": "data", "addr": f"{dst:#x}",
                            "hex": bytes(blob).hex()})
                ops.append({"op": "poke32", "addr": f"{ptr_at:#x}",
                            "val": f"{dst:#x}"})
                kept = [f"{int.from_bytes(blob[i*8:i*8+2],'big'):#05x}@{i}"
                        for i in range(n) if int.from_bytes(blob[i*8:i*8+2], "big")]
                notes.append(f"data   {dst:#08x} +{len(blob):#x}  sound_table {nm} "
                             f"<- {man['src_set']} {src:#08x} ({n} entries; "
                             f"kept {kept}; zeroed {len(zeroed)} unplayable ids; "
                             f"remapped {[(i, hex(a), hex(b)) for i, a, b in remapped]})")
                notes.append(f"poke32 {ptr_at:#08x} <- {dst:#x}  "
                             f"sound_table {nm} per-char ptr row "
                             f"{ptr_row:#04x} (was {old_ptr:#x})")
                fragments.append((dst, len(blob), "VS2",
                                  f"sound_table {nm} ({man['src_set']} {src:#06x}, "
                                  f"id-allowlisted)"))

        # ── select_wheel (14z-60s): append three cells to the character-select
        # wheel. Three edits, none of which shifts a byte of existing content:
        #   1. TABLE B in place — rows 0x10/0x11/0x13 physically exist already as
        #      unused alias copies, so the new rows and the inbound edges are a
        #      28-byte overwrite, no growth, no relocation.
        #   2. the OBJ record and its coordinate list COPIED into profile-gated
        #      space, widened by three entries, with the vanilla budget word
        #      carried over (GOTCHAS: the emitter debits it from a shared
        #      per-frame budget; a change once flipped a skip decision into a
        #      one-byte $FF811B divergence). 85 >= 21 entries.
        #   3. one longword repointed, the record's single referrer.
        # The vanilla record and list are left untouched where they are: measured
        # to have exactly one referrer each and no interior pointers
        # (docs/game/atlas/select_screen.md), which is what makes copy-and-repoint
        # safe rather than a relocation that has to be prayed over.
        if args.stage >= 6:
            for sw in tenant_rows("select_wheel"):
                if args.stage < _int(sw.get("stage", 0)):
                    continue
                if sw.get("profile") and sw["profile"] != args.profile:
                    continue
                nm = sw["name"]
                lay = json.loads((root / sw["layout"]).read_text())
                tb = _int(sw["table_b"])
                rec = _int(sw["record"])
                recptr = _int(sw["record_ptr"])
                clist = _int(sw["coord_list"])

                fmtw, budget, count = struct.unpack(">HHH", vj[rec:rec + 6])
                cptr = int.from_bytes(vj[rec + 6:rec + 10], "big")
                nvan = count + 1
                bad = []
                if count != _int(sw["expect_count"]):
                    bad.append(f"count {count} != {_int(sw['expect_count'])}")
                if budget != _int(sw["expect_budget"]):
                    bad.append(f"budget {budget:#x} != {_int(sw['expect_budget']):#x}")
                if cptr != _int(sw["expect_cptr"]):
                    bad.append(f"cptr {cptr:#x} != {_int(sw['expect_cptr']):#x}")
                if vj_u32(recptr) != rec:
                    bad.append(f"{recptr:#x} holds {vj_u32(recptr):#x}, not {rec:#x}")
                if bad:
                    fail.append(f"select_wheel {nm}: vanilla anchors moved: "
                                + "; ".join(bad))
                    continue

                DIRS = ["R", "L", "D", "U", "DR", "DL", "UR", "UL"]
                # Cell keys are BARE HEX ("10", "11", "13") — parse them as hex
                # explicitly. _int() treats a bare decimal string as decimal, so
                # "10"/"11"/"13" came out as 0x0A/0x0B/0x0D and the new rows were
                # written over Sasquatch, random and Lei-Lei while the newcomers
                # were never created at all. Caught only because two tools
                # disagreed on the changed-byte count by 2 (14z-60s).
                def _cell(k):
                    c = int(str(k), 16)
                    if not (0x10 <= c <= 0x1F):
                        fail.append(f"select_wheel {nm}: new cell {c:#04x} is not "
                                    f"in the variant half 0x10-0x1F — a new cell "
                                    f"may never overwrite a vanilla cell")
                    if c in (0x12, 0x18):
                        fail.append(f"select_wheel {nm}: id {c:#04x} is RESERVED "
                                    f"(docs/game/atlas/id_space.md)")
                    return c
                # --- 1. TABLE B, in place -------------------------------------
                rows = [bytearray(vj[tb + c * 8: tb + c * 8 + 8]) for c in range(32)]
                for k, spec in lay["cells"].items():
                    c = _cell(k)
                    for i, dname in enumerate(DIRS):
                        rows[c][i] = _int(spec["adjacency"][dname])
                for e in lay.get("edges_in", []):
                    rows[_int(e["from"])][DIRS.index(e["dir"])] = _int(e["to"])
                nb = 0
                for c in range(32):
                    if bytes(rows[c]) != vj[tb + c * 8: tb + c * 8 + 8]:
                        ops.append({"op": "data", "addr": f"{tb + c * 8:#x}",
                                    "hex": bytes(rows[c]).hex()})
                        nb += sum(1 for i in range(8)
                                  if rows[c][i] != vj[tb + c * 8 + i])
                notes.append(f"data   {tb:#08x}        select_wheel {nm}: TABLE B "
                             f"in place, {nb} bytes over "
                             f"{len(lay['cells'])} new rows + "
                             f"{len(lay.get('edges_in', []))} inbound edges")

                # --- 2. coord list: copy + append ------------------------------
                newcells = [(_cell(k), dict(v)) for k, v in lay["cells"].items()]
                newcells.sort(key=lambda kv: kv[0])
                # bank5 palette rows (14z-63, maintainer round): the layout's
                # vs2 attr pal rows are SHARED vanilla medallion rows here, so
                # real art rendered under wrong palettes (Phobos/Pyron read as
                # noise). On group-C builds each cell's entry is re-palmed to
                # its declared FREE row (measured: OBJ-unreferenced on select
                # across 3 replays + a live poke-probe changed zero pixels)
                # and the vs2 palette bytes are written into select block A
                # (the wheel view's live copy) in the bank5 branch below.
                bank5_active = (sw.get("bank5")
                                and _int(T.get("gfx_bank", 2)) >= 4)
                if bank5_active:
                    for _c, spec in newcells:
                        if "pal_row" in spec:
                            spec["attr"] = ((_int(spec["attr"]) & ~0x1F)
                                            | _int(spec["pal_row"]))
                cl = bytearray(vj[clist:clist + nvan * 4])
                # The list's pairs are RELATIVE to the drawer object's base
                # (measured (256,176) — see the layout's _coord_note); 'pos'
                # is a ring-centre, corner_offset the sprite-corner shift.
                # Appending pos verbatim put the three entries at OBJ
                # x=480+/y=344+ — emitted, never on screen (14z-62i).
                _bx, _by = lay.get("obj_base", (0, 0))
                _cx, _cy = lay.get("corner_offset", (0, 0))
                for _c, spec in newcells:
                    x, y = spec["pos"]
                    cl += struct.pack(">hh", int(x) + int(_cx) - int(_bx),
                                      int(y) + int(_cy) - int(_by))
                # --- 2b. VERSION STRING (14z-105, CLAUDE.md §5's "visible
                # in-game version string", maintainer-approved 14z-104): N
                # authored glyph sprites appended to the SAME record — the
                # select screen is the one roster-owned always-visited
                # surface, and it already diverges under the ratified §4 v3
                # window, so the string costs no new divergence class. Tiles
                # are AUTHORED (provenance NEW — the effect_tail precedent),
                # encoded by gfx_tiles.encode from build/manifest/
                # version_font.json, placed in group C's upper bank by
                # build_gfx --wheel-bank5 (the "authored" list). Gated on
                # bank5 being active: without group C there is nowhere to
                # put a glyph. Knobs (all under [[select_wheel]]):
                #   version_text  the string (chars must exist in the font)
                #   version_x/y   screen position of the first glyph's
                #                 top-left (screen = OBJ - (64, 16), measured)
                #   version_pal   select palette row (must be one of the
                #                 thunk-re-asserted medallion rows — stable
                #                 by construction; the font's `ink` index)
                #   version_base  group C upper-bank code of the first
                #                 glyph (row-aligned; one cell per glyph)
                vt_entries = []        # (tile, attr) per glyph
                vt_tiles = {}          # code -> 128B canonical tile (hex)
                vt_text = str(sw.get("version_text", ""))
                if vt_text and not bank5_active:
                    notes.append(f"# select_wheel {nm}: version_text "
                                 f"{vt_text!r} SKIPPED — bank5 inactive (no "
                                 f"group C to hold the glyphs)")
                elif vt_text:
                    from gfx_tiles import encode as _enc_tile
                    _font = json.loads((root / sw["version_font"]).read_text())
                    _ink = int(_font["ink"])
                    _vb = _int(sw["version_base"])
                    _vp = _int(sw["version_pal"])
                    if _vb & 0xF:
                        fail.append(f"select_wheel {nm}: version_base "
                                    f"{_vb:#x} must be row-aligned (low "
                                    f"nibble 0)")
                    if _vb < 0x10000 or _vb + len(vt_text) > 0x20000:
                        fail.append(f"select_wheel {nm}: version_base "
                                    f"{_vb:#x}+{len(vt_text)} is outside "
                                    f"group C's upper bank")
                    _sx, _sy = _int(sw["version_x"]), _int(sw["version_y"])
                    for _i, _ch in enumerate(vt_text):
                        if _ch not in _font["glyphs"]:
                            fail.append(f"select_wheel {nm}: version_text "
                                        f"char {_ch!r} has no glyph in "
                                        f"{sw['version_font']}")
                            continue
                        _g = _font["glyphs"][_ch]
                        if len(_g) != 7 or any(len(r) != 5 for r in _g):
                            fail.append(f"select_wheel {nm}: glyph {_ch!r} "
                                        f"is not 5x7")
                            continue
                        _px = bytearray([15] * 256)   # pen 15 = transparent
                        # 2x scale, 10x14 ink box centred in the 16x16 cell
                        for _r, _row in enumerate(_g):
                            for _cx, _v in enumerate(_row):
                                if _v == "#":
                                    for _dy in (0, 1):
                                        for _dx in (0, 1):
                                            _px[(1 + 2 * _r + _dy) * 16
                                                + 3 + 2 * _cx + _dx] = _ink
                        _code = _vb + _i
                        vt_tiles[_code] = _enc_tile(_px).hex()
                        vt_entries.append((_code & 0xFFFF, _vp & 0x1F))
                        # coords are RELATIVE to the drawer base, like the
                        # cells above; OBJ x = screen x + 64
                        # OBJ (x, y) -> screen (x - 64, y - 16): measured
                        # 14z-105 on the live OBJ list (x=0x194/y=0xCA drew
                        # at screen (340, 186))
                        cl += struct.pack(">hh",
                                          _sx + 64 + 16 * _i - int(_bx),
                                          _sy + 16 - int(_by))
                    notes.append(f"# select_wheel {nm}: version_text "
                                 f"{vt_text!r} -> {len(vt_entries)} glyph "
                                 f"entries at screen ({_sx},{_sy}), pal row "
                                 f"{_vp:#04x}, codes {_vb:#x}+ (authored "
                                 f"tiles via wheel_bank5.json)")
                cl_dst = alloc(sw.get("hole", "a"), len(cl),
                               f"select_wheel {nm} coords")
                if cl_dst is None:
                    continue

                # --- 3. record: copy + append + repoint ------------------------
                body = bytearray(vj[rec:rec + 10 + nvan * 4])
                struct.pack_into(">H", body, 4,
                                 nvan + len(newcells) + len(vt_entries) - 1)  # count
                struct.pack_into(">I", body, 6, cl_dst)                    # cptr
                for _c, spec in newcells:
                    body += struct.pack(">HH", _int(spec["tile"]), _int(spec["attr"]))
                for _t, _a in vt_entries:
                    body += struct.pack(">HH", _t, _a)
                if budget < nvan + len(newcells) + len(vt_entries):
                    fail.append(f"select_wheel {nm}: record budget {budget} "
                                f"< {nvan + len(newcells) + len(vt_entries)} "
                                f"entries — the carried-over budget word no "
                                f"longer covers the record")
                    continue
                rec_dst = alloc(sw.get("hole", "a"), len(body),
                                f"select_wheel {nm} record")
                if rec_dst is None:
                    continue

                ops.append({"op": "data", "addr": f"{cl_dst:#x}", "hex": bytes(cl).hex()})
                ops.append({"op": "data", "addr": f"{rec_dst:#x}", "hex": bytes(body).hex()})
                ops.append({"op": "poke32", "addr": f"{recptr:#x}", "val": f"{rec_dst:#x}"})
                notes.append(f"data   {cl_dst:#08x} +{len(cl):#x}  select_wheel {nm} "
                             f"coord list ({nvan} vanilla + {len(newcells)} new "
                             f"+ {len(vt_entries)} version glyphs)")
                notes.append(f"data   {rec_dst:#08x} +{len(body):#x}  select_wheel {nm} "
                             f"record (count {count}->"
                             f"{nvan + len(newcells) + len(vt_entries) - 1}, "
                             f"budget {budget:#x} CARRIED OVER, cptr -> {cl_dst:#x})")
                notes.append(f"poke32 {recptr:#08x} <- {rec_dst:#x}  select_wheel "
                             f"{nm} record ptr (was {rec:#x}; the record's ONLY "
                             f"referrer — vanilla record and list are untouched)")
                fragments.append((rec_dst, len(body), "NEW",
                                  f"select_wheel {nm} record ({nvan + len(newcells)} "
                                  f"cells + {len(vt_entries)} version glyphs)"))
                fragments.append((cl_dst, len(cl), "NEW",
                                  f"select_wheel {nm} coord list"))

                # ── highlight base rows (14z-63, phase 3 item 2): the ring/
                # highlight drawer ($FFBA00) positions per hovered cell via a
                # 32-row pc-relative word-pair table at the site below —
                # variant half a byte-identical ALIAS in vsav (the TABLE B
                # convention), UN-aliased in vs2 where Capcom wrote its
                # newcomers' bases. Without this, hovering an appended cell
                # draws the highlight at the aliased row's base (the
                # misplaced-label report, 14z-62i). In-place overwrite of
                # rows 0x10/0x11/0x13 with the layout's highlight_base pairs;
                # row 0x12 keeps the alias (reserved id). PC-relative reads
                # assert the PROGRAM function code, so the stored bytes are
                # ENCRYPTED — these are code ops, not data ops. Independent
                # of bank5/group C: any extended-wheel build needs it.
                if sw.get("highlight_base_site"):
                    hb_site = _int(sw["highlight_base_site"])
                    opc_hb = (root / "build/out/vsavj_opcodes.bin").read_bytes()
                    lo_half = opc_hb[hb_site:hb_site + 0x40]
                    hi_half = opc_hb[hb_site + 0x40:hb_site + 0x80]
                    if lo_half != hi_half:
                        fail.append(f"select_wheel {nm}: highlight base table "
                                    f"at {hb_site:#x} variant half is NOT an "
                                    f"alias of the base half — wrong site or "
                                    f"moved table")
                        continue
                    nrows = 0
                    for _c, spec in newcells:
                        hb = spec.get("highlight_base")
                        if hb is None:
                            fail.append(f"select_wheel {nm}: cell {_c:#04x} "
                                        f"has no highlight_base in the layout")
                            continue
                        row = hb_site + 4 * _c
                        ops.append({"op": "code", "addr": f"{row:#x}",
                                    "hex": struct.pack(">HH", int(hb[0]),
                                                       int(hb[1])).hex()})
                        nrows += 1
                        notes.append(f"code   {row:#08x} +4     select_wheel "
                                     f"{nm}: highlight base row {_c:#04x} <- "
                                     f"({hb[0]},{hb[1]}) (was the row "
                                     f"{_c & 0x0F:#04x} alias)")
                    notes.append(f"# select_wheel {nm}: {nrows} highlight base "
                                 f"rows written in place (32-row aliased "
                                 f"pc-rel table {hb_site:#x}; the vs2 "
                                 f"precedent — its variant half is un-aliased "
                                 f"for its newcomers)")

                # ── ring_rows (14z-63, maintainer-ratified round 7): the
                # extended cells' hover highlight = the host's ring_ref_cell
                # ring records verbatim (records encode no cell identity; the
                # extended base table above does the placement). P1+P2 rows
                # for cells NOT owned by the tenant (the tenant's own rows
                # ride [[select_records]] art="host_ring"), MIRROR rows
                # (array +0x100) for ALL new cells.
                if sw.get("ring_rows"):
                    hl = _int(sw["highlight_array"])
                    ref_c = _int(sw["ring_ref_cell"])
                    nring = 0
                    for off, halves in ((0x00, "p1"), (0x80, "p2"),
                                        (0x100, "mirror")):
                        lo = vj[hl + off:hl + off + 0x40]
                        hi = vj[hl + off + 0x40:hl + off + 0x80]
                        if lo != hi:
                            fail.append(f"select_wheel {nm}: highlight "
                                        f"{halves} half at {hl + off:#x} is "
                                        f"not 32-row aliased")
                            continue
                        ref_rec = vj_u32(hl + off + 4 * ref_c)
                        ref_fmt = int.from_bytes(vj[ref_rec:ref_rec + 2],
                                                 "big")
                        if ref_fmt not in (0, 2):
                            fail.append(f"select_wheel {nm}: {halves} ring "
                                        f"ref {ref_rec:#x} fmt {ref_fmt:#x} "
                                        f"not a record")
                            continue
                        for _c, spec in newcells:
                            if halves != "mirror" and _c in _tenant_cells:
                                continue   # a tenant's P1/P2 rows are
                                           # select_records host_ring's
                            row = hl + off + 4 * _c
                            ops.append({"op": "poke32", "addr": f"{row:#x}",
                                        "val": f"{ref_rec:#x}"})
                            nring += 1
                            notes.append(f"poke32 {row:#08x} <- {ref_rec:#x}"
                                         f"  select_wheel {nm}: {halves} "
                                         f"highlight row {_c:#04x} = host "
                                         f"row {ref_c:#04x} ring (ring_rows)")
                    notes.append(f"# select_wheel {nm}: {nring} ring rows "
                                 f"poked (host row {ref_c:#04x} records "
                                 f"verbatim; P1/P2 for non-tenant cells + "
                                 f"mirror for all)")

                # ── bank5 (14z-63, phase 3): serve the WHOLE wheel from WIDE
                # group C bank 5 — real medallion art for the appended cells,
                # vanilla-cell pixels identical BY CONSTRUCTION (byte-copied
                # tiles). The wheel drawer is ONE object (one bank word), so
                # per-entry banks are impossible; the measured mechanism:
                #   * select entry inits the drawer ($FFB800) at PRG:0x5F8B2
                #     `move.w #$2000,$18(a6)` — a per-object init that writes
                #     ONLY this object's bank word (family-wide tap, 14z-63),
                #     unlike the shared attract loop at 0x07C428 (stride-0x80
                #     over every menu object — NEVER patch that one).
                #   * on select the drawer's anim chain is a single FF-entry
                #     (0x2689FA -> the wheel record, stop-flagged), so the
                #     flip affects exactly the wheel record's tiles.
                #   * the VS-phase re-init (0x5FD02) rewrites the field, so
                #     the RAM divergence re-converges (§4 v3 window; end
                #     moves ~2362 -> ~2415 on the pick replays).
                # Tile inventory (emitted for build_gfx_donovan --wheel-bank5):
                # every tile of every vanilla entry, host art byte-identical
                # vsav group A -> group C 0x10000+code; the appended entries'
                # native vs2 codes, art from vs2 group A. Gated on a group-C
                # tenant: with the band in banks 2-3 there is no group C to
                # hold the art, and the flip would serve zeros (the m5_wide
                # 0x0F+WIDE shape keeps its placeholder medallions).
                if sw.get("bank5"):
                    from gfx_tiles import bank_word as _bw5
                    if _int(T.get("gfx_bank", 2)) < 4:
                        notes.append(f"# select_wheel {nm}: bank5 SKIPPED — "
                                     f"tenant gfx bank < 4 (no group C); "
                                     f"placeholder medallions retained")
                    else:
                        site = _int(sw["bank_site"])
                        old = bytes.fromhex(sw["bank_site_old"])
                        opc5 = (root / "build/out/vsavj_opcodes.bin").read_bytes()
                        if opc5[site:site + 6] != old:
                            fail.append(f"select_wheel {nm}: bank site "
                                        f"{site:#x} holds "
                                        f"{opc5[site:site+6].hex()}, expected "
                                        f"{old.hex()} (move.w #$2000,$18(a6))")
                            continue
                        newhex = old[:2].hex() + f"{_bw5(5):04x}" + old[4:].hex()
                        ops.append({"op": "code", "addr": f"{site:#x}",
                                    "hex": newhex})

                        def _blk(t, at, into):
                            bx, by = attr_block(at)
                            for dy in range(by):
                                for dx in range(bx):
                                    into.add(cell_at(t, dx, dy))
                        host_t, new_t = set(), set()
                        for k in range(nvan):
                            t5, at5 = struct.unpack(
                                ">HH", vj[rec + 10 + 4 * k:rec + 14 + 4 * k])
                            _blk(t5, at5, host_t)
                        for _c, spec in newcells:
                            _blk(_int(spec["tile"]), _int(spec["attr"]), new_t)
                        both = host_t & new_t
                        if both:
                            fail.append(f"select_wheel {nm}: host/new tile "
                                        f"overlap {sorted(hex(x) for x in both)}")
                            continue
                        _vt_c = {c - 0x10000 for c in vt_tiles}
                        if _vt_c & (host_t | new_t):
                            fail.append(f"select_wheel {nm}: version glyph "
                                        f"codes overlap wheel tiles "
                                        f"{sorted(hex(x) for x in _vt_c & (host_t | new_t))}")
                            continue
                        _wb5 = {"host": sorted(host_t), "vs2": sorted(new_t)}
                        if vt_tiles:
                            # authored glyphs: code (group C index, 0x10000+)
                            # -> canonical 128B tile hex; build_gfx places
                            # them verbatim (provenance "authored")
                            _wb5["authored"] = {f"{c:#x}": h
                                                for c, h in sorted(vt_tiles.items())}
                        write_out(side_name("wheel_bank5.json"), json.dumps(_wb5))
                        notes.append(f"code   {site:#08x} +6     select_wheel "
                                     f"{nm}: drawer bank word #$2000 -> "
                                     f"#${_bw5(5):04x} (bank 5) in the select "
                                     f"init — writes ONLY $FFB818 (measured)")
                        notes.append(f"# select_wheel {nm}: {len(host_t)} host "
                                     f"+ {len(new_t)} vs2 tiles -> "
                                     f"wheel_bank5.json (group C upper bank, "
                                     f"placed by build_gfx --wheel-bank5)")
                        # medallion palettes (14z-63): the vs2 rows into the
                        # select block A's free rows. RESERVED rows refused:
                        # figure bases/swords/ring/host-medallion (measured
                        # select row map).
                        pal_a = _int(sw.get("pal_block_a", 0))
                        src_wp5 = (root / f"build/out/{man['src_set']}"
                                   "_data.bin").read_bytes()
                        RESERVED_PAL = {0x14, 0x15, 0x17, 0x18, 0x1E}
                        for _c, spec in newcells:
                            pr = spec.get("pal_row")
                            ps = spec.get("pal_src")
                            if pr is None or ps is None or not pal_a:
                                fail.append(f"select_wheel {nm}: bank5 cell "
                                            f"{_c:#04x} lacks pal_row/pal_src "
                                            f"(or no pal_block_a) — real art "
                                            f"needs its real palette")
                                continue
                            pr, ps = _int(pr), _int(ps)
                            if pr >= 0x20 or pr in RESERVED_PAL:
                                fail.append(f"select_wheel {nm}: pal_row "
                                            f"{pr:#04x} for cell {_c:#04x} is "
                                            f"reserved or out of range")
                                continue
                            rowb = src_wp5[ps:ps + 0x20]
                            dstp = pal_a + pr * 0x20
                            ops.append({"op": "data", "addr": f"{dstp:#x}",
                                        "hex": rowb.hex()})
                            notes.append(f"data   {dstp:#08x} +0x20  "
                                         f"select_wheel {nm}: medallion pal "
                                         f"row {pr:#04x} (cell {_c:#04x}) <- "
                                         f"vs2 {ps:#x}; entry attr re-palmed")

                        # per-frame palette re-assert (14z-63 round 10 — the
                        # WHITE-OUT fix). The select venue-phase system fades
                        # the whole page from per-phase source blocks the
                        # engine COMPUTES (measured: rows 0x16/0x19/0x00 get
                        # foreign content from 0x3A02C0/0x3A0900/0x3A0960/
                        # 0x3A12C0/0x39A7E0... — sticky, e.g. Donovan's
                        # medallion whiting out), so "a free row" does not
                        # survive phase changes. Instead of chasing every
                        # computed block, the highlight position helper at
                        # 0x5FAD0 — the once-per-select-frame heartbeat,
                        # alive for the screen's whole life — is thunked to
                        # ALSO copy the three block-A rows into palette RAM
                        # (F000-alpha OR, the loader's transform) every
                        # frame: any clobber self-heals next frame, for any
                        # phase known or unknown. Position writes stay
                        # byte-identical (same table via absolute lea);
                        # palette RAM is outside the work-RAM basis, so the
                        # only legacy cost is cycles inside the already-open
                        # select window class. The thunk consumes the whole
                        # 18-byte helper (jsr overwrites its first 3 words;
                        # the remnant is unreachable), so it pops the
                        # helper-internal return and rts's to the caller.
                        # ── march retarget (14z-63 round 10 — the WHITE-OUT
                        # fix). Root cause: the accent MARCH claims palette
                        # row 0x16 in a late select venue phase (the marcher
                        # iterates a row list through the shared uploader's
                        # dest computation at 0x2AD44), overwriting Donovan's
                        # medallion palette with the silver sword march —
                        # invisible on vanilla (row unreferenced), sticky on
                        # ours. Measured: through this uploader row 0x16 is
                        # written ONLY on select (never in matches, 2P
                        # victories, or transitions — those are the fade/load
                        # families), so the redirect is unconditional at the
                        # site: row 0x16 -> row 0x02 (unref-on-select; its
                        # only other select writer is the late hurry phase,
                        # also invisible). Legacy: palette RAM only, both
                        # rows invisible, work RAM untouched (d0 is the
                        # function's own scratch), cycles = the accepted
                        # accent-thunk class on the same call path.
                        mr = sw.get("march_retarget_mid")
                        if mr:
                            # two mid-row dest computations exist (of the four
                            # `move.b $18b(a6),d0` sites): 0x2AD44 (+d1, the
                            # d1-carry family) and 0x2B598 (+1, the per-hover
                            # figure-family writer measured via d0=0xC0 at the
                            # tail). Both are thunked with the same redirect.
                            # Of the THREE dest computations in the
                            # uploader region (add+lsl#5 idiom census), only
                            # TWO are thunked: 0x2AD44 ($18B+d1) is the
                            # IN-MATCH accent path (all four accent sites
                            # funnel through it) — thunking it shifted a
                            # frame-boundary parity permanently (replay 04
                            # f2009 / 05 f9126, the $FF8094 phase flip,
                            # measured 14z-64) AND it never computes the mid
                            # rows on select (the v2 build with it alone
                            # still whited out). The measured select mid-row
                            # writers are the other two. Each thunk also
                            # gates on the select screen being live
                            # ($FFB818 == 0x3000, the wheel drawer's bank
                            # word — set at select entry, cleared by the VS
                            # re-init) as insurance for unmeasured flows.
                            MR_SITES = [
                                (0x2B598, "102e018b5200"),  # $18B + 1 (phase)
                                (0x2B7D8, "102e000fd001"),  # $F + d1 (hover,
                                                            # jump table
                                                            # 0x2B640)
                            ]
                            opc7 = (root / "build/out/vsavj_opcodes.bin"
                                    ).read_bytes()
                            for MR_SITE, MR_OLD in MR_SITES:
                                if opc7[MR_SITE:MR_SITE + 6].hex() != MR_OLD:
                                    fail.append(f"select_wheel {nm}: march "
                                                f"dest site {MR_SITE:#x} holds"
                                                f" {opc7[MR_SITE:MR_SITE+6].hex()}"
                                                f", expected {MR_OLD}")
                                    continue
                                mbody = (
                                    MR_OLD        # the displaced load+add
                                    + "0c000016"  # cmpi.b #$16,d0
                                    "670e"        # beq.b maybe
                                    "0c000019"    # cmpi.b #$19,d0
                                    "6708"        # beq.b maybe
                                    "0c00001a"    # cmpi.b #$1A,d0
                                    "6702"        # beq.b maybe
                                    "4e75"        # rts
                                    # maybe: redirect only while the select
                                    # screen is live (wheel drawer bank word)
                                    "0c79300000ffb818"  # cmpi.w #$3000,$FFB818
                                    "6602"        # bne.b rts
                                    "7002"        # moveq #2,d0
                                    "4e75")       # rts
                                mt = alloc("a", len(mbody) // 2,
                                           f"select_wheel {nm} march mid-row "
                                           f"retarget {MR_SITE:#x}")
                                if mt is None:
                                    continue
                                ops.append({"op": "code", "addr": f"{mt:#x}",
                                            "hex": mbody})
                                ops.append({"op": "code",
                                            "addr": f"{MR_SITE:#x}",
                                            "hex": f"4eb9{mt:08x}"})
                                notes.append(
                                    f"code   {mt:#08x} +{len(mbody)//2:#x}"
                                    f"  select_wheel {nm}: march mid-row "
                                    f"retarget 0x16/0x19 -> 0x02 (dest "
                                    f"computation {MR_SITE:#x} jsr-routed)")
                                fragments.append(
                                    (mt, len(mbody) // 2, "NEW",
                                     f"select_wheel {nm} march mid-row "
                                     f"retarget {MR_SITE:#x}"))

                        # DISABLED by default (pal_reassert flag): measured
                        # 14z-63 round 10 — even a check-then-copy version
                        # perturbs the legacy fade system (the fade reads
                        # back re-asserted values; its step counters at
                        # $FF0E94/A4/B4/C4 diverge on every fade and never
                        # re-converge). Superseded by march_retarget above.
                        hb_site2 = (_int(sw.get("highlight_base_site", 0))
                                    if sw.get("pal_reassert") else 0)
                        if hb_site2:
                            HELPER = 0x5FAD0
                            OLD6 = "3006e5483d7b"
                            opc6 = (root / "build/out/vsavj_opcodes.bin"
                                    ).read_bytes()
                            if opc6[HELPER:HELPER + 6].hex() != OLD6:
                                fail.append(f"select_wheel {nm}: helper "
                                            f"{HELPER:#x} holds "
                                            f"{opc6[HELPER:HELPER+6].hex()}, "
                                            f"expected {OLD6}")
                                continue
                            # check-then-copy: an always-copy version cost
                            # ~700 cycles/frame and SHIFTED a legacy
                            # input-accept boundary (replay 11's pick moved
                            # a tick; the match never re-converged — a real
                            # violation, measured). The steady-state path is
                            # three cmpi.w probes on each row's WORD 1 (word
                            # 0 collides: Phobos's f111 == the grey ramp's)
                            # + an early exit; the copy loops run only on
                            # the frame after an actual clobber.
                            prefix = (
                                "2f08"                       # move.l a0,-(sp)
                                "3006"                       # move.w d6,d0
                                "e548"                       # lsl.w #2,d0
                                f"41f9{hb_site2:08x}"        # lea table.l,a0
                                "3d7000000010"               # move.w (a0,d0.w),$10(a6)
                                "3d7000020014"               # move.w 2(a0,d0.w),$14(a6)
                                "205f"                       # movea.l (sp)+,a0
                            )
                            checks = ""
                            n_c = len(newcells)
                            for i, (_c2, spec2) in enumerate(newcells):
                                pr2 = _int(spec2["pal_row"])
                                rowb2 = src_wp5[_int(spec2["pal_src"]) + 2:
                                                _int(spec2["pal_src"]) + 4]
                                w1 = ((rowb2[0] | 0xF0) << 8) | rowb2[1]
                                dst2 = 0x90C000 + pr2 * 0x20 + 2
                                # bne.b to heal: remaining checks then exit(4)
                                remaining = (n_c - 1 - i) * 10
                                disp = remaining + 4
                                checks += (f"0c79{w1:04x}{dst2:08x}"
                                           f"66{disp:02x}")
                            exit_ = "588f4e75"               # addq #4,sp; rts
                            heal = "48e740c0"                # movem.l d1/a0-a1,-(sp)
                            for _c2, spec2 in newcells:
                                pr2 = _int(spec2["pal_row"])
                                src2 = pal_a + pr2 * 0x20
                                dst2 = 0x90C000 + pr2 * 0x20
                                heal += (
                                    f"41f9{src2:08x}"        # lea src.l,a0
                                    f"43f9{dst2:08x}"        # lea dst.l,a1
                                    "700f"                   # moveq #15,d0
                                    "3218"                   # move.w (a0)+,d1
                                    "0041f000"               # ori.w #$F000,d1
                                    "32c1"                   # move.w d1,(a1)+
                                    "51c8fff6"               # dbra d0,.-8
                                )
                            heal += ("4cdf0302"              # movem.l (sp)+,d1/a0-a1
                                     "588f4e75")             # addq #4,sp; rts
                            body = prefix + checks + exit_ + heal
                            tk2 = alloc("a", len(body) // 2,
                                        f"select_wheel {nm} pal re-assert thunk")
                            if tk2 is not None:
                                ops.append({"op": "code", "addr": f"{tk2:#x}",
                                            "hex": body})
                                ops.append({"op": "code",
                                            "addr": f"{HELPER:#x}",
                                            "hex": f"4eb9{tk2:08x}"})
                                notes.append(f"code   {tk2:#08x} +{len(body)//2:#x}"
                                             f"  select_wheel {nm}: per-frame "
                                             f"medallion-palette re-assert "
                                             f"(the select heartbeat helper "
                                             f"{HELPER:#x} jsr-routed; position "
                                             f"writes byte-identical, 3 rows "
                                             f"re-copied each frame)")
                                fragments.append((tk2, len(body) // 2, "NEW",
                                                  f"select_wheel {nm} pal "
                                                  f"re-assert thunk"))

        # ── select_records (M3a, 14z-62): the tenant's OWN select records at a
        # variant id — what the hovered cell displays. Three UI pieces (portrait,
        # name banner, cursor highlight) each ride a 32-row x 4-byte
        # record-pointer array per player (P2 array = P1 + 0x80), indexed by the
        # cursor CELL/ID with NO 4-bit fold; rows 0x10-0x1F alias 0x00-0x0F in
        # vanilla, and no legacy gameplay path writes a variant-half id — so
        # repointing the tenant's two rows per piece touches nothing legacy
        # content can reach, BY CONSTRUCTION (docs/game/atlas/select_screen.md;
        # tests/test_select_arrays.sh, tests/audit_id_writers.sh). At the
        # substituted slot 0x0F this section is INERT: select_port.py's in-place
        # surgery remains that track's mechanism, and the frozen references
        # rebuild byte-identically.
        #
        # Composed records keep VS2'S OWN budget words: the budget debits the OBJ
        # emitter's shared frame budget only on frames that DRAW the record, and
        # a variant row draws only when the tenant is hovered — new-character
        # content by definition (contrast select_port's in-place surgery, which
        # must keep the host's budget because legacy cursors visit slot 0x0F).
        #
        # Tile codes are remapped through select_port.PLACEMENTS (the single
        # placement map — the tenant's select art still sits in the host band
        # until the gfx half moves it to WIDE group C). Entries with no placement
        # keep their vs2 codes as DOCUMENTED PLACEHOLDERS where the manifest row
        # allows it (the ratified medallion policy: imperfect art is acceptable,
        # mechanical soundness is not). The pairs the composed records rely on
        # are emitted as select_tiles.json so the gfx stage places exactly the
        # art these records reference — and none of the slot-0x0F-only families
        # (splash/win-quote), whose Jedah art therefore returns to vanilla on
        # variant-id builds.
        #
        # Slice C: the variant-id test moved off the build scalar and onto each
        # row's OWNER. The section is variant-only BY CONSTRUCTION (no row
        # carries a key), so it is declared here rather than in the manifest. A
        # merged build can hold a base-half tenant and a variant tenant at once,
        # which is exactly what a single outer test cannot express.
        _sel_rows = [sr for sr in tenant_rows("select_records")
                     if row_applies(sr, owner_of(sr), only_variant=True)]
        if args.stage >= 6 and _sel_rows:
            import select_port as _selp
            src_data = (root / f"build/out/{man['src_set']}_data.bin").read_bytes()

            def _u16(b, o):
                return int.from_bytes(b[o:o + 2], "big")

            def _u32(b, o):
                return int.from_bytes(b[o:o + 4], "big")

            sel_pairs = {}
            sel_bank5 = set()
            for sr in _sel_rows:
                if args.stage < _int(sr.get("stage", 0)):
                    continue
                nm = sr["name"]
                # Slice D: this row's identity is its OWNER's — both the vsavj
                # row it repoints and the vs2 SOURCE character it reads from.
                _sown = owner_of(sr)
                _srow = _int(_sown["dst_slot"])
                _src_char = _int(_sown["src_char"])
                # art = "native_c5" (14z-62j, option A): the record keeps its
                # NATIVE vs2 tile codes and the art rides WIDE group C bank 5
                # at 0x10000+code — no placement map, no placeholders. The
                # piece's drawer object must be bank-gated on the tenant
                # (the palette thunk does the portrait's).
                # art = "host_ring" (14z-63, maintainer-ratified): the piece's
                # vs2 record is the WRONG UI piece for this slot (vs2's
                # post-confirm name bar vs vsavj's hover ring), so the
                # tenant's rows point at the HOST's ring_ref_cell record
                # VERBATIM — no composition, no allocation, no vs2 read.
                _native = sr.get("art") == "native_c5"
                _host_ring = sr.get("art") == "host_ring"
                for side in ("p1", "p2"):
                    # single-sided pieces (14z-62e: splash P1/P2 and the win
                    # quote are each ONE array, not a +0x80 pair) declare only
                    # the keys they have
                    if f"vj_{side}" not in sr:
                        continue
                    vj_base = _int(sr[f"vj_{side}"])
                    vj_row = vj_base + 4 * _srow
                    vj_alias = vj_base + 4 * (_srow & 0x0F)
                    exp_alias = _int(sr[f"expect_vj_alias_{side}"])
                    vsrc = _u32(src_data, _int(sr[f"vs2_{side}"]) + 4 * _src_char)
                    bad = []
                    if vj_u32(vj_alias) != exp_alias:
                        bad.append(f"vj base-half row {vj_alias:#x} holds "
                                   f"{vj_u32(vj_alias):#x}, expected {exp_alias:#x}")
                    if vj_u32(vj_row) != exp_alias:
                        bad.append(f"vj variant row {vj_row:#x} holds "
                                   f"{vj_u32(vj_row):#x} — does not alias its "
                                   f"base-half counterpart {exp_alias:#x}")
                    if vsrc != _int(sr[f"expect_vs2_{side}"]):
                        bad.append(f"vs2 {side} row holds {vsrc:#x}, expected "
                                   f"{_int(sr[f'expect_vs2_{side}']):#x}")
                    if bad:
                        fail.append(f"select_records {nm}/{side}: vanilla anchors "
                                    "moved: " + "; ".join(bad))
                        continue
                    if _host_ring:
                        ref_c = _int(sr["ring_ref_cell"])
                        ref_rec = vj_u32(vj_base + 4 * ref_c)
                        ref_fmt = int.from_bytes(vj[ref_rec:ref_rec + 2], "big")
                        if ref_fmt not in (0, 2):
                            fail.append(f"select_records {nm}/{side}: ring ref "
                                        f"row {ref_c:#04x} record {ref_rec:#x} "
                                        f"fmt {ref_fmt:#x} not a record")
                            continue
                        ops.append({"op": "poke32", "addr": f"{vj_row:#x}",
                                    "val": f"{ref_rec:#x}"})
                        notes.append(f"poke32 {vj_row:#08x} <- {ref_rec:#x}  "
                                     f"select_records {nm}/{side} array row "
                                     f"{_srow:#04x} = the HOST row "
                                     f"{ref_c:#04x} ring record VERBATIM "
                                     f"(host_ring; was {exp_alias:#x})")
                        continue
                    fmt, bud, cm1 = struct.unpack(">HHH", src_data[vsrc:vsrc + 6])
                    cnt = cm1 + 1
                    cptr = _u32(src_data, vsrc + 6)
                    ents = [(_u16(src_data, vsrc + 10 + 4 * k),
                             _u16(src_data, vsrc + 12 + 4 * k)) for k in range(cnt)]
                    new_ents, holders = [], []
                    for t, at in ents:
                        bx, by = attr_block(at)
                        if _native:
                            new_ents.append((t, at))
                            for dy in range(by):
                                for dx in range(bx):
                                    sel_bank5.add(cell_at(t, dx, dy))
                            continue
                        anchor = _selp.PLACEMENTS.get((t, bx, by))
                        if anchor is None:
                            if not sr.get("allow_placeholder_tiles", False):
                                fail.append(
                                    f"select_records {nm}/{side}: no placement "
                                    f"for block (0x{t:04X},{bx},{by}) and "
                                    f"placeholders not allowed for this piece")
                            holders.append(t)
                            new_ents.append((t, at))
                            continue
                        new_ents.append((anchor, at))
                        for dy in range(by):
                            for dx in range(bx):
                                s = cell_at(t, dx, dy)
                                d = cell_at(anchor, dx, dy)
                                if sel_pairs.get(s, d) != d:
                                    fail.append(f"select_records {nm}/{side}: "
                                                f"conflicting placement for tile "
                                                f"0x{s:04X}")
                                sel_pairs[s] = d
                    cl = src_data[cptr:cptr + 4 * cnt]
                    cl_dst = alloc(sr.get("hole", "a"), len(cl),
                                   f"select_records {nm}/{side} coords")
                    if cl_dst is None:
                        continue
                    body = struct.pack(">HHH", fmt, bud, cnt - 1)
                    body += cl_dst.to_bytes(4, "big")
                    for t, at in new_ents:
                        body += struct.pack(">HH", t, at)
                    rec_dst = alloc(sr.get("hole", "a"), len(body),
                                    f"select_records {nm}/{side} record")
                    if rec_dst is None:
                        continue
                    ops.append({"op": "data", "addr": f"{cl_dst:#x}",
                                "hex": cl.hex()})
                    ops.append({"op": "data", "addr": f"{rec_dst:#x}",
                                "hex": body.hex()})
                    ops.append({"op": "poke32", "addr": f"{vj_row:#x}",
                                "val": f"{rec_dst:#x}"})
                    ph = ("" if not holders else
                          ", PLACEHOLDER tile code(s) "
                          + "/".join(f"0x{t:04X}" for t in holders)
                          + " — unplaced until the gfx half")
                    notes.append(f"data   {cl_dst:#08x} +{len(cl):#x}  "
                                 f"select_records {nm}/{side} coord list "
                                 f"({cnt} pairs, vs2 {cptr:#x})")
                    notes.append(f"data   {rec_dst:#08x} +{len(body):#x}  "
                                 f"select_records {nm}/{side} record (vs2 "
                                 f"{vsrc:#x}, {cnt} entries, budget {bud:#x} = "
                                 f"vs2's own{ph})")
                    notes.append(f"poke32 {vj_row:#08x} <- {rec_dst:#x}  "
                                 f"select_records {nm}/{side} array row "
                                 f"{_srow:#04x} (was {exp_alias:#x}, the "
                                 f"base-half alias)")
                    fragments.append((cl_dst, len(cl), "VS2",
                                      f"select_records {nm}/{side} coord list"))
                    fragments.append((rec_dst, len(body), "VS2",
                                      f"select_records {nm}/{side} record"))
            _pairs = sorted([s, d] for s, d in sel_pairs.items())
            write_out(side_name("select_tiles.json"),
                      json.dumps(_pairs).encode(), "select_records")
            notes.append(f"# select_records: {len(_pairs)} bank-1 tile placements "
                         f"-> select_tiles.json (only the composed records' art; "
                         f"the slot-0x0F splash/win-quote families are NOT "
                         f"placed, so that Jedah art stays vanilla)")
            write_out(side_name("select_bank5.json"),
                      json.dumps(sorted(sel_bank5)).encode(),
                      "select_records")
            notes.append(f"# select_records: {len(sel_bank5)} native bank-1 "
                         f"tiles -> select_bank5.json (copied vs2 -> group C "
                         f"bank 5 by build_gfx; the drawer's bank is thunk-"
                         f"gated per hover)")

        # ── win_pal_variant (14z-63, phase 3 item 5): the tenant's win-screen
        # palette at a variant id. The sparse-block design: a block laid out
        # with the VANILLA pool's color stride, only the tenant's sets
        # populated, and a thunk at the pool-base load that rebases
        # a0 = block - TT*unit when the winner is the tenant — the vanilla
        # (color*17 + id)*unit arithmetic then lands each color on the
        # tenant's set. Variant-id builds only; the 0x0F track keeps its
        # in-place slice replacement (win_pal_slot0f_c0..c7).
        #
        # Slice C: variant-only BY CONSTRUCTION, per the row's OWNER — same
        # reasoning as select_records above.
        # N-WAY, BY CONCATENATION (14z-80h). This is ONE thunk at ONE
        # shared site (0x5F1B6), so N tenants cannot each patch it — that was
        # 2 of the merged patch's 4 remaining op collisions. The body's shape
        # makes the N-way form free: each element is
        #     cmpi.b #TT,d6 / bne.b +8 / movea.l #rebase,a0 / rts
        # i.e. 14 bytes whose `bne.b +8` skips exactly its own movea+rts, so
        # "the next element" and "the vanilla tail" are the SAME target and
        # chaining is a pure CONCATENATION with no displacement to recompute. For one tenant the emitted bytes are therefore identical
        # to the single-element form this replaces — which is why the three
        # frozen verticals do not move.
        #
        # ENGINE-LEVEL: emitted once, on the last iteration, over EVERY
        # tenant's rows (engine_rows) rather than per iteration.
        _wp_rows = [wp for wp in engine_rows("win_pal_variant")
                    if row_applies(wp, owner_of(wp), only_variant=True)]
        if args.stage >= 6 and _wp_rows:
            _wp_sites = {}          # site -> [(name, row, rebase, pool)]
            for wp in _wp_rows:
                if args.stage < _int(wp.get("stage", 0)):
                    continue
                nm = wp["name"]
                site = _int(wp["site"])
                old = bytes.fromhex(wp["site_old"])
                opc_wp = (root / "build/out/vsavj_opcodes.bin").read_bytes()
                if opc_wp[site:site + 6] != old:
                    fail.append(f"win_pal_variant {nm}: site {site:#x} holds "
                                f"{opc_wp[site:site+6].hex()}, expected "
                                f"{old.hex()}")
                    continue
                pool = _int(wp["pool_base"])
                if old[2:6] != pool.to_bytes(4, "big"):
                    fail.append(f"win_pal_variant {nm}: site_old operand != "
                                f"pool_base {pool:#x}")
                    continue
                cstride = _int(wp["pool_color_stride"])
                unit = _int(wp["unit"])
                ncol = _int(wp["colors"])
                vsrc = _int(wp["vs2_src"])
                vstride = _int(wp["vs2_color_stride"])
                src_data = (root / f"build/out/{man['src_set']}_data.bin"
                            ).read_bytes()
                blk_len = (ncol - 1) * cstride + unit
                blk = alloc(wp.get("hole", "a"), blk_len,
                            f"win_pal_variant {nm} sparse block")
                if blk is None:
                    continue
                for c in range(ncol):
                    sl = src_data[vsrc + c * vstride:vsrc + c * vstride + unit]
                    if len(sl) != unit:
                        fail.append(f"win_pal_variant {nm}: vs2 slice {c} "
                                    f"read short")
                        break
                    ops.append({"op": "data",
                                "addr": f"{blk + c * cstride:#x}",
                                "hex": sl.hex()})
                else:
                    # One CHAIN ELEMENT per tenant. d6 holds the winner id at
                    # the site; movea sets no flags and the fall-through
                    # (moveq #0,d0) defines its own, so the CCR clobber is
                    # safe. Slice E: the id in the compare is the ROW OWNER's.
                    _wrow = _int(owner_of(wp)["dst_slot"])
                    rebase = blk - _wrow * unit
                    _wp_sites.setdefault(site, []).append(
                        {"name": nm, "row": _wrow, "rebase": rebase,
                         "pool": pool})
                    notes.append(f"data   {blk:#08x} +{blk_len:#x}  "
                                 f"win_pal_variant {nm}: sparse block, "
                                 f"{ncol} sets of {unit:#x} at stride "
                                 f"{cstride:#x} (vs2 {vsrc:#x} "
                                 f"stride {vstride:#x})")
                    fragments.append((blk, blk_len, "VS2",
                                      f"win_pal_variant {nm} sparse block"))

            # ONE thunk per site, whichever tenants declared it. Elements in
            # declaration order; the vanilla tail last, reached by any
            # element whose compare fails.
            for _site, _els in sorted(_wp_sites.items()):
                _pools = {e["pool"] for e in _els}
                if len(_pools) != 1:
                    fail.append(f"win_pal_variant @{_site:#x}: tenants declare "
                                f"different pool bases {sorted(_pools)} — one "
                                f"thunk cannot serve them")
                    continue
                _pool = _pools.pop()
                body = "".join(f"0c06{e['row']:04x}"      # cmpi.b #TT,d6
                               f"6608"                    # bne.b +8 -> next
                               f"207c{e['rebase']:08x}"   # movea.l #rebase,a0
                               f"4e75"                    # rts
                               for e in _els)
                body += f"207c{_pool:08x}4e75"            # vanilla tail
                tk = alloc("a", len(body) // 2, "win_pal_variant thunk")
                if tk is None:
                    continue
                ops.append({"op": "code", "addr": f"{tk:#x}", "hex": body})
                ops.append({"op": "code", "addr": f"{_site:#x}",
                            "hex": f"4eb9{tk:08x}"})
                notes.append(f"code   {tk:#08x} +{len(body)//2:#x}  "
                             f"win_pal_variant thunk, {len(_els)}-way: "
                             + ", ".join(f"{e['name']} d6=={e['row']:#04x} -> "
                                         f"a0={e['rebase']:#x}" for e in _els)
                             + f"; else vanilla pool {_pool:#x}")
                notes.append(f"code   {_site:#08x} +6     win_pal_variant: "
                             f"movea.l #pool -> jsr {tk:#x}")
                fragments.append((tk, len(body) // 2, "NEW",
                                  f"win_pal_variant {len(_els)}-way thunk"))

        # ── site_thunk: generic 6-byte engine-site -> jsr thunk (14q pattern) ───
        # The thunk body is authored hex (must preserve the displaced
        # instruction's semantics on its vanilla path, including flags where
        # the fall-through consumes them). Old bytes verified against the
        # vanilla opcode image; thunk placed in hole "a"; site patched to
        # jsr thunk (6 bytes, code-op so it re-encrypts).
        # 14z-66: the block gate dropped from 6 to 4 (the shadow-seq guard is
        # a stage-4 behavior thunk) with the per-row DEFAULT stage raised to 6
        # — every pre-existing row declares stage explicitly (6 or 99), so
        # emission is unchanged for them at every stage (m3a gate verifies).
        # patch = "jmp" emits a stack-neutral jmp instead of jsr, for sites
        # whose displaced instruction is itself a jmp (the thunk must then end
        # by continuing the flow, never rts).
        if args.stage >= 4:
            opc_img_st = None
            for st in tenant_rows("site_thunk"):
                if args.stage < _int(st.get("stage", 6)):
                    continue
                nm = st["name"]
                # profile (14z-105): a thunk that exists only under a build
                # profile (the Oboro select hook — roster UX, so WIDE-only by
                # construction; the stock twin must stay bit-identical). Same
                # key and semantics as [[select_wheel]]/[[sound_table]].
                if st.get("profile") and st["profile"] != args.profile:
                    notes.append(f"# site_thunk {nm}: SKIPPED (profile "
                                 f"{st['profile']!r} != {args.profile!r})")
                    continue
                # only_variant_slot (14z-62e), by the row's OWNER (slice C): a
                # thunk that exists only for the de-substituted tenant (e.g. the
                # select-palette redirect, whose block lives in profile-gated
                # space). Skipped at base-half slots, where the in-place
                # mechanisms serve.
                _own = owner_of(st)
                if not row_applies(st, _own):
                    notes.append(f"# site_thunk {nm}: SKIPPED (variant-id-only; "
                                 f"tenant is at {_int(_own['dst_slot']):#04x})")
                    continue
                site = _int(st["site"])
                old = bytes.fromhex(st["old_hex"])
                if len(old) != 6:
                    fail.append(f"site_thunk {nm}: displaced site must be 6 bytes")
                    continue
                if opc_img_st is None:
                    opc_img_st = (root / "build/out/vsavj_opcodes.bin").read_bytes()
                if opc_img_st[site:site + 6] != old:
                    fail.append(f"site_thunk {nm}: vanilla bytes at {site:#x} != "
                                f"old_hex ({opc_img_st[site:site+6].hex()})")
                    continue
                # A site_thunk's body is HAND-AUTHORED machine code, and some of
                # it compares against the tenant's character id
                # (`cmpi.b #<id>,$FF8782` / `$FF8B82`). That id was written as a
                # literal byte inside the hex string, where a tenant move would
                # be silently wrong rather than loud: the thunk would keep
                # gating on 0x0F, so the tenant would take the vanilla path and
                # the OLD occupant of 0x0F would take the ported one, with
                # nothing to crash.
                #
                # `TT` in the hex is substituted with the tenant id and tracks it
                # forever. A stale LITERAL is a hard failure rather than an
                # automatic rewrite — silently editing authored code could mask a
                # thunk that compares against some other character on purpose.
                _hx = st["thunk_hex"].lower()
                # The AUTHORED body, before any substitution — the stale
                # placed-address guard below reads this, not _hx: after
                # region_subst/data_subst run, a placed address in the body is
                # exactly what we asked for, so only the pre-substitution text
                # can tell an authored literal from a resolved one.
                _hx_authored = _hx
                # Slice E: TT/TU (and row_subst below, which derives from _tid)
                # take the ROW OWNER's id. Same open N-tenant question as the
                # win-pal thunk: the three `*_bank_variant_id` rows are declared
                # identically by all three tenants at ONE shared site each, so the
                # merge dedups them to one thunk whose body tests N ids.
                _tid = _int(owner_of(st)["dst_slot"]) & 0xFF
                # TU (14z-62j): the tenant id under the WIN-QUOTE consumer bias
                # (+0x40 rows — the shared consumer at 0x5F328 receives d0
                # pre-biased per piece). Replaced before TT ("tu" contains no
                # "tt").
                _hx = _hx.replace("tu", "%02x" % ((_tid + 0x40) & 0xFF))
                _hx = _hx.replace("tt", "%02x" % _tid)
                # row_subst (14z-62c): a thunk body may embed the ADDRESS of a
                # per-char table row (e.g. the accent thunks read the sprite
                # palette table's tenant row). Hardcoding it froze row 0x0F into
                # the body exactly like the id literal did. The manifest names a
                # non-hex placeholder and the table base; the substituted value
                # is base + 4*tenant, so the body tracks the tenant forever.
                for _kv in str(st.get("row_subst", "")).split(","):
                    if not _kv.strip():
                        continue
                    _ph, _, _tb = _kv.partition("=")
                    _ph = _ph.strip().lower()
                    if _ph not in _hx:
                        fail.append(f"site_thunk {st['name']}: row_subst "
                                    f"placeholder '{_ph}' not present in "
                                    f"thunk_hex")
                    _hx = _hx.replace(
                        _ph, "%08x" % (_int(_tb.strip()) + 4 * _tid))
                # region_subst (14z-66): "placeholder=region:offset" — the thunk
                # embeds the PLACED address of an extracted region (+offset),
                # e.g. the tenant_jump_seq thunk aims the clone's sub-state
                # table. Resolved from the placement map, so the body tracks
                # wherever the allocator puts the region.
                for _kv in str(st.get("region_subst", "")).split(","):
                    if not _kv.strip():
                        continue
                    _ph, _, _spec = _kv.partition("=")
                    _ph = _ph.strip().lower()
                    _rn, _, _ro = _spec.strip().partition(":")
                    if _rn not in placed:
                        fail.append(f"site_thunk {st['name']}: region_subst "
                                    f"region '{_rn}' not placed at this stage")
                        continue
                    if _ph not in _hx:
                        fail.append(f"site_thunk {st['name']}: region_subst "
                                    f"placeholder '{_ph}' not present in "
                                    f"thunk_hex")
                    _hx = _hx.replace(
                        _ph, "%08x" % (placed[_rn] + _int(_ro or "0")))
                # data_subst (14z-62e): "placeholder=src:len:hole" — the thunk
                # embeds the address of a SOURCE-SET data block; the generator
                # reads it, places it via the space model, emits the data op,
                # and substitutes the allocated address into the body.
                # GATHER form (14z-67): "placeholder=src:len:hole:xN@STRIDE" —
                # N chunks of len bytes at STRIDE intervals, concatenated into
                # one contiguous placed block (a strided GRID COLUMN, e.g.
                # Huitzil's select-portrait palette rows: the vs2 uploader
                # remaps him INTO the grid at column 0x0B rather than giving
                # him a dedicated block like Donovan's).
                for _kv in str(st.get("data_subst", "")).split(","):
                    if not _kv.strip():
                        continue
                    _ph, _, _spec = _kv.partition("=")
                    _ph = _ph.strip().lower()
                    _parts = _spec.strip().split(":")
                    _srcs, _lens, _hole = _parts[0], _parts[1], _parts[2]
                    _dsrc, _dlen = _int(_srcs), _int(_lens)
                    _sdat = (root / f"build/out/{man['src_set']}_data.bin"
                             ).read_bytes()
                    if len(_parts) > 3 and _parts[3].startswith("x"):
                        _n, _stride = _parts[3][1:].split("@")
                        _n, _stride = int(_n, 0), int(_stride, 0)
                        _blob = b"".join(
                            _sdat[_dsrc + _k * _stride:
                                  _dsrc + _k * _stride + _dlen]
                            for _k in range(_n))
                        _dlen = _dlen * _n
                    else:
                        _blob = _sdat[_dsrc:_dsrc + _dlen]
                    if len(_blob) != _dlen:
                        fail.append(f"site_thunk {st['name']}: data_subst src "
                                    f"read short")
                        continue
                    _da = alloc(_hole, _dlen,
                                f"site_thunk {st['name']} data block")
                    if _da is None:
                        continue
                    ops.append({"op": "data", "addr": f"{_da:#x}",
                                "hex": _blob.hex()})
                    notes.append(f"data   {_da:#08x} +{_dlen:#x}  site_thunk "
                                 f"{st['name']} data block <- {man['src_set']} "
                                 f"{_dsrc:#08x}")
                    fragments.append((_da, _dlen, "VS2",
                                      f"site_thunk {st['name']} data block"))
                    if _ph not in _hx:
                        fail.append(f"site_thunk {st['name']}: data_subst "
                                    f"placeholder '{_ph}' not present in "
                                    f"thunk_hex")
                    _hx = _hx.replace(_ph, "%08x" % _da)
                for _fld in ("00ff8782", "00ff8b82"):
                    _i = 0
                    while True:
                        _i = _hx.find("0c3900", _i)
                        if _i < 0:
                            break
                        if _hx[_i + 8:_i + 16] == _fld:
                            _got = int(_hx[_i + 6:_i + 8], 16)
                            if _got != _tid:
                                fail.append(
                                    f"site_thunk {st['name']}: body compares the "
                                    f"char id against {_got:#04x} at hex offset "
                                    f"{_i + 6}, but the tenant is {_tid:#04x}. "
                                    f"Write 'TT' there so it tracks the tenant.")
                        _i += 6
                # The same trap in ADDRESS-REGISTER-RELATIVE form (14z-62c —
                # this is how four accent thunks and the companion/LS thunks
                # kept gating on 0x0F after the tenant moved: the original
                # guard only knew the absolute `cmpi.b #id,$FF8x82.l` shape).
                # cmpi.b #imm,(d16,An) = 0C28+n; the id lives at displacement
                # $382 (the char-id field) or $A (the select keeper's cached
                # owner id). Word-aligned scan; a mismatch is a hard failure.
                import re as _re
                # id_literal_ok (14z-66): ids a thunk COMPARES ON PURPOSE that
                # are not the tenant — e.g. a displaced VANILLA id test the
                # thunk re-executes verbatim (the tenant_jump_seq thunk
                # re-runs the engine's own Anakaris cmpi). Listed explicitly
                # so the stale-literal guard stays loud for everything else.
                _ok_ids = {_int(x) for x in
                           str(st.get("id_literal_ok", "")).split(",") if x.strip()}
                for _m in _re.finditer(r"0c2[89abcdef]00([0-9a-f]{2})(0382|000a)",
                                       _hx):
                    if _m.start() % 4:
                        continue        # not instruction-aligned — embedded data
                    _got = int(_m.group(1), 16)
                    if _got in _ok_ids:
                        continue
                    if _got != _tid:
                        fail.append(
                            f"site_thunk {st['name']}: body compares a char/owner "
                            f"id field against {_got:#04x} at hex offset "
                            f"{_m.start() + 6} (An-relative form), but the tenant "
                            f"is {_tid:#04x}. Write 'TT' there so it tracks the "
                            f"tenant.")
                # STALE PLACED-ADDRESS guard (14z-78). The two guards above are
                # the same trap one dimension over: an authored body that bakes
                # a value the BUILD chooses. They cover the tenant id; this one
                # covers the ALLOCATOR's output.
                #
                # Paid for by M3b's only remaining blocker. The two select-
                # companion thunks carried `207c000dda1e` (movea.l
                # #$000DDA1E,A0) — anim's placed address, hand-computed once.
                # It tracked nothing, so relocating `anim` left both bodies
                # aiming into whatever slid into the vacated range; the resolver
                # read those bytes as 16-bit offsets and took an address error
                # at vanilla PC 0x015098. Nothing failed at BUILD time, which is
                # why "anim cannot move" stood as a layout constraint for a
                # session. `region_subst` is the correct spelling and this makes
                # the wrong one loud.
                #
                # Anchored on the opcodes that take a 32-bit absolute/immediate
                # operand, and word-aligned — an unanchored scan reads operand
                # pairs as addresses (e.g. a body ending `...0040` + `4e75`
                # parses as 0x00404E75, inside wide_ext) and would be noise.
                # That anchor set is therefore this guard's coverage boundary:
                # a placed address reached some other way (a raw longword in an
                # embedded data table) is NOT caught here.
                _abs_ops = {"4ef9": "jmp", "4eb9": "jsr", "4879": "pea"}
                for _r in range(8):
                    _abs_ops["%04x" % (0x207C + _r * 0x200)] = f"movea.l ->A{_r}"
                    _abs_ops["%04x" % (0x41F9 + _r * 0x200)] = f"lea ->A{_r}"
                    _abs_ops["%04x" % (0x203C + _r * 0x200)] = f"move.l ->D{_r}"
                    _abs_ops["%04x" % (0x2039 + _r * 0x200)] = f"move.l abs->D{_r}"
                # addr_literal_ok: a literal that is placement-valued ON PURPOSE
                # (same escape hatch as id_literal_ok above).
                _ok_addrs = {_int(x) for x in
                             str(st.get("addr_literal_ok", "")).split(",")
                             if x.strip()}
                for _i in range(0, len(_hx_authored) - 11, 4):   # word-aligned
                    if _hx_authored[_i:_i + 4] not in _abs_ops:
                        continue
                    _w = _hx_authored[_i + 4:_i + 12]
                    if len(_w) < 8 or not all(c in "0123456789abcdef" for c in _w):
                        continue        # a placeholder, or runs off the end
                    _v = int(_w, 16)
                    if _v in _ok_addrs:
                        continue
                    for _rn in sorted(placed):
                        _lo = placed[_rn]
                        _hi = _lo + regions[_rn]["len"]
                        if _lo <= _v < _hi:
                            fail.append(
                                f"site_thunk {st['name']}: body bakes "
                                f"{_v:#08x} ({_abs_ops[_hx_authored[_i:_i + 4]]}) "
                                f"at hex offset {_i + 4}, which is inside placed "
                                f"region '{_rn}' ({_lo:#08x}+{_hi - _lo:#x}). A "
                                f"placed address does NOT track the allocator — "
                                f"write a placeholder and "
                                f"region_subst = \"<ph>={_rn}:{_v - _lo:#x}\", or "
                                f"list it in addr_literal_ok if it is meant to be "
                                f"a fixed address.")
                            break
                body = bytes.fromhex(_hx)
                if site in _st_multi:
                    # More than one tenant declares this site: record THIS
                    # tenant's fully-substituted body (built with its own
                    # placements) and let the chain pass below emit one thunk
                    # for all of them. Never reached on a single-tenant build,
                    # where no site is multi-declared.
                    _st_multi_bodies.setdefault(site, []).append(
                        (nm, body, st.get("patch", "jsr"), old))
                    notes.append(f"# site_thunk {nm}: body deferred to the "
                                 f"{site:#08x} chain ({len(body)} bytes)")
                    continue
                # hole "b" is REQUIRED for thunks carrying embedded data read
                # via data loads: hole "a" lies inside the CPS-2 crypt range,
                # where placed bytes are stored re-encrypted for opcode
                # fetches — data reads bypass decryption and see ciphertext
                # (14z-20, paid for; docs/GOTCHAS.md).
                hole_sel = st.get("hole", "a")
                td = alloc(hole_sel, len(body), f"site_thunk {nm}")
                if td is None:
                    fail.append(f"site_thunk {nm}: no room in hole {hole_sel}")
                    continue
                patch_kind = st.get("patch", "jsr")
                # rts_ok (14z-71): the site is the head of a CALLED HANDLER, not a
                # point in a fall-through flow — the engine reaches it through a
                # dispatch and every sibling handler exits by `rts`. There, `rts`
                # is the CORRECT exit and jmp_ok's assertion ("the body never
                # rts's") is simply the wrong claim to make; asserting it would
                # be a lie in the manifest. A separate flag keeps jmp_ok's meaning
                # intact and states this site's actual contract: the body may rts,
                # and any path that declines the work must re-enter the displaced
                # original by jmp.
                if (patch_kind == "jmp"
                        and not st["old_hex"].lower().startswith("4ef9")
                        and not st.get("jmp_ok") and not st.get("rts_ok")):
                    fail.append(f"site_thunk {nm}: patch='jmp' over a non-jmp "
                                f"site (old_hex starts {st['old_hex'][:4]}) — "
                                f"set jmp_ok = true to assert the thunk body "
                                f"NEVER rts's or falls through (it must re-enter "
                                f"the original flow by jmp only), or rts_ok = true "
                                f"if the site is a CALLED HANDLER whose siblings "
                                f"all exit by rts")
                    continue
                ops.append({"op": "code", "addr": f"{td:#x}", "hex": body.hex()})
                ops.append({"op": "code", "addr": f"{site:#x}",
                            "hex": ("4ef9" if patch_kind == "jmp" else "4eb9")
                            + f"{td:08x}"})
                notes.append(f"code   {td:#08x} +{len(body):#x}  site_thunk {nm}; "
                             f"site {site:#08x} {patch_kind}-routed")
                fragments.append((td, len(body), "GEN", f"site_thunk {nm}"))
                fragments.append((site, 6, "GEN", f"site_thunk {nm} engine site"))

        # ── site_thunk, THE MULTI-TENANT SITES (14z-80h) ────────────────────
        # A site MORE THAN ONE tenant declares cannot take one thunk per
        # tenant: the loop above skipped those rows, recording each tenant's
        # fully-substituted body (built with ITS OWN placements, which is why
        # this cannot simply be hoisted out of the loop), and they are chained
        # into ONE thunk here, on the last iteration.
        #
        # The chain is a CONCATENATION and the split point is READ FROM THE
        # BODY, not assumed: the shape is
        #     0c06 00TT      cmpi.b #TT,d6
        #     66 dd          bne.s +dd     -> the next element / the tail
        #     <dd bytes>     this tenant's work
        #     <tail>         the non-tenant path
        # so element length = 6 + dd, and each element's own `bne` already
        # targets whatever follows it. Every declaring tenant must present the
        # SAME tail, which is what makes one chain legitimate.
        if engine_here() and _st_multi_bodies:
            for _site, _els in sorted(_st_multi_bodies.items()):
                _heads, _tail, _kind, _bad = [], None, None, False
                _dhead = None      # displaced-head shape (14z-84): the 6-byte
                #                    displaced original opens EVERY body, then
                #                    the compare element(s). None = the
                #                    original compare-first shape.
                for _nm, _b, _pk, _old in _els:
                    _pb = _b
                    if not (len(_pb) >= 8 and _pb[0:2] == b"\x0c\x06"
                            and _pb[4] == 0x66):
                        # not compare-first: accept the DISPLACED-HEAD shape —
                        # body = <6-byte head == the site's old bytes> +
                        # <cmpi (4 or 6 bytes) / bne.s dd / dd bytes> + tail.
                        # Every declarer must carry the identical head.
                        _h, _pb = _b[:6], _b[6:]
                        if _h != _old:
                            fail.append(
                                f"site_thunk {_nm}: {len(_els)} tenants "
                                f"declare site {_site:#x}, so their bodies "
                                f"must chain — but this one opens neither "
                                f"with `cmpi.b #TT,d6 / bne.s` nor with the "
                                f"displaced original ({_b[:6].hex()} != "
                                f"{_old.hex()}). Chain it by hand or give "
                                f"the tenants separate sites.")
                            _bad = True
                            break
                        if _dhead is None:
                            _dhead = _h
                        elif _h != _dhead:
                            fail.append(f"site_thunk {_nm}: declarers at "
                                        f"{_site:#x} present DIFFERENT "
                                        f"displaced heads")
                            _bad = True
                            break
                        _hoff = 6
                    else:
                        _hoff = 0
                        if _dhead is not None:
                            fail.append(f"site_thunk {_nm}: site {_site:#x} "
                                        f"mixes compare-first and displaced-"
                                        f"head bodies — one shape per site")
                            _bad = True
                            break
                    # the compare element: cmpi is 4 bytes (register dest) or
                    # 6 (with an ea displacement); the bne.s that ends it sits
                    # right after
                    if len(_pb) >= 6 and _pb[0] == 0x0C and _pb[4] == 0x66:
                        _boff = 4
                    elif len(_pb) >= 8 and _pb[0] == 0x0C and _pb[6] == 0x66:
                        _boff = 6
                    else:
                        fail.append(
                            f"site_thunk {_nm}: body at {_site:#x} has no "
                            f"parseable `cmpi / bne.s` element after "
                            f"offset {_hoff} ({_pb[:8].hex()})")
                        _bad = True
                        break
                    _elen = _boff + 2 + _pb[_boff + 1]
                    if _elen > len(_pb):
                        fail.append(f"site_thunk {_nm}: bne.s displacement "
                                    f"{_pb[_boff + 1]:#x} runs past the body")
                        _bad = True
                        break
                    _heads.append(_pb[:_elen])
                    if _tail is None:
                        _tail, _kind = _pb[_elen:], _pk
                    elif _pb[_elen:] != _tail:
                        fail.append(
                            f"site_thunk {_nm}: the tenants at site "
                            f"{_site:#x} present DIFFERENT non-tenant tails, "
                            f"so one chain cannot serve them")
                        _bad = True
                        break
                if _bad:
                    continue
                body = (_dhead or b"") + b"".join(_heads) + _tail
                td = alloc("a", len(body), f"site_thunk chain @{_site:#x}")
                if td is None:
                    fail.append(f"site_thunk chain @{_site:#x}: no room")
                    continue
                ops.append({"op": "code", "addr": f"{td:#x}", "hex": body.hex()})
                ops.append({"op": "code", "addr": f"{_site:#x}",
                            "hex": ("4ef9" if _kind == "jmp" else "4eb9")
                            + f"{td:08x}"})
                notes.append(f"code   {td:#08x} +{len(body):#x}  site_thunk "
                             f"{len(_els)}-way chain at {_site:#08x}: "
                             + ", ".join(n for n, _, _, _ in _els)
                             + f" ({len(_tail)} shared tail bytes)")
                fragments.append((td, len(body), "GEN",
                                  f"site_thunk {len(_els)}-way chain"))
                fragments.append((_site, 6, "GEN",
                                  f"site_thunk chain engine site"))

        # ── 14z-82 F2: the MERGED init shim, assembled after the loop ────────
        # Every declaring tenant's dispatch row routes through ONE shim:
        # seeder + phase gate once, then flavor_chain_multi's per-owner
        # blocks, each exiting into its OWNER's placed handler. Assembled
        # here (engine_here) because later tenants' handlers do not exist on
        # iteration 0 — the same reason the site_thunk chains above are.
        if engine_here() and _shim_multi:
            _sc = _shim_cfg_all
            _fmap = dict(_sc.get("_flavor_by_owner") or {})
            _missing = sorted(set(_fmap) - set(_shim_multi))
            if _missing:
                fail.append(f"init_shim: declaring tenant(s) {_missing} never "
                            f"reached the dispatch collector — a dispatch row "
                            f"was consumed by an earlier branch; no shim "
                            f"planted for them")
            elif _sc.get("objram_clear"):
                fail.append("init_shim: objram_clear on a multi-tenant build "
                            "is Donovan-gated by construction today — decide "
                            "its merged scope before enabling (the standing "
                            "flavor_tail refusal, now enforced here)")
            else:
                _tw = tripwire_for(0xF2F2F2, "init_shim chain fall-through "
                                   "(an id no declaring tenant claims)") \
                    if args.tripwire_open else None
                if _tw is None:
                    fail.append("init_shim: the merged chain fall-through "
                                "needs a tripwire — build with "
                                "--tripwire-open")
                else:
                    _latch = _int(_sc["latch_disp"])
                    _flavd = _int(_sc["flavor_disp"])
                    _hold = _int(_sc["flavor_hold_flag"])
                    _pg = b""
                    if _sc.get("latch_mode") == "phase":
                        _pg = (bytes([0x0C, 0xB9, 0x00, 0x04, 0x00, 0x00,
                                      0x00, 0xFF, 0x80, 0x0C])
                               + bytes([0x66, 0x0C]))
                    _ids2 = {t.get("name"): _int(t["dst_slot"])
                             for t in _tenant_list}
                    _hmap = {n: (_ids2[n], h)
                             for n, h in _shim_multi.items()}
                    _shim = (bytes([0x2F, 0x0D])
                             + bytes([0x4B, 0xF9, 0x00, 0xFF, 0x80, 0x00])
                             + _pg
                             + bytes([0x4A, 0xAD]) + _latch.to_bytes(2, "big")
                             + bytes([0x66, 0x06])
                             + bytes([0x4E, 0xB9])
                             + _int(_sc["seed_entry"]).to_bytes(4, "big")
                             + bytes([0x2A, 0x5F])
                             + flavor_chain_multi(_fmap, _flavd, _hold,
                                                  _hmap, _tw))
                    assert len(_shim) == 22 + len(_pg) + 54 * len(_fmap) + 6, \
                        len(_shim)
                    _sd = alloc("a", len(_shim), "merged init seed shim")
                    if _sd is None:
                        fail.append("init_shim: no room for the merged shim")
                    else:
                        ops.append({"op": "code", "addr": f"{_sd:#x}",
                                    "hex": _shim.hex()})
                        notes.append(
                            f"code   {_sd:#08x} MERGED init shim (pool latch "
                            f"A5+{_latch:#x}, seeder "
                            f"{_int(_sc['seed_entry']):#x}"
                            + (", phase-gated" if _pg else "")
                            + f"; flavor (A6+{_flavd:#x}) "
                            + ", ".join(
                                f"{_n}<-{_dv:#04x}/held {_hv:#04x}"
                                f"->handler {_hmap[_n][1]:#x}"
                                for _n, (_dv, _hv) in sorted(_fmap.items()))
                            + f" [Start bitmask {_hold:#x}]; unmatched id -> "
                            f"tripwire {_tw:#x}) planted on "
                            f"{len(_hmap)} dispatch rows (F2 fix)")
                        fragments.append((_sd, len(_shim), "GEN",
                                          "merged pool-seed + flavor init "
                                          "shim (F2)"))
                        _tby = {t.get("name"): t for t in _tenant_list}
                        for _n2 in sorted(_shim_multi):
                            repoint(_sc["dispatch"], _sd,
                                    f"{_n2} handler via MERGED seed shim "
                                    f"(F2)", tenant=_tby[_n2])

        # ── code_word: guarded single-word code patch (session 14z-22) ─────────
        # For data-in-code words a 6-byte site_thunk cannot touch without
        # clobbering neighbors (jump-table entries, embedded constants).
        # old_hex verified against the vanilla opcode image; emitted as a
        # code op so crypt-range re-encryption applies.
        if args.stage >= 6:
            opc_img_cw = None
            for cw in tenant_rows("code_word"):
                if args.stage < _int(cw.get("stage", 0)):
                    continue
                nm = cw["name"]
                # only_base_slot / only_variant_slot (14z-87): same gating as
                # aux_poke/data_port/site_thunk — added for the voice-borrow
                # site pad, whose word must stay vanilla on the stock twin.
                if not row_applies(cw, owner_of(cw)):
                    notes.append(f"# code_word {nm}: SKIPPED (slot-track gated; "
                                 f"owner at {_int(owner_of(cw)['dst_slot']):#04x})")
                    continue
                old = bytes.fromhex(cw["old_hex"])
                # new_hex_variant (14z-62d), by the row's OWNER (slice C): value
                # differs by where the tenant lives (e.g. the OBJ bank word: host
                # band vs WIDE group C).
                _nh = row_hex(cw, "new_hex", owner_of(cw))
                new = bytes.fromhex(_nh)
                if len(old) != 2 or len(new) != 2:
                    fail.append(f"code_word {nm}: old/new must be exactly 2 bytes")
                    continue
                if opc_img_cw is None:
                    opc_img_cw = (root / "build/out/vsavj_opcodes.bin").read_bytes()
                # slot_table/slot_stride/slot_off (14z-62c): the word is a
                # per-char TABLE ENTRY and follows the tenant. `slot_mirror`
                # additionally pokes the 0x1F twin on base-half builds (the
                # mirror-variant doctrine); a variant-id tenant has no mirror.
                # old_hex documents the BASE-HALF slot's vanilla word; a
                # variant entry is anchored on being a vanilla alias of its
                # base-half counterpart instead.
                if "slot_table" in cw:
                    # Slice D: the entry is the row OWNER's, and so is its
                    # mirror (a variant-id tenant has none).
                    _crow, _cvar, _cmir = row_ident(owner_of(cw))
                    stb = _int(cw["slot_table"])
                    sst = _int(cw.get("slot_stride", 4))
                    sof = _int(cw.get("slot_off", 0))
                    addr = stb + sst * _crow + sof
                    if _crow >= 0x10:
                        alias = stb + sst * (_crow & 0x0F) + sof
                        if opc_img_cw[addr:addr + 2] != opc_img_cw[alias:alias + 2]:
                            fail.append(f"code_word {nm}: variant entry at "
                                        f"{addr:#x} does not alias its base-half "
                                        f"counterpart — table shape moved")
                            continue
                    elif opc_img_cw[addr:addr + 2] != old:
                        fail.append(f"code_word {nm}: vanilla bytes at {addr:#x} "
                                    f"!= old_hex ({opc_img_cw[addr:addr+2].hex()})")
                        continue
                    targets = [addr]
                    if cw.get("slot_mirror") and _crow < 0x10:
                        targets.append(stb + sst * _cvar + sof)
                    for a2 in targets:
                        ops.append({"op": "code", "addr": f"{a2:#x}",
                                    "hex": new.hex()})
                        notes.append(f"code   {a2:#08x} +0x2  code_word {nm} "
                                     f"(slot entry {'mirror ' if a2 != addr else ''}"
                                     f"-> {new.hex()})")
                        fragments.append((a2, 2, "GEN", f"code_word {nm}"))
                    continue
                addr = _int(cw["addr"])
                if opc_img_cw[addr:addr + 2] != old:
                    fail.append(f"code_word {nm}: vanilla bytes at {addr:#x} != "
                                f"old_hex ({opc_img_cw[addr:addr+2].hex()})")
                    continue
                ops.append({"op": "code", "addr": f"{addr:#x}", "hex": new.hex()})
                notes.append(f"code   {addr:#08x} +0x2  code_word {nm} "
                             f"({old.hex()} -> {new.hex()})")
                fragments.append((addr, 2, "GEN", f"code_word {nm}"))

        # ── code_ptr: a guarded single-LONG code patch aimed at a PLACED region
        # (14z-71, the beam port) ─────────────────────────────────────────────
        # The engine's per-pool effect-CLASS tables are rows of absolute handler
        # pointers, indexed by an object field and read PC-relatively — i.e.
        # through the OPCODES space, inside the crypt window — so they are
        # patched with a `code` op, never poke32.
        #
        # vsav ships several of those rows as STUBS pointing at the bare `rts`
        # that follows the table, where vs2/vh2 carry a real handler. This row
        # hands one such dead row a ported handler, which is a strictly smaller
        # change than an obj_hook table rebuild: no relocated table, no engine
        # site patch, and no cycle cost on any legacy path.
        #
        # Superset safety rests on the row being DEAD, measured rather than
        # argued (tests/audit_effect_class_rows.sh), plus old_hex pinning the
        # slot to the stub so a table that ever moves fails the build loudly
        # instead of silently patching someone else's row.
        if args.stage >= 4:
            opc_img_cp = None
            for cp in tenant_rows("code_ptr"):
                if args.stage < _int(cp.get("stage", 4)):
                    continue
                nm = cp["name"]
                addr = _int(cp["addr"])
                old = bytes.fromhex(cp["old_hex"])
                if len(old) != 4:
                    fail.append(f"code_ptr {nm}: old_hex must be exactly 4 bytes")
                    continue
                if opc_img_cp is None:
                    opc_img_cp = (root / "build/out/vsavj_opcodes.bin").read_bytes()
                if opc_img_cp[addr:addr + 4] != old:
                    fail.append(f"code_ptr {nm}: vanilla bytes at {addr:#x} != "
                                f"old_hex ({opc_img_cp[addr:addr + 4].hex()})")
                    continue
                _rn, _, _ro = str(cp["region"]).partition(":")
                if _rn not in placed:
                    fail.append(f"code_ptr {nm}: region '{_rn}' not placed at "
                                f"this stage")
                    continue
                val = placed[_rn] + _int(_ro or "0")
                ops.append({"op": "code", "addr": f"{addr:#x}",
                            "hex": f"{val:08x}"})
                notes.append(f"code   {addr:#08x} +0x4  code_ptr {nm} "
                             f"({old.hex()} -> {val:08x} = {_rn}"
                             f"+{_int(_ro or '0'):#x})")
                fragments.append((addr, 4, "GEN", f"code_ptr {nm}"))

        # ── win/quote palette 0x60-view repoint (session 14u) ─────────────────────
        # Companion to select_port's block copies: the hardcoded
        # `lea 0x39FDC0,a0` at CODE:0x1C424 (the char*0x60-view win-screen
        # uploader) must read copy B at 0x24C3C0. Code space — the imm is
        # re-encrypted by patch_prg's code op. Slot-0x0F-only visual
        # surface; the masked gate arbitrates.
        WINPAL_ENABLE = False   # 14z: copies convicted of the throw
                                # victim-teleport (see select_port note)
        if args.stage >= 6 and WINPAL_ENABLE:
            ops.append({"op": "code", "addr": "0x1c426", "hex": "0024c3c0"})
            notes.append("# winpal: 0x1C424 lea imm -> copy B 0x24C3C0")
            # quote-time side-table reader -> the private table. Site
            # attribution is PATH-DEPENDENT and was settled by per-site
            # gate bisection (session 14u): 0x1BF56 preloads at normal
            # select entry, 0x1C5CE on the 2P/VS select path, 0x7D4FC on
            # the challenger-join path — all three stage block bytes
            # through work RAM on LEGACY replays and must keep the vanilla
            # table. Only 0x1C1FA is exclusively quote-time.
            # 14y: 0x1BF56 added — re-reading its code shows it copies
            # DIRECTLY to palette RAM 0x90C2C0 (no work-RAM staging; the
            # "bulk preloader" attribution was wrong for THIS site — only
            # 0x1C5CE/0x7D4FC stage through work RAM). It is the select/HUD
            # portrait-row uploader (side table + char*0xA0) and likely the
            # quote-screen path as well. Legacy chars read copy bytes
            # identical to vanilla; the masked battery arbitrates.
            # 0x1BF56 ACTIVE (maintainer sign-off, session 14y round 22):
            # the select/HUD palette-row uploader reads the patched copies —
            # fixes HUD mini-portrait, select portraits and the quote
            # palette family. Cost accepted: one spawn-boundary flicker
            # frame (@829, the approved mechanism class) on 02/05/07,
            # reclassified masked-EXACT -> masked-FLICKER; revert-and-
            # rethink if playtest shows problems (maintainer's terms).
            for site in ((0x1C1FA, 0x1BF56) if WINPAL_ENABLE else ()):
                ops.append({"op": "code", "addr": f"{site + 2:#x}",
                            "hex": "0024de00"})
            notes.append("# winpal: 3 quote-site table imms -> 0x24DE00")

        # ── M2b stage 7 (session 14q): companion-overlay zone port ────────────────
        # build/manifest/overlay/ is generated by tools/overlay_port.py from
        # pristine vs2 + the vsavj opcode dump (topology B, STATE 14q): the
        # relocated vs2 overlay zone slice lands in Jedah's strip area and
        # his per-char code immediates are repointed (code ops re-encrypt).
        #
        # THE SHARED-FILE CLASS (14z-80): this section is driven by a file,
        # not by an owned manifest row, so `row_here()` has nothing to ask.
        # It takes the same iteration-0 rule by hand. Note its T-select thunk
        # bakes ONE tenant id (slice E), so on a merged build it gates on
        # tenant 0 — the same open N-way-dispatch question, recorded there.
        ovdir = Path(__file__).resolve().parent.parent / "build/manifest/overlay"
        if _ti == 0 and args.stage >= 6 and (ovdir / "overlay_patch.json").exists():
            ovm = json.loads((ovdir / "overlay_patch.json").read_text())
            for seg in ovm["segments"]:
                blob = (ovdir / seg["path"]).read_bytes()
                assert len(blob) == seg["len"], f"overlay {seg['path']} length"
                write_out(seg["path"], blob, "overlay segment")
                pa = int(seg["at"], 16)
                ops.append({"op": "data_file", "addr": f"{pa:#x}",
                            "path": seg["path"]})
                fragments.append((pa, len(blob), "VS2",
                                  f"companion-overlay zone {seg['path']} "
                                  f"(vs2 0x2A0426 split, topology B)"))
            # T-site pokes are CONDITIONAL: the same Jedah display sites run
            # in the attract INTRO CUTSCENE (legacy-exact, pre-4278) and for
            # the in-match overlay (Donovan). Each site's `movea.l #T,a0`
            # (6 bytes) becomes `jsr thunk` (6 bytes); the thunk selects the
            # vanilla or ported table on the documented match-active check
            # $FF8004.l == 0x40000 (docs/game/atlas/ram.md; the attract DEMO is
            # in-match => ported, the cutscene is not => vanilla). CCR note:
            # every jump target (the strip walkers) starts with a d0 mask,
            # so the thunk's flag clobber is dead on all paths.
            pairs_seen = {}
            thunk = bytearray()
            for pk in ovm["pokes"]:
                key = (pk["old"], pk["new"])
                if key not in pairs_seen:
                    pairs_seen[key] = len(thunk)
                    # a0 = vanilla T; take the ported T only when a match is
                    # ACTIVE ($FF8004.l == 0x40000) and a slot-0x0F player is
                    # in it ($FF8782/$FF8B82 char id) — shared display code
                    # runs these sites for every character (the Demitri-match
                    # hang, session 14q); legacy matches must walk the
                    # vanilla tables byte-exactly.
                    thunk += bytes.fromhex("207c") + \
                        int(pk["old"], 16).to_bytes(4, "big")
                    thunk += bytes.fromhex("0cb90004000000ff8004")   # match?
                    thunk += bytes.fromhex("661a")                    # no -> rts
                    # cmpi.b #<tenant id>,$FF8782 / $FF8B82. The id was hardcoded
                    # as 000f here, INSIDE hand-authored machine code — the one
                    # place a tenant move would be silently wrong rather than
                    # loud: the thunk would gate on 0x0F, so the tenant would get
                    # the VANILLA tables and Jedah would get the ported ones, with
                    # nothing to crash. Built from the tenant id instead.
                    # Slice E: from `T`, not `port["port"]` — see charid_sites.
                    _tid8 = "%02x" % (_int(T["dst_slot"]) & 0xFF)
                    thunk += bytes.fromhex("0c3900" + _tid8 + "00ff8782")
                    thunk += bytes.fromhex("670a")                    # yes -> ported
                    thunk += bytes.fromhex("0c3900" + _tid8 + "00ff8b82")
                    thunk += bytes.fromhex("6606")                    # no -> rts
                    thunk += bytes.fromhex("207c") + \
                        int(pk["new"], 16).to_bytes(4, "big")
                    thunk += bytes.fromhex("4e75")
            ta = alloc("a", len(thunk), "overlay T-select thunks")
            if ta is not None:
                write_out("overlay_thunks.bin", thunk, "overlay thunks")
                ops.append({"op": "code_file", "addr": f"{ta:#x}",
                            "path": "overlay_thunks.bin"})
                fragments.append((ta, len(thunk), "GEN",
                                  "overlay T-select thunks (match-flag cond)"))
                for pk in ovm["pokes"]:
                    taddr = ta + pairs_seen[(pk["old"], pk["new"])]
                    # site addr = the 4-byte immediate; the opcode word 207C
                    # sits 2 bytes before — rewrite the full 6-byte insn
                    ops.append({"op": "code", "addr": f"{pk['addr'] - 2:#x}",
                                "hex": "4eb9" + f"{taddr:08x}"})
            notes.append(f"# overlay: {len(ovm['segments'])} zone segments + "
                         f"{len(ovm['pokes'])} T-sites thunked "
                         f"({len(pairs_seen)} thunks at {ta:#x})")

        # ── end of the per-tenant body: harvest what the emit block needs ──
        # `placed` and `man` are rebound on the next iteration, so this
        # tenant's placements are copied out here. Tenant 0 keeps the bare
        # region name — placements.json's consumers (verify_gfx_build.py,
        # verify_pcrel_data.py, audit_region_overlap.py) key by it — and
        # later tenants are suffixed, because seven region names are shared
        # across the three tenants (14z-77h) and they are DIFFERENT spans.
        for _rn in placed:
            _key = _rn if _ti == 0 else f"{_rn}@{T.get('name', _ti)}"
            all_placements[_key] = {"dst": placed[_rn],
                                    "src": man["regions"][_rn]["src"],
                                    "len": man["regions"][_rn]["len"]}

    # ── AGREEING DUPLICATE OPS (14z-80g) ────────────────────────────────────
    # Two tenants can emit the SAME BYTES at the same address through
    # different mechanisms — Donovan's `data_port hit_class_props_ext` writes
    # 0x28D4E-0x28D53 while Huitzil's and Pyron's `aux_poke effect_map_*`
    # poke16 the same three words with the same values, and H's and P's
    # adjacent `byte15b` entries both widen to the word 0xBE88A with the
    # same content. Nothing silently wins there — but patch_prg's overlap
    # assertion (rightly) refuses ANY two ops writing one word, so a merged
    # patch stops on an agreement.
    #
    # An op whose every byte is ALREADY written with the SAME value is
    # therefore dropped, with a note naming who covered it. Anything else —
    # a partial overlap, or one byte of disagreement — is left in place for
    # patch_prg to refuse, because that is a real conflict and this pass must
    # not become a way to make one disappear. Inert for one tenant: a
    # single-tenant build emits no overlapping ops at all.
    def _op_bytes(o):
        """(addr, bytes) an op writes, or (addr, None) if not resolvable."""
        a = int(o["addr"], 16)
        if "hex" in o:
            return a, bytes.fromhex(o["hex"])
        if o["op"] == "poke32":
            return a, int(o["val"], 16).to_bytes(4, "big")
        if o["op"] == "poke16":
            return a, int(o["val"], 16).to_bytes(2, "big")
        if "path" in o:
            p = out / o["path"]
            return a, (p.read_bytes() if p.is_file() else None)
        return a, None

    _bytemap, _kept, _dropped = {}, [], 0
    for _o in ops:
        _a, _b = _op_bytes(_o)
        if _b is None:
            _kept.append(_o)
            continue
        _covered = all(_bytemap.get(_a + i, (None,))[0] == _b[i]
                       for i in range(len(_b)))
        if _covered and len(_b):
            _dropped += 1
            _by = {_bytemap[_a + i][1] for i in range(len(_b))}
            notes.append(f"# op {_o['op']} {_a:#08x} +{len(_b):#x} DROPPED: "
                         f"already written identically by {sorted(_by)}")
            continue
        for i in range(len(_b)):
            _bytemap.setdefault(_a + i, (_b[i], f"{_o['op']}@{_a:#x}"))
        _kept.append(_o)
    if _dropped:
        ops[:] = _kept
        notes.append(f"# {_dropped} agreeing duplicate op(s) dropped "
                     f"(identical bytes at the same address)")

    # ── emit ─────────────────────────────────────────────────────────────────
    (out / "placements.json").write_text(json.dumps(
        {"stage": args.stage, "regions": all_placements}, indent=1))
    # ── tenant.json: the id the GFX half must agree with ────────────────────
    # build_gfx_donovan.py and verify_gfx_build.py used to hard-code slot
    # 0x0F ("Jedah's bank"), so they were silently independent of the port's
    # target — a build with the tenant moved elsewhere still placed bank
    # table row 0x0F. Emitting the tenant here makes one manifest row drive
    # BOTH halves, and lets the gfx verifier assert against the same id the
    # program half used rather than a constant.
    #
    # 14z-80: `tenant.json` still describes tenant 0 and is UNCHANGED, so the
    # four consumers (build_gfx_donovan.py, verify_gfx_build.py,
    # check_tenant_hud.py, build_donovan.sh) need no edit and every
    # single-tenant build emits the same bytes. The full array goes to a NEW
    # `tenants.json`, which is what a multi-tenant gfx half will read — that
    # half is single-tenant today, by decision.
    def _tenant_row(tp):
        return {"name": tp.get("name", "donovan"),
                "id": _int(tp["dst_slot"]),
                "mirror_variant": bool(tp.get("mirror_variant", False)),
                "src_set": tp.get("src_set"),
                "src_char": _int(tp["src_char"]) if "src_char" in tp else None,
                "gfx_bank": _int(tp["gfx_bank"]) if "gfx_bank" in tp else 2}

    _tp = port.get("port", {})
    (out / "tenant.json").write_text(json.dumps(_tenant_row(_tp), indent=1))
    (out / "tenants.json").write_text(json.dumps(
        [_tenant_row(t) for t in _tenant_list], indent=1))
    # 14z-82: the type-renumber map, for the gates (audit_type_dispatch_range
    # reads the renumbered index range) and the atlas. Written ONLY when
    # non-empty, so every single-tenant build's file set is unchanged.
    if TYPE_RENUMBER_ORDER:
        (out / "type_map.json").write_text(json.dumps(
            [{"site": s, "index": i, "orig_type": t, "tenant": tn,
              "src_handler": tgt}
             for s, i, t, tn, tgt in TYPE_RENUMBER_ORDER], indent=1))
    # 14z-85: the owner-tag map — every detoured 59-75 stamp site, its tag
    # value and its thunk (= the tag-write PC the pool-byte audit asserts
    # against). Written ONLY when non-empty: single-tenant file sets are
    # unchanged (the owner-tag pass is empty at N=1 by construction).
    if OWNER_TAG_MAP:
        (out / "tag_map.json").write_text(json.dumps(OWNER_TAG_MAP, indent=1))
    # ── program-image extension (Phase C step 2) ─────────────────────────────
    # If any op lands beyond the base 4MB image, the patcher must GROW the
    # image and emit the appended ROM members. The generator is what knows the
    # profile, so it states the requirement here rather than patch_prg.py
    # re-deriving it. Emitted only when a profile space was actually used, so
    # a WIDE build that happens to need no extension stays byte-identical to
    # the stock one.
    for _n, _v2, _vj in unstubbed:
        notes.append(f"# M5: sfx helper {_v2:#x} UN-STUBBED -> vsavj {_vj:#x} "
                     f"(record array {_n} is placed)")
    ext_spaces = [spaces[n] for n in order
                  if spaces[n]["profile"] and spaces[n]["cur"] > spaces[n]["start"]]
    image = None
    if ext_spaces:
        # Size to the PROFILE's declared extent, not to what we happened to
        # use. The emulator descriptors declare a fixed shape (PRG 6MB as four
        # appended 512KB members) and a romset that carries fewer members
        # simply fails to load. Content decides nothing about image geometry.
        need = max(sp["end"] for sp in ext_spaces)
        msize = 0x80000
        base = len(vj)
        count = -(-(need - base) // msize)        # ceil
        image = {"extend_to": base + count * msize,
                 "member_size": msize,
                 # Names and sizes MUST match the vsavjw descriptors in BOTH
                 # emulator patches; one romset feeds both.
                 "member_names": [f"vsw.{41 + i}" for i in range(count)],
                 # 0xFF, so the allocator's "dest must be 0xFF fill" check
                 # holds for extension space exactly as it does for the holes.
                 "fill": 0xFF,
                 "profile": args.profile}
        notes.append(f"# image: extend to {image['extend_to']:#x} "
                     f"({count} x {msize:#x} member(s): "
                     f"{', '.join(image['member_names'])})")
    spec = {"ops": ops}
    # THE SOURCE SET THE OPS WERE VERIFIED AGAINST (14z-94, GitHub #18).
    # Every old-byte check in this generator runs against the CACHED decrypted
    # views; nothing joined that image to the one patch_prg later writes into,
    # so the ops would apply to any zip with a .key and a program member —
    # including a previous builder's output, which is exactly the case where
    # the generator's premises (0xFF fill at the allocation, dst_old_head at
    # the data_port destination) no longer hold. Recording it here lets the
    # apply step refuse.
    spec["src_program_identity"] = cps.program_identity(args.vsavj)
    if image:
        spec["image"] = image
    (out / "patch.json").write_text(json.dumps(spec, indent=1))
    (out / "patch_notes_fragment.md").write_text(
        f"# donovan-m2 stage {args.stage} — generated op notes\n\n"
        + "\n".join(notes) + "\n")
    (out / "atlas_fragment.md").write_text(
        "| dest | len | provenance | what |\n|---|---|---|---|\n"
        + "\n".join(f"| `PRG:0x{d:06X}` | 0x{ln:X} | {pv} | {w} |"
                    for d, ln, pv, w in fragments) + "\n")
    print(f"stage {args.stage}: {len(ops)} ops, "
          + ", ".join(f"{sp['name']} 0x{sp['cur']:06X}/0x{sp['end']:06X} "
                      f"(free 0x{max(0, sp['end'] - sp['cur']):X})"
                      for sp in (spaces[n] for n in order)))
    if fail:
        print(f"\nGENERATION FAILED ({len(fail)}):")
        seen = set()
        for f in fail:
            if f not in seen:
                print(f"  {f}")
                seen.add(f)
        sys.exit(1)
    print("GENERATION OK")


if __name__ == "__main__":
    main()
