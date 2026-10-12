class_name Tiles
extends RefCounted
## Named tiles for maps' own legends. A map renames its characters to these with '% <char> <tile>'
## lines (in Mercy General '.' is hospital tile, not the Vellum's cobble), so a new district is never
## short of letters. Each named tile has an internal code: a character no map types directly, which is
## what the grid stores and what code compares against (Tiles.WARD_SEAL, never a literal). The Act 1
## maps' own single letters (the legend in vellum_street.txt) are their own codes and have no name.

# --- Mercy General ---------------------------------------------------------------------------------
## Corridors, wards and the theatre: on the Lattice.
const HOSPITAL_TILE := "α"
## The ambulance yard: on the Lattice.
const ASPHALT := "β"
## The night nurses' station: off the Lattice (they kept paper).
const STAFF_FLOOR := "γ"
## A glass partition, cut away to waist height so the wards can be seen into.
const PARTITION := "δ"
## A ward door the Steward sealed at the Quiet (WardSeal).
const WARD_SEAL := "ε"
const AMBULANCE := "ζ"
const NURSE_DESK := "η"
## Where a Sterilizer starts.
const STERILIZER := "θ"
## The hospital's walls (tall, on the back edges), its locked doors, and a ward bed.
const HOSPITAL_WALL := "ι"
const HOSPITAL_DOOR := "κ"
const HOSPITAL_BED := "λ"

# --- Greywater --------------------------------------------------------------------------------------
## The seawall's concrete: high ground, on the Lattice.
const SEAWALL := "ξ"
## A low street: on the Lattice, and it floods at high tide (Tide).
const LOW_STREET := "ο"
## Kelp on a low street: it slows you, and it floods too.
const KELP := "π"
## The thick Marrow over a low street: on the Lattice, but the Steward can't see through it.
const MARROW := "ρ"
## Iron grating in the old manual pump room: off the Lattice.
const GRATING := "σ"
## A pumping station's walls (tall, on the back edges) and its doors.
const PUMP_WALL := "τ"
const PUMP_DOOR := "υ"
## A tidal turbine turning in the channel; a tide gauge people read by hand.
const TURBINE := "φ"
const TIDE_GAUGE := "χ"

# --- The Vellum (Act 2's east bank) -------------------------------------------------------------------
# (The lowercase Greek letters are spent; these are uppercase.)
## The newsroom's parquet: on the Lattice (the Feed was written here).
const NEWSROOM_FLOOR := "Γ"
## A newsroom desk: a black screen with the ring burned into it.
const NEWSROOM_DESK := "Δ"

# --- Harbor Ward (no Lattice anywhere in it but the ferry slip and the border) ----------------------------
## Pier planks on pilings over the water, and the Ward's hand-laid stone lanes: both off the Lattice.
const PIER := "Θ"
const WARD_STONE := "Λ"
## A boat-house (tall, on the back edges), and one with its door.
const BOATHOUSE := "Ξ"
const BOATHOUSE_DOOR := "Π"
## A Wardfolk lantern on a post, hand-wired, cyan; a piling standing in the water, kelp on it.
const LANTERN := "Σ"
const PILING := "Φ"
## The Harbor Bridge's severed end.
const BRIDGE_STUB := "Ψ"
## Where a Warden is posted (it walks its beat from there), and where the curfew patrol comes in when
## you pick Noor up.
const WARDEN := "Ω"
const PATROL := "Ю"
## Noor, down at the border (her turn); the Wardfolk's boat on the depot slipway.
const NOOR_DOWN := "Ж"
const WARD_BOAT := "Б"
## A boat-house with the Ward's own radio mast on its roof, dark since the city went quiet.
const WARD_MAST := "И"

# --- The Ark -----------------------------------------------------------------------------------------
## The Clinic (from Mercy General) and its door.
const CLINIC := "μ"
const CLINIC_DOOR := "ν"
## The Pumphouse (from Greywater) and its door.
const PUMPHOUSE := "ψ"
const PUMPHOUSE_DOOR := "ω"
## The Commons (from Harbor Ward), on new ground at the Ark's back rim, and its door.
const COMMONS := "Ц"
const COMMONS_DOOR := "Ч"
## Where the Wardfolk who came over stand, by the Commons (only once it stands).
const WARDFOLK := "Щ"
## The Council Chamber (from the Spire), sunk into a foundation behind Noor, and its door.
const COUNCIL := "Ш"
const COUNCIL_DOOR := "Й"

# --- The Spire ---------------------------------------------------------------------------------------
## Black glass floor, the Steward's own (on the Lattice); a server rack in the cooling halls; a glass pane
## standing in the atrium; where the Steward says what it did (a Confession).
const SPIRE_GLASS := "Ы"
const RACK := "Э"
const PANE := "Ъ"
const CONFESSION := "Я"

# --- How tall the solid ones stand -------------------------------------------------------------------
## Solid named things taller than a chest-height shot: they stop sight, swings and shots
## (LevelGrid.blocks_line). Buildings stop them anyway.
const TALL := AMBULANCE + TURBINE + RACK
## Solid named things at waist height or below, or thin: you see, swing and shoot over or past them.
## A test keeps every solid tile in one of the two.
const LOW := PARTITION + NURSE_DESK + HOSPITAL_BED + TIDE_GAUGE + NEWSROOM_DESK + LANTERN + PILING + WARD_BOAT \
	+ PANE + COUNCIL

const BY_NAME: Dictionary[String, String] = {
	"hospital_tile": HOSPITAL_TILE, "asphalt": ASPHALT, "staff_floor": STAFF_FLOOR, "partition": PARTITION,
	"ward_seal": WARD_SEAL, "ambulance": AMBULANCE, "nurse_desk": NURSE_DESK, "sterilizer": STERILIZER,
	"hospital_wall": HOSPITAL_WALL, "hospital_door": HOSPITAL_DOOR, "hospital_bed": HOSPITAL_BED,
	"clinic": CLINIC, "clinic_door": CLINIC_DOOR, "pumphouse": PUMPHOUSE, "pumphouse_door": PUMPHOUSE_DOOR,
	"seawall": SEAWALL, "low_street": LOW_STREET, "kelp": KELP, "marrow": MARROW, "grating": GRATING,
	"pump_wall": PUMP_WALL, "pump_door": PUMP_DOOR, "turbine": TURBINE, "tide_gauge": TIDE_GAUGE,
	"newsroom_floor": NEWSROOM_FLOOR, "newsroom_desk": NEWSROOM_DESK,
	"pier": PIER, "ward_stone": WARD_STONE, "boathouse": BOATHOUSE, "boathouse_door": BOATHOUSE_DOOR,
	"lantern": LANTERN, "piling": PILING, "bridge_stub": BRIDGE_STUB, "warden": WARDEN,
	"patrol": PATROL, "noor_down": NOOR_DOWN, "ward_boat": WARD_BOAT, "commons": COMMONS, "commons_door": COMMONS_DOOR,
	"wardfolk": WARDFOLK, "ward_mast": WARD_MAST, "spire_glass": SPIRE_GLASS, "rack": RACK, "pane": PANE, "confession": CONFESSION,
	"council": COUNCIL, "council_door": COUNCIL_DOOR,
}


## The internal code of a named tile, or "" if there's no such tile.
static func code_of(tile_name: String) -> String:
	return BY_NAME.get(tile_name, "")
