# Milestone review: vertical slice

Reviewer: **sol_analyst** (Sol 6.1, xhigh, read-only) via the "Sol analysis" skill, run through
`codex exec -s read-only`. Scope: `git diff 911fb9c..499648a` (steps 0–8). Author of the code under
review: Claude Code (Claude Opus 5.5).

- Round 1: findings below (verbatim), then what was done about each.
- Round 2: the re-review after the fixes (at the end of this file).

## Round 1 findings (verbatim from sol_analyst)

I would not call the milestone done yet. The acceptance flows are implemented, but there are save-loss risks, input and combat bugs, violations of the path and hardware-coverage rules, and several assumptions that will break when a second district is added.

Reviewed `911fb9c..499648ad780504dcd0c80cf6f2fc83f984388478`, the design brief, world bible, decisions, production code, tests, and existing gate logs. The logs substantiate 164 passing tests, 19 passing smoke checks, and 43 passing full-slice checks without reported errors or warnings. I did not rerun the gate because its autopilot writes to the normal player save slot. Read-only numerical checks confirmed the aim, path, and projectile geometry findings below. No files were edited.

“Confirmed” means the implementation and failure path are verified in the code; it does not mean every filesystem fault or future-content scenario was exercised in Godot.

The following findings are confirmed.

1. **High · bug — The gate and recordings overwrite the player’s save.**  
   [autoload/autopilot.gd:21](/home/homebox/Documents/rookmate/undertow/autoload/autopilot.gd:21), [autoload/save_service.gd:7](/home/homebox/Documents/rookmate/undertow/autoload/save_service.gd:7), [tools/check.sh:51](/home/homebox/Documents/rookmate/undertow/tools/check.sh:51), [tools/record.sh:18](/home/homebox/Documents/rookmate/undertow/tools/record.sh:18)

   Autopilot starts New Game without redirecting `SaveService`. Level entry, core choice, and Ark entry therefore save into `user://saves/slot_1.json`. Only the unit/integration runner selects scratch saves.

   **Failure:** A developer with an existing run executes `tools/check.sh` or records a progress video. Autopilot replaces that run, and subsequent saves also replace its backup.

   **Fix:** Select an isolated save directory before any autopilot scene runs. Give each automated run its own directory and make save isolation an explicit check.

2. **High · bug — Mouse aim uses the feet while projectiles are drawn at chest height.**  
   [game/player/operator.gd:168](/home/homebox/Documents/rookmate/undertow/game/player/operator.gd:168), [game/weapons/projectile.gd:8](/home/homebox/Documents/rookmate/undertow/game/weapons/projectile.gd:8)

   Mouse aim converts the vector from the Operator’s ground position to the cursor. Projectiles follow that ground vector but are drawn 64 pixels above it.

   **Failure:** Put a Custodian three ground tiles along the positive grid-x direction and point at its chest. The calculated direction is approximately 22.8° away from the actual target direction, outside the aim-assist half-cone. The ray misses its ground position by approximately 1.16 tiles, exceeding the combined 0.56-tile projectile/Custodian radius. Manual mouse combat therefore misses targets the cursor visibly points at.

   **Fix:** Define a consistent mouse aiming plane and account for the projectile/body height, or resolve cursor targets to their ground positions. Add a mouse-driven combat test; current weapon tests select pad mode and explicitly update facing.

3. **High · bug — Closing Pause can unpause an open Archive or ending panel.**  
   [ui/pause/pause_menu.gd:41](/home/homebox/Documents/rookmate/undertow/ui/pause/pause_menu.gd:41), [ui/pause/pause_menu.gd:59](/home/homebox/Documents/rookmate/undertow/ui/pause/pause_menu.gd:59), [game/ark/ark_level.gd:96](/home/homebox/Documents/rookmate/undertow/game/ark/ark_level.gd:96)

   Pause opens regardless of whether another screen already owns the paused state. Its `close()` always sets `SceneTree.paused = false`.

   **Failure:** Open the Archive, press controller Start, then Resume. The Archive remains open while the Ark resumes behind it. Movement, dodging, voice changes, and play-time tracking can run beneath the modal. The ending panel has the same ownership conflict. Focus also remains on the now-hidden Pause control.

   **Fix:** Centralize modal/pause ownership, or restore the previous pause state and previous focus when Pause closes. Test Start → Resume while the Archive is open and while replaying.

