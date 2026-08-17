#!/usr/bin/env python3
"""cps2_decrypt.py — CPS-2 program-ROM opcode decryption/encryption.

Python port of MAME src/mame/capcom/cps2crypt.cpp (BSD-3-Clause; algorithm
broken by Andreas Naive, reference code by Nicola Salmoria) plus the key-file
decode from cps2.cpp init_cps2crypt(). Behavior is intended to be
bit-identical to MAME; the harness verifies this against a MAME opcode-space
dump (tests/test_decrypt_oracle.sh).

CPS-2 encrypts only opcode fetches. The stored ROM *is* the data view; this
tool derives the opcode view (decrypt) or, given a desired opcode view,
the stored form (encrypt — needed when patches inject new code).

Usage:
    # decrypt: src = romset zip (reads .key + program files), out = raw image
    python3 tools/cps2_decrypt.py <set.zip> <out_opcodes.bin> [--data-out f]
    # encrypt: src = raw opcode-view image, out = raw stored-form image
    python3 tools/cps2_decrypt.py <in_opcodes.bin> <out_stored.bin> --encrypt --keyzip <set.zip>

Byte-order conventions (paid-for lesson, see docs/GOTCHAS.md):
  - ROM *files* store each 16-bit word low-byte-first; the value MAME's
    cps2_decrypt operates on is the little-endian read of the file bytes.
  - Raw *images* produced here (opcode view, data view) are 68k logical
    order: big-endian words, exactly what the CPU sees and what a
    disassembler wants. Identical to a MAME opcode-space dump.
  - --encrypt emits file byte order, ready for repacking into a romset.
Prints SHA-1 of everything read and written. Always self-checks the inverse
direction on the full image (round-trip must be exact).
"""

import argparse
import hashlib
import re
import sys
import zipfile
from array import array
from pathlib import Path

# ── bit-group permutations ────────────────────────────────────────────────────

FN1_GROUPA = (10, 4, 6, 7, 2, 13, 15, 14)
FN1_GROUPB = (0, 1, 3, 5, 8, 9, 11, 12)
FN2_GROUPA = (6, 0, 2, 13, 1, 4, 14, 7)
FN2_GROUPB = (3, 5, 9, 10, 8, 15, 12, 11)

# ── s-boxes: (table[64], inputs[6] (-1 = key-only), outputs[2]) ──────────────

FN1_R1_BOXES = (
    ((0,2,2,0,1,0,1,1,3,2,0,3,0,3,1,2,1,1,1,2,1,3,2,2,2,3,3,2,1,1,1,2,
      2,2,0,0,3,1,3,1,1,1,3,0,0,1,0,0,1,2,2,1,2,3,2,2,2,3,1,3,2,0,1,3),
     (3, 4, 5, 6, -1, -1), (3, 6)),
    ((3,0,2,2,2,1,1,1,1,2,1,0,0,0,2,3,2,3,1,3,0,0,0,2,1,2,2,3,0,3,3,3,
      0,1,3,2,3,3,3,1,1,1,1,2,0,1,2,1,3,2,3,1,1,3,2,2,2,3,1,3,2,3,0,0),
     (0, 1, 2, 4, 7, -1), (2, 7)),
    ((3,0,3,1,1,0,2,2,3,1,2,0,3,3,2,3,0,1,0,1,2,3,0,2,0,2,0,1,0,0,1,0,
      2,3,1,2,1,0,2,0,2,1,0,1,0,2,1,0,3,1,2,3,1,3,1,1,1,2,0,2,2,0,0,0),
     (0, 1, 2, 3, 6, 7), (0, 1)),
    ((3,2,0,3,0,2,2,1,1,2,3,2,1,3,2,1,2,2,1,3,3,2,1,0,1,0,1,3,0,0,0,2,
      2,1,0,1,0,1,0,1,3,1,1,2,2,3,2,0,3,3,2,0,2,1,3,3,0,0,3,0,1,1,3,3),
     (0, 1, 3, 5, 6, 7), (4, 5)),
)

