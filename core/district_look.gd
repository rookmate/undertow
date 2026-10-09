class_name DistrictLook
extends RefCounted
## How a district looks: its ground, its buildings, its sky and its light. Every district shares the
## city's rules (gold is the Steward's, cream is human, red-orange is danger); this is what differs
## between them (world bible, "The districts"). Colours come from Palette; looks only choose among them.

var ground_a: Color = Palette.COBBLE_A
var ground_b: Color = Palette.COBBLE_B
var ground_wet: Color = Palette.COBBLE_WET
var pavement: Color = Palette.PAVEMENT
var stone: Color = Palette.STONE_OLD
var wall: Color = Palette.BRICK
var wall_shade: Color = Palette.BRICK_DARK
var wall_top: Color = Palette.BRICK_TOP
var sky_top: Color = Palette.SKY_VIOLET
var sky_bottom: Color = Palette.SKY_TEAL
## A band of light low on the horizon (blue hour); transparent for night districts.
var horizon: Color = Color(Palette.SKY_TEAL, 0.0)
var skyline: Color = Color(Palette.BLACK_MIRROR, 0.85)
var water: Color = Palette.WATER_DEEP
## CanvasModulate for the world, voice on and muted.
var ambient_on: Color = Palette.AMBIENT_VOICE_ON
var ambient_muted: Color = Palette.AMBIENT_MUTED


## The look of a district (or the Ark) by id. Unknown ids get the Vellum's look, the city's default.
static func for_district(id: String) -> DistrictLook:
	var look := DistrictLook.new()
	match id:
		"vellum", "ark":
			pass
	return look
