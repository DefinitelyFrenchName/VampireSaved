#!/usr/bin/env python3
"""audit_qs_id_table.py — census of a QSound Z80 driver's sound-id table.

Usage:
    audit_qs_id_table.py <set.zip>:<prefix> [--json out.json] [--id 0xNNN ...]

    e.g.  audit_qs_id_table.py "$ROMDIR/vsav.zip":vm3     (vsavj's driver)
          audit_qs_id_table.py "$ROMDIR/vsav2.zip":vs2

Everything is DERIVED from the member bytes via the driver's own fixed-ROM
anchor pointers (14z-86, reader-traced on live vsavj — RH-27 satisfied for
every table below; docs/game/engine_internals.md "The QSound Z80 driver"):

    word($3B00) -> sound-bank header: [id-mod word BE][2 config bytes],
                   id table at header+6, 4 bytes/id
    word($3B02) -> sample-record table (8 B/record:
                   [bank][start LE][loop LE][end LE][transpose])
    word($3B04) -> default note table (4 B/entry:
                   [sample# LE][ix+0D][instrument#])

Id-table entry = [addr-hi][addr-mid][addr-lo][tail]: a 24-bit big-endian
address in the driver's LOGICAL space, which equals the FLAT member-concat
file offset (vm3.01+vm3.02). The consumer treats byte0==0 as a NO-OP id
(ld a,d / ret z at 0x02E1 — Z still set from `or a`), so b0==0 rows are
FREE. Hardware masks the computed bank to 4 bits (MAME qsound_banksw_w:
`data & 0x0f`, overflow -> bank 0), so only the low 18 bits of the address
reach the ROM; higher b0 bits are addressing DON'T-CARE (music entries
carry nonzero high nibbles there — classified separately, do not imitate
them for new sfx rows).

Prints the SHA-1 of every member read (repo convention).
"""
import argparse, hashlib, json, struct, sys, zipfile


def flat_effective(addr24):
    """The flat file offset the driver's bank fold + 4-bit hw mask lands on."""
    top = (addr24 >> 14) - 2
    if top <= 0:               # borrow or bank 0: no fold, CPU = low 16 bits
        cpu = addr24 & 0xFFFF
        if cpu < 0x8000:
            return cpu          # fixed ROM
        return cpu              # bank-0 window: flat == CPU
    bank = top & 0x0F
    return 0x8000 + bank * 0x4000 + (addr24 & 0x3FFF)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src", help="<set.zip>:<member-prefix>")
    ap.add_argument("--json", help="write full census as JSON")
    ap.add_argument("--id", action="append", default=[],
                    help="hex id(s) to print in detail")
    args = ap.parse_args()

    zpath, _, prefix = args.src.rpartition(":")
    if not zpath:
        sys.exit("src must be <set.zip>:<prefix>")
    z = zipfile.ZipFile(zpath)
    # the Z80 driver is exactly <prefix>.01 + <prefix>.02 (stock naming:
    # vm3.01) or <prefix>01 + <prefix>02 (the WIDE content members
    # vsw.z01/z02); a bare prefix match would also swallow the gfx/qsound
    # members (vm3.05a..vm3.20m)
    p = prefix.lower()
    wanted = {p + ".01", p + ".02", p + "01", p + "02"}
    members = sorted(n for n in z.namelist() if n.lower() in wanted)
    if len(members) != 2:
        sys.exit(f"no {prefix}(.)01/02 member pair in {zpath} "
                 f"(found {members})")
    data = b""
    for n in members:
        b = z.read(n)
        print(f"read {n}  len 0x{len(b):x}  sha1 {hashlib.sha1(b).hexdigest()}")
        data += b

    hdr_ptr = struct.unpack_from("<H", data, 0x3B00)[0]
    rec_ptr = struct.unpack_from("<H", data, 0x3B02)[0]
    note_ptr = struct.unpack_from("<H", data, 0x3B04)[0]
    mod = struct.unpack_from(">H", data, flat_effective(hdr_ptr))[0]
    table = flat_effective(hdr_ptr) + 6
    print(f"anchors: header={hdr_ptr:#06x} sample_records={rec_ptr:#06x} "
          f"note_table={note_ptr:#06x}")
    print(f"id table @flat {table:#07x}, mod {mod:#05x} ({mod} ids)")

    rows = []
    n_free = n_live = n_flagged = n_oob = 0
    for i in range(mod):
        o = table + i * 4
        b0, b1, b2, b3 = data[o:o + 4]
        addr = (b0 << 16) | (b1 << 8) | b2
        eff = flat_effective(addr)
        if b0 == 0 and addr == 0:
            cls = "free"
            n_free += 1
        elif b0 == 0:
            # b0==0 but nonzero low bytes: STILL a no-op to the consumer
            cls = "free-nonzero-tail"
            n_free += 1
        else:
            aliased = (addr >> 18) != 0    # bits beyond the hw reach
            in_rom = eff < len(data)
            if not in_rom:
                cls = "oob"
                n_oob += 1
            elif aliased:
                cls = "live-flagged"       # music-style: high don't-care bits set
                n_flagged += 1
            else:
                cls = "live"
                n_live += 1
        rows.append({"id": i, "bytes": data[o:o + 4].hex(), "addr": addr,
                     "eff": eff, "tail": b3, "class": cls})

    print(f"classes: live {n_live}, live-flagged {n_flagged}, "
          f"free {n_free}, oob {n_oob}  (total {mod})")

    free = [r["id"] for r in rows if r["class"].startswith("free")]
    ranges = []
    for i in free:
        if ranges and i == ranges[-1][1] + 1:
            ranges[-1][1] = i
        else:
            ranges.append([i, i])
    print(f"free ids ({len(free)}):",
          " ".join(f"{a:#x}" if a == b else f"{a:#x}-{b:#x}"
                   for a, b in ranges))

    for h in args.id:
        raw = int(h, 16)
        i = raw % mod       # the consumer normalizes: sbc-loop mod ($F010)
        r = rows[i]
        if raw != i:
            print(f"id {raw:#05x} folds to row {i:#05x} (mod {mod:#x})")
        print(f"id {i:#05x}: bytes {r['bytes']} addr {r['addr']:#08x} "
              f"eff flat {r['eff']:#07x} tail {r['tail']:#04x} [{r['class']}]")
        if r["class"].startswith("live"):
            eff = r["eff"]
            pri = data[eff]
            slots = [struct.unpack_from(">H", data, eff + 1 + 2 * k)[0]
                     for k in range(16)]
            print(f"    song: priority {pri:#04x} slots " +
                  " ".join(f"{k}:{w:#06x}" for k, w in enumerate(slots) if w))

    if args.json:
        with open(args.json, "w") as f:
            json.dump({"src": args.src, "members": members, "mod": mod,
                       "table": table,
                       "anchors": {"header": hdr_ptr, "records": rec_ptr,
                                   "notes": note_ptr},
                       "rows": rows}, f)
        print(f"wrote {args.json}")


if __name__ == "__main__":
    main()
