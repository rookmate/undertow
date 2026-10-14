class_name ArtBindings
extends RefCounted
## Explicit coverage of terrain, scenery and district materials. Physical art has no shape fallback.

const FLOOR: Dictionary[int, String] = {
	LevelGrid.Floor.COBBLE: "mat_cobble",
	LevelGrid.Floor.PAVEMENT: "mat_concrete",
	LevelGrid.Floor.OLD_QUAY: "mat_quay",
	LevelGrid.Floor.STACKS: "mat_paper",
	LevelGrid.Floor.STAIRS: "mat_steps",
	LevelGrid.Floor.WATER: "mat_water",
	LevelGrid.Floor.RAILING: "mat_concrete",
	LevelGrid.Floor.LOW_WALL: "mat_concrete",
	LevelGrid.Floor.CONCRETE: "mat_concrete",
	LevelGrid.Floor.FOUNDATION: "mat_foundation",
	LevelGrid.Floor.LAWN: "kestrel_lawn",
	LevelGrid.Floor.STEPS: "mat_steps",
	LevelGrid.Floor.TIMBER: "mat_timber",
	LevelGrid.Floor.GRAVEL: "mat_gravel",
	LevelGrid.Floor.TRACK: "mat_track",
	LevelGrid.Floor.CARRIAGE: "mat_steel",
	LevelGrid.Floor.GANTRY: "mat_grating",
	LevelGrid.Floor.CAB: "mat_steel",
	LevelGrid.Floor.TILE: "mat_tile",
	LevelGrid.Floor.ASPHALT: "mat_asphalt",
	LevelGrid.Floor.STAFF: "mat_staff",
	LevelGrid.Floor.SEAWALL: "mat_seawall",
	LevelGrid.Floor.LOW_STREET: "mat_seawall",
	LevelGrid.Floor.KELP: "mat_kelp",
	LevelGrid.Floor.GRATING: "mat_grating",
	LevelGrid.Floor.PARQUET: "mat_parquet",
	LevelGrid.Floor.PIER: "mat_timber",
	LevelGrid.Floor.WARD_STONE: "mat_cobble",
	LevelGrid.Floor.GLASS: "mat_glass",
	LevelGrid.Floor.CULVERT: "mat_brick",
}

const PROP: Dictionary[int, String] = {
	StaticProp.Kind.LOW_WALL: "low_wall",
	StaticProp.Kind.SHELF: "shelf",
	StaticProp.Kind.KIOSK: "kiosk",
	StaticProp.Kind.BOLLARD: "bollard",
	StaticProp.Kind.HEDGE: "kestrel_hedge",
	StaticProp.Kind.PLANTER: "kestrel_planter",
	StaticProp.Kind.SPRINKLER: "sprinkler",
	StaticProp.Kind.BED: "bed",
	StaticProp.Kind.DESK: "desk",
	StaticProp.Kind.CONTAINER: "container",
	StaticProp.Kind.PARTITION: "partition",
	StaticProp.Kind.NURSE_DESK: "nurse_desk",
	StaticProp.Kind.HOSPITAL_BED: "hospital_bed",
	StaticProp.Kind.TURBINE: "turbine_mast",
	StaticProp.Kind.NEWS_DESK: "news_desk",
	StaticProp.Kind.LANTERN: "lantern",
	StaticProp.Kind.PILING: "piling",
	StaticProp.Kind.RACK: "rack",
	StaticProp.Kind.PANE: "pane",
}

const PROP_RECT: Dictionary[int, Rect2] = {
	StaticProp.Kind.LOW_WALL: Rect2(-64, -62, 128, 98),
	StaticProp.Kind.SHELF: Rect2(-40, -141, 80, 164),
	StaticProp.Kind.KIOSK: Rect2(-45, -121, 90, 146),
	StaticProp.Kind.BOLLARD: Rect2(-10, -38, 20, 44),
	StaticProp.Kind.HEDGE: Rect2(-60, -68, 120, 102),
	StaticProp.Kind.PLANTER: Rect2(-36, -78, 72, 88),
	StaticProp.Kind.SPRINKLER: Rect2(-12, -16, 24, 20),
	StaticProp.Kind.BED: Rect2(-51, -51, 102, 80),
	StaticProp.Kind.DESK: Rect2(-45, -80, 90, 105),
	StaticProp.Kind.CONTAINER: Rect2(-63, -93, 126, 128),
	StaticProp.Kind.PARTITION: Rect2(-58, -96, 116, 128),
	StaticProp.Kind.NURSE_DESK: Rect2(-48, -108, 96, 135),
	StaticProp.Kind.HOSPITAL_BED: Rect2(-51, -50, 102, 79),
	StaticProp.Kind.TURBINE: Rect2(-16, -116, 32, 124),
	StaticProp.Kind.NEWS_DESK: Rect2(-50, -100, 100, 128),
	StaticProp.Kind.LANTERN: Rect2(-18, -116, 42, 124),
	StaticProp.Kind.PILING: Rect2(-12, -50, 24, 58),
	StaticProp.Kind.RACK: Rect2(-51, -161, 102, 190),
	StaticProp.Kind.PANE: Rect2(-58, -166, 116, 198),
}

const WALL: Dictionary[String, String] = {
	"kestrel": "mat_plaster",
	"loop": "mat_steel",
	"tideworks": "mat_steel",
	"mercy": "mat_hospital_wall",
	"vellum": "mat_brick",
	"greywater": "mat_concrete",
	"harbor": "mat_clapboard",
	"spire": "mat_glass",
	"ark": "mat_brick",
}

static func ground_key(kind: int, district: String) -> String:
	if district == "kestrel":
		if kind == LevelGrid.Floor.COBBLE:
			return "kestrel_cobble"
		if kind in [LevelGrid.Floor.PAVEMENT, LevelGrid.Floor.LOW_WALL]:
			return "kestrel_paving"
	return FLOOR.get(kind, "")
