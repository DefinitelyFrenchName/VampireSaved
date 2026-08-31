#!/usr/bin/env python3
"""charmap_html.py — the CHARACTER PAGE: a wiki-style HTML rendering of one
tenant's character-data map (14z-121 (5)).

  python3 tools/charmap_html.py <tenant> <build_dir> <out.html> [--sprites <dir>]

--sprites <dir> (14z-121 (6), INTERNAL pages only — the published artifacts
carry no art): embed <dir>/<Move-Name>__<seq>.png beside each chain's box
diagram — the character's own sprite at that chain's first active frame,
captured from the native game's OBJ list by tests/lua/sprite_capture.lua and
drawn by tools/sprite_render.py. The output is written OUTSIDE the tracked
tree (build/charpages/); rendered art is not published.

Reads, and only reads:
  docs/project/tables/chars/<tenant>.json     the map (charmap_gen.py) — physics rows, chains, records, projectiles
  build/manifest/moves_<tenant>.toml          the maintainer's move list (names, inputs, notes, table:seq per row)
  <build_dir>/extract                          the tenant's hitbox set (tools/hitbox_records.py) for the box diagrams
  tests/expected/reactions_<tenant>.txt       the frozen reaction lines (tests/test_reactions.sh)

Every number on the page is a value from those files; the derivations are the
ones the map already documents (startup = frames before the first attack
node, active = the attack nodes' frames, recovery = the frames after —
charmap_md.py; boxes placed as in engine_internals "Hitboxes and attack
records": authored facing LEFT, drawn here mirrored to face RIGHT). Where a
row has no attack record the strip says so rather than showing zeros.
Nothing is written back; the page is regenerated whenever the map is.
"""
import html
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import _minitoml  # noqa: E402
import hitbox_records  # noqa: E402
import frame_data  # noqa: E402

REPO = Path(__file__).resolve().parent.parent
DISPLAY = {"donovan": ("Donovan Baine", "Vampire Savior 2 / Vampire Hunter 2", "0x13"),
           "huitzil": ("Huitzil (Phobos)", "Vampire Savior 2 / Vampire Hunter 2", "0x10"),
           "pyron": ("Pyron", "Vampire Savior 2 / Vampire Hunter 2", "0x11")}
# World -> OBJ-screen placement of a fighter's boxes over its captured sprite (14z-121 (7)), calibrated on Donovan's
# walk (f2600) and 5LP (f3623) captures: the sprite's feet sit at OBJ y = KY - world_y (world y = 40 on the ground),
# its x at KX + (world_x - camera). A box (bx, by, hw, hh) authored facing LEFT is mirrored (P1 faces right on the rigs).
KX, KY = 64, 262
KIND_LABEL = {"normal": "Normal", "throw": "Throw", "special": "Special", "es": "ES", "ex": "EX", "df": "Dark Force", "dash": "Movement", "misc": "Movement / other"}
SECTIONS = [("normals", "Normals", ("normal",)), ("throws", "Throws", ("throw",)), ("specials", "Specials", ("special", "es")),
            ("ex", "EX moves", ("ex",)), ("df", "Dark Force", ("df",)), ("movement", "Movement", ("dash", "misc"))]


def esc(s):
    return html.escape(str(s), quote=True)


def chain_frame_data(chain, atk_recs=None):
    """(durs, frame_data-dict-or-None) from a map chain (vs2 values). THE derivation
    is tools/frame_data.py — `active` is the attack nodes only, never the
    first..last SPAN (corrected 14z-125; see that module's header)."""
    nodes = chain.get("nodes") or []
    durs = [n["fields"]["dur"]["vs2"] for n in nodes]
    return durs, frame_data.from_nodes(nodes, atk_recs)


