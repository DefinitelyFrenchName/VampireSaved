#!/bin/sh
# install_hooks.sh — point git at the tracked hooks under tools/git-hooks/
# (14z-162, GitHub #151). Idempotent; run once per clone.
#
# It sets core.hooksPath to a TRACKED directory so the hooks travel with the
# repo and cannot silently drift from an untracked .git/hooks copy. The only
# hook today is commit-msg, which runs tools/check_commit_subject.py --file on
# the message being committed and REFUSES a message GitHub would read as closing
# an issue on push. A hook is advisory (git --no-verify skips it, and it never
# runs on a machine that has not run this script), so the same rule is enforced
# non-optionally by tests/test_commit_subject.sh in the static tier.
#
# Usage: tools/install_hooks.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
git config core.hooksPath tools/git-hooks
chmod +x tools/git-hooks/* 2>/dev/null || true
echo "core.hooksPath -> tools/git-hooks (commit-msg: refuse a GitHub-closing subject)"
