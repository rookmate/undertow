# Walking and terrain depth

The previous walk frames kept the same leg forward. Swapping them and bobbing the whole body
could not produce a continuous stride. The full-screen district painting also flattened the
playable street against a distant scene.

The primary Codex agent implemented the changes below. A read-only `sol_analyst` investigated
the original behavior, reviewed the implementation and checked the animation fixes on 2026-10-15.
Its final focused review found no remaining animation issue and independently passed all seven
gait tests. It found no blocking terrain, atlas, ordering, aim-ownership or save-isolation issue.

## Changes

The Operator uses painted torso, arm, thigh, calf and boot parts with reviewed joint anchors.
Actual post-collision travel advances two opposite feet through planted and passing phases.
Standing against a wall stops the cycle. Carrying slows its cadence and uses separate painted
torsos that preserve Noor's silhouette, lantern and the Operator's scale. Rolls and downed poses
retain their painted assets; external knockback and pulls do not advance the walk.

Native iterations corrected shoulder placement, excessive knee lift and flattened boots.
The boots now keep their painted shape while the leg segments foreshorten. Two generated
full-body walk sheets were rejected because they repeated the original leading-leg problem.
Only the accepted three sheets and their prompts, refinement history and joint metadata are
included. Their original pixels are unchanged. The catalog has 178 frames across 27 sheets
plus the original Kestrel materials.

Terrain edges use the whole grid's physical support, including buildings and lawns, rather than
chunk-local walkability. Exposed edges have masonry, coping, grass verges, timber pilings or open
steel trusses. Water sits below the quay walls and ripples in world space. Two moving mist planes
replace the stretched district panorama. Ground stays stable, and the design documents describe
the exposed construction as a cutaway through an intact city. Navigation, collision and the
Steward's three-cell prediction keep their existing rules.

## Review findings and fixes

1. **P2, stance feet snapped during reversals.** A planted contact could jump about 59 pixels when
   the movement heading reversed. Gait turns now retain the world contact and rebase the local
   trajectory. Lifted feet settle exponentially toward the new trajectory, retaining any remaining
   correction when they land. Regressions cover reversals, right-angle turns and late-flight turns.
2. **P2, arms were a quarter-cycle late.** Cosine aligns the swing with the contact phases.
   Follow-up review caught the rear shoulder-side exchange, and a new anchor-based test exposed
   the mirror interaction. The final swing uses rear-view sign and projected movement direction;
   outer mirroring already exchanges the physical arm. Tests cover front/rear, both mirrors, six
   headings and both contacts. All seven gait tests pass independently under Sol's closure check.
3. **P2, mist mixed physical pixels and logical viewport size.** `SCREEN_UV` now supplies normalized
   coordinates, which are converted into the logical viewport before applying camera motion.
   The final exported pack exercises this shader with the native Vulkan renderer.

## Validation

- `final-gate-summary.log`: complete gate PASS with 549 tests, import, smoke gameplay, the
  310-check campaign, all three endings, revisit, tool door and eight district tours. These use
  headless fixed-60-fps simulation. Campaign invulnerability follows the existing gate policy.
- `final-tests.log`: full 550-test suite PASS after the last arm-sign correction and added test.
  This includes atlas bounds, anchors, transparency, mipmaps, terrain topology, collision-stopped
  gait and carrying speed. The full campaign preceded that drawing-only correction.
- `final-stage.log` and `final-stage/`: native captures of all districts, boss openings, muted
  views, carrying, downed state, Ark and map. The final mist coordinate fix is also exercised by
  the exported Harbor tour below.
- `motion-final.log` and `movement.mp4`: final native 28.7-second recording PASS. It uses real
  Operator physics/input and covers complete cycles in four directions, normal and carrying,
  continuous reversals, stops, dodge, hit and downed state.
- `terrain-walk.mp4`: 40 seconds of native Loop walking/combat. This intentionally shortened
  recording does not finish the route, so its log's unfinished-route result is not claimed as a
  passing scenario. The separate complete gate validates progression.
- `live-loop.log`: native Loop tour PASS, 60 fps average and 57 fps 1% low, Intel Iris Xe,
  1920×1080, Forward+, vsync disabled with a 60 fps cap. Capturing video is excluded from this
  performance measurement.
- `export-final.log` and `pack-harbor-final.log`: Linux pack export and native Harbor tour verify
  the shipped catalog, imported textures, shaders and final rig code.
- Catalog regeneration produces 178 frames from 27 sheets plus Kestrel originals.
  `git diff --check` passes.

Evidence lives in the ignored `reports/movement-terrain/` directory. Every run uses a scratch
`XDG_DATA_HOME`; both preview stages also select their own save and settings paths. Steam Deck,
Windows and macOS checks listed in `PROGRESS.md` remain pending.
