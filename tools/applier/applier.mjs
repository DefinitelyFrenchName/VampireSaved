// applier.mjs — the browser applier's LOGIC, step for step the same as
// tools/apply_release.py, which stays the tool of record. No DOM here: the page
// is a front end over this module, and tests/test_applier_page.sh runs this very
// module under node against $ROMDIR and requires its output to equal the Python
// applier's member for member.
//
// The order, and it is the Python tool's order because failing in a different
// order would mean failing with a different message:
//   1. verify every reference member the manifest names, reporting ALL bad ones;
//   2. rebuild the source blob (fixed zip order, members sorted) and check its sha1;
//   3. per target member: copy pristine, or decode its VCDIFF and check the sha1;
//   4. only then build the zips, and check the whole set's key.
// Nothing is handed back unless every member verified.

import { vcdiffDecode } from "./vcdiff.mjs";
import { openZip, writeZip } from "./zip.mjs";

/** A refusal the player is meant to read. `.lines` carries a multi-line body. */
export class ApplierError extends Error {
  constructor(message, lines) {
    super(message);
    this.name = "ApplierError";
    this.lines = lines || [];
  }
}

const HEX = Array.from({ length: 256 }, (_, i) => i.toString(16).padStart(2, "0"));

export async function sha1Hex(bytes) {
  const d = new Uint8Array(await crypto.subtle.digest("SHA-1", bytes));
  let s = "";
  for (let i = 0; i < d.length; i++) s += HEX[d[i]];
  return s;
}

const skipped = (e, noQsoundBios) => noQsoundBios && e.optional === "qsound-bios";

/**
 * Which reference dumps this manifest needs, for the chosen variant — so the
 * page can name them BEFORE the player picks anything, and so the QSound BIOS
 * set is not demanded of someone who asked for the set without it.
 */
export function requiredDumps(manifest, noQsoundBios) {
  const blob = manifest.source.order.slice();
  const needed = new Set();
  for (const entries of Object.values(manifest.zips)) {
    for (const e of entries) {
      if (e.pristine_from && !skipped(e, noQsoundBios)) needed.add(e.pristine_from.zip);
    }
  }
  const extra = (manifest.pristine_sources || [])
    .filter((s) => needed.has(s.zip) && !blob.includes(s.zip))
    .map((s) => s.zip);
  return { blob, extra, all: blob.concat(extra) };
}

/**
 * @param manifest      the release's manifest.json, parsed
 * @param patches       Map<"patches/…/x.xdelta", Uint8Array>
 * @param dumps         Map<"vsavj.zip", Uint8Array> — the player's own files
 * @param noQsoundBios  omit the optional QSound BIOS member (MiSTer / FBNeo)
 * @param onProgress    (stage, done, total) — for the page's progress line
 */
