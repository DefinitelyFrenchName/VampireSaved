#!/usr/bin/env python3
"""check_qs_voice_batch.py — whole-run keyon multiset A/B for the M5
voice batch (14z-86). usage:
    check_qs_voice_batch.py <ours_sweep.txt> <native_sweep.txt> <ours_vsavjw.zip>
        [--romdir DIR]

Compares EVERYTHING each run keyed (window-free: per-id window
attribution is venue-flaky for delayed keyons) as (voice, length,
content) signatures. PASS iff: no native signature is missing from
ours, no ours signature is foreign to vs2's sample library (a
signature ours-only but whose content exists in vs2's image is a
priority-suppressed track echo — measured moving with injection
timing), and no signature's count drifts by more than 2.
"""
import hashlib, os, re, sys, zipfile
# NO HARDCODED ROMDIR (14z-94, GitHub #67). This was the maintainer's own
# absolute path, and the only tracked source file leaking one — which made the
# tool unrunnable-with-a-confusing-error for anyone else, and pinned a path
# that is itself stale in this repo's history ('Vampire Saved' predates the
# 2026-08-05 rename to 'Vampire_Saved'). Resolution order is now --romdir,
# then $ROMDIR, then a NAMED failure: guessing is what produced the papercut.
_rd = None
if '--romdir' in sys.argv:
    i = sys.argv.index('--romdir'); _rd = sys.argv[i+1]; del sys.argv[i:i+2]
elif os.environ.get('ROMDIR'):
    _rd = os.environ['ROMDIR']
if not _rd:
    sys.exit('set ROMDIR (or pass --romdir <dir>) — the reference-set '
             'directory holding vsav.zip / vsav2.zip')

zv = zipfile.ZipFile(f'{_rd}/vsav.zip')
z2 = zipfile.ZipFile(f'{_rd}/vsav2.zip')
zt = zipfile.ZipFile(sys.argv[3])
ours_img = zv.read('vm3.11m') + zv.read('vm3.12m') + zt.read('vsw.21m') + b'\x00'*0x400000
nat_img = z2.read('vs2.11m') + z2.read('vs2.12m')

def keyons(path):
    tri, regs, out = {}, {}, []
    first = None
    for line in open(path):
        m = re.match(r'== f(\d+) id', line)
        if m and first is None:
            first = int(m.group(1))
        m = re.match(r'f(\d+) w d00([012]) ([0-9a-f]+)', line)
        if not m: continue
        fr, port, val = int(m.group(1)), int(m.group(2)), int(m.group(3), 16)
        tri[port] = val
        if port == 2:
            reg = val; data = tri.get(0,0) << 8 | tri.get(1,0)
            prev = regs.get(reg); regs[reg] = data
            if reg < 0x80 and (reg & 7) == 3 and data == 0x8000:
                if first is not None and fr >= first:
                    v = reg >> 3
                    out.append((fr, v, regs.get(((v-1)&15)*8, 0),
                                regs.get(v*8+1, 0), regs.get(v*8+5, 0),
                                regs.get(v*8+2, 0)))
    return out

# PACKING LAW #3 — THE ENDPOINT IS INCLUSIVE (14z-87b; enforced here 14z-93,
# GitHub #82). The record's `end` offset is played/looped INCLUSIVE, proven
# by field width (native windows end at 0xFFFF, so no exclusive reading is
# expressible) and by the sword-plant beep: an EXCLUSIVE copy in
# build_qs_songs.py left every packed sample's last played byte holding the
# NEXT blob's first byte, audible as a ~1.8kHz impulse train to keyoff.
# build_qs_songs.py:247 was corrected to `q2[w0:w1 + 1]` then; this checker
# and audit_qs_voice_batch.py were NOT, so the one byte that caused the beep
# sat outside the audit surface — corruption confined to it passed clean.
#
# The law itself lives in tools/qs_window.py so the builder and both audit
# paths cannot drift apart again; tests/test_qs_window_law.sh is its ground
# truth, including the terminal-byte-corruption control.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from qs_window import try_window, length as _qs_len       # noqa: E402


def _win(img, bb, s, e):
    """The audible window for a QSound record, endpoint INCLUSIVE."""
    return try_window(img, (bb << 16) | s, (bb << 16) | e)


# STABLE DIGESTS (14z-96): the content field used to be Python's built-in
# hash(), which is RANDOMIZED PER PROCESS (PYTHONHASHSEED) — fine for the
# in-run multiset compare, but the printed values looked like durable
# identifiers and were not: two runs of the SAME builds print different
# numbers, which reads as "the content moved" when nothing did. sha1-derived
# digests compare identically in-run and stay meaningful across runs.
def _digest(b):
    return hashlib.sha1(b).hexdigest()[:16]