FN1_R2_BOXES = (
    ((3,3,2,0,3,0,3,1,0,3,0,1,0,2,1,3,1,3,0,3,3,1,3,3,3,2,3,2,2,3,1,2,
      0,2,2,1,0,1,2,0,3,3,0,1,3,2,1,2,3,0,1,3,0,1,2,2,1,2,1,2,0,1,3,0),
     (0, 1, 2, 3, 6, -1), (1, 6)),
    ((1,2,3,2,1,3,0,1,1,0,2,0,0,2,3,2,3,3,0,1,2,2,1,0,1,0,1,2,3,2,1,3,
      2,2,2,0,1,0,2,3,2,1,2,1,2,1,0,3,0,1,2,3,1,2,1,3,2,0,3,2,3,0,2,0),
     (2, 4, 5, 6, 7, -1), (5, 7)),
    ((0,1,0,2,1,1,0,1,0,2,2,2,1,3,0,0,1,1,3,1,2,2,2,3,1,0,3,3,3,2,2,2,
      1,1,3,0,3,1,3,0,1,3,3,2,1,1,0,0,1,2,2,2,1,1,1,2,2,0,0,3,2,3,1,3),
     (1, 2, 3, 4, 5, 7), (0, 3)),
    ((2,1,0,3,3,3,2,0,1,2,1,1,1,0,3,1,1,3,3,0,1,2,1,0,0,0,3,0,3,0,3,0,
      1,3,3,3,0,3,2,0,2,1,2,2,2,1,1,3,0,1,0,1,0,1,1,1,1,3,1,0,1,2,3,3),
     (0, 1, 3, 4, 6, 7), (2, 4)),
)

FN1_R3_BOXES = (
    ((0,0,0,3,3,1,1,0,2,0,2,0,0,0,3,2,0,1,2,3,2,2,1,0,3,0,0,0,0,0,2,3,
      3,0,0,1,1,2,3,3,0,1,3,2,0,1,3,3,2,0,0,1,0,2,0,0,0,3,1,3,3,3,3,3),
     (0, 1, 5, 6, 7, -1), (0, 5)),
    ((2,3,2,3,0,2,3,0,2,2,3,0,3,2,0,2,1,0,2,3,1,1,1,0,0,1,0,2,1,2,2,1,
      3,0,2,1,2,3,3,0,3,2,3,1,0,2,1,0,1,2,2,3,0,2,1,3,1,3,0,2,1,1,1,3),
     (2, 3, 4, 6, 7, -1), (6, 7)),
    ((3,0,2,1,1,3,1,2,2,1,2,2,2,0,0,1,2,3,1,0,2,0,0,2,3,1,2,0,0,0,3,0,
      2,1,1,2,0,0,1,2,3,1,1,2,0,1,3,0,3,1,1,0,0,2,3,0,0,0,0,3,2,0,0,0),
     (0, 2, 3, 4, 5, 6), (1, 4)),
    ((0,1,0,0,2,1,3,2,3,3,2,1,0,1,1,1,1,1,0,3,3,1,1,0,0,2,2,1,0,3,3,2,
      1,3,3,0,3,0,2,1,1,2,3,2,2,2,1,0,0,3,3,3,2,2,3,1,0,2,3,0,3,1,1,0),
     (0, 1, 2, 3, 5, 7), (2, 3)),
)

