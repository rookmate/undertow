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

## Round 2 findings (verbatim from sol_analyst)

Scope: `git diff 499648a..9e028fc` (the round 1 fixes) plus a re-check of every round 1 finding.

I would not close the milestone yet. Most round-1 fixes are substantive, and the recorded gate passes are supported by the logs. However, the fix introduces a projectile-wall regression, broken invalid-map recovery, and a way to complete a level without recovering any cores. Several growth and failure-path guarantees are also incomplete.

Reviewed `git diff 499648a..9e028fc`, the 29 original findings, the brief, world bible, decisions, changed production code, tests, and validation logs. No files were edited. I did not rerun the gate because it writes files and this session is read-only. Read-only numerical reproductions confirmed the projectile obstruction failure and the Ark population capacity failure.

“Confirmed” below means the code and failure path are established. It does not mean every scenario was reproduced interactively in Godot.

The logs confirm:

- [tests.log:216](/home/homebox/Documents/rookmate/undertow/reports/check/tests.log:216): 207 tests pass.
- [smoke.log:34](/home/homebox/Documents/rookmate/undertow/reports/check/smoke.log:34): 20 checks pass at 30 seconds.
- [full.log:60](/home/homebox/Documents/rookmate/undertow/reports/check/full.log:60): 45 checks pass at 150 seconds.
- [linux-run.log:33](/home/homebox/Documents/rookmate/undertow/reports/export/linux-run.log:33): the exported Linux build passes 20 checks.
- The three export logs explicitly list the maps and JSON documents in their packages. The inspected logs contain no reported errors or warnings.

For each round-1 finding:

