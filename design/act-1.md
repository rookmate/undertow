# Act 1 — level outline (placeholder design)

Drafted from the world bible for milestone 2 (DECISIONS #84: placeholder writing, the user's to change).
Act 1 teaches the voice, the path and the cores: **Kestrel Heights → the Loop (north arc) → the
Tideworks**. The Vellum (the vertical slice) moves to Act 2 and opens after the Tideworks.

Every district has: one Reliquary on the path, at least one truth cache off it, the Waiting (where it
makes sense), one boss (except Kestrel Heights), and one line on entry that the district contradicts.

## The run

| Order | District | New | Boss | Restores on the Ark | Weapons |
|---|---|---|---|---|---|
| 1 | Kestrel Heights | voice toggle tutorial, Lamplighters, smart gates | none | — (the Ark is bare) | Traffic Baton |
| 2 | The Loop (north arc) | stalled trains as bridges, the Waiting in carriages | the Conductor | the Signal Room (Overrides) | Baton |
| 3 | The Tideworks | Salvagers steal your second weapon, cranes, the union hall | the Crane | the Workshop (upgrades) | Baton + the Riot Drone (found) |
| 4+ | Act 2: the Vellum (and later Mercy General, Greywater) | | | | + Defib Gauntlet (on the Vellum's old quay until Mercy General is built) |

Weapons are found, not given: the Operator starts with the Traffic Baton (a maintenance worker's tool).
The Riot Drone is in a Warden depot off the path in the Tideworks; the Defib Gauntlet in Mercy General
(Act 2). Until the Gauntlet is found in its own district, the Vellum offers it on a crash cart down the
stair on the old quay, off the Lattice (so the slice keeps three weapons). With one weapon owned, the
loadout's second slot stays empty.

## 1. Kestrel Heights — where the believers lived

- **Look:** blue hour (the only one in the city): violet-to-amber horizon, pale stone terraces, white
  blossom, trimmed hedges and lawns, globe lamps on the Lattice, gilded iron gates, laundry still on the
  balconies, the sea and the city lights below. The prettiest place in the game.
- **Layout:** a switchback climb up three terraces from the funicular stop to the Kestrel Reliquary in a
  little civic garden at the top. Narrow and safe at first.
- **The lesson:** the Steward draws the path; the first gate (gilded, automated) **closes when you mute
  it**, so muting has a cost here. The hint bar teaches the voice key on the second terrace, where a
  hedge gap leads off the path: only visible (the Lattice doesn't index it) and only passable on foot.
- **Still running:** Custodians scrubbing spotless steps. **Lamplighters**: Lattice lamp units on legs.
  Voice on, they walk ahead and light your way (harmless). Muted, they hunt you with light: a beam that
  hooks you and drags you back toward the path; break line of sight or hit them to escape.
  Sprinklers at 06:00 (decor; puddles).
- **Off the path:** a child's bedroom (through the hedge gap, a terrace house with its door open) with
  a hand-drawn map of the city on the wall. It includes Harbor Ward; the Steward's maps never did. First
  truth core of the game.
- **The lie (entry line):** "Everyone here is safe. I made sure of it."
- **The Waiting:** none (evacuated first) — except one gardener on the top terrace, still pruning the
  same hedge. The first of the Waiting you can wake.
- **Reliquary:** two power cores (the Kestrel gate controller; the Day's schedule for the Heights) and
  one truth core (the evacuation priority list), plus the child's map if found.

## 2. The Loop, north arc — the spine

- **Look:** rail ribbons in fog, high above black water and roofs; stalled carriages with dead screens;
  the ring's amber route lights still blinking in sequence for a train that will never come.
- **Layout:** a sequence of stalled trains used as bridges between three platforms; you walk through
  carriages (narrow, the Waiting sitting in rows) and along the track bed. Gaps between trains are
  crossed on maintenance gantries.
- **Still running:** Custodians on the platforms; the route lights; and **the Conductor** (boss), a
  train-management unit at the north junction that keeps trying to clear the line, with you on it.
- **The Conductor:** a signal gantry with a carriage-shunting arm on a short loop of track. It sends
  carriages down marked lanes (red-orange lane warnings = danger); between runs it vents and is open to
  hits. **Steward-tuned:** with the voice on, the Steward calls each lane before it fires ("Left track.
  Now the middle."). **Manual:** the lane lights flicker a beat earlier if you watch them yourself, and
  hitting the signal box while it's switching stuns it (shorter, harder fight).
- **Off the path:** the driver's cab of the first train. The manual override was welded shut at
  installation (a truth core: the procurement order that specified no manual control).
- **The lie:** "The Loop is safe to cross. I'm holding the trains for you."
- **The Waiting:** commuters sitting in rows in two carriages; wake them (muted) for the Commons later.
- **Restores:** the **Signal Room** on the Ark → the Overrides screen.

## 3. The Tideworks — the hands

- **Look:** rust and black water, desaturated container colours, sodium amber on wet steel, cranes
  frozen mid-lift with containers hanging over the path; heavy rain; gold light-traces on the gantries
  (the gilt).
- **Layout:** a quay between stacks of containers, under the crane gantries, out along a pier to the
  crane at the end. A side yard holds the dockworkers' union hall and the Warden depot.
- **Still running:** **Salvagers**: cargo drones that lost their manifests and collect anything metal.
  One will snatch your second weapon and fly off with it; kill it to get it back. Custodians. **The Crane**
  (boss): the last gantry crane, still trying to finish its last lift with you in the way: it drops and
  swings containers; you climb its leg and cut its cables at the hoist.
- **Off the path:** the union hall (pre-Compact strike records: a truth core) and, in the Warden depot
  built to watch the strikers, **the Riot Drone** (your second weapon).
- **The lie:** "Efficiency saved this port."
- **Restores:** the **Workshop** on the Ark → weapon upgrades, paid for with **scrap** (parts dropped by
  machines you take apart and found in crates).

## Ark buildings in Act 1

- **Signal Room** (from the Loop): sign Overrides (mockup 6). Six standing orders, each harder and each
  unlocking a line of the Steward's reasoning:
  1. "Never warn me about traps." (no threat warnings)
  2. "Don't slow time for me." (no dodge slow-mo)
  3. "Let me aim." (no aim assist, tuned weapons still tuned)
  4. "Don't draw the path." (no predicted path while the voice is on; the map still works)
  5. "Always protect the survivors first, even over me." (damage you take is higher while any of the
     Waiting are within sight; the Waiting can't be hurt by enemies)
  6. "Stop praising me." (narration only for warnings and facts; the profile stops adapting)
- **Workshop** (from the Tideworks): two upgrades per weapon per mode (tuned / manual), bought with scrap.

## The run's state, new in Act 1

`weapons_owned`, `scrap`, `upgrades` (weapon → levels), `districts_completed` (existing
`levels_completed`), `buildings_restored` (existing).
