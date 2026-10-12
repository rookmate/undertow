class_name Palette
extends RefCounted
## Every colour in Undertow comes from here. Colours have owners (design brief, "Color has owners"):
##   STEWARD_*   the Steward and only the Steward: path, Lattice lamps, ring, gilt, assists, power cores,
##               its narration. Usage is restricted by tests/unit/test_color_rules.gd.
##   TRUTH_CYAN  what the player found alone: off-path survivors, truth cores, unindexed logs, Rewrite.
##   NEON_*      the old city, people selling things to people. Keeps burning after the Quiet.
##   WARD_CYAN   Harbor Ward's own light, hand-wired: its lanterns. The only cyan the city made itself.
##   HUMAN_CREAM human warmth: candles, kitchens, lit windows. Human light is never gold.
##   DANGER      danger and nothing else.
## Hex literals are only allowed in this file (also enforced by the colour-rules test).

# --- Owned colours -----------------------------------------------------------------------------
const STEWARD_GOLD := Color("#F0B35B")
const STEWARD_GOLD_DIM := Color("#F0B35B", 0.35)
const STEWARD_GOLD_HOT := Color(1.88, 1.4, 0.72) # HDR value of the gold, for bloom on emissive gilt.
const TRUTH_CYAN := Color("#7CC7E0")
const WARD_CYAN := Color("#5FD3C6")
const WARD_CYAN_HOT := Color(0.74, 1.62, 1.5)
const TRUTH_CYAN_HOT := Color(0.97, 1.56, 1.76)
const NEON_MAGENTA := Color("#E24C8F")
const NEON_LIME := Color("#9BE36A")
const HUMAN_CREAM := Color("#F3E3C6")
const DANGER := Color("#E5654B")

# --- Muted state / UI neutrals ------------------------------------------------------------------
const IVORY := Color("#ECE8DF")
const IVORY_DIM := Color("#ECE8DF", 0.55)
const IVORY_FAINT := Color("#ECE8DF", 0.18)
const NEAR_BLACK := Color("#0C0D11")
const PANEL := Color("#0C0D11", 0.86)
const GREY_COLD := Color("#7D848C")
const GREY_DEEP := Color("#2B3036")
const SCORCH := Color("#1B1A19")

# --- World materials (not owned colours; never amber) --------------------------------------------
const GROUND_TEAL := Color("#0B1A20")
const COBBLE_A := Color("#363E42")
const COBBLE_B := Color("#3F484D")
const COBBLE_WET := Color("#52626A")
const PAVEMENT := Color("#434A4F")
const STONE_OLD := Color("#45454B")
const PAPER := Color("#B9B3A6")
const BRICK := Color("#66362F")
const BRICK_DARK := Color("#472621")
const BRICK_TOP := Color("#3A2829")
const IRON_VERDIGRIS := Color("#3F7068")
const IRON_DARK := Color("#1A2326")
const BLACK_MIRROR := Color("#06080B")
const STAINED_ROSE := Color("#8C3B5A")
const STAINED_TEAL := Color("#2E6E73")
const WATER_DEEP := Color("#06141A")
const WATER_SHEEN := Color("#1A3A46")
const SKY_VIOLET := Color("#251C3B")
const SKY_TEAL := Color("#0E2329")
const FOG := Color("#9FB3BC")

# --- Kestrel Heights (blue hour: pale stone, lawns, hedges, white blossom) ------------------------------
const KESTREL_STONE_A := Color("#8A8780")
const KESTREL_STONE_B := Color("#97938B")
const KESTREL_WET := Color("#6F7D8C")
const KESTREL_PAVEMENT := Color("#918D86")
const KESTREL_LIMESTONE := Color("#B8AE9D")
const KESTREL_LIMESTONE_SHADE := Color("#8C8375")
const KESTREL_SLATE := Color("#545C69")
const SKY_DUSK_BLUE := Color("#2B3B6B")
const SKY_DUSK_LOW := Color("#4A477A")
const SUNSET_ROSE := Color("#D98A7C")
const LAWN := Color("#3B583A")
const LAWN_STRIPE := Color("#446543")
const HEDGE := Color("#2B4830")
const BLOSSOM := Color("#EDEADF")
const TIMBER := Color("#5B4535")
const GRAVEL := Color("#6C6B67")
## Kestrel's CanvasModulate: the blue hour is brighter than the city's night.
const AMBIENT_DUSK_ON := Color(0.46, 0.48, 0.63)
const AMBIENT_DUSK_MUTED := Color(0.27, 0.28, 0.33)

# --- The Loop (rail ribbons in fog, high over black water) ---------------------------------------------
const LOOP_CONCRETE := Color("#6E7478")
const LOOP_LIVERY := Color("#4E6A70")
const LOOP_LIVERY_SHADE := Color("#36494D")
const LOOP_ROOF := Color("#2C3638")
const SKY_FOG_TOP := Color("#1B2433")
const SKY_FOG_LOW := Color("#2A3540")
const AMBIENT_FOG_ON := Color(0.33, 0.36, 0.46)
const AMBIENT_FOG_MUTED := Color(0.22, 0.24, 0.27)

