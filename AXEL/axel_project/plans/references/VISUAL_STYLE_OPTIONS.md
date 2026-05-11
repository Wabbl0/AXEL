# AXEL — Visual Style Alternatives Reference

Curated external shaders and addons for comparison against the current noir+scanline baseline.
Primary implementation: `noir_palette_filter.gdshader` + `overworld_scanline.gdshader`.

---

## Current Baseline (implemented)

| Layer | Shader | Canvas Layer | Key Knobs |
|-------|--------|-------------|-----------|
| Noir palette | `scenes/fx/noir_palette_filter.gdshader` | 90 | `t0`, `t1`, `t2`, 4 palette colors |
| Scanline/terminal | `scenes/fx/overworld_scanline.gdshader` | 92 | `line_density`, `line_strength`, `chroma_strength`, `noise_strength`, `vignette_strength` |

---

## Option A: Full CRT Plugin (nofacer)

- **Source:** https://godotengine.org/asset-library/asset/4219
- **Repo:** https://github.com/nofacer/godot-crt
- **License:** MIT
- **Setup time:** 5 min (download, enable plugin, add CRT node to CanvasLayer)
- **Features:** Scanlines, screen curvature, noise/interference, shadow mask (grille), vignette, chromatic aberration, rolling line, pixel effects
- **Runtime cost:** Low-medium (single full-screen pass, no SSAO-level sampling)
- **AXEL fit:** High for CRT feel; curvature and grille add TV-monitor authenticity. Can layer ON TOP of existing noir shader (noir on layer 90, CRT on layer 92+).
- **Trade-off:** Plugin adds `addons/` folder. May conflict visually with noir at high curvature — test at subtle settings first.

---

## Option B: GodotRetro VHS/Glitch Pack

- **Source:** https://godotassetlibrary.com/asset/yrO9jK/godot-retro
- **Repo:** https://github.com/Ahopness/GodotRetro
- **License:** CC0 (Glitch + NTSC shaders are MIT)
- **Setup time:** 5 min (copy folder, apply shader to ColorRect)
- **Features:** 22 shaders including VHS, VHS Pause, Glitch, Simple Glitch, NTSC, Sharpness, Lens Distortion, Grain
- **Runtime cost:** Low (simple per-pixel math, no texture lookups beyond screen)
- **AXEL fit:** VHS shader matches dread/memory-corruption tone. Glitch shader useful for event triggers (memory flashback, guilt spikes). NOT a global filter — best as triggered effect.
- **Trade-off:** Designed for Godot 3.5+; shaders may need minor port to Godot 4 syntax (`texture()` vs `textureLod()`, uniform hints). VHS permanently active can reduce readability.

---

## Option C: Palette Quantization + Dithering (godotshaders.com)

### C1: Posterization with Dithering
- **Source:** https://godotshaders.com/shader/outline-posterization-color-palette-and-dithering/
- **License:** Community (check page)
- **Features:** Combines outline detection, posterization, custom palette mapping, and ordered dithering in one pass.
- **AXEL fit:** Could replace noir hard-band quantization with smoother dithered transitions. More retro-game than CRT-horror. Worth testing as an alternative mood.
- **Trade-off:** More complex shader to tune; dithering can fight against scanlines.

### C2: Arbitrary Color Reduction + Ordered Dithering
- **Source:** https://godotshaders.com/shader/arbitrary-color-reduction-ordered-dithering/
- **Features:** Bayer matrix (2x2, 4x4, 8x8), arbitrary color count reduction, modular `.gdshaderinc` includes.
- **AXEL fit:** If you want to keep the 4-band AXEL palette but add Bayer dither for texture in transitions.

### C3: Snap Colors to Palette (Oklab)
- **Source:** https://godotshaders.com/shader/snap-screen-colors-to-palette-posterize/
- **Features:** Perceptual color matching via Oklab space. Up to 256 palette colors.
- **AXEL fit:** Could use AXEL's 4 canonical colors but with perceptual matching for smoother art adaptation.

### C4: VesperaFX (Modular Suite)
- **Repo:** https://github.com/devkcud/VesperaFX
- **License:** Check repo
- **Features:** Bayer/Noise/Floyd-Steinberg/Blue Noise dithering, palette mapping (luminance, brute-force RGB, LUT), quantization, pixelation. Modular `.gdshaderinc` architecture.
- **AXEL fit:** Most configurable option. Could replace both noir quantization and add dither/pixelation on top.
- **Trade-off:** Heaviest to integrate; many moving parts.

---

## Option D: CRT Display Shader (godotshaders.com)

- **Source:** https://godotshaders.com/shader/crt-display-shader-pixel-mask-scanlines-glow-godot-4-4-1/
- **License:** Community
- **Features:** Pixel mask patterns, scanlines, glow bloom. Single-file shader for Godot 4.4.1+.
- **AXEL fit:** Clean standalone alternative to the nofacer plugin if you want fewer files.

---

## Option E: CRT with Luminance Preservation

- **Source:** https://godotshaders.com/shader/crt-with-luminance-preservation/
- **Features:** Screen curvature + phosphor arrangement + luminance-preserving scanlines.
- **AXEL fit:** Better detail retention in dark areas than standard scanline overlay.

---

## Comparison Matrix

| Option | Setup | Performance | Noir Compat | AXEL Tone | Readability |
|--------|-------|-------------|-------------|-----------|-------------|
| Baseline (current) | Done | Excellent | N/A | Perfect | Good |
| A: CRT Plugin | Easy | Good | Stacks above | Strong | Good |
| B: GodotRetro VHS | Easy | Good | Stacks above | Strong (event-triggered) | Medium |
| C: Dither/Palette | Medium | Good | Replaces noir | Retro-game | Medium |
| D: CRT Display | Easy | Good | Stacks above | Strong | Good |
| E: CRT Luminance | Easy | Good | Stacks above | Strong | Best dark detail |

---

## Recommended Next Steps

1. Keep current noir + scanline baseline as primary visual.
2. Test **Option A** (CRT plugin) layered on top at subtle settings for added authenticity.
3. Keep **Option B** (VHS/Glitch) shaders on hand for narrative event triggers (not permanent filter).
4. If noir banding feels too harsh after playtesting, try **C2** (Bayer dither) as a transition-smoothing layer between noir bands.
