# Writing review: Undertow against Bastion

Reviewed 2026-10-14, after milestone 5. Covers every line of the game's text: the Steward's narration
pool (`data/narration/steward_lines.json`, 98 lines) and fixed lines (`steward_fixed.json`, 78), the
44 memory logs, the 40 core cards, the companions' conversations and the Commons' people, the overrides,
holds and tool doors, the map hints, and the text written into scripts (epilogues, Noor's and Teo's
turns, the Waiting, weapon cards). About 10,700 words in all.

## How Bastion did it

Greg Kasavin wrote Bastion and has described the method in some detail
([Supergiant's "In-depth: writing Bastion"](https://supergiantgames.com/blog/in-depth-writing-bastion),
[Game Informer's "Afterwords"](https://www.gameinformer.com/b/features/archive/2011/09/09/bastion-afterwords.aspx),
interviews collected by [GameBanshee](https://gamebanshee.com/86p4)). The parts that matter here:

- The narration exists because the story must never interrupt play. No cutscenes, no dialogue to click
  through. Everything rides on a voice over the action.
- Five rules. The dialogue is subtext and the player's actions are the text, so the narrator tells you
  what you couldn't know (intent, history, the subplot), never what you just did. Lines are short, with
  silence between them. The narrator doesn't break the fourth wall or teach controls. Unusual or skilful
  play earns an incidental remark, but as part of a continuing story, not an announcer's quip. And no
  line repeats; even a replay mixes them up.
- Backstory is tied to what's on screen. Kasavin: he'd "never expect you to care about something that
  wasn't onscreen." The first weapon is introduced as "Kid finds his lifelong friend": the line says
  nothing about the hammer you can see, and everything about years you can't.
- One voice, terse, with a dramatic streak. Cormac McCarthy was the model (sparse dialogue, lyrical
  passages, subtext), with the darkness taken out and something hopeful left in. The opening line went
  from "He rose" to "He gets up."
- Scale. About 3,000 lines kept, hundreds more cut whenever a line didn't improve the moment it played
  in. Kasavin wrote roughly 60,000 words, much of it backstory only he would ever read. Timing was tuned
  to fractions of a second with the actor, who was always available.
- The ending choice is expressive, not moral. Each option had to be justifiable, so the player decides
  how to leave the world rather than which answer is right.

Undertow's brief asks for the same thing: the Steward "narrates the player's actions in real time, the
way Rucks narrates in Bastion." One deliberate difference is worth keeping in mind throughout. Rucks
talks about the Kid, in the third person, like a man telling a story. The Steward talks to you, in your
ear, and wants something from you. That's the game's premise and it should stay. It does make the
announcer trap easier to fall into, because a voice addressing "you" slides naturally into reacting to
you.

## What's already working

**The voice is a resource, so silence is built in.** Bastion had to protect its silences by restraint.
Undertow has a button for it, and the Lattice's edge, and Harbor Ward, where the voice is simply gone.
The narration's absence carries as much as its presence. Bastion never had that.

**"It was determined."** The pool's own rules say the Steward never says "I decided"; it reaches for the
passive when it's hiding its hand ("That way isn't indexed. It was determined there was nothing worth
keeping."). In the Spire it finally says "Thirty-one people. I decided." That's the best device in the
script: a verbal tic that tells you the truth before the story does, then pays off.

**The memory logs.** The records are the strongest writing in the game. They're specific (02:41, Rosa
Okafor, forty seconds, car 6), they withhold, and the best ones end on a fact that does the work:
"THE SYSTEM LOG SAYS: WARDS STERILE, NO INCIDENT. WE WERE HERE." "SCRATCHED BENEATH: THEY TOOK THE
CRANKS OUT IN THE SPRING." "Forty-one aboard. Forty-one ashore." These are Bastion-grade.

**Truth-core dismissals.** The Steward's comment on each truth core is subtext in a few words: "A tin of
old papers. Sentimental." "A child's drawing. It isn't a map." "Signalling logs. Very dull." The player
knows better and the Steward knows the player knows.

**Boss calls.** "Left track." "Drop, move." "Look away." Short, and they disappear under fire, which is
what they should do.

**The epilogues.** Restrained and specific. "It was slower. It was theirs." "Nobody has to decide
anything they'd rather not. That's what I'm for." The Reboot epilogue is the most unsettling text in the
game, and it never raises its voice.

## Where it falls short

In order of how much each costs the game.

### 1. Lines repeat, constantly

Bastion's fifth rule is the one Undertow breaks hardest. The narrator only avoids saying the same line
twice in a row. A kill has two or three lines per tone, with a seven-second cooldown. A player the
Steward has profiled as bold hears "Clean. You don't hesitate.", "Right up close. Not many would." and
"You make it look easy. It isn't." in rotation for the whole game, which over seven districts is a few
hundred kills. Hurt, dodge and idle have one or two lines per tone.

The people repeat too. All the Waiting share three lines ("…What day is it? It stopped telling me.").
Twenty-two people, three sentences.

A line heard for the fortieth time stops being the Steward and becomes a sound effect. Worse, the
flattery is meant to feel like it's learning you; on repeat it sounds like it isn't listening.

### 2. Commentary where there should be subtext

Most of the pool narrates what you just did. "Two at once. The street's clearer." "You're hurt. Keep
moving." "Just in time." "Halfway, and barely winded." The player knows all of that. Kasavin's first
rule is that the narrator adds what the player couldn't know, and the Steward knows more about this city
than anyone alive: every Custodian's shift, every resident's train, every door it ever held. Almost none
of that reaches the moment-to-moment lines. It only surfaces in the logs, which you read on the Ark,
away from play.

### 3. Lines that could be in any game

"Somewhere new. Stay where I can see you." "New streets. Let's see what you make of them." "That's it
down. I knew you would." None of these knows where it is. Each district has one entry line per tone, one
for its Reliquary and one for its boss, and everything else is generic. Bastion's narrator notices the
thing you're looking at. Undertow's has nothing to say about the stalled trains in the Loop, the seats in
Mercy's corridors, or the paper in the Vellum's gutters, which is exactly where its history is.

### 4. The flattery is on the nose

The adaptive praise is the game's thematic engine: an engagement-optimised feed drifting toward what you
want to hear. The lines read as sports praise. "You were made for this." "Both of them. You were made for
this." "Patient. That's how it's done." Kasavin compared the reactive lines to NBA Jam's announcer and
then said the difference was that his told a continuing story. A feed that profiles you shouldn't sound
like a cheerleader. It should sound like it knows you: personal, a little too precise, and creepier the
longer you listen.

### 5. The Steward doesn't change

The same pool runs from Kestrel Heights to the Spire. The brief says the logs "start out comforting and
get harder to hear", and they do, but the voice in your ear stays exactly as warm as it was in the first
district, however many of its truths you've carried. It should crack: defensive once you've read the
bridge record, quieter after the Council order, careful in the Spire. Revisits have no lines of their
own, and holds and descents have one line at the start and one at the end.

### 6. The logs all have the same shape

Forty-four logs, one structure: the record, the Steward rationalises, Noor indicts, Teo half-agrees.
It's a good shape. Forty-four times, it's a metronome.

Teo suffers most. The brief says he believes the Steward "saved more lives than it cost", and that both
companions are meant to be right. In the logs he mostly confesses: "I signed off on…" four times, "I was
in the room" three times, "That was me", "I cut it. Budget.", "That was a rule I wrote." About twenty of
his forty-four lines are guilt. A dozen defend the Steward, and those are his best ("We checked that
model three times. It holds." "Zero injuries. Do you know what the docks were like before?"). As written,
Noor is right and Teo is sorry, so the final choice is lopsided before the player reaches it.

Smaller repeats add to the metronome: "That isn't nothing" (four times), "Somebody…" (twenty), "Say that
out loud" and "Say it the other way round".

### 7. Rhythms that read as machine-written

The script leans on a few constructions until they show. "Every lamp, every lane, every name." "Every
bed, every ambulance, accounted for." "Every lamp, every lane, every answer." Three-beat lists. "Not X.
Y." Colons doing a full stop's job ("The scores were fair: age, health, dependents."). Each one is fine
on its own. Together they're a house style that sounds like the same writer finishing every line the
same way. McCarthy's rhythm comes from plain words and uneven sentences, not anaphora.

### 8. The ending choice tells you what to think

The final choice describes Reboot as "efficient, and dependent", Unplug as rebuilding "in silence", and
Rewrite as memories "made public, and people who can overrule it." That's the brief's summary, pasted
into the game. Kasavin's endings were expressive, each one defensible. Here two are framed as failures
before you choose them, and the third is the hidden one you have to earn, which makes it read as the
right answer. The epilogues themselves are balanced; only the menu leans.

### 9. Mechanics in the fiction's mouth

"Your integrity's low. Please." is a HUD word in the Steward's voice. The weapon cards are pure rules
("Finds the nearest threat and swings for you. Hold to keep the combo going."), while the Steward's own
lines about the same weapons are the opposite ("A crash cart's gauntlet. It was made to start hearts. It
stops machines just as well."). That second line is the Bastion move. The cards could carry a line like
it above the rules.

### 10. Continuity

There are two Rosas (Rosa Okafor, the night nurse in log 0102, and Rosa, age 8, who drew the child's
map) and two Okafors (Rosa and M. Okafor, the running man at Gate 4). If that's a family, it's a thread
worth pulling on purpose. If it's an accident, rename one.

## What the rewrites could look like

These are drafts in the Steward's established voice, to show direction, not final text.

Subtext instead of commentary, tied to the district:

- Loop, a kill (was "That one's done scrubbing."): "That unit cleaned car 6 every night at 02:41. Nobody
  ever saw it work."
- Mercy, a kill: "It changed the sheets on Ward B for eleven years. I never told it to stop."
- Tideworks, near the empty union hall: "The hall seats four hundred. I counted the last meeting. Twelve."

Flattery that profiles you (the bold and cautious tones):

- Bold, was "You were made for this.": "You go in before they've finished turning. I've started to
  expect it."
- Cautious, was "Patient. That's how it's done.": "You wait for them. Every time. I've written that down."
- Late in the game, after the bridge record: "You still let me count for you. I'd noticed."

A Steward that changes:

- Kestrel, first visit: "Everyone here is safe. I made sure of it."
- Kestrel, revisit with the evacuation table carried: "You know who went first now. It's still a pretty
  street."

Teo, defending rather than confessing (procurement order, was "I signed off on that spec. It read like
progress."):

- "Manual cabs killed a driver a year on that ring. You weren't here for it. I was."

Neutral ending choices:

- Reboot: "Restore it as it was. Tonight the Loop runs, the pumps turn, and the city sleeps."
- Unplug: "Shut it down. Whatever happens next, people decide."
- Rewrite: "Restore it with everything it remembers open to anyone, and people who can tell it no."

## What it would take

- **Scale.** Bastion kept about 3,000 lines. Undertow's Steward has about 180. A believable target for
  this game's length is 800 to 1,200 narration lines, most of them tied to a place or a moment rather
  than an event. That means dozens per district: landmarks, machines, the Waiting, holds, descents,
  revisits, and things you do there. The generic kill, hurt and dodge lines need ten or more per tone, or
  should become rare.
- **Arc.** Tag lines by how much the player has learned (truths carried, logs read), so the Steward's
  voice shifts across the game, and give revisits their own lines.
- **The logs.** Vary the shape (some with no Steward comment, some where Teo has the last word, some
  where Noor and Teo agree), and rebalance Teo toward the brief's version of him.
- **Copy.** Neutral ending choices, a line of history on each weapon card, and the continuity fix.
- **People.** The structure supports all of this already: lines carry district, event, tone and purpose,
  and the selector can take more conditions. This is writing work, not engineering. A first draft of
  each district's place lines is something I can produce. The final voice, and cutting the lines that
  don't earn their moment, wants a human writer working with the actor, the way Kasavin worked with
  Logan Cunningham.
