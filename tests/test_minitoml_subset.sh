#!/bin/sh
# test_minitoml_subset.sh — the manifest parser must mean the SAME THING on
# every host (14z-94, GitHub #42). ROM-free, ~1 s.
#
# THE DEFECT. tools/_minitoml.py delegates to tomllib on Python >= 3.11 and
# falls back to its own subset parser below that. The two are not equivalent,
# and where they disagree they disagree SILENTLY — so "the build" became a
# function of the developer's interpreter, against CLAUDE.md rule 3. This has
# already shipped wrong bytes once: a nested `[[data_port.fix]]` row parsed as
# a flat orphan key and never applied on this host, while a >= 3.11 host would
# have applied it. Same manifest, different ROM, including in the frozen
# references (build/manifest/donovan.toml:735).
#
# THE FIX IS REFUSAL, NOT IMITATION. Rather than teach the subset parser to
# mimic tomllib's nesting, it now REJECTS every construct the two read
# differently. Anything it accepts, tomllib parses identically — which is a
# property that holds without needing tomllib present to check it. That
# matters because this host is 3.9.6: a gate that could only work by
# COMPARING the two parsers would skip here, and a skip is exactly how #29
# says these things rot.
#
# NOT IN SCOPE, but recorded so the next reader is not surprised: two tracked
# manifests (dispatch_census.toml, shared_writes.toml) use ARRAY values that
# the subset parser has never supported. They are read by hand-rolled `re`
# parsers in their own tools, not through _minitoml, so they are unaffected
# either way. A third parsing approach in the tree is its own (unfiled) smell.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT INT TERM
rc=0
fail() { echo "  FAIL: $*"; rc=1; }

echo "== 1. every manifest the subset parser handles still parses =="
python3 - > "$T/corpus.txt" 2>&1 <<'PY' || true
import sys, glob
sys.path.insert(0, "tools")
from _minitoml import _loads_subset as L
ok, arr, bad = 0, [], []
for f in sorted(glob.glob("build/manifest/*.toml")):
    try:
        L(open(f).read()); ok += 1
    except ValueError as e:
        (arr if "unsupported value syntax" in str(e) else bad).append((f, e))
print(f"PARSED {ok}")
for f, e in arr:
    print(f"ARRAY  {f}: {e}")
for f, e in bad:
    print(f"BAD    {f}: {e}")
PY
n=$(sed -n 's/^PARSED \([0-9]*\)/\1/p' "$T/corpus.txt")
echo "  ok: $n manifests parse under the subset parser"
if grep -q '^BAD ' "$T/corpus.txt"; then
    fail "a manifest is refused for a DIVERGENCE reason, not an array:"
    grep '^BAD ' "$T/corpus.txt" | sed 's/^/        /'
fi
grep -c '^ARRAY ' "$T/corpus.txt" | while read -r a; do
    echo "  note: $a manifest(s) use array values (read by their own re parsers)"
done

echo "== 2. VERDICT CONTROLS — each divergent construct must be REFUSED =="
try() { # try <label> <toml>
    if python3 - "$2" <<'PY' > "$T/out" 2>&1
import sys
sys.path.insert(0, "tools")
from _minitoml import _loads_subset as L
L(sys.argv[1])
PY
    then
        fail "'$1' was ACCEPTED — it parses differently under tomllib"
    else
        echo "  ok: '$1' refused — $(sed -n 's/.*ValueError: //p' "$T/out" | head -1)"
    fi
}
try "dotted table header"       '[a.b]
x = 1'
try "dotted table-array header" '[[a.b]]
x = 1'
try "dotted bare key"           '[t]
dotted.key = 5'
try "duplicate key"             '[t]
a = 1
a = 2'
try "negative hex"              '[t]
a = -0x10'

echo "== 3. NO FALSE POSITIVES — the ordinary shapes still parse =="
if python3 - <<'PY' > "$T/ok.txt" 2>&1
import sys
sys.path.insert(0, "tools")
from _minitoml import _loads_subset as L
d = L('''
[table]
s = "text"
n = 42
h = 0x1E
b = true

[[rows]]
a = 1

[[rows]]
a = 2
''')
assert d["table"] == {"s": "text", "n": 42, "h": 0x1E, "b": True}, d
assert [r["a"] for r in d["rows"]] == [1, 2], d
# the SAME key in two different rows of an array is legal, not a duplicate
print("ok")
PY
then
    echo "  ok: strings, decimals, hex, bools and repeated array rows parse"
    echo "      (and the same key in two array rows is not a duplicate)"
else
    fail "an ordinary manifest shape was refused:"; sed 's/^/        /' "$T/ok.txt"
fi

echo "== 4. cross-check against tomllib where the host has it =="
if python3 -c "import tomllib" 2>/dev/null; then
    python3 - > "$T/x.txt" 2>&1 <<'PY' || true
import sys, glob, tomllib
sys.path.insert(0, "tools")
from _minitoml import _loads_subset as L
bad = 0
for f in sorted(glob.glob("build/manifest/*.toml")):
    txt = open(f).read()
    try:
        mine = L(txt)
    except ValueError:
        continue
    if mine != tomllib.loads(txt):
        print(f"DISAGREE {f}"); bad += 1
print(f"CHECKED bad={bad}")
PY
    if grep -q "bad=0" "$T/x.txt"; then
        echo "  ok: both parsers agree on every manifest the subset accepts"
    else
        fail "the parsers disagree:"; sed 's/^/        /' "$T/x.txt"
    fi
else
    echo "  n/a: this host has no tomllib (Python $(python3 -c 'import sys;print(".".join(map(str,sys.version_info[:2])))'))."
    echo "       That is WHY section 2 is the real guarantee: agreement is"
    echo "       enforced by refusing the divergent constructs, not by"
    echo "       comparing two parsers that cannot both be present here."
fi

echo
if [ "$rc" = 0 ]; then
    echo "PASS: the manifest subset means one thing on every host."
else
    echo "FAIL: see above."
fi
exit $rc