| # | Verdict | Evidence and remaining reason |
|---|---|---|
| 1 | **Partly** | Supported scenarios now select isolated saves before driving scenes. However, `scenario` becomes a directory component before validation, and isolation compares unnormalized strings. `../saves` can target the player's directory. See confirmed finding 7 below. [autoload/autopilot.gd:70](/home/homebox/Documents/rookmate/undertow/autoload/autopilot.gd:70) |
| 2 | **Resolved** | `cursor_aim()` offsets the cursor by the projectile's chest height before converting to ground aim. The added test covers the original three-tile example. It is a geometry test, rather than a mouse-input combat test, but it verifies the faulty calculation. [game/player/operator.gd:188](/home/homebox/Documents/rookmate/undertow/game/player/operator.gd:188), [tests/unit/test_combat_geometry.gd:31](/home/homebox/Documents/rookmate/undertow/tests/unit/test_combat_geometry.gd:31) |
| 3 | **Resolved** | Pause pops its own ownership and restores previous focus; another modal keeps the tree paused. The Archive test exercises this directly. The new save dialog has separate ownership problems described below. [ui/pause/pause_menu.gd:65](/home/homebox/Documents/rookmate/undertow/ui/pause/pause_menu.gd:65), [tests/integration/test_modals_and_routing.gd:27](/home/homebox/Documents/rookmate/undertow/tests/integration/test_modals_and_routing.gd:27) |
| 4 | **Resolved** | `_start()` rejects busy navigation before invoking `prepare`; Title and Loadout place their state changes inside that callback. GUI input is disabled during the fade. [autoload/scene_router.gd:99](/home/homebox/Documents/rookmate/undertow/autoload/scene_router.gd:99), [ui/title/title.gd:85](/home/homebox/Documents/rookmate/undertow/ui/title/title.gd:85), [tests/integration/test_modals_and_routing.gd:60](/home/homebox/Documents/rookmate/undertow/tests/integration/test_modals_and_routing.gd:60) |
| 5 | **Resolved** | Writes flush and check the file error, then compare the temporary file with the intended contents before rotation. Short-write and failed-write tests check preservation of the main save; corrupt main files no longer overwrite good backups. Rename/removal failures are not covered by the injected boundary. [core/save_store.gd:43](/home/homebox/Documents/rookmate/undertow/core/save_store.gd:43), [tests/unit/test_save_store.gd:91](/home/homebox/Documents/rookmate/undertow/tests/unit/test_save_store.gd:91) |
| 6 | **Partly** | Checkpoints now report failure, and leaving offers retry, leave, and stay. Those choices have meaningful tests. However, exit requests are not serialized, and save dialogs do not fully participate in focus/input ownership or transition cleanup. See confirmed finding 4. [ui/common/save_flow.gd:16](/home/homebox/Documents/rookmate/undertow/ui/common/save_flow.gd:16), [tests/integration/test_save_flow.gd:52](/home/homebox/Documents/rookmate/undertow/tests/integration/test_save_flow.gd:52) |
| 7 | **Resolved** | Coverage feeds the shared assist calculation. Narration, profiling, damage, weapon mode, warnings, slow motion, and the map's player marker consult that state. The accepted 0.6-second grace and Ark exception are explicit. [game/level/level.gd:110](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:110), [core/assists.gd:34](/home/homebox/Documents/rookmate/undertow/core/assists.gd:34), [tests/integration/test_coverage.gd:30](/home/homebox/Documents/rookmate/undertow/tests/integration/test_coverage.gd:30) |
| 8 | **Resolved** | Loadout derives the district from the saved location; departure, resume routing, and restoration use `LevelCatalog`. The former fixed Vellum routes are removed. [ui/loadout/loadout.gd:19](/home/homebox/Documents/rookmate/undertow/ui/loadout/loadout.gd:19), [autoload/scene_router.gd:79](/home/homebox/Documents/rookmate/undertow/autoload/scene_router.gd:79), [core/core_choice.gd:49](/home/homebox/Documents/rookmate/undertow/core/core_choice.gd:49) |
| 9 | **Partly** | Placement IDs, level-scoped narration, and actual cache markers replace the Vellum constants. Validation checks duplicate IDs within one map, but it does not validate content references or uniqueness across maps. The “ids point at real content” check covers only the shipped Vellum map. [core/level_grid.gd:88](/home/homebox/Documents/rookmate/undertow/core/level_grid.gd:88), [game/level/level.gd:304](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:304), [tests/unit/test_level_grid.gd:108](/home/homebox/Documents/rookmate/undertow/tests/unit/test_level_grid.gd:108) |
| 10 | **Resolved** | Prediction explicitly excludes the current cell, and rendering immediately removes cells outside the current prediction. Added tests inspect painted membership while moving, at a corner, and after muting. [core/path_predictor.gd:67](/home/homebox/Documents/rookmate/undertow/core/path_predictor.gd:67), [game/path/predicted_path.gd:43](/home/homebox/Documents/rookmate/undertow/game/path/predicted_path.gd:43), [tests/integration/test_predicted_path.gd:163](/home/homebox/Documents/rookmate/undertow/tests/integration/test_predicted_path.gd:163) |
| 11 | **Resolved** | Coverage now depends on indexed floor rather than navigation openness. Prediction can start from a neighboring open cell when the Operator occupies a lamp cell's playable corner. The added integration test covers that case. [core/path_predictor.gd:49](/home/homebox/Documents/rookmate/undertow/core/path_predictor.gd:49), [tests/integration/test_predicted_path.gd:190](/home/homebox/Documents/rookmate/undertow/tests/integration/test_predicted_path.gd:190) |
| 12 | **Resolved** | Voice and coverage changes cancel active slow motion immediately. Both transitions have tests. [game/level/slow_mo.gd:16](/home/homebox/Documents/rookmate/undertow/game/level/slow_mo.gd:16), [tests/integration/test_coverage.gd:65](/home/homebox/Documents/rookmate/undertow/tests/integration/test_coverage.gd:65) |
| 13 | **Resolved** | Shared weapon candidate filtering now requires line of sight, and Custodian strikes do too. Tests cover the original kiosk obstruction and an unobstructed alternative target. The visibility query's sampled geometry still has corner limitations described below. [game/weapons/weapon.gd:80](/home/homebox/Documents/rookmate/undertow/game/weapons/weapon.gd:80), [game/enemies/custodian.gd:59](/home/homebox/Documents/rookmate/undertow/game/enemies/custodian.gd:59), [tests/integration/test_combat_rules.gd:35](/home/homebox/Documents/rookmate/undertow/tests/integration/test_combat_rules.gd:35) |
| 14 | **Partly** | Target-circle sweeps and travel ordering are implemented. Wall obstruction is regressed at normal projectile speeds because every tick excludes its start and end cells. The wall test uses an unusually fast projectile that skips across the entire kiosk in one tick. See confirmed finding 1. [game/weapons/projectile.gd:34](/home/homebox/Documents/rookmate/undertow/game/weapons/projectile.gd:34), [tests/integration/test_combat_rules.gd:48](/home/homebox/Documents/rookmate/undertow/tests/integration/test_combat_rules.gd:48) |
| 15 | **Resolved** | Knockback contributes velocity before `move_and_slide()`. The integration test applies repeated hits against a building boundary and checks that the player remains on playable ground. [game/player/operator.gd:112](/home/homebox/Documents/rookmate/undertow/game/player/operator.gd:112), [tests/integration/test_combat_rules.gd:75](/home/homebox/Documents/rookmate/undertow/tests/integration/test_combat_rules.gd:75) |
| 16 | **Partly** | The original nested-type crashes and unknown offered-core handling are addressed. Missing required collections and Reliquary keys are still accepted; undersized offers are retained after reporting an error; `_loaded` becomes true even with errors. The new choice fallback converts these failures into successful progression. [core/content_db.gd:20](/home/homebox/Documents/rookmate/undertow/core/content_db.gd:20), [core/content_db.gd:36](/home/homebox/Documents/rookmate/undertow/core/content_db.gd:36) |
| 17 | **Partly** | Unknown cells fail closed, and marker/ID/reachability validation exists. Initialization stops before saving. However, returning to Title is rejected during the incoming transition, and processing continues against uninitialized fields. See confirmed finding 2. [game/level/level.gd:40](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:40), [game/level/level.gd:95](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:95) |
| 18 | **Resolved** | Archive facade and door construction consult restoration state; otherwise an `UnbuiltPlot` appears. Before/after restoration behavior has integration coverage. Additional building types will still need their own plot and fixture definitions. [game/ark/ark_level.gd:37](/home/homebox/Documents/rookmate/undertow/game/ark/ark_level.gd:37), [game/ark/ark_level.gd:56](/home/homebox/Documents/rookmate/undertow/game/ark/ark_level.gd:56), [tests/integration/test_ark.gd:98](/home/homebox/Documents/rookmate/undertow/tests/integration/test_ark.gd:98) |
| 19 | **Partly** | Population now expands beyond three markers, and the eight-survivor test is meaningful. Exhausting available cells, or removing all `s` markers, returns a short array that `_populate()` indexes as though complete. See confirmed finding 8. [game/ark/ark_level.gd:33](/home/homebox/Documents/rookmate/undertow/game/ark/ark_level.gd:33), [game/ark/ark_level.gd:62](/home/homebox/Documents/rookmate/undertow/game/ark/ark_level.gd:62) |
| 20 | **Resolved** | The list is bounded in a focus-following scroll container, and the record is bounded with internal scrolling. The new test checks structure and `follow_focus`, but does not exercise large content volumes or controller scrolling through long records. [ui/archive/archive_screen.gd:43](/home/homebox/Documents/rookmate/undertow/ui/archive/archive_screen.gd:43), [ui/archive/archive_screen.gd:63](/home/homebox/Documents/rookmate/undertow/ui/archive/archive_screen.gd:63), [tests/integration/test_ark.gd:146](/home/homebox/Documents/rookmate/undertow/tests/integration/test_ark.gd:146) |
| 21 | **Resolved** | Both props call the canonical `RingPainter`; the Reliquary projects it onto its lid. No substitute geometry remains in these props. [game/props/reliquary.gd:60](/home/homebox/Documents/rookmate/undertow/game/props/reliquary.gd:60), [game/level/static_prop.gd:85](/home/homebox/Documents/rookmate/undertow/game/level/static_prop.gd:85) |
| 22 | **Resolved** | Profiling requires Steward presence and excludes hubs. The Ark test emits a dodge and checks that caution is unchanged. [game/level/steward_watch.gd:50](/home/homebox/Documents/rookmate/undertow/game/level/steward_watch.gd:50), [tests/integration/test_coverage.gd:79](/home/homebox/Documents/rookmate/undertow/tests/integration/test_coverage.gd:79) |
| 23 | **Resolved** | `run_replaced` calls `reset_session()`. New Game and Continue both emit it; ordinary district transitions do not. The added test checks history, tone counts, and cooldown behavior. [autoload/narrator.gd:28](/home/homebox/Documents/rookmate/undertow/autoload/narrator.gd:28), [tests/integration/test_adaptive_narration.gd:109](/home/homebox/Documents/rookmate/undertow/tests/integration/test_adaptive_narration.gd:109) |
| 24 | **Resolved** | Loadout creates its live Steward line only when voice is on; the added test checks its absence when muted. [ui/loadout/loadout.gd:77](/home/homebox/Documents/rookmate/undertow/ui/loadout/loadout.gd:77), [tests/integration/test_adaptive_narration.gd:119](/home/homebox/Documents/rookmate/undertow/tests/integration/test_adaptive_narration.gd:119) |
| 25 | **Resolved** | Complete scenario checklists are registered at startup. Long runs require Archive and ending checks even if those phases are never reached. Unknown scenarios retain a failing required check. [autoload/autopilot.gd:119](/home/homebox/Documents/rookmate/undertow/autoload/autopilot.gd:119), [autoload/autopilot.gd:151](/home/homebox/Documents/rookmate/undertow/autoload/autopilot.gd:151) |
| 26 | **Resolved** | Missing expected directories and zero executed tests now fail. The runner also collects runtime errors/warnings and applies a real-time timeout. I verified the implementation; the throwaway broken-test demonstrations are reported evidence, not independently rerun evidence. [tests/test_runner.gd:63](/home/homebox/Documents/rookmate/undertow/tests/test_runner.gd:63), [tests/test_runner.gd:113](/home/homebox/Documents/rookmate/undertow/tests/test_runner.gd:113) |
| 27 | **Resolved** | Bindings explicitly use all devices, and tests check button/axis action matching for device IDs 0, 1, and 3. Physical reconnection remains part of finding 29. [autoload/controls.gd:98](/home/homebox/Documents/rookmate/undertow/autoload/controls.gd:98), [tests/unit/test_controls.gd:28](/home/homebox/Documents/rookmate/undertow/tests/unit/test_controls.gd:28) |
| 28 | **Resolved** | All presets include text/JSON data, export logs show the required files, and the exported Linux executable passes its smoke run. This closes the packaging concern, not Windows/macOS runtime compatibility. [export_presets.cfg:10](/home/homebox/Documents/rookmate/undertow/export_presets.cfg:10), [reports/export/Linux.log:57](/home/homebox/Documents/rookmate/undertow/reports/export/Linux.log:57) |
| 29 | **Not resolved, with a written reason** | Development-host performance is measured, and unavailable hardware is clearly documented. Deck performance, real controllers, and Windows/macOS runtime behavior remain unverified. [PROGRESS.md:117](/home/homebox/Documents/rookmate/undertow/PROGRESS.md:117), [reviews/vertical-slice.md:321](/home/homebox/Documents/rookmate/undertow/reviews/vertical-slice.md:321) |

