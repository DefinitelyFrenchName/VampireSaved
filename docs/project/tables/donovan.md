# Donovan (char id 0x13) — extraction manifest & behavioral values

GENERATED — do not edit by hand. Regenerate with:

    python3 tools/tables_char_md.py <build>/extract docs/project/tables/donovan.md

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
| `x05c800` | `+52` (`0x00000034`) |
| `x026142` | `+46` (`0x0000002e`) |
| `x028122` | `+46` (`0x0000002e`) |
| `x2b7ef4` | `-80732` (`0xfffec4a4`) |
| `x065952` | `+52` (`0x00000034`) |
| `x065c22` | `+52` (`0x00000034`) |
| `x065e5a` | `+52` (`0x00000034`) |
| `x066ec4` | `+52` (`0x00000034`) |
| `x06717c` | `+52` (`0x00000034`) |
| `x101aca` | `+0` (`0x00000000`) |
| `aux0` | `-131116` (`0xfffdffd4`) |

## Region manifest

| region | kind | src | orc | length | grow | refs | variant sites | char-id sites | SHA-1 |
|---|---|---|---|---|---|---|---|---|---|
| `hitbox` | data | `PRG:0x0c8bb8` | `PRG:0x0c844a` | `0x25c2` | `0x0` | 0 | 24 | 0 | `0171aada4ed84f85cf3ce92b31815ddf59ff31b4` |
| `hitbox_proj` | data | `PRG:0x0d0ca8` | `PRG:0x0d053a` | `0x1000` | `0x0` | 0 | 0 | 0 | `204dbe67776b3f0b89703fe80dc503ac37d3cedc` |
| `anim` | data | `PRG:0x27f548` | `PRG:0x26b9d4` | `0x20f00` | `0x30000` | 3979 | 0 | 0 | `9ea840774b3111eb107de1abafec842939cc384e` |
| `code` | code | `PRG:0x059490` | `PRG:0x0594c0` | `0x3200` | `0x8000` | 474 | 0 | 0 | `bbfabf4a4ecd29fdc0549ea02e2e1ebc6b2d9418` |
| `x05c800` | code | `PRG:0x05c800` | `PRG:0x05c834` | `0x6a00` | `0xd100` | 723 | 0 | 0 | `92f9dc55ceda3666df2c6f1383462a9f9e9701b5` |
| `x026142` | code | `PRG:0x026142` | `PRG:0x026170` | `0x1400` | `0x1400` | 44 | 0 | 0 | `05b198390f24fc4d84786a7416527e6880473dd5` |
| `x028122` | code | `PRG:0x028122` | `PRG:0x028150` | `0xe00` | `0xe00` | 46 | 0 | 0 | `25f8809c49687e0e954078fb6e4f6841591cc5fb` |
| `x088512` | code | `PRG:0x088512` | `PRG:0x088512` | `0x2f00` | `0x0` | 251 | 0 | 1 | `e1f908111c70cbdb0a24209e959c2bc989d055f4` |
| `x0905ae` | code | `PRG:0x0905ae` | `PRG:0x0905ae` | `0x300` | `0x0` | 10 | 0 | 0 | `4d76aeb99a0d4d18fa817e5e89e378ed0bd3be9b` |
| `x2b7ef4` | data | `PRG:0x2b7ef4` | `PRG:0x2a4398` | `0xb20c` | `0x0` | 2065 | 0 | 0 | `699eb2f851919c838cf26e75bd2c2b2988dee7bb` |
| `x065952` | code | `PRG:0x065952` | `PRG:0x065986` | `0x2d0` | `0x2d0` | 19 | 0 | 0 | `db66917c099dd3d76a884e56883c9ee4037e1c40` |
| `x065c22` | code | `PRG:0x065c22` | `PRG:0x065c56` | `0x100` | `0x238` | 4 | 0 | 0 | `ea3a32e4b4e296c55028649b8f7353a57b5a1f80` |
| `x065e5a` | code | `PRG:0x065e5a` | `PRG:0x065e8e` | `0x106a` | `0x106a` | 92 | 0 | 0 | `e27f25182422522f03384445292027e025635dae` |
| `x066ec4` | code | `PRG:0x066ec4` | `PRG:0x066ef8` | `0x2b8` | `0x2b8` | 16 | 0 | 0 | `d460617ea818d1e16fe684e3cbc78d306e62ef84` |
| `x06717c` | code | `PRG:0x06717c` | `PRG:0x0671b0` | `0x154` | `0x154` | 13 | 0 | 0 | `0ff846f89a3df20042945130270ecae9a5a25408` |
| `x101aca` | data | `PRG:0x101aca` | `PRG:0x101aca` | `0x10ce` | `0x0` | 0 | 0 | 0 | `a34b061531e2452699d34e2ee35afca837f6036e` |
| `aux0_0` | data | `PRG:0x334b80` | `PRG:0x314b54` | `0xf10` | `0x0` | 0 | 0 | 0 | `90dc675a71ffd36d1b3d9e0f8b991da9acc0beb7` |
| `aux0_1` | data | `PRG:0x337460` | `PRG:0x317434` | `0x190` | `0x0` | 0 | 0 | 0 | `d63ade90c05932bf09652c63d9f7d51f4d97a8f5` |
| `aux0_2` | data | `PRG:0x33ccf0` | `PRG:0x31ccc4` | `0x1a0` | `0x0` | 0 | 0 | 0 | `8f61859c3f7aa61c5be2e80155652c7365c4dc5d` |
| `aux0_3` | data | `PRG:0x34cb60` | `PRG:0x32cb34` | `0x190` | `0x0` | 0 | 0 | 0 | `1a0338599d88244cd6e278028bde14fa86397f3e` |
| `aux0_4` | data | `PRG:0x352120` | `PRG:0x3320f4` | `0xe070` | `0x0` | 0 | 0 | 0 | `a6f0ff8a1440739fde36775d445bf49ff91d9a2a` |

