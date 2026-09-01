#!/usr/bin/env python3
"""plant_anim_reloc_control.py — the must-fire control for
tests/test_tenant_anim_relocation.sh: copy a tenant's verify_data.bin with ONE
anim node's sprite pointer (+4) rewritten to a SOURCE-range address, i.e. the
unrelocated-pointer defect the gate exists to catch.

  python3 tools/plant_anim_reloc_control.py <src build dir> <dst dir> <verdict.json>

Reads the node address from the audit's own verdict (`first_node`) so the
control always plants on a node the walker actually visits. Writes ONLY into
<dst dir>; never touches the build dir.
"""
import json, struct, sys
from pathlib import Path

src_dir, dst_dir, verdict = (Path(a) for a in sys.argv[1:4])
data = bytearray((src_dir / "verify_data.bin").read_bytes())
reg = json.loads((src_dir / "patch" / "placements.json").read_text())["regions"]["anim"]
node = json.loads(verdict.read_text())["first_node"]
if node is None:
    print("no first_node in the verdict — nothing to plant", file=sys.stderr)
    sys.exit(2)
data[node + 4:node + 8] = struct.pack(">I", reg["src"] + 0x100)
(dst_dir / "verify_data.bin").write_bytes(bytes(data))
print(f"planted a source-range pointer at node {node:#x}+4")
