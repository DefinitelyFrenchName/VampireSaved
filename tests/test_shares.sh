#!/bin/sh
# test_shares.sh — GATES DECLARE WHAT THEY SHARE; THE POOL AND THE HOST CLAIM KEEP HOLDERS APART (#370, 14z-225). ci_portable: no ROM, ~25 s.
#
# WHAT: every registered gate carries one well-formed `# SHARES:` line (maintainer-ruled 2026-11-08: "B1: every gate has
#   the line (Recommended)"), every token it names is `self` or a row of tests/shares.tsv, every row is held by a gate,
#   and a gate holding a row makes the row's claim call (tests/lib/share_pool.py census); the static pool never runs two
#   jobs holding one token at once and still runs jobs that share nothing side by side; and the host claim
#   (tests/lib/shares.sh vs_shares_claim, "C1: yes, host-wide lock (Recommended)") makes a run beside a live holder wait
#   and then REFUSE, lets a run nested under its holder proceed at once, and takes over a dead holder's lock.
# HOW: 1. the census over the tree (it must read at least 500 registered gates). 2. known answers on a copy of the
#   tree's registries, shares.tsv and gate scripts: a gate with its line removed (NO-LINE), a gate naming a token the
#   registry lacks (UNKNOWN-TOKEN), a gate holding release-assets with no claim call (UNCLAIMED), a registry row no gate
#   holds (UNHELD); the unperturbed copy reads clean. 3. tests/lib/static_pool.py in a synthetic repo whose job stub logs
#   each job's start and end: two gates holding release-assets must not overlap, two declaring none must; a gate
#   declaring `self` with two control modes must run them one after the other, and a `none` gate's two must overlap
#   (the path from a `# SHARES: self` header to the pool's `self:<gate>` token). 4. the host
#   claim (an OS file lock held by tests/lib/share_lock.py for the claiming shell's lifetime; maintainer-ruled 2026-11-09
#   "Kernel lock (Recommended)") in a private claim directory, every claim under `sh -e`: a holder; a hand run beside it
#   REFUSED after its 1-second wait, its line naming the holder and "waited 1s of 1"; a hand run with no VS_SHARES_WAIT
#   reading a 2-second wait from a registry copy ("waited 2s of 2"); a run whose environment names the holder (proceeds,
#   the lock untouched); a run naming the holder of another token (claims that token normally); the holder SIGKILLed (no
#   trap runs) and the next claim taking the token; four claimers started at once, each holding 1 s, all served and no
#   two holding at once; a lock file left behind naming a dead holder, claimed at once.
# EXPECTS: 0 problems on the tree and every case its answer. A red census line names the gate and what to add.
# FOLLOWS: tests/lib/share_pool.py tests/lib/shares.sh tests/lib/share_lock.py tests/lib/static_pool.py tests/shares.tsv tests/ci_static.txt tests/ci_portable.txt tests/ci_emulator.tsv tests/
#
# MUST-FIRE: perturbed-copy: no-line — a copy of the tree with the first registered gate's `# SHARES:` line removed must be named NO-LINE and FAIL the gate (mode: section 1's census reads that copy)
# MUST-FIRE: perturbed-copy: unknown-token — a copy with that gate's line naming `no-such-token` must be named UNKNOWN-TOKEN and FAIL the gate (mode: section 1 reads that copy)
# MUST-FIRE: perturbed-copy: unclaimed — a copy with a gate holding release-assets whose claim call is removed must be named UNCLAIMED and FAIL the gate (mode: section 1 reads that copy)
# MUST-FIRE: perturbed-copy: unheld — a copy whose tests/shares.tsv gains a row no gate holds must name it UNHELD and FAIL the gate (mode: section 1 reads that copy)
# MUST-FIRE: shadow-tool: pool-tokens-ignored — a copy of tests/lib/share_pool.py whose SHARE-PICK test ignores tokens must start the two release-assets stubs together, and section 3 must FAIL (mode: that copy is the pool's)
# MUST-FIRE: shadow-tool: self-ignored — a copy of tests/lib/share_pool.py whose SHARE-SELF line drops `self` from a gate's tokens must start the `self` stub's two control modes together, and section 3 must FAIL (mode: that copy is the pool's; rule-checker run 2026-11-09-1752 Q4)
# MUST-FIRE: shadow-tool: claim-nesting-ignored — a copy of tests/lib/shares.sh whose SHARES-NESTED skip is disabled must REFUSE the run nested under the live holder, and section 4 must FAIL (mode: that copy is the library section 4 sources)
# MUST-FIRE: shadow-tool: claim-wait-ignored — a copy of tests/lib/shares.sh whose SHARES-WAIT line sets the wait to 0 must REFUSE at once beside a live holder (no "waited 1s of 1", and a registry wait of 2 not read), and section 4 must FAIL (mode: that copy is the library section 4 sources; rule-checker run 2026-11-09-1754 Q4)
# MUST-FIRE: shadow-tool: lock-nb-ignored — a copy of tests/lib/share_lock.py whose SHARE-LOCK-TAKE line never takes the flock must let two of four claimers started at once hold release-assets together, and section 4 must FAIL (mode: that copy is the helper section 4's root carries; rule-checker run 2026-11-09-1755 Q4)
# MUST-FIRE: shadow-tool: owner-death-ignored — a copy of tests/lib/share_lock.py whose SHARE-LOCK-OWNER loop never ends must keep the token after its holder is SIGKILLed, so the next claim is REFUSED, and section 4 must FAIL (mode: that copy is the helper section 4's root carries)
# SHARES: none — every check runs in its own mktemp directory, the claims in a private claim directory
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)" || { echo "FAIL: test_shares — mktemp -d failed (W)"; exit 2; }
HOLDER=""
trap '[ -n "$HOLDER" ] && kill "$HOLDER" 2>/dev/null; rm -rf "$W"' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM
: > "$W/main.log"
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*" | tee -a "$W/main.log"; fail=1; }

