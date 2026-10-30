#!/bin/sh
# publish_ledger.sh — build the session ledger page and, with --push, publish it on the `gh-pages` branch (GitHub #267).
#
# The page (tools/ledger_page.py) is built from `tools/session_metrics.py collect` over every session the ledger, git
# and STATE know, after `check` passes, as three files (index.html, ledger.css, ledger.js: no inline script or style, so
# a strict Content-Security-Policy serves it too). With --push it becomes ONE orphan commit holding them and .nojekyll,
# force-pushed to <remote>'s gh-pages with a lease on the tip it read: the page is derived data, so the branch keeps no
# history and the repository does not grow by a page at every close (ruled 2026-10-29: "gh-pages is fine"; served once
# the maintainer switches Pages on for that branch). A close step (docs/project/session_close.md `ledger-page`), run
# after the push of main: pushing happens only at the close ([VSP-17]).
#
# --own-site (ruled 2026-10-29: "The close uploads it", at alexrichard.org/vs-swarm-ledger/): the same three files are
# rsynced into <DEPLOY_TARGET>vs-swarm-ledger/ — DEPLOY_TARGET (user@host:path/to/webroot/) and DEPLOY_PORT are the
# maintainer's own site's settings (its deploy.sh reads the same two), set in their shell profile. ssh runs in batch mode
# (a missing key fails at once, never waits on a password) and the upload is bounded by a timeout. The site's own build
# copies no .html from its sources, so the page lives beside it; its deploy.sh never deletes, so the folder stays.
#
# --own-site-if-set (the maintainer, 2026-10-29: "I might not be able to do the config for the upload in time. If so
# that's fine to. Fail or ignore the deploy"): as --own-site when DEPLOY_TARGET is set; otherwise the own site is
# SKIPPED, said in one line, and the rest goes on. The close's step uses it.
#
# Usage: tools/publish_ledger.sh [--data DIR] [--out DIR] [--repo DIR] [--remote NAME] [--push] [--own-site|--own-site-if-set]
#   --data DIR   use datasets already collected (skips collect and check; the test's synthetic input)
#   --out DIR    where the page is written, under DIR/site (default build/ledger_page)
# Gate: tests/test_ledger_page.sh.
set -eu
DATA=""; OUT=build/ledger_page; REPO=.; REMOTE=origin; PUSH=0; OWN=0
while [ $# -gt 0 ]; do
    case "$1" in
    --data) shift; DATA="${1:?--data needs a dir}" ;;
    --out) shift; OUT="${1:?--out needs a dir}" ;;
    --repo) shift; REPO="${1:?--repo needs a dir}" ;;
    --remote) shift; REMOTE="${1:?--remote needs a name}" ;;
    --push) PUSH=1 ;;
    --own-site) OWN=1 ;;
    --own-site-if-set) if [ -n "${DEPLOY_TARGET:-}" ]; then OWN=1; else echo "SKIPPED the own site: DEPLOY_TARGET is not set"; fi ;;
    *) echo "usage: tools/publish_ledger.sh [--data DIR] [--out DIR] [--repo DIR] [--remote NAME] [--push] [--own-site|--own-site-if-set]" >&2; exit 2 ;;
    esac
    shift
done
TOOLS="$(cd "$(dirname "$0")" && pwd)"
if [ "$OWN" = 1 ] && [ -z "${DEPLOY_TARGET:-}" ]; then
    echo "FAIL: --own-site needs DEPLOY_TARGET (user@host:path/to/webroot/, the site's deploy.sh setting) — nothing published"; exit 1
fi
mkdir -p "$OUT"; OUT="$(cd "$OUT" && pwd)"   # absolute: the git calls below run under -C "$REPO"
if [ -z "$DATA" ]; then
    DATA="$OUT/data"
    python3 "$TOOLS/session_metrics.py" collect --keys 14z-1..14z-99999 --repo "$REPO" --out "$DATA" > "$OUT/collect.log"
    python3 "$TOOLS/session_metrics.py" check "$DATA" > "$OUT/check.log" || { echo "FAIL: session_metrics check: $(tail -1 "$OUT/check.log")"; exit 1; }
fi
python3 "$TOOLS/ledger_page.py" "$DATA" --out "$OUT/site" --repo "$REPO"
own_site() {  # the three files into <DEPLOY_TARGET>vs-swarm-ledger/
    _port="${DEPLOY_PORT:-22}"
    case "$_port" in *[!0-9]*|"") echo "FAIL: DEPLOY_PORT must be a number, got '$_port'"; exit 1 ;; esac
    _dest="${DEPLOY_TARGET%/}/vs-swarm-ledger/"
    timeout 300 rsync -rtz --checksum -e "ssh -p $_port -o BatchMode=yes -o ConnectTimeout=20" "$OUT/site/" "$_dest" \
        || { echo "FAIL: the upload to the own site did not complete"; exit 1; }
    echo "published the page to the own site's vs-swarm-ledger/"
}
if [ "$PUSH" = 0 ]; then
    [ "$OWN" = 1 ] && own_site
    echo "built $OUT/site (not pushed: --push publishes it on $REMOTE's gh-pages)"; exit 0
fi

# the orphan commit, made with plumbing on a private index: nothing in the working tree or the real index moves
IDX="$(mktemp "${TMPDIR:-/tmp}/ledger_idx.XXXXXX")" && [ -n "$IDX" ] || { echo "FAIL: no temporary index"; exit 2; }
trap 'rm -f "$IDX"' EXIT
rm -f "$IDX"
B_NOJ="$(printf '' | git -C "$REPO" hash-object -w --stdin)"
GIT_INDEX_FILE="$IDX" git -C "$REPO" update-index --add --cacheinfo "100644,$B_NOJ,.nojekyll"
for f in index.html ledger.css ledger.js; do
    GIT_INDEX_FILE="$IDX" git -C "$REPO" update-index --add --cacheinfo "100644,$(git -C "$REPO" hash-object -w "$OUT/site/$f"),$f"
done
TREE="$(GIT_INDEX_FILE="$IDX" git -C "$REPO" write-tree)"
COMMIT="$(echo "session ledger page ($(date -u +%Y-%m-%dT%H:%MZ)), generated by tools/publish_ledger.sh (#267)" | git -C "$REPO" commit-tree "$TREE")"
OLD="$(git -C "$REPO" ls-remote "$REMOTE" refs/heads/gh-pages | cut -f1)"
git -C "$REPO" push --force-with-lease="refs/heads/gh-pages:$OLD" "$REMOTE" "$COMMIT:refs/heads/gh-pages"
echo "published $COMMIT on $REMOTE gh-pages (was ${OLD:-absent})"
[ "$OWN" = 1 ] && own_site
exit 0
