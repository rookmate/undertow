# Milestone 5 plan: deeper districts, harder bosses

Placeholder design, from the conversation after milestone 4 (DECISIONS 174–177). The game takes a bot
about 17 minutes start to finish, a first-time player perhaps 45–90. This milestone makes districts
take 20–30 minutes each the first time, through play rather than padding, and bosses that escalate.

## The rules (decided)

- **Truths are found by exploring.** They sit off the Lattice, where the Steward can't help: no path,
  no assists, its map silent. You see the reward before you earn it (a sealed door, a cache behind
  glass), so exploring pays off instead of feeling like a hunt.
- **Holds and descents lock them.** A hold: defend something while it happens, and it opens what you
  saw. A descent: a short dark section off the Lattice ending in its prize (a truth core, a weapon
  upgrade, a survivor). At most one of each per district.
- **Noor's Mast counts what's left, never where** (DECISIONS 174, built).
- **Revisits harden by that district's truths** (175), and truths found on a revisit go straight to
  the Archive (176).
- **Dying in a boss fight restarts it** (177).

## Districts in three movements

1. **Arrival**, on the Lattice: the Steward in charge, the district's problem set up.
2. **The problem**: where the Steward's way and the people's way split. The hold lives here.
3. **The descent and the boss**: off the path, then the Reliquary.

Each movement ends on a beat (a narration line, a door, the map changing).

## Revisits

- A reason to go back: a door one of the Ark's tools opens (the Jammer opens a Steward-locked gate,
  the Defib restarts a dead lift), with a truth behind it; the district in a changed state where it
  fits (Greywater at high tide, the Vellum after the Feed goes dark).
- Hardening in steps by the truths taken from that district: more Custodians, then shorter windups,
  then elite variants. Every warning stays readable at every step; raw damage rises least.
- Revisits pay better: more scrap, and truths that only exist on a revisit.

## Bosses in stages

Two or three stages (at 66% and 33%), each with a short transition (a beat it can't be hit, a line,
the music up). Escalation is behaviour first: the Steward's calls come later or stop ("I can't read it
any more"), the arena changes, the boss loses parts and gets faster but more exposed, patterns
combine. Stage 3 is the shortest. Every stage's calls must fit its gaps (test_boss_calls, per stage).
Reduce flashing applies to transitions.

| Boss | Stage 2 | Stage 3 |
|---|---|---|
| The Lung (Greywater) | the tide rises: the arena shrinks for good | the Marrow rolls in: it can't see you either |
| The Conductor (the Loop) | express trains, two lanes at once | platforms break; it leaves the cab |
| The Crane (the Tideworks) | the hook swings; containers stack into walls | a leg buckles: it topples across the pier |
| The Surgeon (Mercy) | the mist spreads, wards seal in turn | triage: it tags you and calls orderlies |
| The Editor (the Vellum) | headlines become hazards (ink, paper walls) | decoys of you; the presses run backwards |
| The Warden-Prime (Harbor) | two Wardens; the light splits in two | the mast down: blind, it hunts by sound |

Kestrel Heights and the Spire keep theirs as they are (the Spire has no combat on purpose).

## Steps

| Step | What |
|---|---|
| 33 | The Mast counts, doesn't point; this plan (done) |
| 34 | Dying in a boss fight restarts it; the checkpoint at the arena door; the boss's intro cut short on a retry |
| 35 | Boss stages, built on the Lung (three stages) |
| 36 | Greywater in three movements: the pump hold (crank by hand while the tide comes in; the basement drains), the old pump room as its descent; its truths moved inside them |
| 37 | Play and time Greywater; tune. If it lands at 20+ minutes and feels earned, roll the pattern out |
| 38+ | The other districts in turn, each with its boss's stages |
| — | Revisits: tool doors, hardening by that district's truths, truths to the Archive |
| — | Rewrite's truth threshold re-tuned against the new count of truths |
| — | Sol analysis review (reviews/deeper-districts.md), fixes, re-check |

## Open (to tune once it's played)

- How many truths each district holds, and Rewrite's threshold (5 today).
- The hardening steps' sizes.
- Whether a retry skips the boss's first stage (decided: no; the fight restarts in full).
