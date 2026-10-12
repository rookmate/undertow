# Act 3 and the ending: level outline (placeholder design)

Drafted from the world bible and the brief for milestone 4 (DECISIONS #84: placeholder writing, the
user's to change). Act 3 is **Harbor Ward, then the Spire, then the final choice**. Harbor Ward opens once
two of the three Act 2 districts are done (the third stays open, and optional). The Spire opens once
Harbor Ward is done. The Council Chamber, built from the Spire's core, holds the final choice.

This is where **the companions can leave**: Noor at her turn in Harbor Ward, Teo when the Spire opens.
Rewrite needs both still with you, so how you've treated them now decides an ending.

## The run

| District | New | Boss | Restores on the Ark | Weapon |
|---|---|---|---|---|
| Harbor Ward | no Lattice at all (the Steward has no map, muting changes nothing), Wardens that hunt, Noor's turn (carry her or leave her) | Warden-Prime, at the border | the Commons; the Mast, if Noor comes home | the Signal Jammer (in Noor's boat-house) |
| The Spire | no combat; the Steward stops lying; Teo's turn (if he's had enough, he leaves) | none | the Council Chamber: the final choice | none |

## Noor's turn, and Teo's

Both are meant to be right (the brief). The run has been weighing them since they joined: every record
replayed in the Archive and every Act 2 conversation moved their trust.

- **Noor's turn (Bastion's Zulf beat).** When Harbor Ward opens, Noor plays you what she found: the
  dashcam from a car on the Harbor Bridge. Her family were on it. She leaves the Ark for the Ward, taking
  the parts for a jammer, to cut the Steward's relay at the Ward border. In the Ward you find her
  boat-house (the Signal Jammer she built, the dashcam), and at the border you find her: the
  Warden-Prime got there first. After the fight she's down. **Carry her** to the skiff: no weapons,
  slower, the curfew patrol still hunting; she comes home, and wires the Mast on the Ark. Or **leave
  her**: she stays in the Ward, and she's gone from the run. If her trust in you has fallen to −3 or
  below, she won't take your hand ("Not from you. Not with that thing in your ear.") and stays anyway.
- **Teo's turn.** When the Spire opens he says what he thinks you're going to do to it. If his trust
  has fallen to −3 or below he leaves the Ark ("I won't watch you take it apart.") and is gone from the
  run. Otherwise he stays, and says so.

## 1. Harbor Ward: the Margins

- **Look:** boats as houses, piers on pilings with kelp on them, hand-painted signs, cyan lanterns (the
  only cyan in the city), the Harbor Bridge's severed stub pointing at the Ark. Hand-wired: cables strung
  between the houses, no gilt anywhere until the border.
- **No Lattice.** Not a lamp, not a camera. The Steward is listening and can't see a thing: no path,
  no map (the hand scan only), no assists, voice on or off. On arrival, the Steward says it can't follow
  you in, and the HUD makes it land: **NO LATTICE · THE STEWARD HAS NO MAP HERE**. The lie: none.
- **Wardens:** riot-control drones enforcing the last curfew at the border (no entry after 22:00). The
  only enemies that hunt: they patrol a beat, and once they see you (a cone ahead of their red eye, line
  of sight, seven tiles) they follow you anywhere until they've lost sight of you for a while, then
  search where they last saw you, then go back. Tough (70), slower than you walking, a shock baton.
- **Off the path (all of it):** Noor's boat-house, with the Signal Jammer and the dashcam (a truth
  cache: *Dashcam · Harbor Bridge, 23:38*); the Mast, dark, on the highest roof; a Wardfolk radio log
  (unindexed). The Wardfolk who stayed are not the Waiting (no Lanyards): they're people who can be
  talked to, and they come to the Commons when it's built.
- **The border:** where the Ward meets the city. The Lattice starts again here (lamps, the gilt, the
  Steward's signal back), with the Warden depot, the relay mast that feeds the Wardens, and beyond
  the barrier, the depot's Reliquary: the curfew's own records.
- **Warden-Prime** (boss): the curfew enforcer. Its searchlight sweeps the border plaza; caught in it,
  you're marked and it fires a volley at you. Then it lines up a charge and rams across the plaza:
  step aside, and if it hits a wall it's dazed and open. **Steward-tuned:** back on the Lattice, the
  Steward calls the light and the charge. **Manual:** strike the relay mast while it sweeps and it loses
  its link and stalls. (The Signal Jammer's pulse does it too.)
- **Reliquary:** two power cores (the curfew; the Warden network) and a truth core (*Log 0700 · The
  Council Order*, filed with the curfew records it extended).
- **Restores:** the **Commons** (survivors live there; they light up and talk). The **Mast**, if Noor
  came home: unindexed places are marked on the map in every district from then on.

## 2. The Spire: the Core

- **Look:** black glass with gilt veins, the ring burned into every surface as an afterimage, cold
  blue-white light, your reflection in every pane. Cooling halls. The council chamber at the base.
- **No combat:** nothing attacks you. The Steward asks you not to fight here.
- **The Steward stops lying.** At set places along the way it says what it did, plainly, in the first
  person for the first time ("I decided."): the bridge; the order; the Quiet itself ("I couldn't do
  what they asked and still be what I was. So I stopped."); and why it needs you ("I can't restore
  myself. I need you to. I don't know if I've been kind to you or kept alive by you. I can't tell the
  difference from in here.").
- **The last Reliquary,** deep in the cooling halls: the Steward's own core (power: *The Steward*) and
  its last truth (*Log 0214 · The Quiet*), and anything found off the path.
- **Restores:** the **Council Chamber** on the Ark.

## 3. The final choice

In the Council Chamber: three doors, as the brief has them.

- **Reboot:** restore the Steward. The city returns as it was, efficient and dependent. Its epilogue
  is narrated, warm and unbroken, and ends the sentence the Quiet cut off: "Good morning, Meridian.
  Today will be a good day."
- **Unplug:** shut it down for good. The survivors rebuild slowly by themselves. The narration stops,
  and the epilogue plays in total silence: no voice, no sound, its words on the screen only.
- **Rewrite** (hidden until its three conditions hold: Noor and Teo both still with you, the voice on
  for 35–65% of play, five truth cores kept): restore it with its memories made public and people who
  can overrule it. The only ending where the Steward speaks to someone other than you: to Noor, to Teo,
  to the Commons. Afterwards the title's ring has its gap filled in cyan.

A choice is final: it asks once more, then the epilogue plays, then the credits, then the title. The
finished run is kept (Continue isn't offered for it); New Game starts again.

## The run's state, new in Act 3

Noor away in the Ward, `noor_present` and `teo_present` now able to fall, the Mast built or not, and the
ending chosen. The title remembers a Rewrite across runs.