export async function applyRelease({ manifest, patches, dumps, noQsoundBios = false, onProgress = null }) {
  const m = manifest;
  const say = (stage, done, total) => { if (onProgress) onProgress(stage, done, total); };
  const log = [];

  // ── 1. the reference dumps ────────────────────────────────────────────────
  const refs = new Map();
  const openRef = (zname) => {
    if (refs.has(zname)) return refs.get(zname);
    const bytes = dumps.get(zname);
    if (!bytes) throw new ApplierError(`missing reference dump: ${zname}`);
    let z;
    try {
      z = openZip(bytes, zname);
    } catch (ex) {
      // A truncated or half-copied download is an ordinary thing to have, and a raw
      // parser error tells the player nothing about WHICH of their files is wrong.
      // The same wording apply_release.py uses (2026-09-21).
      throw new ApplierError(`${zname}: not a readable zip file (damaged, incomplete, or not a zip) — ${ex.message}`);
    }
    refs.set(zname, z);
    return z;
  };
  // A member can also fail to come out of a structurally valid zip (a damaged deflate
  // stream). Same rule: name the member, never surface a parser error.
  const readRef = async (zname, member) => {
    try {
      return await openRef(zname).read(member);
    } catch (ex) {
      if (ex instanceof ApplierError) throw ex;
      throw new ApplierError(`${zname}/${member}: cannot read this member (damaged dump) — ${ex.message}`);
    }
  };

  const bad = [];
  let done = 0;
  for (const r of m.source.recipe) {
    const z = openRef(r.zip);
    if (!z.has(r.member)) { bad.push(`${r.zip}/${r.member}: member missing`); continue; }
    const d = await readRef(r.zip, r.member);
    if (d.length !== r.size || (await sha1Hex(d)) !== r.sha1) {
      bad.push(`${r.zip}/${r.member}: sha1/size mismatch (wrong or modified dump)`);
    }
    say("verifying your dumps", ++done, m.source.recipe.length);
  }

  // PRISTINE-ONLY SOURCES — reference zips the release copies members out of
  // without them feeding the source blob (the QSound BIOS set). Verified to the
  // same standard; and a source that only feeds SKIPPED entries is not demanded.
  const neededSrcs = new Set();
  for (const entries of Object.values(m.zips)) {
    for (const e of entries) {
      if (e.pristine_from && !skipped(e, noQsoundBios)) neededSrcs.add(e.pristine_from.zip);
    }
  }
  let nextra = 0;
  for (const src of m.pristine_sources || []) {
    if (!neededSrcs.has(src.zip)) continue;
    const z = openRef(src.zip);
    for (const r of src.members) {
      if (!z.has(r.member)) { bad.push(`${src.zip}/${r.member}: member missing`); continue; }
      const d = await readRef(src.zip, r.member);
      if (d.length !== r.size || (await sha1Hex(d)) !== r.sha1) {
        bad.push(`${src.zip}/${r.member}: sha1/size mismatch (wrong or modified dump)`);
      }
      nextra++;
    }
  }
  if (bad.length) {
    throw new ApplierError("reference dumps do not match the manifest:", bad);
  }
  log.push(`reference dumps verified: ${m.source.recipe.length + nextra} members`);

  // ── 2. the source blob ────────────────────────────────────────────────────
  const source = new Uint8Array(m.source.size);
  let at = 0;
  done = 0;
  const blobMembers = [];
  for (const z of m.source.order) for (const n of openRef(z).names()) blobMembers.push([z, n]);
  for (const [z, n] of blobMembers) {
    const d = await readRef(z, n);
    if (at + d.length > source.length) {
      throw new ApplierError("source blob sha1 mismatch — an extra or missing member in a reference zip");
    }
    source.set(d, at); at += d.length;
    say("rebuilding the source blob", ++done, blobMembers.length);
  }
  if (at !== source.length || (await sha1Hex(source)) !== m.source.sha1) {
    throw new ApplierError("source blob sha1 mismatch — an extra or missing member in a reference zip");
  }
  log.push("source blob rebuilt and verified");

  // ── 3. every target member, verified before anything is built ─────────────
  const built = new Map();
  let nskip = 0;
  const totalEntries = Object.values(m.zips).reduce((a, e) => a + e.length, 0);
  done = 0;
  for (const [zname, entries] of Object.entries(m.zips)) {
    const out = [];
    for (const e of entries) {
      if (skipped(e, noQsoundBios)) { nskip++; say("rebuilding the romset", ++done, totalEntries); continue; }
      let d;
      if (e.pristine_from) {
        d = await readRef(e.pristine_from.zip, e.pristine_from.member);
      } else {
        const pb = patches.get(e.patch);
        if (!pb) throw new ApplierError(`patch missing: ${e.patch}`);
        if ((await sha1Hex(pb)) !== e.patch_sha1) {
          throw new ApplierError(`patch file corrupted: ${e.patch}`);
        }
        try {
          d = vcdiffDecode(pb, source);
        } catch (ex) {
          throw new ApplierError(`${zname}/${e.member}: cannot decode ${e.patch}: ${ex.message} — NOT writing`);
        }
      }
      if (d.length !== e.size || (await sha1Hex(d)) !== e.sha1) {
        throw new ApplierError(`${zname}/${e.member}: rebuilt member does not match the manifest — NOT writing`);
      }
      out.push([e.member, d]);
      say("rebuilding the romset", ++done, totalEntries);
    }
    built.set(zname, out);
    log.push(`  ${zname}: ${out.length} members verified`
      + (nskip ? ` (${nskip} optional member(s) omitted)` : ""));
  }

  // ── 4. the set key, against the manifest's own declaration ────────────────
  // Computed exactly as tools/build_fingerprint.py wholeset_key() does: the
  // player's one-line confirmation that they hold the same romset as everyone
  // else (netplay needs it identical).
  const keyField = noQsoundBios ? "applied_set_key_no_qsound_bios" : "applied_set_key";
  const want = m[keyField];
  const enc = new TextEncoder();
  const keyParts = [];
  let keyLen = 0;
  const push = (u8) => { keyParts.push(u8); keyLen += u8.length; };
  for (const zname of [...built.keys()].sort()) {
    push(enc.encode(zname));
    for (const [member, data] of [...built.get(zname)].sort((a, b) => (a[0] < b[0] ? -1 : a[0] > b[0] ? 1 : 0))) {
      push(enc.encode(member)); push(data);
    }
  }
  const keyBuf = new Uint8Array(keyLen);
  let kp = 0;
  for (const part of keyParts) { keyBuf.set(part, kp); kp += part.length; }
  const setKey = await sha1Hex(keyBuf);
  if (want && setKey !== want) {
    throw new ApplierError(`the written set's key ${setKey.slice(0, 8)} does not match the manifest's `
      + `${keyField} ${want.slice(0, 8)} — the output is NOT what this release declares`);
  }

  return {
    built, setKey, declaredKey: want || null, nskip,
    variant: noQsoundBios
      ? "without the optional QSound BIOS member"
      : "standalone (every member the emulator asks for)",
    log,
  };
}

/** Pack a verified result into downloadable zips — only ever called after the above. */
export async function packZips(result, onProgress = null) {
  const out = [];
  for (const [zname, members] of result.built) {
    out.push([zname, await writeZip(members, (d, t) => onProgress && onProgress(zname, d, t))]);
  }
  return out;
}
