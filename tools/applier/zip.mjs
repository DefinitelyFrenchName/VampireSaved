// zip.mjs — the ZIP half of the browser applier: read the player's reference
// dumps, write the romset. No dependencies; DEFLATE is the platform's own
// CompressionStream/DecompressionStream("deflate-raw").
//
// WHAT IT DELIBERATELY REFUSES, because a silent misread is worse than a stop:
// ZIP64, encryption, and any compression method but STORED (0) and DEFLATE (8).
// Measured 2026-09-21: all four reference dumps are method 8, no ZIP64, no
// directory entries, and their namelist is already in sorted order.
//
// THE WRITER MATCHES tools/apply_release.py's zipfile OUTPUT FIELD FOR FIELD
// (version 20, flags 0, method 8, the fixed 1997-05-19 timestamp, create_system
// 3, external_attr 0) so that on an engine whose deflate is zlib's the whole
// container comes out byte-identical. It is NOT identical on every engine and
// the fidelity contract does not claim it is: Firefox's deflate-raw emits a
// different (valid) stream for the same input — measured 2026-09-21, 2042 bytes
// against zlib's 1424 on one 200 KB fixture. What IS contractual is the MEMBER
// bytes and the set key, which no encoder can change.

const CRC_TABLE = (() => {
  const t = new Uint32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = (c & 1) ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1);
    t[n] = c >>> 0;
  }
  return t;
})();

export function crc32(buf) {
  let c = 0xFFFFFFFF;
  for (let i = 0; i < buf.length; i++) c = CRC_TABLE[(c ^ buf[i]) & 0xFF] ^ (c >>> 8);
  return (c ^ 0xFFFFFFFF) >>> 0;
}

async function inflateRaw(bytes) {
  const s = new Blob([bytes]).stream().pipeThrough(new DecompressionStream("deflate-raw"));
  return new Uint8Array(await new Response(s).arrayBuffer());
}

async function deflateRaw(bytes) {
  const s = new Blob([bytes]).stream().pipeThrough(new CompressionStream("deflate-raw"));
  return new Uint8Array(await new Response(s).arrayBuffer());
}

const u16 = (b, o) => b[o] | (b[o + 1] << 8);
const u32 = (b, o) => (b[o] | (b[o + 1] << 8) | (b[o + 2] << 16) | (b[o + 3] << 24)) >>> 0;

/** Open a zip held in memory. `label` names it in every refusal. */
export function openZip(bytes, label) {
  // the End Of Central Directory record, scanned back over the comment field
  let eocd = -1;
  const floor = Math.max(0, bytes.length - 65557);
  for (let i = bytes.length - 22; i >= floor; i--) {
    if (u32(bytes, i) === 0x06054B50) { eocd = i; break; }
  }
  if (eocd < 0) throw new Error(`${label}: not a zip file (no end-of-central-directory record)`);
  const count = u16(bytes, eocd + 10);
  const cdOff = u32(bytes, eocd + 16);
  if (cdOff === 0xFFFFFFFF || u16(bytes, eocd + 8) === 0xFFFF) {
    throw new Error(`${label}: ZIP64 archives are not supported`);
  }
  const entries = new Map();
  const names = [];
  let p = cdOff;
  const dec = new TextDecoder();
  for (let n = 0; n < count; n++) {
    if (u32(bytes, p) !== 0x02014B50) throw new Error(`${label}: damaged central directory`);
    const flags = u16(bytes, p + 8);
    const method = u16(bytes, p + 10);
    const csize = u32(bytes, p + 20);
    const usize = u32(bytes, p + 24);
    const nlen = u16(bytes, p + 28), elen = u16(bytes, p + 30), clen = u16(bytes, p + 32);
    const lho = u32(bytes, p + 42);
    const name = dec.decode(bytes.subarray(p + 46, p + 46 + nlen));
    if (flags & 0x1) throw new Error(`${label}/${name}: encrypted zip members are not supported`);
    if (csize === 0xFFFFFFFF || usize === 0xFFFFFFFF || lho === 0xFFFFFFFF) {
      throw new Error(`${label}/${name}: ZIP64 entries are not supported`);
    }
    if (method !== 0 && method !== 8) {
      throw new Error(`${label}/${name}: compression method ${method} is not supported (only stored and deflate)`);
    }
    entries.set(name, { method, csize, usize, lho });
    names.push(name);
    p += 46 + nlen + elen + clen;
  }
  return {
    label,
    /** Every member name, sorted — the order tools/apply_release.py's
     *  `sorted(zf.namelist())` walks when it rebuilds the source blob. */
    names: () => names.slice().sort(),
    has: (name) => entries.has(name),
    async read(name) {
      const e = entries.get(name);
      if (!e) throw new Error(`${label}/${name}: member missing`);
      if (u32(bytes, e.lho) !== 0x04034B50) throw new Error(`${label}/${name}: damaged local header`);
      const nlen = u16(bytes, e.lho + 26), elen = u16(bytes, e.lho + 28);
      const start = e.lho + 30 + nlen + elen;
      const raw = bytes.subarray(start, start + e.csize);
      const out = e.method === 0 ? raw.slice() : await inflateRaw(raw);
      if (out.length !== e.usize) {
        throw new Error(`${label}/${name}: member decompressed to ${out.length} bytes, not ${e.usize}`);
      }
      return out;
    },
  };
}

