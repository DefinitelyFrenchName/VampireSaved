#!/bin/sh
# test_bbh_fidelity.sh — the generic black-box harness (`bbh`, the SEPARATE
# repository extracted from this tree, docs/project/harness_scope.md)
# reproduces THIS tree's verdicts: its fidelity gate is run against this
# tree and must be green. The ONLY file this tree gains from the extraction
# (harness_scope.md §7.8, maintainer-ruled 2026-09-06: this project's own
# harness "stays as it is" and never consumes the generic one).
#
# What it runs (harness_scope.md §5): F1 the classifier, F3 the tier
# classifier, F4 the sweep registry, F5 the masked vocabulary over the
# .masked specs (sampled: every 4th; BBH_FIDELITY_F5=1 for all 1,891), F6
# the fingerprint (over $ROMDIR and a sample of build dirs), F7 the suite
# dispatch over the expectation trees with a stub driver, F9 the hygiene
# tools, F10 the field comparator and the dump checker — all ROM-free but
# F6, ~65 s. With BBH_MAME_FIDELITY=1 it ALSO runs F8 (the Lua layer, the
# drivers and the recording tools on the real emulators, ~1 min) — never
# beside another gate run in this tree, because F8 runs gates of this tree.
#
# The harness is found by $BBH_HOME; unset, the gate looks for a
# `blackbox-harness` directory beside this tree and beside its parent (the
# ruled location is ~/Developer/blackbox-harness beside ~/Developer/
# Vampire_Saved/, i.e. ../../blackbox-harness from here — the scope's
# "sibling" default was one level short, measured at the first run, 14z-138).
# SKIP when absent — a clean checkout has no harness, which is why this is
# ci_static and never ci_portable (CI fails on SKIP). It writes only into
# temporary directories; --freeze never runs inside fidelity.
#
# Usage: ROMDIR=... [BBH_HOME=<harness dir>] [BBH_MAME_FIDELITY=1] tests/test_bbh_fidelity.sh
# Static tier (ci_static). 14z-138.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
if [ -z "${BBH_HOME:-}" ]; then
    for c in "$REPO/../blackbox-harness" "$REPO/../../blackbox-harness"; do
        [ -x "$c/bin/bbh" ] && { BBH_HOME="$c"; break; }
    done
fi
[ -n "${BBH_HOME:-}" ] && [ -x "$BBH_HOME/bin/bbh" ] || { echo "SKIP: no generic harness beside this tree or its parent (set BBH_HOME; clone https://github.com/DefinitelyFrenchName/blackbox-harness)"; exit 0; }
BBH_HOME="$(cd "$BBH_HOME" && pwd)"; export BBH_HOME
if [ -n "${ROMDIR:-}" ] && [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; export ROMDIR; fi
# The harness's consumer config names THIS tree by a relative root that is
# ONE host's layout; this gate knows where it is and passes that as the
# fidelity test's input (harness conventions 6, ruled 2026-09-07 — before
# it, a clone with a different layout failed here for a reason that was not
# fidelity). The test derives a private config copy with this absolute root.
# The assertion is the control that the input reaches the resolver.
BBH_FIDELITY_ROOT="$REPO"; export BBH_FIDELITY_ROOT
_cfg="$(mktemp -d)/bbh.vampire.toml"
sed "s|^root = .*|root = \"$REPO\"|" "$BBH_HOME/example/consumers/bbh.vampire.toml" > "$_cfg"
root="$(cd "$BBH_HOME" && PYTHONPATH=lib/py python3 -m bbh.config "$_cfg" root)"; rm -rf "$(dirname "$_cfg")"
[ "$root" = "$REPO" ] || { echo "FAIL: a config copy rooted here resolves to $root, not this tree ($REPO)"; exit 1; }
echo "== bbh fidelity against this tree ($(cd "$BBH_HOME" && git rev-parse --short HEAD 2>/dev/null || echo 'no git')) =="
rc=0
sh "$BBH_HOME/selftest/test_fidelity_vampire.sh" </dev/null || rc=1
if [ "${BBH_MAME_FIDELITY:-0}" = 1 ]; then
    sh "$BBH_HOME/selftest/test_fidelity_mame.sh" </dev/null || rc=1
else
    echo "  (F8, the instrument-side fidelity, not run: set BBH_MAME_FIDELITY=1 — ~1 min, never beside another gate run here)"
fi
[ "$rc" = 0 ] && echo "PASS: the generic harness reproduces this tree's verdicts" || { echo "FAIL: see above"; exit 1; }
