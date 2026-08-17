# shadow_tools.sh — a WRITABLE copy of a tool, inside a throwaway repo root.
# Sourced, not executed. (14z-94, GitHub #81.)
#
# WHY. Several verdict controls prove a substitution site is live by
# PERTURBING the generator and re-running it. They did that by editing
# tracked `tools/gen_donovan_patch.py` in place and restoring from a snapshot
# on an exit trap. An exit trap covers an ordinary Ctrl-C and nothing else:
#
#   * two of these gates in two terminals (or two CI workers on one checkout)
#     each snapshot a different transient state and restore over each other;
#   * SIGKILL, a crashed shell, or a machine losing power leaves the
#     generator perturbed — and it is the file every build runs;
#   * a legitimate edit saved DURING a long control suite is silently
#     overwritten by the restore.
#
# None of those need anything unusual to happen. Test instrumentation should
# not be able to damage tracked source at all, so it now edits a copy.
#
# WHY A SHADOW ROOT AND NOT JUST A COPY OF THE FILE. gen_donovan_patch.py
# resolves the repository from its own location —
# `Path(__file__).resolve().parent.parent` — to reach build/manifest/overlay
# and friends, and inserts its own directory on sys.path to import
# cps2_decrypt and _minitoml. A copy in /tmp would therefore find neither the
# manifests nor its siblings. So the shadow is `<work>/shadow/tools/<tool>`
# (a real copy) beside SYMLINKS to every other tool, under a root whose
# build/, tests/ and docs/ are symlinks to the real ones. `parent.parent`
# then lands on the shadow root and every repo-relative read resolves through
# the links to the genuine files.
#
# The copy is what gets perturbed; the real tree is never written.
#
# Usage:
#   . "$REPO/tests/lib/shadow_tools.sh"
#   GEN="$(shadow_tool "$WORK" gen_donovan_patch.py)"
#   python3 "$GEN" ...            # run it
#   ... perturb "$GEN" ...        # edit it freely; nothing tracked is touched

# shadow_tool <workdir> <tool-basename> -> prints the path of the writable copy
shadow_tool() {
    _st_work="$1"; _st_tool="$2"
    _st_repo="${REPO:?shadow_tool needs REPO set}"
    _st_root="$_st_work/shadow"
    if [ ! -d "$_st_root/tools" ]; then
        mkdir -p "$_st_root/tools"
        for _st_f in "$_st_repo"/tools/*; do
            [ -e "$_st_f" ] || continue
            ln -sf "$_st_f" "$_st_root/tools/$(basename "$_st_f")"
        done
        # Repo-relative reads (build/manifest/...) resolve through these.
        for _st_d in build tests docs; do
            [ -e "$_st_repo/$_st_d" ] && ln -sfn "$_st_repo/$_st_d" "$_st_root/$_st_d"
        done
    fi
    rm -f "$_st_root/tools/$_st_tool"
    cp "$_st_repo/tools/$_st_tool" "$_st_root/tools/$_st_tool"
    printf '%s\n' "$_st_root/tools/$_st_tool"
}

# shadow_restore <workdir> <tool-basename> — undo a perturbation by re-copying
# the pristine tool over the shadow. (The real file was never touched.)
shadow_restore() {
    cp "${REPO:?}/tools/$2" "$1/shadow/tools/$2"
}
