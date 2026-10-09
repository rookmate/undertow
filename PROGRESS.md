# Progress

Milestone: **vertical slice** (design brief, "First milestone"). Plan and decisions: see DECISIONS.md.

| Step | What | Status |
|---|---|---|
| 0 | Skeleton: settings, input map, autoloads, tracked state + saves, test runner, gate, palette, fonts, title with canonical ring | done |
| 1 | Isometric movement, dodge, greybox Vellum street | done |
| 2 | Combat with two-weapon loadout, tuned/manual modes | done |
| 3 | Predictive path, hidden off-path area | next |
| 4 | Voice toggle: assists, map, narration, lighting | |
| 5 | Adaptive narration from tagged line pools | |
| 6 | Level end with power-vs-truth core choice | |
| 7 | Ark hub with the Archive | |
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

## Next

Step 3: the Steward's predicted path (three gold tiles ahead, routed over the Lattice's cells only),
and the off-path stacks hidden from it (the Waiting, a truth cache, an unindexed log).

## How to run

```bash
godot --path .                       # play (title screen)
godot --path . -- --debug-overlay    # start with the tracked-state overlay open (F3 toggles it)
```

## How to test

```bash
tools/check.sh                       # the full gate: import, tests, 30 s autopilot run
godot --headless --fixed-fps 60 --path . res://tests/test_runner.tscn            # tests only
godot --headless --fixed-fps 60 --path . res://tests/test_runner.tscn -- --filter=save   # some tests
tools/record.sh <name> [seconds] [scenario]   # progress video -> ../undertow-recordings/<name>.mp4
```

Autopilot scenarios (`-- --autopilot --autopilot-scenario=NAME`): `slice` (default: title → loadout
→ level, fighting up the street), `ring_gallery`. Runs of 55 s or more also expect the route to finish.
Gate logs and screenshots land in `reports/check/` (ignored by git).