G1="$(python3 -c 'import sys; sys.path.insert(0, "tests/lib"); import share_pool; print(share_pool.registered(".")[0])')"
GH=test_release_asset_shape   # a gate that holds release-assets and claims it
mkcopy() {  # mkcopy <dir> <perturbation|clean>
    mkdir -p "$1/tests"
    cp tests/ci_portable.txt tests/ci_static.txt tests/ci_emulator.tsv tests/shares.tsv tests/*.sh "$1/tests/"
    case "$2" in
        no-line)       grep -v '^# SHARES: ' "tests/$G1.sh" > "$1/tests/$G1.sh" ;;
        unknown-token) sed 's/^# SHARES: .*$/# SHARES: no-such-token/' "tests/$G1.sh" > "$1/tests/$G1.sh" ;;
        unclaimed)     grep -v 'vs_shares_claim' "tests/$GH.sh" > "$1/tests/$GH.sh" ;;
        unheld)        printf 'zz-unheld-token\t900\tvs_shares_claim\ta planted row no gate holds\n' >> "$1/tests/shares.tsv" ;;
    esac
}
tag_of() { case "$1" in no-line) echo "NO-LINE	$G1" ;; unknown-token) echo "UNKNOWN-TOKEN	$G1" ;; unclaimed) echo "UNCLAIMED	$GH" ;; unheld) echo "UNHELD	zz-unheld-token" ;; esac; }

echo "== 1. the census over the tree"
ROOT="$REPO"; WANT=""
case "${VS_CTL:-}" in no-line|unknown-token|unclaimed|unheld) mkcopy "$W/mode" "$VS_CTL"; ROOT="$W/mode"; WANT="^$(tag_of "$VS_CTL")	" ;; esac
python3 tests/lib/share_pool.py census --root "$ROOT" > "$W/census.out" 2>&1; rc=$?
sed 's/^/  /' "$W/census.out" | tail -8
[ "$rc" = 0 ] && ok "every registered gate declares what it shares, every token is registered, held and claimed" \
    || bad "the census named a problem (above): $(head -1 "$W/census.out")"
cat "$W/census.out" >> "$W/main.log"
n="$(sed -n 's/^census: \([0-9]*\) registered gates read.*/\1/p' "$W/census.out")"
[ "${n:-0}" -ge 500 ] && ok "the census read $n registered gates" || bad "the census read ${n:-no} registered gates (a blinded reader reads fewer than 500)"

echo "== 2. known answers on a copy (the first registered gate: $G1; the holding gate: $GH)"
mkcopy "$W/clean" clean
python3 tests/lib/share_pool.py census --root "$W/clean" > "$W/clean.out" 2>&1 && ok "the unperturbed copy reads clean" \
    || bad "the unperturbed copy was named: $(head -1 "$W/clean.out")"
if [ -z "${VS_CTL:-}" ]; then
    for c in no-line unknown-token unclaimed unheld; do
        mkcopy "$W/$c" "$c"; python3 tests/lib/share_pool.py census --root "$W/$c" > "$W/$c.out" 2>&1 || :
        if grep >/dev/null "^$(tag_of "$c")	" "$W/$c.out"; then vs_ctl_fired "$c" "$(grep -m1 "^$(tag_of "$c")	" "$W/$c.out" | cut -c1-120)"
        else vs_ctl_dead "$c" "the $c copy was not named $(tag_of "$c" | tr '\t' ' '): $(tail -1 "$W/$c.out")"; fail=1; fi
    done
fi

echo "== 3. the static pool keeps token holders apart and runs the rest side by side"
FR="$W/fr"; mkdir -p "$FR/tests/lib" "$FR/w"
cp tests/lib/static_pool.py "$FR/tests/lib/"; cp tests/lib/share_pool.py "$FR/tests/lib/share_pool.py"
sed 's|            if not (task\[1\] \& h):   # SHARE-PICK|            if True:   # SHARE-PICK disabled|' tests/lib/share_pool.py > "$W/share_pool_blind.py"
cmp -s tests/lib/share_pool.py "$W/share_pool_blind.py" && bad "could not blind the pool — the SHARE-PICK line moved"
sed 's|    return frozenset(("self:" + gate) if t == "self" else t for t in toks)   # SHARE-SELF|    return frozenset(t for t in toks if t != "self")   # SHARE-SELF disabled|' tests/lib/share_pool.py > "$W/share_pool_noself.py"
cmp -s tests/lib/share_pool.py "$W/share_pool_noself.py" && bad "could not drop self — the SHARE-SELF line moved"
vs_ctl_is pool-tokens-ignored && cp "$W/share_pool_blind.py" "$FR/tests/lib/share_pool.py"
vs_ctl_is self-ignored && cp "$W/share_pool_noself.py" "$FR/tests/lib/share_pool.py"
printf '%s\n' '#!/bin/sh' 'g="$1"; W="$2"; k="$g"; [ "${5:-}" = control ] && k="$g.$6"; mkdir -p "$W/pre"' \
    'echo "start $k $(python3 -c "import time; print(time.time())")" >> "$W/jobs.log"; sleep 1.5' \
    'echo "end $k $(python3 -c "import time; print(time.time())")" >> "$W/jobs.log"; echo "0 1" > "$W/pre/$g.run"' \
    'case "$g:${5:-}" in g_s:gate|g_n:gate) printf "controls\nc1\nc2\n" > "$W/pre/$g.ctlq" ;; esac; exit 0' > "$FR/tests/lib/static_job.sh"
for g in g_a g_b; do printf '#!/bin/sh\n# %s — a stub holding release-assets\n# SHARES: release-assets\n' "$g" > "$FR/tests/$g.sh"; done
for g in g_c g_d; do printf '#!/bin/sh\n# %s — a stub sharing nothing\n# SHARES: none — a stub\n' "$g" > "$FR/tests/$g.sh"; done
printf '#!/bin/sh\n# g_s — a stub whose two control modes must not overlap\n# SHARES: self\n' > "$FR/tests/g_s.sh"
printf '#!/bin/sh\n# g_n — a stub whose two control modes may overlap\n# SHARES: none — a stub\n' > "$FR/tests/g_n.sh"
pool3() {  # pool3 -> P3_HELD P3_FREE P3_SELF P3_NONE (apart|overlap|missing)
    rm -rf "$FR/w"; mkdir -p "$FR/w"
    (cd "$FR" && python3 tests/lib/static_pool.py 6 "$FR/w" all portable g_a g_b g_c g_d g_s g_n > "$W/pool.out" 2> "$W/pool.err") || :
    ov() { awk -v a="$1" -v b="$2" '$2 == a && $1 == "start" {sa = $3} $2 == a && $1 == "end" {ea = $3}
            $2 == b && $1 == "start" {sb = $3} $2 == b && $1 == "end" {eb = $3}
            END {if (!sa || !sb || !ea || !eb) print "missing"; else if (sb < ea && sa < eb) print "overlap"; else print "apart"}' "$FR/w/jobs.log"; }
    P3_HELD="$(ov g_a g_b)"; P3_FREE="$(ov g_c g_d)"; P3_SELF="$(ov g_s.c1 g_s.c2)"; P3_NONE="$(ov g_n.c1 g_n.c2)"
}
pool3
{ echo "pool: $(cat "$W/pool.out")"; sed 's/^/  log: /' "$FR/w/jobs.log"; } >> "$W/main.log"
[ "$P3_HELD" = apart ] && ok "the two release-assets stubs ran one after the other" \
    || bad "the token holders g_a and g_b ran $P3_HELD (want apart): $(tr '\n' '|' < "$FR/w/jobs.log")"
[ "$P3_FREE" = overlap ] && ok "the two none stubs ran side by side (the pool is parallel)" \
    || bad "the stubs sharing nothing g_c and g_d ran $P3_FREE (want overlap): $(tr '\n' '|' < "$FR/w/jobs.log")"
[ "$P3_SELF" = apart ] && ok "the self stub's two control modes ran one after the other" \
    || bad "the self stub g_s's control modes ran $P3_SELF (want apart): $(tr '\n' '|' < "$FR/w/jobs.log")"
[ "$P3_NONE" = overlap ] && ok "the none stub's two control modes ran side by side" \
    || bad "the none stub g_n's control modes ran $P3_NONE (want overlap): $(tr '\n' '|' < "$FR/w/jobs.log")"
if [ -z "${VS_CTL:-}" ]; then
    cp "$W/share_pool_blind.py" "$FR/tests/lib/share_pool.py"; pool3; cp tests/lib/share_pool.py "$FR/tests/lib/share_pool.py"
    [ "$P3_HELD" = overlap ] && vs_ctl_fired pool-tokens-ignored "a pool blind to tokens ran g_a and g_b together" \
        || { vs_ctl_dead pool-tokens-ignored "the blind pool still ran g_a and g_b $P3_HELD"; fail=1; }
    cp "$W/share_pool_noself.py" "$FR/tests/lib/share_pool.py"; pool3; cp tests/lib/share_pool.py "$FR/tests/lib/share_pool.py"
    [ "$P3_SELF" = overlap ] && vs_ctl_fired self-ignored "a reader that drops self ran g_s's two control modes together" \
        || { vs_ctl_dead self-ignored "the self-dropping reader still ran g_s's modes $P3_SELF"; fail=1; }
fi

echo "== 4. the host claim (an OS file lock, tests/lib/share_lock.py): wait then REFUSE, nested proceeds, a dead holder frees it, no two holders"
LIB="$REPO/tests/lib/shares.sh"
sed 's|            continue   # SHARES-NESTED: under the token.s live holder|            :   # SHARES-NESTED disabled|' "$LIB" > "$W/shares_nonest.sh"
cmp -s "$LIB" "$W/shares_nonest.sh" && bad "could not disable the nested skip — the SHARES-NESTED line moved"
sed 's#^        _vsc_max="$(_vs_shares_wait "$_vsc_t")"   \# SHARES-WAIT: .*$#        _vsc_max=0   \# SHARES-WAIT disabled#' "$LIB" > "$W/shares_nowait.sh"
cmp -s "$LIB" "$W/shares_nowait.sh" && bad "could not zero the wait — the SHARES-WAIT line moved"
mkroot() {  # mkroot <dir> [sed expression for share_lock.py]: a root holding tests/shares.tsv and the lock helper
    mkdir -p "$1/tests/lib"; cp tests/shares.tsv "$1/tests/"
    if [ -n "${2:-}" ]; then sed "$2" tests/lib/share_lock.py > "$1/tests/lib/share_lock.py"
        cmp -s tests/lib/share_lock.py "$1/tests/lib/share_lock.py" && bad "could not shadow the lock helper for $1 — its marked line moved"
    else cp tests/lib/share_lock.py "$1/tests/lib/"; fi
}
mkroot "$W/r_real"
mkroot "$W/r_nolock" 's|^            fcntl.flock(fd, fcntl.LOCK_EX \| fcntl.LOCK_NB)   # SHARE-LOCK-TAKE$|            pass   # SHARE-LOCK-TAKE disabled|'
mkroot "$W/r_noowner" 's|^    while alive(owner):   # SHARE-LOCK-OWNER: .*$|    while True:   # SHARE-LOCK-OWNER disabled|'
mkroot "$W/r_reg2"; awk -F'\t' 'BEGIN {OFS = "\t"} !/^#/ && $1 == "release-assets" {$2 = 2} {print}' tests/shares.tsv > "$W/r_reg2/tests/shares.tsv"
ROOT4="$W/r_real"
vs_ctl_is claim-nesting-ignored && LIB="$W/shares_nonest.sh"; vs_ctl_is claim-wait-ignored && LIB="$W/shares_nowait.sh"
vs_ctl_is lock-nb-ignored && ROOT4="$W/r_nolock"; vs_ctl_is owner-death-ignored && ROOT4="$W/r_noowner"
now() { python3 -c 'import time; print("%.3f" % time.time())'; }
claim4() {  # claim4 <lib> <root> <who> <token> <hold s> [VAR=value...]: a claim under sh -e; prints its output, exit in $C4
    _l="$1"; _r="$2"; _w="$3"; _t="$4"; _h="$5"; shift 5
    env VS_SHARES_DIR="$W/claims" REPO="$_r" "$@" sh -ec '. "$1"; vs_shares_claim "$2" "$3"; echo "CLAIMED $2 $$"; [ "$4" = 0 ] || { echo "hold $2 start $(python3 -c "import time; print(\"%.3f\" % time.time())")" >> "$5"; sleep "$4"; echo "hold $2 end $(python3 -c "import time; print(\"%.3f\" % time.time())")" >> "$5"; }; vs_shares_release' _ "$_l" "$_w" "$_t" "$_h" "$W/holds.log" 2>&1
}
sweep4() { pkill -f "share_lock.py hold $W/claims" 2>/dev/null || :; [ -n "$HOLDER" ] && kill -9 "$HOLDER" 2>/dev/null; HOLDER=""; }
s4() {  # s4 <lib> <root> -> S4a S4f S4b S4c S4d S4g S4e (refused|proceeded|claimed|freed|apart|taken, or what happened)
    sweep4; rm -rf "$W/claims"; mkdir -p "$W/claims"; : > "$W/holds.log"
    env VS_SHARES_DIR="$W/claims" REPO="$2" sh -c '. "$1"; vs_shares_claim holder release-assets; exec sleep 60' _ "$1" > "$W/holder.out" 2>&1 &
    HOLDER=$!; _i=0; while [ "$(cut -d' ' -f1 "$W/claims/release-assets.flock" 2>/dev/null)" != "$HOLDER" ] && [ "$_i" -lt 100 ]; do sleep 0.1; _i=$((_i + 1)); done
    _t0=$(date +%s); o="$(claim4 "$1" "$2" hand release-assets 0 VS_SHARES_WAIT=1)"; C4=$?; _dt=$(( $(date +%s) - _t0 ))
    case "$C4:$o" in 3:*"REFUSED: hand — the shared resource 'release-assets' is held on this host by $HOLDER holder"*"waited 1s of 1)"*) S4a=refused ;; *) S4a="exit $C4: $o" ;; esac
    [ "$S4a" = refused ] && [ "$_dt" -lt 1 ] && S4a="refused after ${_dt}s, under its 1-second wait"
    _t0=$(date +%s)
    o="$(env VS_SHARES_DIR="$W/claims" REPO="$W/r_reg2" sh -ec 'unset VS_SHARES_WAIT; . "$1"; vs_shares_claim reg release-assets; echo "CLAIMED reg"' _ "$1" 2>&1)"; C4=$?; _dt=$(( $(date +%s) - _t0 ))
    case "$C4:$o" in 3:*"REFUSED: reg — "*"waited 2s of 2)"*) S4f=refused ;; *) S4f="exit $C4: $o" ;; esac
    [ "$S4f" = refused ] && [ "$_dt" -lt 2 ] && S4f="refused after ${_dt}s, under the registry's 2-second wait"
    o="$(claim4 "$1" "$2" nested release-assets 0 VS_SHARES_WAIT=1 VS_SHARES_HOLDER_release_assets="$HOLDER")"; C4=$?
    if [ "$C4" = 0 ] && printf '%s' "$o" | grep -q '^CLAIMED nested' && [ "$(cut -d' ' -f1 "$W/claims/release-assets.flock")" = "$HOLDER" ]; then S4b=proceeded
    else S4b="exit $C4: $o"; fi
    o="$(claim4 "$1" "$2" other jtsim-scratch 0 VS_SHARES_WAIT=1 VS_SHARES_HOLDER_release_assets="$HOLDER")"; C4=$?
    if [ "$C4" = 0 ] && printf '%s' "$o" | grep -q '^CLAIMED other'; then S4c=claimed; else S4c="exit $C4: $o"; fi
    kill -9 "$HOLDER" 2>/dev/null; wait "$HOLDER" 2>/dev/null; HOLDER=""   # the holder dies hard: no EXIT trap, no release
    o="$(claim4 "$1" "$2" after release-assets 0 VS_SHARES_WAIT=3)"; C4=$?
    if [ "$C4" = 0 ] && printf '%s' "$o" | grep -q '^CLAIMED after'; then S4d=freed; else S4d="exit $C4: $o"; fi
    for _k in 1 2 3 4; do claim4 "$1" "$2" race$_k release-assets 1 VS_SHARES_WAIT=30 > "$W/race$_k.out" & done; wait
    _ok=0; for _k in 1 2 3 4; do grep -q "^CLAIMED race$_k" "$W/race$_k.out" && _ok=$((_ok + 1)); done
    _ov="$(awk '$1 == "hold" && $3 == "start" {s[$2] = $4} $1 == "hold" && $3 == "end" {e[$2] = $4}
        END {n = 0; for (a in s) for (b in s) if (a < b && s[a] < e[b] && s[b] < e[a]) n++; print n}' "$W/holds.log")"
    if [ "$_ok" = 4 ] && [ "$_ov" = 0 ]; then S4g=apart; else S4g="$_ok of 4 claimed, $_ov overlapping pair(s): $(tr '\n' '|' < "$W/holds.log")"; fi
    printf '99999999 a-holder-long-gone\n' > "$W/claims/jtsim-scratch.flock"   # a lock file left behind, nothing holding it
    _t0=$(date +%s); o="$(claim4 "$1" "$2" leftover jtsim-scratch 0 VS_SHARES_WAIT=0)"; C4=$?; _dt=$(( $(date +%s) - _t0 ))
    if [ "$C4" = 0 ] && printf '%s' "$o" | grep -q '^CLAIMED leftover' && [ "$_dt" -le 1 ]; then S4e=taken; else S4e="exit $C4 after ${_dt}s: $o"; fi
    sweep4
}
s4 "$LIB" "$ROOT4"
{ for v in S4a S4f S4b S4c S4d S4g S4e; do eval "echo \"$v \$$v\""; done; } >> "$W/main.log"
[ "$S4a" = refused ] && ok "beside a live holder a hand run waited 1 s and was REFUSED (exit 3), naming the holder and its wait" || bad "beside a live holder: $S4a"
[ "$S4f" = refused ] && ok "with no VS_SHARES_WAIT a hand run read the token's 2-second wait from the registry, waited it out and was REFUSED" || bad "the registry's wait: $S4f"
[ "$S4b" = proceeded ] && ok "a run whose environment names the live holder proceeded at once, the holder's lock untouched" || bad "nested under the holder: $S4b"
[ "$S4c" = claimed ] && ok "a run naming the holder of another token claimed its own token normally" || bad "naming another token's holder: $S4c"
[ "$S4d" = freed ] && ok "the holder killed with SIGKILL (no trap ran), the next claim took the token within its wait" || bad "after the holder died: $S4d"
[ "$S4g" = apart ] && ok "four claimers started at once each got the token, and no two held it at the same time" || bad "two or more claimers held release-assets at once, or one never got it: $S4g"
[ "$S4e" = taken ] && ok "a lock file left behind with a dead holder's line, and nothing holding it, was claimed at once" || bad "beside a left-over lock file: $S4e"
if [ -z "${VS_CTL:-}" ]; then
    s4 "$W/shares_nonest.sh" "$W/r_real"
    [ "$S4b" != proceeded ] && vs_ctl_fired claim-nesting-ignored "a claim blind to nesting: the run under the live holder read '$(printf '%s' "$S4b" | head -1 | cut -c1-100)'" \
        || { vs_ctl_dead claim-nesting-ignored "the nesting-blind claim still let the nested run through"; fail=1; }
    s4 "$W/shares_nowait.sh" "$W/r_real"
    [ "$S4a" != refused ] && [ "$S4f" != refused ] && vs_ctl_fired claim-wait-ignored "a claim whose wait is 0 refused at once: '$(printf '%s' "$S4f" | head -1 | cut -c1-100)'" \
        || { vs_ctl_dead claim-wait-ignored "the zero-wait claim still read as waiting (S4a $S4a, S4f $S4f)"; fail=1; }
    s4 "$LIB" "$W/r_nolock"
    [ "$S4g" != apart ] && vs_ctl_fired lock-nb-ignored "a helper that never takes the flock: $(printf '%s' "$S4g" | cut -c1-100)" \
        || { vs_ctl_dead lock-nb-ignored "the lock-less helper still kept the four claimers apart"; fail=1; }
    s4 "$LIB" "$W/r_noowner"
    [ "$S4d" != freed ] && vs_ctl_fired owner-death-ignored "a helper that outlives its holder: the claim after the holder died read '$(printf '%s' "$S4d" | head -1 | cut -c1-100)'" \
        || { vs_ctl_dead owner-death-ignored "the immortal helper still freed the token"; fail=1; }
