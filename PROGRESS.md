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
| — | Sol analysis review (reviews/vertical-slice.md), fixes, re-check | done (4 rounds; closed) |

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

**Review fixes (round 2).** Exact wall traversal for shots and sight, broken maps return to the title
through the router, broken Reliquaries can't complete a level, boot-time map/content check across
districts, the modal stack owns focus/input/draw order, serialized close requests, autopilot scenario
validated before disk access, bounded survivor placement, Archive usable with a pad at any content
volume. 228 tests.

**Review round 3–4.** A district's own Reliquary must be valid; found cores never stand in for it.
Sol's closure check found nothing open. 229 tests.

**Milestone status: the vertical slice is done and reviewed.**

## Milestone 2: Act 1 (in progress)

Following the world bible's order. Same gates per step, a video per visible step, Sol analysis review
at the end. The user's answers (2026-10-09) are in DECISIONS.md 80–87.

| Step | What | Status |
|---|---|---|
| 9 | Audio: buses, `Sound` service, synthesized placeholder SFX and ambience, hooks in play and UI | done |
| 9b | Voiced narration: placeholder text-to-speech for every Steward line, played with its subtitles | done |
| 10 | Options: volumes, display, subtitle size, key and pad rebinding, saved settings | done |
| 11 | District structure: acts and unlock order, found weapons, scrap and upgrades in the save (v2), the Loop map from the Ark dock, per-district look | done |
| 12a | Kestrel Heights: the district (terraces, lawns, hedges, planters, sprinklers, smart gates, laundry, blue-hour look), its cores, logs and voiced lines | done |
| 12b | Kestrel Heights: Lamplighters, the child's room, the gardener, the voice tutorial | done |
| 12c | New Game starts in Kestrel Heights with the baton; autopilot routes for Kestrel and the Vellum | done |
| 13a | Bosses: the framework (armour and openings, HUD bar, voiced callouts, barriers) and the Conductor | done |
| 13b | The Loop (north arc): stalled trains as bridges, the Waiting in carriages, the driver's cab; the Conductor at the junction; route and tour | done |
| 14 | The Signal Room and the Overrides screen (mockup 6): six overrides with effects and Steward replies | done |
| 15 | The Tideworks: cranes and containers, Salvagers, the union hall, finding the Riot Drone, the Crane | done |
| 16 | The Workshop: scrap and weapon upgrades | done |
| — | Sol analysis review (reviews/act-1.md), fixes, re-check | done (3 rounds; closed) |

**Review (reviews/act-1.md).** Sol found 13 problems in round 1, all fixed over three rounds (decisions
111–123): weapons and aim assist now respect who may be struck (friendly Lamplighters, weak points);
weapons survive finds and snatches; every Steward line has a purpose that the standing orders
govern; the Vellum offers the Defib Gauntlet; rebinding checks every binding; damaged settings and saves
are normalized; boss maps must be playable; the autopilot is split into infrastructure, scenarios and
district routes, with a campaign (New Game to the Archive, save and Continue in between) as the gate's
long run; subtitles keep the voice's own clock; the gate checks its own district listing. The gate also
caught a leak at exit (sounds started while quitting), now fixed. 317 tests.

**Milestone status: Act 1 is done and reviewed.**

## Milestone 3: Act 2 (done)

Mercy General, the Vellum and Greywater, in any order once the Tideworks is done; Noor and Teo join.
Plan and placeholder design: `design/act-2.md`. Same gates per step, a video per visible step, Sol
analysis review at the end.

