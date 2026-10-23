"""tests/lib/hosttext.py — THE HOST-TEXT GUARD (#308, shared since #314, 14z-207). Imported before a tool runs: on every
host, a text-mode open() from code outside Python's own library that names no encoding, or a text write that names no
newline, is refused with a `HOST-TEXT:` line and exit 1 (no traceback: a traceback is a DIED run, never a verdict).
On Windows such an open() is cp1252 and CRLF; on the Mac and Linux it is UTF-8 and LF, so without the guard only a
Windows run sees it. It covers builtins.open, not io.open or pathlib. Users: tests/test_readme_recording.sh,
tests/test_applier_page.sh."""
import builtins, os, sys
sys.stdout.reconfigure(encoding="utf-8", newline="\n")  # its own HOST-TEXT line too: per process (docs/platform/gotchas.md)
_open = builtins.open
_lib = tuple(os.path.realpath(p) + os.sep for p in {sys.prefix, sys.base_prefix, sys.exec_prefix})
def strict_open(file, mode="r", buffering=-1, encoding=None, errors=None, newline=None, closefd=True, opener=None):
    if "b" not in mode:
        f = sys._getframe(1)
        if not os.path.realpath(f.f_code.co_filename).startswith(_lib):
            why = ("names no encoding, so its bytes are the host's (cp1252 on Windows)" if encoding is None else
                   "names no newline, so it writes the host's line ends (CRLF on Windows)"
                   if newline is None and any(c in mode for c in "wax+") else "")
            if why:
                print("HOST-TEXT: %s:%d: open(%r, %r) %s" % (f.f_code.co_filename, f.f_lineno, file, mode, why), flush=True)
                os._exit(1)
    return _open(file, mode, buffering, encoding, errors, newline, closefd, opener)
builtins.open = strict_open
