#!/usr/bin/env python3
"""gen_applier_page.py <release platform dir> [-o OUT.html] [--platform fbneo|mame|mister]

Generate the release's SELF-CONTAINED applier page — slice A2-A6 of
`docs/project/applier_app_scope.md`. One HTML file that turns a player's own
reference dumps into the romset, with no Python, no terminal and no install.

WHY ONE FILE, and it is not a preference. Measured 2026-09-21 in Chrome and
Firefox: a page opened from `file://` is refused `fetch`, `XMLHttpRequest` AND
cross-file `import` — so a page cannot read the `manifest.json`, the `patches/`
or a sibling `.mjs` sitting next to it. Everything it needs is therefore inlined:
this release's manifest, its 20 patches (base64) and the three applier modules,
concatenated into one inline module. That also makes the ruling of 2026-09-20
("a local file in the asset", "one page per release") literally true — the page
IS the release's applier, and it cannot be paired with the wrong manifest.

WHAT THE PAGE MAY NOT CONTAIN, asserted here and by tests/test_applier_page.sh:
no network primitive of any kind (`fetch`, `XMLHttpRequest`, `WebSocket`,
`sendBeacon`, `EventSource`, `navigator.connection`), and no external resource
reference (`src=`/`href=` to anything but a `#fragment`). The page is handed the
player's commercial dumps; "it does not upload them" has to be a property anyone
can check by reading the file, not a promise in a README (rule 7's spirit,
`docs/project/applier_app_scope.md` §2).
"""
import argparse, base64, json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
APPLIER = os.path.join(HERE, "applier")
# The order is the dependency order: vcdiff, then zip, then the applier that
# uses both. Concatenated into ONE module, so the imports between them go away.
MODULES = ["vcdiff.mjs", "zip.mjs", "applier.mjs"]

PLATFORM_LABEL = {"fbneo": "FBNeo", "mame": "MAME", "mister": "MiSTer"}
NEXT_STEP = {
    "fbneo": "put it where the README's &ldquo;Play on FBNEO&rdquo; section says — on macOS or "
             "Linux, <code>PLAY.command</code> does that part for you.",
    "mame": "put it where the README's &ldquo;Play on MAME&rdquo; section says — on macOS or "
            "Linux, <code>PLAY.command</code> does that part for you.",
    "mister": "copy it to your MiSTer's <code>games/mame/</code> folder and use the "
              "<code>.mra</code> files, as <code>MISTER.md</code> describes. Choose "
              "&ldquo;leave it out&rdquo; above for MiSTer.",
}

IMPORT_RE = re.compile(r'^\s*import\s.*\sfrom\s+"\./[A-Za-z0-9_]+\.mjs";\s*$')
EXPORT_RE = re.compile(r"^export\s+(?=(async\s+function|function|class|const|let|var)\b)")
STRAY_RE = re.compile(r"^\s*(import|export)\b")


def inline_modules():
    """The three modules as one module body: sibling imports dropped, `export`
    stripped from declarations. Anything else that looks like an import or an
    export is a REFUSAL, not a silent pass — the page is generated code and a
    surprise here would ship as a broken page."""
    out = []
    for name in MODULES:
        src = open(os.path.join(APPLIER, name)).read()
        lines = []
        for i, line in enumerate(src.splitlines(), 1):
            if IMPORT_RE.match(line):
                continue
            stripped = EXPORT_RE.sub("", line)
            if STRAY_RE.match(stripped):
                sys.exit(f"{name}:{i}: cannot inline this import/export form: {line.strip()!r}\n"
                         f"  the page is ONE module; keep sibling imports on their own line and\n"
                         f"  `export` immediately before a declaration, or teach this generator.")
            lines.append(stripped)
        out.append(f"// ── {name} " + "─" * (66 - len(name)) + "\n" + "\n".join(lines))
    return "\n\n".join(out)


# A DENYLIST CANNOT PROVE ABSENCE, and this one does not pretend to. The page's real
# guarantee is its Content-Security-Policy (`default-src 'none'; connect-src 'none'`),
# which the BROWSER enforces against every primitive including the ones nobody thought
# to list; it is required below and asserted in the generated file. This list is the
# second, independent check — it catches a mistake at authoring time, where a CSP
# violation would only show up at run time in someone's console. It was widened on
# 2026-09-21 after a rule-checker observed it was an enumeration with a single control
# and named five primitives it could not see.
FORBIDDEN = [
    (r"\bfetch\s*\(", "fetch()"),
    (r"\bfetchLater\s*\(", "fetchLater()"),
    (r"\bXMLHttpRequest\b", "XMLHttpRequest"),
    (r"\bWebSocket\b", "WebSocket"),
    (r"\bWebTransport\b", "WebTransport"),
    (r"\bRTCPeerConnection\b", "RTCPeerConnection"),
    (r"\bRTCDataChannel\b", "RTCDataChannel"),
    (r"\bEventSource\b", "EventSource"),
    (r"\bsendBeacon\b", "navigator.sendBeacon"),
    (r"\bimportScripts\s*\(", "importScripts()"),
    (r"\bnew\s+(?:Shared)?Worker\b", "Worker"),
    (r"\bserviceWorker\b", "navigator.serviceWorker"),
    (r"\bnavigator\.connection\b", "navigator.connection"),
    (r"\bnew\s+Image\s*\(", "new Image()"),
    (r"\bsetAttribute\s*\(\s*[\"'](?:src|href|action|srcset|formaction|data)[\"']", "setAttribute of a URL attribute"),
    (r"\bnavigator\.geolocation\b", "navigator.geolocation"),
]
# The one CSP directive set the page may not ship without: no network of any kind, no
# framing, no form post, no base rewrite. This is what makes the guarantee a property of
# the page rather than a property of our grep.
CSP_REQUIRED = ("default-src 'none'", "connect-src 'none'", "form-action 'none'", "base-uri 'none'")
# Only a #fragment may be a src/href target: anything else is a resource the page
# would go and get, which is exactly what must not happen.
RESOURCE_RE = re.compile(r"""\b(?:src|href)\s*=\s*["'](?!#)([^"']*)["']""", re.I)


