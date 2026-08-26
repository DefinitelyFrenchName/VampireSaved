#!/bin/sh
# test_mister_mra_map.sh — the MiSTer download image is EXACTLY the placement
# map, the trim that makes it downloadable is real, and the stock reference
# leg did not move. (14z-107 (5), MiSTer slice D0;
# docs/project/mister_map.md §3 is the design this gate defends.)
#
# WHY IT EXISTS. `docs/project/mister_map.md` derives the WIDE `.rom` layout
# on paper and `tests/audit_mister_map_fit.sh` freezes the arithmetic. This
# gate is the other half: it runs the REAL generator over the REAL romset and
# asserts the bytes agree with the paper. The two were derived independently,
# so a disagreement means one of them is wrong — which is the finding.
#
# WHAT IT LOCKS
#  1. The stock `vsavj` MRA emitted by `cores/cps2w` is still BYTE-IDENTICAL
#     to `cores/cps2`'s except `<rbf>` — the reference leg of the emulator
#     superset invariant, on FPGA. And `cores/cps2` emits NO WIDE MRA at all:
#     the WIDE machine entry is tagged `sourcefile="capcom/cps2w.cpp"`, which
#     the reference core's `sourcefile=["cps2.cpp"]` does not match, so the
#     profile is gated BY CONSTRUCTION rather than by a filter.
#  2. The WIDE MRA's region table is the map's, to the byte: region starts,
#     total length, and the four 1 KiB header words 6144 / 6400 / 15552 /
#     64704. Every region start is 1 KiB-aligned — which is the only reason
#     the header words are correct at all, because the Go generator's `pos`
#     counts the 20-byte key region while the RTL's `bulk_addr` does not
#     (`FULL_HEADER = 26'd64`, jtcps1_prom_we.v:58).
#  3. With the WIDE romset present: the produced `.rom` is 66,265,152 B, its
#     header carries those four words, and EVERY region is byte-for-byte what
#     the zips hold — including that the trimmed QSound region is a PURE
#     TRUNCATION of the untrimmed one (mister_map.md §9 open question Q2,
#     answered here rather than assumed).
#  4. The catalogue entry names the CURRENT build's CRCs. jtframe locates zip
#     members by CRC32 and by NOTHING ELSE (mra2rom.go:163-172); FBNeo and
#     MAME resolve by name and only warn, which is why the WIDE members carry
#     sentinel hashes there. A romset rebuild that moves a CRC must move the
#     fork's entry, and this is what says so.
#  5. The stock `vsavj.rom` built from the pristine sets is BIT-IDENTICAL to
#     the 14z-106 measurement — 46,407,744 B, sha1 `f9dc2987…`. Size alone
#     would not notice a remapped region.
#  6. THE PROFILE BIT (slice D1, 14z-107 (6)). Header byte 41 is 0xFE in the
#     WIDE MRA and 0xFF — the generator's own fill — in every stock one, in
#     the MRA and in the `.rom` alike. This is the MiSTer half of "profile-
#     gated so stock vsavj is untouched BY CONSTRUCTION": the RTL reads that
#     byte at download time (cores/cps2w/hdl/jtcps2w_profile.v), so a stock
#     MRA on jtcps2w.rbf is a stock machine. Control A doubles as this check's
#     own control — it disables the setname="vsavjw" match, and the bit must
#     go back to 0xFF.
#
# MUST-FIRE CONTROLS (a layout check with no control asserts nothing)
#  A. THE UNTRIMMED MAPPING MUST BE REJECTED. Put the QSound extension back
#     in the `qsound` region whole — the way MAME declares it — and the image
#     must exceed the 26-bit `ioctl_addr` ceiling AND need a firmware start
#     word of 71,936 KiB, which does not fit the 16-bit header field. Note
#     what the generator does with it: it writes the WRAPPED low 16 bits and
#     says nothing. The trim is mandatory, and its absence is SILENT.
#  B. PERTURB THE TRIM BY 1 KiB. `length=0x0F0000` -> `0x0F0400` and the
#     frozen region table must fail. Without this, check 2 could be passing
#     on a table it recomputes from the same source it is checking.
#
# Cost: five `jtframe mra` runs, ~30 s. Needs the emu/jtcores submodule, `go`
# and $ROMDIR; the `.rom` checks additionally need a built WIDE romset
# (build/m3b_merged13 by default, MRA_MAP_BUILD to override). Everything is
# written to a temp dir OUTSIDE the repo — `.rom` files are ROM content
# (CLAUDE.md rule 7).
#
# Usage: ROMDIR=... tests/test_mister_mra_map.sh
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
BUILD="${MRA_MAP_BUILD:-build/m3b_merged14}"  # re-pointed 14z-110

