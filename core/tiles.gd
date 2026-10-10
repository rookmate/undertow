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

# --- The Ark -----------------------------------------------------------------------------------------
## The Clinic (from Mercy General) and its door.
const CLINIC := "μ"
const CLINIC_DOOR := "ν"
## The Pumphouse (from Greywater) and its door.
const PUMPHOUSE := "ψ"
const PUMPHOUSE_DOOR := "ω"

const BY_NAME: Dictionary[String, String] = {
	"hospital_tile": HOSPITAL_TILE, "asphalt": ASPHALT, "staff_floor": STAFF_FLOOR, "partition": PARTITION,
	"ward_seal": WARD_SEAL, "ambulance": AMBULANCE, "nurse_desk": NURSE_DESK, "sterilizer": STERILIZER,
	"hospital_wall": HOSPITAL_WALL, "hospital_door": HOSPITAL_DOOR, "hospital_bed": HOSPITAL_BED,
	"clinic": CLINIC, "clinic_door": CLINIC_DOOR, "pumphouse": PUMPHOUSE, "pumphouse_door": PUMPHOUSE_DOOR,
	"seawall": SEAWALL, "low_street": LOW_STREET, "kelp": KELP, "marrow": MARROW, "grating": GRATING,
	"pump_wall": PUMP_WALL, "pump_door": PUMP_DOOR, "turbine": TURBINE, "tide_gauge": TIDE_GAUGE,
}


## The internal code of a named tile, or "" if there's no such tile.
static func code_of(tile_name: String) -> String:
	return BY_NAME.get(tile_name, "")
