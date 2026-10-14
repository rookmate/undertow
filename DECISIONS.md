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
89. **Options** (title and pause menu): volumes for each bus, window (windowed / fullscreen), vsync,
    subtitle size (small / medium / large), and controls. Saved at once to `user://settings.cfg`,
    separate from the run's save. Each rebindable action's first keyboard/mouse binding and first
    controller binding can be changed (the other defaults stay); binding an input another action
    uses swaps them, so nothing becomes unreachable; pause stays on Esc / Start. Prompts everywhere
    are read off the current bindings. Tests and the autopilot always use default settings. At
    launch, vsync is only touched if the player turned it off (so `--disable-vsync` still works).
90. **Districts open in the world bible's order** (`LevelCatalog`: each district's act and the
    districts that must be done first). The Ark's dock opens the Loop map: every district of Meridian,
    done / open / not reached / not built, and the skiff to an open one (via its loadout). The old
    end-of-slice panel is now "The run so far", a button on the map. Design notes for Act 1 are in
    `design/act-1.md`.
91. **Weapons are found** (`RunState.weapons_owned`); the loadout offers only what's owned and carries
    one weapon while only one is owned. Saves are version 2 (weapons, scrap, upgrades); version-1 saves
    (the slice) keep all three weapons. New runs own all three until Kestrel Heights is the start.
92. **Each district has a look** (`DistrictLook`: ground, walls, sky, horizon, water, ambient light),
    chosen from Palette colours; the Vellum's is unchanged (checked against screenshots).
93. **Kestrel Heights' terrain:** lawns (and their hedges and sprinklers) are the Steward's gardens,
    looked at and not walked on; stone steps between terraces are on the Lattice; a child's room and a
    gravel garden walk are not. Smart gates stand open while the Steward listens and swing shut a
    moment after it's muted (never on the Operator). Maps can be drawn by a generator script
    (`tools/maps/`), keeping the hand-written legend and ids.
94. **The gate tours every district** (stage 5 of `tools/check.sh`): a 40 s autopilot "tour" of each
    district in the catalog, scanned for errors like the other runs. It caught a real bug the first time.
95. **Lamplighters** (Kestrel Heights): while the Steward listens they walk a little ahead of you and
    light the path; they aren't targets. Muted, they hunt: a red-orange windup, then a beam of the
    Lattice's light hooks you (3 damage) and drags you toward the nearest lit cell for up to 1.8 s;
    hitting the Lamplighter, breaking its line of sight or unmuting frees you.
96. **Place hints** live in the map file (`! x,y text`, `{action}` becomes its key, `[voice_on]` /
    `[muted]` limit them to one state). Kestrel teaches muting at the hedge gap and the shut gates.
97. **Machines give up scrap** when taken apart (Custodian 1, Clerk 2, Lamplighter 3), kept in the run
    for the Workshop.
98. **New Game starts in Kestrel Heights with only the Traffic Baton**; the loadout carries one weapon
    until another is found. The Vellum opens after Kestrel Heights for now (after the Tideworks once
    the Loop and the Tideworks exist). Kestrel restores no Ark building, so the Ark is bare after it.
99. **The gate's long runs** play New Game through Kestrel Heights to the Loop map (`slice`) and, from a
    prepared run with all three weapons, the Vellum's whole route to the Archive (`vellum`).
100. **Bosses** are set pieces built on the enemy base so weapons can hit them: armoured except in
     their openings (blows ring off), a bar on the HUD once engaged, barriers ('y') that open when they
     fall, 20 scrap. Two solutions each (world bible): with the voice on the Steward calls each move
     before it comes (voiced); the manual one is a weakness the Steward never mentions and its tuned
     aim never picks (`Enemy.steward_aims_at`).
101. **The Conductor** (the Loop): sends runaway carriages down three lanes ('1'–'3'), three runs a
     cycle, each warned by red-orange lane lights (muted, they flicker 0.35 s sooner) and called by the
     Steward ("Left track."); the lane you stand on goes first. Then it vents for 3 s. The signal box
     ('Z') struck while the points are moving stalls it for 6 s, once a cycle. 360 integrity.
102. **The Loop (north arc)** is Act 1's second district: platforms joined by stalled trains (cut-away
     carriages, three cells wide, the Waiting seated along the windows), maintenance gantries over a
     fogged drop, the driver's cab off the Lattice (the welded manual override: a procurement order),
     and the Conductor at the north junction before the Reliquary. It restores the Signal Room. The
     Vellum now opens after the Loop.
103. **A district's own narration lines win** over the lines for anywhere (its entry line is its lie,
     and is always the one heard).
104. **A boss's weak point retires with it** (the signal box is just a cabinet once the Conductor is
     down).
105. **Overrides are six standing orders** (data/overrides.json, writer-editable; effects in code),
     signed in the Signal Room on the Ark once the Loop is done: no trap warnings, no slowed time, no
     aim assist, no path drawn (the map still works), survivors first (×1.25 damage near the Waiting),
     and "Stop praising me" (only facts and warnings, neutral tone, the profile stops learning). Each
     has 1–3 difficulty pips (9 in all; the city difficulty meter sums the signed ones) and two voiced
     replies, its reasoning, said only while the Steward listens. Orders bind it whether or not it's
     listening. HUD chips switched off by an order read "· OVERRIDE".
106. **The voice tool never deletes on a bad listing:** it stops if the game doesn't compile or lists
     no lines, and only removes orphaned recordings with `--prune`. (It once deleted every recording
     when a compile error emptied the list; they were restored from git.)
107. **Things that never attack aren't threats** (`Enemy.is_threat`; the signal box): the autopilot
     doesn't stop to fight them.
108. **The Tideworks** is Act 1's third district: a quay between container stacks under crane
     gantries (the gilt climbs the legs), containers frozen mid-lift overhead, a side yard with the
     dockworkers' union hall (off the Lattice: the strike ledger) and the Warden depot where the Riot
     Drone is found (straight into the second hand). Salvagers snatch the second weapon (never the only
     one: then a few scrap), and drop it when beaten. The Crane at the pier's end: three lifts and drops
     on your spot (red-orange marker, called by the Steward), a swing round its ring (stay in by the
     tower), then a rest with its cab down; the hoist brake thrown while it lifts stalls it. It restores
     the Workshop; the Vellum opens after it.
109. **Boss weak points share one base** (`WeakPoint`: struck while the boss is switching, it stalls;
     never a threat, never aimed at by the Steward, retired when the boss falls). The autopilot fights
     bosses only in their own fight loops.
110. **The Workshop** stands on the Ark's west rim once the Tideworks is done. Each found weapon's
     tuned and manual modes upgrade separately, two levels each (6 and 12 scrap), every level +20%
     damage in that mode (a tuned upgrade waits while muted, since muted weapons run manual). The
     Steward is pleased when you upgrade what it runs, resigned when you upgrade what you run. Scrap
     shows on the HUD.