[ -f "emu/jtcores/.gitmodules" ] || { echo "SKIP: emu/jtcores not initialised (tools/setup_jtcores.sh)"; exit 0; }
[ -n "${ROMDIR:-}" ] || { echo "SKIP: ROMDIR not set"; exit 0; }
[ -f "$ROMDIR/vsavj.zip" ] || { echo "SKIP: no $ROMDIR/vsavj.zip"; exit 0; }
command -v go >/dev/null 2>&1 || {
    JTF="${JTSIM_SCRATCH:-${TMPDIR:-/tmp}/vampire-saved-jtsim}/modules/jtframe/src/jtframe/jtframe"
    [ -x "$JTF" ] || { echo "SKIP: no go toolchain and no prebuilt jtframe"; exit 0; }; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/mister_mra_map.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT INT TERM
MRA="$REPO/tools/mister_mra.sh"
SRC="$REPO/emu/jtcores"

echo "== generating MRAs (ROM-free) for both cores =="
"$MRA" --core cps2  --no-rom --quiet --out "$WORK/stockcore" || exit 1
"$MRA" --core cps2w --no-rom --quiet --out "$WORK/widecore"  || exit 1

echo "== control A: the UNTRIMMED mapping, as MAME declares it =="
# Both halves of the trim are undone: the extension member moves back into
# `qsound` and `vsw.22m` joins it — exactly ROM_START(vsavjw) — and the
# `qsoundw` row stops matching `vsavjw`, so the byte window is not emitted.
# (Only the first half is not enough: `parse_parts` does not consult the
# machine's file list at all, so the window would still be placed.) The
# resulting image is then the map's own §3 "mapped verbatim" table, which this
# control therefore also cross-checks through the real generator.
sed 's/setname="vsavjw"/setname="__no_such_set__"/' \
    "$SRC/cores/cps2w/cfg/mame2mra.toml" > "$WORK/untrimmed.toml"
cmp -s "$SRC/cores/cps2w/cfg/mame2mra.toml" "$WORK/untrimmed.toml" && {
    echo "FAIL: control A could not disable the qsoundw row"; exit 1; }
python3 - "$SRC/doc/mame.xml" "$WORK/untrimmed.xml" <<'PY'
import re, sys
src, dst = sys.argv[1], sys.argv[2]
t = open(src, encoding="utf-8", errors="replace").read()
m = re.search(r'(<rom name="vsw\.21m"[^>]*region=")qsoundw("[^>]*offset=")0("/>)', t)
if not m:
    sys.exit("control A: no vsw.21m qsoundw row to un-trim")
row = m.group(1) + "qsound" + m.group(2) + "800000" + m.group(3)
row += '\n\t\t' + row.replace("vsw.21m", "vsw.22m").replace('offset="800000"',
                                                            'offset="c00000"')
open(dst, "w", encoding="utf-8").write(t[:m.start()] + row + t[m.end():])
PY
[ -f "$WORK/untrimmed.xml" ] || exit 1
"$MRA" --core cps2w --no-rom --quiet --xml "$WORK/untrimmed.xml" \
    --toml "$WORK/untrimmed.toml" --out "$WORK/untrimmed" || exit 1

echo "== control B: the trim perturbed by 1 KiB =="
sed 's/length=0x0F0000/length=0x0F0400/' \
    "$SRC/cores/cps2w/cfg/mame2mra.toml" > "$WORK/perturbed.toml"
cmp -s "$SRC/cores/cps2w/cfg/mame2mra.toml" "$WORK/perturbed.toml" && {
    echo "FAIL: control B did not perturb anything (the length row moved?)"; exit 1; }
"$MRA" --core cps2w --no-rom --quiet --toml "$WORK/perturbed.toml" --out "$WORK/perturbed" || exit 1

ROMRUNS=0
if [ -f "$BUILD/rompath/vsavjw.zip" ]; then
    echo "== building the real .rom images =="
    "$MRA" --core cps2w --wide "$BUILD" --quiet --out "$WORK/widerom" || exit 1
    "$MRA" --core cps2w             --quiet --out "$WORK/stockrom" || exit 1
    ROMRUNS=1
else
    echo "note: no $BUILD/rompath/vsavjw.zip — the .rom checks are skipped"
fi

python3 - "$WORK" "$REPO" "$BUILD" "$ROMRUNS" <<'PY'
import hashlib, os, re, subprocess, sys, zipfile

WORK, REPO, BUILD, ROMRUNS = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4] == "1"
errs = []
def bad(m):
    print("FAIL:", m); errs.append(m)