def assert_self_contained(html, path):
    bad = []
    csp = re.search(r'<meta\s+http-equiv="Content-Security-Policy"\s+content="([^"]*)"', html, re.I)
    if not csp:
        bad.append("no Content-Security-Policy meta tag — the page's guarantee would rest "
                   "on this scan alone, which cannot prove absence")
    else:
        for directive in CSP_REQUIRED:
            if directive not in csp.group(1):
                bad.append(f"the Content-Security-Policy lacks `{directive}`")
    for pat, label in FORBIDDEN:
        for m in re.finditer(pat, html):
            line = html.count("\n", 0, m.start()) + 1
            bad.append(f"line {line}: {label}")
    for m in RESOURCE_RE.finditer(html):
        line = html.count("\n", 0, m.start()) + 1
        bad.append(f"line {line}: external resource {m.group(1)!r}")
    # a dynamic import would reach for a file beside the page, which file:// refuses
    for m in re.finditer(r"\bimport\s*\(", html):
        bad.append(f"line {html.count(chr(10), 0, m.start()) + 1}: dynamic import()")
    if bad:
        sys.exit(f"{path}: the page is not self-contained:\n  " + "\n  ".join(bad))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("pkgdir", help="a release platform dir (holds manifest.json and patches/)")
    ap.add_argument("-o", "--out", default="", help="default: <pkgdir>/apply_release.html")
    ap.add_argument("--platform", default="", help="default: the pkgdir's own name")
    ap.add_argument("--shell", default=os.path.join(APPLIER, "page_shell.html"))
    a = ap.parse_args()

    platform = a.platform or os.path.basename(os.path.normpath(a.pkgdir))
    if platform not in PLATFORM_LABEL:
        sys.exit(f"unknown platform {platform!r} (expected one of {', '.join(sorted(PLATFORM_LABEL))})")
    mpath = os.path.join(a.pkgdir, "manifest.json")
    if not os.path.exists(mpath):
        sys.exit(f"no manifest.json in {a.pkgdir}")
    manifest = json.load(open(mpath))

    patches = {}
    for entries in manifest["zips"].values():
        for e in entries:
            if "patch" not in e or e["patch"] in patches:
                continue
            p = os.path.join(a.pkgdir, e["patch"])
            if not os.path.exists(p):
                sys.exit(f"patch missing from the package: {p}")
            blob = open(p, "rb").read()
            patches[e["patch"]] = base64.b64encode(blob).decode("ascii")

    out_zip = sorted(manifest["zips"])[0]
    html = open(a.shell).read()
    subs = {
        "{{RELEASE_NAME}}": manifest.get("name") or "this release",
        "{{VERSION_STRING}}": manifest.get("version_string") or "?",
        "{{PLATFORM_LABEL}}": PLATFORM_LABEL[platform],
        "{{NEXT_STEP}}": NEXT_STEP[platform],
        "{{OUT_ZIP}}": out_zip,
        "{{MANIFEST_FP}}": (manifest.get("build_fingerprint") or "?")[:8],
    }
    for k, v in subs.items():
        if k not in html:
            sys.exit(f"{a.shell}: placeholder {k} is missing")
        html = html.replace(k, v)
    for marker, value in (("/*{{MODULES}}*/", inline_modules()),
                          ("/*{{MANIFEST}}*/ null", json.dumps(manifest, separators=(",", ":"))),
                          ("/*{{PATCHES}}*/ null", json.dumps(patches, separators=(",", ":")))):
        if marker not in html:
            sys.exit(f"{a.shell}: marker {marker} is missing")
        html = html.replace(marker, value, 1)

    out = a.out or os.path.join(a.pkgdir, "apply_release.html")
    assert_self_contained(html, out)
    open(out, "w").write(html)
    print(f"{out}: {len(html) / 1048576:.2f} MB, {len(patches)} patches inlined, "
          f"{len(MODULES)} modules, manifest {subs['{{MANIFEST_FP}}']}, platform {platform}")


if __name__ == "__main__":
    main()
