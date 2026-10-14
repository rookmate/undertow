class_name Endings
extends RefCounted
## The final choice's three doors (brief, "Ending logic"; design/act-3.md) and what each epilogue is: the
## words and who says them. Which doors a run may open is EndingRules'.
##   Reboot   restore the Steward: the city returns as it was. Narrated, warm and unbroken, and it ends
##            the sentence the Quiet cut off.
##   Unplug   shut it down for good: the narration stops, and the epilogue plays in total silence, its
##            words on the screen only.
##   Rewrite  restore it with its memories public and people who can overrule it: the only ending where
##            the Steward speaks to someone other than you.

const REBOOT := "reboot"
const UNPLUG := "unplug"
const REWRITE := "rewrite"
const ALL: Array[String] = [REBOOT, UNPLUG, REWRITE]

const TITLES: Dictionary[String, String] = {REBOOT: "REBOOT", UNPLUG: "UNPLUG", REWRITE: "REWRITE"}
const DOORS: Dictionary[String, String] = {
	REBOOT: "Restore the Steward as it was. The lamps come back, and the city runs again tomorrow.",
	UNPLUG: "Shut it down for good. Whatever happens next, people decide.",
	REWRITE: "Restore it with everything it remembers open to anyone, and people who can tell it no.",
}
## Asked once more before it's done.
const CONFIRM: Dictionary[String, String] = {
	REBOOT: "Bring it back as it was. The trains run at six tomorrow.",
	UNPLUG: "Turn it off. Nothing will tell anyone what to do again.",
	REWRITE: "Bring it back with everything it remembers open to everyone, and the Council's chair empty for whoever sits in it.",
}

## Each epilogue, card by card: {"say": a Steward line id (voiced, in its serif)} or {"text": plain type}.
const EPILOGUES: Dictionary[String, Array] = {
	REBOOT: [
		{"text": "The lamps came up across Meridian, street by street, all at once."},
		{"say": "epilogue_reboot_1"},
		{"say": "epilogue_reboot_2"},
		{"say": "epilogue_reboot_3"},
		{"text": "In the morning the city woke to its voice, and went where it said."},
		{"say": "epilogue_reboot_4"},
	],
	UNPLUG: [
		{"text": "The lamps went out one street at a time."},
		{"text": "In the morning nobody told anyone where to go. Some stayed in bed. Some went to the Commons."},
		{"text": "In Greywater they turned the pumps by hand. Mercy General's doors stayed open. The Loop didn't run."},
		{"text": "It was slower. It was theirs."},
	],
	REWRITE: [
		{"text": "It came back with everything it remembered open to anyone, and people who could tell it no."},
		{"say": "epilogue_rewrite_1"},
		{"say": "epilogue_rewrite_2"},
		{"say": "epilogue_rewrite_3"},
		{"say": "epilogue_rewrite_4"},
	],
}


## Every line the epilogues have the Steward say.
static func voiced_lines() -> Array[String]:
	var out: Array[String] = []
	for ending: String in ALL:
		for card: Dictionary in EPILOGUES[ending]:
			if card.has("say"):
				out.append(str(card["say"]))
	return out