def ok(m):
    print("  ok", m)

STOCK = "Vampire Savior The Lord of Vampire (Japan 970519).mra"
WIDE  = "Vampire Savior The Lord of Vampire (Japan 970519, CPS-2 WIDE v1).mra"

def find(root, name):
    for d, _, fs in os.walk(root):
        if name in fs:
            return os.path.join(d, name)
    return None

# ── 1. the stock leg: byte-identical except <rbf>, and cps2 has no WIDE MRA ──
a, b = find(WORK + "/stockcore", STOCK), find(WORK + "/widecore", STOCK)
if not a or not b:
    bad("the stock vsavj MRA was not emitted by both cores")
else:
    la = open(a).read().replace("<rbf>jtcps2</rbf>", "<rbf>@@</rbf>")
    lb = open(b).read().replace("<rbf>jtcps2w</rbf>", "<rbf>@@</rbf>")
    if la == lb:
        ok("stock vsavj MRA from cps2w == cps2's, except <rbf> "
           "(the FPGA reference leg)")
    else:
        import difflib
        bad("the stock vsavj MRA is NOT a twin any more:")
        for l in list(difflib.unified_diff(la.split("\n"), lb.split("\n"),
                                           "cps2", "cps2w", lineterm=""))[:40]:
            print("      " + l)
if find(WORK + "/stockcore", WIDE):
    bad("cores/cps2 emitted a WIDE MRA — the sourcefile gate is not gating")
else:
    ok("cores/cps2 emits no WIDE MRA (sourcefile=capcom/cps2w.cpp is unseen "
       "by sourcefile=[\"cps2.cpp\"])")
w = find(WORK + "/widecore", WIDE)
if not w:
    bad("cores/cps2w did not emit the WIDE MRA at all")
    print("\nFAIL: MiSTer MRA map"); sys.exit(1)
ok("cores/cps2w emits the WIDE MRA")

# ── 2. the region table, frozen against docs/project/mister_map.md §3 ───────
# `pos` counts the 20-byte key; bulk_addr (what the RTL sees) is pos - 0x14.
MAP = [("key", 0x0), ("maincpu", 0x14), ("audiocpu", 0x600014),
       ("qsound", 0x640014), ("qsoundw", 0xE40014), ("gfx", 0xF30014),
       ("firmware", 0x3F30014)]
TOTAL = 0x3F32014                    # body; the .rom adds the 44-byte header
HDR = {"audiocpu": 6144, "qsound": 6400, "gfx": 15552, "firmware": 64704}
ROM_SIZE = 66265152
KEY_LEN = 0x14

def region_table(path):
    t = open(path).read()
    starts = {r: int(s, 16) for r, s in
              re.findall(r"<!-- (\w+) - starts at 0x([0-9A-F]+)", t)}
    m = re.search(r"<!-- Total 0x([0-9A-F]+) bytes", t)
    return starts, (int(m.group(1), 16) if m else None)

def header_words(path):
    t = open(path).read()
    m = re.search(r'asm_md5="[0-9a-f]*">\s*<part>(.*?)</part>', t, re.S) \
        or re.search(r'md5="None"[^>]*>\s*<part>(.*?)</part>', t, re.S)
    if not m:
        return None
    by = bytes(int(x, 16) for x in m.group(1).split())
    # bits=10, reverse=true: each 16-bit word is stored byte-swapped
    return {n: by[2 * i] | (by[2 * i + 1] << 8)
            for i, n in enumerate(("audiocpu", "qsound", "gfx", "firmware"))}