## Dispatch targets (the per-character code-pointer rows, source -> oracle)

| table | src target | orc target |
|---|---|---|
| `dispatch_00` | `PRG:0x05ae20` | `PRG:0x05ae50` |
| `dispatch_01` | `PRG:0x05949a` | `PRG:0x0594ca` |
| `dispatch_02` | `PRG:0x059d54` | `PRG:0x059d84` |
| `dispatch_03` | `PRG:0x059d54` | `PRG:0x059d84` |
| `dispatch_04` | `PRG:0x059d54` | `PRG:0x059d84` |
| `dispatch_05` | `PRG:0x05a802` | `PRG:0x05a832` |
| `dispatch_06` | `PRG:0x05988c` | `PRG:0x0598bc` |
| `dispatch_07` | `PRG:0x05aaa0` | `PRG:0x05aad0` |
| `dispatch_08` | `PRG:0x059920` | `PRG:0x059950` |
| `dispatch_09` | `PRG:0x059a22` | `PRG:0x059a52` |
| `dispatch_10` | `PRG:0x0597c2` | `PRG:0x0597f2` |
| `dispatch_11` | `PRG:0x05abea` | `PRG:0x05ac1a` |
| `dispatch_12` | `PRG:0x05ad8c` | `PRG:0x05adbc` |
| `dispatch_13` | `PRG:0x05add6` | `PRG:0x05ae06` |
| `dispatch_14` | `PRG:0x05ab64` | `PRG:0x05ab94` |
| `dispatch_15` | `PRG:0x059944` | `PRG:0x059974` |
| `dispatch_16` | `PRG:0x05ae8c` | `PRG:0x05aebc` |
| `dispatch_17` | `PRG:0x05aec8` | `PRG:0x05aef8` |
| `dispatch_18` | `PRG:0x05af14` | `PRG:0x05af44` |
| `dispatch_19` | `PRG:0x05aef6` | `PRG:0x05af26` |

## VS2-vs-VH2 variant sites (maintainer-facing: where per-game flavour lives)

Bytes that DIFFER between the source and oracle sets inside a ported region and are NOT explained by a pointer shift. The port ships the SOURCE value. A candidate 'VS2 vs VH2 flavour' tunable set — SPEC §3 variant policy.

| region | offset in region | vsav2 byte | vhunt2 byte |
|---|---|---|---|
| `hitbox` | `+0x24bd` | `07` | `04` |
| `hitbox` | `+0x24cc` | `07` | `00` |
| `hitbox` | `+0x24cd` | `09` | `00` |
| `hitbox` | `+0x2535` | `13` | `08` |
| `hitbox` | `+0x253d` | `14` | `04` |
| `hitbox` | `+0x2544` | `07` | `00` |
| `hitbox` | `+0x2545` | `15` | `00` |
| `hitbox` | `+0x254d` | `16` | `04` |
| `hitbox` | `+0x2555` | `17` | `04` |
| `hitbox` | `+0x255d` | `18` | `04` |
| `hitbox` | `+0x2565` | `19` | `04` |
| `hitbox` | `+0x256d` | `1A` | `05` |
| `hitbox` | `+0x257c` | `07` | `00` |
| `hitbox` | `+0x257d` | `1C` | `00` |
| `hitbox` | `+0x259c` | `07` | `00` |
| `hitbox` | `+0x259d` | `50` | `00` |
| `hitbox` | `+0x25a4` | `07` | `00` |
| `hitbox` | `+0x25a5` | `51` | `00` |
| `hitbox` | `+0x25ac` | `07` | `00` |
| `hitbox` | `+0x25ad` | `52` | `00` |
| `hitbox` | `+0x25b4` | `07` | `00` |
| `hitbox` | `+0x25b5` | `53` | `00` |
| `hitbox` | `+0x25bc` | `07` | `00` |
| `hitbox` | `+0x25bd` | `57` | `00` |

