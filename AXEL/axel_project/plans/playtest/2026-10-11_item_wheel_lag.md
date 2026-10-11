# Item wheel: lag while open

**Note:** Opening the item wheel lagged the game.

**Cause:** While open, the wheel lays itself out every frame. Each layout asked `AxelRun.owned_items()` 20+ times, and every call ran a `ResourceLoader.exists()` file check plus `load()` for each owned item.

**Fix (shipped):** `item_wheel.gd` caches the per-rank item lists and rebuilds them only when `owned_item_ids` changes. It warms each icon's 64px copy at that time, so no image is resized during a layout.

**Check:** `tools/qa/item_wheel_check.gd`.
