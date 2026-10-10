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

