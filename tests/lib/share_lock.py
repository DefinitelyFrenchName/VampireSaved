#!/usr/bin/env python3
"""share_lock.py — THE HOST CLAIM'S LOCK: an OS file lock (fcntl.flock) held for a shell's lifetime (#370, 14z-225;
maintainer-ruled 2026-11-09 "Kernel lock (Recommended)", after five rule-checker rounds each found a hole in a
hand-written mkdir lock: rule-checker runs 2026-11-09-1751 to -1755).

    share_lock.py hold <lock file> <wait seconds> <owner pid> <who> <ready file>

Opens (creating) the lock file and takes an exclusive flock, retrying without blocking until <wait seconds> have passed.
  HELD:    writes "<owner pid> <who>" into the lock file (for the messages of whoever waits on it), then
           "HELD <waited>" into <ready file>, and stays alive while <owner pid> is alive (checked every 0.2 s); when the
           owner is gone it exits, and the kernel releases the lock with its last descriptor. A SIGTERM ends it the same
           way (tests/lib/shares.sh vs_shares_release sends one).
  REFUSED: writes "REFUSED <waited> <the lock file's owner line>" into <ready file> and exits 3.
The lock cannot outlive its holder process: a crash, a SIGKILL or a power loss frees it, so there is no stale lock and
no owner-less lock to recover — the class the mkdir lock kept failing on. The owner line in the file is information
only; it never decides who holds the lock.
"""
import fcntl, os, signal, sys, time


def alive(pid):
    try:
        os.kill(pid, 0)
        return True
    except ProcessLookupError:
        return False
    except PermissionError:
        return True


def main(argv):
    if len(argv) != 7 or argv[1] != "hold":
        print(__doc__, file=sys.stderr)
        return 2
    path, wait, owner, who, ready = argv[2], int(argv[3]), int(argv[4]), argv[5], argv[6]
    fd = os.open(path, os.O_RDWR | os.O_CREAT, 0o644)
    t0 = time.monotonic()
    while True:
        try:
            fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)   # SHARE-LOCK-TAKE
            break
        except BlockingIOError:
            waited = int(time.monotonic() - t0)
            if waited >= wait:
                try:
                    line = os.pread(fd, 200, 0).decode("utf-8", "replace").strip() or "?"
                except OSError:
                    line = "?"
                with open(ready + ".tmp", "w") as f:
                    f.write("REFUSED %d %s\n" % (waited, line))
                os.replace(ready + ".tmp", ready)
                return 3
            time.sleep(0.2)
    waited = int(time.monotonic() - t0)
    os.ftruncate(fd, 0)
    os.pwrite(fd, ("%d %s\n" % (owner, who)).encode(), 0)
    with open(ready + ".tmp", "w") as f:
        f.write("HELD %d\n" % waited)
    os.replace(ready + ".tmp", ready)
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
    signal.signal(signal.SIGHUP, signal.SIG_IGN)
    while alive(owner):   # SHARE-LOCK-OWNER: held exactly as long as the claiming shell lives
        time.sleep(0.2)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
