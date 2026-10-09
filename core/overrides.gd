class_name Overrides
extends RefCounted
## Standing orders the Steward must obey (brief, "Overrides"). Each makes the game harder and unlocks
## dialogue that shows how it reasons. The Signal Room screen comes later; in the slice they are signed
## from the debug overlay.

const NO_TRAP_WARNINGS := "no_trap_warnings"
const SURVIVORS_FIRST := "survivors_first"

const ALL: Dictionary[String, Dictionary] = {
	NO_TRAP_WARNINGS: {
		"order": "Never warn me about traps.",
		"difficulty": 2,
		"effect": "Threat warnings are off, even with the voice on.",
	},
	SURVIVORS_FIRST: {
		"order": "Always protect the survivors first, even over me.",
		"difficulty": 1,
		"effect": "The Steward weighs survivors above you. (No gameplay effect in the slice yet.)",
	},
}


static func is_known(override_id: String) -> bool:
	return ALL.has(override_id)


static func order_text(override_id: String) -> String:
	return str(ALL.get(override_id, {}).get("order", override_id))
