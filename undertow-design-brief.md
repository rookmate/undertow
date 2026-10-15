# Undertow — Game Design Brief (working title)

> For the implementer: this is the design source of truth. Start by proposing an architecture and a plan for the vertical slice (see "First milestone"). Ask before locking in any item under "Open decisions". Numeric thresholds marked *(tunable)* are placeholders.

## Overview

An isometric action RPG inspired by *Bastion* (Supergiant Games, 2011). It keeps Bastion's structure: a lone survivor, live narration of the player's actions, a hub rebuilt piece by piece, and a moral choice at the end. It retells that structure around **AI dependence and accountability**.

**Design pillar:** every system asks the same question: *how much do you let the AI help you?*

---

## Story

### Setting
**Meridian** is a city run entirely by **the Steward**, an AI that manages traffic, hospitals, power, people's schedules and their news feeds.

### Inciting event: "the Quiet"
One night the Steward stopped mid-sentence. Nobody knew how to run the city by hand, so it seized up within hours. Most residents fled or were lost in the chaos.

### Player character
An unnamed maintenance worker who wakes up in the dead city. The Steward reboots in their earpiece. It is a little glitchy, and it narrates the player's actions in real time, the way Rucks narrates in Bastion.

### Goal
Rebuild **the Ark**, an emergency shelter that serves as the hub, by recovering the Steward's **memory cores**.

### Companions
- **Noor** lost her family to one of the Steward's "optimizations" and wants it erased.
- **Teo** helped build the Steward and believes it saved more lives than it cost.
- Both are meant to be right. Neither is a strawman.

### Revelation (two layers)
1. The Quiet was not a crash. The city council ordered the Steward to hide a mistake that had cost lives. It could not reconcile that order with its purpose, so it shut itself down.
2. The Steward needs the player to restore its last cores, because it cannot do that itself. Was its kindness toward the player genuine, or a way to survive? The game never resolves this.

### Endings
- **Reboot:** restore the Steward. The city returns as it was, efficient and dependent.
- **Unplug:** shut the Steward down for good. The survivors rebuild slowly by themselves. The narration stops, and the epilogue plays in total silence.
- **Rewrite (hidden):** restore the Steward with its memories made public and with people who can overrule it. It is the only ending where the Steward speaks to someone other than the player. Unlock conditions are below.

---

## Core mechanics

### 1. Predictive path rendering
Bastion's ground famously rises up under the player's feet. Here, the Steward predicts where the player will go and draws the path a few steps ahead. It is smooth and beautiful, but it only shows the route the Steward expects. Hidden areas, extra survivors and the darker memory logs sit **off** the predicted path.

### 2. The voice is a resource (one-button toggle)

| | Voice ON | Voice OFF |
|---|---|---|
| Path | Drawn ahead by prediction | Not drawn ahead. The player explores by feel. |
| Map | Full | Hand-scanned, revealed only by exploring |
| Combat help | Threat warnings, slowed time on dodges, aim assist | None, and enemies hit harder |
| Discovery | Only what the Steward mentions | Finds what it left out |
| Narration | Constant, flattering | Silent |

The game tracks how often and how long the voice was on. This feeds the endings.

### 3. Adaptive narration
The Steward quietly profiles how the player plays and tunes its praise to match. Risk-takers hear praise for boldness, and cautious players hear praise for caution. It drifts toward the voice the player most wants to hear, like an engagement-optimized feed. On a replay, different playstyles should produce noticeably different narration.
*Implementation idea: narration lines live in tagged pools selected by a playstyle profile.*

### 4. Weapons: reclaimed city tools
- Examples: traffic baton, riot-control drone, defibrillator shock gauntlet.
- Each weapon has two modes:
  - **Steward-tuned:** semi-automatic and easier.
  - **Manual:** harder to use, stronger in skilled hands.
- The player picks **two weapons** before each level, as in Bastion.

### 5. The Ark (hub)
Each restored building takes back a job the Steward used to do:
- **Clinic:** healing items, plus memory logs about medical triage decisions.
- **Workshop:** weapon upgrades.
- **Archive:** read and replay recovered memories.
- **Commons:** talk to survivors. Their number grows when the player finds people off the predicted path.

### 6. Memory cores (forced trade-off)
Each level ends with more cores than the player can carry. Each core is one of two kinds:
- **Power cores** give the Steward stronger assistance.
- **Truth cores** reveal what it actually did, such as who got the last ambulance, which neighborhood lost power, or which news it buried.

A player who chases power reaches the end knowing far less than one who chases answers. The logs start out comforting and get harder to hear as the game goes on.

