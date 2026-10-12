#!/usr/bin/env python3
"""One-shot writer for combat item .tres + 48x48 8-band placeholder icons.
Source of truth remains plans/combat/AXEL_COMBAT_ITEM_CATALOG_PLAN.md.
Run from repo: python AXEL/axel_project/tools/combat/generate_item_resources.py
"""
from __future__ import annotations

import os
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ITEMS_DIR = ROOT / "combat" / "data" / "items"
ICONS_DIR = ROOT / "combat" / "art" / "item_icons"
SCRIPT = "res://combat/scripts/item_def.gd"

PAL = [
    (230, 0, 0),
    (178, 0, 0),
    (128, 0, 0),
    (77, 0, 0),
    (46, 5, 5),
    (20, 3, 3),
    (5, 0, 0),
    (0, 0, 0),
]
WHITE = (255, 255, 255)

ITEMS = [
    ("C1", "C1_ash_spin_token", "Ash Spin Token", 0, "spinpay",
     "Each paid spin makes wins pay 10% more this fight (up to +40%).",
     "paid_spin_payout_scalar", {"per_paid_spin": 0.06, "cap": 0.36}),
    ("C2", "C2_chalk_dust", "Chalk Dust", 0, "",
     "Normal symbols pay 10% more.",
     "normal_payout_bonus", {"amount": 0.10}),
    ("C3", "C3_locker_map_pin", "Locker Map Pin", 0, "",
     "Normal symbols appear 10% more often.",
     "spawn_weight_normals", {"amount": 0.08}),
    ("C4", "C4_static_spark", "Static Spark", 0, "",
     "+5% chance each spin that a random power activates.",
     "girl_power_chance", {"amount": 0.05}),
    ("C5", "C5_burn_mark", "Burn Mark", 0, "",
     "After 2 spins with no power, the next spin gets +10% chance that a power activates.",
     "dead_spin_power_catchup", {"spins": 2, "amount": 0.08}),
    ("C6", "C6_cigarette_stub", "Cigarette Stub", 0, "cigarette",
     "Cigarette symbols pay 10% more.",
     "power_payout_bonus", {"power": "cigarette", "amount": 0.10}),
    ("C7", "C7_broken_bottle_cap", "Broken Bottle Cap", 0, "alcohol",
     "Alcohol symbols pay 10% more.",
     "power_payout_bonus", {"power": "alcohol", "amount": 0.10}),
    ("C8", "C8_bloody_gauze", "Bloody Gauze", 0, "bloody_hand",
     "Bloody hand symbols pay 10% more.",
     "power_payout_bonus", {"power": "bloody_hand", "amount": 0.10}),
    ("C9", "C9_dusty_battery", "Dusty Battery", 0, "",
     "After your first spin with no win each fight, Power symbols appear 10% more often on the next spin.",
     "first_dead_power_spawn", {"amount": 0.06}),
    ("C10", "C10_tarnished_coin", "Tarnished Coin", 0, "",
     "Your first paid spin each fight gives back 25% of the BET.",
     "first_paid_spin_refund", {"amount": 0.25}),
    ("U1", "U1_filtered_spinner", "Filtered Spinner", 1, "spinpay",
     "Each paid spin makes wins pay 10% more this fight (up to +60%).",
     "paid_spin_payout_scalar", {"per_paid_spin": 0.15, "cap": 0.90}),
    ("U2", "U2_iron_lighter", "Iron Lighter", 1, "",
     "Normal symbols pay 20% more.",
     "normal_payout_bonus", {"amount": 0.20}),
    ("U3", "U3_weighted_trinity_die", "Weighted Vice Die", 1, "",
     "Power symbols appear 10% more often.",
     "power_symbol_weight", {"amount": 0.10}),
    ("U4", "U4_faulty_relay", "Faulty Relay", 1, "",
     "+10% chance each spin that a random power activates.",
     "girl_power_chance", {"amount": 0.10}),
    ("U5", "U5_split_wick", "Split Wick", 1, "",
     "When a Wild is made, 25% chance to make one more Wild nearby.",
     "extra_wild_on_create", {"chance": 0.25}),
    ("U6", "U6_cigarette_charm", "Cigarette Charm", 1, "cigarette",
     "Cigarette symbols appear 15% more often. The cigarette power has a 20% chance to burn one more set of Normal symbols.",
     "power_charm", {"power": "cigarette", "spawn_chance": 0.12, "extra_set_chance": 0.20}),
    ("U7", "U7_alcohol_charm", "Alcohol Charm", 1, "alcohol",
     "Alcohol symbols appear 15% more often. The alcohol power has a 30% chance to add 1 more Wild.",
     "power_charm", {"power": "alcohol", "spawn_chance": 0.12, "extra_wild_chance": 0.30}),
    ("U8", "U8_bloody_hand_charm", "Bloody Hand Charm", 1, "bloody_hand",
     "Bloody hand symbols appear 15% more often. The bloody hand power has a 25% chance to change 1 more symbol.",
     "power_charm", {"power": "bloody_hand", "spawn_chance": 0.12, "extra_transform_chance": 0.25}),
    ("R1", "R1_fractured_reel", "Fractured Reel", 2, "spinpay",
     "Your first paid spin each fight is free. Each paid spin makes wins pay 10% more (up to +100%).",
     "paid_spin_payout_scalar", {"per_paid_spin": 0.20, "cap": 99.0, "first_free": True}),
    ("R2", "R2_gilded_commons", "Gilded Commons", 2, "",
     "Normal symbols pay 35% more and appear 10% more often.",
     "normal_payout_bonus", {"amount": 0.35, "weight": 0.10}),
    ("R3", "R3_triune_sigil", "Triune Sigil", 2, "",
     "Power symbols appear 15% more often and pay 15% more.",
     "power_symbol_weight", {"amount": 0.15, "payout": 0.15}),
    ("R4", "R4_glitch_button", "Glitch Button", 2, "",
     "Random powers activate twice as often.",
     "girl_power_chance", {"mode": "double"}),
    ("R5", "R5_chain_wildseed", "Chain Wildseed", 2, "",
     "Every 3rd Wild made in a fight makes one more Wild.",
     "extra_wild_on_create", {"every_nth": 2}),
    ("R6", "R6_trinity_echo", "Vice Echo", 2, "",
     "When a random power activates, 30% chance a second one activates at 50% strength.",
     "trinity_echo", {"chance": 0.30, "potency": 0.50}),
    ("E1", "E1_ash_crown", "Ash Crown", 3, "",
     "Power symbols appear 20% more often, and powers are 25% stronger.",
     "power_symbol_weight", {"amount": 0.20, "potency": 0.25}),
    ("E2", "E2_null_gravity_pin", "Null Gravity Pin", 3, "",
     "After a spin with no win, 40% chance a random power activates.",
     "null_gravity", {"chance": 0.40}),
    ("E3", "E3_echo_loom", "Echo Loom", 3, "",
     "The first Wild made each spin makes a second Wild next to it.",
     "extra_wild_on_create", {"first_each_spin": True}),
    ("E4", "E4_overflow_ledger", "Overflow Ledger", 3, "spinpay",
     "Each paid spin makes wins pay 15% more this fight (up to +150%). Power symbols also appear 5% more often.",
     "paid_spin_payout_scalar", {"per_paid_spin": 0.30, "cap": 99.0, "power_symbol_chance": 0.02}),
    ("L1", "L1_twin_pentagram", "Twin Pentagram", 4, "",
     "Every time a Wild is made, one more Wild is made.",
     "extra_wild_on_create", {"always": True}),
    ("L2", "L2_trinity_overclock", "Vice Overclock", 4, "",
     "When a power activates, both other powers also activate at full strength (once per spin).",
     "power_chain", {"chance": 1.0, "potency": 1.0, "other_count": 2, "once_per_spin": True}),
    ("L3", "L3_void_satchel", "Void Satchel", 4, "",
     "Gives you 2 more item slots (up to 9).",
     "extra_inventory_slots", {"bonus_slots": 2}),
    ("C-A", "C-A_echo_splinter", "Echo Splinter", 0, "A",
     "When a power activates, 20% chance another power also activates at 25% strength.",
     "power_chain", {"chance": 0.20, "potency": 0.25, "other_count": 1}),
    ("U-A", "U-A_echo_fuse", "Echo Fuse", 1, "A",
     "When a power activates, 35% chance another power also activates at 35% strength.",
     "power_chain", {"chance": 0.35, "potency": 0.35, "other_count": 1}),
    ("R-A", "R-A_echo_relay", "Echo Relay", 2, "A",
     "When a power activates, one other power also activates at 50% strength.",
     "power_chain", {"chance": 1.0, "potency": 0.50, "other_count": 1}),
    ("E-A", "E-A_trinity_relay_spine", "Vice Relay Spine", 3, "A",
     "When a power activates, both other powers also activate at 50% strength.",
     "power_chain", {"chance": 1.0, "potency": 0.50, "other_count": 2}),
    ("C-B", "C-B_meter_scratch", "Meter Scratch", 0, "B",
     "Your first Power symbol win each spin fills 1 extra Skull Meter step.",
     "premium_meter", {"first_line_bonus": 1}),
    ("U-B", "U-B_meter_hook", "Meter Hook", 1, "B",
     "Power symbol wins fill the Skull Meter 25% more.",
     "premium_meter", {"gain_mult": 1.25}),
    ("R-B", "R-B_meter_coil", "Meter Coil", 2, "B",
     "Power symbol wins fill 1 extra Skull Meter step.",
     "premium_meter", {"length_boost": 1}),
    ("E-B", "E-B_meter_furnace", "Meter Furnace", 3, "B",
     "Any Power symbol win fills the whole Skull Meter.",
     "premium_meter", {"any_line_fills": True, "wild_extra": 1}),
    ("L-B", "L-B_meter_blood_moon", "Meter Blood Moon", 4, "B",
     "Your first Power symbol win each spin fills 1 Skull Meter step. The Skull Meter can fill past full.",
     "premium_meter", {"first_fills_section": True, "overflow": True}),
    ("C-C", "C-C_trinity_ash", "Vice Ash", 0, "C",
     "In the Vice Round, Normal symbols pay 15% more.",
     "trinity_run", {"normal_payout": 0.15}),
    ("U-C", "U-C_trinity_matchbook", "Vice Matchbook", 1, "C",
     "If the Vice Round's first spin has no win, you get 1 extra spin.",
     "trinity_run", {"first_miss_extra_spins": 1}),
    ("R-C", "R-C_trinity_syringe", "Vice Syringe", 2, "C",
     "In the Vice Round, each winning spin makes later wins pay 20% more.",
     "trinity_run", {"win_scalar": 0.2}),
    ("E-C", "E-C_trinity_halo", "Vice Halo", 3, "C",
     "In the Vice Round, every power activates at 150% strength.",
     "trinity_run", {"vice_potency": 1.5}),
    ("L-C", "L-C_trinity_crucible", "Vice Crucible", 4, "C",
     "In the Vice Round, every spin activates your chosen power plus one random power at 60% strength.",
     "trinity_run", {"chosen_plus_random": 0.60}),
    ("C-D", "C-D_free_spins_teaser", "Free Spins Teaser", 0, "D",
     "Entering Free Spins pays 0.5x your BET at once.",
     "free_spins", {"enter_burst": 0.5}),
    ("U-D", "U-D_free_spins_primer", "Free Spins Primer", 1, "D",
     "Free Spins start with 2 extra spins.",
     "free_spins", {"extra_spins": 2}),
    ("R-D", "R-D_free_spins_injector", "Free Spins Injector", 2, "D",
     "In Free Spins, each win in a chain adds 1 extra to the MULTIPLIER.",
     "free_spins", {"cascade_payout_step": 1}),
    ("E-D", "E-D_free_spins_engine", "Free Spins Engine", 3, "D",
     "In Free Spins, the first win each spin turns 1 winning symbol into a Wild.",
     "free_spins", {"first_win_wild": True}),
    ("L-D", "L-D_free_spins_catastrophe", "Free Spins Catastrophe", 4, "D",
     "In Free Spins, every power that activates also activates a random power at 75% strength.",
     "free_spins", {"chain_random_potency": 0.75}),
    ("C-E", "C-E_diagonal_chalk", "Diagonal Chalk", 0, "E",
     "Wins also count on the top-left to bottom-right diagonal (3 or more in a row).",
     "diagonal", {"mode": "major"}),
    ("U-E", "U-E_diagonal_compass", "Diagonal Compass", 1, "E",
     "Wins also count on both corner-to-corner diagonals (3 or more in a row).",
     "diagonal", {"mode": "both"}),
    ("R-E", "R-E_diagonal_grid_lens", "Diagonal Grid Lens", 2, "E",
     "Wins also count on the top-left to bottom-right diagonal, and can make Wilds.",
     "diagonal", {"mode": "both", "wilds": True}),
    ("E-E", "E-E_diagonal_cruciform", "Diagonal Cruciform", 3, "E",
     "Wins also count on both corner-to-corner diagonals. Diagonal wins fill the Skull Meter at 75%.",
     "diagonal", {"mode": "both", "meter_frac": 0.75}),
    ("L-E", "L-E_diagonal_covenant", "Diagonal Covenant", 4, "E",
     "Every diagonal counts. Diagonal wins pay like normal wins and can make Wilds.",
     "diagonal", {"mode": "all", "full_lines": True, "wilds": True}),
    ("C-F", "C-F_threshold_trace", "Threshold Trace", 0, "F",
     "If 8 or more of one symbol are on the grid, win 0.25x your BET.",
     "board_count", {"threshold": 8, "bonus_stake": 0.25}),
    ("U-F", "U-F_threshold_knot", "Threshold Knot", 1, "F",
     "If 7 or more of one symbol are on the grid, win 0.5x your BET.",
     "board_count", {"threshold": 7, "bonus_stake": 0.50}),
    ("R-F", "R-F_threshold_brand", "Threshold Brand", 2, "F",
     "If 6 or more of one symbol are on the grid, win 0.75x your BET. Can pay after every win in a chain.",
     "board_count", {"threshold": 6, "bonus_stake": 0.75, "once_per_step": True}),
    ("E-F", "E-F_threshold_tribunal", "Threshold Tribunal", 3, "F",
     "If 6 or more of one symbol are on the grid, win 0.75x your BET and fill 1 Skull Meter step.",
     "board_count", {"threshold": 6, "bonus_stake": 0.75, "meter": True}),
    ("L-F", "L-F_threshold_dominion", "Threshold Dominion", 4, "F",
     "If 8 or more of one symbol are on the grid, they all clear and pay like a line win.",
     "board_count", {"threshold": 6, "full_resolver": True}),
    ("C-M", "C-M_chalk_mark", "Chalk Mark", 0, "M",
     "Marks 1 random cell. A win through it pays x2 to x2.5.",
     "corner_glyphs", {"cells": 1, "mult_min": 2.0, "mult_max": 2.5, "dest": "winnings"}),
    ("U-M", "U-M_ink_tag", "Ink Tag", 1, "M",
     "Marks 3 random cells. A win through one pays x2 to x3.",
     "corner_glyphs", {"cells": 3, "mult_min": 2.0, "mult_max": 3.0, "dest": "winnings"}),
    ("R-M", "R-M_scratch_ticket", "Scratch Ticket", 2, "M",
     "Marks 3 random cells. A win through one pays extra and adds +1 to the MULTIPLIER.",
     "corner_glyphs", {"cells": 3, "mult_min": 2.0, "mult_max": 3.0, "dest": "split", "win_frac": 0.6}),
    ("E-M", "E-M_crt_etching", "CRT Etching", 3, "M",
     "Marks 4 random cells with +2 or +3. A win through one adds that number to the MULTIPLIER.",
     "corner_glyphs", {"cells": 4, "mult_min": 2.0, "mult_max": 3.0, "dest": "all_mult"}),
    ("L-M", "L-M_red_glyph", "Red Glyph", 4, "M",
     "Marks 4 random cells. A win through one adds +3 or +4 to the MULTIPLIER.",
     "corner_glyphs", {"cells": 4, "mult_min": 2.5, "mult_max": 3.5, "dest": "all_mult"}),
    ("C-G", "C-G_locker_tape", "Locker Tape", 0, "G",
     "Paid spins: wins pay 15% more. Not in the Vice Round or Free Spins.",
     "sealed_grid", {"payout_bonus": 0.12}),
    ("U-G", "U-G_rusted_hasp", "Rusted Hasp", 1, "G",
     "Paid spins: wins pay 20% more. Not in the Vice Round or Free Spins.",
     "sealed_grid", {"payout_bonus": 0.20}),
    ("R-G", "R-G_basement_bar", "Basement Bar", 2, "G",
     "Paid spins: wins pay 30% more. Not in the Vice Round or Free Spins.",
     "sealed_grid", {"payout_bonus": 0.28}),
    ("E-G", "E-G_mason_lock", "Mason Lock", 3, "G",
     "Paid spins: wins pay 40% more. Not in the Vice Round or Free Spins.",
     "sealed_grid", {"payout_bonus": 0.38}),
    ("L-G", "L-G_iron_lung", "Iron Lung", 4, "G",
     "Paid spins: wins pay 50% more. Not in the Vice Round or Free Spins.",
     "sealed_grid", {"payout_bonus": 0.50}),
    ("C-H", "C-H_loose_thread", "Loose Thread", 0, "H",
     "Each fight starts with 5% of the GOAL already filled.",
     "goal_head_start", {"paid_percent": 0.05}),
    ("U-H", "U-H_torn_label", "Torn Label", 1, "H",
     "Each fight starts with 10% of the GOAL already filled.",
     "goal_head_start", {"paid_percent": 0.1}),
    ("R-H", "R-H_witness_slip", "Witness Slip", 2, "H",
     "Each fight starts with 15% of the GOAL already filled.",
     "goal_head_start", {"paid_percent": 0.15}),
    ("E-H", "E-H_confession_card", "Confession Card", 3, "H",
     "Each fight starts with 20% of the GOAL already filled.",
     "goal_head_start", {"paid_percent": 0.2}),
    ("L-H", "L-H_true_name_tag", "True Name Tag", 4, "H",
     "Each fight starts with 25% of the GOAL already filled.",
     "goal_head_start", {"paid_percent": 0.25}),
]