4. **High · bug — Scene transitions reject navigation after callers have already changed the run.**  
   [autoload/scene_router.gd:40](/home/homebox/Documents/rookmate/undertow/autoload/scene_router.gd:40), [autoload/scene_router.gd:63](/home/homebox/Documents/rookmate/undertow/autoload/scene_router.gd:63), [ui/title/title.gd:86](/home/homebox/Documents/rookmate/undertow/ui/title/title.gd:86), [ui/title/title.gd:100](/home/homebox/Documents/rookmate/undertow/ui/title/title.gd:100)

   The fade ignores mouse input and leaves controls active. `_busy` drops subsequent `goto()` calls, but New Game and Continue mutate `GameState` before calling it.

   **Failure:** With an Ark save available, click New Game and then Continue during the 250 ms fade. Continue replaces the run with the completed Ark run, while its navigation is discarded. The pending transition still opens Loadout. Departing can replay Vellum with already-owned cores filtered out, leaving fewer than two selectable cores. The inverse sequence can send a fresh run directly into the Ark.

   **Fix:** Disable all scene input during transitions, including focused controller/keyboard controls. Accept navigation and its associated state change as one operation; rejected transitions must not mutate the run.

5. **High · bug — Save writes are published without checking whether the contents were written successfully.**  
   [core/save_store.gd:47](/home/homebox/Documents/rookmate/undertow/core/save_store.gd:47)

   `store_string()` is followed by `close()`, then backup rotation and rename. No write/flush error is checked.

   **Failure:** Disk space runs out after opening the temporary file. A truncated file can still be renamed into the main slot and reported as a successful save. A later autosave rotates that corrupt main file over the last good backup, potentially losing both recoverable copies.

   **Fix:** Flush and inspect the file error before closing and rotating anything. Publish only a successfully written temporary file, retain the last known-good backup on failure, and test write failures through an injectable filesystem boundary.

6. **High · bug — Gameplay ignores save failures and still reports completion or leaves the run.**  
   [ui/pause/pause_menu.gd:65](/home/homebox/Documents/rookmate/undertow/ui/pause/pause_menu.gd:65), [ui/core_choice/core_choice.gd:172](/home/homebox/Documents/rookmate/undertow/ui/core_choice/core_choice.gd:172), [ui/ark/end_of_slice.gd:96](/home/homebox/Documents/rookmate/undertow/ui/ark/end_of_slice.gd:96), [autoload/game_state.gd:14](/home/homebox/Documents/rookmate/undertow/autoload/game_state.gd:14)

   Save errors reach a console print, but callers discard the returned `Error`.

   **Failure:** The save directory becomes unwritable. Save and Quit returns to Title anyway; core choice appears committed; closing the window exits. On the next launch, the old save returns and progress is lost without an in-game explanation.

   **Fix:** Handle failed saves in the relevant UI, preserve the in-memory run, and provide retry/recovery. Save and Quit must not discard the current run after a failed write.

7. **High · brief-violation — Steward perception and assists are global rather than limited by hardware coverage.**  
   [autoload/steward.gd:38](/home/homebox/Documents/rookmate/undertow/autoload/steward.gd:38), [autoload/narrator.gd:49](/home/homebox/Documents/rookmate/undertow/autoload/narrator.gd:49), [ui/hud/minimap.gd:33](/home/homebox/Documents/rookmate/undertow/ui/hud/minimap.gd:33)

   Assists depend on voice, power cores, and overrides, with no level or coverage input. Only the predicted path applies a local coverage check. Narration, aim assist, threat warnings, slow-motion eligibility, and the Steward map remain available beyond the Lattice.

   **Failure:** Walk into the unindexed stacks with voice on. The path disappears, but the Steward can still assist, narrate observed behavior, and locate the Operator on its map. The same implementation would give Harbor Ward Steward functions that the world bible explicitly forbids.

   **Fix:** Model hardware coverage separately from the voice preference and apply it consistently to perception, map, narration, and assists. Preserve the Ark’s explicit advisory exception. The governing rule is `undertow-world-bible.md:11`; Harbor Ward makes the expected behavior explicit at line 125.

8. **High · maintainability — Level departure and saved-location routing are fixed to Vellum.**  
   [ui/loadout/loadout.gd:171](/home/homebox/Documents/rookmate/undertow/ui/loadout/loadout.gd:171), [autoload/scene_router.gd:18](/home/homebox/Documents/rookmate/undertow/autoload/scene_router.gd:18), [core/core_choice.gd:8](/home/homebox/Documents/rookmate/undertow/core/core_choice.gd:8)

   Loadout always departs to `level_vellum`. Resume routing contains explicit Vellum strings, and district-to-building progression is another separately maintained lookup.

   **Failure:** Add Tideworks and route it through the shared Loadout screen. Depart opens Vellum and overwrites the saved location. A Tideworks save cannot resume until another bespoke router entry is added.

   **Fix:** Introduce a level definition/catalog carrying scene, map, destination, Reliquary, building, and related district data. Pass the intended destination through Loadout and derive resume routing from the saved level ID.

