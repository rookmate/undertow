class_name WeaponGlow
extends RefCounted
## The light a weapon gives off: Steward gold while it is Steward-tuned, ivory when the Operator runs it.

static func color(tuned: bool) -> Color:
	return Palette.STEWARD_GOLD if tuned else Palette.IVORY


static func hot(tuned: bool) -> Color:
	var c := color(tuned)
	return Color(c.r * 1.6, c.g * 1.6, c.b * 1.6, c.a)