The confirmed findings in the fix diff, ranked by severity, are:

1. **High · bug: ordinary projectiles now pass through blocking cells.**

   [core/level_grid.gd:159](/home/homebox/Documents/rookmate/undertow/core/level_grid.gd:159) excludes both endpoint cells from `first_block()`. [game/weapons/projectile.gd:41](/home/homebox/Documents/rookmate/undertow/game/weapons/projectile.gd:41) calls that query independently for every movement tick.

   At the Drone's normal speed of 15 tiles/second, a 60 Hz tick travels 0.25 tiles. Entering a kiosk excludes it as the end cell; subsequent ticks exclude it as both endpoint cells; leaving excludes it as the start cell. A shot can cross the entire kiosk without finding a wall. Clerk bales have the same problem.

   A numerical reproduction against the shipped kiosk at `(13,17)` returned `-1` for all eight consecutive quarter-tile segments crossing it. The added test instead uses 150 tiles/second, placing the kiosk between the endpoints and concealing the regression.

   The query also samples every 0.05 tiles rather than calculating cell intersections, so sufficiently short corner crossings can escape detection.

   **Required change:** use exact segment traversal/intersection for blocking geometry. Separate any actor-endpoint exceptions from projectile obstruction. Test normal-speed entry, travel within a blocker, exit, grazing corners, and different tick rates.

