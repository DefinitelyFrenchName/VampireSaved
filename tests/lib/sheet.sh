# sheet.sh — what a comparing gate RAN and JUDGED, written for the comparative capture sheets (14z-204, GitHub #291
# slice S1, the design ruled 2026-10-17). Sourced; sh, no bashisms.
#
# THE CONTRACT. A gate whose leading comment block declares `# SHEET: legs ...` sources this file and, ONLY when the
# caller set SHEET_OUT=<dir>, writes the legs it ran and the moments it judged to $SHEET_OUT/sheet.tsv. With SHEET_OUT
# unset every function returns 0 and writes nothing, so the gate decides nothing differently: it only writes a file.
# tools/proof_sheets.py reads that file, re-runs each leg with tests/lua/sheet_capture.lua, photographs it at each
# moment, and PROVES each picture against what the gate logged there; a picture it cannot prove is shown as NOT THE
# JUDGED RUN, never silently.
#
# THE FILE (tab-separated; tools/proof_sheets.py `read_sheet` is its one reader and refuses a malformed row):
#   sheet   <sid> <title> <chars|-> <tickets|-> <not comparable>
#   leg     <sid> <leg> <role> <set> <rompath> <replay> <pokes|-> <frames> <log|-> <mask|->
#   moment  <sid> <mid> <label> <verdict> <values|->
#   at      <sid> <mid> <leg> <frame> <basis> <expect|->
#   anchors <sid>
#   tap     <sid> <leg> <instrument> <env>   (D2: the leg re-runs under its gate's own instrument; env is K=V;K=V)
#   trace   <sid> <leg> <trace file> <FIELDS>   (#291 S4-D: the gate's per-frame tests/lua/field_trace.lua log of the
#           leg and its addr:size:name spec, so every frame of a `fields` span is proven on what the gate traced there)
#   span    <sid> <mid> <leg> <lo-hi | f1,f2,...>   (#291 S4-D: the judged event's window on that leg — about 9 frames
#           spread across lo-hi, the moment's frame among them — or an explicit frame list, kept whole; each frame is
#           proven on the moment's own basis: log, fields (needs the leg's trace row first) or event)
#   inputs  <sid> <n>   (#291 S4-E: also photograph, in EACH round, up to n (at most 18) frames where the replay starts
#           holding an input (or, short of that, holds one), the rounds found from the sheet's anchors; each proven on
#           the leg's log)
# role is ours | vsavj | vs2. replay and log are paths INSIDE $SHEET_OUT (sheet_leg copies them there, because the
# gate's own work directory is deleted at its exit). frames is how far the leg runs. mask is replay.lua's MASK_RANGES
# for the leg's checksum log (`-` = the whole of work RAM).
# basis, what proves the picture of leg <leg> at <frame>:
#   log     the leg's own checksum log (replay.lua's, the gate's), read at <frame>;
#   ram     <expect> is that checksum, given directly (16 hex digits);
#   fields  <expect> is `addr:size=value,...` (size b/w/l, words and longs SIGNED: tests/lua/field_trace.lua's reading);
#   file    <expect> is a picture inside $SHEET_OUT that the gate itself judged (a frozen golden): shown as it is;
#   none    nothing the gate logged can prove it: the picture is shown UNPROVEN;
#   event   <expect> is `<log inside SHEET_OUT>:<lo>-<hi>`, the gate's own tap log and a frame window: the leg (which
#           needs a `tap` row) is re-run under tests/lua/sheet_tap_capture.lua, and the picture is EVENT-PROVEN when the
#           re-run's lines in the window equal the gate's — weaker than a checksum, and said so (ruled 2026-10-18, D2).
# `anchors <sid>` asks for the replay's sync anchors (round start, each down and the next round's spawn) on every leg
# of the sheet, proven on the leg's log: the legacy oracle's moments beyond its attributed frames (ruled 2026-10-17).

sheet_on() { [ -n "${SHEET_OUT:-}" ]; }

