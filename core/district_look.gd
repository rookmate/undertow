class_name DistrictLook
extends RefCounted
## How a district looks: its ground, its buildings, its sky and its light. Every district shares the
## city's rules (gold is the Steward's, cream is human, red-orange is danger); this is what differs
## between them (world bible, "The districts"). Colours come from Palette; looks only choose among them.

var district_id: String = "vellum"

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
## Walls of black glass (the Spire): dark mirror panes and cold veins, no windows.
var black_glass: bool = false
## Painted base materials, selected by district. Lights remain on their own canvas layers.
var cobble_texture: Texture2D
var paving_texture: Texture2D
var lawn_texture: Texture2D
var wall_texture: Texture2D
var roof_texture: Texture2D
var window_texture: Texture2D
var door_texture: Texture2D
var balcony_texture: Texture2D
var railing_texture: Texture2D
var hedge_texture: Texture2D
var planter_texture: Texture2D
var lamp_texture: Texture2D
## CanvasModulate for the world, voice on and muted.
var ambient_on: Color = Palette.AMBIENT_VOICE_ON
var ambient_muted: Color = Palette.AMBIENT_MUTED


## The look of a district (or the Ark) by id. Unknown ids get the Vellum's look, the city's default.
static func for_district(id: String) -> DistrictLook:
	var look := DistrictLook.new()
	look.district_id = id if ArtBindings.WALL.has(id) else "vellum"
	look.wall_texture = ArtCatalog.texture(ArtBindings.WALL.get(id, "mat_brick"))
	look.roof_texture = ArtCatalog.texture("mat_slate" if id in ["kestrel", "vellum", "ark"] else "mat_steel")
	look.window_texture = preload("res://assets/art/kestrel/window_ornament.tres")
	look.door_texture = preload("res://assets/art/kestrel/door_ornament.tres")
	look.balcony_texture = preload("res://assets/art/kestrel/balcony.tres")
	look.railing_texture = preload("res://assets/art/kestrel/railing.tres")
	look.lamp_texture = preload("res://assets/art/kestrel/lamp_housing.tres")
	if id == "mercy":
		look.window_texture = ArtCatalog.texture("hospital_frame")
	elif id == "greywater":
		look.window_texture = ArtCatalog.texture("pump_frame")
	elif id == "harbor":
		look.window_texture = ArtCatalog.texture("boat_frame")
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
			look.cobble_texture = preload("res://assets/art/kestrel/wet_stone.png")
			look.paving_texture = preload("res://assets/art/kestrel/paving.png")
			look.lawn_texture = preload("res://assets/art/kestrel/lawn.png")
			look.wall_texture = preload("res://assets/art/kestrel/limestone_wall.png")
			look.roof_texture = preload("res://assets/art/kestrel/slate_roof.png")
			look.window_texture = preload("res://assets/art/kestrel/window_ornament.tres")
			look.door_texture = preload("res://assets/art/kestrel/door_ornament.tres")
			look.balcony_texture = preload("res://assets/art/kestrel/balcony.tres")
			look.railing_texture = preload("res://assets/art/kestrel/railing.tres")
			look.hedge_texture = preload("res://assets/art/kestrel/hedge.tres")
			look.planter_texture = preload("res://assets/art/kestrel/planter.tres")
			look.lamp_texture = preload("res://assets/art/kestrel/lamp_housing.tres")
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
		"harbor":
			# Boats as houses, tarred timber, kelp on the pilings, the only cyan in the city: its own.
			look.ground_a = Palette.WARD_STONE
			look.ground_b = Palette.WARD_STONE_B
			look.ground_wet = Palette.WARD_STONE_B.lightened(0.1)
			look.pavement = Palette.WARD_STONE
			look.stone = Palette.WARD_STONE.darkened(0.1)
			look.wall = Palette.BOATHOUSE
			look.wall_shade = Palette.BOATHOUSE_SHADE
			look.wall_top = Palette.BOATHOUSE_ROOF
			look.timber = Palette.PIER_PLANK
			look.sky_top = Palette.SKY_HARBOR_TOP
			look.sky_bottom = Palette.SKY_HARBOR_LOW
			look.ambient_on = Palette.AMBIENT_HARBOR_ON
			look.ambient_muted = Palette.AMBIENT_HARBOR_MUTED
			look.void_fog = Color(Palette.FOG, 0.06)
		"spire":
			# The Steward's own house: black glass and cold light, no rain, no sky to speak of.
			look.ground_a = Palette.SPIRE_GLASS
			look.ground_b = Palette.SPIRE_GLASS_B
			look.ground_wet = Palette.SPIRE_GLASS_B.lightened(0.08)
			look.pavement = Palette.SPIRE_GLASS
			look.stone = Palette.SPIRE_GLASS_B
			look.wall = Palette.SPIRE_WALL
			look.wall_shade = Palette.SPIRE_WALL_SHADE
			look.wall_top = Palette.SPIRE_WALL_TOP
			look.water = Palette.COOLANT
			look.sky_top = Palette.SKY_SPIRE_TOP
			look.sky_bottom = Palette.SKY_SPIRE_LOW
			look.skyline = Color(Palette.BLACK_MIRROR, 0.0)
			look.rain = false
			look.black_glass = true
			look.ambient_on = Palette.AMBIENT_SPIRE_ON
			look.ambient_muted = Palette.AMBIENT_SPIRE_MUTED
		"vellum", "ark":
			pass
	return look