FN1_R4_BOXES = (
    ((1,1,1,1,1,0,1,3,3,2,3,0,1,2,0,2,3,3,0,1,2,1,2,3,0,3,2,3,2,0,1,2,
      0,1,0,3,2,1,3,2,3,1,2,3,2,0,1,2,2,0,0,0,2,1,3,0,3,1,3,0,1,3,3,0),
     (1, 2, 3, 4, 5, 7), (0, 4)),
    ((3,0,0,0,0,1,0,2,3,3,1,3,0,3,1,2,2,2,3,1,0,0,2,0,1,0,2,2,3,3,0,0,
      1,1,3,0,2,3,0,3,0,3,0,2,0,2,0,1,0,3,0,1,3,1,1,0,0,1,3,3,2,2,1,0),
     (0, 1, 2, 3, 5, 6), (1, 3)),
    ((0,1,1,2,0,1,3,1,2,0,3,2,0,0,3,0,3,0,1,2,2,3,3,2,3,2,0,1,0,0,1,0,
      3,0,2,3,0,2,2,2,1,1,0,2,2,0,0,1,2,1,1,1,2,3,0,3,1,2,3,3,1,1,3,0),
     (0, 2, 4, 5, 6, 7), (2, 6)),
    ((0,1,2,2,0,1,0,3,2,2,1,1,3,2,0,2,0,1,3,3,0,2,2,3,3,2,0,0,2,1,3,3,
      1,1,1,3,1,2,1,1,0,3,3,2,3,2,3,0,3,1,0,0,3,0,0,0,2,2,2,1,2,3,0,0),
     (0, 1, 3, 4, 6, 7), (5, 7)),
)

FN2_R1_BOXES = (
    ((2,0,2,0,3,0,0,3,1,1,0,1,3,2,0,1,2,0,1,2,0,2,0,2,2,2,3,0,2,1,3,0,
      0,1,0,1,2,2,3,3,0,3,0,2,3,0,1,2,1,1,0,2,0,3,1,1,2,2,1,3,1,1,3,1),
     (0, 3, 4, 5, 7, -1), (6, 7)),
    ((1,1,0,3,0,2,0,1,3,0,2,0,1,1,0,0,1,3,2,2,0,2,2,2,2,0,1,3,3,3,1,1,
      1,3,1,3,2,2,2,2,2,2,0,1,0,1,1,2,3,1,1,2,0,3,3,3,2,2,3,1,1,1,3,0),
     (1, 2, 3, 4, 6, -1), (3, 5)),
    ((1,0,2,2,3,3,3,3,1,2,2,1,0,1,2,1,1,2,3,1,2,0,0,1,2,3,1,2,0,0,0,2,
      2,0,1,1,0,0,2,0,0,0,2,3,2,3,0,1,3,0,0,0,2,3,2,0,1,3,2,1,3,1,1,3),
     (1, 2, 4, 5, 6, 7), (1, 4)),
    ((1,3,3,0,3,2,3,1,3,2,1,1,3,3,2,1,2,3,0,3,1,0,0,2,3,0,0,0,3,3,0,1,
      2,3,0,0,0,1,2,1,3,0,0,1,0,2,2,2,3,3,1,2,1,3,0,0,0,3,0,1,3,2,2,0),
     (0, 2, 3, 5, 6, 7), (0, 2)),
)

FN2_R2_BOXES = (
    ((3,1,3,0,3,0,3,1,3,0,0,1,1,3,0,3,1,1,0,1,2,3,2,3,3,1,2,2,2,0,2,3,
      2,2,2,1,1,3,3,0,3,1,2,1,1,1,0,2,0,3,3,0,0,2,0,0,1,1,2,1,2,1,1,0),
     (0, 2, 4, 6, -1, -1), (4, 6)),
    ((0,3,0,3,3,2,1,2,3,1,1,1,2,0,2,3,0,3,1,2,2,1,3,3,3,2,1,2,2,0,1,0,
      2,3,0,1,2,0,1,1,2,0,2,1,2,0,2,3,3,1,0,2,3,3,0,3,1,1,3,0,0,1,2,0),
     (1, 3, 4, 5, 6, 7), (0, 3)),
    ((0,0,2,1,3,2,1,0,1,2,2,2,1,1,0,3,1,2,2,3,2,1,1,0,3,0,0,1,1,2,3,1,
      3,3,2,2,1,0,1,1,1,2,0,1,2,3,0,3,3,0,3,2,2,0,2,2,1,2,3,2,1,0,2,1),
     (0, 1, 3, 4, 5, 7), (1, 7)),
    ((0,2,1,2,0,2,2,0,1,3,2,0,3,2,3,0,3,3,2,3,1,2,3,1,2,2,0,0,2,2,1,2,
      2,3,3,3,1,1,0,0,0,3,2,0,3,2,3,1,1,1,1,0,1,0,1,3,0,0,1,2,2,3,2,0),
     (1, 2, 3, 5, 6, 7), (2, 5)),
)

