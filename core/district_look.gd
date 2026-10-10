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
var lawn: Color = Palette.LAWN
var lawn_stripe: Color = Palette.LAWN_STRIPE
var hedge: Color = Palette.HEDGE
var blossom: Color = Palette.BLOSSOM
var timber: Color = Palette.TIMBER
var gravel: Color = Palette.GRAVEL
var asphalt: Color = Palette.YARD_ASPHALT
## A floor kept by people, off the Lattice (the night nurses' station's lino).
var staff_floor: Color = Palette.WARD_LINO
var grout: Color = Palette.WARD_GROUT
var glass: Color = Palette.WARD_GLASS
## Fog drawn over the drop beside walkable ground (rail ribbons in fog); transparent where there's none.
var void_fog: Color = Color(Palette.FOG, 0.0)
## Rain on all of it (art direction, "the Quiet"); off indoors.
var rain: bool = true
## CanvasModulate for the world, voice on and muted.
var ambient_on: Color = Palette.AMBIENT_VOICE_ON
var ambient_muted: Color = Palette.AMBIENT_MUTED


## The look of a district (or the Ark) by id. Unknown ids get the Vellum's look, the city's default.
static func for_district(id: String) -> DistrictLook:
	var look := DistrictLook.new()
	match id:
		"kestrel":
			# The blue hour (the only one in the city): pale stone terraces under a violet sky with a rose
			# band where the sun went down. The prettiest place in the game.
			look.ground_a = Palette.KESTREL_STONE_A
			look.ground_b = Palette.KESTREL_STONE_B
			look.ground_wet = Palette.KESTREL_WET
			look.pavement = Palette.KESTREL_PAVEMENT
			look.stone = Palette.KESTREL_LIMESTONE_SHADE
			look.wall = Palette.KESTREL_LIMESTONE
			look.wall_shade = Palette.KESTREL_LIMESTONE_SHADE
			look.wall_top = Palette.KESTREL_SLATE
			look.sky_top = Palette.SKY_DUSK_BLUE
			look.sky_bottom = Palette.SKY_DUSK_LOW
			look.horizon = Color(Palette.SUNSET_ROSE, 0.55)
			look.ambient_on = Palette.AMBIENT_DUSK_ON
			look.ambient_muted = Palette.AMBIENT_DUSK_MUTED
		"loop":
			# Rail ribbons in fog, high above black water and roofs; carriages in faded livery.
			look.ground_a = Palette.LOOP_CONCRETE.darkened(0.15)
			look.ground_b = Palette.LOOP_CONCRETE
			look.pavement = Palette.LOOP_CONCRETE
			look.stone = Palette.LOOP_CONCRETE.darkened(0.25)
			look.wall = Palette.LOOP_LIVERY
			look.wall_shade = Palette.LOOP_LIVERY_SHADE
			look.wall_top = Palette.LOOP_ROOF
			look.sky_top = Palette.SKY_FOG_TOP
			look.sky_bottom = Palette.SKY_FOG_LOW
			look.ambient_on = Palette.AMBIENT_FOG_ON
			look.ambient_muted = Palette.AMBIENT_FOG_MUTED
			look.void_fog = Color(Palette.FOG, 0.09)
		"tideworks":
			# Rust and black water, sodium-dark steel in the rain; the gilt runs along the gantries.
			look.ground_a = Palette.DOCK_CONCRETE
			look.ground_b = Palette.DOCK_CONCRETE_B
			look.ground_wet = Palette.STEEL_WET.lightened(0.15)
			look.pavement = Palette.DOCK_CONCRETE_B
			look.stone = Palette.STEEL_WET
			look.wall = Palette.RUST
			look.wall_shade = Palette.RUST_DARK
			look.wall_top = Palette.STEEL_WET
			look.sky_top = Palette.SKY_STORM_TOP
			look.sky_bottom = Palette.SKY_STORM_LOW
			look.ambient_on = Palette.AMBIENT_STORM_ON
			look.ambient_muted = Palette.AMBIENT_STORM_MUTED
		"mercy":
			# Long white corridors gone grey, every third light working; the dark beyond the glass.
			look.ground_a = Palette.WARD_TILE_A
			look.ground_b = Palette.WARD_TILE_B
			look.ground_wet = Palette.WARD_TILE_B.lightened(0.12)
			look.pavement = Palette.WARD_TILE_A
			look.stone = Palette.WARD_WALL_SHADE
			look.wall = Palette.WARD_WALL
			look.wall_shade = Palette.WARD_WALL_SHADE
			look.wall_top = Palette.WARD_WALL_TOP
			look.sky_top = Palette.SKY_WARD_TOP
			look.sky_bottom = Palette.SKY_WARD_LOW
			look.skyline = Color(Palette.BLACK_MIRROR, 0.0)
			look.rain = false
			look.ambient_on = Palette.AMBIENT_WARD_ON
			look.ambient_muted = Palette.AMBIENT_WARD_MUTED
		"greywater":
			# Concrete and kelp under fog so thick the path lights are halos; standing water everywhere.
			look.ground_a = Palette.SEAWALL_CONCRETE
			look.ground_b = Palette.SEAWALL_CONCRETE_B
			look.ground_wet = Palette.LOW_STREET_WET
			look.pavement = Palette.SEAWALL_CONCRETE
			look.stone = Palette.PUMP_CONCRETE_SHADE
			look.wall = Palette.PUMP_CONCRETE
			look.wall_shade = Palette.PUMP_CONCRETE_SHADE
			look.wall_top = Palette.PUMP_ROOF
			look.sky_top = Palette.SKY_MARROW_TOP
			look.sky_bottom = Palette.SKY_MARROW_LOW
			look.ambient_on = Palette.AMBIENT_MARROW_ON
			look.ambient_muted = Palette.AMBIENT_MARROW_MUTED
			look.void_fog = Color(Palette.FOG, 0.12)
		"vellum", "ark":
			pass
	return look