def godot_value(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, float):
        if v == int(v) and abs(v) >= 1:
            return str(float(v))
        s = ("%g" % v)
        if "." not in s and "e" not in s.lower():
            s += ".0"
        return s
    if isinstance(v, int):
        return str(v)
    return '"%s"' % str(v).replace('"', '\\"')


def godot_dict(d: dict) -> str:
    parts = []
    for k, v in d.items():
        parts.append('%s: %s' % (godot_value(k) if False else ('"%s"' % k), godot_value(v)))
    return "{%s}" % ", ".join(parts)


def chunk(tag: bytes, data: bytes) -> bytes:
    crc = zlib.crc32(tag + data) & 0xFFFFFFFF
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", crc)


def write_png(path: Path, item_id: str) -> None:
    w = h = 48
    hsh = abs(hash(item_id))
    bg = PAL[7]
    stroke = PAL[hsh % 4]
    fill = PAL[4 + (hsh % 3)]
    pixels = []
    for y in range(h):
        for x in range(w):
            if x < 2 or y < 2 or x >= w - 2 or y >= h - 2:
                pixels.append(stroke)
            elif 10 <= x < 38 and 10 <= y < 38:
                bit = ((x * 7 + y * 13 + hsh) % 11) < 4
                pixels.append(stroke if bit else fill)
            else:
                pixels.append(bg)
    pixels[5 * w + 5] = WHITE
    pixels[5 * w + 6] = WHITE
    raw = b""
    i = 0
    for y in range(h):
        raw += b"\x00"
        for x in range(w):
            r, g, b = pixels[i]
            raw += bytes((r, g, b, 255))
            i += 1
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    path.write_bytes(png)