9. **High · maintainability — Map markers reuse global Vellum entity IDs.**  
   [game/level/level.gd:277](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:277), [ui/hud/minimap.gd:70](/home/homebox/Documents/rookmate/undertow/ui/hud/minimap.gd:70), [data/narration/steward_lines.json:22](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:22)

   Every `W`, `w`, `T`, and `U` receives the same corresponding Vellum ID. The minimap similarly assumes one Vellum truth cache. Generic level-entry narration selects Vellum-specific lines.

   **Failure:** Add a second doorway survivor to a map. Both share an ID, so rescuing one suppresses the other on reload and cannot increase the survivor count twice. Reusing the markers in another district makes its cache or survivor appear already collected. Entering that district announces “The Vellum.”

   **Fix:** Give each placed entity a stable, unique ID through level-specific placement metadata. Scope narration by level/context and draw discovery markers from actual placed entities rather than `first("T")` plus a constant.

10. **Medium · brief-violation — The rendered path can include the current cell and more than three tiles.**  
    [core/path_predictor.gd:61](/home/homebox/Documents/rookmate/undertow/core/path_predictor.gd:61), [game/path/predicted_path.gd:41](/home/homebox/Documents/rookmate/undertow/game/path/predicted_path.gd:41), [game/path/predicted_path.gd:65](/home/homebox/Documents/rookmate/undertow/game/path/predicted_path.gd:65)

    Prediction includes the current route cell unless its center is less than 0.6 tiles away. A position 0.05 tiles from a cell corner is approximately 0.636 tiles from its center, so the cell beneath the Operator is included. Rendering also retains expired predictions until their alpha fades to zero.

    **Failure:** Near a tile corner, a path tile lies under the feet. During a normal one-cell advance at 60 FPS, the old tile still has alpha 0.9 while the new fourth tile has alpha 0.1: four tiles are painted. Replanning can retain even more; muting leaves fading gold tiles temporarily visible.

    **Fix:** Exclude the current cell explicitly and constrain the painted set to the three valid forward cells. Test actual rendered membership, corner positions, movement transitions, and mute transitions. Existing tests inspect `shown`, not the retained painted tiles.

11. **Medium · bug — Navigation coverage disagrees with physical walkability around small props.**  
    [game/level/level.gd:224](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:224), [core/level_grid.gd:19](/home/homebox/Documents/rookmate/undertow/core/level_grid.gd:19), [core/path_predictor.gd:47](/home/homebox/Documents/rookmate/undertow/core/path_predictor.gd:47)

    Lamps and bollards have 32% collision footprints, but navigation treats their whole cells as solid. `covers()` additionally equates hardware coverage with navigation openness.

    **Failure:** Walk through the physically open corner of a lamp cell. The Operator is still on lit pavement, yet prediction returns no path because that entire cell is closed in the navigation grid. Similar mismatches occur around occupied cells.

    **Fix:** Separate Lattice coverage from route occupancy. Make navigation’s handling of partial obstacles consistent with playable movement, including how a route starts from an otherwise blocked coarse cell.

12. **Medium · bug — Muting does not cancel active Steward slow motion.**  
    [game/level/slow_mo.gd:16](/home/homebox/Documents/rookmate/undertow/game/level/slow_mo.gd:16), [game/level/slow_mo.gd:49](/home/homebox/Documents/rookmate/undertow/game/level/slow_mo.gd:49)

    Eligibility is checked when slow motion starts. The component does not subscribe to voice changes.

    **Failure:** Trigger a perfect dodge, then mute immediately. The UI and damage rules switch to the unassisted state, but `Engine.time_scale` remains slowed for the remaining assist duration.

    **Fix:** Cancel active slow motion and restore normal time when the assist becomes unavailable. Add a toggle-during-slow-motion test.