2. **High · crash risk: invalid-map recovery leaves an unusable level running.**

   [game/level/level.gd:43](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:43) requests Title from `_ready()` and returns. During normal navigation, [autoload/scene_router.gd:105](/home/homebox/Documents/rookmate/undertow/autoload/scene_router.gd:105) keeps `_busy` true throughout scene creation and the return fade, so that recovery request is rejected.

   The failed level remains current. Its `_process()` then calls `exploration.observe(player.cell())` despite neither object having been initialized. Loading an invalid map directly also leaves processing enabled while recovery waits for its fade.

   **Required change:** disable failed level processing immediately and make initialization failure an explicit router outcome. Add a test that enters a malformed level through the real router and verifies recovery, unchanged saved progress, and absence of subsequent null-access errors.

3. **High · brief violation/data-integrity bug: invalid or missing Reliquary content can restore a building with zero cores.**

   [core/content_db.gd:36](/home/homebox/Documents/rookmate/undertow/core/content_db.gd:36) defaults missing collections to empty dictionaries. It does not require a Reliquary entry for every catalog district. Undersized offers are reported but retained at line 73.

   The new [core/core_choice.gd:20](/home/homebox/Documents/rookmate/undertow/core/core_choice.gd:20) reduces the required carry count to the offer size. Consequently, `validate([], [])` succeeds. `apply()` then completes the district, restores its building, clears found cores, and moves the run to the Ark.

   A missing or mistyped Reliquary key therefore bypasses the brief's forced trade-off. The old behavior rejected an undersized choice; this diff converts the same content defect into apparently successful progression.

   **Required change:** validate catalog-to-content completeness before play and reject invalid offers. If revisiting completed districts needs different rules, model that explicitly instead of relaxing fresh-level completion. Add tests for absent keys, undersized offers, and zero-core application that assert no progression changes.

