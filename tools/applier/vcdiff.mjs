// vcdiff.mjs — a JS port of tools/apply_release.py's vcdiff_decode, for the
// browser applier. Same RFC 3284 subset, same refusals. Proven byte-identical
// against the Python decoder over every shipped patch (see vcdiff_fidelity.mjs).
const NOOP = 0, ADD = 1, RUN = 2, COPY = 3;
const NEAR_SIZE = 4, SAME_SIZE = 3;
const VCD_MAGIC = Uint8Array.of(0xD6, 0xC3, 0xC4, 0x00);
const HDR_SECONDARY = 1, HDR_CODETABLE = 2, HDR_APPHEADER = 4;
const WIN_SOURCE = 1, WIN_TARGET = 2, WIN_ADLER32 = 4;

function codeTable() {
  const t = [[RUN, 0, 0, NOOP, 0, 0]];
  for (let s = 0; s < 18; s++) t.push([ADD, s, 0, NOOP, 0, 0]);
  for (let mode = 0; mode < 9; mode++) {
    t.push([COPY, 0, mode, NOOP, 0, 0]);
    for (let s = 4; s < 19; s++) t.push([COPY, s, mode, NOOP, 0, 0]);
  }
  for (let mode = 0; mode < 6; mode++)
    for (let s1 = 1; s1 < 5; s1++)
      for (let s2 = 4; s2 < 7; s2++) t.push([ADD, s1, 0, COPY, s2, mode]);
  for (let mode = 6; mode < 9; mode++)
    for (let s1 = 1; s1 < 5; s1++) t.push([ADD, s1, 0, COPY, 4, mode]);
  for (let mode = 0; mode < 9; mode++) t.push([COPY, 4, mode, ADD, 1, 0]);
  if (t.length !== 256) throw new Error(`code table is ${t.length}, not 256`);
  return t;
}
const CODE_TABLE = codeTable();

class Reader {
  constructor(b, i = 0) { this.b = b; this.i = i; }
  byte() { return this.b[this.i++]; }
  varint() { let v = 0; for (;;) { const c = this.b[this.i++]; v = v * 128 + (c & 0x7f); if (!(c & 0x80)) return v; } }
  take(n) { const s = this.b.subarray(this.i, this.i + n); this.i += n; return s; }
}

class AddrCache {
  constructor() { this.near = new Int32Array(NEAR_SIZE); this.same = new Int32Array(SAME_SIZE * 256); this.nn = 0; }
  update(a) { this.near[this.nn] = a; this.nn = (this.nn + 1) % NEAR_SIZE; this.same[a % (SAME_SIZE * 256)] = a; }
  decode(here, mode, addrs) {
    let a;
    if (mode === 0) a = addrs.varint();
    else if (mode === 1) a = here - addrs.varint();
    else if (mode < 2 + NEAR_SIZE) a = this.near[mode - 2] + addrs.varint();
    else a = this.same[(mode - 2 - NEAR_SIZE) * 256 + addrs.byte()];
    this.update(a);
    return a;
  }
}

function adler32(d) {
  let a = 1, b = 0;
  for (let i = 0; i < d.length; i++) { a = (a + d[i]) % 65521; b = (b + a) % 65521; }
  return ((b * 65536) + a) >>> 0;
}

export function vcdiffDecode(patch, source) {
  const r = new Reader(patch);
  const magic = r.take(4);
  for (let i = 0; i < 4; i++) if (magic[i] !== VCD_MAGIC[i]) throw new Error("not a VCDIFF stream");
  const hdr = r.byte();
  if (hdr & HDR_SECONDARY) throw new Error("VCDIFF secondary compression is not supported (the packager never uses it)");
  if (hdr & HDR_CODETABLE) throw new Error("VCDIFF custom code table is not supported");
  if (hdr & HDR_APPHEADER) r.take(r.varint());
  const chunks = []; let outLen = 0;
  while (r.i < patch.length) {
    const win = r.byte();
    let srcLen = 0, srcPos = 0;
    if (win & (WIN_SOURCE | WIN_TARGET)) { srcLen = r.varint(); srcPos = r.varint(); }
    r.varint();
    const tgtLen = r.varint();
    if (r.byte() !== 0) throw new Error("VCDIFF per-section compression is not supported");
    const dataLen = r.varint(), instLen = r.varint(), addrLen = r.varint();
    let want = null;
    if (win & WIN_ADLER32) { const w = r.take(4); want = ((w[0] << 24) | (w[1] << 16) | (w[2] << 8) | w[3]) >>> 0; }
    const data = new Reader(r.take(dataLen)), inst = new Reader(r.take(instLen)), addrs = new Reader(r.take(addrLen));
    let seg;
    if (win & WIN_SOURCE) seg = source.subarray(srcPos, srcPos + srcLen);
    else if (win & WIN_TARGET) { const sofar = concat(chunks, outLen); seg = sofar.subarray(srcPos, srcPos + srcLen); }
    else seg = new Uint8Array(0);
    const t = new Uint8Array(tgtLen); let n = 0;
    const cache = new AddrCache();
    while (inst.i < instLen) {
      const e = CODE_TABLE[inst.byte()];
      for (const [ins, sz0, mode] of [[e[0], e[1], e[2]], [e[3], e[4], e[5]]]) {
        if (ins === NOOP) continue;
        let size = sz0 === 0 ? inst.varint() : sz0;
        if (ins === ADD) { t.set(data.take(size), n); n += size; }
        else if (ins === RUN) { const v = data.byte(); t.fill(v, n, n + size); n += size; }
        else {
          const a = cache.decode(srcLen + n, mode, addrs);
          if (a < srcLen) {
            const end = a + size;
            if (end <= srcLen) { t.set(seg.subarray(a, end), n); n += size; }
            else {
              t.set(seg.subarray(a, srcLen), n); n += srcLen - a;
              for (let k = 0; k < end - srcLen; k++) t[n++] = t[k];
            }
          } else {
            const p = a - srcLen;
            if (p + size <= n) { t.set(t.subarray(p, p + size), n); n += size; }
            else for (let k = 0; k < size; k++) t[n++] = t[p + k];
          }
        }
      }
    }
    if (n !== tgtLen) throw new Error(`VCDIFF window length mismatch: ${n} != ${tgtLen}`);
    if (want !== null && adler32(t) !== want) throw new Error("VCDIFF window adler32 mismatch");
    chunks.push(t); outLen += tgtLen;
  }
  return concat(chunks, outLen);
}

function concat(chunks, total) {
  const o = new Uint8Array(total); let p = 0;
  for (const c of chunks) { o.set(c, p); p += c.length; }
  return o;
}