PROFILE_BYTE = 41
def header_bytes(path):
    t = open(path).read()
    m = re.search(r'asm_md5="[0-9a-f]*">\s*<part>(.*?)</part>', t, re.S) \
        or re.search(r'md5="None"[^>]*>\s*<part>(.*?)</part>', t, re.S)
    return None if not m else bytes(int(x, 16) for x in m.group(1).split())

def check_table(path):
    starts, total = region_table(path)
    bad_here = []
    for reg, want in MAP:
        got = starts.get(reg)
        if got != want:
            bad_here.append("%s starts at %s, map says %#x" %
                            (reg, hex(got) if got is not None else "(absent)", want))
        elif reg != "key" and (got - KEY_LEN) % 1024:
            bad_here.append("%s bulk_addr %#x is not 1 KiB-aligned — the "
                            "header word is then off by a block" % (got - KEY_LEN))
    if total != TOTAL:
        bad_here.append("total %s, map says %#x" %
                        (hex(total) if total else "(absent)", TOTAL))
    words = header_words(path)
    if words is None:
        bad_here.append("no header part in the MRA")
    else:
        for n, want in HDR.items():
            if words[n] != want:
                bad_here.append("header word %s = %d KiB, map says %d"
                                % (n, words[n], want))
    return bad_here

problems = check_table(w)
if problems:
    for msg in problems:
        bad("WIDE MRA: " + msg)
else:
    ok("WIDE region table == mister_map.md §3 (starts, total %#x, header "
       "words %s), every region 1 KiB-aligned" % (TOTAL, list(HDR.values())))

# ── 2b. the profile bit, in the MRAs ───────────────────────────────────────
for label, path, want in (("stock vsavj (from cps2)",  a, 0xFF),
                          ("stock vsavj (from cps2w)", b, 0xFF),
                          ("the WIDE set",             w, 0xFE)):
    if not path:
        continue
    hb = header_bytes(path)
    if hb is None or len(hb) <= PROFILE_BYTE:
        bad("%s: no readable header in the MRA" % label)
    elif hb[PROFILE_BYTE] != want:
        bad("%s: header byte %d is 0x%02X, want 0x%02X — the CPS-2 WIDE "
            "profile bit is wrong (0xFF = off, 0xFE = on)"
            % (label, PROFILE_BYTE, hb[PROFILE_BYTE], want))
    else:
        ok("%-26s header byte %d = 0x%02X (profile %s)"
           % (label, PROFILE_BYTE, want, "OFF" if want == 0xFF else "ON"))

# ── 3. control A: the untrimmed mapping must be refused ────────────────────
u = find(WORK + "/untrimmed", WIDE)
if not u:
    bad("control A produced no MRA")
else:
    starts, total = region_table(u)
    size = 44 + total
    fw = starts["firmware"] - KEY_LEN
    words = header_words(u)
    if size <= (1 << 26):
        bad("control A did not fire: the untrimmed image is %d B, inside the "
            "26-bit ioctl_addr ceiling" % size)
    elif (fw >> 10) < (1 << 16):
        bad("control A half-fired: firmware start %d KiB still fits 16 bits"
            % (fw >> 10))
    else:
        ok("control A fired: untrimmed = %.3f MB (> 64 MB) and needs "
           "qsnd_start %d KiB (> 65535)" % (size / 2 ** 20, fw >> 10))
        if words["firmware"] == (fw >> 10) & 0xFFFF and words["firmware"] != fw >> 10:
            ok("...and the generator SILENTLY WRITES THE WRAPPED WORD %d — "
               "which is why the trim is a gate, not a preference"
               % words["firmware"])
    # control A also un-matches the setname="vsavjw" HEADER row, so the
    # profile bit must revert to the fill. That makes it the profile check's
    # own control: if byte 41 were 0xFE here, the row would not be gated by
    # setname at all and every stock MRA would be carrying it.
    hb = header_bytes(u)
    if hb is None or len(hb) <= PROFILE_BYTE:
        bad("control A: no readable header")
    elif hb[PROFILE_BYTE] != 0xFF:
        bad("control A: header byte %d is 0x%02X with setname un-matched — "
            "the profile row is NOT setname-gated" % (PROFILE_BYTE, hb[PROFILE_BYTE]))
    else:
        ok("control A doubles as the profile control: un-match the setname and "
           "byte %d returns to the 0xFF fill" % PROFILE_BYTE)
    # mister_map.md §3 "Mapped verbatim": firmware at bulk_addr 73,662,464
    # and 70.26 MB total. Derived on paper there; reproduced here.
    if fw != 73662464 or size != 73670720:
        bad("the untrimmed image is %d B with firmware at %d — mister_map.md "
            "§3 derives 73670720 B and 73662464. One of the two is wrong."
            % (size, fw))
    else:
        ok("untrimmed layout reproduces mister_map.md §3 exactly "
           "(73,670,720 B; firmware at 73,662,464 = 71,936 KiB)")