FN2_R3_BOXES = (
    ((2,1,2,1,2,3,1,3,2,2,1,3,3,0,0,1,0,2,0,3,3,1,0,0,1,1,0,2,3,2,1,2,
      1,1,2,1,1,3,2,2,0,2,2,3,3,3,2,0,0,0,0,0,3,3,3,0,1,2,1,0,2,3,3,1),
     (2, 3, 4, 6, -1, -1), (3, 5)),
    ((3,2,3,3,1,0,3,0,2,0,1,1,1,0,3,0,3,1,3,1,0,1,2,3,2,2,3,2,0,1,1,2,
      3,0,0,2,1,0,0,2,2,0,1,0,0,2,0,0,1,3,1,3,2,0,3,3,1,0,2,2,2,3,0,0),
     (0, 1, 3, 5, 7, -1), (0, 2)),
    ((2,2,1,0,2,3,3,0,0,0,1,3,1,2,3,2,2,3,1,3,0,3,0,3,3,2,2,1,0,0,0,2,
      1,2,2,2,0,0,1,2,0,1,3,0,2,3,2,1,3,2,2,2,3,1,3,0,2,0,2,1,0,3,3,1),
     (0, 1, 2, 3, 5, 7), (1, 6)),
    ((1,2,3,2,0,2,1,3,3,1,0,1,1,2,2,0,0,1,1,1,2,1,1,2,0,1,3,3,1,1,1,2,
      3,3,1,0,2,1,1,1,2,1,0,0,2,2,3,2,3,2,2,0,2,2,3,3,0,2,3,0,2,2,1,1),
     (0, 2, 4, 5, 6, 7), (4, 7)),
)

FN2_R4_BOXES = (
    ((2,0,1,1,2,1,3,3,1,1,1,2,0,1,0,2,0,1,2,0,2,3,0,2,3,3,2,2,3,2,0,1,
      3,0,2,0,2,3,1,3,2,0,0,1,1,2,3,1,1,1,0,1,2,0,3,3,1,1,1,3,3,1,1,0),
     (0, 1, 3, 6, 7, -1), (0, 3)),
    ((1,2,2,1,0,3,3,1,0,2,2,2,1,0,1,0,1,1,0,1,0,2,1,0,2,1,0,2,3,2,3,3,
      2,2,1,2,2,3,1,3,3,3,0,1,0,1,3,0,0,0,1,2,0,3,3,2,3,2,1,3,2,1,0,2),
     (0, 1, 2, 4, 5, 6), (4, 7)),
    ((2,3,2,1,3,2,3,0,0,2,1,1,0,0,3,2,3,1,0,1,2,2,2,1,3,2,2,1,0,2,1,2,
      0,3,1,0,0,3,1,1,3,3,2,0,1,0,1,3,0,0,1,2,1,2,3,2,1,0,0,3,2,1,1,3),
     (0, 2, 3, 4, 5, 7), (1, 2)),
    ((2,0,0,3,2,2,2,1,3,3,1,1,2,0,0,3,1,0,3,2,1,0,2,0,3,2,2,3,2,0,3,0,
      1,3,0,2,2,1,3,3,0,1,0,3,1,1,3,2,0,3,0,2,3,2,1,3,2,3,0,0,1,3,2,1),
     (2, 3, 4, 5, 6, 7), (5, 6)),
)

# ── key schedule bit-selection tables ────────────────────────────────────────

EXPAND_1ST_BITS = (
    33, 58, 49, 36,  0, 31, 22, 30,  3, 16,  5, 53,
    10, 41, 23, 19, 27, 39, 43,  6, 34, 12, 61, 21,
    48, 13, 32, 35,  6, 42, 43, 14, 21, 41, 52, 25,
    18, 47, 46, 37, 57, 53, 20,  8, 55, 54, 59, 60,
    27, 33, 35, 18,  8, 15, 63,  1, 50, 44, 16, 46,
     5,  4, 45, 51, 38, 25, 13, 11, 62, 29, 48,  2,
    59, 61, 62, 56, 51, 57, 54,  9, 24, 63, 22,  7,
    26, 42, 45, 40, 23, 14,  2, 31, 52, 28, 44, 17,
)