def box_svg(H, hb8, hbA, width=150, height=110):
    """The move's own boxes, mirrored to face right. hurt = blue, push = green, hit = red."""
    try:
        nb = H.node_boxes(hb8, hbA)
    except Exception:
        return ""
    boxes = []
    for b in nb["vuln"]:
        if any(b): boxes.append(("hurt", tuple(b)))
    if any(nb["push"]): boxes.append(("push", tuple(nb["push"])))
    ab = (nb.get("attack") or {}).get("box")
    if ab and any(ab): boxes.append(("hit", tuple(ab)))
    if not boxes:
        return ""
    # placed: centre (-x, y) [mirrored], half extents; y up, ground y = 40
    xs = [(-b[0]) - b[2] for _, b in boxes] + [(-b[0]) + b[2] for _, b in boxes]
    ys = [b[1] - b[3] for _, b in boxes] + [b[1] + b[3] for _, b in boxes] + [40]
    x0, x1 = min(xs) - 8, max(xs) + 8
    y0, y1 = min(ys) - 8, max(ys) + 8
    sc = min(width / (x1 - x0), height / (y1 - y0))
    W, Hh = (x1 - x0) * sc, (y1 - y0) * sc
    def X(v): return (v - x0) * sc
    def Y(v): return (y1 - v) * sc
    parts = [f'<svg class="boxes" viewBox="0 0 {W:.0f} {Hh:.0f}" width="{W:.0f}" height="{Hh:.0f}" role="img" aria-label="hit, hurt and push boxes of the first active frame">']
    parts.append(f'<line class="ground" x1="0" y1="{Y(40):.1f}" x2="{W:.0f}" y2="{Y(40):.1f}"/>')
    for kind, (x, y, hw, hh) in boxes:
        cx = -x
        parts.append(f'<rect class="{kind}" x="{X(cx - hw):.1f}" y="{Y(y + hh):.1f}" width="{2 * hw * sc:.1f}" height="{2 * hh * sc:.1f}"/>')
    parts.append(f'<circle class="origin" cx="{X(0):.1f}" cy="{Y(0):.1f}" r="2.5"/>')
    parts.append("</svg>")
    return "".join(parts)


