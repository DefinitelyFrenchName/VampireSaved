"""_minitoml.py — minimal TOML-subset parser (fallback for Python < 3.11).

Supports exactly what build manifests use: [table], [[array-of-tables]],
bare keys with string / integer (decimal or 0x hex) / boolean values, and
comments. Anything else raises. If the host Python has tomllib, use that
instead (tools import `loads` from here, which delegates when possible).
"""


def _parse_value(raw, lineno):
    raw = raw.strip()
    if raw.startswith('"') and raw.endswith('"') and len(raw) >= 2:
        body = raw[1:-1]
        if '"' in body or "\\" in body:
            raise ValueError(f"line {lineno}: escapes/quotes unsupported: {raw}")
        return body
    if raw in ("true", "false"):
        return raw == "true"
    # NEGATIVE HEX IS REFUSED (GitHub #42). `int("-0x10", 0)` is -16 here
    # while tomllib rejects it outright, so accepting it would make the same
    # manifest mean different things on different hosts.
    if raw.startswith("-0x") or raw.startswith("+0x"):
        raise ValueError(f"line {lineno}: signed hex is not TOML: {raw}")
    try:
        return int(raw, 0)
    except ValueError:
        raise ValueError(f"line {lineno}: unsupported value syntax: {raw}") from None


def _strip_comment(line):
    in_str = False
    for i, ch in enumerate(line):
        if ch == '"':
            in_str = not in_str
        elif ch == "#" and not in_str:
            return line[:i]
    return line


def _loads_subset(text):
    """Parse the manifest subset, REFUSING anything tomllib would read
    differently (GitHub #42).

    This parser is the fallback on hosts without tomllib (< 3.11), and the two
    are not equivalent. Where they disagree they disagree SILENTLY, which
    already shipped wrong bytes once: a nested `[[data_port.fix]]` row parsed
    here as a flat orphan key and simply never applied, while a >= 3.11 host
    would have applied it — the same manifest, different bytes, including in
    the frozen references (build/manifest/donovan.toml:735).

    The fix is not to imitate tomllib but to REFUSE the divergent constructs,
    so that anything this parser accepts, tomllib parses identically:

        dotted table header   [a.b] / [[a.b]]   here: flat "a.b"; tomllib: nested
        dotted bare key       a.b = 1           here: flat "a.b"; tomllib: nested
        duplicate key         a=1 then a=2      here: last wins; tomllib: raises
        signed hex            -0x10             here: -16;       tomllib: raises

    A manifest using any of them is now a hard error on EVERY host rather
    than a different build on each. The tracked corpus uses none of them
    (asserted by tests/test_minitoml_subset.sh), so this is inert today —
    which is the point: it stays inert only because it is enforced.
    """
    root = {}
    current = root
    seen = {}          # id(table) -> set of keys, for duplicate detection
    for lineno, line in enumerate(text.splitlines(), 1):
        line = _strip_comment(line).strip()
        if not line:
            continue
        if line.startswith("[["):
            if not line.endswith("]]"):
                raise ValueError(f"line {lineno}: malformed table array header")
            name = line[2:-2].strip()
            if "." in name:
                raise ValueError(f"line {lineno}: dotted table-array header "
                                 f"[[{name}]] parses differently under tomllib")
            current = {}
            root.setdefault(name, []).append(current)
        elif line.startswith("["):
            if not line.endswith("]"):
                raise ValueError(f"line {lineno}: malformed table header")
            name = line[1:-1].strip()
            if "." in name:
                raise ValueError(f"line {lineno}: dotted table header "
                                 f"[{name}] parses differently under tomllib")
            current = root.setdefault(name, {})
        else:
            if "=" not in line:
                raise ValueError(f"line {lineno}: expected key = value")
            key, raw = line.split("=", 1)
            key = key.strip()
            if "." in key:
                raise ValueError(f"line {lineno}: dotted key {key!r} parses "
                                 f"differently under tomllib")
            ks = seen.setdefault(id(current), set())
            if key in ks:
                raise ValueError(f"line {lineno}: duplicate key {key!r} — "
                                 f"tomllib rejects this, the subset parser "
                                 f"would silently keep the last one")
            ks.add(key)
            current[key] = _parse_value(raw, lineno)
    return root


try:
    import tomllib as _tomllib

    def loads(text):
        return _tomllib.loads(text)
except ImportError:
    def loads(text):
        return _loads_subset(text)