EXPAND_2ND_BITS = (
    34,  9, 32, 24, 44, 54, 38, 61, 47, 13, 28,  7,
    29, 58, 18,  1, 20, 60, 15,  6, 11, 43, 39, 19,
    63, 23, 16, 62, 54, 40, 31,  3, 56, 61, 17, 25,
    47, 38, 55, 57,  5,  4, 15, 42, 22,  7,  2, 19,
    46, 37, 29, 39, 12, 30, 49, 57, 31, 41, 26, 27,
    24, 36, 11, 63, 33, 16, 56, 62, 48, 60, 59, 32,
    12, 30, 53, 48, 10,  0, 50, 35,  3, 59, 14, 49,
    51, 45, 44,  2, 21, 33, 55, 52, 23, 28,  8, 26,
)

# Each row is a permutation of the 16 seed bits (subkey bit i <- seed bit tbl[i]).
EXPAND_SUBKEY_BITS = (
     5, 10, 14,  9,  4,  0, 15,  6,  1,  8,  3,  2, 12,  7, 13, 11,
     5, 12,  7,  2, 13, 11,  9, 14,  4,  1,  6, 10,  8,  0, 15,  3,
     4, 10,  2,  0,  6,  9, 12,  1, 11,  7, 15,  8, 13,  5, 14,  3,
    14, 11, 12,  7,  4,  5,  2, 10,  1, 15,  0,  9,  8,  6, 13,  3,
)

# ── precomputed machinery ────────────────────────────────────────────────────


def _optimise(box):
    table, inputs, outputs = box
    input_lookup = [
        sum(((val >> inputs[i]) & 1) << i for i in range(6) if inputs[i] >= 0)
        for val in range(256)
    ]
    output = [((o & 1) << outputs[0]) | (((o >> 1) & 1) << outputs[1]) for o in table]
    return input_lookup, output


def _extract_table(bits):
    """16-bit value -> 8-bit (bit i of result = bit bits[i] of value)."""
    return [sum(((v >> bits[i]) & 1) << i for i in range(8)) for v in range(0x10000)]


def _scatter_table(bits):
    """8-bit value -> 16-bit (bit bits[i] of result = bit i of value)."""
    return [sum(((v >> i) & 1) << bits[i] for i in range(8)) for v in range(0x100)]


class _Network:
    def __init__(self, group_a, group_b, round_boxes):
        self.extract_a = _extract_table(group_a)
        self.extract_b = _extract_table(group_b)
        self.scatter_a = _scatter_table(group_a)
        self.scatter_b = _scatter_table(group_b)
        self.rounds = [[_optimise(b) for b in boxes] for boxes in round_boxes]

    def _fn(self, val, boxes, key24):
        r = 0
        for j, (il, out) in enumerate(boxes):
            r |= out[il[val] ^ ((key24 >> (6 * j)) & 0x3F)]
        return r

    def forward(self, val, keys):
        l = self.extract_b[val]
        r = self.extract_a[val]
        l ^= self._fn(r, self.rounds[0], keys[0])
        r ^= self._fn(l, self.rounds[1], keys[1])
        l ^= self._fn(r, self.rounds[2], keys[2])
        r ^= self._fn(l, self.rounds[3], keys[3])
        return self.scatter_a[l] | self.scatter_b[r]

    def inverse(self, val, keys):
        l = self.extract_a[val]
        r = self.extract_b[val]
        r ^= self._fn(l, self.rounds[3], keys[3])
        l ^= self._fn(r, self.rounds[2], keys[2])
        r ^= self._fn(l, self.rounds[1], keys[1])
        l ^= self._fn(r, self.rounds[0], keys[0])
        return self.scatter_b[l] | self.scatter_a[r]


