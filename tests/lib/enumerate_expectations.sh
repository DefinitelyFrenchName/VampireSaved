# enumerate_expectations.sh — shared expectation-kind enumeration. Source it.
#
# WHY IT EXISTS (14z-90, GitHub issue #17). tests/audit_merged_legacy.sh
# evaluated `"$EXPECT"/*.masked` and said nothing about anything else in the
# directory. `.pending` marks a legacy pairing with NO ratified class in any
# expectation set — exactly the state the audit exists to detect — so the two
# dropped replays put its blind spot precisely over the project's one open
# superset-invariant regression. 43 of 45 pairings were measured and the gap
# was reported nowhere; the script's own header claimed 47.
#
# It REPORTS, it does not INCLUDE. A `.pending` file is prose, not a
# `<class> <baseset> <args>` line, so there is nothing to compare against.
# Borrowing another set's class would be a FOURTH inline merged override, and
# STATE.md 14z-89 (4) pre-flags that as the wrong direction. The three tenant
# sets are also measurably NOT interchangeable (they disagree on 12, 26 and
# 37_victor_ko), so "just use huitzil's spec" is not available either.
#
# enumerate_expectations <expect-dir> <repo-root>
#   prints one `<name>|<kind>|<disposition>` line per expectation whose stem is
#   a real replay, and returns non-zero if any is pending or of an unknown kind.
enumerate_expectations() {
    _ee_dir="$1"; _ee_repo="$2"; _ee_bad=0
    for _ee_f in "$_ee_dir"/*; do
        [ -f "$_ee_f" ] || continue
        _ee_b="$(basename "$_ee_f")"
        _ee_stem="${_ee_b%.*}"; _ee_ext="${_ee_b##*.}"
        [ -f "$_ee_repo/tests/replays/$_ee_stem.rpl" ] || continue
        case "$_ee_ext" in
            masked)  echo "$_ee_stem|masked|EVAL" ;;
            skip)    echo "$_ee_stem|skip|SKIP" ;;
            # self-frozen to a SINGLE-TENANT image; a merged program image
            # differs by construction, so these are never a legacy leg.
            sha1)    echo "$_ee_stem|sha1|N/A" ;;
            pending) echo "$_ee_stem|pending|NOT-EVALUATED"; _ee_bad=1 ;;
            *)       echo "$_ee_stem|$_ee_ext|UNKNOWN-KIND"; _ee_bad=1 ;;
        esac
    done
    return "$_ee_bad"
}