def write_tres(item) -> None:
    item_id, stem, name, rarity, family, desc, effect_id, params = item
    icon_res = "res://combat/art/item_icons/%s.png" % item_id
    desc_esc = desc.replace('"', '\\"')
    family_esc = family.replace('"', '\\"')
    text = """[gd_resource type="Resource" script_class="ItemDef" load_steps=3 format=3]

[ext_resource type="Script" path="%s" id="1_script"]
[ext_resource type="Texture2D" path="%s" id="2_icon"]

[resource]
script = ExtResource("1_script")
id = &"%s"
display_name = "%s"
rarity = %d
family = "%s"
description = "%s"
effect_id = &"%s"
effect_params = %s
icon = ExtResource("2_icon")
""" % (SCRIPT, icon_res, item_id, name, rarity, family_esc, desc_esc, effect_id, godot_dict(params))
    (ITEMS_DIR / ("%s.tres" % stem)).write_text(text, encoding="utf-8")


def main() -> None:
    ICONS_DIR.mkdir(parents=True, exist_ok=True)
    ITEMS_DIR.mkdir(parents=True, exist_ok=True)
    assert len(ITEMS) == 75, "expected 75 items, got %d" % len(ITEMS)
    ids = [i[0] for i in ITEMS]
    assert "L-A" not in ids
    for item in ITEMS:
        write_png(ICONS_DIR / ("%s.png" % item[0]), item[0])
        write_tres(item)
    print("wrote %d items + icons" % len(ITEMS))


if __name__ == "__main__":
    main()