| Step | What | Status |
|---|---|---|
| 17 | Act 2's design; Noor and Teo join (they arrive on the Ark after the Tideworks, once) | done |
| 18 | Mercy General: the district (sealed wards, Sterilizers, the night nurses' station); the Defib Gauntlet moves home | done |
| 19 | The Surgeon (boss); still props stop redrawing every frame | done |
| 20 | The Clinic: field dressings (use_item, Q / LB), triage records | done |
| 21 | Greywater: the district (the tide, kelp, the thick Marrow, the manual pump room) | done |
| 22 | The Lung (boss) and the Pumphouse | done |
| 23a | The Vellum's east bank: the footbridge, the newsroom, the deep stacks and Prem Vashti's office, the Reliquary past the press hall; Clerks flash the Feed | done |
| 23b | The Editor (boss) in the press hall | done |
| 24 | Companion conversations after each Act 2 district; the campaign through Act 2 | done |
| — | Sol analysis review (reviews/act-2.md), fixes, re-check | done (6 rounds; closed) |

**Milestone status: Act 2 is done and reviewed.**

## Milestone 4: Act 3 and the ending (in progress)

Harbor Ward, the Spire, the Council Chamber and the final choice; the companions can leave. Plan and
placeholder design: `design/act-3.md`. Same gates per step, a video per visible step, Sol analysis
review at the end.

| Step | What | Status |
|---|---|---|
| 25 | Act 3's design; Reduce flashing (Options, Accessibility) | done |
| 26a | Harbor Ward: no Lattice (muting changes nothing), Net Lane and the piers, the border plaza, the dashcam; Noor goes ahead at the dock | done |
| 26b | The Wardens that hunt | done |
| 27 | The Signal Jammer | done |
| 27b | The Steward's path as a quiet trail (studs and a dashed thread) instead of three gilded tiles | done |
| 28 | Warden-Prime, Noor's turn (carry her or leave her), the border Reliquary, the Commons | done |
| 29 | The Mast; the Commons' people | done |
| 30 | The Spire (no combat; the Steward stops lying); Teo's turn | done |
| 31 | The Council Chamber: the final choice, the three epilogues, the title after Rewrite | done |
| 32 | The campaign to an ending | next |
| — | Sol analysis review (reviews/act-3.md), fixes, re-check | |

## Later milestones (planned)

- The art pack (painted sprites in place of the code-drawn placeholders), the voice actor, the writing,
  GodotSteam (achievements, cloud saves), signed release builds, and testing on real hardware.

## How to run

```bash
godot --path .                       # play (title screen)
godot --path . -- --debug-overlay    # start with the tracked-state overlay open (F3 toggles it)
```

Controls: move WASD / left stick · aim mouse / right stick · weapon 1 LMB (or J) / RT · weapon 2 RMB
(or K) / LT · dodge Space / A · interact E / X · voice V / Y · field dressing Q / LB · pause Esc /
Start · overlay F3 / Back+R3 (debug builds; F5–F8 debug switches while it's open).

## How to rebuild the sound and the voice

```bash
python3 -I tools/make_audio.py      # sound effects and ambience (needs ffmpeg)
python3 -I tools/make_voice.py      # voices new or changed Steward lines (needs Piper, below)
python3 -I tools/make_voice.py --prune   # ...and deletes recordings of lines that no longer exist
```

Piper (placeholder text-to-speech) lives outside the repo. On this machine it was set up with:

```bash
python3 -m venv --without-pip --system-site-packages ~/.local/opt/piper-venv
~/.local/opt/piper-venv/bin/python -m pip install piper-tts
mkdir -p ~/.local/opt/piper-voices && cd ~/.local/opt/piper-voices
curl -LO https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_GB/cori/high/en_GB-cori-high.onnx
curl -LO https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_GB/cori/high/en_GB-cori-high.onnx.json
```

A test fails if any Steward line has no recording or its recording says older text.

## How to export

```bash
tools/export.sh                      # Linux, Windows, macOS into build/, then runs the Linux build 30 s
```

## How to measure

```bash
godot --path . --disable-vsync --max-fps 0 -- --autopilot --autopilot-seconds=24   # prints [perf]
godot --path . -- --autopilot --perf-disable=minimap,lights   # switch features off to cost them
godot --path . -- --autopilot --perf-hide=StaticProp,WardSeal  # hide and stop nodes of these classes
```

## What only hardware can confirm

- Steam Deck: 60 fps in the Vellum street (the `[perf]` line), readable text at 1280×800, the
  controller layout, focus in every screen, the voice toggle on Y.
- A second controller and unplugging/replugging one mid-run.
- Windows and macOS: launch, New Game, save, quit, Continue. macOS will say the app is from an
  unidentified developer (ad-hoc signed): right-click → Open.

## How to test

```bash
tools/check.sh                       # the full gate: import, tests, 30 s run, the campaign, district tours
godot --headless --fixed-fps 60 --path . res://tests/test_runner.tscn            # tests only
godot --headless --fixed-fps 60 --path . res://tests/test_runner.tscn -- --filter=save   # some tests
tools/record.sh <name> [seconds] [scenario]   # progress video -> ../undertow-recordings/<name>.mp4
```

Autopilot scenarios (`-- --autopilot --autopilot-scenario=NAME`): `slice` (default: New Game →
Kestrel Heights → the Reliquary → the bare Ark → the Loop map), `campaign` (one run as a player plays
it: New Game, Kestrel Heights, the Loop and an order signed in the Signal Room, save and return to the
title, Continue, the Tideworks and a Workshop upgrade, then Act 2: Mercy General, Greywater and the
Vellum, each talked over with Noor and Teo on the Ark, to the Archive; ends when done; give it
`--autopilot-seconds=900`), `loop`, `tideworks`, `mercy`, `greywater`, `vellum` (a prepared run
straight to that district and the Ark after it, carrying only what the districts before gave), `ring_gallery`, `options` (the
options screen: a volume, a rebinding), `tour` with `--autopilot-level=ID` (straight into a district:
photographs its start, checkpoints, finds, Reliquary, muted). Runs of 55 s or more also expect the
route to finish. Screenshots (`--autopilot-shots=DIR`) need a window: a headless run never draws.
The autopilot is `autoload/autopilot.gd` (its hands and checklist), `autoload/autopilot/scenarios/`
and one route per district in `autoload/autopilot/routes/`.
Gate logs and screenshots land in `reports/check/` (ignored by git).
