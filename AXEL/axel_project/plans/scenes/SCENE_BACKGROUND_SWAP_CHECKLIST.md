# Scene Background Swap Checklist

Reusable process for replacing a scene's placeholder/tilemap visuals with a single hand-drawn background image.

## Naming Convention

- Drawing files: `<sceneNumber>_<SceneName>.png` (e.g. `1.1_SchoolExterior.png`)
- Store under: `exports/Drawings/`
- Godot auto-generates `.import` sidecar on first editor open after adding the file.

## Per-Scene Swap Steps

### 1. Preflight

- [ ] Drawing file exists at `exports/Drawings/<sceneNumber>_<SceneName>.png`
- [ ] `.import` sidecar generated (open project in Godot editor once if missing)
- [ ] Note the texture uid from the `.import` file (`uid="uid://..."`)
- [ ] Identify canonical scene path: `scenes/Arc_<N>/<sceneNumber>_<SceneName>.tscn`

### 2. Inventory Current Nodes

Categorize every node in the `.tscn` into:

| Category | Action | Examples |
|----------|--------|----------|
| Visual-only background | REMOVE | `Floor` (Polygon2D), colored placeholder polygons, `TileMapLayer` nodes, environment decoration sprites |
| Collision / physics | KEEP | `StaticBody2D` walls, `CollisionShape2D`, `CollisionPolygon2D` |
| Interaction triggers | KEEP | `Area2D` interact zones + their collision children |
| Player + layer | KEEP | `PlayerLayer`, `Player`, sprites, collision shape |
| Overlays / UI | KEEP | `NoirPaletteOverlay`, `TopDialogueOverlay`, any HUD |
| Scene script | KEEP | Root script (`<scene>.gd`) -- do not modify |

### 3. Edit the `.tscn` File

1. **Add** new `ext_resource` for the drawing texture (use uid from `.import`):
   ```
   [ext_resource type="Texture2D" uid="uid://..." path="res://exports/Drawings/<file>.png" id="<new_id>"]
   ```

2. **Add** a `Sprite2D` background node as first child of root:
   ```
   [node name="Background_<sceneNumber>" type="Sprite2D" parent="."]
   z_index = -100
   centered = false
   texture = ExtResource("<new_id>")
   ```

3. **Remove** all visual-only nodes identified in step 2.

4. **Remove** orphaned `ext_resource` entries (textures only used by removed nodes).

5. **Remove** orphaned `sub_resource` entries (TileSetAtlasSource, TileSet blocks only used by removed nodes).

6. **Keep** all collision/interaction sub_resources (`RectangleShape2D`, `CircleShape2D`, etc.).

### 4. Verify Script Node Paths

Cross-check the scene script's `@onready` and `get_node()` calls against the remaining node tree. Every referenced path must still exist.

### 5. Quick Tests (in Godot editor)

- [ ] Scene loads without errors in editor
- [ ] Drawing is visible as full background at correct position
- [ ] Player spawns and can move
- [ ] Noir overlay renders on top of drawing
- [ ] Dialogue overlay appears and is readable against new art
- [ ] Scene transition (if any) still triggers correctly
- [ ] No z-order issues (player visible above background)

### 6. Log

Record result after completing each scene:

| Scene | Date | Drawing File | Result | Notes |
|-------|------|-------------|--------|-------|
| 1.1 School Exterior | 2026-05-11 | `1.1_SchoolExterior.png` | Done | First swap; legacy Floor/tilemap/placeholder polygons removed |
| | | | | |
