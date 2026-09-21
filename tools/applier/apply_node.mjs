// apply_node.mjs — tools/apply_release.py's command line, driven through the
// BROWSER applier's own modules (applier.mjs + zip.mjs + vcdiff.mjs).
//
// It exists so the page's logic can be held to the Python applier's output by a
// gate rather than by inspection: tests/test_applier_page.sh runs this and
// apply_release.py over the same $ROMDIR and requires the results to be equal
// member for member, for BOTH variants. It is NOT shipped to players and is not
// a second applier — it is the same modules the page runs, with node's fs where
// the page has a file picker.
//
//   node tools/applier/apply_node.mjs --romdir DIR --out DIR \
//        [--manifest release/<name>/<platform>/manifest.json] [--no-qsound-bios]
//        [--members-only]      write members as loose files, not zips
import { readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { applyRelease, packZips, requiredDumps, ApplierError } from "./applier.mjs";

const argv = process.argv.slice(2);
const opt = (name, dflt = null) => {
  const i = argv.indexOf(name);
  return i < 0 ? dflt : argv[i + 1];
};
const flag = (name) => argv.includes(name);

const romdir = opt("--romdir");
const out = opt("--out");
const manifestPath = resolve(opt("--manifest", join(dirname(new URL(import.meta.url).pathname), "manifest.json")));
const noQsoundBios = flag("--no-qsound-bios");
if (!romdir || !out) {
  console.error("usage: apply_node.mjs --romdir DIR --out DIR [--manifest PATH] [--no-qsound-bios] [--members-only]");
  process.exit(2);
}

const manifest = JSON.parse(readFileSync(manifestPath, "utf8"));
const here = dirname(manifestPath);

// the player's dumps, by the names the manifest asks for
const dumps = new Map();
for (const z of requiredDumps(manifest, noQsoundBios).all) {
  const p = join(romdir, z);
  if (existsSync(p)) dumps.set(z, new Uint8Array(readFileSync(p)));
}

// the patches, which the page carries inline and this carries from disk
const patches = new Map();
for (const entries of Object.values(manifest.zips)) {
  for (const e of entries) {
    if (!e.patch || patches.has(e.patch)) continue;
    const p = join(here, e.patch);
    if (existsSync(p)) patches.set(e.patch, new Uint8Array(readFileSync(p)));
  }
}

try {
  const result = await applyRelease({ manifest, patches, dumps, noQsoundBios });
  for (const line of result.log) console.log(line);
  mkdirSync(out, { recursive: true });
  if (flag("--members-only")) {
    for (const [zname, members] of result.built) {
      const d = join(out, zname.replace(/\.zip$/, ""));
      mkdirSync(d, { recursive: true });
      for (const [member, data] of members) writeFileSync(join(d, member), data);
    }
  } else {
    for (const [zname, bytes] of await packZips(result)) writeFileSync(join(out, zname), bytes);
  }
  console.log(`OK: wrote ${[...result.built.keys()].sort().join(", ")} to ${out} — every member verified `
    + `(build ${manifest.build_fingerprint || "?"}, mark ${JSON.stringify(manifest.version_string)})`);
  console.log(`    ${result.variant}; set key ${result.setKey.slice(0, 8)}`
    + (result.declaredKey ? "" : " (this release declares no key for that variant)"));
} catch (e) {
  if (e instanceof ApplierError) {
    console.error(e.message);
    for (const l of e.lines) console.error("  " + l);
    process.exit(1);
  }
  throw e;
}