## Per-character values (row 0x13 of each 32-row table — the tunables)

`value*`/`rec8`/`byte2d` rows are COPIED into the build (never repointed); `*_ptr` rows are the source-set pointers the port repoints to the relocated copy.

| table | vsavj row base | kind | value / pointer |
|---|---|---|---|
| `anim_index_a` | `PRG:0x0bce7a` | data_ptr | `0x27f548` |
| `anim_index_a2` | `PRG:0x0bcefa` | data_ptr | `0x281696` |
| `anim_index_b` | `PRG:0x0bcf7a` | data_ptr | `0x28709c` |
| `anim_index_c` | `PRG:0x0bcffa` | data_ptr | `0x287192` |
| `anim_index_proj` | `PRG:0x0bd07a` | data_ptr | `0x289ef6` |
| `param32_a` | `PRG:0x0bd87a` | rec8 | `00030000 FFFD6000` |
| `jump_params` | `PRG:0x0bdb7a` | rec8 | `00000000 00000000 0007C000 FFFFA000 00040000 FFFFFB00 0007E000 FFFFA000 FFFBC000 00000500 00080000 FFFFA000` |
| `hitbox_base` | `PRG:0x0bd97a` | data_ptr | `0xc8df8` |
| `hitbox_comp` | `PRG:0x0bd9fa` | data_ptr | `0xc8bb8` |
| `proj_hitbox_base` | `PRG:0x0bda7a` | data_ptr | `0xd0ca8` |
| `proj_hitbox_comp` | `PRG:0x0bdafa` | data_ptr | `0xd1002` |
| `rec8_a` | `PRG:0x0bdb7a` | rec8 | `00080000 FFFFA600` |
| `word132` | `PRG:0x0be17a` | value16 | `0018` |
| `word_pos_a` | `PRG:0x0be1ba` | value16 | `0010` |
| `word_pos_b` | `PRG:0x0be1fa` | value16 | `0008` |
| `capture_kf_ptr` | `PRG:0x0be27a` | data_ptr | `0xca1ca` |
| `param32_b` | `PRG:0x0be2fa` | rec8 | `00020000 FFFD6000` |
| `rec8_b` | `PRG:0x0be3fa` | rec8 | `00096000 FFFF8400` |
| `word_y_off` | `PRG:0x0be7fa` | value16 | `0000` |
| `word_range` | `PRG:0x0be83a` | value16 | `0000` |
| `byte15b` | `PRG:0x0be87a` | value8 | `3C` |
| `byte2d_a` | `PRG:0x0be89a` | byte2d | `0A0A0303 03030A0A 0A0A0303 0A0A030A 0A030303 030A0A03 0303030A 0A03` |
| `byte2d_b` | `PRG:0x0bec5a` | byte2d | `0C0C0303 03030C0C 0C0C0303 0C0C030C 0C030303 030C0C03 0303030C 0C03` |
| `tail_code_ptr` | `PRG:0x0bf29a` | code_ptr | `0x59adc` |
| `tail_data_ptr` | `PRG:0x0bf41a` | data_ptr | `0xcb01a` |
| `ai_script_0` | `PRG:0x0bf01a` | data_ptr | `0x101aca` |
| `ai_script_1` | `PRG:0x0bf09a` | data_ptr | `0x101bc8` |
| `ai_script_2` | `PRG:0x0bf11a` | data_ptr | `0x102674` |
| `ai_script_3` | `PRG:0x0bf19a` | data_ptr | `0x102b82` |

## Gap tables classified by the oracle (`auto` kind — no documented consumer)

| table | verdict | entry (first) |
|---|---|---|
| `gap_bd8fa` | values | `fffde000` |
| `gap_bdc7a` | values | `ffffec00` |
| `gap_bdcfa` | values | `ffff9400` |
| `gap_bdd7a` | values | `ffffa000` |
| `gap_bddfa` | values | `ffff9a00` |
| `gap_bde7a` | values | `ffff9000` |
| `gap_bdefa` | values | `ffff8400` |
| `gap_bdf7a` | values | `ffffec00` |
| `gap_bdffa` | values | `ffff9c00` |
| `gap_be07a` | values | `ffffa000` |
| `gap_be0fa` | values | `ffff9a00` |
| `gap_be23a` | values | `0000` |
| `gap_be37a` | values | `fffde000` |
| `gap_be4fa` | values | `ffff8300` |
| `gap_be57a` | values | `ffffa000` |
| `gap_be5fa` | values | `ffff7000` |
| `gap_be67a` | values | `ffffe000` |
| `gap_be6fa` | values | `ffff8300` |
| `gap_be77a` | values | `ffffa000` |

Provenance of every byte above: `VS2` (source set) validated against `VH2` (oracle) — CLAUDE.md §2 rule 4. Consumers and semantics: `docs/game/atlas/character_tables.md`.
