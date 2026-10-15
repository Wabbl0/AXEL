# New item icon prompts (2026-10-15)

Prompts for the 18 planned items in [AXEL_COMBAT_ITEM_CATALOG_PLAN.md](AXEL_COMBAT_ITEM_CATALOG_PLAN.md) ("Planned items"). The original Cursor prompts were not saved. This style rule was worked out from the existing originals in `tools/combat/ai_icon_src/`.

## Status (2026-10-15)

- **Done (AI art):** all of T, X and N (15 icons). Originals in `tools/combat/ai_icon_src/`, noir files in `combat/art/item_icons/`.
- **Placeholders:** `C11` (🪪 ID card as the hall pass), `C12` (🔔 bell) and `C13` (🚬 cigarette) are Windows Segoe UI Emoji renders. Before the noir remap they were split into light grey, dark grey and red, given a dark-red outline and light grit. Replace them with AI art later using the prompts below.
- Some downloads were `.jpg` or 1254 px. They were turned into 1024 px `.png` files (the remap only reads `.png` and never downscales). The `.jpg` originals were not kept in the project.
- `C-T`, `U-X`, `E-X`, `L-X`, `C-N` came with a border or a textured card behind the object. The border and background were cut away before the remap. Add "no border, no card, no background texture" when regenerating.
- The remap now takes item ids, so only those icons are rewritten: `godot --headless --path AXEL/axel_project -s res://tools/combat/remap_item_icons_noir.gd -- C11 C12 C13`. With no ids it still rewrites every icon.
- The icons are not in the game yet: the 18 item `.tres` files do not exist yet.

## How to use

1. Open the image generator (ChatGPT, Gemini, …).
2. Upload the 2–3 **reference icons** listed for the item (from `tools/combat/ai_icon_src/`).
3. Paste the **style block** and then the item's **subject** line.
4. Save the result as a square PNG: `tools/combat/ai_icon_src/{id}.png` (for example `C-T.png`).
5. Do 2–3 first as a test. Claude then runs the noir remap and the icon checks.

## Style block (paste before every subject)

```
Match the style of the attached reference icons exactly. A single game item icon, square 1:1, 1024x1024. One object only, centered, filling about 60–75% of the frame, slightly tilted or seen at a gentle 3/4 angle. Pure solid black background, no floor, no scene, no vignette, no frame, no border, no card or panel behind the object, no background texture or scratches, no glow. Gritty hand-inked illustration: heavy distressed texture, scratches, grime, rough worn edges, fine crosshatch-like detail, like an old horror noir print. Colour palette strictly limited to deep blood red, warm bone grey / dirty off-white, and black. No other colours, no gold, no blue, no green. Absolutely no text, letters, numbers or logos anywhere. Mood: decaying school, guilt, dread.
```

## Rarity look (keep the ladder)

- **Common:** plain, small, simple object, little blood.
- **Uncommon:** a bit more detail, some red wear.
- **Rare:** worn and scratched, clear red accents or splatter.
- **Epic:** heavy wear, dripping or smeared blood, metal plate or rivets.
- **Legendary:** the most ornate and ritual-looking version, strongest red, richest detail.

## Family T — Tickets (Punch Card)

References: `R-M.png`, `L-H.png`, `E-H.png`

| ID | Name idea | Subject |
|---|---|---|
| `C-T` | Torn Stub | `Subject: a single small torn paper ticket stub, bone-grey paper, ragged torn edge, one punched hole, faint red smudge.` |
| `U-T` | Punch Card | `Subject: an old paper punch card with a row of punched holes, edges curled and dirty, a few holes rimmed in red.` |
| `R-T` | Lucky Strip | `Subject: a short strip of three joined raffle tickets, perforated folds, the last ticket half torn off, red splatter across them.` |
| `E-T` | Hoarder's Roll | `Subject: a thick roll of paper tickets on a rusted metal spool, the loose end hanging down, blood dripping from the roll.` |
| `L-T` | Twin Ticket | `Subject: two identical ornate tickets crossed over each other, riveted to a dark metal plate, deep red ink stains soaking both, ritual and sinister.` |

## Family X — Hexes (Penance)

References: `U-C.png`, `C-H.png`, `R-M.png`

| ID | Name idea | Subject |
|---|---|---|
| `C-X` | Bent Nail | `Subject: a single bent old iron nail, rusty and grimy, a tiny red tip.` |
| `U-X` | Knotted Cord | `Subject: a short cord tied in three tight knots, frayed bone-grey fibres with red threads woven in.` |
| `R-X` | Scratched Cross | `Subject: a small wooden cross with deep scratch marks across it, one arm cracked, red stain in the scratches.` |
| `E-X` | Burnt Rosary | `Subject: a coiled rosary of charred dark beads, a few beads cracked, the small cross dripping blood.` |
| `L-X` | Hex Crown | `Subject: a crown made of twisted rusted nails bound with cord, ritual and ornate, soaked in deep red blood.` |

## Family N — Dread (Guilt)

References: `R-M.png`, `E-H.png`, `U-C.png`

| ID | Name idea | Subject |
|---|---|---|
| `C-N` | Ink Drop | `Subject: a single heavy drop of thick black-red ink, glossy, with a tiny splash under it.` |
| `U-N` | Faded Photo | `Subject: an old curled photograph seen from the back, bone-grey paper, a dark red stain spreading from one corner.` |
| `R-N` | Cracked Inkwell | `Subject: a small cracked glass inkwell, dark red ink leaking out through the crack.` |
| `E-N` | Stained Report | `Subject: a folded school report card with no readable writing, a large dark red stain soaking through it, dripping.` |
| `L-N` | Swelling Stain | `Subject: a riveted metal plate with a huge spreading blood-red stain shaped like a dark heart, veins of red running outward, ornate and ritual.` |

## Common uniques

References: `C-H.png`, `U-C.png`, `L-H.png`

| ID | Name | Subject |
|---|---|---|
| `C11` | Hall Pass | `Subject: a worn wooden school hall pass paddle with a frayed string loop at the top, no writing, scuffed edges, a faint red thumbprint.` |
| `C12` | Homeroom Bell | `Subject: an old metal school hand bell with a wooden handle, dented and grimy, a red smear on the rim.` |
| `C13` | Last Cigarette | `Subject: a crushed cigarette pack with no logo, one last cigarette sticking out, a thin red ember at its tip, ash falling.` |

## After generating

- Run the noir remap (`tools/combat/remap_item_icons_noir.gd`) to make `combat/art/item_icons/{id}.png` (1024×1024, transparent background, 8-band palette).
- Checks: `tools/qa/item_icons_check.gd` (75 → 93 once all items exist), `tools/qa/item_icon_draw_size_check.gd`.
- If a result shows text or extra colours, regenerate. The remap fixes colours, but not text or busy backgrounds.
