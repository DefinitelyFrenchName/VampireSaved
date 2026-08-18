#!/usr/bin/env python3
"""qs_ledger.py — resolve the QSound voice ledger BOUND to a given romset.

Why this exists (14z-94, GitHub #89). The QSound audits sweep a list of voice
ids. Those ids come from build/manifest/qs_songs.toml by way of
build_qs_songs.py's ledger — NOT from the romset. So an audit handed a build
directory has no way to know, from the ROM alone, which voices that build
actually authored.

What the audits did instead: attempt `build_qs_songs.py --dry-run` (an option
that has never existed, so argparse exited 2), suppress that with
`>/dev/null 2>&1 || true`, and then fall back to rebuilding a ledger from the
canonical build/wide0 overlay. The result is a sweep of TODAY'S manifest ids
run against a possibly older supplied artifact, reported as a verdict on that
artifact. Voices the supplied build really authored are never exercised, and
the green result is attributed to it anyway.

The rule enforced here:

  * a ledger is emitted with every QSound build, next to the romset, and
    carries a fingerprint of the members build_qs_songs.py writes;
  * an audit recomputes that fingerprint from the romset it was handed and
    refuses on mismatch, BEFORE any emulator runs;
  * a supplied build with no ledger is REFUSED, not filled in from another
    overlay.

QS_LEDGER_UNBOUND=1 overrides, deliberately loudly — same idiom as
freeze_masked_basis.sh's BASIS_FORCE_MASK. It exists because builds predating
this change carry no ledger; what it must never do is stay quiet about the
fact that the id inventory is then unbound from the artifact.

Usage: qs_ledger.py <vsavjw.zip> [--ledger PATH] [--print ours|native|both]
Exit 0 and print the requested id list; nonzero with an explanation otherwise.
"""
import argparse
import hashlib
import json
import os
import sys
import zipfile

Z01, Z02, EXT = "vsw.z01", "vsw.z02", "vsw.21m"


def sha1(b):
    return hashlib.sha1(b).hexdigest()


def fingerprint(zpath, members):
    """Recompute the ledger fingerprint from a romset on disk."""
    z = zipfile.ZipFile(zpath)
    names = z.namelist()
    missing = [m for m in members if m not in names]
    if missing:
        raise SystemExit(
            f"{zpath}: ledger names member(s) {missing} that the romset does "
            f"not contain — the ledger does not describe this artifact")
    return sha1(b"".join(z.read(m) for m in members))


def resolve(zpath, ledger_path=None):
    """Return the ledger bound to <zpath>, or exit with why not."""
    if ledger_path is None:
        ledger_path = zpath + ".ledger.json"
    unbound = os.environ.get("QS_LEDGER_UNBOUND", "0") == "1"

    if not os.path.exists(ledger_path):
        raise SystemExit(
            f"REFUSING: no voice ledger for {zpath}\n"
            f"  looked for: {ledger_path}\n"
            f"\n"
            f"  The voice ids an audit sweeps come from the MANIFEST, not from\n"
            f"  the romset, and they CANNOT be re-derived from a finished\n"
            f"  build (this builder's spans are already filled). Deriving them\n"
            f"  from build/wide0 instead would sweep today's ids against this\n"
            f"  artifact and report the result as a verdict on it (GitHub #89).\n"
            f"\n"
            f"  Rebuild so the ledger is emitted alongside the romset — it\n"
            f"  is written by default now. THAT IS THE ONLY ROUTE for a build\n"
            f"  with no ledger at all.\n"
            f"\n"
            f"  QS_LEDGER_UNBOUND=1 DOES NOT HELP HERE, and this message used\n"
            f"  to offer it (corrected 14z-95). With no ledger file there are\n"
            f"  no ids to accept — honouring the override would mean deriving\n"
            f"  them from build/wide0, which is the exact substitution #89\n"
            f"  exists to prevent. The override applies only to a ledger that\n"
            f"  EXISTS but predates the artifact fingerprint.\n"
            f"  (An error message naming a switch the code ignores is the #89\n"
            f"  shape itself — a phantom --dry-run — so it is fixed as text,\n"
            f"  not by making the switch work.)")

    with open(ledger_path) as f:
        led = json.load(f)

    art = led.get("artifact")
    if art is None:
        if not unbound:
            raise SystemExit(
                f"REFUSING: {ledger_path} carries no artifact fingerprint.\n"
                f"  It predates GitHub #89, so nothing ties it to {zpath}.\n"
                f"  Rebuild, or set QS_LEDGER_UNBOUND=1 to accept an id list\n"
                f"  that is not bound to the artifact under test.")
        print(f"  WARNING: {ledger_path} has no fingerprint; binding NOT checked",
              file=sys.stderr)
        return led, "unbound-legacy"

    got = fingerprint(zpath, art["members"])
    if got != art["fingerprint"]:
        # Always fatal. This is not "no evidence" — it is evidence of a
        # MISMATCH, so QS_LEDGER_UNBOUND does not override it.
        per = []
        z = zipfile.ZipFile(zpath)
        for m in art["members"]:
            want = art.get("member_sha1", {}).get(m, "?")
            have = sha1(z.read(m))
            per.append(f"    {m}: ledger {want[:12]}  romset {have[:12]}"
                       + ("" if want == have else "   <-- differs"))
        raise SystemExit(
            f"REFUSING: {ledger_path} does not describe {zpath}\n"
            f"  ledger fingerprint: {art['fingerprint']}\n"
            f"  romset fingerprint: {got}\n" + "\n".join(per) + "\n"
            f"\n"
            f"  The QSound members this ledger was written for are not the\n"
            f"  ones in this romset, so its voice ids are another build's.\n"
            f"  Auditing on them would exercise voices this artifact may not\n"
            f"  author, and miss ones it does.")
    return led, got


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("zip")
    ap.add_argument("--ledger")
    ap.add_argument("--print", dest="what", default="both",
                    choices=("ours", "native", "both", "none"))
    a = ap.parse_args()
    led, fp = resolve(a.zip, a.ledger)
    ours = ",".join("%x" % v["id"] for v in led["voices"])
    native = ",".join("%x" % v["vs2_id"] for v in led["voices"])
    if a.what == "ours":
        print(ours)
    elif a.what == "native":
        print(native)
    elif a.what == "both":
        print(ours)
        print(native)
    print(f"  ledger bound to artifact ({len(led['voices'])} voices, "
          f"fingerprint {fp[:12]})", file=sys.stderr)


if __name__ == "__main__":
    main()
