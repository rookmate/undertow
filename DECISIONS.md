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
41. **Predicted path:** A* over Lattice cells only (indexed, walkable, not occupied), no diagonal steps
    so tiles meet edge to edge. The Steward commits to a route and keeps it while the Operator stays
    on it (no flicker between equal-cost routes); stepping off it re-plans. Tiles within 0.6 tiles of
    the feet are skipped, so all three are ahead. Brightness 1.0 / 0.68 / 0.42, nearest first; tiles
    fade in and out as the prediction moves. Off the Lattice, and with the voice muted, there is no
    path. Destination: the open cell beside the Reliquary that is quickest to reach from the start.
42. **Off-path content is absent while the Steward listens:** unindexed finds and the stacks' Waiting
    resident are invisible and unusable with the voice on, and the Marrow darkens the unindexed cells.
    Muted, the fog thins and they appear. The doorway resident on the lit street is visible either way,
    but can only be woken muted; with the voice on the Steward says "They're resting. Leave them."
43. **Interact** reaches 1.4 tiles. Woken residents speak in Barlow Condensed and cream (Fraunces
    Italic is reserved for the Steward), then walk off toward the Ark and count as survivors.
44. **Off-path truth core** is held in `RunState.found_core_ids` until the Reliquary offers it as the
    fourth card (step 6).
45. **The gate has a fourth stage:** a 90 s full-slice autopilot run that must pass every check for
    the features built so far (the 30 s run stays as the brief's required check).
46. **The voice switch (V / Y)** works in levels only and is remembered in the run
    (`RunState.voice_on`). `Assists.compute(voice, power cores, overrides)` is the single source for
    what it changes: path, map mode, threat warnings, dodge slow-mo, aim assist, forced manual,
    damage multiplier, narration. Power cores strengthen aim assist (+0.1 each, max 0.85) and slow-mo
    (+0.08 s each).
47. **Muted lighting state:** Lattice lamps go dark one by one outward from the Operator (45 ms apart),
    the gilt dies, the ambient tweens to cold, and a screen-space grade (`mute_grade.gdshader`) pulls
    the world to cold greys and ivory while sparing bright saturated light (neon, truth cyan). The
    Operator's ivory hand lamp comes on. Unmuting reverses it; the Steward says "There you are."
48. **Threat warnings** are the Steward's: a gold bracket and "THREAT" over the enemy winding up and a
    gold arc around the Operator pointing at it. The danger itself stays red-orange (the windup).
49. **Slow-mo:** time scale 0.35 for 0.35 s (unscaled) when a dodge starts within 2.4 tiles of a
    windup or an incoming bale, or when a hit lands inside the roll's invulnerability. Voice on only.
50. **Minimap:** voice on, the Steward's map in gold, "STEWARD MAP · 100% CHARTED", without the
    unindexed stacks. Muted, a hand scan of cells within 3 tiles of where you've walked, with the
    real percentage of all walkable cells (including off-path ones).
51. **Narration pools** (`data/narration/steward_lines.json`): 14 events, 53 lines, tones bold /
    cautious / neutral, every event has a neutral fallback, per-event cooldowns and priorities, a 2.8 s
    minimum gap between lines. The Steward never says "I decided" (tested).
52. **Selection:** the tone is drawn first from weights set by the profile's lean (lean 0 is mostly
    neutral; at ±0.9 the matching tone is about 4× everything else), then the least recently heard
    line in that tone. Tested: a risky replay is >60% bold lines, a cautious replay >60% careful
    lines, and the two differ by more than 45 points each way.
53. **Profiling** (`StewardWatch`) only while the voice is on ("STEWARD · LISTENING"; muted, it isn't
    listening). Risk: close kills, kills under 35% Integrity, close double kills, hits taken without
    rolling, manual weapon use, leaving the Lattice. Caution: dodges, retreating rolls, slow-mo dodges,
    kills from 3+ tiles, tuned weapon use, returning to the Lattice. Weapon-mode use counts at most
    once per 4 s per weapon.
54. **Core and log content** lives in `data/cores/cores.json` and `data/logs/memory_logs.json`
    (placeholder text, writer-editable), read through `ContentDb`. The Vellum's Reliquary holds the
    Lattice Core and Feed Core (power; comforting logs 0311 and 0102) and Log 0522's cracked core
    (truth: the Harbor Bridge). Prem Vashti's audit note is the off-path truth core.