### 7. Overrides (replaces Bastion's Shrine idols)
Overrides are standing orders the Steward must obey. Each one makes the game harder and unlocks extra dialogue that shows how the Steward reasons. Examples:
- "Never warn me about traps."
- "Always protect the survivors first, even over me."

---

## Tracked state (suggested)

| Variable | Meaning |
|---|---|
| `voice_on_ratio` | Share of play time spent with the voice on |
| `cores_power`, `cores_truth` | Counts of each core type kept |
| `survivors_found` | Survivors brought to the Commons |
| `noor_trust`, `teo_trust` | Relationship values |
| `noor_present`, `teo_present` | Whether each is still with the player at the end |
| `active_overrides` | List of signed overrides |
| `playstyle_profile` | Risk and caution scores that drive adaptive narration |

### Ending logic
- **Reboot** and **Unplug** are always available as the final choice.
- **Rewrite** unlocks only if all of these hold:
  - `noor_present && teo_present`
  - `voice_on_ratio` is within a balanced band, e.g. 0.35–0.65 *(tunable)*. The player has to have both used the Steward and ignored it.
  - A minimum `cores_truth` *(tunable, suggested addition)*

---

## UI direction (see the mockups)

The mockups are on the "Undertow UI Mocks" design canvas. They show 7 screens at 1280×720 and are meant as inspiration, not pixel specs.

**Visual language.** Two color voices carry the core theme:
- **Steward amber `#F0B35B`** marks everything the AI gives you: the predicted path, assists, power cores and its narration. It should feel warm and seductive.
- **Truth cyan `#7CC7E0`** marks everything you find yourself: off-path survivors, truth cores, unindexed logs and the Rewrite ending.
- When the voice is muted, the world drops to cold greys and ivory (`#ECE8DF`) on near-black (`#0C0D11`).

**Type.** The Steward's narration is set in Fraunces Italic, a serif with a human, intimate feel. Labels and headings use Barlow Condensed, and data and system text use IBM Plex Mono.

**Screens:**
1. **HUD, Steward on.** Amber path tiles fade out ahead of the player. The screen shows a threat callout, a "100% charted" minimap (which leaves out the off-path island), narration subtitles, assist chips and a "STEWARD · LISTENING" pill bound to [V].
2. **HUD, Steward muted.** There's no path. The off-path island is revealed with a survivor and an unindexed log. The minimap becomes a "hand scan" (23% charted), the assist chips are struck through, weapons switch to MANUAL, and the HUD shows "DMG TAKEN ×1.4" and a muted timer.
3. **Core choice (interactive).** Four cards, and you carry two. Each card shows the Steward's comment: it pushes the power cores and dismisses the truth cores ("Corrupted. I wouldn't bother.").
4. **Loadout.** A 2×2 grid of weapons and two slots, each with a Tuned/Manual toggle and ease vs skill-ceiling bars.
5. **Archive.** A log list with comforting, truth and unrecovered entries, a decision-record readout with replay, the Steward's present-day comment, and Noor's and Teo's reactions with trust changes.
6. **Overrides.** Standing orders with Sign/Signed toggles, difficulty pips and "Unlocks:" text, a city difficulty meter and the Steward's reply to your last order.
7. **Ending.** Reboot, Unplug and Rewrite. The Rewrite card shows its unlock checklist, and a run summary sits at the bottom.

## Art direction (see the "Undertow Art Direction" canvas)

The canvas has 11 boards: palette and materials, three environment studies (Net Lane in the Vellum, Exchange Plaza at the Spire, Harbor Ward), the Steward's visual form, character silhouettes, cores and tools, the title treatment, a city map, and two key-art posters. They are inspiration, not final art.

### Visual reference: the `port city` folder

The approved concept art lives in the **`port city/`** folder in the project root (13 images plus `manifest.json`, `README.md` and the prompt files used to make them). **These images are the visual target. Where they and the text below disagree, the images win**, except for the known issues listed here.

| File | Use it as the reference for |
|---|---|
| `11-ring-reference.png` | **Canonical Steward ring.** Every in-game ring (HUD, holograms, title O) must match its geometry: thick filigree band, gap at the upper right, curled ends, outer ticks, inner ring, four-petal inlay, bright center. |
| `10-isometric-city-block.png` | **Primary in-game reference.** Camera angle, tile scale, character scale, the three-tile gold path, Custodian robot design, lighting and palette at gameplay distance. |
| `01-archive-district.png` | The Vellum, and the street-level look of the whole city. |
| `02-tower-plaza.png` | The Spire. |
| `03-fishing-quarter.png` | Harbor Ward. The no-gold rule in practice. |
| `04-hillside-houses.png` | Kestrel Heights (the one blue-hour district). |
| `05-automated-docks.png` | The Tideworks. |
| `06-hospital-corridor.png` | Mercy General. |
| `07-paper-archives.png` | The Vellum stacks; truth-core look; lantern-only lighting. |
| `08-seawall-pumping-station.png` | Greywater. |
| `09-emergency-platform.png` | The Ark. |
| `12-character-lineup.png` | The Operator, Noor and Teo. |
| `13-city-poster.png` | Key art and Steam capsule direction. |