13. **Medium · bug — Target selection and close-range damage ignore intervening walls.**  
    [game/weapons/weapon.gd:77](/home/homebox/Documents/rookmate/undertow/game/weapons/weapon.gd:77), [game/weapons/traffic_baton.gd:75](/home/homebox/Documents/rookmate/undertow/game/weapons/traffic_baton.gd:75), [game/weapons/defib_gauntlet.gd:66](/home/homebox/Documents/rookmate/undertow/game/weapons/defib_gauntlet.gd:66)

    Targets are filtered by distance and arc only. Tuned targeting has no visibility check.

    **Failure:** A Custodian stands across a kiosk or wall within reach. Baton and Gauntlet damage it through the obstacle. Alternatively, the tuned Drone selects a nearer enemy behind a tram and repeatedly fires into the tram instead of selecting a reachable enemy.

    **Fix:** Define obstruction rules for each weapon and apply a shared visibility query to target acquisition and hit resolution. Test blocked and unobstructed targets together.

14. **Medium · bug — Projectiles check endpoints instead of the swept movement segment.**  
    [game/weapons/projectile.gd:32](/home/homebox/Documents/rookmate/undertow/game/weapons/projectile.gd:32)

    Each physics tick moves the projectile, then tests only its new cell and its new distance from targets.

    **Failure:** A Drone pellet travels 0.25 tiles per tick at 60 FPS. For a Custodian with combined hit radius 0.56, endpoints at x = −0.125 and +0.125, y = 0.55 are both outside the hit circle, although the segment passes through it. The shot misses. A segment can also cross a short corner of a blocking cell while both endpoints are in open cells.

    **Fix:** Sweep the segment against target circles and blocking geometry, resolving intersections in travel order. Test grazing hits, wall corners, and different tick rates.

15. **Medium · bug — Player knockback bypasses world collision.**  
    [game/player/operator.gd:193](/home/homebox/Documents/rookmate/undertow/game/player/operator.gd:193)

    An enemy hit adds directly to `position`; it does not move through the physics body.

    **Failure:** Take a hit while backed against a railing, kiosk, or wall. The unconditional quarter-tile displacement can place the Operator’s collision shape inside the obstacle, leaving the next physics frame to resolve an invalid overlap.

    **Fix:** Apply knockback through collision-aware movement, preferably as a velocity component processed alongside normal motion. Test hits against obstacles and map boundaries.

16. **Medium · crash-risk — Writer-editable content lacks schema and reference validation.**  
    [core/content_db.gd:16](/home/homebox/Documents/rookmate/undertow/core/content_db.gd:16), [core/archive_model.gd:58](/home/homebox/Documents/rookmate/undertow/core/archive_model.gd:58), [ui/archive/archive_screen.gd:180](/home/homebox/Documents/rookmate/undertow/ui/archive/archive_screen.gd:180)

    Loading validates only that the top-level JSON value is a dictionary. Nested values are assigned to typed dictionaries without checks, references are unchecked, and `_loaded` is set before loading succeeds. Parse errors are accumulated without a production diagnostic.

    **Failure:** A writer sets `"cores": []` or a log’s `"noor"` reaction to a string: valid JSON produces a GDScript type/method error. A mistyped Reliquary key yields fewer than two cards and an unusable choice screen. An unknown offered core is treated as power and can be counted without valid content.

    **Fix:** Validate the complete schema, kinds, unique IDs, foreign keys, reactions, and minimum valid offer size before gameplay. Return a clear failure, log it, and mark the database loaded only after successful validation.

17. **Medium · maintainability — Text maps accept unknown walkable void and missing required markers.**  
    [core/level_grid.gd:34](/home/homebox/Documents/rookmate/undertow/core/level_grid.gd:34), [core/level_grid.gd:62](/home/homebox/Documents/rookmate/undertow/core/level_grid.gd:62), [core/level_grid.gd:70](/home/homebox/Documents/rookmate/undertow/core/level_grid.gd:70), [game/level/level.gd:37](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:37)

    Unknown characters map to `Floor.VOID` but are walkable unless present in the `SOLID` string. Empty/missing maps and missing starts are not rejected before level construction and saving.

    **Failure:** A new map contains an accidental `x`: it creates invisible walkable floor and navigation space. Remove `P`, or ship without the map file, and the player starts from the sentinel `(-1, -1)` while level initialization continues and saves the location.

    **Fix:** Validate allowed characters, required/unique markers, dimensions, and essential reachability. Unknown cells should fail closed. Abort initialization before updating or saving progress when validation fails.

18. **Medium · maintainability — Ark restoration is painted into the map rather than derived from progression.**  
    [game/level/level.gd:164](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:164), [game/ark/ark_level.gd:32](/home/homebox/Documents/rookmate/undertow/game/ark/ark_level.gd:32)

    `A` always builds the Archive facade, and `a` always installs a usable Archive entrance. Neither consults `buildings_restored`.

    **Failure:** A later build permits visiting the Ark before finishing Vellum, or finishing another district first. The Archive is already built and accessible despite its restoration flag being absent.

    **Fix:** Construct each Ark plot and its interaction from the run’s restoration state, using district/building definitions. Test the Ark before and after restoring individual buildings.