// The fixed timestamp tools/apply_release.py stamps on every member:
// ZipInfo(name, date_time=(1997, 5, 19, 0, 0, 0)) — the reference set's date.
const DOS_TIME = 0;
const DOS_DATE = ((1997 - 1980) << 9) | (5 << 5) | 19;

/**
 * Write a zip of [name, Uint8Array] pairs in the given order, deflated, with
 * the same header fields Python's zipfile writes for apply_release.py.
 */
export async function writeZip(members, onProgress) {
  const enc = new TextEncoder();
  const locals = [];
  const central = [];
  let offset = 0;
  let i = 0;
  for (const [name, data] of members) {
    const nb = enc.encode(name);
    const comp = await deflateRaw(data);
    const crc = crc32(data);
    const lh = new Uint8Array(30 + nb.length);
    const lv = new DataView(lh.buffer);
    lv.setUint32(0, 0x04034B50, true);
    lv.setUint16(4, 20, true);          // version needed to extract
    lv.setUint16(6, 0, true);           // flags
    lv.setUint16(8, 8, true);           // method: deflate
    lv.setUint16(10, DOS_TIME, true);
    lv.setUint16(12, DOS_DATE, true);
    lv.setUint32(14, crc, true);
    lv.setUint32(18, comp.length, true);
    lv.setUint32(22, data.length, true);
    lv.setUint16(26, nb.length, true);
    lv.setUint16(28, 0, true);          // extra length
    lh.set(nb, 30);
    locals.push(lh, comp);

    const ch = new Uint8Array(46 + nb.length);
    const cv = new DataView(ch.buffer);
    cv.setUint32(0, 0x02014B50, true);
    cv.setUint16(4, (3 << 8) | 20, true);  // version made by: Unix, 2.0
    cv.setUint16(6, 20, true);
    cv.setUint16(8, 0, true);
    cv.setUint16(10, 8, true);
    cv.setUint16(12, DOS_TIME, true);
    cv.setUint16(14, DOS_DATE, true);
    cv.setUint32(16, crc, true);
    cv.setUint32(20, comp.length, true);
    cv.setUint32(24, data.length, true);
    cv.setUint16(28, nb.length, true);
    cv.setUint16(30, 0, true);          // extra
    cv.setUint16(32, 0, true);          // comment
    cv.setUint16(34, 0, true);          // disk
    cv.setUint16(36, 0, true);          // internal attrs
    // EXTERNAL ATTRS = 0o600 << 16, which is what ZipFile.writestr stamps even on an
    // explicit ZipInfo (measured 2026-09-21 on python 3.9.6; ZipInfo itself constructs
    // with 0). Not cosmetic: with create_system 3 (Unix) an external_attr of 0 means
    // mode 0000, and an extractor that honours it writes files nobody can read.
    cv.setUint32(38, 0o600 << 16, true);
    cv.setUint32(42, offset, true);
    ch.set(nb, 46);
    central.push(ch);
    offset += lh.length + comp.length;
    if (onProgress) onProgress(++i, members.length);
  }
  const cdStart = offset;
  let cdLen = 0;
  for (const c of central) cdLen += c.length;
  const end = new Uint8Array(22);
  const ev = new DataView(end.buffer);
  ev.setUint32(0, 0x06054B50, true);
  ev.setUint16(8, members.length, true);
  ev.setUint16(10, members.length, true);
  ev.setUint32(12, cdLen, true);
  ev.setUint32(16, cdStart, true);
  let total = cdStart + cdLen + 22;
  const out = new Uint8Array(total);
  let q = 0;
  for (const part of locals) { out.set(part, q); q += part.length; }
  for (const part of central) { out.set(part, q); q += part.length; }
  out.set(end, q);
  return out;
}
