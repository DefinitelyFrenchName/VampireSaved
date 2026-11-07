#!/bin/sh
# test_dead_span_reach.sh — ON EACH TRACKED BUILT IMAGE, A PORT'S DEAD SPAN IS REACHED BY ITS ALLOWED TABLE ROWS AND NOTHING ELSE (14z-221c, GitHub #354).
#
# WHAT: a port puts a jump on six bytes proven dead in PRISTINE vsavj (tests/test_dead_span.sh) and points one table row
#   at it — two spans since M26: #294's PRG:0x024024-0x024029 (the per-frame palette table PRG:0x02ADEC's row 0x13) and
#   #363's PRG:0x029CBA-0x029CBF (the victim reaction table PRG:0x02385C's row 0x4F). test_dead_span reads pristine vsavj
#   only and the ports' own gates perturb the port itself, so a later change that made other code in the BUILT image
#   reach a span passed both (#354). This gate reads every span of tests/expected/dead_span_reach.tsv on the five
#   tracked builds (MERGED DON HUI PYR STOCK, tests/run_all_emulator.sh's tracks): on a build the row's roles name, the
#   span is reached by EXACTLY its allowed table rows, each bound to its named reader sites — no instruction names a span
#   address (A), no 32-bit value equals one (C), no other table row gives one (T), no PC-indexed read lands in it through
#   a base within 0x100 of it on either side (D: an index may be negative), no register is loaded with such a base, odd or even, or has such a constant added to it (R), except the bases the row accepts at
#   their named sites; every allowed row is seen; and the fence holds (L: every reached instruction ending at the span
#   start is an unconditional transfer and none straddles it); on every other build the span is DEAD by the same six rules.
#   Addresses are read as the 68000's 24-bit bus sees them: an operand's top byte is ignored, and a data long counts with
#   top byte 0x00 or 0xFF (14z-221c, rule-checker run 2026-11-06-1676; the tool's header).
# HOW: tools/audit_dead_span.py on each build's verify_op.bin / verify_data.bin (the opcode and data views the build
#   writes), the code ranges the vsavj window 0-0x100000 plus every [[space]] of the three tenant manifests clipped to the
#   image (hole_b, and wide_ext on a WIDE image): `--allow-table <row> --expect only` on a carrying build, the default
#   `--expect dead` elsewhere. Each rule is over-approximate (decode at every even address, every 2-aligned long of both
#   full views, every table base's rows within the jump-table extent), so a false reference can only turn it red.
#   The controls: in-gate, each is planted on EVERY span, on the first build the span's roles name, and reads FIRED only
#   when it fails each span by its own rule (14z-223, GitHub #366: planted on the first span only, the fall-through plant
#   was blind on #363's span and no run showed it); as a mode it plants on the first span only.
# EXPECTS: #294's span: on merged and Donovan solo, VERDICT REACHED ONLY (allowed PRG:0x02A646 row 0x8A, PRG:0x02ADEC
#   row 0x13 seen 2 of 2, other refs A 0 C 0 T 0 D 0 R 0, fenced yes); on Phobos solo, Pyron solo and the stock twin,
#   VERDICT DEAD. #363's span: on merged and Phobos solo, VERDICT REACHED ONLY (allowed PRG:0x02385C row 0x4F seen 1 of 1,
#   other refs A 0 C 0 T 0 D 0 R 0, fenced yes); on Donovan solo, Pyron solo and the stock twin, VERDICT DEAD. A red names the extra
#   reference (instruction, long or table row), the missing allowed row, or the broken fence. Stated, not tested: an
#   address formed at run time from no constant anywhere (the tool's header); that a base or row the table accepts at
#   its named sites never reaches the span at run time (0x23F84's reader is bounded on pristine vsavj only,
#   tests/audit_dead_span_exec.sh; 0x24000 and row 0x8A of 0x02A646 rest on reading the code, and so do #363's three
#   bases above its span, 0x029CC2, 0x029D02 and 0x029D92, as tests/test_dead_span.sh names them); what each jump does
#   at run time (tests/audit_don_row0c.sh, tests/audit_beam_slide.sh); code outside the declared ranges (the vsavj window and the manifests' spaces).
#
# MUST-FIRE: perturbed-copy: plant-jsr — the first span's first carrying build with a `jsr <span start>.l` planted in memory at the top of its last code range must be REACHED OTHERWISE with an A reference (mode: the tool's --plant jsr on that build)
# MUST-FIRE: perturbed-copy: plant-long — the same build with the span start planted as a long near the end of its data view must be REACHED OTHERWISE with a C reference (mode: --plant long)
# MUST-FIRE: perturbed-copy: plant-table — the same build with a second PC-indexed word table whose row 0 gives the span start must be REACHED OTHERWISE with a T reference (mode: --plant table)
# MUST-FIRE: perturbed-copy: plant-table-data — the same build with a `lea B.l,a0` (B 0x300 past the span, beyond rule R) and, in the data view at B, a row 0 giving the span start must be REACHED OTHERWISE by rule T with the REF line naming the data view: a register-loaded table's rows are read in both views (14z-221c, rule-checker run 2026-11-06-1678; mode: --plant table-data)
# MUST-FIRE: perturbed-copy: plant-pcidx — the same build with a `move.b $<span start - 0x10>(pc,d0.w),d0` planted 0x40 below the span must be REACHED OTHERWISE by rule D (14z-221c; mode: --plant pcidx)
# MUST-FIRE: perturbed-copy: plant-pcidx-above — the same build with a `move.b $<span end + 0x10>(pc,d0.w),d0` planted 0x40 below the span, a base ABOVE the span that a negative index reaches, must be REACHED OTHERWISE by rule D (its window is two-sided since 14z-221c, rule-checker run 2026-11-06-1664; mode: --plant pcidx-above)
# MUST-FIRE: perturbed-copy: plant-lea — the same build with a `lea <span start - 0x10>.l,a0` planted at the top of the code window must be REACHED OTHERWISE by rule R (14z-221c; mode: --plant lea)
# MUST-FIRE: perturbed-copy: plant-lea-odd — the same build with a `lea <span start - 0x0F>.l,a0`, an ODD base, planted at the top of the code window must be REACHED OTHERWISE by rule R, which takes a base of either parity (14z-221c, rule-checker run 2026-11-06-1669; mode: --plant lea-odd)
# MUST-FIRE: perturbed-copy: plant-adda — the same build with an `adda.l #<span start - 0x10>,a0` planted at the top of the code window must be REACHED OTHERWISE by rule R: a constant added to a register forms the base (14z-221c, rule-checker run 2026-11-06-1669; mode: --plant adda)
# MUST-FIRE: perturbed-copy: plant-pea — the same build with a `pea <span start - 0x10>.l` planted at the top of the code window must be REACHED OTHERWISE by rule R (each form rule R lists has its control, so a capstone name the tool stopped matching fails: the lea.l trap; 14z-221c, rule-checker run 2026-11-06-1674; mode: --plant pea)
# MUST-FIRE: perturbed-copy: plant-movea — the same with a `movea.l #<span start - 0x10>,a0` must be REACHED OTHERWISE by rule R (14z-221c; mode: --plant movea)
# MUST-FIRE: perturbed-copy: plant-addi — the same with an `addi.l #<span start - 0x10>,d0` must be REACHED OTHERWISE by rule R (14z-221c; mode: --plant addi)
# MUST-FIRE: perturbed-copy: plant-jsr-alias — the same build with `jsr $01<span start>.l` planted at the top of the code window must be REACHED OTHERWISE with an A reference: the 68000's 24-bit bus ignores the top byte (14z-221c, rule-checker run 2026-11-06-1676; mode: --plant jsr-alias)
# MUST-FIRE: perturbed-copy: plant-long-alias — the same with the long 0xFF<span start> near the end of the data view must be REACHED OTHERWISE with a C reference (a long counts with top byte 0x00 or 0xFF; mode: --plant long-alias)
# MUST-FIRE: perturbed-copy: plant-lea-alias — the same with `lea $FF<span start - 0x10>.l,a0` must be REACHED OTHERWISE by rule R (mode: --plant lea-alias)
# MUST-FIRE: perturbed-copy: base-reloaded — the same build with a second `lea` of the port row's table base planted near the top of the code window must be REACHED OTHERWISE by rule T: an allowed row is bound to its base's named sites (14z-221c; mode: --plant reload)
# MUST-FIRE: perturbed-copy: base-reread — the same build with a second `move.b <the row's first accepted base>(pc,d0.w),d0` planted 0x40 below that base must be REACHED OTHERWISE by rule D: an accepted base is bound to its named readers (14z-221c; mode: --plant reread)
# MUST-FIRE: perturbed-copy: second-entry — the same build with a long (span start - 2) planted in the data view, so a second reached path enters just before the span, must be REACHED OTHERWISE by the fence: every reached instruction ending at the span start must be an unconditional transfer and none may straddle it (14z-221c; mode: --plant second-entry)
# MUST-FIRE: perturbed-copy: second-entry-alias — second-entry with the long 0xFF<span start - 2>, a 24-bit alias, must be REACHED OTHERWISE by the fence: the descent's entries are read as the 68000's bus does (14z-221c, rule-checker run 2026-11-06-1677; mode: --plant second-entry-alias)
# MUST-FIRE: perturbed-copy: straddle — the same build with a 4-byte `move.w #imm,d0` written at the span start - 2 and a long naming it, so a reached instruction straddles the span's first byte, must be REACHED OTHERWISE with the FENCE line naming it STRADDLING (14z-221c, rule-checker run 2026-11-06-1664; mode: --plant straddle)
# MUST-FIRE: perturbed-copy: row-dropped — the same build with the allowed row given its neighbour's word must be REACHED OTHERWISE, the allowed row seen 0 times ("exactly one" fails on none; mode: --plant unallow)
# MUST-FIRE: perturbed-copy: fall-through — the same build with nops over every reached instruction ending at the span start, each whole (a 4-byte bra.w on #294's span, a 6-byte jmp.l on #363's; 14z-223, #366), must be REACHED OTHERWISE, not fenced (mode: --plant fallthrough)
# MEASURES: judged-pairs — 10 the (span, build) pairs given a verdict: the table's two frozen spans (#294's, #363's) on the five tracked builds
# FOLLOWS: tools/audit_dead_span.py tools/_minitoml.py tests/expected/dead_span_reach.tsv build/manifest/donovan.toml
#   build/manifest/huitzil.toml build/manifest/pyron.toml tests/lib/controls.sh
#
# SHEET: none — a static read of program bytes; no emulator leg
#
# Usage: [MERGED=build/m3b_merged34] [DON=build/don_m30] [HUI=build/hui64] [PYR=build/pyron49] [STOCK=build/m5_stock25]
#   tests/test_dead_span_reach.sh       static tier (built images, no ROMDIR, no emulator); ~19 min on the MacBook (18:42 measured
#   14z-223 with the controls on both spans; 10:31 with them on the first span only)
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
python3 -c "import capstone" 2>/dev/null || { echo "SKIP: python capstone not installed"; exit 0; }
MERGED="${MERGED:-build/m3b_merged34}"; DON="${DON:-build/don_m30}"; HUI="${HUI:-build/hui64}"
PYR="${PYR:-build/pyron49}"; STOCK="${STOCK:-build/m5_stock25}"
TAB="tests/expected/dead_span_reach.tsv"
ROLES="merged donovan huitzil pyron stock"
TOOL="python3 tools/audit_dead_span.py"
SPACES="--spaces build/manifest/donovan.toml --spaces build/manifest/huitzil.toml --spaces build/manifest/pyron.toml"
W="$(mktemp -d)" || { echo "FAIL: test_dead_span_reach — mktemp -d failed (W)"; exit 2; }; trap 'rm -rf "$W"' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }

dir_of() {  # dir_of <role> — the build dir, absolute
    case "$1" in merged) d="$MERGED" ;; donovan) d="$DON" ;; huitzil) d="$HUI" ;; pyron) d="$PYR" ;; stock) d="$STOCK" ;;
        *) return 1 ;; esac
    case "$d" in /*) echo "$d" ;; *) echo "$REPO/$d" ;; esac
}
has_views() { [ -f "$1/verify_op.bin" ] && [ -f "$1/verify_data.bin" ]; }
carries() { case ",$2," in *",$1,"*) return 0 ;; esac; return 1; }   # carries <role> <roles list>

# the table: span, row, roles, ticket — every row well-formed, at least one
grep -v '^#' "$TAB" | awk -F'\t' 'NF' > "$W/rows.tsv"
if [ ! -s "$W/rows.tsv" ]; then vs_ctl_nj "the span table $TAB has no row"; echo "FAIL: test_dead_span_reach (no row in $TAB)"; exit 1; fi
if awk -F'\t' '!($1 ~ /^[0-9a-f]+-[0-9a-f]+$/ && $2 ~ /^[0-9A-Fa-f]+:[0-9A-Fa-f]+(@[0-9A-Fa-f]+(\/[0-9A-Fa-f]+)*)?(,[0-9A-Fa-f]+:[0-9A-Fa-f]+(@[0-9A-Fa-f]+(\/[0-9A-Fa-f]+)*)?)*$/ && $3 ~ /^(-|[0-9A-Fa-f]+(@[0-9A-Fa-f]+(\/[0-9A-Fa-f]+)*)?(,[0-9A-Fa-f]+(@[0-9A-Fa-f]+(\/[0-9A-Fa-f]+)*)?)*)$/ && $4 ~ /^[a-z]+(,[a-z]+)*$/ && $5 ~ /^[0-9]+$/) { print; bad = 1 } END { exit !bad }' "$W/rows.tsv" > "$W/badrows"; then
    vs_ctl_nj "the span table has a malformed row"; echo "FAIL: test_dead_span_reach (malformed row in $TAB: $(head -1 "$W/badrows"))"; exit 1
fi
for r in $(cut -f4 "$W/rows.tsv" | tr ',' ' '); do
    dir_of "$r" > /dev/null || { echo "FAIL: test_dead_span_reach (role '$r' in $TAB is not one of: $ROLES)"; exit 1; }
done

# the builds: none present is a fresh checkout (SKIP, as ci_static's build-dir gates do); some missing is a red
present=0; missing=""
for r in $ROLES; do d="$(dir_of "$r")"; if has_views "$d"; then present=$((present + 1)); else missing="$missing ${d#$REPO/}"; fi; done
if [ "$present" -eq 0 ]; then echo "SKIP: no build at any of the five tracks (no verify_op.bin/verify_data.bin:$missing)"; exit 0; fi

# judge <role> <span> <row> <pcidx> <roles> [<plant>] — runs the tool; writes $W/out; prints nothing; sets jrc
judge() {
    d="$(dir_of "$1")"
    # the row column may name more than one row (14z-221c): the port's own first, then a row accepted with a reason in
    # the table's `why`; each is passed as its own --allow-table
    _at=""; for _r in $(echo "$3" | tr ',' ' '); do _at="$_at --allow-table $_r"; done
    if carries "$1" "$5"; then x="$_at --expect only"; else x="$_at"; fi
    # the row's accepted PC-indexed bases (rule D, 14z-221c): each carries a runtime bound named in the table's `why`
    px=""; [ "$4" = - ] || for b in $(echo "$4" | tr ',' ' '); do px="$px --allow-pcidx $b"; done
    p=""; [ -n "${6:-}" ] && p="--plant $6"
    # base-reloaded: a second loader of the port row's table base (its site binding, 14z-221c, rule-checker run -1661)
    [ "${6:-}" = reload ] && p="$p --reload-base $(echo "$3" | cut -d, -f1 | cut -d: -f1)"
    # base-reread: a second PC-indexed reader of the row's first accepted base (rule D's site binding, run -1662)
    [ "${6:-}" = reread ] && p="$p --reload-base $(echo "$4" | cut -d, -f1 | cut -d@ -f1)"
    $TOOL "$d/verify_op.bin" "$d/verify_data.bin" --span "$2" --code 0-100000 $SPACES $x $px $p > "$W/out" 2>&1 < /dev/null; jrc=$?
}
verdict() { grep -a '^VERDICT' "$W/out" | head -1; }

# the controls' target: the first row's span on the first build its roles name
set -- $(head -1 "$W/rows.tsv" | cut -f1-4)
C_SPAN="$1"; C_ROW="$2"; C_PX="$3"; C_ROLES="$4"; C_ROLE="${4%%,*}"
CTL="plant-jsr:jsr:A plant-long:long:C plant-table:table:T plant-table-data:table-data:tdata plant-pcidx:pcidx:D plant-pcidx-above:pcidx-above:D plant-lea:lea:R plant-lea-odd:lea-odd:R plant-adda:adda:R plant-pea:pea:R plant-movea:movea:R plant-addi:addi:R plant-jsr-alias:jsr-alias:A plant-long-alias:long-alias:C plant-lea-alias:lea-alias:R base-reloaded:reload:T base-reread:reread:D second-entry:second-entry:fence second-entry-alias:second-entry-alias:fence straddle:straddle:straddle row-dropped:unallow:seen fall-through:fallthrough:fence"
# fired_for <expect-key>: the verdict line says REACHED OTHERWISE for the control's own reason
fired_for() {
    v="$(verdict)"
    echo "$v" | grep -q '^VERDICT REACHED OTHERWISE' || return 1
    case "$1" in
        A) echo "$v" | grep -qE 'other refs A [1-9]' ;; C) echo "$v" | grep -qE ' C [1-9][0-9]* T' ;;
        # the tool prints `T n D n R n;` since rules D and R (14z-221c); one arm per line (a comment once swallowed the
        # seen arm: rule-checker run 2026-11-06-1660)
        T) echo "$v" | grep -qE ' T [1-9][0-9]* D ' ;;
        # rule T's DATA-view half: the REF line must name the data view (14z-221c, rule-checker run -1678)
        tdata) echo "$v" | grep -qE ' T [1-9][0-9]* D ' && grep -a '^REF T' "$W/out" | grep -q '(data view' ;;
        D) echo "$v" | grep -qE ' D [1-9][0-9]* R ' ;;
        R) echo "$v" | grep -qE ' R [1-9][0-9]*;' ;;
        seen) echo "$v" | grep -q 'seen 0 of' ;;
        fence) echo "$v" | grep -q 'fenced no' ;;
        # a straddler, not a second predecessor: the FENCE line must name it (14z-221c, rule-checker run -1664 Q1)
        straddle) echo "$v" | grep -q 'fenced no' && grep -a '^FENCE' "$W/out" | grep -q 'STRADDLING the span start' ;;
    esac
}

for c in $CTL; do
    name="${c%%:*}"; rest="${c#*:}"; plant="${rest%%:*}"; key="${rest#*:}"
    if vs_ctl_is "$name"; then
        d="$(dir_of "$C_ROLE")"
        has_views "$d" || { vs_ctl_nj "no verify_op.bin/verify_data.bin at ${d#$REPO/}"; echo "FAIL: test_dead_span_reach (no views at ${d#$REPO/})"; exit 1; }
        echo "== MODE $name: span $C_SPAN on $C_ROLE (${d#$REPO/}) with --plant $plant"
        judge "$C_ROLE" "$C_SPAN" "$C_ROW" "$C_PX" "$C_ROLES" "$plant"
        grep -aE '^(# PLANT|REF|ALLOW|MISSING|LIVE|FENCE|VERDICT)' "$W/out" | sed 's/^/        /'
        if [ -z "$(verdict)" ]; then   # the tool died or never judged: its tail, indented, and the run judged nothing
            tail -8 "$W/out" | sed 's/^/  | /'
            vs_ctl_nj "the tool gave no verdict line (rc $jrc)"; echo "FAIL: test_dead_span_reach (no verdict)"; exit 1
        fi
        [ "$jrc" -eq 0 ] && vs_ctl_left_green "$name" "FAIL: the $plant plant left the span reached only by its row"
        fired_for "$key" || { vs_ctl_nj "the $plant plant failed the span, but not by its own rule ($(verdict))"; echo "FAIL: test_dead_span_reach (control mode)"; exit 1; }
        echo "FAIL (mode): as required — the $plant plant made the span REACHED OTHERWISE"; exit 1
    fi
done

echo "== 1. each span of $TAB on each tracked build"
pairs=0
while IFS="$(printf '\t')" read -r span row pcidx roles ticket why; do
    for r in $ROLES; do
        d="$(dir_of "$r")"
        if ! has_views "$d"; then bad "#$ticket span $span on $r: no verify_op.bin/verify_data.bin at ${d#$REPO/} — NOT JUDGED, never a pass"; continue; fi
        judge "$r" "$span" "$row" "$pcidx" "$roles"
        v="$(verdict)"
        grep -aE '^(#|REF|ALLOW|MISSING|LIVE|FENCE|VERDICT)' "$W/out" | grep -v '^# /' | sed 's/^/        /'
        if [ -z "$v" ]; then bad "#$ticket span $span on $r (${d#$REPO/}): the tool gave no verdict (rc $jrc)"; continue; fi
        pairs=$((pairs + 1))
        if carries "$r" "$roles"; then
            if [ "$jrc" -eq 0 ] && echo "$v" | grep -q '^VERDICT REACHED ONLY'; then ok "#$ticket span $span on $r (${d#$REPO/}): reached only by row $row"
            else bad "#$ticket span $span on $r (${d#$REPO/}): not reached only by row $row ($v)"; fi
        else
            if [ "$jrc" -eq 0 ] && echo "$v" | grep -q '^VERDICT DEAD'; then ok "#$ticket span $span on $r (${d#$REPO/}): DEAD"
            else bad "#$ticket span $span on $r (${d#$REPO/}): not DEAD ($v)"; fi
        fi
    done
done < "$W/rows.tsv"
echo "MEASURED: judged-pairs = $pairs"

# every control on EVERY span, each on the first build its roles name, FIRED only when it fails each span by its own
# rule (14z-223, GitHub #366: the fall-through plant nopped 4 bytes, and #363's fence is a 6-byte jmp.l, so on that span
# it fenced nothing — while the controls planted on the first span only, no run could show it)
echo "== 2. controls: each must fire in-gate on every span of $TAB, on the first build its roles name (the modes above prove them as modes on span $C_SPAN)"
for c in $CTL; do
    name="${c%%:*}"; rest="${c#*:}"; plant="${rest%%:*}"; key="${rest#*:}"
    cok=""; cbad=""
    while IFS="$(printf '\t')" read -r span row pcidx roles ticket why; do
        role="${roles%%,*}"
        if ! has_views "$(dir_of "$role")"; then cbad="$cbad; #$ticket span $span: no views at $role — the control ran nothing there"; continue; fi
        judge "$role" "$span" "$row" "$pcidx" "$roles" "$plant"
        if [ "$jrc" -ne 0 ] && fired_for "$key"; then cok="$cok; #$ticket on $role: $(verdict)"
        else tail -8 "$W/out" | sed 's/^/  | /'; cbad="$cbad; #$ticket span $span on $role: rc $jrc: $(verdict)"; fi
    done < "$W/rows.tsv"
    if [ -z "$cbad" ]; then vs_ctl_fired "$name" "${cok#; }"
    else vs_ctl_dead "$name" "the $plant plant did not fail every span by its own rule: ${cbad#; }"; fail=1; fi
done

[ "$fail" -eq 0 ] && echo "PASS" || echo "FAIL"
exit "$fail"