# --- The Tideworks (rust and black water, desaturated containers, wet steel) ---------------------------
const RUST := Color("#7A3B26")
const RUST_DARK := Color("#4E2619")
const CONTAINER_TEAL := Color("#2F5B5E")
const CONTAINER_RED := Color("#6E2A22")
const CONTAINER_GREY := Color("#5A5E62")
const STEEL_WET := Color("#3A4248")
const DOCK_CONCRETE := Color("#4A4D50")
const DOCK_CONCRETE_B := Color("#53575A")
const SKY_STORM_TOP := Color("#121A24")
const SKY_STORM_LOW := Color("#222A33")
const AMBIENT_STORM_ON := Color(0.31, 0.33, 0.43)
const AMBIENT_STORM_MUTED := Color(0.21, 0.22, 0.25)

# --- Mercy General: long white corridors gone grey, every third light working -----------------------
const WARD_TILE_A := Color("#5C6964")
const WARD_TILE_B := Color("#65726D")
const WARD_GROUT := Color("#39423F")
const WARD_WALL := Color("#A3A8A2")
const WARD_WALL_SHADE := Color("#787E79")
const WARD_WALL_TOP := Color("#4A524E")
const WARD_GLASS := Color("#8FB0B4")
const WARD_LINO := Color("#5A5047")
const YARD_ASPHALT := Color("#2E3235")
const YARD_PAINT := Color("#C9C5B8")
const AMBULANCE_WHITE := Color("#C8CBC6")
const SKY_WARD_TOP := Color("#11161B")
const SKY_WARD_LOW := Color("#1B2328")
const AMBIENT_WARD_ON := Color(0.32, 0.35, 0.39)
const AMBIENT_WARD_MUTED := Color(0.2, 0.22, 0.24)
const STERILE_MIST := Color("#CFE3DC")

# --- Greywater: concrete, kelp, standing water, fog so thick the path lights are halos -------------
const SEAWALL_CONCRETE := Color("#5B6264")
const SEAWALL_CONCRETE_B := Color("#646B6C")
const LOW_STREET := Color("#3A4446")
const LOW_STREET_WET := Color("#4D5D61")
const KELP := Color("#3E4A2E")
const KELP_DARK := Color("#2A331F")
const GRATING := Color("#2C3133")
const PUMP_CONCRETE := Color("#6A6F6C")
const PUMP_CONCRETE_SHADE := Color("#4B504E")
const PUMP_ROOF := Color("#383D3C")
const SKY_MARROW_TOP := Color("#1E2A2E")
const SKY_MARROW_LOW := Color("#34434A")
const AMBIENT_MARROW_ON := Color(0.34, 0.38, 0.42)
const AMBIENT_MARROW_MUTED := Color(0.22, 0.24, 0.26)

# --- The Vellum's newsroom: worn parquet, a hundred black screens with the ring burned into them ----
const PARQUET := Color("#4A3C31")
const PARQUET_B := Color("#54443A")
const NEWS_DESK := Color("#3B3833")
## The ring the Feed showed for sixteen years, burned into every dead screen: a ghost, not the Steward's
## gold (nothing here is its now).
const SCREEN_BURN := Color(0.62, 0.6, 0.55, 0.16)
## The Feed at full white, turned on you (FeedBlind): a cold screen white, not the human cream.
const FEED_WHITE := Color("#E6EDF2")

# --- Harbor Ward: boats as houses, tarred timber, kelp on the pilings, its own cyan lanterns -------
const PIER_PLANK := Color("#4C3F33")
const PIER_PLANK_B := Color("#56483A")
const WARD_STONE := Color("#3F4446")
const WARD_STONE_B := Color("#474D4F")
const BOATHOUSE := Color("#3A3532")
const BOATHOUSE_SHADE := Color("#2A2624")
const BOATHOUSE_ROOF := Color("#2F3A3B")
const SKY_HARBOR_TOP := Color("#0F1A22")
const SKY_HARBOR_LOW := Color("#1D3038")
const AMBIENT_HARBOR_ON := Color(0.36, 0.42, 0.46)
const AMBIENT_HARBOR_MUTED := Color(0.36, 0.42, 0.46)

# --- Characters ---------------------------------------------------------------------------------
const COVERALL := Color("#39424A")
const COVERALL_LIGHT := Color("#4B565E")
const HIVIS_DULL := Color("#B9B28A")
const SKIN_SHADOW := Color("#5E4A42")
const CUSTODIAN_SHELL := Color("#C9CDCB")
const CUSTODIAN_PANEL := Color("#3F7A4A")
const CLERK_SHELL := Color("#8F8A7E")
const WAITING_GREY := Color("#5C6166")

# --- Lighting states ----------------------------------------------------------------------------
## CanvasModulate for the world. Voice on: soft violet-teal night. Muted: cold grey, near-black.
const AMBIENT_VOICE_ON := Color(0.29, 0.31, 0.44)
const AMBIENT_MUTED := Color(0.22, 0.235, 0.26)
