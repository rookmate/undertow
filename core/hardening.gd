class_name Hardening
extends RefCounted
## Revisits harden by what you took from that district (DECISIONS 175, 187): the more of its truths
## you've carried out, the harder its machines are when you come back. Only that district's truths
## count, never the run's. In steps, each keeping what came before: one more Custodian beside each one
## placed; their windups a fifth shorter (every warning still long enough to read); elites, half again
## as hard to take apart and a little faster, marked at their feet. What they hit you for never rises.
## A revisit pays better too: every machine gives up twice the parts.

const MORE_FROM := 1
const QUICKER_FROM := 2
const ELITE_FROM := 3
const WINDUP_SCALE := 0.8
const ELITE_INTEGRITY := 1.5
const ELITE_SPEED := 1.15
const REVISIT_SCRAP := 2


## How hard a district is now: how many of its truths you've carried out (0 up to ELITE_FROM).
static func step(run: RunState, level_id: String) -> int:
	var n := 0
	for id: String in LevelCatalog.truths_of(level_id):
		if run.truth_core_ids.has(id):
			n += 1
	return mini(n, ELITE_FROM)


## A machine as a revisit at step `s` makes it (once it's in the level and set up as built).
static func apply(e: Enemy, s: int) -> void:
	e.scrap_value *= REVISIT_SCRAP
	if s >= QUICKER_FROM:
		e.windup_scale = WINDUP_SCALE
	if s >= ELITE_FROM:
		e.make_elite(ELITE_INTEGRITY, ELITE_SPEED)


## What the city map says of a district you've done, by its step.
static func describe(s: int) -> String:
	match s:
		0:
			return "Its machines as you left them."
		1:
			return "Harder now: more of its machines."
		2:
			return "Harder now: more of them, and quicker to strike."
	return "Harder now: more, quicker, and some of them elite."