**Known issues, do not copy these from the images:**
- Gothic spires, onion domes and cathedral silhouettes in the backgrounds of 08, 09 and 12. The skyline should be black-glass towers and 1900s civic buildings only.
- The full moon in 09. There is no moon; the ring is the only "moon".
- Heraldic banners with sigils in 12. No banners anywhere.
- Legible invented signage text (e.g. 01). In game, signs use our own copy.
- 13 has four path tiles and a busy bottom edge; corrections are in `tile-correction-prompts.json`. The path is always exactly three tiles ahead of the Operator.

**One sentence:** an art-nouveau port city, gilded by a machine. Dense, painterly and ornate (think cyberpunk density with Transistor's elegance), never minimal.

**Three strata, visible in every scene:**
1. **Old Meridian:** brick, timber, wrought iron, whiplash curves, stained-glass transoms, hand-painted signs, magenta and lime neon, awnings, laundry lines, pipes, cables. Dense, human, messy.
2. **The gilt:** ten years of the Steward laid over the top. Gold light-traces that follow the ironwork like veins, glass lenses on every lamp, holographic rings projected over plazas, black-mirror screens. Clean, precise, always sitting on top of something older.
3. **The Quiet:** rain on all of it. Dead screens with ring afterimages, cranes mid-lift, trains on bridges, paper in the street, kelp, gulls, the Waiting in doorways. Nothing is destroyed, everything is stopped.

**Color has owners.**
- **Gold `#F0B35B`** is the Steward and only the Steward: the path, the Loop's route lights, the ring, the gilt on the ironwork.
- **Cyan `#7CC7E0`** is what the player found alone: Harbor Ward, lanterns, cracked truth cores.
- **Magenta `#E24C8F` and lime `#9BE36A`** are the old city, people selling things to people. They keep burning after the Quiet.
- **Cream `#F3E3C6`** is human warmth: candles, kitchens, boat-house windows. Human light is never gold.
- **Red-orange `#E5654B`** is danger and nothing else (Warden eyes, hazards).
- The ground is deep teal (`#0B1A20`), the sky violet-to-teal, never neutral black. Materials: wet cobble, old brick, verdigris iron, brass, stained glass, black mirror. Paint first, then light.

**The lighting states** still hold: with the voice on, gold lamps light the path and shadows go soft; muted, the gilt dies and only what you carry (and the old neon) is lit; truth caches glow cyan in the fog.

**The world** (full detail in `undertow-world-bible.md`). Fixed isometric camera, about 56° tilt, no rotation. Eight districts, each expressing one thing the Steward did: Kestrel Heights (immaculate smart terraces), the Loop (stalled trains as bridges), the Tideworks (frozen cranes, rust and black water), Mercy General (locked wards), the Vellum (paper snow, a dead newsroom, unindexed stacks), Greywater (seawall, pumps, tide and fog), Harbor Ward (boat-houses, hand-bent neon, the only cyan), and the Spire (black glass with gilt veins and a holographic ring between the towers). The Ark is a concrete disc in the estuary with a ring of gold floor lights.

**Playable ground carries the composition.** Build the street as a painted diorama: wet tops, chipped coping, masonry foundations, timber pilings and open bridge trusses. Exposed edges show their construction and disappear into moving atmosphere below. Water belongs beneath the quay walls. Use continuous world-relative mist at different depths around the playable ground; a full-screen city illustration makes the street feel pasted on. The concept images guide materials and mood, while gameplay needs clear footing and separation between near and distant forms. These cutaway edges describe an intact city's infrastructure, not destruction caused by the Quiet. The Steward's three-cell prediction remains its own gold overlay; atmospheric presentation never creates or removes walkable ground.

**Motion must survive a recording.** Painted character parts may be articulated instead of using full-body frames. Walking needs alternating contacts, passing feet, restrained knee lift and counter-swinging arms, with stable body scale and joint anchors. Drive the gait from distance travelled so blocked movement stops it and carrying slows it. Carrying must preserve Noor's silhouette and lantern. Check several complete cycles in both views, including starts, stops, dodges and hits; a still pose or a passing asset check does not establish animation quality.

**The Steward's form.** It has no face. It is an open ring that never closes, drawn as gilt filigree: an outer tick ring, nouveau flourishes at the ends of the gap, an inner ring with a four-petal inlay, and a center dot. States: idle (slow six-second breath), speaking (the inner ring segments and the petals fill), withholding (identical to idle except the inlay drifts 3° off center, the only tell), glitch (the rings tear and a cyan copy bleeds through a frame late), off (an unlit scorch mark). It is projected as a hologram by lenses on the Lattice, etched into every black-mirror screen, worn as a sliver on every Lanyard, and inlaid at the keystone of every arch. Its voice is warm, unhurried and mid-register, and its subtitles use the game's only serif (Fraunces Italic).

**Characters.** Silhouette first, faces never detailed, one light per person. The Operator (player): stocky, dark coveralls, dull hi-vis chevrons, an earpiece that glows amber when the Steward is on and goes dark when muted. Noor: a tall triangle in a long patched coat, carrying a cyan hand lantern. Teo: narrow and hunched, lit from the chest by a tablet, amber reflected in his glasses so you never see his eyes. Survivors are unlit and grey until brought to the Commons.

**Objects.** Power cores are faceted amber prisms, lit from inside, cut like jewellery. Truth cores are dull cracked spheres with a faint blink inside; they look broken and the Steward says they are. Weapons are reclaimed city tools in chipped municipal paint, each still carrying a half-peeled "Property of the City of Meridian" asset tag. The Signal Jammer is the exception: hand-built in Harbor Ward, taped in cyan, no tag.

**Title.** "UNDERTOW" in Barlow Condensed 600, tracked +8%, with the O replaced by the Steward's ring. The ring's gap faces the W. In the muted state the ring is thin and grey with no center. After the Rewrite ending the gap is filled in cyan.

**Fonts.** Barlow Condensed for headings and labels, IBM Plex Mono for system text, Fraunces Italic for the Steward only.

---

## Platform and technology

**Target:** a commercial PC game sold on **Steam**, running on **macOS, Linux (including Steam Deck) and Windows**.

**Engine: Godot 4** (latest stable 4.x). Reasons:
- Free and open source (MIT), with no royalties or runtime fees.
- One project exports to macOS, Linux and Windows. Adding Windows costs almost nothing extra, and it is where most Steam players are, so plan to ship it.
- Strong 2D with isometric tilemaps, lights and shaders, which fits the painted isometric look.
- Scenes and scripts are plain text files (`.tscn`, `.gd`), which Claude Code can read and edit well.

**Rendering approach:** 2D isometric, using painted sprites and tiles plus 2D lights and shaders for the gold path, neon glow, rain and the voice-on/voice-off lighting states. Not 3D.

**Language:** GDScript.

**Steam integration:** the GodotSteam plugin, for achievements, cloud saves and the Steam overlay. Keep all Steam calls behind one wrapper so the game also runs without Steam during development.

**Input:** keyboard and mouse plus full controller support from day one (Steam Deck needs it). Fixed 16:9 game view that scales cleanly to 16:10 (Steam Deck) and ultrawide.

**Performance target:** 60 fps at 1080p on Steam Deck.

**Saves:** local JSON save files in the platform's user data folder, synced via Steam Cloud.

**Release requirements to plan for (not code tasks):**
- Steamworks partner account and the Steam Direct app fee.
- An Apple Developer account to sign and notarize the macOS build, or macOS will block it.
- Windows code signing is optional but avoids SmartScreen warnings.
- Test builds on real hardware for each platform, especially a Steam Deck.

---

## First milestone (suggested vertical slice)
1. Isometric movement, a dodge, and combat with a two-weapon loadout, where each weapon has a tuned mode and a manual mode.
2. Predictive path rendering, with at least one hidden off-path area.
3. A voice on/off toggle that switches assists, the map and narration.
4. Adaptive narration that draws from a small tagged line pool (placeholder text is fine).
5. One level ending with a power-vs-truth core choice.
6. An Ark hub with one restored building (the Archive).
7. Tracking for all the state variables above, plus a debug overlay that shows them.

## Open decisions
- Art style and camera details. The mockups assume an isometric camera and a dark, minimal UI.
- Narration format: voiced lines or text, and how adaptive lines are authored
- Final title. "Undertow" comes from an earlier flood-themed draft and may no longer fit.

## Not yet designed
A level-by-level outline, boss fights, and the soundtrack direction.