55. **Core choice:** carry exactly two; choosing is final. Carried cores' logs are filed for the
    Archive; cores left behind stay unrecovered. Choosing completes the level, restores the Archive
    (the Vellum's Ark building) and saves with the location set to the Ark. Opening the Reliquary saves
    first, so Continue lands back on the cards with any found core still offered.
56. **The Steward's card comments show only while it listens.** Muted, the cards show only their own
    description.
57. **The Ark is a hub level** (`ArkLevel`, map `data/levels/ark.txt`): same builder, but no enemies,
    no predicted path, no weapons, no voice-time counting, no minimap ("the Steward may advise here and
    may not act"); the HUD pill reads "STEWARD · ADVISING ONLY". The restored Archive stands on the back
    edge; unbuilt plots for the other buildings; Noor (cyan lantern) and Teo (tablet, gold in his
    glasses) by the Archive; every woken survivor stands lit in cream by the Commons plot.
58. **Archive screen:** opened from the Archive door, pauses the Ark. Recovered logs first (the
    Steward's comforting records, then truth, then unindexed), unrecovered entries last with their
    titles withheld. Replay prints the decision record line by line (0.45 s per line), then shows the
    Steward's present-day comment (only while it listens) and Noor's and Teo's reactions; trust moves
    once per log, only for companions who are present. Companions' lines on the Ark change with trust.
59. **The game's UI theme is merged into the engine default theme** (`UiTheme.install()`), because
    theme inheritance stops at CanvasLayers and Node2Ds; overlays (pause, Archive, end panel) need it.
60. **End of the slice:** the dock on the Ark ("THE SKIFF ISN'T READY").
61. **EndingRules:** Reboot and Unplug always; Rewrite needs Noor and Teo present, a voice ratio in
    0.35–0.65 inclusive with some time tracked, and 5+ truth cores. Trust and power cores don't
    matter to the unlock. One level gives at most two truth cores, so the slice alone can't unlock
    Rewrite (tested); the end-of-slice panel and the debug overlay show the checklist.
62. **Debug overlay (debug builds only):** every brief variable, assists, logs, loadout, location, the
    ending checklist; while open, F5/F6 sign or revoke the two example overrides and F7/F8 toggle
    Noor's and Teo's presence. Back+R3 opens it on a pad.
63. **Saves happen** at level start, on opening the Reliquary, after the core choice, on reaching the
    Ark, after each Archive replay, on Save-and-return from the pause menu or the dock, and when the
    window is closed mid-run.
64. **Start markers:** 'P' (lit street) on levels, 'p' (bare concrete) on hubs; the Ark has no Lattice
    cells at all (tested), and the Steward's watch ignores Lattice transitions there.

### From the milestone review (reviews/vertical-slice.md)

65. **The Steward's reach is its hardware.** It is present only on or next to Lattice cells (with a
    0.6 s grace so brushing an edge doesn't flicker). Off the Lattice, voice on buys nothing: no path,
    warnings, slow-mo or aim assist, forced manual weapons, ×1.4 damage, no narration, no profiling.
    The map reads "SIGNAL LOST" and can't place you; the pill reads "STEWARD · NO SIGNAL" with the ring
    glitching. The switch itself stays on. The Ark is the exception: it may advise there.
66. **Levels are listed in `LevelCatalog`** (scene, display name, the Ark building each restores).
    Saved locations route through `SceneRouter.destination_for`; new levels are one catalog entry plus
    a map file.
67. **Map files name the things placed on them:** `@ x,y id` lines give each Waiting, cache and log
    slip its content id; maps are validated on load (unknown characters, start marker, ids, a
    reachable Reliquary) and a broken map returns to the title before anything is saved. Unknown
    cells are solid.
68. **Narration lines can be scoped to a level** (`"level": "vellum"`); every event keeps at least one
    unscoped line so a new district is never silent.
69. **One stack owns the pause (`Modals`).** The game unpauses only when the last screen closes; only
    the top screen takes input.
70. **Saving:** checkpoints that fail show a notice and play goes on (the run is still in memory);
    leaving the run with a failed save asks TRY AGAIN / LEAVE WITHOUT SAVING / STAY. The warning is
    ivory, not red-orange (red-orange means danger in the world).
71. **Controller bindings listen to every device**, so any connected pad works.
72. **Exports:** presets for Linux, Windows and macOS (`export_presets.cfg`, output in `build/`, not
    committed). The macOS build is ad-hoc signed (Gatekeeper will still warn; a Developer ID and
    notarization are needed to ship) and uses ETC2/ASTC textures for Apple Silicon.
73. **Performance evidence comes from the autopilot's `[perf]` report**; `--perf-disable=…` is a
    developer flag for measuring feature costs. The 60 fps-on-Deck target can only be confirmed on a
    Deck.
74. **Walls are exact:** shots and sight lines walk every grid cell they cross; a line through the
    corner two walls share is blocked.
75. **A broken map or broken content never becomes progress.** A broken level stops and the router
    takes the player to the title (nothing saved). A Reliquary must offer more cores than you can
    carry, or the level can't be completed from it: its own definition must (cores found off the path
    add to it, never stand in for a missing or rejected one), and so must what's on the table.
    Every district's map and content are checked together at boot (`LevelCatalog.check_all`): ids unique across districts, caches hold truth
    cores, slips hold unindexed logs. District maps are listed in `LevelCatalog`.
76. **The top screen owns everything** (`Modals`): drawn on top, the only one focusable and
    clickable, focus restored when it closes. A failed-save question is blocking: no pause menu over
    it. Scene changes dismiss open screens; an unanswered save question counts as "stay".
77. **The Ark shows every survivor it has room for** (about 158 now) and reports any overflow; nobody
    leaves the run.
78. **Archive text stays in its boxes** (ellipsis), and the record scrolls with up/down from a pad.
79. **Deliberate errors in tests** go through `Diagnostics` and are captured and checked; any other
    engine or script error still fails the test and the gate.

## Milestone 2: Act 1

Asked of the user on 2026-10-09 and answered the same day.

80. **Commits are authored as rookmate** with the GitHub noreply address (the user's choice; their
    account blocks pushes that expose their email). Every earlier commit was rewritten the same way;
    the old history is only on the local branch `backup/pre-noreply-rewrite`. `main` is pushed to
    github.com/rookmate/undertow (private).
81. **Art stays drawn in code** (confirmed), district by district, in each district's palette from the world
    bible and the `port-city` images, until painted art exists. A prompt pack and import spec come
    later so painted sprites can replace the drawing code piece by piece.
82. **Audio is synthesized placeholder** (confirmed): `tools/make_audio.sh` builds every sound effect and ambience
    loop with ffmpeg from formulas (no recordings, nothing to license); the generated .ogg files are
    committed. No music until there is a soundtrack direction.
83. **GodotSteam isn't added yet** (confirmed: skip for now); `SteamService` stays a no-op.
84. **Placeholder writing** (confirmed) (story beats, dialogue, logs, narration) is written from the world bible
    into the editable JSON files and marked placeholder.
85. **Narration is voiced; the title is "Undertow"** (the user's answers to the brief's open
    decisions). Until there's a voice actor, every Steward line is voiced with offline text-to-speech
    (placeholder), and subtitles stay on.
86. **Act order from the world bible:** Act 1 is Kestrel Heights → the Loop → the Tideworks; Act 2
    (Mercy General, the Vellum, Greywater in any order) opens after the Tideworks. New Game starts in
    Kestrel Heights; the Vellum keeps everything built for the slice and becomes an Act 2 district.
87. **Sound rules.** Gameplay asks `Sound` for a named cue; each cue has variations and a little pitch
    spread. Buses: Music, Ambience, SFX, Steward, UI (volumes come from the options). The Steward's
    chime comes with its words (so never while muted); the Lattice hum plays only while the Steward is
    with you (voice on and on its hardware), so muting is heard as well as seen. The stacks sound
    underground. Machines wind up audibly whatever the voice (the sound is physical; the warning is
    the Steward's). Headless runs record cues without starting them (the dummy driver never releases
    them); every quit goes through `Sound.quit()` so nothing leaks at exit. Recordings carry sound.
88. **The Steward's placeholder voice** is Piper's en_GB "cori" (trained on public-domain LibriVox
    recordings; non-commercial voices were ruled out even for placeholders), two semitones lower with
    formants kept, slightly slowed, warmed and levelled: warm, unhurried, mid-register. Every Steward
    line has a stable id and a recording (`assets/voice/<id>.ogg`); lines it says outside the
    narration pools live in `data/narration/steward_fixed.json`. It speaks only when its narration is
    allowed, one line at a time (a new line cuts off the last), and stops mid-word when muted or out of
    reach; subtitles stay up as long as the line takes. It comments aloud on the core card you look at,
    on a memory log after its replay, and when you try to wake one of the Waiting. Its last words before
    the Quiet are said once per launch on the title, cut off. Noor, Teo and the survivors stay text for
    now.
