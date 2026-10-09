# Decisions

Decisions taken for Undertow, newest last. "Default" means the user accepted the recommended default
on 2026-10-09 ("continue with your defaults"). Anything else was decided during the build because the
brief and the user's answers didn't cover it.

## From the round of questions (all defaults accepted)

1. **Slice district:** the Vellum, street level plus the stacks below. The Archive comes from the Vellum.
2. **Path rule:** exactly three gold tiles ahead of the Operator, none under the feet, nearest brightest.
   (Image 10 shows the Operator standing on the first tile; the brief text and the correction prompts win.)
3. **Camera and scale:** fixed isometric camera, 128×72 px tiles (≈56° tilt from vertical; image 10's
   path tiles measure 0.53–0.56 height/width), 1920×1080 base view, about 15 tiles across, Operator
   about 1.3 tile widths tall, no rotation, no zoom.
4. **Narration format:** on-screen text in Fraunces Italic. Every line has a stable ID for future
   voice-over. Lines live in a hand-editable JSON file tagged by event, tone and optional conditions.
5. **Title:** "Undertow" stays the working title. The name lives in `project.godot`
   (`application/config/name`) and in the wordmark (`ui/title/wordmark.gd`).
6. **Weapons:** Traffic Baton, Riot Drone, Defib Gauntlet; pick 2; the fourth grid slot shows locked.
7. **Core cards:** the Reliquary offers 2 power + 1 truth; the off-path truth core becomes a fourth card
   if found; carry 2.
8. **Noor and Teo:** both at the Ark as placeholder silhouettes who react in the Archive;
   `noor_present`/`teo_present` start true.
9. **Overrides:** tracked and saved; the debug overlay signs the two example overrides; "Never warn me
   about traps" turns off threat warnings. No Signal Room screen in this milestone.
10. **Rewrite thresholds:** `voice_on_ratio` in 0.35–0.65 and at least 5 truth cores (`core/tunables.gd`).
11. **voice_on_ratio** counts level play only (not menus, pause or the Ark).
12. **Steam:** `SteamService` wrapper only; it no-ops without GodotSteam. GodotSteam isn't vendored
    until there is an App ID.
13. **Controls:** Move WASD / left stick; aim mouse / right stick; weapon 1 LMB / RT; weapon 2 RMB / LT;
    dodge Space / A; interact E / X; voice V / Y; pause Esc / Start; debug overlay F3 / Back+R3.
14. **Fonts:** Fraunces (Italic), Barlow Condensed, IBM Plex Mono bundled under the SIL OFL
    (`assets/fonts/*-OFL.txt`).
15. **Git:** plain git, no remote, no LFS for now.

## Made during the build

16. **Engine:** Godot 4.7.2-stable (standard build), Forward+ renderer, HDR 2D on (needed for bloom on
    the gilt and neon, and for light blending). Godot is installed at `~/.local/opt/godot-4.7.2` and
    linked as `~/.local/bin/godot`; export templates are in `~/.local/share/godot/export_templates/4.7.2.stable`.
17. **Stretch:** `canvas_items` with aspect `expand`: 16:10 (Steam Deck) and ultrawide show more of the
    world; nothing is stretched or letterboxed. Development window 1600×900.
18. **GDScript warnings are errors.** Every warning that is on by default is set to error level in
    `project.godot`, so a new warning fails the import, the tests and the run.
19. **Tests:** a small in-house runner (`tests/test_runner.tscn`, `tests/test_case.gd`) rather than
    the GUT add-on, so there is no third-party version to track. Run with `--fixed-fps 60` so tests that
    wait on game time run faster than real time and deterministically.
20. **Input map in code** (`autoload/controls.gd`), not in `project.godot`: readable, testable, ready
    for rebinding. J and K are extra keyboard bindings for the two weapons, for keyboard-only play.
21. **UI built in GDScript** with thin `.tscn` wrappers while everything is placeholder; easy to read
    and change in text. Revisit when real art arrives and designers need the editor.
22. **Colour ownership is enforced by a test** (`tests/unit/test_color_rules.gd`): the gold hex only in
    `core/palette.gd`; `Palette.STEWARD_*` only in an allowlist of Steward-owned scripts (each with a
    reason); no hex colour literals outside the palette; no amber-looking numeric colours.
23. **Saves:** one slot, `user://saves/slot_1.json` (custom user dir "Undertow"), written via a temp
    file; the previous save is kept as `slot_1.bak.json`; an unreadable save is moved to `.corrupt` and
    the backup is loaded. Saves from a newer game version are refused and left untouched.
