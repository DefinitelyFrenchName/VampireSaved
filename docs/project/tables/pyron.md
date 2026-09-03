# Pyron (char id 0x11) — extraction manifest & behavioral values

GENERATED — do not edit by hand. Regenerate with:

    python3 tools/tables_char_md.py <build>/extract docs/project/tables/pyron.md

Source set `vsav2`, oracle set `vhunt2` (`tools/extract_char.py`; every region is oracle-validated — see the tool's header). Row addresses are vsavj, from `build/manifest/bank_map.toml`; region addresses are vsav2 (`src`) and vhunt2 (`orc`).

## Inputs (SHA-1 of every member the extractor read)

| member | SHA-1 |
|---|---|
| `vs2j.03` | `a52f40618d7f12f1df5862ad8e15fea60bef22a2` |
| `vs2j.04` | `bf5c2e4339e1a66b3c819900cc9b723a537adf6b` |
| `vs2j.05` | `4d5625a9a06926c1a42c8f6e3a4c943f17750ec2` |
| `vs2j.06` | `d8c1040a6ee6b9fc677a6a32b99bf02b6a707812` |
| `vs2j.07` | `69dac07e1f483b6478f792d20a137d6a081fbea3` |
| `vs2j.08` | `de1184ab771c6f075cdefa744a28b09f78d91643` |
| `vs2j.09` | `0e9dd54e401e6d7c4fe81107ffd27e42ca810fcb` |
| `vs2j.10` | `bf0416df66a33c7a4678ab4a047de334dfd3b31e` |
| `vsav2.key` | `35779f0284dc15591493c8ec75ecda801148f3e0` |

## Measured shifts (oracle − source, bytes)

| region class | shift |
|---|---|
| `code` | `+48` (`0x00000030`) |
| `bank` | `-1902` (`0xfffff892`) |
| `anim` | `-80756` (`0xfffec48c`) |
| `x0d143e` | `-1902` (`0xfffff892`) |
| `x05c800` | `+52` (`0x00000034`) |
| `x026142` | `+46` (`0x0000002e`) |
| `x028122` | `+46` (`0x0000002e`) |
| `x2b7ef4` | `-80732` (`0xfffec4a4`) |
| `x0672d0` | `+52` (`0x00000034`) |
| `x067550` | `+52` (`0x00000034`) |
| `x067846` | `+52` (`0x00000034`) |
| `x067a00` | `+52` (`0x00000034`) |
| `x06800c` | `+52` (`0x00000034`) |
| `x068458` | `+52` (`0x00000034`) |
| `x068768` | `+52` (`0x00000034`) |
| `x0689cc` | `+52` (`0x00000034`) |
| `x068c78` | `+52` (`0x00000034`) |
| `x069046` | `+52` (`0x00000034`) |
| `x0692f6` | `+52` (`0x00000034`) |
| `x06965e` | `+52` (`0x00000034`) |
| `x100e3c` | `+0` (`0x00000000`) |
| `aux0` | `-131116` (`0xfffdffd4`) |

## Region manifest

| region | kind | src | orc | length | grow | refs | variant sites | char-id sites | SHA-1 |
|---|---|---|---|---|---|---|---|---|---|
| `hitbox` | data | `PRG:0x0c7502` | `PRG:0x0c6d94` | `0x16b6` | `0x0` | 0 | 0 | 0 | `1e553b2cc025b02ce126bcc639e250a8be22b11e` |
| `hitbox_proj` | data | `PRG:0x0d0986` | `PRG:0x0d0218` | `0x322` | `0x0` | 0 | 0 | 0 | `4414316fe7cdd1b069947b5ec73a94d49b44914e` |
| `anim` | data | `PRG:0x264086` | `PRG:0x250512` | `0x1b500` | `0x30000` | 2660 | 0 | 0 | `c3bde06fb8811cb55a21b5a823a441ec384701fe` |
| `code` | code | `PRG:0x0574c0` | `PRG:0x0574f0` | `0x5200` | `0x8000` | 776 | 4 | 0 | `7613fc93be3a278902ea7a12b01a7dd8a0b7d684` |
| `x0d143e` | data | `PRG:0x0d143e` | `PRG:0x0d0cd0` | `0x900` | `0x0` | 0 | 0 | 0 | `fcdd9c20018ea704bd3680e8b3400360e9a27ff1` |
| `x05c800` | code | `PRG:0x05c800` | `PRG:0x05c834` | `0x6a00` | `0xd100` | 723 | 0 | 0 | `92f9dc55ceda3666df2c6f1383462a9f9e9701b5` |
| `x026142` | code | `PRG:0x026142` | `PRG:0x026170` | `0x1400` | `0x1400` | 44 | 0 | 0 | `05b198390f24fc4d84786a7416527e6880473dd5` |
| `x028122` | code | `PRG:0x028122` | `PRG:0x028150` | `0xe00` | `0xe00` | 46 | 0 | 0 | `25f8809c49687e0e954078fb6e4f6841591cc5fb` |
| `x088512` | code | `PRG:0x088512` | `PRG:0x088512` | `0x3b40` | `0x0` | 333 | 0 | 0 | `c5cb8f8b2a6e4ec2f580ab8677e3e028db8b36e9` |
| `x2b7ef4` | data | `PRG:0x2b7ef4` | `PRG:0x2a4398` | `0xb20c` | `0x0` | 2065 | 0 | 0 | `699eb2f851919c838cf26e75bd2c2b2988dee7bb` |
| `x0672d0` | code | `PRG:0x0672d0` | `PRG:0x067304` | `0x280` | `0x280` | 14 | 0 | 0 | `30cd1a201195fa289112977db03a665673cb7989` |
| `x067550` | code | `PRG:0x067550` | `PRG:0x067584` | `0x2f6` | `0x2f6` | 18 | 0 | 0 | `2f0e6b3267d4e1a8acd2b84de1f7782edcea6670` |
| `x067846` | code | `PRG:0x067846` | `PRG:0x06787a` | `0x1ba` | `0x1ba` | 17 | 0 | 0 | `0ae86ca393fb23ec3043e66519313d732f33a99c` |
| `x067a00` | code | `PRG:0x067a00` | `PRG:0x067a34` | `0x60c` | `0x60c` | 50 | 0 | 0 | `ee39ac82861f490ed74327dd4875bb915e5d4618` |
| `x06800c` | code | `PRG:0x06800c` | `PRG:0x068040` | `0x44c` | `0x44c` | 20 | 0 | 0 | `aaea98f8edb1f7e3bb7beb869cce00fc4e1b55c1` |
| `x068458` | code | `PRG:0x068458` | `PRG:0x06848c` | `0x310` | `0x310` | 18 | 0 | 0 | `44d8cc3037c81459953a8d2c8b87abc064add881` |
| `x068768` | code | `PRG:0x068768` | `PRG:0x06879c` | `0x264` | `0x264` | 13 | 0 | 0 | `54c901e3b8d43be650dfd86aaa26854e77b7b6af` |
| `x0689cc` | code | `PRG:0x0689cc` | `PRG:0x068a00` | `0x2ac` | `0x2ac` | 16 | 0 | 0 | `4a987f2a331f203eb6ddb08ce3db0be929b32775` |
| `x068c78` | code | `PRG:0x068c78` | `PRG:0x068cac` | `0x3ce` | `0x3ce` | 17 | 0 | 0 | `1d65977a03425804216a9b118b039754bf872602` |
| `x069046` | code | `PRG:0x069046` | `PRG:0x06907a` | `0x2b0` | `0x2b0` | 19 | 0 | 0 | `e66315313a352faf0b466ed2a50f2288ba9fa963` |
| `x0692f6` | code | `PRG:0x0692f6` | `PRG:0x06932a` | `0x368` | `0x368` | 25 | 0 | 0 | `a91894517d7a57613e66ec3409ec39463af9e67a` |
| `x06965e` | code | `PRG:0x06965e` | `PRG:0x069692` | `0x100` | `0x400` | 8 | 0 | 0 | `3483340bb663b54f905d9f3adea3dd4d8f763d08` |
| `x100e3c` | data | `PRG:0x100e3c` | `PRG:0x100e3c` | `0xc8e` | `0x0` | 0 | 0 | 0 | `483a5c39fa2200e61bfca5f05543683a268c42af` |
| `aux0_0` | data | `PRG:0x334170` | `PRG:0x314144` | `0x190` | `0x0` | 0 | 0 | 0 | `41dfcc6bc3ea45a5e332ee9fdb32db5dc529bc24` |
| `aux0_1` | data | `PRG:0x33cd00` | `PRG:0x31ccd4` | `0x190` | `0x0` | 0 | 0 | 0 | `8712decee91c06b48122cc619669efa736425462` |
| `aux0_2` | data | `PRG:0x344a60` | `PRG:0x324a34` | `0xd830` | `0x0` | 0 | 0 | 0 | `24d3cf8344427859aa93d67e9c7874864395ee1a` |

## Dispatch targets (the per-character code-pointer rows, source -> oracle)

| table | src target | orc target |
|---|---|---|
| `dispatch_00` | `PRG:0x059424` | `PRG:0x059454` |
| `dispatch_01` | `PRG:0x0574ce` | `PRG:0x0574fe` |
| `dispatch_02` | `PRG:0x057cf0` | `PRG:0x057d20` |
| `dispatch_03` | `PRG:0x057cf0` | `PRG:0x057d20` |
| `dispatch_04` | `PRG:0x057cf0` | `PRG:0x057d20` |
| `dispatch_05` | `PRG:0x058dd2` | `PRG:0x058e02` |
| `dispatch_06` | `PRG:0x057852` | `PRG:0x057882` |
| `dispatch_08` | `PRG:0x057c74` | `PRG:0x057ca4` |
| `dispatch_09` | `PRG:0x0579c2` | `PRG:0x0579f2` |
| `dispatch_10` | `PRG:0x0577c0` | `PRG:0x0577f0` |
| `dispatch_11` | `PRG:0x05921c` | `PRG:0x05924c` |
| `dispatch_12` | `PRG:0x05933a` | `PRG:0x05936a` |
| `dispatch_13` | `PRG:0x0593ee` | `PRG:0x05941e` |
| `dispatch_14` | `PRG:0x058fdc` | `PRG:0x05900c` |
| `dispatch_15` | `PRG:0x057940` | `PRG:0x057970` |
| `dispatch_16` | `PRG:0x058d28` | `PRG:0x058d58` |
| `dispatch_17` | `PRG:0x058d90` | `PRG:0x058dc0` |
| `dispatch_18` | `PRG:0x059462` | `PRG:0x059492` |
| `dispatch_19` | `PRG:0x058dc6` | `PRG:0x058df6` |

## VS2-vs-VH2 variant sites (maintainer-facing: where per-game flavour lives)

Bytes that DIFFER between the source and oracle sets inside a ported region and are NOT explained by a pointer shift. The port ships the SOURCE value. A candidate 'VS2 vs VH2 flavour' tunable set — SPEC §3 variant policy.

| region | offset in region | vsav2 byte | vhunt2 byte |
|---|---|---|---|
| `code` | `+0x0001` | `82` | `B0` |
| `code` | `+0x0521` | `42` | `48` |
| `code` | `+0x052f` | `3C` | `40` |
| `code` | `+0x054b` | `36` | `38` |

## Per-character values (row 0x11 of each 32-row table — the tunables)

`value*`/`rec8`/`byte2d` rows are COPIED into the build (never repointed); `*_ptr` rows are the source-set pointers the port repoints to the relocated copy.

| table | vsavj row base | kind | value / pointer |
|---|---|---|---|
| `anim_index_a` | `PRG:0x0bce7a` | data_ptr | `0x264086` |
| `anim_index_a2` | `PRG:0x0bcefa` | data_ptr | `0x2695d0` |
| `anim_index_b` | `PRG:0x0bcf7a` | data_ptr | `0x266554` |
| `anim_index_c` | `PRG:0x0bcffa` | data_ptr | `0x265fd0` |
| `anim_index_proj` | `PRG:0x0bd07a` | data_ptr | `0x26d5b4` |
| `param32_a` | `PRG:0x0bd87a` | rec8 | `00040000 FFFC8000` |
| `jump_params` | `PRG:0x0bdb7a` | rec8 | `00000000 00000000 00086000 FFFF9000 0005C000 FFFFF500 00088000 FFFF9000 FFFA4000 00000B00 0008A000 FFFF9000` |
| `hitbox_base` | `PRG:0x0bd97a` | data_ptr | `0xc75fe` |
| `hitbox_comp` | `PRG:0x0bd9fa` | data_ptr | `0xc7502` |
| `proj_hitbox_base` | `PRG:0x0bda7a` | data_ptr | `0xd098e` |
| `proj_hitbox_comp` | `PRG:0x0bdafa` | data_ptr | `0xd0986` |
| `rec8_a` | `PRG:0x0bdb7a` | rec8 | `000B0000 FFFF7000` |
| `word132` | `PRG:0x0be17a` | value16 | `0018` |
| `word_pos_a` | `PRG:0x0be1ba` | value16 | `0010` |
| `word_pos_b` | `PRG:0x0be1fa` | value16 | `0008` |
| `capture_kf_ptr` | `PRG:0x0be27a` | data_ptr | `0xc7f98` |
| `param32_b` | `PRG:0x0be2fa` | rec8 | `00020000 FFFD6000` |
| `rec8_b` | `PRG:0x0be3fa` | rec8 | `00094000 FFFF8400` |
| `word_y_off` | `PRG:0x0be7fa` | value16 | `004E` |
| `word_range` | `PRG:0x0be83a` | value16 | `0028` |
| `byte15b` | `PRG:0x0be87a` | value8 | `3C` |
| `byte2d_a` | `PRG:0x0be89a` | byte2d | `0A0A0A03 03030A0A 03030303 0A0A030A 0A030A0A 030A0A03 0A0A030A 0A03` |
| `byte2d_b` | `PRG:0x0bec5a` | byte2d | `0C0C0C03 03030C0C 03030303 0C0C030C 0C030C0C 030C0C03 0C0C030C 0C03` |
| `tail_code_ptr` | `PRG:0x0bf29a` | code_ptr | `0x57ab2` |
| `tail_data_ptr` | `PRG:0x0bf41a` | data_ptr | `0xc8b18` |
| `ai_script_0` | `PRG:0x0bf01a` | data_ptr | `0x100e3c` |
| `ai_script_1` | `PRG:0x0bf09a` | data_ptr | `0x100f28` |
| `ai_script_2` | `PRG:0x0bf11a` | data_ptr | `0x101814` |
| `ai_script_3` | `PRG:0x0bf19a` | data_ptr | `0x101ab4` |

## Gap tables classified by the oracle (`auto` kind — no documented consumer)

| table | verdict | entry (first) |
|---|---|---|
| `gap_bd8fa` | values | `fffde000` |
| `gap_bdc7a` | values | `00000000` |
| `gap_bdcfa` | values | `fffffb00` |
| `gap_bdd7a` | values | `00000000` |
| `gap_bddfa` | values | `00000500` |
| `gap_bde7a` | values | `fffff500` |
| `gap_bdefa` | values | `00000000` |
| `gap_bdf7a` | values | `00000000` |
| `gap_bdffa` | values | `fffffb00` |
| `gap_be07a` | values | `00000000` |
| `gap_be0fa` | values | `00000500` |
| `gap_be23a` | values | `0000` |
| `gap_be37a` | values | `fffde000` |
| `gap_be4fa` | values | `00000000` |
| `gap_be57a` | values | `00000000` |
| `gap_be5fa` | values | `00000000` |
| `gap_be67a` | values | `00000000` |
| `gap_be6fa` | values | `00000000` |
| `gap_be77a` | values | `00000000` |

Provenance of every byte above: `VS2` (source set) validated against `VH2` (oracle) — CLAUDE.md §2 rule 4. Consumers and semantics: `docs/game/atlas/character_tables.md`.
