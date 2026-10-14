# Complete painted art

The read-only `sol_analyst` agent reviewed the complete implementation on 2026-10-14. It found
three issues. The primary Codex agent applied the fixes and verified them below. Two attempts to
obtain a Sol closure review failed because the selected model was at capacity; this document does
not claim independent approval of the fixes.

## Coverage

The game now uses 162 named painted frames across all eight districts and the Ark. The full
inventory is `assets/art/complete/coverage.json`: all 30 physical terrain kinds, 23 static scenery
kinds, 18 facades, the Operator's movement/carrying/downed states, civilians, six enemy families,
six bosses and their moving machinery, doors, fixtures, pickups, tools, item illustrations,
backgrounds, title and navigation map. The built-in image_gen tool produced 24 new sheets guided
by the approved local concepts. Prompts, original PNGs, reference roles, refinements, crop metadata
and import recipes remain in `assets/art/`.

The canonical ring, path, lighting, shadows, weather, water level, attack warnings, particles,
confession text and interface controls remain responsive code. Painted coverage is complete;
actor animation uses a limited set of painted poses with mirroring, bobbing and transforms.

## Review findings and fixes

1. **P1: the assembled preview wrote into the normal player save.** `art_stage._ready` now selects
   `user://art_preview_saves` and `user://art_preview_settings.cfg` before preparing any synthetic
   run or opening any Level. A complete native preview left both normal save files byte-for-byte
   unchanged, and created no normal settings file. The initial preview had already overwritten the
   normal save and rotating backup with synthetic data. No earlier copy was found in game data or
   task temporary directories. The affected files are preserved in the ignored
   `reports/art-complete/save-incident/` folder. The prevention is fixed; earlier data was not restored.
2. **P2: panorama drift wrapped abruptly.** `SkyBackdrop` clamps its drift inside the overscan.
   A regression checks continuity across both signs of the previous wrap boundaries and verifies
   that the painting cannot drift outside the overscan.
3. **P2: dead screens lost their ring afterimages.** Kiosks, office desks and newsroom desks now draw
   the canonical faint grey ring in their painted screen planes using reviewed source anchors.
   The enlarged native screenshot `final/gallery/screen_afterimages.png` confirms the projections.

The preview also frees its final Level and uses the game's sound shutdown before exiting. Its
final log contains no warnings or resource leaks. Equipped tools stow while Noor is carried;
front/rear carrying and carrying through a dodge were captured in the actual Harbor level.

## Validation

- The updated suite passes all 523 tests. Frame bounds, anchors, actual alpha, mipmaps and every
  enum/owner binding are checked, alongside gameplay tests.
- The complete gate passes import, tests, smoke gameplay, the 310-check campaign, all three
  endings, revisit, the tool door and all eight district tours.
- All eight native district tours passed. Native galleries show all 162 frames; assembled native
  captures cover district starts/muted views, boss openings, carrying/downed poses, Ark residents
  and the navigation map.
- The Linux export pack loads and passes a 40-second Mercy General tour. The runtime catalog is
  explicitly included in every export preset.
- Movie Maker recorded about 40 seconds of native gameplay in `final/painted-gameplay.mp4`.
- `git diff --check` passes.

Two default parallel empty-cache imports crashed while saving the existing Fraunces italic font.
Retry imports passed. Font-only reproductions and a clean unchanged-HEAD import passed, so those
checks do not establish a baseline cause. A full fresh copy with serial imports passed, then a
second fresh copy with the committed `editor/import/use_multiple_threads=false` setting passed
without errors or warnings. The setting is an editor import workaround; gameplay is unaffected.

Retired boss fittings now clear their collision layer and mask, resolving the independently
reproduced Harbor relay obstruction. Headless screenshots return without awaiting a render frame.
Both have regressions. The full campaign reaches its ending after those fixes.

Evidence is in the ignored `reports/art-complete/` directory. Rendered checks are in `final/`;
the 523-test full gate and export check after rebasing onto main's narration commits are in `pr/`.
Headless scenarios use fixed 60-fps simulation; rendered captures and the recording use the native
Vulkan renderer. Hardware checks listed in `PROGRESS.md` remain pending.