24. **No monitor on this machine.** The display server runs (`DISPLAY=:0`, `WAYLAND_DISPLAY=wayland-0`)
    but every DRM output is disconnected, so presenting with vsync blocks forever. Windowed gate runs
    use `--disable-vsync --max-fps 60`; recordings use Movie Maker (`--write-movie`, 30 fps).
25. **Screenshots** from the HDR viewport are linear; `core/screenshot.gd` converts them to sRGB in
    float so dark scenes don't band. Movie Maker output is already sRGB.
26. **Concept art isn't imported:** `port-city/.gdignore` keeps 34 MB of reference images out of the
    import cache and out of builds.
27. **Progress videos** are written to `../undertow-recordings/` (outside the repo) by `tools/record.sh`.
28. **Step 0 title screen:** New Game and Continue stay disabled until there is a level to start.
    (Step 1: both enabled. New Game starts the Vellum street; Continue resumes `RunState.location`.)
29. **Input maps onto the ground diamond** (Bastion-style): up-right walks straight along the street
    (grid -y), right walks straight across the screen, and the Operator covers ground at the same speed
    in every direction (so vertical screen motion is 0.5625× horizontal). Walk 3.2 tiles/s; the dodge
    rolls about 2 tiles in 0.3 s, invulnerable for the first 0.24 s, 0.55 s cooldown.
30. **Levels are text maps** (`data/levels/*.txt`, legend in the file) built into nodes at runtime:
    one floor canvas item, one depth-sorted node per building cell / prop / lamp, one static body.
31. **Occlusion rule:** tall buildings only on the back edges of walkable ground; a test
    (`test_no_building_hides_walkable_ground`) fails if a building would hide a walkable cell. The
    Vellum plaza got a canal inlet instead of a building block on its camera side for this reason.
32. **Off-path area of the slice:** the Vellum's overflow stacks on the old loading quay, an island
    reached only by a stair through a gap in the canal railing. Unindexed (no lamps, not on the
    Steward's map). It sits on the camera side so nothing hides it.
33. **Lighting:** "paint first, then light". Near-neutral stone albedo, a dark violet-blue
    CanvasModulate for the night, gold PointLight2D pools from Lattice lamps. Light sources (lamp
    lenses, lit windows, neon, the gilt, reflections) are drawn by unshaded `Emissive` child nodes so
    the night doesn't dim them; their HDR colours bloom through a 2D glow environment. Wet-street
    reflections are additive streaks under lamps and neon.
34. **Data files outside Godot's import** (`data/**/*.txt`, `*.json`) must be added to export filters
    when export presets are created.
35. **Weapon light follows the mode:** a Steward-tuned tool glows gold, a manual one glows ivory
    (`WeaponGlow`). With the voice off every weapon is manual (`Loadout.effective_mode`).
36. **Weapon designs:** Traffic Baton (tuned: auto-target, wide 150° arc, hold to chain; manual:
    aimed 105° arc, press within 0.16–0.45 s of a swing to chain, third hit on the beat ×1.6).
    Riot Drone (tuned: auto-target, holds fire before overheating; manual: aimed, harder pellets that
    pierce one, overheats after ~3.5 s of held fire for 1.4 s). Defib Gauntlet (tuned: auto-charges
    0.6 s, 1.8-tile shock; manual: release between 0.5–0.8 s for a 2.3-tile, 30-damage shock, early
    release is weak, holding past 1.1 s shocks the Operator for 8).
37. **Enemies of the slice:** Custodians in pairs (26 integrity, melee lunge 8 damage after a 0.55 s
    red-orange windup) and one Clerk (40 integrity, keeps 3.5–5.5 tiles away, throws paper bales for
    10 after a 0.75 s windup). Red-orange appears only on danger: windups, Integrity loss, overheat.
38. **Integrity 100**, a 0.35 s grace after each hit, downed at 0 and back at the last checkpoint
    (the start, then the 'C' cell) after 1.6 s at full Integrity. Killed enemies stay dead.
39. **Aim:** mouse on keyboard/mouse, right stick on a pad, facing otherwise. While the Steward is
    listening, aim assist bends manual aim up to 55% toward a threat inside a 24° cone (step 4 makes
    this part of the voice toggle).
40. **Continue resumes at the loadout** for a run saved inside a level (weapons are picked before each
    level).
