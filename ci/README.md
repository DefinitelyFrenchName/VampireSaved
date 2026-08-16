# CI — DRAFTED, NOT ENABLED (14z-91, GitHub #41)

`static-and-groundtruth.yml` is a draft. It is deliberately **not** in
`.github/workflows/`, because a file committed there runs on the next push;
this one runs nowhere until someone moves it.

## To enable

```sh
mkdir -p .github/workflows
git mv ci/static-and-groundtruth.yml .github/workflows/
```

## What the maintainer is deciding, not just reviewing

- **Executable config on third-party infrastructure.** Enabling means GitHub
  Actions runs this repo's code on every push.
- **Public job logs and a public badge on a rule-7 repo.** Nothing here reads
  `$ROMDIR` or any derived view — that is enforced by the portable list, and
  it is why the list is 13 gates and not 23 — but the exposure is a policy
  question, not a technical one.

## Why it is worth having

The static half (`py_compile`, `bash -n`, **and `dash -n`**) would have
caught the `#!/bin/sh`-with-bash-constructs breakage the day it landed
rather than sessions later. `dash -n` is the load-bearing part: the repo
targets POSIX sh and macOS `/bin/sh` is bash, so the developer machine
cannot see the class at all.

## The naming is deliberate

`static-and-groundtruth`, not `tests`. A job called "tests" that runs 13 of
~90 gates would report green for a tree whose emulator gates were never
run. The name says what it covers.
