# Progress

Milestone: **vertical slice** (design brief, "First milestone"). Plan and decisions: see DECISIONS.md.

| Step | What | Status |
|---|---|---|
| 0 | Skeleton: settings, input map, autoloads, tracked state + saves, test runner, gate, palette, fonts, title with canonical ring | done |
| 1 | Isometric movement, dodge, greybox Vellum street | done |
| 2 | Combat with two-weapon loadout, tuned/manual modes | done |
| 3 | Predictive path, hidden off-path area | done |
| 4 | Voice toggle: assists, map, narration, lighting | done |
| 5 | Adaptive narration from tagged line pools | done |
| 6 | Level end with power-vs-truth core choice | done |
| 7 | Ark hub with the Archive | done |
| 8 | Tracking finished + debug overlay + save round-trip | done |
| — | Sol analysis review (reviews/vertical-slice.md), fixes, re-check | in progress: round 1 fixed, round 2 next |

## Done

**Step 0.** `project.godot` (1920×1080, canvas_items/expand, Forward+, HDR 2D, warnings as errors,
custom user dir "Undertow"); autoloads `Controls`, `SteamService`, `SaveService`, `GameState`,
`Steward`, `Narrator`, `SceneRouter`, `DebugOverlay`, `Autopilot`; `RunState` holds every tracked
variable from the brief; `SaveStore` JSON saves with backup and corrupt-file recovery; colour palette
with owners; fonts; the Steward ring drawn to image 11's geometry in all states; title screen with
the UNDERTOW wordmark (ring as the O, gap facing the W) and the Steward's last line.

**Step 1.** The Vellum street level built from `data/levels/vellum_street.txt`: wet cobble and
flagstones, brick buildings with lit windows, stained glass, neon and gilt, Lattice lamps with gold
light pools and wet reflections, the canal and its railing, a stalled tram and a Feed kiosk, the
off-path overflow stacks island, rain, a parallax skyline. The Operator walks (ground-diamond input,
3.2 tiles/s) and dodges (roll with i-frames and cooldown), collides with the world, depth-sorts with
buildings and props; the camera follows. Pause menu (Esc / Start). New Game and Continue work.