# ── 4. control B: 1 KiB of perturbation must break the frozen table ────────
pert = find(WORK + "/perturbed", WIDE)
if not pert:
    bad("control B produced no MRA")
elif not check_table(pert):
    bad("control B did not fire: the region table still matched after the "
        "trim length moved by 1 KiB")
else:
    ok("control B fired: +0x400 on the trim breaks the frozen table")

# ── 5. the real .rom, byte for byte ────────────────────────────────────────
if ROMRUNS:
    rom = os.path.join(WORK, "widerom", "vsavjw.rom")
    if not os.path.exists(rom):
        bad("no vsavjw.rom was produced from %s — a CRC in the fork's "
            "catalogue or TOML does not match the built romset" % BUILD)
    else:
        data = open(rom, "rb").read()
        if len(data) != ROM_SIZE:
            bad(".rom is %d B, map says %d" % (len(data), ROM_SIZE))
        else:
            ok(".rom size %d B (%.3f MB), %d B under the 64 MB ioctl_addr "
               "ceiling" % (len(data), len(data) / 2 ** 20, (1 << 26) - len(data)))
        words = {n: data[2 * i] | (data[2 * i + 1] << 8)
                 for i, n in enumerate(("audiocpu", "qsound", "gfx", "firmware"))}
        if words != HDR:
            bad(".rom header words %s, map says %s" % (words, HDR))
        else:
            ok(".rom header words %s" % words)
        if data[PROFILE_BYTE] != 0xFE:
            bad("the WIDE .rom's header byte %d is 0x%02X, want 0xFE — the "
                "core would download this image and run it as STOCK"
                % (PROFILE_BYTE, data[PROFILE_BYTE]))
        else:
            ok("the WIDE .rom carries the profile bit: byte %d = 0xFE"
               % PROFILE_BYTE)

        rp = os.path.join(REPO, BUILD, "rompath")
        zw = zipfile.ZipFile(os.path.join(rp, "vsavjw.zip"))
        zp = zipfile.ZipFile(os.path.join(rp, "vsav.zip"))
        zq = zipfile.ZipFile(os.path.join(os.environ["ROMDIR"], "qsound_hle.zip"))
        for z, n in ((zw, "vsavjw.zip"), (zp, "vsav.zip")):
            print("  read %s sha1 %s" % (n, hashlib.sha1(
                open(os.path.join(rp, n), "rb").read()).hexdigest()))

        def rd(n):
            try:
                return zw.read(n)
            except KeyError:
                return zp.read(n)

        def swap(b):                       # <interleave output=16> map="12"
            a = bytearray(b); a[0::2], a[1::2] = b[1::2], b[0::2]; return bytes(a)

        def il64(names):                   # <interleave output=64> map=…21/2100/…
            ms = [rd(n) for n in names]; out = bytearray()
            for i in range(0, len(ms[0]), 2):
                for k in range(4):
                    out += ms[k][i:i + 2]
            return bytes(out)

        HDRLEN = 44
        def at(pos):
            return HDRLEN + pos

        checks = []
        checks.append(("key", 0x0, rd("vsavj.key")))
        checks.append(("maincpu", 0x14, b"".join(rd(n) for n in (
            "vm3j.03d", "vm3j.04d", "vm3j.05a", "vm3j.06b", "vm3j.07b",
            "vm3j.08a", "vm3j.09b", "vm3j.10b",
            "vsw.41", "vsw.42", "vsw.43", "vsw.44"))))
        checks.append(("audiocpu", 0x600014, rd("vsw.z01") + rd("vsw.z02")))
        qs = swap(rd("vm3.11m")) + swap(rd("vm3.12m"))
        trimmed = swap(rd("vsw.21m"))[:0xF0000]
        checks.append(("qsound+qsoundw", 0x640014, qs + trimmed))
        checks.append(("gfx", 0xF30014,
                       il64(["vm3.13m", "vm3.15m", "vm3.17m", "vm3.19m"]) +
                       il64(["vm3.14m", "vm3.16m", "vm3.18m", "vm3.20m"]) +
                       il64(["vsw.31m", "vsw.33m", "vsw.35m", "vsw.37m"])))
        checks.append(("firmware", 0x3F30014, zq.read("dl-1425.bin")[:0x2000]))
        for name, pos, exp in checks:
            got = data[at(pos):at(pos) + len(exp)]
            if got == exp:
                ok("region %-14s %#010x + %#x bytes == the romset"
                   % (name, pos - KEY_LEN if name != "key" else 0, len(exp)))
            else:
                first = next((i for i in range(min(len(got), len(exp)))
                              if got[i] != exp[i]), min(len(got), len(exp)))
                bad("region %s differs from the romset at +%#x" % (name, first))
        # the trim must be a PURE TRUNCATION (mister_map.md §9 Q2)
        if swap(rd("vsw.21m"))[:0xF0000] == data[at(0x640014) + 0x800000:
                                                 at(0x640014) + 0x8F0000]:
            ok("the trimmed QSound region is a PURE TRUNCATION of the "
               "untrimmed one (mister_map.md Q2)")
        else:
            bad("the trim is not a pure truncation — parts= changed the bytes")
        # the QSound placement covers every live byte
        live = len(rd("vsw.21m").rstrip(b"\0"))
        if live > 0xF0000:
            bad("QSound live extent 0x%X exceeds the 0xF0000 placement"
                % (0x800000 + live))
        else:
            ok("QSound live to 0x%X, placed to 0x8F0000 (DSP sample bank 0x8E "
               "boundary)" % (0x800000 + live))

    # ── the catalogue names the CURRENT build's CRCs ───────────────────────
    r = subprocess.run([sys.executable, os.path.join(REPO, "tools/gen_vsavjw_xml.py"),
                        os.path.join(REPO, BUILD, "rompath", "vsavjw.zip"),
                        "--check", os.path.join(REPO, "emu/jtcores/doc/mame.xml")],
                       capture_output=True, text=True)
    if r.returncode:
        bad("the fork's vsavjw catalogue entry is not %s's — jtframe resolves "
            "members by CRC32 alone, so a stale entry means no .rom at all\n%s"
            % (BUILD, r.stderr))
    else:
        ok("the fork's vsavjw entry names %s's CRCs" % BUILD)

    # ── the stock reference leg's own download image ───────────────────────
    stock = os.path.join(WORK, "stockrom", "vsavj.rom")
    if not os.path.exists(stock):
        bad("no stock vsavj.rom was produced from the pristine sets")
    else:
        sz = os.path.getsize(stock)
        sha = hashlib.sha1(open(stock, "rb").read()).hexdigest()
        # docs/platform/mister.md Recipe step 5 records both, measured 14z-106.
        if sz != 46407744 or sha != "f9dc29870c871355c5c0fa06c6ad8bea9236ba28":
            bad("stock vsavj.rom is %d B sha1 %s; docs/platform/mister.md "
                "records 46407744 / f9dc2987… — the FPGA reference download "
                "image MOVED" % (sz, sha))
        else:
            ok("stock vsavj.rom 46,407,744 B sha1 f9dc2987… — the reference "
               "download image is BIT-IDENTICAL, not merely the same size")
        sb = open(stock, "rb").read(64)
        if sb[PROFILE_BYTE] != 0xFF:
            bad("the stock .rom's header byte %d is 0x%02X, not the 0xFF fill "
                "— a stock download would arm the WIDE profile"
                % (PROFILE_BYTE, sb[PROFILE_BYTE]))
        else:
            ok("the stock .rom leaves byte %d at the 0xFF fill: stock vsavj on "
               "jtcps2w.rbf is a STOCK MACHINE" % PROFILE_BYTE)

if errs:
    print("\nFAIL: MiSTer MRA map — %d problem(s)" % len(errs))
    sys.exit(1)
print("\nPASS: the MiSTer MRA produces exactly the placement map's image, the "
      "trim is mandatory and the stock leg is untouched")
PY