4. **Medium · bug/maintainability: the modal stack owns pause, but does not own input, focus, or exit-request lifetime consistently.**

   [ui/pause/pause_menu.gd:44](/home/homebox/Documents/rookmate/undertow/ui/pause/pause_menu.gd:44) opens a hidden Pause menu regardless of the existing top modal. A save question draws at layer 80; Pause draws at layer 40. Pressing Start during a failed window-close save therefore pushes Pause above the question logically and focuses controls behind it visually.

   `Modals.is_top()` guards selected `_unhandled_input()` handlers, but GUI button callbacks remain enabled. `SaveFailure._choose()` has no ownership check or previous-focus restoration. Repeated close requests also start multiple independent `before_leaving()` coroutines because [autoload/game_state.gd:26](/home/homebox/Documents/rookmate/undertow/autoload/game_state.gd:26) has no in-progress guard.

   Save dialogs are children of the root, whereas scene transitions merely clear the stack. Thus another navigation can leave a live dialog and suspended exit request behind after its scene is gone.

   **Required change:** let one modal owner manage focus, enabled controls, visual order, and teardown. Serialize leaving requests and prevent Pause from taking focus behind a pending save decision. Test real input, repeated close requests, Stay focus restoration, and transition cleanup.

5. **Medium · bug: HUD redraw caching leaves expired world prompts on screen.**

   [ui/hud/hud_view.gd:59](/home/homebox/Documents/rookmate/undertow/ui/hud/hud_view.gd:59) redraws while a world annotation currently exists. Its signature includes Integrity and weapon state, but excludes annotation presence.

   Walk out of interaction range with unchanged weapon/Integrity state. `_world_anchored()` becomes false and the signature remains unchanged, so the draw list containing the previous interaction prompt is retained. The same failure applies when the last threat expires or the last survivor speech ends.

   **Required change:** redraw on the transition from having world annotations to having none, or separate the always-updated annotation layer from the cached HUD. Test annotation removal, not only appearance.

6. **Medium · content/data-integrity gap: map validation does not validate the promised content contracts.**

   [core/level_grid.gd:88](/home/homebox/Documents/rookmate/undertow/core/level_grid.gd:88) checks local ID presence and uniqueness without consulting content. A `T` pointing to an unknown core or a `U` pointing to an unknown log passes map validation.

   The cache records the unknown core, which `CoreChoice.offer()` later filters out. The slip records an unknown unlocked log, which the Archive never lists. Duplicate survivor IDs across different maps also remain undetected and share global rescue state.

   **Required change:** validate all catalog maps against core/log kinds and global survivor identity before gameplay. Keep that contract in one validation boundary. The current Vellum-only assertions do not protect new districts.

7. **Medium · save-loss risk: an unknown autopilot scenario can escape the isolated save directory before being rejected.**

   [autoload/autopilot.gd:71](/home/homebox/Documents/rookmate/undertow/autoload/autopilot.gd:71) joins the unchecked scenario onto `user://autopilot`, then immediately deletes saves. Only afterward does `_register_expected()` reject unknown scenarios.

   `--autopilot-scenario=../saves` produces `user://autopilot/../saves`, which resolves to the player's save directory. The string differs from `DEFAULT_DIR`, so the isolation check does not detect the alias. Both the gate and recording script accept an externally supplied scenario.

   **Required change:** validate the scenario against the supported names before any filesystem operation, and use the validated name for its directory. Test rejection without touching either player save file.