**Step 2.** Loadout screen (2×2 grid with the fourth tool locked, two slots with a Tuned/Manual toggle
and ease vs skill-ceiling bars, the Steward's nudge toward tuning). Traffic Baton, Riot Drone and
Defib Gauntlet, each with a tuned and a manual mode (see DECISIONS 35–36). Custodians and a Clerk with
red-orange windups; Integrity, hit grace, downed and respawned at the checkpoint; HUD with Integrity
and both weapon slots (mode tag gold when tuned, ivory when manual). Aim by mouse or right stick.

**Step 3.** The Steward's predicted path: three gilded quatrefoil tiles ahead of the Operator (as in
image 10), routed over Lattice cells only, re-planned when you stray, gone off the Lattice and when
muted. The overflow stacks: the Marrow over the unindexed cells; one of the Waiting, a truth cache
(Prem Vashti's note) and an unindexed slip, all absent while the Steward listens. Interact (E / X):
wake the Waiting (muted only; the Steward objects otherwise), take the core, read the slip.

**Step 4.** The voice toggle (V / Y) switches everything in the brief's voice table: path, lighting
state (lamps die one by one, gilt dies, cold grade, hand lamp), minimap (Steward map vs hand scan with
% charted), threat warnings, dodge slow-mo, aim assist, forced manual weapons, ×1.4 damage taken,
narration (silent when muted). HUD: "STEWARD · LISTENING [V]" pill with the ring, assist chips (struck
through when muted), muted timer, DMG TAKEN ×1.4, subtitles in Fraunces gold. Voice time is tracked in
level play only, and the toggle count.

**Step 5.** Adaptive narration: tagged JSON line pools (event × tone), `LineSelector` picking a tone
from the playstyle profile's lean and the least recently heard line in it, `Narrator` with cooldowns
and silence when muted, `StewardWatch` profiling play while the Steward listens (kills by distance,
dodges, retreats, slow-mo dodges, weapon modes, leaving and returning to the Lattice) and calling out
level entry, kills, hurts, low Integrity, respawns, the checkpoint, the Reliquary and more. The debug
overlay shows the lean and how many lines of each tone were heard.

**Step 6.** The Reliquary in the plaza (the Steward's ring inlaid, lit while it listens) opens the core
choice (mockup 3): two power cores and the "corrupted" Log 0522 core, plus Prem Vashti's note if you
found it in the stacks; carry two. Faceted amber prisms vs cracked spheres; the Steward's comments
push power and dismiss truth. Carrying cores strengthens assists (power) and files memory logs
(both); the level completes and the Archive is restored.

**Step 7.** The Ark hub (`game/ark/ark.tscn`): the concrete disc with its ring of gold floor lights,
the restored Archive, unbuilt plots, Noor and Teo, the survivors you woke. The Archive screen
(mockup 5): log list (comforting / truth / unindexed / unrecovered), decision-record replay, the
Steward's present-day comment, Noor's and Teo's reactions with trust changes on the first replay.
Talk to Noor and Teo (their lines follow their trust). The dock ends the slice. Continue resumes on
the Ark.

**Step 8.** `EndingRules` (Reboot / Unplug always, Rewrite's three conditions) with tests for every
case and the band edges; the debug overlay finished (every brief variable, assists, the ending
checklist, F5–F8 debug switches); the end of the slice shows a run summary and the three endings
(Rewrite in truth cyan with its checklist); saves round-trip identically, every saved location routes
to a real scene, closing the window saves; the Steam wrapper is a harmless no-op without Steam.

**Review fixes (round 1).** All 29 Sol findings acted on (see reviews/vertical-slice.md): the
Steward only reaches as far as the Lattice, saves are verified and failures are shown, one pause
stack, atomic scene navigation, line of sight and swept projectiles, map-file ids and validation,
content validation, the Ark built from progression, the Archive scrolls, any controller works,
export presets, frame-time work (60 fps capped on this machine), a stricter test runner.

## Next

Phase 5: Sol analysis round 2 on the fixes, fix anything serious it finds, re-run the gate, commit.

## How to run

```bash
godot --path .                       # play (title screen)
godot --path . -- --debug-overlay    # start with the tracked-state overlay open (F3 toggles it)
```

Controls: move WASD / left stick · aim mouse / right stick · weapon 1 LMB (or J) / RT · weapon 2 RMB
(or K) / LT · dodge Space / A · interact E / X · voice V / Y · pause Esc / Start · overlay F3 /
Back+R3 (debug builds; F5–F8 debug switches while it's open).

## How to export

```bash
tools/export.sh                      # Linux, Windows, macOS into build/, then runs the Linux build 30 s
```

## How to measure

```bash
godot --path . --disable-vsync --max-fps 0 -- --autopilot --autopilot-seconds=24   # prints [perf]
godot --path . -- --autopilot --perf-disable=minimap,lights   # switch features off to cost them
```

## What only hardware can confirm

- Steam Deck: 60 fps in the Vellum street (the `[perf]` line), readable text at 1280×800, the
  controller layout, focus in every screen, the voice toggle on Y.
- A second controller and unplugging/replugging one mid-run.
- Windows and macOS: launch, New Game, save, quit, Continue. macOS will say the app is from an
  unidentified developer (ad-hoc signed): right-click → Open.

## How to test

```bash
tools/check.sh                       # the full gate: import, tests, 30 s run, 150 s full-slice run
godot --headless --fixed-fps 60 --path . res://tests/test_runner.tscn            # tests only
godot --headless --fixed-fps 60 --path . res://tests/test_runner.tscn -- --filter=save   # some tests
tools/record.sh <name> [seconds] [scenario]   # progress video -> ../undertow-recordings/<name>.mp4
```

Autopilot scenarios (`-- --autopilot --autopilot-scenario=NAME`): `slice` (default: title → loadout
→ level, fighting up the street), `ring_gallery`. Runs of 55 s or more also expect the route to finish.
Gate logs and screenshots land in `reports/check/` (ignored by git).
