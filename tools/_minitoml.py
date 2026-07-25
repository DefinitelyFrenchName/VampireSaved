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
    root = {}
    current = root
    for lineno, line in enumerate(text.splitlines(), 1):
        line = _strip_comment(line).strip()
        if not line:
            continue
        if line.startswith("[["):
            if not line.endswith("]]"):
                raise ValueError(f"line {lineno}: malformed table array header")
            name = line[2:-2].strip()
            current = {}
            root.setdefault(name, []).append(current)
        elif line.startswith("["):
            if not line.endswith("]"):
                raise ValueError(f"line {lineno}: malformed table header")
            name = line[1:-1].strip()
            current = root.setdefault(name, {})
        else:
            if "=" not in line:
                raise ValueError(f"line {lineno}: expected key = value")
            key, raw = line.split("=", 1)
            current[key.strip()] = _parse_value(raw, lineno)
    return root


try:
    import tomllib as _tomllib

    def loads(text):
        return _tomllib.loads(text)
except ImportError:
    def loads(text):
        return _loads_subset(text)
