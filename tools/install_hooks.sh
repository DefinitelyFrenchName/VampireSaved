#!/bin/sh
# install_hooks.sh — point git at the tracked hooks under tools/git-hooks/
# (14z-162, GitHub #151). Idempotent; run once per clone.
#
# It sets core.hooksPath to a TRACKED directory so the hooks travel with the
# repo and cannot silently drift from an untracked .git/hooks copy. The hooks:
#   commit-msg  runs tools/check_commit_subject.py --file on the message being
#               committed and REFUSES a message GitHub would read as closing an
#               issue on push (mirrored non-optionally by tests/test_commit_subject.sh);
#   pre-commit  THE GREEN GUARD (#290, ruled 2026-10-16): refuses a commit whose tree
#               has no strict GREEN whole-tier run with ROMDIR set
#               (tools/git-hooks/green_guard.py, tests/test_green_guard.sh);
#   pre-push    the guard's light push check: the pushed TIP's tree only.
# A hook is advisory where it does not run: git --no-verify skips it, a clean
# merge, cherry-pick, rebase or revert makes a commit without the pre-commit hook
# (measured 2026-10-16), and a machine that has not run this script runs none.
#
# Usage: tools/install_hooks.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
git config core.hooksPath tools/git-hooks
chmod +x tools/git-hooks/* 2>/dev/null || true
echo "core.hooksPath -> tools/git-hooks (commit-msg: refuse a GitHub-closing subject; pre-commit and pre-push: the green guard, #290)"