# sh has no locals: every helper variable below is prefixed `__sheet_`, so it cannot overwrite a caller's (14z-204: a
# helper loop named `_sf` overwrote audit_merged_legacy's frame variable of the same name between two calls).
_sheet_row() {  # _sheet_row <field>... — one tab-separated row, a tab or newline inside a field refused
    for __sheet_f in "$@"; do
        case "$__sheet_f" in *"	"*|*"
"*) echo "sheet.sh: a field holds a tab or a newline: $__sheet_f" >&2; return 1 ;; esac
    done
    mkdir -p "$SHEET_OUT"
    __sheet_r="$1"; shift
    for __sheet_f in "$@"; do __sheet_r="$__sheet_r	$__sheet_f"; done
    printf '%s\n' "$__sheet_r" >> "$SHEET_OUT/sheet.tsv"
}

sheet_new() {  # sheet_new <sid> <title> <chars|-> <tickets|-> <not comparable>
    sheet_on || return 0
    _sheet_row sheet "$1" "$2" "$3" "$4" "$5"
}

sheet_leg() {  # sheet_leg <sid> <leg> <role> <set> <rompath> <replay file> <pokes|-> <frames> [<log file|-> [<mask|->]]
    sheet_on || return 0
    mkdir -p "$SHEET_OUT/legs"
    __sheet_rpl="legs/$1.$2.rpl"; cp "$6" "$SHEET_OUT/$__sheet_rpl" || return 1
    __sheet_log=-
    if [ -n "${9:-}" ] && [ "${9:-}" != - ]; then __sheet_log="legs/$1.$2.log"; cp "$9" "$SHEET_OUT/$__sheet_log" || return 1; fi
    _sheet_row leg "$1" "$2" "$3" "$4" "$5" "$__sheet_rpl" "${7:--}" "$8" "$__sheet_log" "${10:--}"
}

sheet_moment() {  # sheet_moment <sid> <mid> <label> <verdict> [<values|->]
    sheet_on || return 0
    _sheet_row moment "$1" "$2" "$3" "$4" "${5:--}"
}

sheet_at() {  # sheet_at <sid> <mid> <leg> <frame> <basis> [<expect|->]
    sheet_on || return 0
    _sheet_row at "$1" "$2" "$3" "$4" "$5" "${6:--}"
}

sheet_file() {  # sheet_file <sid> <name> <picture> — copy a picture the gate judged; prints its path inside SHEET_OUT
    sheet_on || return 0
    mkdir -p "$SHEET_OUT/files"
    cp "$3" "$SHEET_OUT/files/$1.$2" && printf 'files/%s.%s' "$1" "$2"
}

sheet_rows() {  # sheet_rows <file> — append moment/at/span rows a gate's own script wrote in the format above (bulk emitters)
    sheet_on || return 0
    awk -F'\t' '($1 == "moment" && NF == 6) || ($1 == "at" && NF == 7) || ($1 == "span" && NF == 5) {next} {bad = NR; exit} END {exit bad ? 1 : 0}' "$1" \
        || { echo "sheet.sh: $1 holds a row that is not a 6-field moment, a 7-field at or a 5-field span" >&2; return 1; }
    mkdir -p "$SHEET_OUT"; cat "$1" >> "$SHEET_OUT/sheet.tsv"
}

sheet_tap() {  # sheet_tap <sid> <leg> <instrument path> <env: name-value pairs, ';'-separated> — the leg's own tap instrument (D2)
    sheet_on || return 0
    _sheet_row tap "$1" "$2" "$3" "$4"
}

sheet_trace() {  # sheet_trace <sid> <leg> <field_trace file> <FIELDS addr:size:name,...> — the leg's per-frame trace (S4-D)
    sheet_on || return 0
    mkdir -p "$SHEET_OUT/legs"
    __sheet_tr="legs/$1.$2.trace"; cp "$3" "$SHEET_OUT/$__sheet_tr" || return 1
    _sheet_row trace "$1" "$2" "$__sheet_tr" "$4"
}

sheet_span() {  # sheet_span <sid> <mid> <leg> <lo-hi | f1,f2,...> — the judged event's window on that leg (S4-D)
    sheet_on || return 0
    _sheet_row span "$1" "$2" "$3" "$4"
}

sheet_inputs() {  # sheet_inputs <sid> <n> — up to n frames at the replay's own inputs, inside rounds (S4-E)
    sheet_on || return 0
    _sheet_row inputs "$1" "$2"
}

sheet_anchors() {  # sheet_anchors <sid>
    sheet_on || return 0
    _sheet_row anchors "$1"
}
