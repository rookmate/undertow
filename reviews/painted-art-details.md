# Kestrel painted details

Reviewed by the read-only `sol_analyst` agent on 2026-10-14. No implementation blockers found.

## Scope and verified contracts

Six transparent PNGs add window and door surrounds, balcony ironwork, hedges, blossom urns and lamp
housings. Seven AtlasTexture resources select tight crops, including a single balcony section reused
for terrace railings. Prompts are in `assets/art/detail-prompts.json`; assets and runtime contracts
are listed in `assets/art/README.md`.

Only Kestrel selects these assets. Other districts keep their existing geometry branches. Buildings
draw base surfaces, emissive window fills, shaded painted ornaments, and then the separately
switchable emissive gilt. Muted screenshots preserve human windows and extinguish gold.

Polygon UV conversion maps normalized atlas-region coordinates to the underlying bitmap. All crop
regions fit inside their source images. All six source images are RGBA with true transparency and
mipmaps. The railing crop has transparent openings; its denser appearance comes from painted curls
and repeated supports. Its quads still connect cell centers to the existing half-cell endpoints at
44 px height, including corners. Garden props retain footprint-center node positions and y-sort.

Sol independently measured the lamp aperture at `(-0.19, -150.13)` in local game coordinates,
matching the live lens center `(0, -150)`. Its approximately 26.5 by 27 px opening fits over the
glow. The shaded housing draws above the emissive lens; muted darkness remains below it. Point
lighting, reflections, maps and collision are unchanged.

## Validation

- Normal and empty-cache imports contain no errors or warnings.
- All 509 existing tests pass. Final script compilation also passes after the railing addition.
- Smoke gameplay, all eight district tours, all three endings, revisit and tool-door checks pass.
- Windowed Kestrel and Vellum tours pass. Kestrel's listening, muted and Reliquary screenshots were inspected.
- Movie Maker captured `reports/art-detail-pass/kestrel-details.mp4`.

Logs and images are in `reports/art-detail-pass/`, ignored by git. Headless scenarios use fixed 60 fps
simulation and omit screenshot requests because of the existing screenshot wait described in
`reviews/painted-art-first-pass.md`. Windowed runs supply rendered visual evidence.

The full campaign gate was not rerun for this detail pass. The earlier Harbor Ward campaign stall
was independently reproduced on unchanged HEAD and remains a separate baseline limitation. Full
directional character animation, NPCs, enemies and the remaining props still need painted assets.