def _expand_key(bits, srckey64):
    dst = [0, 0, 0, 0]
    for i in range(96):
        dst[i // 24] |= ((srckey64 >> bits[i]) & 1) << (i % 24)
    return dst


def _fixup_key1(k):
    k[0] ^= ((k[0] >> 1) & 1) << 4
    k[0] ^= ((k[0] >> 2) & 1) << 5
    k[0] ^= ((k[0] >> 8) & 1) << 11
    k[1] ^= ((k[1] >> 0) & 1) << 5
    k[1] ^= ((k[1] >> 8) & 1) << 11
    k[2] ^= ((k[2] >> 1) & 1) << 5
    k[2] ^= ((k[2] >> 8) & 1) << 11
    return k


def _fixup_key2(k):
    k[0] ^= ((k[0] >> 0) & 1) << 5
    k[0] ^= ((k[0] >> 6) & 1) << 11
    k[1] ^= ((k[1] >> 0) & 1) << 5
    k[1] ^= ((k[1] >> 1) & 1) << 4
    k[2] ^= ((k[2] >> 2) & 1) << 5
    k[2] ^= ((k[2] >> 3) & 1) << 4
    k[2] ^= ((k[2] >> 7) & 1) << 11
    k[3] ^= ((k[3] >> 1) & 1) << 5
    return k


def decode_key(keybytes):
    """20-byte .key file -> (master_key_64, lower_byte, upper_byte, watchdog)."""
    decoded = [0] * 10
    for b in range(160):
        bit = (317 - b) % 160
        if (keybytes[bit // 8] >> ((bit ^ 7) % 8)) & 1:
            decoded[b // 16] |= 0x8000 >> (b % 16)

    master = (
        (decoded[0] << 48) | (decoded[1] << 32) | (decoded[2] << 16) | decoded[3]
    )
    watchdog = (decoded[6], decoded[5], decoded[4])  # 68k words, fetch order
    if decoded[9] == 0xFFFF:
        lower, upper = 0xFF0000, 0xFFFFFF  # dead board
    else:
        lower, upper = 0, ((((~decoded[9]) & 0x3FF) << 14) | 0x3FFF) + 1
    return master, lower, upper, watchdog


class Cipher:
    """Per-key CPS-2 opcode cipher over a whole program image."""

    def __init__(self, keybytes):
        self.master, self.lower, self.upper, self.watchdog = decode_key(keybytes)
        self.fn1 = _Network(FN1_GROUPA, FN1_GROUPB, (FN1_R1_BOXES, FN1_R2_BOXES, FN1_R3_BOXES, FN1_R4_BOXES))
        self.fn2 = _Network(FN2_GROUPA, FN2_GROUPB, (FN2_R1_BOXES, FN2_R2_BOXES, FN2_R3_BOXES, FN2_R4_BOXES))
        # MAME's srckey[0] = decoded[0..1] (high half of master), srckey[1] =
        # decoded[2..3]; expand tables read BIT(srckey[b/32], b%32), so as one
        # 64-bit int: low 32 bits = srckey[0], high 32 = srckey[1].
        self._src64 = ((self.master >> 32) & 0xFFFFFFFF) | ((self.master & 0xFFFFFFFF) << 32)
        self.key1 = _fixup_key1(_expand_key(EXPAND_1ST_BITS, self._src64))

    def _key2_for_seed(self, seed):
        subkey = 0
        for i in range(64):
            subkey |= ((seed >> EXPAND_SUBKEY_BITS[i]) & 1) << i
        subkey ^= self._src64
        return _fixup_key2(_expand_key(EXPAND_2ND_BITS, subkey))

    def crypt_words_at(self, words, base_word, decrypt=True):
        """(De/en)crypt an arbitrary run of 16-bit words as if they lived at
        word address base_word, base_word+1, ... Used to encrypt an injected
        code blob into stored form (decrypt=False) or verify. Words outside
        the key's encrypted range are returned unchanged (raw), matching how
        the CPU would fetch them. Returns a new list."""
        lo, hi = self.lower // 2, self.upper // 2
        fn2 = self.fn2.forward if decrypt else self.fn2.inverse
        # cache key2 per low-16 seed so repeated addresses are cheap
        cache = {}
        out = []
        for k, w in enumerate(words):
            a = base_word + k
            if lo <= a <= hi:
                i = a & 0xFFFF
                key2 = cache.get(i)
                if key2 is None:
                    key2 = cache[i] = self._key2_for_seed(self.fn1.forward(i, self.key1))
                out.append(fn2(w, key2))
            else:
                out.append(w)
        return out

    def transform(self, words, decrypt=True, progress=None):
        """words: list/array of 16-bit ints indexed by word address."""
        nwords = len(words)
        out = array("H", bytes(2 * nwords))
        lo, hi = self.lower // 2, self.upper // 2
        fn2 = self.fn2.forward if decrypt else self.fn2.inverse
        for i in range(0x10000):
            if progress and (i & 0xFFF) == 0:
                progress(i)
            seed = self.fn1.forward(i, self.key1)
            key2 = self._key2_for_seed(seed)
            for a in range(i, nwords, 0x10000):
                if lo <= a <= hi:
                    out[a] = fn2(words[a], key2)
                else:
                    out[a] = words[a]
        return out


# ── set handling ─────────────────────────────────────────────────────────────

# Program members: the stock .03-.10 pair-numbered chips, plus the CPS-2
# WIDE extension members vsw.41-.44. Without the 4x alternation the
# extension was invisible to the build fingerprint, so two WIDE builds
# differing only in extension CONTENT hashed identically — the same blind
# spot 14z-54 found for gfx/QSound. Ordering still works: int("41") sorts
# after int("10"), which is the load order.
# PROGRAM members: .03-.10 (vsavj/vsav2/vhunt2, with revision suffixes a/b/d)
# and .41-.44 (the WIDE extension, unsuffixed).
#
# THE SUFFIX CLASS EXCLUDES 'm' ON PURPOSE (GitHub #19). Gfx members are
# always 'm'-suffixed, and the gfx namer emits vsw.{31+2i}m — which at the
# documented `--gfx 8` growth path (docs/project/M3b_plan.md:219) produces
# vsw.39m, vsw.41m, vsw.43m, vsw.45m. With a bare [a-z]? the middle two
# matched as PROGRAM: load_set/load_stored would concatenate two 4 MB GFX
# members into the 68k blob (every logical word past ~0x400000 wrong),
# build_fingerprint would hash gfx into the dispatch fingerprint, and since
# int('41') is the sort key for BOTH 'vsw.41' and 'vsw.41m' the member ORDER
# would come from namelist order rather than load order. Inert at --gfx 4,
# silently wrong at the next member count the project has already written
# down. No real program member is m-suffixed — measured across all five
# reference sets and a packed vsavjw (suffixes in use: a, b, d, bare).
# build_fingerprint.py:83 already classified 'vsw.NNm' as gfx BEFORE
# consulting this regex; the two classifiers now agree instead.
_PRG_RE = re.compile(r"\.(0[3-9]|10|4[1-4])[a-ln-z]?$")


def program_identity(zpath):
    """Stable identity of a romset zip's PROGRAM members (14z-94, GitHub #18).

    SHA-1 over each program member's NAME, LENGTH and raw bytes, in the same
    load order load_set/load_stored use. Both the generator and patch_prg
    compute it from here so the two can never drift into disagreeing about
    what "the same source set" means.

    Why it exists: a generated patch.json carries only {op, addr, val|hex|path}
    — no expected-old bytes and no source identity — so patch_prg would apply
    those offsets to ANY zip with one .key and at least one program member.
    All the old-byte verification in this project happens in the GENERATOR,
    against the cached decrypted views, and nothing joined that image to the
    one actually patched.
    """
    h = hashlib.sha1()
    with zipfile.ZipFile(zpath) as zf:
        prgs = sorted((n for n in zf.namelist() if _PRG_RE.search(n)),
                      key=lambda n: int(_PRG_RE.search(n).group(1)))
        for n in prgs:
            b = zf.read(n)
            h.update(f"{n}:{len(b)}:".encode())
            h.update(b)
    return h.hexdigest()


def words_from_file_bytes(blob):
    """File storage -> word values: each word is the LE read of its 2 bytes."""
    words = array("H", blob)
    if sys.byteorder == "big":
        words.byteswap()
    return words


def words_from_logical_bytes(blob):
    """Logical (big-endian) image -> word values."""
    words = array("H", blob)
    if sys.byteorder == "little":
        words.byteswap()
    return words


def words_to_logical_bytes(words):
    w = array("H", words)
    if sys.byteorder == "little":
        w.byteswap()
    return w.tobytes()


def words_to_file_bytes(words):
    w = array("H", words)
    if sys.byteorder == "big":
        w.byteswap()
    return w.tobytes()


def load_set(zpath):
    """Return (program_words, keybytes, file_list, sha1s)."""
    sha1s = {}
    with zipfile.ZipFile(zpath) as zf:
        names = zf.namelist()
        keys = [n for n in names if n.endswith(".key")]
        prgs = sorted((n for n in names if _PRG_RE.search(n)),
                      key=lambda n: int(_PRG_RE.search(n).group(1)))
        if len(keys) != 1 or not prgs:
            raise SystemExit(f"{zpath}: expected 1 .key and >=1 program file, got {keys}/{prgs}")
        keybytes = zf.read(keys[0])
        sha1s[keys[0]] = hashlib.sha1(keybytes).hexdigest()
        blob = b""
        for n in prgs:
            data = zf.read(n)
            sha1s[n] = hashlib.sha1(data).hexdigest()
            blob += data
    return words_from_file_bytes(blob), keybytes, prgs, sha1s


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src", type=Path, help="romset zip (decrypt) or raw opcode image (encrypt)")
    ap.add_argument("out", type=Path, help="output raw image (big-endian words)")
    ap.add_argument("--encrypt", action="store_true")
    ap.add_argument("--keyzip", type=Path, help="zip holding the .key (encrypt mode)")
    ap.add_argument("--data-out", type=Path, help="also write the raw stored/data view (decrypt mode)")
    args = ap.parse_args()

    if args.encrypt:
        keysrc = args.keyzip or args.src
        with zipfile.ZipFile(keysrc) as zf:
            keyname = [n for n in zf.namelist() if n.endswith(".key")][0]
            keybytes = zf.read(keyname)
        blob = args.src.read_bytes()
        print(f"read {args.src}  sha1 {hashlib.sha1(blob).hexdigest()}")
        words = words_from_logical_bytes(blob)
        cipher = Cipher(keybytes)
        result = cipher.transform(words, decrypt=False)
        check = cipher.transform(result, decrypt=True)
        assert check == words, "self-check failed: decrypt(encrypt(x)) != x"
        out_bytes = words_to_file_bytes(result)
    else:
        words, keybytes, prgs, sha1s = load_set(args.src)
        for n, s in sha1s.items():
            print(f"read {args.src.name}/{n}  sha1 {s}")
        cipher = Cipher(keybytes)
        print(f"key: master 0x{cipher.master:016x}  encrypted range 0x{cipher.lower:06x}-0x{cipher.upper:06x}")
        print(f"watchdog words: {' '.join(f'{w:04x}' for w in cipher.watchdog)}")
        result = cipher.transform(words, decrypt=True,
                                  progress=lambda i: print(f"\r{i * 100 // 0x10000}%", end="", flush=True))
        print("\rdecrypted; running inverse self-check...")
        check = cipher.transform(result, decrypt=False)
        assert check == words, "self-check failed: encrypt(decrypt(x)) != x"
        if args.data_out:
            args.data_out.write_bytes(words_to_logical_bytes(words))
            print(f"wrote {args.data_out}  sha1 {hashlib.sha1(args.data_out.read_bytes()).hexdigest()}")
        out_bytes = words_to_logical_bytes(result)

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_bytes(out_bytes)
    print(f"wrote {args.out}  sha1 {hashlib.sha1(out_bytes).hexdigest()}  ({len(out_bytes)} bytes)")


if __name__ == "__main__":
    main()