8. **Medium · future-content crash risk: survivor overflow assumes allocation cannot run out.**

   [game/ark/ark_level.gd:89](/home/homebox/Documents/rookmate/undertow/game/ark/ark_level.gd:89) can return fewer cells than requested, while `_populate()` unconditionally indexes `spots[i]` for every survivor.

   Exhaustively following the current allocator over the shipped Ark yields 158 available survivor cells. Requesting 159 returns only 158. Removing all `s` markers produces the same short-array failure immediately, and hub validation permits that map.

   This replaces the old silent population cap with an eventual out-of-bounds failure.

   **Required change:** make allocation capacity explicit and retain access to overflow survivors, or validate a supported population limit before construction. Test exhaustion and missing seed markers, alongside the existing eight-survivor case.

9. **Low · incomplete performance fix: the HUD ring still requests redraw every frame while idle or muted.**

   [ui/hud/steward_pill.gd:27](/home/homebox/Documents/rookmate/undertow/ui/hud/steward_pill.gd:27) assigns `ring.state` every frame. The setter at [ui/common/steward_ring.gd:13](/home/homebox/Documents/rookmate/undertow/ui/common/steward_ring.gd:13) unconditionally queues a redraw, even when the value is unchanged.

   Removing the unconditional redraw from the ring's own `_process()` therefore does not deliver the claimed behavior for the gameplay HUD.

   **Required change:** ignore unchanged state assignments. This does not invalidate the measured host improvement, but the documented explanation overstates which redraw work was removed.

The remaining inferences and unverified risks are separate:

- Deck performance and physical controller/platform behavior remain open as documented. The host logs support approximately 60 FPS average; they do not establish the target hardware result.
- Large Archive lists and long records now have bounds, but the added test checks container properties only. Controller access to earlier portions of a long record, long titles, and long companion reactions still needs a realistic content-volume test.
- Growth-related failures above are confirmed conditional code paths. The current two-survivor, valid-content slice does not demonstrate that players already encounter them.

The tests were strengthened overall. I found no removal of meaningful existing assertions in the reviewed changes. Write-failure, coverage, cancellation, painted-path, collision, and controller-matching tests provide useful evidence. The remaining gaps are consequential: the wall test uses a speed that avoids the normal-speed bug; malformed-map tests stop at `validate()`; malformed-content tests inspect diagnostics without testing refusal of progression; modal tests mostly invoke methods directly; and population tests never exhaust allocation.

Acceptance is therefore **not met**. Finding 29 has an adequate written reason. The claim that the other 28 are fully fixed is not supported, and the new high-severity failures need correction before closure.
## Round 2: what was done about each finding

All nine round 2 findings are fixed, and so is the Archive content-volume inference. Each fix has a
test that was run against the code before the fix and **failed there** (checked by stashing the fix),
so the tests are not just green on the new code. The "partly" verdicts on round 1 items map onto these
findings: #1 → 7, #6 → 4, #9 → 6, #14 → 1, #16 → 3, #17 → 2, #19 → 8.