19. **Medium · maintainability — The Ark silently stops displaying survivors after three.**  
    [game/ark/ark_level.gd:30](/home/homebox/Documents/rookmate/undertow/game/ark/ark_level.gd:30), [data/levels/ark.txt:24](/home/homebox/Documents/rookmate/undertow/data/levels/ark.txt:24)

    Survivor population is capped by the three `s` markers through `mini(spots.size(), survivors.size())`.

    **Failure:** Rescue a fourth survivor in a later district. The tracked count increases, but that survivor never appears or becomes available to talk to at the Ark.

    **Fix:** Provide a population layout that accommodates all rescued survivors, or an explicit capacity/overflow representation that retains access to everyone. Test above the current marker count.

20. **Medium · maintainability — The Archive’s growing list has no scrolling or viewport bounds.**  
    [ui/archive/archive_screen.gd:43](/home/homebox/Documents/rookmate/undertow/ui/archive/archive_screen.gd:43), [ui/archive/archive_screen.gd:115](/home/homebox/Documents/rookmate/undertow/ui/archive/archive_screen.gd:115)

    Every known log becomes a 54-pixel row with 8-pixel separation in an unbounded `VBoxContainer` starting at y = 190.

    **Failure:** Twenty logs extend the list to approximately y = 1430 in the 1080-pixel base view. Later rows overlap controls or sit offscreen, and controller focus can move to invisible entries. Longer records can also expand the fixed-position record panel into subsequent controls.

    **Fix:** Bound and scroll the log list and record area. Ensure keyboard/controller focus scrolls the selected entry into view. Test realistic multi-district content volumes and longer records.

21. **Medium · brief-violation — World props draw substitute Steward rings instead of the canonical geometry.**  
    [game/props/reliquary.gd:49](/home/homebox/Documents/rookmate/undertow/game/props/reliquary.gd:49), [game/level/static_prop.gd:80](/home/homebox/Documents/rookmate/undertow/game/level/static_prop.gd:80)

    The Reliquary draws an arc and center dot; the kiosk draws a simple arc. They omit the canonical filigree, curled ends, outer ticks, inner ring, and four-petal inlay required for every in-game Steward ring by `undertow-design-brief.md:143`.

    **Failure:** Approaching the Reliquary or a dead Feed screen shows a different emblem from the title/HUD ring. Adding more props encourages further independent approximations.

    **Fix:** Reuse the canonical ring painter through the appropriate scale/projection transform, with the correct lit or scorch state, instead of copying selected geometry into each prop.

22. **Low · bug — Safe Ark dodging changes the adaptive combat profile.**  
    [game/level/steward_watch.gd:25](/home/homebox/Documents/rookmate/undertow/game/level/steward_watch.gd:25), [game/level/steward_watch.gd:89](/home/homebox/Documents/rookmate/undertow/game/level/steward_watch.gd:89)

    The Ark inherits the watcher’s dodge subscription. Its hub guard only excludes Lattice-transition observations; every Ark dodge still records caution.

    **Failure:** Roll around the safe hub twenty times. This adds ten caution points without any combat decision and biases narration in the next district. Repeated hub visits increasingly contaminate the intended risk/caution model.

    **Fix:** Exclude hub locomotion from combat profiling, or distinguish traversal dodges from threat-related dodges and weight only the intended behaviors.

23. **Low · bug — Narration history and cooldowns leak between runs.**  
    [autoload/narrator.gd:39](/home/homebox/Documents/rookmate/undertow/autoload/narrator.gd:39), [autoload/game_state.gd:17](/home/homebox/Documents/rookmate/undertow/autoload/game_state.gd:17)

    `reset_session()` clears recent lines, cooldowns, and tone counts, but production never calls it when creating or replacing a run. Tests explicitly reset it.

    **Failure:** Return to Title and immediately start another run. Events can remain suppressed by the previous run’s cooldown/gap, line choices avoid the previous run’s history, and debug tone counts belong to both runs rather than the new profile.

    **Fix:** Define narration lifecycle explicitly and reset run-local narration state on `run_replaced`. Preserve history across district transitions within the same run.

