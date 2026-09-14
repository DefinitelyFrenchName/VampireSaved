# os_metadata.sh — THE ONE DEFINITION of a file manager's folder metadata in a
# release tree: files written when a person BROWSES a directory, which are never
# content, never shipped and never counted (maintainer-ruled 2026-09-14, "they
# must be ignored"). Today that is macOS Finder's `.DS_Store` and nothing else; a
# second name is one more alternative in VS_OS_METADATA_RE.
#
# WHY (14z-153). Finder wrote `release/merged-m18/.DS_Store` two hours after the
# M18 upload and the strict static tier went 149/0/1 on it — the gate measured the
# host. And the uploader listed a platform directory with `find -type f`, which
# sees dotfiles, so one INSIDE a platform directory would have been zipped into a
# published asset.
#
# WHO SOURCES IT: the three release listings that can see a dotfile, each a `find`
# piped through vs_drop_os_metadata — tools/upload_release_assets.sh (what goes in
# an asset), tests/test_release_asset_shape.sh §5 (what must reach one) and
# tests/test_release_roundtrip.sh §4 (the ruled inventory). A shell glob and `ls`
# already skip dotfiles. Ground truth: tests/test_release_os_metadata.sh.
#
#   vs_drop_os_metadata   a path-list filter on stdin: drops every path whose BASENAME
#                         is folder metadata, keeps everything else (look-alikes such as
#                         `x.DS_Store` or `.DS_Store.bak` included); always returns 0
VS_OS_METADATA_RE='(^|/)\.DS_Store$'
vs_drop_os_metadata() { grep -vE "$VS_OS_METADATA_RE" || true; }