| # | Resolution | Covered by |
|---|---|---|
| 1 | `LevelGrid.first_block` walks every cell the segment crosses exactly (grid traversal, not 0.05-tile samples), counts the cells at both ends, and treats a segment through a shared wall corner as blocked. Actors can't stand inside blocking cells (their bodies collide), so sight lines use the same rule. | `test_ticks_of_any_length_stop_at_the_wall` (0.05–2.5-tile ticks stop exactly at the kiosk face), `test_blocking_counts_the_cells_at_both_ends`, `test_a_corner_between_two_walls_does_not_let_a_shot_through`, `test_shots_at_every_speed_stop_at_the_kiosk` (the Drone's real 15 tiles/s, the Clerk's bale, 150 tiles/s), `test_an_open_shot_still_lands` |
| 2 | A level whose map fails validation sets `failed`, stops processing, physics and input at once, and calls `SceneRouter.abandon()`. During a transition the router goes on to the title behind the same fade (the broken level is never announced as current); outside one it starts a normal transition. Nothing is saved. | `test_entering_a_broken_level_lands_on_the_title` (through the real router, with a fixture level: lands on the title, input back, save file byte-identical, no errors after the reports), `test_a_broken_map_stops_the_level_before_anything_runs` |
| 3 | `CoreChoice` no longer shrinks the carry count: an offer that isn't more than two cores is reported as a broken Reliquary and can't complete the level (no cores, no restore, no Ark). `ContentDb` reports missing top-level sections and drops undersized Reliquaries instead of keeping them. `LevelCatalog.check_all()` runs at boot and fails loudly if any district lacks a real Reliquary. The card screen says the Reliquary is broken and offers only "back to the title". | `test_a_broken_offer_completes_nothing`, `test_missing_and_undersized_reliquaries_are_dropped_and_reported`, `test_ids_are_unique_across_districts_and_every_district_has_a_reliquary`, `test_a_reliquary_with_no_real_choice_says_so_and_completes_nothing` |
| 4 | `Modals` now owns draw order (a pushed screen goes above the one under it), input (screens under the top go inert: no focus, no clicks) and focus (restored to where it was when the top closes). A save question is *blocking*: the pause menu can't open over it. Close requests are serialized (one question however often close is pressed). Scene changes dismiss open screens; a pending save question resolves as "stay" instead of waiting forever. | `test_a_save_question_owns_input_and_stay_gives_focus_back` (real pad input: Start, down, accept, right, right, accept), `test_closing_the_window_twice_asks_once` (also: Start during the close question opens nothing), `test_a_scene_change_dismisses_an_open_question`, `test_screens_under_the_top_one_are_inert_until_it_closes` |
| 5 | The HUD redraws once more when the last world-anchored mark (prompt, threat, survivor's words) goes, then stops. | `test_walking_away_clears_the_interaction_prompt` (counts draws: redrawn on leaving, then left alone) |
| 6 | `LevelGrid.content_problems()`: a cache must hold a truth core, a slip an unindexed log. `LevelCatalog.check()` validates every district's map and content together and rejects an id placed in two districts. Levels run the content check on load too. District maps now come from the catalog (one source of truth). | `test_maps_must_name_real_content_of_the_right_kind`, `test_ids_are_unique_across_districts_and_every_district_has_a_reliquary`, `test_shipped_districts_pass_the_boot_check` |
| 7 | The scenario is checked against the known list before anything touches the disk; an unknown one prints `AUTOPILOT FAIL: known_scenario` and exits 1. Isolation compares resolved paths, so `user://autopilot/../saves` is not "isolated". | `test_the_autopilot_never_saves_outside_its_own_folder`; run by hand with `--autopilot-scenario=../saves`: exits 1, the player's save untouched |
| 8 | Survivor placement returns fewer cells only when the Ark is full; the Ark then shows everyone there's room for and reports the overflow (nobody leaves the run, nothing indexes past the end). Ark maps must have survivor spots, Noor, Teo and the dock. Current capacity: about 158. | `test_a_full_ark_is_reported_not_crashed_on`, `test_an_ark_map_without_survivor_spots_is_refused` |
| 9 | The ring's state setter ignores unchanged values, so the HUD ring is drawn once per state as documented. | `test_the_hud_ring_redraws_only_when_its_state_changes` |
| inference: Archive volume | Titles, the Steward's comment and the reactions are clipped with an ellipsis inside fixed boxes; list buttons clip long titles. The record box takes focus (right from the list, left back) and scrolls on ui_up/ui_down from any device: Godot's own RichTextLabel scrolling reads only keyboard keys, so a pad could never scroll it. | `test_a_full_archive_fits_and_scrolls_with_a_pad` (40 logs, a 60-line record, long title and reaction) |

Supporting change: broken content and maps are reported through `Diagnostics.error` (an engine error
normally). Tests that break things on purpose capture those reports and check them, so the test
runner's "any logged error fails the test" rule and the gate's log scan stay as strict as before.

Gate after round 2: import clean; **228 tests** pass; 30 s run 23/23 checks; 150 s full-slice run
45/45; no errors or warnings in any log; 60 fps average (1% low 56–57 fps) capped at 60 on this
machine; `tools/export.sh` exports all three platforms and the exported Linux build passes its run.

Not fixed, with reasons:
- **29 (hardware):** needs a Steam Deck, real controllers and Windows/macOS machines (see PROGRESS.md,
  "What only hardware can confirm").
- **ContentDb caches its result even when it found errors** (round 2, table row 16): kept on purpose.
  The errors are reported at boot (the gate fails on them) and every consumer now refuses broken
  content (no level completes from a broken Reliquary); re-reading the files on every call would add
  nothing.
