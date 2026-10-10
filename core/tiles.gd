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

const BY_NAME: Dictionary[String, String] = {
	"hospital_tile": HOSPITAL_TILE, "asphalt": ASPHALT, "staff_floor": STAFF_FLOOR, "partition": PARTITION,
	"ward_seal": WARD_SEAL, "ambulance": AMBULANCE, "nurse_desk": NURSE_DESK, "sterilizer": STERILIZER,
	"hospital_wall": HOSPITAL_WALL, "hospital_door": HOSPITAL_DOOR, "hospital_bed": HOSPITAL_BED,
}


## The internal code of a named tile, or "" if there's no such tile.
static func code_of(tile_name: String) -> String:
	return BY_NAME.get(tile_name, "")