def main():
    argv = sys.argv[1:]
    sprites = None
    if "--sprites" in argv:
        k = argv.index("--sprites"); sprites = Path(argv[k + 1]); del argv[k:k + 2]
    tenant, build_dir, out = argv[0], Path(argv[1]), Path(argv[2])
    j = json.load(open(REPO / "docs/project/tables/chars" / f"{tenant}.json"))
    S = j["structures"]
    moves = _minitoml.loads((REPO / "build/manifest" / f"moves_{tenant}.toml").read_text())["move"]
    H = hitbox_records.HitboxSet(build_dir / "extract")
    name, home, cid = DISPLAY[tenant]
    bank = S["bank"]["records"]
    anim = S["anim"]
    atk_recs = S["hitbox"]["attack"]
    recs = {r["idx"]: r for r in atk_recs}
    reactions = (REPO / "tests/expected" / f"reactions_{tenant}.txt")
    rx_lines = [l.rstrip("\n").split("\t") for l in reactions.read_text().splitlines() if l.strip()] if reactions.exists() else []

    def f(v):
        return f"{v:g}" if isinstance(v, (int, float)) else esc(v)

    # ---- physics ----
    p32 = bank["param32_a"]["fields"]; jp = bank["jump_params"]["fields"]
    walk = (p32["fwd_walk_xv"]["vs2"], p32["back_walk_xv"]["vs2"])
    jumps = [(k, jp[f"{k}_xv"]["vs2"], jp[f"{k}_yv"]["vs2"], jp[f"{k}_xaccel"]["vs2"], jp[f"{k}_gravity"]["vs2"]) for k in ("neutral", "forward", "back")]
    ported = j["diff_summary"].get("physics_rows_ported")

    # ---- moves ----
    def move_rows(kinds):
        return [m for m in moves if m.get("kind") in kinds]

    def render_move(m, nested=False):
        seqs = [s.strip() for s in str(m.get("seq", "")).split(",") if s.strip()]
        inputs = [s.strip() for s in str(m.get("input", "")).split(",")]
        table = m.get("table", "")
        out = [f'<article class="move{" es" if m.get("kind") == "es" else ""}{" nested" if nested else ""}" id="{esc(m["name"]).replace(" ", "-")}">']
        out.append(f'<header><h3>{esc(m["name"])}</h3><span class="input">{esc(m.get("input", ""))}</span><span class="chip {esc(m.get("kind", ""))}">{esc(KIND_LABEL.get(m.get("kind"), m.get("kind", "")))}</span></header>')
        seen = []
        for i, sq in enumerate(seqs):
            if not table or sq in seen:
                continue
            seen.append(sq)
            chain = (anim.get(table) or {}).get("chains", {}).get(sq)
            # the row's seq list follows the input list's order, or LP/MP/HP (LK/MK/HK) when one input covers three strengths
            if len(seqs) > 1 and len(inputs) == len(seqs):
                label = inputs[i]
            elif len(seqs) > 1 and len(inputs) == 1 and inputs[0][-1:] in ("P", "K"):
                label = ["L", "M", "H"][i] + inputs[0][-1] if i < 3 else f"#{i + 1}"
            else:
                label = ""
            if not chain or not chain.get("nodes"):
                out.append(f'<div class="strip"><span class="chain">{esc(table)}:{esc(sq)}</span><span class="na">chain not in the decoded graph</span></div>')
                continue
            durs, fd = chain_frame_data(chain, atk_recs)
            total = sum(durs)
            rids = fd["records"] if fd else []
            first = chain["nodes"][fd["first"] if fd else 0]["fields"]
            svg = box_svg(H, first["hb8"]["vs2"], first["hbA"]["vs2"])
            cells = [f'<span class="chain" title="anim table:seq">{esc(table)}:{esc(sq)}{(" · " + esc(label)) if label else ""}</span>']
            if fd is None:
                cells.append(f'<span class="na">no attack node · {total} f{" · " + chain["end"] if chain.get("end") else ""}</span>')
            else:
                r = recs.get(rids[0], {}).get("fields", {}) if rids else {}
                act = f'{fd["active"]}' + (f'<small> ({esc(fd["notation"])})</small>' if fd["notation"] != str(fd["active"]) else "")
                cells += [f'<dl><dt>startup</dt><dd>{fd["startup"]}</dd></dl>', f'<dl><dt>active</dt><dd>{act}</dd></dl>',
                          f'<dl><dt>recovery</dt><dd>{fd["recovery"]}</dd></dl>', f'<dl><dt>total</dt><dd>{total}</dd></dl>']
                if r:
                    cells += [f'<dl><dt>damage</dt><dd>{r["real"]}<small>/{r["white"]} white</small></dd></dl>', f'<dl><dt>meter</dt><dd>{r["meter"]}</dd></dl>',
                              f'<dl><dt>class</dt><dd>{r["cls"]:#04x}</dd></dl>', f'<dl><dt>pushback</dt><dd>{r["pb_hit"]}<small>/{r["pb_blk"]} blk</small></dd></dl>',
                              f'<dl><dt>freeze</dt><dd>{r["freeze"]}</dd></dl>']
                if len(rids) > 1:
                    cells.append(f'<span class="note">{len(rids)} attack records ({", ".join(f"{x:#x}" for x in rids)}); the first shown</span>')
            out.append(f'<div class="strip">{("<span class=variant>" + esc(label) + "</span>") if label else ""}{"".join(cells)}</div>')
            img = ""
            if sprites is not None:
                import base64, json as _json
                pf = sprites / (esc(m["name"]).replace(" ", "-") + f"__0x{int(sq, 16):02x}.png")
                if pf.exists():
                    meta = _json.loads(pf.with_suffix(".json").read_text()) if pf.with_suffix(".json").exists() else {}
                    data = base64.b64encode(pf.read_bytes()).decode()
                    if {"x0", "y0", "w", "h", "p1x", "p1y", "cam"} <= meta.keys():
                        # ONE drawing: the sprite at its crop origin and the boxes OUTLINED in the same OBJ-screen space
                        try:
                            nb = H.node_boxes(first["hb8"]["vs2"], first["hbA"]["vs2"])
                        except Exception:
                            nb = None
                        rects = []
                        if nb:
                            fx = KX + (meta["p1x"] - meta["cam"]); fy = KY - meta["p1y"]
                            for kind, b in [("hurt", t) for t in nb["vuln"]] + [("push", nb["push"])] + ([("hit", (nb.get("attack") or {}).get("box"))] if nb.get("attack") else []):
                                if not b or not any(b): continue
                                bx, by, hw, hh = b
                                cx = fx - bx; cy = fy - by
                                rects.append((kind, cx - hw, cy - hh, 2 * hw, 2 * hh))
                        # the objects P1 owns at this frame (the detached hits): each one's attack record from the owner's
                        # hitbox_proj table (node hbA>>8, engine_internals "the object-hit applier"), placed at the object
                        for ob in meta.get("objects", []):
                            if not ob.get("hbA"): continue
                            try:
                                rec = H.record(ob["hbA"] >> 8, proj=True)
                            except Exception:
                                continue
                            b = rec.get("box")
                            if not b or not any(b): continue
                            bx, by, hw, hh = b
                            ox = KX + (ob["x"] - meta["cam"]); oy = KY - ob["y"]
                            cx = ox - bx if ob.get("face", 1) else ox + bx; cy = oy - by
                            rects.append(("hit", cx - hw, cy - hh, 2 * hw, 2 * hh))
                            rects.append(("obj", ox - 2, oy - 2, 4, 4))
                        xs = [meta["x0"], meta["x0"] + meta["w"]] + [r[1] for r in rects] + [r[1] + r[3] for r in rects]
                        ys = [meta["y0"], meta["y0"] + meta["h"]] + [r[2] for r in rects] + [r[2] + r[4] for r in rects]
                        X0, Y0, X1, Y1 = min(xs) - 4, min(ys) - 4, max(xs) + 4, max(ys) + 4
                        sc = 2
                        parts = [f'<svg class="composite" viewBox="{X0} {Y0} {X1 - X0} {Y1 - Y0}" width="{(X1 - X0) * sc}" height="{(Y1 - Y0) * sc}" role="img" aria-label="{esc(m["name"])}: the sprite with its boxes outlined">',
                                 f'<image href="data:image/png;base64,{data}" x="{meta["x0"]}" y="{meta["y0"]}" width="{meta["w"]}" height="{meta["h"]}" style="image-rendering:pixelated"/>']
                        for kind, x, y, w_, h_ in rects:
                            parts.append(f'<rect class="{kind}" x="{x}" y="{y}" width="{w_}" height="{h_}"/>')
                        parts.append("</svg>")
                        img = "".join(parts)
                    else:
                        img = f'<img class="sprite" alt="{esc(m["name"])} at its first active frame" src="data:image/png;base64,{data}">'
            if svg or img:
                out.append(f'<figure>{img}{svg}<figcaption>{"the sprite with its boxes outlined, and " if img else ""}boxes of the {"first active" if fd is not None else "first"} frame · <span class="k hurt">hurt</span> <span class="k push">push</span> <span class="k hit">hit</span></figcaption></figure>')
        if m.get("notes"):
            out.append(f'<p class="notes">{esc(m["notes"])}</p>')
        out.append("</article>")
        return "\n".join(out)

    body = []
    body.append(f'<header class="masthead"><p class="eyebrow">Project Vampire Saved · character data map</p><h1>{esc(name)}</h1><p class="sub">Ported from {esc(home)} · character id <code>{cid}</code> · every value below is measured on the source game or read from the built image</p></header>')
    nav = [('overview', 'Overview & movement')] + [(k, t) for k, t, _ in SECTIONS] + [('projectiles', 'Projectiles'), ('reactions', 'As the victim'), ('provenance', 'Provenance')]
    body.append('<nav class="index"><ol>' + "".join(f'<li><a href="#{k}">{esc(t)}</a></li>' for k, t in nav) + "</ol></nav>")
    body.append('<main>')
    # overview
    body.append('<section id="overview"><h2>Overview &amp; movement</h2>')
    body.append('<div class="stats">')
    body.append(f'<dl><dt>walk forward</dt><dd>{f(walk[0])} <small>px/f</small></dd></dl><dl><dt>walk back</dt><dd>{f(walk[1])} <small>px/f</small></dd></dl>')
    for k, xv, yv, xa, g in jumps:
        body.append(f'<dl><dt>{k} jump</dt><dd>{f(xv)} <small>xv</small> · {f(yv)} <small>yv</small> · {f(g)} <small>gravity</small>{(" · " + f(xa) + " <small>xacc</small>") if xa else ""}</dd></dl>')
    body.append('</div>')
    phys = "The physics rows are the source game's (ported by value)." if ported else "The physics rows are the host slot's (not ported)."
    body.append(f'<p class="fine">{phys} 16.16 fixed point shown as decimals; the jump rows are the three <code>jump_params</code> records.</p></section>')
    # move sections
    for key, title, kinds in SECTIONS:
        rows = move_rows(kinds)
        if not rows:
            continue
        body.append(f'<section id="{key}"><h2>{esc(title)}</h2>')
        if key == "specials":
            # ES rows nest under their parent special (the parent names them in its notes)
            es = {m["name"]: m for m in rows if m.get("kind") == "es"}
            used = set()
            for m in rows:
                if m.get("kind") != "special":
                    continue
                body.append(render_move(m))
                for en, em in es.items():
                    if en.startswith(m["name"]) and en not in used:
                        used.add(en); body.append(render_move(em, nested=True))
            for en, em in es.items():
                if en not in used:
                    body.append(render_move(em))
        else:
            for m in rows:
                body.append(render_move(m))
        body.append('</section>')
    # projectiles
    PJ = S.get("projectile") or {}
    types = [k for k in PJ if not k.startswith("_")]
    if types:
        body.append('<section id="projectiles"><h2>Projectiles</h2><p class="fine">Each projectile this character spawns (the move, its pool type and handler address), with the parameters inline in the handler; velocities in px/frame, +0x9A 0/2/4 = LP/MP/HP, 6 = ES.</p><div class="tablewrap"><table><thead><tr><th>move</th><th>type · handler</th><th>variant</th><th>xv</th><th>x accel</th><th>yv</th><th>y accel</th><th>+0x26</th><th>+0x50</th></tr></thead><tbody>')
        for ty in types:
            d = PJ[ty]; mv = esc(" / ".join(d.get("moves", [])) or "?"); tycell = f'<code>{esc(ty)}</code> · <code>{esc(d["handler_vs2"])}</code>'
            if d["shape"] == "immediate":
                for im in d["immediates"]:
                    body.append(f'<tr><td>{mv}</td><td>{tycell}</td><td>state @{esc(im["pc"])}</td><td colspan="4">{esc(im["field"])} = {f(im["f16"])}</td><td></td><td></td></tr>')
                continue
            for r in d["rows"]:
                body.append(f'<tr><td>{mv}</td><td>{tycell}</td><td>{r["index"].get("+0x9A")}</td><td>{f(r["xv_f"])}</td><td>{f(r["xa_f"])}</td><td>{f(r["yv_f"])}</td><td>{f(r["ya_f"])}</td><td>{r["+0x26"]}</td><td>{r["+0x50"]}</td></tr>')
        body.append('</tbody></table></div></section>')
    # reactions
    if rx_lines:
        body.append('<section id="reactions"><h2>As the victim</h2><p class="fine">Victor attacks this character on the source game; per contact the reaction class, the hit-freeze, the chain path run and the frames until a stand chain returns (the stun as the engine ran it).</p><div class="tablewrap"><table><thead><tr><th>part</th><th>contact</th><th>class</th><th>freeze</th><th>chain path</th><th>frames</th></tr></thead><tbody>')
        for l in rx_lines:
            if len(l) < 6: continue
            body.append(f'<tr><td>{esc(l[0])}</td><td>{esc(l[1])}</td><td>{esc(l[2][4:])}</td><td>{esc(l[3][4:])}</td><td class="path">{esc(l[4])}</td><td>{esc(l[5][4:])}</td></tr>')
        body.append('</tbody></table></div></section>')
    # provenance
    ds = j["diff_summary"]
    body.append(f'<section id="provenance"><h2>Provenance</h2><p class="fine">Map <code>docs/project/tables/chars/{esc(tenant)}.json</code> (schema {esc(j.get("schema"))}) from build <code>{esc(j["sources"]["ours"]["set"])}</code> against the {esc(j["sources"]["vs2"]["set"])} extract; move list <code>build/manifest/moves_{esc(tenant)}.toml</code>. '
                f'Unattributed differences: bank {ds["bank_fields_unattributed"]}, dispatch {ds["dispatch_unattributed"]}, region bytes {ds["region_bytes_unattributed"]}. '
                f'Gates: <code>test_charmap_current</code>, <code>test_move_naming</code>, <code>test_hitbox_encoding</code>, <code>test_reactions</code>, <code>test_projectile_params</code>.</p></section>')
    body.append('</main>')

    css = CSS
    doc = f'<title>{esc(name)}</title>\n<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Marcellus&family=IBM+Plex+Sans:wght@400;500;600&family=IBM+Plex+Mono:wght@400;500&display=swap">\n<style>{css}</style>\n<div class="page">\n' + "\n".join(body) + "\n</div>\n"
    out.write_text(doc)
    print(f"wrote {out} ({len(doc)} bytes, {len(moves)} moves)")