fi

if [ -n "${VS_CTL:-}" ]; then
    if [ "$fail" = 0 ]; then echo "PASS: test_shares (control mode $VS_CTL changed no verdict)"; exit 0; fi
    case "$VS_CTL" in
        no-line|unknown-token|unclaimed|unheld) : ;;
        pool-tokens-ignored) WANT="FAIL  the token holders g_a and g_b ran overlap" ;;
        self-ignored) WANT="FAIL  the self stub g_s's control modes ran overlap" ;;
        claim-nesting-ignored) WANT="FAIL  nested under the holder: exit 3" ;;
        claim-wait-ignored) WANT="FAIL  the registry's wait: exit 3: REFUSED: reg .*waited 0s of 0" ;;
        lock-nb-ignored) WANT="FAIL  two or more claimers held release-assets at once, or one never got it: 4 of 4 claimed, [1-9]" ;;
        owner-death-ignored) WANT="FAIL  after the holder died: exit 3" ;;
    esac
    vs_ctl_caught "$W/main.log" "$WANT"
    echo "FAIL: test_shares (control mode $VS_CTL)"; exit 1
fi
[ "$fail" = 0 ] && echo "PASS: test_shares — every gate declares what it shares; the pool keeps token holders apart; the host claim waits, refuses, nests and takes over" \
    || { echo "FAIL: test_shares"; exit 1; }
