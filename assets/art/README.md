# Painted art

The game uses 162 named painted frames across all eight districts and the Ark. The 24 new sheets
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
| `operator_motion`, `operator_carry` | Front and rear idle/walk poses, mirrored directions, dodge, downed and carrying Noor; carrying remains visible during a dodge |
| `civilians` | Noor, Teo, the Waiting, survivors, Wardfolk and Noor seated/downed |
| `enemies_front`, `enemies_back` | Custodian, Clerk, Lamplighter, Salvager, Sterilizer and Warden |
| `boss_bodies`, `boss_parts` | Conductor, Crane, Surgeon, Lung, Editor and Warden-Prime, with separate moving housings, arms, bellows, masts, rollers and loads |
| `tools_cores` | Equipped tools, found weapons, loadout illustrations, power cores and truth cores |
| `panoramas_a`, `panoramas_b`, `title_painting` | District-specific backgrounds, Ark background and title painting |
| `city_map_v2`, `council_v2` | Industrial Meridian navigation map and recessed Council Chamber |

## Runtime contracts

`ArtCatalog` loads `complete/catalog.json` once and caches textures, atlas regions, UVs and lamp/earpiece
anchors. Missing keys produce errors. `ArtBindings` selects terrain and scenery explicitly.
`DistrictLook` selects the architecture and background for each district; test arenas use the
established Vellum default. All PNGs have tracked import recipes with mipmaps enabled.

Tiles retain the existing 128 × 72 ground diamonds and depth order. A terrain painting spans a 2 × 2
cell block with shared UV edges. Building cells map painted materials onto their exposed faces,
repeat within atlas crops, hide joined walls and map slate or steel onto their roofs. Vehicles retain
joined faces. Rails follow their neighbouring cells. Source crops isolate each sprite, including
objects that extend beyond a generated sheet's nominal grid; original pixels are never rewritten.

`tools/make_art_catalog.py` reproducibly builds the crop metadata using Pillow. Reviewed search boxes
and alpha bounds keep neighbouring props out of a frame. Native atlas previews are available with
`godot --disable-vsync --path . --script res://tools/art_gallery.gd`; assembled district, boss,
carrying and Ark previews use `godot --disable-vsync --path . res://tools/art_stage.tscn`.
Both save their captures under `reports/art-complete/`. The assembled preview uses
`user://art_preview_saves` and `user://art_preview_settings.cfg` for its synthetic run.

Physical paintings sit under live windows, lenses, weapon glows and switchable gilt. Transparent
openings preserve visible cages and mullions. The canonical Steward ring, predicted path, shadows,
weather, fog, water level, reflections, attack warnings, particles, text and interface controls
remain code drawn because they respond to play. Boss parts still move with their phases; actor
motion combines painted pose frames with mirroring, bobbing and transforms. This is complete painted
coverage, with room for later animation and artistic polish.

`catalog.json` is included explicitly in every export preset because the renderer reads it at
runtime. Tests check every enum/owner binding, frame bounds, anchors, alpha and mipmaps. Gameplay
and rendered evidence live in `reports/art-complete/`; final validation is recorded in `PROGRESS.md`
and [`../../reviews/painted-art-complete.md`](../../reviews/painted-art-complete.md).

Editor imports run serially because parallel empty-cache imports crashed while Godot 4.7.2 saved an
existing font resource. A fresh copy with the committed import setting loads without errors or
warnings. The final gate passes 515 tests and every gameplay scenario, and the exported pack was
loaded and toured. The preview's initial save-slot mistake and subsequent isolation are recorded
in the review; affected local files are preserved in the ignored reports.
