#!/usr/bin/env python3
"""trap_air_prologue.py — replace replay 92's forced-pick select prologue with REAL cursor routes
(tools/trap_air_probe.sh PICK=real; the shape is tools/name_moves.prologue_for, the one copy).

Usage: trap_air_prologue.py <rpl> "<p1 moves>" "<p2 moves>"   (rewrites <rpl> in place)
"""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import name_moves as nm

OLD = ("300-305 sys=C1\n420-425 sys=C2\n800-803 sys=S1\n940-943 sys=S2\n"
       "1100-1102 p2=R\n1160-1162 p2=R\n1300-1302 p1=1\n1360-1362 p2=1")
src = open(sys.argv[1]).read()
assert src.count(OLD) == 1, "replay 92's prologue is not verbatim"
open(sys.argv[1], "w").write(src.replace(OLD, nm.prologue_for(sys.argv[2].split(), sys.argv[3].split())))