CSS = """
:root{--bg:#EFEBF3;--bg2:#E4DEEB;--ink:#1C1826;--ink2:#5A5468;--line:#CEC6D8;--accent:#A52E22;--gold:#8A6D12;--hurt:#3B7DD8;--push:#2F9A5C;--hit:#D9483B;--chip:#DDD5E6}
@media (prefers-color-scheme: dark){:root:not([data-theme="light"]){--bg:#121019;--bg2:#1B1826;--ink:#EDE7F5;--ink2:#A79FB8;--line:#302A3D;--accent:#E0523F;--gold:#D9B33A;--hurt:#5B9BEA;--push:#4BBF78;--hit:#F0604F;--chip:#262033}}
:root[data-theme="dark"]{--bg:#121019;--bg2:#1B1826;--ink:#EDE7F5;--ink2:#A79FB8;--line:#302A3D;--accent:#E0523F;--gold:#D9B33A;--hurt:#5B9BEA;--push:#4BBF78;--hit:#F0604F;--chip:#262033}
body{background:var(--bg);color:var(--ink);font-family:"IBM Plex Sans",system-ui,sans-serif;font-size:15px;line-height:1.5}
.page{display:grid;grid-template-columns:200px minmax(0,76ch);gap:0 40px;max-width:1100px;margin:0 auto;padding:32px 24px 80px}
.masthead{grid-column:1/-1;border-bottom:2px solid var(--accent);padding-bottom:18px;margin-bottom:28px}
.eyebrow{text-transform:uppercase;letter-spacing:.14em;font-size:11.5px;color:var(--ink2);margin:0 0 6px}
h1{font-family:Marcellus,Georgia,serif;font-weight:400;font-size:44px;letter-spacing:.01em;margin:0;text-wrap:balance}
.sub{color:var(--ink2);margin:8px 0 0}
h2{font-family:Marcellus,Georgia,serif;font-weight:400;font-size:26px;margin:40px 0 14px;border-bottom:1px solid var(--line);padding-bottom:6px;text-wrap:balance}
h3{font-family:Marcellus,Georgia,serif;font-weight:400;font-size:20px;margin:0}
.index{position:sticky;top:24px;align-self:start}
.index ol{list-style:none;margin:0;padding:0;border-left:1px solid var(--line)}
.index li a{display:block;padding:5px 0 5px 14px;color:var(--ink2);text-decoration:none;font-size:13.5px}
.index li a:hover,.index li a:focus-visible{color:var(--accent);outline:none;border-left:2px solid var(--accent);margin-left:-1px}
main{min-width:0}
code,.chain,dd,td,.input{font-family:"IBM Plex Mono",ui-monospace,monospace;font-variant-numeric:tabular-nums}
.stats{display:grid;grid-template-columns:repeat(auto-fill,minmax(210px,1fr));gap:12px 20px;margin:10px 0}
.stats dl,.strip dl{margin:0}
dt{font-size:11px;text-transform:uppercase;letter-spacing:.1em;color:var(--ink2)}
dd{margin:0;font-size:16px}
dd small,.strip small{font-size:11px;color:var(--ink2);margin-left:2px}
.fine{color:var(--ink2);font-size:13.5px}
.move{padding:16px 0 14px;border-top:1px solid var(--line)}
.move.nested{margin-left:26px;border-top:1px dashed var(--line)}
.move header{display:flex;align-items:baseline;gap:14px;flex-wrap:wrap}
.input{font-size:14px;color:var(--ink2)}
.chip{font-size:11px;text-transform:uppercase;letter-spacing:.1em;padding:2px 8px;border-radius:2px;background:var(--chip);color:var(--ink2)}
.chip.es,.chip.ex,.chip.df{color:var(--gold);border:1px solid var(--gold);background:transparent}
.strip{display:flex;flex-wrap:wrap;gap:8px 22px;align-items:end;margin:12px 0 0;padding-top:6px;border-top:1px dotted var(--line)}
.strip:first-of-type{border-top:0;padding-top:0}
.variant{font-family:Marcellus,Georgia,serif;font-size:15px;color:var(--accent);align-self:center;min-width:2.5em}
.chain{font-size:12.5px;color:var(--ink2);align-self:center}
.na,.note{font-size:12.5px;color:var(--ink2);align-self:center}
figure{margin:10px 0 0;display:flex;align-items:center;gap:14px}
figcaption{font-size:12px;color:var(--ink2)}
.k{display:inline-block;padding:0 6px;border-radius:2px;color:#fff;font-size:11px}
.k.hurt{background:var(--hurt)}.k.push{background:var(--push)}.k.hit{background:var(--hit)}
svg.boxes{background:var(--bg2);border:1px solid var(--line)}
img.sprite{image-rendering:pixelated;background:var(--bg2);border:1px solid var(--line);max-height:180px}
svg.composite{background:var(--bg2);border:1px solid var(--line);max-width:100%;height:auto}
svg.composite rect{fill:none;stroke-width:1}
svg.composite .hurt{stroke:var(--hurt)}svg.composite .push{stroke:var(--push)}svg.composite .hit{stroke:var(--hit)}svg.composite .obj{fill:var(--hit);stroke:none}
svg.boxes .ground{stroke:var(--line);stroke-width:1}
svg.boxes rect{fill-opacity:.28;stroke-width:1.2}
svg.boxes .hurt{fill:var(--hurt);stroke:var(--hurt)}svg.boxes .push{fill:var(--push);stroke:var(--push)}svg.boxes .hit{fill:var(--hit);stroke:var(--hit)}
svg.boxes .origin{fill:var(--ink)}
.notes{margin:10px 0 0;font-size:13.5px;color:var(--ink);max-width:66ch}
.tablewrap{overflow-x:auto}
table{border-collapse:collapse;font-size:13px;width:100%}
th{text-align:left;font-weight:500;font-size:11px;text-transform:uppercase;letter-spacing:.08em;color:var(--ink2);border-bottom:1px solid var(--line);padding:6px 10px 6px 0}
td{padding:5px 10px 5px 0;border-bottom:1px solid var(--line);vertical-align:top}
td.path{font-size:12px}
@media (max-width:820px){.page{grid-template-columns:1fr}.index{position:static;margin-bottom:20px}.index ol{display:flex;flex-wrap:wrap;gap:4px 14px;border:0}}
@media (prefers-reduced-motion: no-preference){.index li a{transition:color .15s}}
"""

if __name__ == "__main__":
    main()
