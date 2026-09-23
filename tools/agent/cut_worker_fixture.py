#!/usr/bin/env python3
"""cut_worker_fixture.py — cut a session's transcript and its WORKER transcripts down to the
records and fields `tools/agent/extract.py` reads, for a frozen gate fixture (GitHub #172 S4).

Why a cut and never a copy: a raw transcript embeds the session's whole context — the system
prompt snapshot, the user's identity and every attachment (measured 14z-177: the headless run
behind `tests/agent/worker_fixture/` carried the maintainer's e-mail address in both of its
transcripts). A fixture lives in a public tree, so it keeps ONLY:

  records   `user` and `assistant` records (never `attachment`, `queue-operation`, ...), plus a
            `queued_command` attachment whose prompt is an `<agent-message …>` hand-back or a
            `<task-notification>` (the two ways a background worker's end arrives)
  fields    type, timestamp, isSidechain, agentId, effort, and message.{role, model, content}
  content   text, tool_use (id, name, input) and tool_result (tool_use_id, content, is_error)
            blocks — never `thinking`

and each worker's `meta.json` reduced to agentType, description, toolUseId and model. It then
REFUSES to write anything that still matches an e-mail address. Deterministic: the same inputs
give the same bytes.

Usage:
  python3 tools/agent/cut_worker_fixture.py SESSION_TRANSCRIPT OUT_DIR
      -> OUT_DIR/<name>.jsonl and OUT_DIR/<name>/subagents/agent-<id>.{jsonl,meta.json}
Stdlib only.
"""
import glob
import json
import os
import re
import sys

EMAIL = re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}")


def cut_block(b):
    t = b.get("type")
    if t == "text":
        return {"type": "text", "text": b.get("text", "")}
    if t == "tool_use":
        return {"type": "tool_use", "id": b.get("id"), "name": b.get("name"), "input": b.get("input")}
    if t == "tool_result":
        out = {"type": "tool_result", "tool_use_id": b.get("tool_use_id"), "content": b.get("content")}
        if b.get("is_error"):
            out["is_error"] = True
        return out
    return None


def cut_record(r):
    t = r.get("type")
    base = {k: r[k] for k in ("type", "timestamp", "isSidechain", "agentId", "effort") if k in r}
    if t in ("user", "assistant"):
        m = r.get("message") or {}
        c = m.get("content")
        if isinstance(c, list):
            c = [x for x in (cut_block(b) for b in c if isinstance(b, dict)) if x]
            if not c:
                return None
        elif not isinstance(c, str):
            return None
        base["message"] = {k: m[k] for k in ("role", "model") if k in m}
        base["message"]["content"] = c
        return base
    if t == "attachment":
        a = r.get("attachment") or {}
        p = str(a.get("prompt", ""))
        if a.get("type") == "queued_command" and (p.startswith("<agent-message") or p.startswith("<task-notification>")):
            base["attachment"] = {"type": "queued_command", "prompt": p}
            return base
    return None


def cut_file(src, dst):
    rows = []
    for line in open(src, encoding="utf-8"):
        try:
            r = cut_record(json.loads(line))
        except ValueError:
            continue
        if r is not None:
            rows.append(json.dumps(r, sort_keys=True, ensure_ascii=False))
    text = "\n".join(rows) + "\n"
    return dst, text


def main(argv):
    if len(argv) != 3:
        print(__doc__.split("Usage:")[1].strip(), file=sys.stderr)
        return 2
    src, out = argv[1], argv[2]
    name = os.path.basename(src)[:-len(".jsonl")]
    writes = [cut_file(src, os.path.join(out, name + ".jsonl"))]
    for meta in sorted(glob.glob(src[:-len(".jsonl")] + "/subagents/*.meta.json")):
        m = json.load(open(meta))
        keep = {k: m[k] for k in ("agentType", "description", "toolUseId", "model") if k in m}
        base = os.path.join(out, name, "subagents", os.path.basename(meta)[:-len(".meta.json")])
        writes.append((base + ".meta.json", json.dumps(keep, sort_keys=True) + "\n"))
        writes.append(cut_file(meta[:-len(".meta.json")] + ".jsonl", base + ".jsonl"))
    leaks = [p for p, t in writes if EMAIL.search(t)]
    if leaks:
        print(f"REFUSED: an e-mail address survives the cut in {', '.join(leaks)}", file=sys.stderr)
        return 1
    for p, t in writes:
        os.makedirs(os.path.dirname(p), exist_ok=True)
        open(p, "w", encoding="utf-8").write(t)
        print(f"wrote {p}: {len(t)} bytes, {t.count(chr(10))} records")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