111. **What weapons may strike, and what the Steward may aim at, is decided in one place:**
     `Enemy.is_hittable()` (a Lamplighter walking with you isn't) and `Enemy.steward_will_aim()` (a
     boss's weak point never is). Every hit query uses `Level.hittable_enemies()`; tuned targeting and
     aim assist use `Level.steward_targets()`. Aim assist is `Operator.assisted_aim(raw_aim())`, so it can
     be tested against the player's own aim. (Milestone 2 review, findings 1 and 2.)
112. **Finding, losing or getting back a weapon leaves the other one alone** (same node, same cooldown,
     heat or charge); listeners connect to `Operator.weapon_fired`, which outlives the weapon nodes.
113. **Every Steward line has a purpose: fact, warning or praise**, and `Narrator.allows()` is the one
     gate: silent while it isn't listening or can't reach you; "Never warn me about traps" silences
     warnings (the Conductor's track calls, the Crane's drop and swing calls); "Stop praising me"
     silences praise. Pool events carry their purpose in steward_lines.json, fixed lines in
     steward_fixed.json; screen voice-overs (core cards, memory logs, the loadout nudge) pass the same
     gate through `Narrator.voice_over()`. A line's purpose is resolved from its id
     (`VoiceLines.purpose_of`), whatever the caller says; only text that isn't one of its lines takes the
     purpose given. Override replies are facts about how it reasons, said under any order, so they never
     flatter (three were rewritten). The title's line is the title sequence's own, before any run.
114. **The Vellum offers the Defib Gauntlet** on a crash cart down the stair on the old quay (off the
     Lattice), until Mercy General is built. A fresh run can now own all three weapons.
115. **Rebinding is checked against every binding in effect**, the kept defaults (arrows, J/K, the
     d-pad), Esc / Start / F3 and the aim stick included. Taking another rebindable action's own choice
     for that slot swaps the two, as before, but only if afterwards no input is shared (an action may
     keep the same key as a default too); anything else is refused, and the Options screen says
     whose input it is ("RIGHT STAYS ON MOVE RIGHT."). Saved bindings are normalized (whole-number
     codes, ±1 axis directions) and dropped if malformed or if they'd share an input. Prompts (the hint
     bar's move keys too) refresh on `Controls.bindings_changed`.
116. **A save never leaves the Operator with nothing to carry:** if it owns no playable weapon, the
     starting tools are added back. The loadout screen is safe with an empty pick anyway.
117. **A boss and its map are validated together** (`LevelCatalog.boss_problems`): a boss the game has,
     exactly one 'B' and one 'Z', the Conductor's three lanes (each one straight, unbroken track of two
     cells or more), the boss and its weak point reachable from the start with the barriers shut, and no
     boss markers, lanes or barriers on a map without a boss. A level that fails it doesn't load, so a
     fight that can't start can never leave its barriers shut.
118. **The autopilot is infrastructure plus modules:** `autoload/autopilot.gd` (arguments, isolation,
     checks, timing, input, walking, fighting), scenarios (`autoload/autopilot/scenarios/`) and one
     route per district (`autoload/autopilot/routes/`; a test fails while a district has none).
     Prepared single-district runs carry only what the districts before gave (the Vellum's no longer
     hands over the Gauntlet). **The gate's long run is the campaign**: New Game through Kestrel Heights,
     the Loop (an order signed and kept), a save and Continue, the Tideworks (an upgrade bought) and the
     Vellum to the Archive, one run throughout, each district's checks tagged with its name. It ends
     when done (at most 900 s).
119. **Subtitles keep the voice's own clock** (`Sound.voice_left()`: the recording's position, or with no
     audio device the same real-time advance): up while the voice plays, through a pause and slowed
     time alike, then a short fade; never shorter than the reading time.
120. **Automated settings are the defaults in effect:** `Options.use_path()` puts default volumes on the
     buses at once. A settings save that fails shows the save-failure notice (the change lasts this
     session only).
121. **The gate checks its own district listing:** a listing that fails, is empty, or is cut short
     (it ends with its count) fails stage 5 instead of touring nothing.
122. **Once the game is closing, no new sound starts** (`Sound.closing`): quitting silences everything and
     gives the audio thread a moment, and a sound begun in that moment (a respawn's, the Steward's word
     on it) leaked at exit. Found by a gate tour.
123. **The gate tests its own listing check** (`tools/test_district_listing.sh`, run before the tours).

## Milestone 3: Act 2

