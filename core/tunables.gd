class_name Tunables
extends RefCounted
## Numbers the brief marks *(tunable)* plus the slice's balance values, in one place.

# --- Camera and grid (see DECISIONS.md: 128×72 tiles ≈ 56° tilt, matches image 10) ----------------
const TILE_W := 128
const TILE_H := 72

# --- Predictive path --------------------------------------------------------------------------------
const PATH_TILES_AHEAD := 3

# --- Ending: Rewrite unlock --------------------------------------------------------------------------
const REWRITE_VOICE_RATIO_MIN := 0.35
const REWRITE_VOICE_RATIO_MAX := 0.65
const REWRITE_MIN_TRUTH_CORES := 5

# --- Voice off -----------------------------------------------------------------------------------------
const MUTED_DAMAGE_TAKEN_MULT := 1.4

# --- Cores ------------------------------------------------------------------------------------------------
const CORES_CARRIED_PER_LEVEL := 2

# --- Trust -------------------------------------------------------------------------------------------------
const TRUST_MIN := -10
const TRUST_MAX := 10

## Workshop upgrades per weapon mode.
## Field dressings (the Clinic): how many you can carry, and the Integrity each gives back.
const DRESSINGS_MAX := 3
const DRESSING_HEAL := 40.0

const UPGRADE_LEVELS := 2
