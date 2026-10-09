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
| 7 | Ark hub with the Archive | next |
| 8 | Tracking finished + debug overlay + save round-trip | |
| — | Sol analysis review (reviews/vertical-slice.md), fixes, re-check | |

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

## Next

Step 7: the Ark hub (concrete disc in the estuary, ring of gold floor lights, the restored Archive,
survivors, Noor and Teo) and the Archive screen (log list, decision-record replay, the Steward's
present-day comment, Noor's and Teo's reactions with trust changes).

## How to run

```bash
godot --path .                       # play (title screen)
godot --path . -- --debug-overlay    # start with the tracked-state overlay open (F3 toggles it)
```

## How to test

```bash
tools/check.sh                       # the full gate: import, tests, 30 s run, 90 s full-slice run
godot --headless --fixed-fps 60 --path . res://tests/test_runner.tscn            # tests only
godot --headless --fixed-fps 60 --path . res://tests/test_runner.tscn -- --filter=save   # some tests
tools/record.sh <name> [seconds] [scenario]   # progress video -> ../undertow-recordings/<name>.mp4
```

Autopilot scenarios (`-- --autopilot --autopilot-scenario=NAME`): `slice` (default: title → loadout
→ level, fighting up the street), `ring_gallery`. Runs of 55 s or more also expect the route to finish.
Gate logs and screenshots land in `reports/check/` (ignored by git).
