# Painted art

The game uses 178 named painted frames across all eight districts and the Ark. The 27 sheets
in `complete/` supply terrain, architecture, scenery, characters, enemies, bosses, machinery,
tools, cores, backgrounds and the city map. Kestrel's original carved details and materials are shared
where appropriate. Every physical render owner is covered; the complete inventory is
[`complete/coverage.json`](complete/coverage.json).

All images were generated with the **built-in image_gen tool** using the approved local `port-city/`
concepts. The full prompts, reference roles and refinement prompts are saved in
[`complete/specs.json`](complete/specs.json). Earlier Kestrel prompts are in `prompts.json` and
`detail-prompts.json`. Original generated PNGs remain unchanged. `city_map_v2.png` and
`council_v2.png` replace the first map and chamber illustrations without deleting the originals.
The old Operator still sheet and first map are retained for provenance and excluded from exports.

## Coverage

| Collection | Runtime use |
| --- | --- |
| `materials_city`, `materials_ground`, `ground_details` | All 30 physical floor kinds, district wall materials and roofs; stairs, lino, asphalt, flagstones and seawalls have distinct paintings |
| `props_city`, `props_industrial`, `props_clinical`, `props_harbor`, `props_mechanical`, `props_misc` | All 23 static scenery kinds, joined vehicles, doors, gates, rails, cranks, hatches, ladders, lamps, docks and machinery |
| `facade_modules` and Kestrel details | All 18 facade kinds: civic stone, brick, hospital panels, pumping works, tarred boat houses and black glass |
| `operator_rig`, `carry_rig` | Articulated front/rear walking and idle bodies, fixed-size boots, counter-swinging arms and Noor carried over the shoulder |
| `operator_motion`, `operator_carry` | Dodge/downed poses and the carrying dodge; earlier walk poses retained for provenance |
| `terrain_edges` | Chipped stone coping, grass verges, tarred timber beams and open steel trusses around physical ground |
| `civilians` | Noor, Teo, the Waiting, survivors, Wardfolk and Noor seated/downed |
| `enemies_front`, `enemies_back` | Custodian, Clerk, Lamplighter, Salvager, Sterilizer and Warden |
| `boss_bodies`, `boss_parts` | Conductor, Crane, Surgeon, Lung, Editor and Warden-Prime, with separate moving housings, arms, bellows, masts, rollers and loads |
| `tools_cores` | Equipped tools, found weapons, loadout illustrations, power cores and truth cores |
| `panoramas_a`, `panoramas_b`, `title_painting` | Earlier district panorama art retained for provenance; title painting remains in use. Gameplay uses continuous atmosphere around the actual terrain |
| `city_map_v2`, `council_v2` | Industrial Meridian navigation map and recessed Council Chamber |

## Runtime contracts

`ArtCatalog` loads `complete/catalog.json` once and caches textures, atlas regions, UVs and lamp/earpiece
anchors. Missing keys produce errors. `ArtBindings` selects terrain and scenery explicitly.
`DistrictLook` selects architecture and atmospheric colours for each district; test arenas use the
established Vellum default. All PNGs have tracked import recipes with mipmaps enabled.

Tiles retain the existing 128 × 72 ground diamonds and depth order. A terrain painting spans a 2 × 2
cell block with shared UV edges. Building cells map painted materials onto their exposed faces,
repeat within atlas crops, hide joined walls and map slate or steel onto their roofs. Vehicles retain
joined faces. Rails follow their neighbouring cells. Source crops isolate each sprite, including
objects that extend beyond a generated sheet's nominal grid; original pixels are never rewritten.
`TerrainEdges` reads neighbouring physical floor kinds across chunk joins, including buildings and
solid lawns. Masonry fades into the atmosphere; transparent trusses and timber pilings support decks.
Static water sits beneath foundations and shimmers inside its own atlas region. Greywater's gameplay
tide keeps its existing layer and timing.

`tools/make_art_catalog.py` reproducibly builds the crop metadata using Pillow. Reviewed search boxes
and alpha bounds keep neighbouring props out of a frame. Native atlas previews are available with
`godot --disable-vsync --path . --script res://tools/art_gallery.gd`; assembled district, boss,
carrying and Ark previews use `godot --disable-vsync --path . res://tools/art_stage.tscn`.
Both save their captures under `reports/art-complete/`. The assembled preview uses
`user://art_preview_saves` and `user://art_preview_settings.cfg` for its synthetic run.

Physical paintings sit under live windows, lenses, weapon glows and switchable gilt. Transparent
openings preserve visible cages and mullions. The canonical Steward ring, predicted path, shadows,
weather, fog, water level, reflections, attack warnings, particles, text and interface controls
remain code drawn because they respond to play. Boss parts still move with their phases. The Operator uses painted cutout limbs with reviewed joint
anchors. `OperatorGait` advances from actual movement after collision resolution, alternates support
and passing feet, and yields to rolls, knockback, pulls and downed poses. Boots keep their shape while
calves foreshorten. The normal and carrying bodies share the same legs and world-space root.
The first attempted eight-frame replacement sheets repeated the same leading leg and were rejected.

Record complete cycles with `godot --write-movie /tmp/motion.avi --fixed-fps 30 --disable-vsync
res://tools/motion_stage.tscn`. This preview drives real player input and isolates saves/settings.
Current motion and terrain evidence is under `reports/movement-terrain/`.

`catalog.json` is included explicitly in every export preset because the renderer reads it at
runtime. Tests check every enum/owner binding, frame bounds, anchors, alpha and mipmaps. Gameplay
and rendered evidence live in `reports/art-complete/`; final validation is recorded in `PROGRESS.md`
and [`../../reviews/painted-art-complete.md`](../../reviews/painted-art-complete.md).

Editor imports run serially because parallel empty-cache imports crashed while Godot 4.7.2 saved an
existing font resource. A fresh copy with the committed import setting loads without errors or
warnings. The initial painted-coverage gate passed 523 tests and every gameplay scenario, and its exported pack was
loaded and toured. The preview's initial save-slot mistake and subsequent isolation are recorded
in the review; affected local files are preserved in the ignored reports.