24. **Low · brief-violation — Muted Continue still displays live Steward dialogue in Loadout.**  
    [ui/loadout/loadout.gd:72](/home/homebox/Documents/rookmate/undertow/ui/loadout/loadout.gd:72)

    The Steward’s Fraunces/gold line is always created, regardless of saved voice state.

    **Failure:** Save Vellum while muted, then Continue. Loadout displays Steward dialogue although narration is supposed to be switched off. Other screens, including core choice and Archive aftermath, already gate present Steward commentary.

    **Fix:** Gate the line using the narration/voice state, or clearly present it as a historical quotation if that is the intended meaning.

25. **Medium · test-gap — Full autopilot can pass without completing the full slice.**  
    [autoload/autopilot.gd:66](/home/homebox/Documents/rookmate/undertow/autoload/autopilot.gd:66), [autoload/autopilot.gd:315](/home/homebox/Documents/rookmate/undertow/autoload/autopilot.gd:315), [autoload/autopilot.gd:341](/home/homebox/Documents/rookmate/undertow/autoload/autopilot.gd:341), [tools/check.sh:67](/home/homebox/Documents/rookmate/undertow/tools/check.sh:67)

    Required checks are registered progressively as scenes and phases are reached. `_finish()` passes if all checks registered so far passed; the gate accepts any `AUTOPILOT PASS` line.

    **Failure:** A slower or regressed run reaches core choice shortly before the time limit and passes the card check, but finishes before registering Ark/Archive/ending requirements. It can print PASS despite never exercising those features. An unknown scenario can similarly finish with only title checks.

    **Fix:** Register the complete required checklist at scenario startup, reject unknown scenarios, and require the expected terminal phase. The current 43-check log did complete the intended route; the problem is that future incomplete runs can also be accepted.

26. **Low · test-gap — The test runner treats running zero tests as success.**  
    [tests/test_runner.gd:62](/home/homebox/Documents/rookmate/undertow/tests/test_runner.gd:62), [tests/test_runner.gd:78](/home/homebox/Documents/rookmate/undertow/tests/test_runner.gd:78), [tools/check.sh:43](/home/homebox/Documents/rookmate/undertow/tools/check.sh:43)

    Missing test directories return an empty list, and an unmatched filter also produces zero tests. `failed_tests == 0` still prints `RESULT: PASS 0 tests`, which satisfies the gate’s result check.

    **Failure:** A directory is renamed or omitted from a packaged validation environment. The unit/integration stage goes green without executing its suite.

    **Fix:** Fail on missing expected directories and zero executed tests. Treat an unmatched explicit filter as a diagnostic failure.

The following are inferences or unverified risks, separate from the confirmed findings.

27. **Medium · bug, inference — Controller bindings may only match joypad device 0.**  
    [autoload/controls.gd:80](/home/homebox/Documents/rookmate/undertow/autoload/controls.gd:80), [autoload/controls.gd:85](/home/homebox/Documents/rookmate/undertow/autoload/controls.gd:85), [tests/unit/test_controls.gd:5](/home/homebox/Documents/rookmate/undertow/tests/unit/test_controls.gd:5)

    Constructed joypad events never set their device to the all-devices value. I did not verify Godot 4.7.2 dispatch behavior with multiple physical device IDs. Existing tests check binding types, while autopilot sends semantic actions.

    **Possible failure:** A second controller, external Deck controller, or reconnected controller receives a nonzero device ID and fails to trigger gameplay actions while default UI navigation still works.

    **Suggested fix/verification:** Explicitly support all devices or track the active controller consistently. Dispatch button and axis events for device IDs 0 and 1, then test hotplug/reconnection on hardware.

28. **Medium · test-gap, inference — Exported builds may omit required text/JSON data.**  
    [core/content_db.gd:6](/home/homebox/Documents/rookmate/undertow/core/content_db.gd:6), [game/level/vellum_street.tscn:8](/home/homebox/Documents/rookmate/undertow/game/level/vellum_street.tscn:8), [DECISIONS.md:85](/home/homebox/Documents/rookmate/undertow/DECISIONS.md:85)

    There are no export presets. Maps and content are read through `FileAccess`, and decision 34 explicitly leaves their export filters pending.

    **Possible failure:** A resource-only export launches with missing maps, narration, or core/log data despite passing all source-tree runs.

    **Suggested fix/verification:** Create an export preset with the required non-resource data filters and smoke-test the exported executable. This is an acknowledged packaging gap, not evidence that a tested export is broken.