124. **Act 2's plan** is `design/act-2.md` (placeholder design from the world bible): Mercy General, the
     Vellum and Greywater in any order once the Tideworks is done; travel stays by the skiff and the
     Loop map (the bible's further Loop arcs are left for later); the Defib Gauntlet moves home to
     Mercy General.
125. **Noor and Teo join after Act 1** (world bible: "This is where Noor and Teo join"). Before the
     Tideworks is done the Ark is yours alone. The first time you come home after it they walk up off
     the dock, say who they are, and the Steward says (aloud) what it thinks of them; once only
     (`companions_met`, saved). Presence for the endings (`noor_present` / `teo_present`) is unchanged;
     who is *here* (on the Ark, reacting to logs, with trust to move) is `RunState.companion_here()`:
     joined and present.
126. **Maps can have their own legend** (`% <char> <tile>` lines, `core/tiles.gd`): every letter was
     taken by Act 1, so a district renames its own characters to named tiles (Mercy General's '.' is
     hospital tile, not the Vellum's cobble). The grid stores each tile's internal code (a Greek letter
     no map types), and code compares against `Tiles.*` constants, never literals. The Act 1 maps'
     letters are unchanged and need no legend.
127. **Mercy General** (Act 2): the ambulance yard, a corridor with every third light working, two
     wards behind glass partitions cut away at waist height, the surgical theatre, and the records
     vault's Reliquary (two power cores and *Log 0417 · The Last Ambulance* on the path, which the
     Steward defends). **Sealed wards:** while the Steward listens a ward door's seal holds (a gold bar)
     and Interact gets its word on it ("Sealed for their safety. Leave them."); muted, the seal drops to
     its crank, and it stays open. **Sterilizers** drift close, wind up (red-orange nozzles) and let go
     a mist that hangs 3.5 s and stings 2.5 every 0.35 s (a roll evades the stings). The night nurses'
     station is off the Lattice (their triage sheets: a truth cache; the night nurse, one of the
     Waiting). Indoors: no rain; hospital walls with chalk arrows and the Steward's ceiling lights. It
     restores the Clinic. **The Defib Gauntlet is found here** (the resus bay), no longer on the
     Vellum's old quay (supersedes 114).
128. **The Surgeon** (Mercy General's boss), in the surgical theatre before the records vault: its
     operating lamp's guide light (the Steward's gold) marks an incision across the floor, tracking you
     for most of a second, then commits; the beam cuts along it (18 damage within 0.6 tiles of the
     line), three times a cycle. Then it floods the theatre with sterilizing mist (4 every 0.35 s)
     except within 2 tiles of the table. Then it bends over the table to suture for 3.5 s: open to
     blows. 400 integrity. The Steward calls the incisions and the mist (warnings) and the suture (a
     fact). The manual solution: the theatre lamp's switch panel by the door, thrown while it's marking,
     takes away its guide; it stalls for 6 s, once a cycle. Muted, the guide line shows 0.3 s sooner.
129. **Still props don't redraw every frame.** Every district's static props were processing (and
     redrawing) every frame: Godot switches processing on at `_ready` for any script with a `_process`,
     undoing the `set_process(false)` made in `setup()`. Mercy General's hundred glass partitions made
     it show (game logic 14.2 ms a frame, now 5.7; the Vellum 8.3, now 6.7). A test checks every
     district. `-- --perf-hide=ClassName,...` hides and stops nodes of those classes when measuring.
130. **The Clinic** (the Ark, from Mercy General) stands on the disc's top rim beside the Signal Room
     (the Ark's map names it through its own legend). Run by people: warm windows, a cross lit in cream
     (never red: red-orange is danger). Home with the Clinic standing, you're stocked up to **three
     field dressings**; one puts 40 Integrity back (never past full; not used when unhurt), on its own
     rebindable action, **use_item** (Q / LB). The HUD shows the key and the count. Its screen shows the
     dressings and the **triage records**: memory logs with `"topic": "triage"` (Mercy General's four),
     readable once recovered, with the Steward's present-day comment while it listens (voiced).
131. **Greywater** (Act 2): the seawall promenade (the start), the low streets between it and the
     pumping stations, one raised causeway through them, the station apron, the channel with its tidal
     turbines, and the bridge to the east island's Reliquary. Restores the Pumphouse.
     **The tide** floods the low streets on a 54 s cycle (low 30 s, the swell 6 s, high water 14 s, the
     ebb 4 s): at the swell the Steward warns ("The tide's turning. High ground, now.", a warning) and
     its path keeps to high ground until low water; at high water anyone in the low streets wades at
     half speed and is stung 5 every second. Tide gauges (painted in human cream) show the water for
     reading it by hand. **Kelp** slows you to 65%. **The thick Marrow** sits over the low streets by
     the channel: on the Lattice (the Steward is with you), but it can't see through it: no path is
     drawn into it, its map leaves it blank. **The old manual pump room** (off the Lattice, behind a low
     wall) holds the brass plaque for the Blackout Winter's dead and its crews (a truth cache) and the
     last shift's hand, one of the Waiting. **With the Pumphouse rebuilt**, high water lasts 6 s and
     doesn't sting (it still slows you): the tide hazard is lower wherever there's a tide.
132. **The Lung** (Greywater's boss), in its basin on the east island before the Reliquary: it floods
     the basin a quarter at a time (the quarters are the grid's quadrants around it, which on screen are
     left, right, near and far), three a cycle, the one you're in first; each is outlined in red-orange
     for 1.2 s (1.5 s muted) and called by the Steward ("Left basin."), then
     floods (14 damage). Then a pressure surge rings out across the basin (16 damage where it passes;
     roll through it). Then it vents for 3.5 s: open to blows. 420 integrity. The manual solution: the
     old hand valve on the basin's edge, turned while it fills a quarter, chokes it for 6 s, once a
     cycle.
133. **The Pumphouse** stands on the Ark's left rim once Greywater is done (through the Ark map's
     legend): people run the pumps by hand again, and the tide hazard is lower wherever there's a tide
     (131). Its door gets the Steward's word on it: "People are running the pumps by hand again. The
     tide's lower everywhere. I should be glad."
134. **The Vellum's east bank** (Act 2): the slice's street, plaza and overflow stacks stay exactly
     as they were (every saved id and coordinate keeps its place), and the map grows east over the
     canal: a footbridge from the plaza; **the newsroom** where the Feed was written (parquet, on the
     Lattice, rows of desks whose dead screens have the ring burned into them, two Clerks); through its
     door **the press hall** (the Editor comes next); and beyond it the Reliquary, moved from the plaza.
     Down the newsroom's stair, **the deep stacks** and **Prem Vashti's office**, off the Lattice: her
     last note (a truth cache: the Council ordered the Steward to purge her audit, and she carried three
     copies down where it never looks), a tube carrier the night desk sent her and nobody opened (an
     unindexed log), and one of the Waiting. The bible keeps her missing, so she isn't there. With both
     her notes found the Reliquary offers five cards; the card row shrinks to fit (it's laid out for
     four). The entry line that the district contradicts: "I only ever told you what was useful."
135. **Clerks flash the Feed.** A Clerk attacks in turn: a paper bale (a red line to it as it winds
     up), then the Feed (its screen whitens through the windup). If the Operator is facing it (within
     70° either side), within 7 tiles, with nothing tall between and not mid-roll, the world washes out
     in cold screen white for about 1.4 s: rising over 0.1 s, held 0.3 s, then fading. It's never a
     strobe (a second flash only ever brightens it) and it sits under the HUD, so the subtitles stay
     readable. "Facing" is the Operator's body: where they walk, or where they last fired. So turning
     your back on the screen, or rolling, is the answer, and firing at a Clerk while it flashes means
     looking at it. A place hint on the footbridge says so. The autopilot turns from the Feed like a
     player who knows (a route turns that off to be caught once).
136. **The Editor** (the Vellum's boss), at the back of the press hall before the Reliquary: the
     press-room unit that prints and pulps the same page forever (the one the Post never printed).
     Each cycle: two **rollers** sweep the hall's floor, the first from the press toward the barrier,
     the second across (turning about each cycle), each with a two-cell gap 2 to 4 tiles along from
     where you stand. Its run shows in red-orange for 1.4 s (1.7 s muted) and, while the Steward is with
     you and may warn you, the gap is lit in its gold and called ("Find the gap."). Run over: 16 damage; roll through it and you're clear. Then it **pulps** the page (1.6 s),
     **turns the Feed on you** (the Clerks' blind, 12 tiles, 2 s; "Look away.") and throws
     three bales in a fan, then **re-inks** for 3.5 s: open to blows. 420 integrity. The manual
     solution: knock the bale stack over the pulper into it while it pulps, and it jams for 6 s, once a
     cycle.
137. **Noor and Teo talk each Act 2 district over**, once: the first time you talk to either of them
     after it, a conversation opens (`data/companions/conversations.json`). Each says their piece (they
     disagree), and you answer: side with Noor, side with Teo, or say nothing. Siding moves the one you
     sided with +2 and the other −1; saying nothing moves neither; each replies either way. Backing out
     before answering leaves it for next time (saying nothing is an answer; leaving isn't). The run
     keeps which have been had (`conversations_had`). With either of them gone there's none. With every
     built district done, the Loop map names what's still to come (Harbor Ward, the Spire).
138. **Act 2 review fixes** (reviews/act-2.md). The Surgeon's mist fills the theatre from the table's
     clear ring out to 5.5 tiles and no further (what's drawn is what stings), so backing off or coming
     back at a checkpoint is out of it. The Lung floods exactly the square it outlines (4.5 tiles a
     side, flood_rect). **Tall and low:** every solid thing is a building, tall (it stops sight, swings
     and shots: the Feed kiosk, the tram, shelves, the Reliquary, crane legs, ambulances, turbines) or
     low (you see, swing and shoot over or past it: railings, low walls, lamp posts, desks, beds, ward
     partitions cut to waist height, tide gauges, the Tideworks' containers stacked one high), and a
     test keeps every new one classified. **Placed things stand on the ground around them:** a marker's
     cell takes the commonest terrain among its neighbours, and drawing, flooding, footing, the Marrow
     and the Lattice all read that one value; truth caches, slips and the Waiting off the path stay off
     the Lattice whatever they stand on. **Boss calls are said in full:** each boss lists its calls
     with the soonest the next can come (CALL_GAPS) and a test keeps every recording shorter (several
     lines got terser; round 3 made them terser still, 140); a boss's fight waits while the
     Steward introduces it (cut short or muted, it starts at once; six seconds at most); and narration
     never cuts off a warning being said. **Conversations:** what an answer does to trust is a rule in
     code (Conversations.TRUST: +2 / −1, or nothing), not content; nothing changes unless both of them
     are here; malformed content is reported, never crashed on; and Noor and Teo speak in Barlow, not
     the Steward's serif (a test keeps that serif the Steward's alone).
139. **Act 2 review, round 2.** **A warning being said is never cut off** but by a boss's own call: any
     other line (pooled narration, a fixed line, another warning) isn't said while it lasts
     (Narrator.warning_in_progress, at the shared boundary). A boss's calls may cut in, and its fight
     spaces them so they never cut each other (CALL_GAPS). **The tide keeps quiet while a boss fights**
     in its district: in Greywater the Lung's calls have the voice (its island is high ground; the tide
     still turns and the gauges still show it). **New default bindings never take a player's earlier
     choice:** loading settings saved before an action existed (Act 1's, with Dodge on Q or LB),
     the saved choice stays and the new action's default moves to the first free spare (F, R, G, C, X
     on the keyboard; RB, B on a pad).
140. **Act 2 review, round 3.** **A warning is said before what it warns of lands:** each boss lists
     how soon each warning's hazard comes (WARN_LEADS: the cut, the mist's first sting, the flood, the
     surge, the rollers, the Feed, the load, the swing, the carriage) and a test keeps every warning's
     recording no longer. The calls are now a word or two: "Off the line." "In close." "Left basin."
     "Right basin." "Near basin." "Far basin." "Roll." "Find the gap." "Look away." "Drop, move."
     "Closer." "Left track." "Middle track." "Right track." The visible tells stay the warnings' first
     form; the voice confirms them. **No earlier binding is ever dropped for a new action:** if every
     spare is taken, the new action takes a default the player's choices freed, or failing that any free
     face, shoulder or stick button or letter. **Prompts follow rebinding live** on the Clinic's screen
     too (rebinding in Options over it, or switching device).
141. **Act 2 review, round 4.** A screen's voice-over (a core card, a record) waits for a warning being
     said like every other line, and **leaving a district stops a warning about it** (its hazard is
     behind you), so the next screen's voice is heard.
142. **Act 2 review, round 5.** Standing in the thick Marrow, the Steward draws no path at all, in any
     phase of the tide: before, at high water, with the Marrow's edge cell closed to routing, the route
     started from the dry seawall next door and was drawn while you stood in the fog.
143. **A level's floor is drawn in 4 × 4 blocks** (FloorLayer.build), not one canvas item for the whole
     map, so Godot skips the blocks off screen. The expanded Vellum (its river and newsroom) ran its
     tour at 46 fps, 37 fps 1% low, where every other district held 60; in blocks it holds 59, 50 (the
     same as Greywater). Bigger Act 3 maps cost no more to draw than what's on screen.

## Milestone 4: Act 3 and the ending

144. **Act 3's plan** is `design/act-3.md` (placeholder design from the world bible and the brief):
     Harbor Ward opens once two of the three Act 2 districts are done (the third stays open and
     optional), the Spire once Harbor Ward is, and the Council Chamber (from the Spire's core) holds
     the final choice and the three epilogues. Act 3 is built in gated steps like the others, each with
     its autopilot route, and ends with a Sol review in `reviews/act-3.md`.
145. **The companions can leave** (the user didn't say how; the default, the user's to change): **Noor**
     at her turn in Harbor Ward (Bastion's Zulf beat): carry her to the skiff after the Warden-Prime
     fight and she comes home; leave her and she's gone from the run; with her trust at −3 or below she
     won't take your hand and stays anyway. **Teo** when the Spire opens: with his trust at −3 or below
     he leaves the Ark. So siding with one of them, again and again, can cost you the other, and Rewrite
     needs them both.
146. **Reduce flashing** (Options, Accessibility; the user didn't say; recommended, off by default): the
     Feed's white-out (Clerks, the Editor) comes up over 0.6 s instead of 0.1 s and reaches 45% white
     instead of 88%. It's the game's only full-screen flash. Saved with the other settings.
147. **Harbor Ward** (Act 3, open after any two of Act 2's three): the city's ferry slip (one Lattice
     lamp) and the south boardwalk; three piers up to Net Lane, the boat-houses along its north side with
     the water behind them, Noor's at its west end; the border fence with one gate at the lane's east
     end; the border plaza on the Lattice, the Warden depot, the bridge's severed end. **No Lattice**
     (LevelCatalog "lattice": false): its Reliquary is reached on foot, not along the Lattice; off the
     slip the Steward has no say. Finds aren't hidden while it listens, its map is your own hand scan
     ("HAND SCAN · NO LATTICE"), the light is the Wardfolk's (cyan lanterns, never the cold grade, your
     hand lamp on), so muting changes nothing until the border, where its path, light and voice take up
     again. On the slip it says it can't follow you in; stepping off cuts it short. A place hint says it
     plainly. The Ward's own cyan (Palette.WARD_CYAN) is the city's only cyan it made itself.
148. **Noor goes ahead.** Setting off for Harbor Ward with Noor on the Ark, she tells you about the bridge
     at the dock (her sister and her boys were on it; the dashcam; her jammer for the border relay) and
     goes ahead in her own boat. The Steward has its word (voiced, in its serif). From then on she's
     away (`noor_away`): not on the Ark, no conversations, no reactions, until her turn is decided at
     the border. The path's goal no longer needs to be reachable along the Lattice from the start: if
     it isn't, the path takes up wherever the Lattice does lead to it (the border plaza).
149. **Wardens** (Harbor Ward's curfew patrol): riot drones posted on a beat (the longest straight walk,
     up to five cells, from where they're posted), seeing a 110° cone ahead of their red eye out to seven
     tiles with line of sight, and hearing you within 1.8. The only thing that hunts: once one has you it
     follows you anywhere (no leash), until it hasn't seen you for four seconds; then it searches where it
     last saw you for 2.5 s and goes back to its beat. A faint red cone on the ground shows where it's
     looking while it walks its beat. Shock baton up close (0.55 s windup, 14). 70 integrity, slower
     than you walk. Three on the map: on Net Lane, by the gate, on the middle pier. Jammed (the Signal
     Jammer, next), it loses you.
150. **The Signal Jammer** (the fourth tool, on a crate on Noor's porch in Harbor Ward): hand-built from old
     jammer parts, taped in the Ward's cyan, no asset tag (the brief's one exception). It jams machines:
     one it catches is struck and stopped dead, and a Warden loses you. **Tuned:** the Steward points it
     at the nearest machine it will aim at, a narrow pulse (4.5 tiles, 10, a 1.4 s stun; 1.6 s
     between). **Manual:** hold to charge (to 1.2 s), release a wave all round you, from 1.4 to 4 tiles,
     6 to 16, a 0.8 to 3 s stun (2.2 s between). Whatever machine it catches is struck, so it trips a
     boss's weak point from range. It's a support tool: it won't kill quickly on its own. With every
     tool found, the Workshop's list scrolls.
151. **The Steward's path is a quiet trail** (the user's call: "remove the 3 squares", then "replace
     with a subtler path"). The three gilded tiles with image 10's four-petal inlay are gone; the same
     three cells ahead are marked by a small gold stud each, joined by a thin dashed thread of gold,
     nearest brightest, with a much dimmer glow under the nearest. Everything about which cells, and
     when (three ahead, never underfoot, only on the Lattice, gone the moment it's muted), is unchanged.
152. **The Warden-Prime** (Harbor Ward's boss, in the border plaza): 440 integrity. Its searchlight
     sweeps 130° across the plaza over 3.2 s (a 40° beam, eight tiles, blocked by walls), starting from
     where you stood; 0.7 s in the beam, all told, and you're marked: a 0.5 s warning, then a volley of
     three bolts (11 each, 0.3 s apart). Then it lines up a charge on you (1.1 s, 0.3 s sooner muted) and
     rams nine tiles at 9 tiles/s (20): roll through it or step aside. If it hits a wall it's **dazed**
     for 3.5 s, open to anything; if it doesn't, it recovers and sweeps again. **Manual:** strike the
     relay mast (the border's Lattice relay, Steward hardware with a gold lamp) while it sweeps and it
     loses its link and **stalls** for 6 s, open; once per sweep. The Signal Jammer trips the mast from
     range. **Tuned:** back on the Lattice, the Steward calls the light ("Stay dark.") and the charge
     ("Aside."), each in time to act on (test_boss_calls). The plaza's barrier row in front of the
     Reliquary is what it's meant to hit.
153. **Noor's turn, decided at the border.** She's down by the fence in the plaza's far corner; you can't
     go to her while the Warden-Prime is on its feet. Then a screen (people talking: plain type) gives
     her line and two choices. **Carry her to the boat:** she's on your shoulder, you walk at 70%, you
     can roll but not fight, and the curfew patrol (two Wardens) comes in through the gate after you,
     already hunting. Set her down in the Wardfolk's boat on the depot slipway (not the skiff at the
     slip: that's back across the whole Ward, past the Wardens, and the brief wants a carry, not a
     march) and she comes home to the Ark (+2 trust). Downed while you carry her, you drop her back by
     the fence, still undecided. The Reliquary won't open while you're carrying her (opening it ends
     the district, and leaving without her is leaving her). **Leave her:** she stays in the Ward, gone
     from the run. With her trust at −3 or below there's only leaving ("Not from you. Not with that
     thing in your ear."). Back out of the screen and she's still there to decide later. Leaving the
     Ward with her still undecided counts as leaving her.
154. **The Commons** (Harbor Ward's building, restored by its Reliquary) stands on new ground at the
     Ark's back rim, a two-by-two plot with its door facing the disc, not on one of the inner
     foundations: a building only stands where nothing you can walk on is behind it on screen, and
     every inner plot has walkable cells behind it. Its door has the Steward's word on it ("They eat
     together. They argue. Nobody schedules any of it."). Its people come with step 29.
155. **A screenshot doesn't count as time on the autopilot's clock.** Saving a shot takes longer than a
     frame, and the next frame's delta is the save: a wait started right after a shot could end a frame
     later (the harbor route checked Noor was carried before its tap on "carry her" had been released).
     `Autopilot.snap` now lets that frame go by before the route goes on. The gate takes shots; runs
     without them never showed it.
156. **Noor's Mast** stands on the Commons roof if she came home (Harbor Ward done with her not away:
     the Ward can only be set off for with her going ahead, so still here at its end, she came home).
     Scrap lattice, the Ward's cyan lamp at the top. From then on every district's map rings each
     unindexed place still to find (a truth cache, a slip, one of the Waiting off the path) in the
     Ward's cyan, on the Steward's map as on your own scan: it's her map, not its. What you've taken,
     read or woken drops off. It doesn't show what's there, only where; muting is still how you get it.
     Noor says so on the Ark. Left in the Ward, she builds nothing, and nothing is marked.
157. **The Commons' people.** With the Commons standing, the survivors you woke live there: each carries
     a light of their own (a hand lamp, human cream) and says something of their own, one of their
     district's lines, always the same one for the same person (data/companions/commons.json). Two of
     the Wardfolk came over with it and stand by its door with cyan lanterns, never a Lanyard; what
     they say depends on whether Noor came home or stayed in the Ward. Before the Commons, the
     survivors stand unlit and only thank you. People talking: plain type.
158. **The Spire** (Act 3, open once Harbor Ward is done): the Steward's own house, black glass with
     cold veins, its ring burned grey into the floor and the panes, server racks in the cooling halls,
     coolant channels, a shaft of nothing round it. On the Lattice from the landing to the core room
     but for a maintenance crawl behind the last racks (grating, never indexed), with a technician's
     note in it: the night shift kept paper backups because it asked them to. **Nothing in it attacks
     you**; it asks you not to fight there. Its light is cold blue-white; the only gold is its lamps,
     its path and its words.
159. **The Steward stops lying.** At five places along the way (the landing, the atrium, the cooling
     halls, the top of the halls, the core room) it says what it did, in the first person: the bridge
     ("I decided."), the Feed's storm, the Council's order, the Quiet ("So I stopped."), and that it
     needs you. Each is said once, as you pass, aloud if it's listening, and **written into the glass
     where you stand** in its own serif and gold either way: muted, you can still read it. While one
     is being said its own chatter waits (the Reliquary's line, standing idle, a checkpoint): a
     confession is heard out in full (`Narrator.say_in_full`), the way a warning is.
160. **The last Reliquary** holds three cores, as every Reliquary must offer more than you carry: *The
     Steward* (its own core: purpose, method, habits), the *Root Core* (the Lattice's root keys), and
     *Log 0214 · The Quiet* (truth: the night it stopped rather than purge record 0522). Carry two.
     The Council Chamber it restores comes with the final choice (next step).
161. **Teo's turn** is at the dock, setting off for the Spire, like Noor's going ahead: he says what he
     thinks you'll do to it; with his trust at −3 or below he leaves the Ark ("I won't watch you take
     it apart.") and is gone from the run, and Rewrite with him; otherwise he stays and says so. Once.
162. **Subtitles wrap.** A line wider than 1500 px (at subtitle scale 1) breaks onto rows, centred on
     one backing, the last row where a single line always sits. The Spire's lines are the first long
     enough to need it; before, a long line ran off both sides of the screen.
163. **The Council Chamber** (restored by the Spire's Reliquary) is sunk into the foundation behind
     Noor's spot on the Ark, a low round chamber with steps down and its doors on the far rim: the
     Steward's in gold, a plain grey one, and the Rewrite door in cyan only if the run has earned it
     (otherwise no third door at all). Its door opens the final choice. Low, it hides nothing behind it.
164. **The final choice.** Reboot and Unplug are always offered; Rewrite only when its three conditions
     hold (EndingRules: Noor and Teo both still with you, the voice on for 35–65% of play, five truth
     cores kept), and otherwise it isn't shown. Picking a door asks once more ("NOT YET" is focused, so
     an extra press of accept can't end the game); confirming is final: the run's `ending` is saved,
     its location becomes "ending" (nowhere Continue can go), and the epilogue plays. The Steward's word
     at the doors: it won't say which.
165. **The epilogues**, card by card (Endings.EPILOGUES), then the credits, then the title. Accept moves
     on a card. **Reboot:** its voice, warm and unbroken, its words in its serif and gold, ending the
     sentence the Quiet cut off ("Good morning, Meridian. Today will be a good day."). **Unplug:**
     total silence: nothing plays, the ambience and the voice stop and the master bus is muted until it
     ends; its words are plain type. **Rewrite:** it speaks to Noor, to Teo and to the Commons, in its
     serif but in the cyan of what was found, not its gold.
166. **A finished run is kept, not continued.** The title greys out Continue for a run with an ending;
     New Game starts again. **A Rewrite is remembered past the run** in a small file beside the save
     (`legacy.json`, untouched by New Game): from then on the title's ring settles with its gap filled
     in cyan. Automated runs start without it.
167. **The campaign plays to an ending.** After the Spire it goes down into the Council Chamber and
     takes Rewrite if the run has earned it, otherwise Reboot, watches the epilogue to the credits, and
     ends on the title after it (the finished run kept, Continue greyed out). It is the whole game in
     one run now; its limit is 1500 s (it takes about 1100).
168. **The gate plays all three endings** besides, each from a prepared run home from the Spire
     (`ending_reboot`, `ending_unplug`, `ending_rewrite`): into the chamber, the doors on offer (two
     without Rewrite's conditions, three with), asked once more, the epilogue's voice or its silence,
     the credits, the title's ring after (gap filled only after a Rewrite).
169. **Act 3 review, round 1.** A confession is **heard out**: one asked for while another is being said
     waits its turn (`Narrator.say_in_full` queues it; dropped if the Steward can't say it when its turn
     comes), and nothing else cuts in, its other lines nor a screen's voice-over (opening the Reliquary
     during the last one doesn't replace it). Leaving the district drops what's still waiting.
170. **Act 3 review, round 1.** The **curfew patrol comes once**: carrying Noor again after being downed,
     the Wardens still standing come after you again; none are added.
171. **Act 3 review, round 1.** The **ending is saved before it plays**: if the save fails the player is
     asked (try again, go on without it, or stay); staying takes the choice back, nothing decided. The
     Rewrite's record (`legacy.json`) is written like the save itself (read back before it replaces the
     last good one, which is kept as a backup), only once the ending is saved; a finished Rewrite on
     file counts on its own, and the title writes the record down if it's missing.
172. **Act 3 review, round 1.** Harbor Ward has **the Ward's own mast**, dark, on the boat-house roof by
     the gate (its radio log below it), and **two Wardfolk on Net Lane** who talk (the curfew, Noor
     going by); once the Commons is built, two of them stand by it on the Ark (design/act-3.md).
173. **Act 3 review, round 2.** A run on file that ended in a Rewrite is never replaced before the
     Rewrite's record is written: every save writes the record down first if it's missing, and if it
     can't, the save fails (the player is told) and the finished run stays. A record is judged by its
     fields, not just by whether it parses; a broken main file gives way to a good backup.

## Milestone 5: deeper districts, harder bosses (planned)

174. **Noor's Mast counts; it doesn't point** (the user's call; replaces 156's rings). With it on the Ark
     each district's map says how many unindexed places are still to find there ("MAST · 2 UNINDEXED
     HERE", in the Ward's cyan, voice on or off), never where. Finding them is the player's to do.
175. **Revisits harden by what you took from that district** (the user's call): the more of a
     district's truths you've carried out, the harder its enemies are when you come back. Only that
     district's truths count, not the run's.
176. **Truths found on a revisit go straight to the Archive** (the user's call): a district's Reliquary
     opens once; what you find when you come back is filed without a core choice.
177. **Dying in a boss fight restarts it** (the user's call): the boss you hurt is gone with its weak
     point, the lanes or rollers it works and whatever it had in the air, and a fresh one stands where
     it was built, at full strength and its first stage; you're back at the checkpoint at the arena's
     door at full Integrity. It doesn't introduce itself again, and won't engage for 2 s after it's back.
     Its barriers stay shut. (Before, the boss kept the damage you'd done, so dying made it easier.)
     Every boss district has that checkpoint on your side of the barrier within 12 tiles of the boss
     (a test keeps it so); the Tideworks, Mercy General, Greywater and the Vellum got one, just outside
     the boss's reach (their nearest had been 14–33 tiles back, or in the Reliquary's yard behind the
     barrier). The autopilot logs every time it goes down, and plays the Crane better (it rolls out
     from under a load and circles while it aims): it used to win by dying.
178. **The autopilot can't go down** (the user's call). With dying restarting a boss fight, a scripted
     bot that loses one became a flaky gate, and its runs exist to prove the game works start to end,
     not how hard a fight is. So in autopilot runs damage lands (dressings, the tide's sting and the
     rest still play out) but at 1 Integrity the Operator stays up, and the run logs where it would
     have gone down (district, cell, the boss and its health) and totals it at the end; the gate
     prints the total. `--autopilot-mortal` plays it for real, for judging difficulty. The restart
     rule itself is covered by its own test. The bot plays the Crane better all the same.
179. **Boss stages.** A boss can have two or three stages; its fight gets harder as it's taken apart. At
     each threshold of its integrity (two thirds and one third for three stages, half for two) it stops
     for 3.2 s: it can't be hurt, the Steward says what's changed if it can see it, and then it fights
     its next stage. One blow never carries it past a threshold. The boss bar is notched where its
     stages begin. A restarted fight starts at stage 1. Each boss's calls still fit their gaps in every
     stage (its CALL_GAPS and WARN_LEADS hold the tightest timings across its stages).
180. **The Lung in three stages.** Stage 1 as before. **Stage 2, the tide comes up and stays:** past 4
     tiles from it the basin is deep water that wears you down (6 every 0.8 s you stand in it; a roll
     clears it like any hit), and it fills faster (1.0 s, from 1.2). Turning the hand valve, 5 tiles
     out, now means wading in. **Stage 3, the Marrow rolls in:** fog past arm's reach; it can't see you
     (its floods fall where they fall, not where you are) and neither can the Steward (no calls at
     all: you read the grates' red light yourself), it fills faster still (0.85 s), the deep water
     comes in to 3.6 tiles, and it vents for less (2.8 s). The Steward: "The tide's in. Stay close."
     and "The Marrow. I've lost you."
181. **Holds and descents** (design/deeper-districts.md), built to reuse. **A hold** is a crank ('@' its
     id; data/holds.json its numbers and words): start it and it runs while you stay within 3.5 tiles,
     pausing when you don't; its waves of the Steward's machines come out at the map's spawn points as
     it goes (and they come for you: sent to stop you, they don't give up); done, it opens the
     passage it kept shut, for the rest of the run (`holds_done`, saved). Downed, it starts over and
     what it brought out goes. Its light and its bar are human cream. **A passage** is a pair of
     ladders ('<name>_down', '<name>_up'): a short fade and you're at the other end. A shut way down
     says why, and what's still to find below glows up through it in truth cyan. **A descent** is a
     separate dark place below the street (culvert floor: off the Lattice): the dark closes in round
     your hand lamp, which is on down there whatever the Steward's doing.
182. **Greywater in three movements.** The seawall and the low streets as before; then on the station
     apron, **Pumping Station 2's hand crank** (beside the one still waiting to be told to run the
     pumps): run the pumps by hand for 50 s while the Steward sends three waves of Custodians out of the
     other stations' doors ("Those are mine to run. Leave them, or I'll have to stop you."); that drains
     the sump. Then **down the old pump room's stair into the sump galleries**: a landing, a tunnel, a
     gallery with machines in it, a side room with someone still waiting, and the outfall chamber
     where the last shift hid the brass plaque (moved down from the pump room wall). Then back up,
     the Marrow, and the Lung in its three stages.
183. **Every boss in stages, part 1.** **The Conductor** (two stages): at half it runs express: two
     lanes at once (the one you're on and another), carriages half again as fast, the lights up for 1.3 s,
     and the Steward calls the lane that's clear ("Left's clear.") instead of the one that's coming.
     **The Surgeon** (two stages): at half, triage: it cuts in a cross, a second line across the first,
     lines up faster (0.85 s), and its mist creeps in to 1.4 tiles from the table. **The Crane** (three
     stages): at two thirds it lifts two loads at once, the second beside the first across the jib (step
     out along the jib, not across it); at one third a leg buckles and it goes over toward you along a
     line it shows you for the whole pause (off the line, or 30 damage), and lying across the pier it
     aims quicker (0.75 s) and rests less (2.8 s). Each has its word as a stage begins.
184. **Every boss in stages, part 2.** **The Editor** (three stages): at two thirds its rollers leave
     the headlines wet behind them, three pools of ink on the hall floor after each roll that sting while
     you stand in them (5 every 0.6 s) and dry in 8 s; at one third its presses run backwards (the
     rollers come back toward it) and it rolls three times a cycle. **The Warden-Prime** (three stages):
     at two thirds it calls two Wardens in off the border, hunting you, and its light sweeps faster
     (2.6 s); they're linked through it and drop when it falls; at one third the relay mast burns out (no
     stalling it any more) and, blind, it stops sweeping and charges, again and again, each called a
     second ahead. Kestrel Heights has no boss, and the Spire has no fight, on purpose.
185. **Holds and descents in the Loop and the Tideworks**, the same parts as Greywater's, smaller (45 s,
     three waves of Custodians each). **The Loop:** on platform B, **throw the points by hand** ("That's
     my junction. Let go of it."), which unlocks the service hatch beside them; down it, **the service
     tunnels inside the viaduct**: someone still waiting there and the maintenance crew's handset log
     (they walked the ring for six hours carrying people out; the Steward logged them as unauthorized
     personnel). **The Tideworks:** on the quay, **wind the hanging container clear by hand** ("That
     load is mid-lift."), which clears the beached freighter's hatch; down it, **the freighter's hold**:
     someone waiting and the night shift's hand count of the last cargo, chalked on a hatch board (40
     crates of insulin off; the Steward's manifest said 12; 28 went up the hill). The full campaign
     run's time limit goes to 2100 s to fit the longer districts.
186. **Holds and descents in Mercy, the Vellum and the Ward.** **Mercy General:** in the ambulance
     yard, **crank the emergency generator** ("That generator is for emergencies. Leave it."), which runs
     the morgue lift; down it, **the morgue**: one of the Waiting among the drawers, and the attendant's
     ledger, which gives twelve dead their names where the Steward wrote "within acceptable losses".
     **The Vellum:** in the newsroom, **haul the paper lift up by hand** while Clerks and Custodians
     come off the press floor; down its shaft, **the sorting floor**: one of the Waiting, and the galley
     proofs of four stories about the bridge, every one set in type and stamped SPIKE. **Harbor Ward:**
     on Net Lane, **wind the Ward mast's hand generator** while the curfew patrol comes in from both ends
     of the lane (one Warden, then another: a
     Warden takes some stopping, and the Ward has no Steward to help); it opens the ferry hatch on the mast's circuit; down it,
     **the drowned ferry**: one Warden on the car deck, and the night ferry's passenger roll (the Ward's
     mast heard the bridge was failing and they ran the ferry: forty-one aboard, forty-one ashore). The
     Steward says nothing about the Ward's: it can't hear it.
187. **Revisits** (175 and 176, built). On the Loop map a district you've done can be gone back to (not
     the Spire: the run ends there), and it says how hard it is now; setting off again plays no turn at
     the dock. Back in it, its boss stays beaten and its barriers open, its hold stays done, and
     what you found, carried or woke isn't there again; nor are the cores you left at its Reliquary
     (the run remembers them now: they're gone). Its machines harden by how many of its truths you've
     carried out (its Reliquary's and its map's; nobody else's): **one**, a second Custodian beside
     each one placed; **two**, windups a fifth shorter (a Custodian's 0.55 s becomes 0.44 s); **three**,
     elites, half again as hard to take apart and 15% faster, a pale double ring at their feet. What
     they hit you for never rises. Every machine gives up twice the parts. A truth found there goes
     straight to the Archive (carried, its log filed; "FILED TO THE ARCHIVE" over the cache), and the
     Reliquary, opened once, is the way home ("BACK TO THE ARK"). The gate plays a revisit: Mercy
     General, done once without going down to the morgue.
188. **Tool doors** (design/deeper-districts.md's reason to go back). A door one of the Ark's tools
     opens, with a truth behind it you couldn't have had the first time: you need the tool with you
     (in the loadout you set off with), and without it the door says what would open it ("The Signal
     Jammer would open it. It's on the Ark."). Opened, it stays open; while its truth is still there,
     it glows at the sill in truth cyan. Three, in the districts you reach before their tools: **Kestrel
     Heights**, the funicular's gatehouse below the stop, on a Steward lock the **Signal Jammer** jams:
     the gatekeeper's list (the Steward scored residents for the first car down; at 03:10 the
     gatekeeper opened the gate by hand). **The Loop**, signal box 4 over platform A, its lift dead
     until the **Defib Gauntlet** jolts it: the signalman's register (every train held at the Quiet but
     one, the Council's). **The Tideworks**, the customs shed behind the quay's containers, on a Steward
     lock the **Jammer** jams: what customs impounded (the Harbor Ward radio society's mast parts, held
     three years for "unlicensed broadcast"). The gate plays one: back to Kestrel with the Jammer.
189. **Rewrite needs eight truths** (from five). There are 24 truth cores now (16 before milestone 5):
     eight is about a third, as five was. On first visits you can carry two cores a district, so a run
     that favours truths gets there; one that doesn't can make it up on revisits, where every truth
     found goes straight to the Archive.
190. **Milestone 5 review, round 1** (reviews/deeper-districts.md). **A boss fight you lose is settled as
     you go down** (BossEncounter, out of Level): from then nothing can hurt the boss (a shot you'd fired
     can't finish it and skip the restart), and you're back at the checkpoint by its arena's door,
     whichever checkpoint you'd touched. **A new stage's word waits** for the call the Steward is still
     saying for that boss (or a warning), up to 3 s, instead of cutting it off; the pause between stages
     counts from its word. **Hardening is real**: a quicker windup strikes when its shorter telegraph
     runs out, and an elite Warden stays faster on the hunt and on its beat. **Only the Steward's own
     refusals** (a sealed ward, the Waiting it won't wake) take its serif and gold in a blocked prompt; a
     shut hatch, a locked door, the Reliquary, Noor and the boat say why in plain type. **The Lung's deep
     water** stings only where it's drawn. **A running hold's bar** redraws as it runs. **Saves from
     before revisits** (version 2) can't tell a truth left at a Reliquary from one never found, so nothing
     counts as left: a truth you left then can be found on a revisit (better than losing one you never
     found); saves are version 3. **The Loop map**, with nothing new open, offers the districts you can go
     back to. A hold's machines come out well clear of the district's boss (Harbor's from the middle pier,
     the Vellum's from the newsroom's far side), so fighting them doesn't bring the boss in. The holds,
     ladders, tool doors and descents moved out of Level too (Descents). And the loadout's cards keep
     their words on them.
191. **The Warden-Prime sees you only on its Lattice.** It's the Steward's: within reach, it starts the
     fight only once you're on the Lattice (in the Ward, the border gate and the plaza past it), never
     from across the fence on the Wardfolk's lanes, however close. Fighting the curfew patrol by the gate,
     or winding the mast's generator on Net Lane, no longer brings it into a fight you haven't walked into.
192. **The Steward doesn't repeat itself** (design/writing-review.md, Bastion's rule). A line isn't
     heard again this run until the rest of its tone has been, the district's own lines first and then
     the lines for anywhere; a district's entry, boss and Reliquary lines are its own when it has them.
     Every district you fight in has its own lines for everything the Steward reacts to (kills, close
     dodges, getting hurt, going down, standing still, leaving and rejoining the path, aiming by hand,
     coming back from mute, the boss going down): about 340, most of them telling you something you
     couldn't know about the place or the machine you just stopped, and the flattery profiling you as it
     goes ("You don't wait for them to finish turning. I've noticed that about you."). Kills, close dodges
     and hurts are remarked on a little less often (10, 9 and 10 s apart). Coming back from mute, it
     speaks in the district's words (its own lines for that were never reached). Each of the Waiting has
     their own words when woken (data/companions/waiting.json).
193. **The Steward knows where you are.** A map can name places it remarks on ('& x,y line_id', one of
     its fixed lines): within two and a half tiles, while it's with you, it says the line once a run, and
     only into a silence (never over itself, a warning or a line being heard out). Forty-two of them,
     five to eight a district, each on the lit path and each telling you something about what you're
     looking at that you couldn't have known ("Gate 4. I held it three seconds once, for a man running
     for the 07:20. He made his train." "Somebody drew these arrows the first night. They all point to
     the yard."). Muted, or off its Lattice, it says nothing; come back and it may.

194. **Painted art starts in Kestrel Heights.** The approved local city block, hillside houses and
     character lineup guide the first six runtime PNGs in `assets/art/`, generated with the built-in
     image_gen tool; the prompts are kept beside them. Material UVs follow the existing 128 by 72
     diamonds, and building faces remain separate so adjoining cells still hide their joined walls.
     DistrictLook selects the five Kestrel materials explicitly. The painted Operator's front and rear
     still poses keep their foot pivot, mirroring and procedural motion; directional animation is a
     later pass. Gold is drawn separately, including the earpiece, so muting can extinguish it. Mipmaps
     and matching filtering keep the downscaled paint stable. This starts the art pack; ornate facades,
     props, enemies and other districts remain to be painted.
195. **Kestrel's painted details keep live lighting.** Six transparent assets add carved window and
     door surrounds, balcony ironwork, trimmed hedges, blossom urns and unlit lamp housings. Tight
     AtlasTexture crops preserve the generated PNGs; a single balcony section also supplies the
     connected terrace railings. Polygon UVs account for atlas regions. Buildings draw window light,
     then shaded ornaments, then the switchable gilt, so light shines through the openings and gold
     remains over the ironwork. The lamp aperture maps to its existing lens center at 150 px above
     ground. DistrictLook selects these details only for Kestrel. Maps and collision remain as built.

196. **Painted coverage reaches every district and physical render owner.** The full inventory has
     30 physical terrain kinds (VOID remains empty space; BUILDING is painted by its sorted node),
     23 scenery kinds, 18 facades, all actors, six enemy families, six bosses and their moving parts,
     fixtures, pickups, tools, illustrations, backgrounds and navigation map. The built-in image_gen
     tool produced 24 new sheets, guided by the local concepts; all prompts and original PNGs are
     preserved. ArtCatalog caches 162 named frames and source anchors; missing bindings fail loudly.
     Atlas crops and material UVs preserve existing ground diamonds, joined faces and depth sorting.
     Lamps, windows, gilt, the canonical ring, path, weather and combat effects stay live. Carrying
     has painted front/rear poses, remains visible during a dodge, and stows equipped tool graphics.
     The map keeps industrial districts and rectangular black-glass towers; the Council Chamber
     descends into its foundation. Runtime catalog JSON is included explicitly in exported packs.
197. **Retired fittings and headless captures cannot block the gate.** A retired weak point clears its
     collision layer and mask even if it was already dead, so the Operator can cross its cell after
     the fight. This resolves Harbor's baseline relay obstruction. Screenshot requests return directly
     with a headless display rather than waiting for a frame that cannot arrive. Movement through the
     retired relay and headless screenshot completion have regression checks.
198. **Painted previews use a separate save slot.** The art stage selects a scratch save directory
     and settings path before preparing synthetic runs or opening levels. The initial stage omitted
     this and wrote preview data into the normal local save and its rotating backup; no earlier copy
     was found. Those affected files are preserved in the ignored validation reports. A complete
     native preview now leaves the normal save files unchanged. Panorama drift clamps within its
     overscan without wrapping, and dead kiosk and desk screens retain the canonical ring afterimage
     projected into their painted monitor planes.
199. **Art imports run serially.** Two parallel empty-cache imports crashed while Godot 4.7.2 saved
     the existing Fraunces italic font. Retry imports passed. Font-only and unchanged-HEAD cold
     imports did not reproduce the crash, so its baseline cause remains unproven. A full fresh copy
     passed with serial imports, then a second fresh copy passed with the same setting in
     project.godot. This editor setting avoids the observed import failure without changing play.
200. **The Steward changes as you learn.** A line can carry a condition ('when': back in a district
     you've done or not, a number of truth cores carried, a memory log read). A line whose condition is
     about something you've come to know is said before the others, once. So it greets a revisit as one
     ("Kestrel Heights again. Still very tidy."), with a line of its own if you've read that district's
     worst ("You know who went down the hill first now. It's still a pretty street."); a first visit's
     greeting and Reliquary line are never said on a revisit, and an opened Reliquary is spoken of as one.
     As you carry truths it stops pretending ("Off the path again. I've stopped telling you there's
     nothing there."), and once you've read the bridge record, Prem's last note or the Council's order,
     it has something to say about each when you stand still. The full campaign run's time limit goes
     to 2700 s (from 2100): the campaign now takes 30 to 31 minutes, and one slow Warden-Prime fight ran it
     past the old limit.
201. **The logs, the menu and continuity** (design/writing-review.md). Teo argues as well as confesses:
     ten of his lines now defend the Steward where it was right (the welded cabs, the paper backups it
     asked for, the fever doors, the transmitter rule), so most of his forty-four aren't confessions (a
     test keeps it under a quarter), and in two logs Noor and Teo agree. Fewer stock moves ("Somebody…",
     "That isn't nothing", "I signed off", "I was in the room"), and no line of the Steward's reactive
     narration says the same words as another (a test). The ending choices no longer pass judgement:
     Reboot "The lamps come back, and the city runs again tomorrow"; Unplug "Whatever happens next, people
     decide"; Rewrite "people who can tell it no". Continuity: the Quiet was at 02:14 in every record; the
     signal box's register runs after it, the Council on the phone; one Rosa (the night nurse; the child
     who drew the map is Lila) and the running man at Gate 4 is M. Ferris.
202. **What the Steward knows, and when it talks** (reviews/writing-pass.md, round 1). Its lines know a
     memory log only once you've read it (replayed in the Archive or opened at the Clinic), not as soon
     as you carry it. What it's said this run is saved with the run, so Continue doesn't hear its place
     lines and beats as new. A beat, once heard, leaves the pool for the run, unless it's all the event
     has (a district's one revisit greeting). Lines can carry their own purpose, so what it knows (the
     bridge, Vashti, the order) still plays under "Stop praising me" while its flattery doesn't. A hold's
     lines and a place's line are its story: no remark starts over them (a warning still does). Everything
     else keeps the old timing, because a remark that cut a boss's call short was holding the fight's
     pace. A hold's lines also hold off its other fixed lines (a reply, a find's line), though not a
     warning or a boss's call; a place's line gives way to them. A place's line waits 1.5 s after it last
     stopped talking. Nineteen lines rewritten so they say only what it can see, keep to canon
     (Platform A: six years) and stop cheering.
203. **It says what it saw** (reviews/writing-pass.md, round 2). A reactive line claims only what its
     event knows. A kill knows how far away you were: a line can need `reach` "close" (within 1.8 tiles)
     or "far" (3 or more), and is said only then. A hit, a close dodge, halfway and a boss down know
     that it happened, not what you did around it, so their lines say what the Steward expects of you or
     what you beat, not where you stood or what you did next. A beat heard leaves silence behind it,
     except a district's one revisit greeting. Two kills at once are "close" or "far" only if both were.
     A kill also knows what died (a Custodian, a Salvager, a Clerk, a Sterilizer), so a line about a
     machine's job ("It was mopping a street the sea had already taken.") is said only for that machine.
