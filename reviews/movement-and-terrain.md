# Actor animation and terrain depth

The previous walk frames kept the same leg forward. Swapping them and bobbing the whole body
could not produce a continuous stride. The full-screen district painting also flattened the
playable street against a distant scene.

The primary Codex agent implemented the changes below. A read-only `sol_analyst` investigated
the original behavior, reviewed the implementation and checked the animation fixes on 2026-10-15.
Its Operator closure review passed all seven gait tests. The expanded actor review found a reversed
Warden stroke and stale art dependencies; both are fixed. Its final focused closure independently
passed six actor-animation and four catalog tests, with no remaining P1/P2 findings in those changes.
It found no blocking terrain, atlas, ordering, aim-ownership or save-isolation issue.

## Changes

The Operator uses painted torso, arm, thigh, calf and boot parts with reviewed joint anchors.
Actual post-collision travel advances two opposite feet through planted and passing phases.
Standing against a wall stops the cycle. Carrying slows its cadence and uses separate painted
torsos that preserve Noor's silhouette, lantern and the Operator's scale. Rolls and downed poses
retain their painted assets; external knockback and pulls do not advance the walk.

Native iterations corrected shoulder placement, excessive knee lift and flattened boots.
The boots now keep their painted shape while the leg segments foreshorten. Two generated
full-body walk sheets were rejected because they repeated the original leading-leg problem.
The accepted Operator, carry and terrain sheets retain their original pixels and prompts. Three
further sheets supply light machines, heavy machines and civilians, using the existing actor art
as references. The current catalog has 251 frames across 30 sheets plus the Kestrel originals.
Reviewed crops isolate joint parts and boots without changing the generated pixels.

Terrain edges use the whole grid's physical support, including buildings and lawns, rather than
chunk-local walkability. Exposed edges have masonry, coping, grass verges, timber pilings or open
steel trusses. Water sits below the quay walls and ripples in world space. Two moving mist planes
replace the stretched district panorama. Ground stays stable, and the design documents describe
the exposed construction as a cutaway through an intact city. Navigation, collision and the
Steward's three-cell prediction keep their existing rules.

## Enemy, boss and companion review

The first pass exercised enemies during gameplay but only reviewed the Operator's complete gait in
native recordings. The follow-up review checked each enemy family, every boss and moving companions.

| Actor | Finding and change |
| --- | --- |
| Clerk | Static legs skated while pursuing. Painted joints now walk, and its arm throws on the existing bale deadline. |
| Warden | Fixed legs and idle wall-clock bob. Distance-driven legs now stop with it; the painted baton winds back, strikes and recovers. |
| Lamplighter | Fixed tripod slid, with stale friendly facing. Three phased feet keep two supports planted, and travel sets the friendly view. |
| Salvager | Hover was appropriate, but its claw never reached or gripped. The claw now extends from the hull and carries the stolen crate; fleeing sets its visual direction. |
| Sterilizer | Hover was appropriate. Its separate painted nozzles now deploy and retract with the attack. |
| Custodian | Wheeled movement remains; attack suspension now compresses. Brush rotation is still deferred. |
| Warden-Prime | Static charge legs and fixed lamp. It now steps through the charge, turns its body for charge/beam and aims the lamp head along the beam. |
| Crane | Warning and rest transitions teleported the load. Warning prepares the swing start, and rest/stall lower the load continuously. |
| Conductor | Housing snapped 60 pixels at vulnerability. It now travels into and out of the opening. |
| Surgeon | Hub snapped 40 pixels and rotating arms reset instantly. Both now ease into their next pose. |
| Lung | Breathing jumped on pause/resume. Its phase now advances with scene time. |
| Editor | Rollers snapped 16 pixels into the opening. They now travel between poses. |
| Noor, Teo, survivors, Waiting | Arrival/departure tweens translated fixed sprites. Painted legs now follow actual travel, stop on arrival and carry their attached lights/items. |

`StrideCycle` is the shared contact clock. `PaintedParts` supplies the same transform for a painted
segment and its attachments. Separate biped, tripod and hover renderers stay small. Enemy walking
uses actual post-collision travel; stun and knockback cannot advance it. Combat deadlines, damage,
collision and progression rules retain their existing behavior. Settled Wardfolk, seated/downed
Noor, existing hover motion and existing machine prop motion remain appropriate to those states.
Death effects retain the existing fade; this pass does not add articulated collapses.

The native actor stage uses real AI and boss phase clocks. Its neutral inspection lighting survives
voice changes, while voice behavior still drives hostile/friendly transitions. Enemy previews must
observe a windup. Boss previews must engage, observe every required attack phase, return to the
cycle's start and exercise the real manual vulnerability action. Failure exits nonzero.

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

4. **P2, Warden baton rotated away from the target.** The Clerk and Warden need opposite strokes.
   The Warden now uses its own rotation sign. A regression maps the actual painted weapon anchor
   through the production transform and checks its forward travel for both views and mirrors.
5. **P2, actor coverage still required old static bodies.** The manifest now lists the current
   dynamic rig parts, hover hulls/appendages and mast head. A new test requires each joint, boot sole
   and attachment anchor, so removing a runtime dependency fails before drawing.

## Validation

Expanded actor pass:

- `actors-gate-summary.log` and `actors-gate/`: complete gate PASS with 555 tests, smoke gameplay,
  the 310-check campaign, all endings, revisit, tool door and all eight district tours.
- `actors-final-tests.log`: all 557 tests PASS after the drawing-only Warden stroke fix and the
  added endpoint/required-anchor regressions. A later drawing-only correction hides Teo's tablet
  glow in rear view; all 14 Ark tests and a fresh native companion recording pass afterward.
- `enemies-final.log` and `enemies.mp4`: native 73.3-second recording PASS, all six enemy families,
  approach/turns, windup/release, stun, recovery and death. Every family entered its attack windup.
- `bosses-final.log` and `bosses.mp4`: native 125.6-second recording PASS, all six bosses. Required
  phases, cycle return and manual openings are observed. `prime-final.log` and `warden-prime.mp4`
  add a 16.3-second Warden-Prime cycle with foreground buildings hidden for inspection, including
  volley, charge, collision/daze and manual opening. Collision remains active.
- `people-final-v2.log` and `companions.mp4`: native 26.8-second recording PASS, real arrival routes,
  turns/stops and Waiting departure. The final Teo rear view correctly hides the tablet glow.
- `actors-export.log` and `actors-pack-harbor.log`: final Linux pack export and native Harbor tour
  PASS at 1920×1080 on Intel Iris Xe, Forward+, vsync disabled with a 60 fps cap. The tour measured
  60 fps average and 55 fps 1% low while a separate video encode was running. No recording ran in
  the game process. This is a packaging/render check, not a Steam Deck performance result.

Earlier Operator and terrain pass:

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
- Current catalog regeneration produces 251 frames from 30 sheets plus Kestrel originals.
  `git diff --check` passes.

Evidence lives in the ignored `reports/movement-terrain/` directory. Every run uses a scratch
`XDG_DATA_HOME`; both preview stages also select their own save and settings paths. Steam Deck,
Windows and macOS checks listed in `PROGRESS.md` remain pending.