29. **Medium · test-gap, inference — The platform, controller, and Deck performance targets remain unsubstantiated.**  
    [project.godot:71](/home/homebox/Documents/rookmate/undertow/project.godot:71), [project.godot:93](/home/homebox/Documents/rookmate/undertow/project.godot:93), [tools/check.sh:49](/home/homebox/Documents/rookmate/undertow/tools/check.sh:49), [undertow-design-brief.md:211](/home/homebox/Documents/rookmate/undertow/undertow-design-brief.md:211)

    A Linux desktop run capped at 60 FPS does not establish 60 FPS at 1080p on Deck, real controller usability, or Windows/macOS compatibility. Forward+ and HDR are accepted choices, but their cost on the target hardware has not been measured.

    **Possible failure:** The slice functions on the development host yet misses the Deck frame budget, exhibits controller focus/input issues, or fails in a platform export.

    **Suggested fix/verification:** Run the exported slice on Deck with a real controller, measure frame times at the stated target, and perform Windows/macOS launch, save/resume, and full-route smoke tests.

The Steam wrapper, tracked-state serialization/debug coverage, and Rewrite threshold logic match the accepted milestone decisions. Text-only narration, deferred GodotSteam installation, and Rewrite remaining locked in this slice are intentional scope decisions, not findings.
## Round 1: what was done about each finding

All 29 were acted on. 28 are fixed in code with a test or an automated check; 29 is measured here and
needs the target hardware to close (see below). Gate after the fixes: import clean, **207 tests**
passing (was 164), 30 s run 20/20 checks, 150 s full-slice run 45/45 checks, no errors or warnings;
`tools/export.sh` exports Linux, Windows and macOS and the exported Linux build passes the 30 s run.