def sig(img, k, bank_or=0):
    fr, v, b, s, e, p = k
    b &= 0xFF
    n = _qs_len(s, e)                  # INCLUSIVE length (packing law #3)
    for bb in ((b, b | 0x80) if bank_or else (b,)):
        w = _win(img, bb, s, e)
        if any(w):
            return (v, n, _digest(bytes(w)))
    return (v, n, _digest(b''))

from collections import Counter
co, co_blobs = Counter(), {}
for k in keyons(sys.argv[1]):
    s = sig(ours_img, k, 1)
    co[s] += 1
    fr, v, b, st, e, p = k
    for bb in ((b & 0xFF), (b & 0xFF) | 0x80):
        w = _win(ours_img, bb, st, e)   # INCLUSIVE, same law as sig()
        if any(w):
            co_blobs[s] = bytes(w); break
cn, cn_blobs = Counter(), {}
for k in keyons(sys.argv[2]):
    s = sig(nat_img, k)
    cn[s] += 1
    fr, v, b, st, e, p = k
    w = _win(nat_img, b & 0xFF, st, e)
    if any(w):
        cn_blobs[s] = bytes(w)
foreign = []
echo = 0
for s in co:
    if s in cn:
        continue
    # a signature native's run never keyed is acceptable ONLY if its
    # content exists in vs2's own sample library (a priority-suppressed
    # track echo — measured moving with injection timing, 14z-86);
    # anything vs2 could not play at all stays FOREIGN
    blob = co_blobs.get(s)
    if blob is not None and blob in nat_img:
        echo += 1
        continue
    foreign.append(s)
missing = [s for s in cn if s not in co]

# THE FROZEN SOURCE DIFFERENCE (GitHub #93, maintainer-ruled 2026-08-19).
# Bank 108's trap-family sample (vsavj record #506, keyed by 12 vanilla ids:
# 0x118/0x119, 0x198/0x199, 0x27e/0x29b + their +0x300 aliases) differs
# between the two GAMES' original sample ROMs at exactly its INCLUSIVE
# endpoint: vsav 0x6C5000 = 0xFF, vsav2 = 0x00. The byte is Capcom's own,
# vanilla vsav has always played it, and the maintainer's ear-check of the
# restored chirp (14z-85g) passed WITH it — so the expectation is FROZEN
# rather than the byte patched (patching would deviate LEGACY audio from
# vanilla for all six base ids; the superset invariant outranks tenant
# tail-byte exactness). THE FREEZE IS NOT A WINDOW: the exception below
# byte-verifies, on every run, that the divergence is EXACTLY the known
# shape — one foreign + one missing, same channel, length 20481, prefixes
# identical, endpoints exactly (0xFF, 0x00). Anything else stays red.
# QS_BATCH_STRICT=1 disarms the exception for anyone wanting bit-exactness
# (the audit runs that as a must-fire control).
# UPGRADE PATH if the chirp tail ever becomes audible in the field
# (option C on the issue, maintainer-recorded): author a tenant-only copy
# of the 20,481 bytes with the 0x00 endpoint into vsw.21m and remap ONLY
# the tenant's 0x199 references to it — native-exact for the tenant,
# vanilla untouched for legacy.
if not os.environ.get('QS_BATCH_STRICT') and len(foreign) == 1 \
        and len(missing) == 1:
    fs, ms = foreign[0], missing[0]
    bo, bn = co_blobs.get(fs), cn_blobs.get(ms)
    if (fs[0] == ms[0] and fs[1] == ms[1] == 20481
            and bo is not None and bn is not None
            and len(bo) == len(bn) == 20481
            and bo[:-1] == bn[:-1]
            and bo[-1] == 0xFF and bn[-1] == 0x00):
        print('  known: (v%d, 20481) ours %s / native %s — the bank-108 '
              'inclusive-endpoint source difference (vsav 0xFF / vsav2 '
              '0x00; GitHub #93, frozen by maintainer ruling 2026-08-19; '
              'QS_BATCH_STRICT=1 re-arms)' % (fs[0], fs[2], ms[2]))
        foreign, missing = [], []

drift = {s: (co[s], cn[s]) for s in cn if s in co and abs(co[s]-cn[s]) > 2}
print('whole-run signatures: ours %d distinct / native %d distinct' %
      (len(co), len(cn)))
print('suppressed-track echoes (content in vs2 library):', echo)
print('foreign (ours-only):', len(foreign), ' missing (native-only):',
      len(missing), ' count-drift>2:', len(drift))
for s in foreign[:5]: print('  foreign', s)
for s in missing[:5]: print('  missing', s)
for s, c in list(drift.items())[:5]: print('  drift', s, c)
sys.exit(1 if (foreign or missing or drift) else 0)