| # | Resolution | Covered by |
|---|---|---|
| 1 | The autopilot always uses its own save folder (`user://autopilot/<scenario>`), emptied before each run, and checks that it isn't the player's (`save_isolated`). The gate and recordings can no longer touch the real save. | autopilot check `save_isolated` |
| 2 | Mouse aim goes from the chest-height muzzle to the cursor raised by the same chest height (`Operator.cursor_aim`), so shots go where the cursor points. | `test_combat_geometry::test_mouse_aim_points_where_the_cursor_points` |
| 3 | `Modals` stack owns the pause: screens push and pop themselves; the game unpauses only when the last one closes, and only the top one takes input. Pause, Archive, end panel and save warning use it. | `test_modals_and_routing` (2 tests) |
| 4 | `SceneRouter.goto(key, prepare)` runs the state change only once the navigation is accepted, so a refused navigation changes nothing; GUI input is off during fades and modals are cleared on scene change. Title, loadout, core choice and Continue all go through it. | `test_a_refused_navigation_does_not_change_the_run` |
| 5 | `SaveStore.save` writes a temp file, checks the write error and reads it back to compare; it rotates the main save to `.bak` only if the main save is itself valid, and restores it if the final rename fails. | `test_save_store` (short write, failed write, corrupt main not rotated over the backup) |
| 6 | `SaveFlow`: checkpoints report a failure with a notice and play goes on; leaving the run (title, close window, dock) asks TRY AGAIN / LEAVE WITHOUT SAVING / STAY. Nothing is discarded silently. | `test_save_flow` (4 tests), `test_closing_the_window_saves_then_quits` |
| 7 | Coverage: the Steward is present only on/near Lattice cells (0.6 s grace). Off the Lattice, the voice being on buys nothing (no path, warnings, slow-mo, aim assist, narration, forced manual, ×1.4 damage), the map says SIGNAL LOST and can't place you, the pill reads NO SIGNAL with a glitching ring, and play isn't profiled. The Ark is the advisory exception. | `test_coverage` (6 tests), autopilot `steward_blind_in_stacks` |
| 8 | `LevelCatalog` holds every level's scene, name and the Ark building it restores; the loadout departs to the saved level, Continue routes any saved location through `SceneRouter.destination_for`. | `test_tracked_state` routing tests, `test_core_choice` restore test |
| 9 | Placed things get ids from the map file (`@ x,y id`), validated unique and pointing at real content; narration lines can be scoped to a level and every event keeps a neutral line for anywhere; the hand-scan map marks what you found from the level's own caches. | `test_level_grid` ids, `test_line_selector` level scoping |
| 10 | The painted path is at most three tiles and never the cell underfoot, including while tiles fade. | `test_predicted_path` (painted ≤ 3, corner of a cell, muting removes tiles at once) |
| 11 | The predictor starts from the nearest open Lattice cell when the Operator stands in a lamp cell's open corner. | `test_standing_in_a_lamp_cells_open_corner_keeps_the_path` |
| 12 | Muting or losing the signal cancels slow motion at once (timing in unscaled time). | `test_muting_cancels_slowed_time`, `test_losing_the_signal_cancels_slowed_time` |
| 13 | Weapons choose and hit only targets in line of sight; Custodian strikes need line of sight too. | `test_combat_rules` (baton through the kiosk, drone target choice) |
| 14 | Projectiles sweep their whole movement segment and hit in travel order; walls stop them. | `test_combat_geometry` (grazing shot, hit order), `test_a_fast_pellet_stops_at_the_kiosk_corner` |
| 15 | Knockback is a velocity resolved through physics, so it never pushes the Operator into a wall or the water. | `test_knockback_does_not_push_the_operator_into_a_wall` |
| 16 | `ContentDb` validates cores, logs and reliquaries (kinds, required fields, references, minimum offer); bad entries are dropped and reported, never crashed on. | `test_broken_content_is_reported_not_crashed_on`, `test_shipped_content_is_valid` |
| 17 | `LevelGrid.validate` rejects unknown characters, missing start or Reliquary markers and bad ids; unknown cells are solid (fail closed); a broken map sends you to the title before anything is saved. | `test_validation_catches_broken_maps` |
| 18 | The Ark's buildings come from `buildings_restored`: a restored building stands with its door, an unrestored one is a bare plot (`UnbuiltPlot`). | `test_buildings_stand_only_once_restored` |
| 19 | Survivors overflow to free cells near the Commons, any number, never on top of each other. | `test_every_survivor_has_a_place_on_the_ark` |
| 20 | The Archive list scrolls and follows controller focus. | `test_the_archive_list_scrolls` |
| 21 | The Reliquary inlay and the Feed kiosk draw the canonical ring (`RingPainter`), squashed onto the ground; the kiosk uses the MUTED look. | ring geometry tests; by eye (ring gallery recording) |
| 22 | The Steward's watch records nothing on the Ark or off the Lattice. | `test_the_ark_is_the_advisory_exception`, `test_it_does_not_profile_what_it_cannot_see` |
| 23 | Narration history and cooldowns reset with every new run. | `test_a_new_run_starts_with_fresh_narration` |
| 24 | Muted Continue shows no Steward line in the loadout. | `test_the_muted_loadout_has_no_steward_line` |
| 25 | The autopilot registers every expected check up front (30 s and full-route lists), so a run that stops early fails; an unknown scenario is an error. | gate stages 3 and 4 |
| 26 | The test runner fails when nothing runs, a directory is missing or a filter matches nothing. It now also fails any test that logs an engine or script error or warning, resets pause/time scale between tests, and abandons a test still running after 120 s. | checked by hand with throwaway broken tests (error, leftover pause, hang) |
| 27 | Confirmed: bindings now listen to every device (`device = -1`), so a second or reconnected controller works. | `test_any_controller_drives_the_actions` |
| 28 | Export presets for Linux, Windows and macOS include the text/JSON data; `tools/export.sh` exports all three and runs the exported Linux build through the 30 s autopilot. macOS needed ETC2/ASTC textures (enabled) and is ad-hoc signed (unsigned arm64 apps don't launch). | `tools/export.sh` (EXPORT: PASS) |
| 29 | Not closable here: no Deck, controller or Windows/macOS machine. Measured and optimised what could be (below); what to check on hardware is listed in PROGRESS.md. | autopilot `[perf]` report |

**Performance (finding 29).** The autopilot now reports frame times in the district and where they
go (game logic on the main thread, frame submission, GPU). On this machine (Intel Iris Xe iGPU,
1920×1080, Forward+, HDR 2D):

- Before: capped at 60 it ran at about 51 fps; uncapped 16 ms average, slowest 1% 24 ms.
- The Steward ring, HUD pill and HUD panels redrew every frame; the minimap redrew ~1,000 cell
  polygons whenever you stepped into a new cell (in either mode). Now the ring redraws only while
  speaking or glitching, the HUD only when its state changes, the subtitles only while shown, and the
  minimap keeps its cells in 8×8 chunks that redraw only when a cell in them is first seen (hand
  scan) or the map changes mode.
- After: capped at 60 it holds **60 fps average, slowest 1% about 54–56 fps**; uncapped about 15 ms
  average. Main-thread game logic median 6.4–6.8 ms (1% 9–10 ms), GPU median 9–10 ms.
- `--perf-disable=lights,glow,grade,rain,reflections,fog,buildings,hdr,minimap,hud` (developer flag)
  switches features off to measure their cost.

The Deck renders 1280×800 (about half the pixels) on a GPU in the same class, so the GPU side should
have headroom; its CPU is slower than this one, so the 6–7 ms of game logic is the number to watch.
That has to be measured on the Deck itself.
