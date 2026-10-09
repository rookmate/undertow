# Milestone review: Act 1 (milestone 2)

Reviewer: **sol_analyst** (Sol 6.1, xhigh, read-only) via the "Sol analysis" skill, run through
`codex exec -s read-only`. Scope: `git diff 4623662..e244859` (steps 9–16: sound, voice, options,
districts, Kestrel Heights, bosses and the Loop, the Signal Room, the Tideworks, the Workshop). Author of
the code under review: Claude Code (Claude Opus 5.5).

## Round 1 findings (verbatim from sol_analyst)

The milestone gate passes, but several gameplay and design contracts remain broken. I would keep milestone 2 open until the targeting, weapon lifecycle, override and weapon acquisition findings below are addressed.

I reviewed `4623662..e244859`, the design sources, tests and recorded gate output. The logs substantiate **291 passing tests**, the reported long routes and all four district tours. I made no edits and did not rerun commands that would write logs, imports, saves or settings.

“Confirmed” below means the failure follows from the implementation; conditional findings state the input or circumstance required. Hardware and listening conclusions remain separate.

Confirmed findings, ranked by severity:

1. **High: friendly Lamplighters remain combat targets while the Steward listens.**

   `_on_voice(true)` removes a Lamplighter from the `enemies` group, but combat enumerates `Level._enemies` through `living_enemies()`, which checks only whether each enemy is alive. Lamplighters retain the default `steward_aims_at` flag and accept damage. Consequently, tuned weapons can select, stun and kill a friendly guide, contrary to decision 95. Manual aim assistance also treats it as a candidate.

   The test named “are not targets” asserts group membership without firing a weapon, so it cannot catch this. Establish explicit combat eligibility and use it consistently across aim assistance, tuned selection and hit queries; test an actual attack with the voice on and off. Evidence: [lamplighter.gd:55](/home/homebox/Documents/rookmate/undertow/game/enemies/lamplighter.gd:55), [level.gd:189](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:189), [weapon.gd:85](/home/homebox/Documents/rookmate/undertow/game/weapons/weapon.gd:85), [test_kestrel.gd:63](/home/homebox/Documents/rookmate/undertow/tests/integration/test_kestrel.gd:63).

2. **Medium: the Steward assists aiming at boss weak points through the fallback path.**

   `WeakPoint` sets `steward_aims_at = false` and `is_threat = false`. Tuned target selection respects the first flag, but `Operator.aim_ground()` supplies every living enemy to aim assistance without either filter. Manual weapons therefore receive Steward assistance toward the signal box or hoist brake. Tuned weapons also use that assisted aim when no eligible automatic target is in reach.

   At the base assistance strength, an aim eight degrees beside a weak point bends to 3.6 degrees beside it. This contradicts decision 109’s “never aimed at by the Steward.” The current test compares tuned direction with `player.aim_ground()`, which may already contain the forbidden assistance. Test against the raw stick or mouse direction and filter assistance candidates by the appropriate eligibility contract. Evidence: [operator.gd:240](/home/homebox/Documents/rookmate/undertow/game/player/operator.gd:240), [weak_point.gd:10](/home/homebox/Documents/rookmate/undertow/game/bosses/weak_point.gd:10), [weapon.gd:99](/home/homebox/Documents/rookmate/undertow/game/weapons/weapon.gd:99), [test_bosses.gd:100](/home/homebox/Documents/rookmate/undertow/tests/integration/test_bosses.gd:100).

3. **Medium: finding, losing or recovering a weapon disconnects combat profiling for the remainder of the district.**

   `add_weapon()` and `take_weapon()` call `_re_equip()`, which destroys and recreates **every** carried Weapon node. `StewardWatch.setup()` connects `fired` only to the original instances, with no reconnection path. Finding the Riot Drone or undergoing a Salvager snatch therefore stops tuned/manual usage events and manual-weapon commentary, including for the recreated Baton.

   Recreating unaffected weapons also resets their transient cooldown, heat and charge state. Preserve unaffected instances, or publish weapon firing through a stable Operator signal. Cover acquisition and snatch/recovery followed by actual firing. Evidence: [operator.gd:76](/home/homebox/Documents/rookmate/undertow/game/player/operator.gd:76), [steward_watch.gd:31](/home/homebox/Documents/rookmate/undertow/game/level/steward_watch.gd:31), [weapon_find.gd:26](/home/homebox/Documents/rookmate/undertow/game/props/weapon_find.gd:26), [salvager.gd:68](/home/homebox/Documents/rookmate/undertow/game/enemies/salvager.gd:68).

4. **Medium: standing orders do not govern all Steward speech.**

   Boss warnings check `steward_present`, then use `Narrator.speak_text()`. That method checks narration availability but does not check `threat_warnings`. With “Never warn me about traps” signed, the Conductor still calls tracks and the Crane still says “Drop. Get out from under it.”

   “Stop praising me” is enforced only by `Narrator.notify()`. Fixed speech bypasses that policy; its signing reply itself ends with praise: “you’re good at this. You are.” Workshop replies also continue through this unrestricted route.

   Give lines explicit purposes, such as warning, fact and praise, and apply standing-order policy at one narration boundary. Test boss encounters and fixed replies with the orders signed. Evidence: [boss.gd:88](/home/homebox/Documents/rookmate/undertow/game/bosses/boss.gd:88), [narrator.gd:60](/home/homebox/Documents/rookmate/undertow/autoload/narrator.gd:60), [narrator.gd:76](/home/homebox/Documents/rookmate/undertow/autoload/narrator.gd:76), [overrides.json:44](/home/homebox/Documents/rookmate/undertow/data/overrides.json:44), [workshop_screen.gd:97](/home/homebox/Documents/rookmate/undertow/ui/ark/workshop_screen.gd:97).

5. **Medium: a fresh run cannot obtain the planned Vellum Defib Gauntlet.**

   The Act 1 outline explicitly says the Vellum temporarily offers the Gauntlet until Mercy General exists. New runs own only the Baton; the production acquisition path is the weapon-find prop, and the only placed weapon find is the Tideworks Riot Drone. The Vellum contains no Gauntlet find or equivalent grant.

   The Vellum autopilot masks this omission by granting all playable weapons while preparing its run. Implement the planned offer and assert acquisition on a route that arrives from a fresh New Game. Evidence: [act-1.md:19](/home/homebox/Documents/rookmate/undertow/design/act-1.md:19), [weapon_defs.gd:18](/home/homebox/Documents/rookmate/undertow/core/weapon_defs.gd:18), [tideworks.txt:18](/home/homebox/Documents/rookmate/undertow/data/levels/tideworks.txt:18), [autopilot.gd:425](/home/homebox/Documents/rookmate/undertow/autoload/autopilot.gd:425).

6. **Medium: rebinding allows conflicts with retained secondary defaults.**

   Collision detection compares only another action’s primary binding, although `bindings_for()` retains arrow keys, J/K and d-pad defaults. Rebinding `move_left` to Right Arrow leaves Right Arrow on `move_right`; pressing it activates both directions and cancels movement. Rebinding Dodge to J similarly overlaps the retained primary-attack binding.

   Check collisions against the complete effective binding set. Because decision 89 requires secondary defaults to remain, some collisions need rejection or an explicit resolution policy rather than the current primary-only swap. Evidence: [controls.gd:15](/home/homebox/Documents/rookmate/undertow/autoload/controls.gd:15), [controls.gd:89](/home/homebox/Documents/rookmate/undertow/autoload/controls.gd:89), [controls.gd:118](/home/homebox/Documents/rookmate/undertow/autoload/controls.gd:118).

7. **Medium, conditional crash risks: persisted input and weapon data are insufficiently normalized.**

   Two concrete cases pass the current admission checks:

   - A saved pad-axis binding such as `["pad_axis", ["bad", 1.0]]` passes `_valid()` because only the nested array’s length is checked. Registration then assigns `"bad"` to the typed axis property, producing a runtime error during settings load.
   - A v2 save containing only `weapons_owned: ["signal_jammer"]` survives the “known weapon” filter. It owns no playable weapon, so the loadout resolves to an empty array and `_ready()` indexes `picked[0]`.

   Neither input arises from the current ordinary UI. They are nevertheless confirmed boundary failures relevant to damaged settings and future weapon/save changes. Validate binding element types and ranges; ensure loaded ownership contains at least one playable weapon; make empty loadouts safe. Evidence: [controls.gd:160](/home/homebox/Documents/rookmate/undertow/autoload/controls.gd:160), [controls.gd:229](/home/homebox/Documents/rookmate/undertow/autoload/controls.gd:229), [run_state.gd:147](/home/homebox/Documents/rookmate/undertow/core/run_state.gd:147), [loadout.gd:24](/home/homebox/Documents/rookmate/undertow/ui/loadout/loadout.gd:24).

8. **Medium, conditional content failures: catalog validation does not validate boss requirements.**

   Validation checks characters, IDs, reachability and Reliquary content, but not the relationship between the catalog’s boss and its required map markers. A Conductor map with no lane digits is accepted, then reaches `randi() % lanes.size()` with zero lanes. Missing `B` or an unsupported boss ID can leave already-created barriers permanently closed; missing `Z` silently removes the manual solution.

   The committed maps supply these elements. The defect is that the new content boundary accepts configurations that later crash or trap the player, which becomes increasingly costly as districts are added. Validate boss IDs, boss-marker counts, required weak points, lane geometry and barrier configuration before spawning. Evidence: [level_catalog.gd:107](/home/homebox/Documents/rookmate/undertow/core/level_catalog.gd:107), [level_grid.gd:102](/home/homebox/Documents/rookmate/undertow/core/level_grid.gd:102), [level.gd:471](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:471), [conductor.gd:68](/home/homebox/Documents/rookmate/undertow/game/bosses/conductor.gd:68).

9. **Medium, maintainability: the autopilot has become a district-specific monolith, and its prepared runs conceal progression omissions.**

   `autoload/autopilot.gd` grew from 715 to 1,348 lines. It combines argument handling, isolation, input, movement, combat, performance capture, screenshots, UI internals and district-specific routes. Core-choice and Ark dispatch branch on particular districts; their fallback assumes the Vellum. Adding another district requires editing shared control flow in several places.

   Split reusable driving/checking infrastructure from scenario modules, with explicit dispatch that rejects unsupported scenarios. Preserve the current checks and add one continuous New Game → Kestrel → Loop → Tideworks → Vellum route carrying the same run state, including a save/Continue boundary. The missing Gauntlet demonstrates the practical consequence of relying on prepared runs. Evidence: [autopilot.gd:415](/home/homebox/Documents/rookmate/undertow/autoload/autopilot.gd:415), [autopilot.gd:633](/home/homebox/Documents/rookmate/undertow/autoload/autopilot.gd:633), [autopilot.gd:671](/home/homebox/Documents/rookmate/undertow/autoload/autopilot.gd:671).

10. **Low: voiced narration and subtitle lifetime use different clocks.**

    Sound and its voice player process while paused. Subtitles inherit pausable processing and decrement their remaining duration using scaled `delta`. Pausing during speech lets the recording finish while the subtitle timer stops; slow motion also extends subtitle lifetime independently of the recording.

    Use a shared speech lifetime or consistent pause/time-scale behavior. Verify pause and perfect-dodge slow motion during a voiced line. Evidence: [sound.gd:92](/home/homebox/Documents/rookmate/undertow/autoload/sound.gd:92), [sound.gd:125](/home/homebox/Documents/rookmate/undertow/autoload/sound.gd:125), [subtitles.gd:37](/home/homebox/Documents/rookmate/undertow/ui/hud/subtitles.gd:37), [subtitles.gd:56](/home/homebox/Documents/rookmate/undertow/ui/hud/subtitles.gd:56).

11. **Low: stage 5 can silently skip every district tour and still report success.**

    District listing is embedded in a command substitution, stderr is discarded, and its exit status and nonempty output are never checked. A failed or timed-out listing produces no iterations without changing `status`. A read-only shell reproduction returned `listing_failure_status=0`.

    Capture and validate the listing before iterating, retain its diagnostics, and fail on an unsuccessful or empty result. The recorded milestone gate did run all four tours; this finding concerns the gate’s failure behavior. Evidence: [check.sh:83](/home/homebox/Documents/rookmate/undertow/tools/check.sh:83).

12. **Low: automated “default settings” do not reset the applied audio state.**

    Options loads and applies the player’s settings before Autopilot starts. `Options.use_path()` resets stored fields and bindings but does not apply the defaults to audio buses. Automated runs can therefore retain the player’s previously applied mute/volume settings while claiming default volumes. The test runner uses the same reset path.

    Apply the intended isolated defaults before execution, while respecting the recorded command-line display behavior. Evidence: [options.gd:21](/home/homebox/Documents/rookmate/undertow/autoload/options.gd:21), [options.gd:27](/home/homebox/Documents/rookmate/undertow/autoload/options.gd:27), [autopilot.gd:133](/home/homebox/Documents/rookmate/undertow/autoload/autopilot.gd:133), [test_runner.gd:44](/home/homebox/Documents/rookmate/undertow/tests/test_runner.gd:44).

13. **Low: option feedback does not consistently reflect bindings or persistence failures.**

    The introductory movement hint hardcodes `WASD`/`LEFT STICK`; its Dodge prompt refreshes only on device changes, so rebinding on the same device while paused can leave stale text. This violates decision 89’s requirement that prompts reflect current bindings.

    Separately, Options UI callers discard `save_settings()` errors. A failed write leaves the screen presenting a change that will disappear on restart, without telling the player. Add binding-change notification and show persistence failures through the existing notice pattern. Evidence: [level_hints.gd:43](/home/homebox/Documents/rookmate/undertow/ui/hud/level_hints.gd:43), [level_hints.gd:79](/home/homebox/Documents/rookmate/undertow/ui/hud/level_hints.gd:79), [options_screen.gd:194](/home/homebox/Documents/rookmate/undertow/ui/options/options_screen.gd:194).

Inferences and remaining validation gaps:

- The separate prepared routes establish substantial district coverage, but do not establish uninterrupted progression with accumulated cores, overrides, upgrades, survivors and ownership. Other carry-over failures are a risk, not a confirmed finding.
- Steam Deck, real controllers, Windows/macOS and milestone exports remain unverified. No platform-specific failure is established by this review.
- Voice and synthesized-audio quality require listening. Static inspection found matching coverage for all 139 Steward voice IDs, with no missing or stale manifest entries; that does not establish intelligibility, mix or characterization.
- I found no confirmed weakening of existing assertions, breach of the gold ownership rule, or newly introduced Steam calls outside its wrapper.

The recorded results are credible within their exercised paths: [tests.log:303](/home/homebox/Documents/rookmate/undertow/reports/check/tests.log:303), [full_slice.log:39](/home/homebox/Documents/rookmate/undertow/reports/check/full_slice.log:39), [full_loop.log:2189](/home/homebox/Documents/rookmate/undertow/reports/check/full_loop.log:2189), [full_tideworks.log:2232](/home/homebox/Documents/rookmate/undertow/reports/check/full_tideworks.log:2232), [full_vellum.log:60](/home/homebox/Documents/rookmate/undertow/reports/check/full_vellum.log:60).
## Round 1 fixes (Claude Code)

Round 2 found findings 6 and 8 only partly fixed, and three problems introduced by these fixes; see
"Round 2 findings" and "Round 2 fixes" below. Decisions 111–121 record the new rules.

1. **Friendly Lamplighters as targets (High).** Fixed. `Enemy.is_hittable()` and `Enemy.steward_will_aim()`
   are now the only places that decide combat eligibility. `Level.hittable_enemies()` feeds every hit
   query (projectiles, the baton's arc, the gauntlet's pulse, tuned targeting).
   `Level.steward_targets()` feeds tuned selection and aim assist. A Lamplighter is hittable only
   while it hunts, and it's a threat only then. New tests swing the baton (tuned and manual) at a lamp
   a tile away: nothing lands while the Steward listens, and muted the hit lands. Both tests fail on
   the old code.

   Running the campaign showed what the old bug had been covering for: the autopilot's Kestrel route
   had been "fighting" friendly lamps. It now only fights things that are hittable and are threats.
2. **Aim assist bent toward weak points.** Fixed. `Operator.aim_ground()` is now
   `assisted_aim(raw_aim())`, and assistance considers only `steward_targets()`. A new test checks
   against the raw aim: 8° beside the signal box stays 8° beside it, while an ordinary machine in the
   same place pulls it in.
3. **Weapon swaps disconnected profiling and reset state.** Fixed. `take_weapon` and `add_weapon` now
   remove or add only the affected node; the other weapon keeps its node and state and moves up a slot
   if it has to. `StewardWatch` listens to `Operator.weapon_fired`, which survives swaps. A new test
   covers a find, a snatch and a return, then fires both weapons and checks they're profiled.
4. **Standing orders didn't govern all speech.** Fixed. Every line now has a purpose: fact, warning or
   praise.
   - Pool events carry it in `steward_lines.json`, fixed lines in `steward_fixed.json`, and both are
     validated.
   - `Narrator.allows()` is the one gate. Boss callouts, find lines, the Waiting's refusal, Workshop
     replies, override replies and screen voice-overs all pass through it.
   - Track, drop and swing calls are warnings, so "Never warn me about traps" silences them. The
     "workshop_tuned" reply is praise.
   - Three override replies that flattered were rewritten as facts, including the "Stop praising me"
     reply itself, and re-voiced.
   - New tests cover every warning callout with the order signed, a crane fight in silence, praise
     against facts, and validation of fixed lines.
5. **No Defib Gauntlet from a fresh run.** Fixed. The Gauntlet now lies on a crash cart on the Vellum's
   old quay, down the stair and off the Lattice, with a place hint and a voiced Steward line.
   - The Vellum's prepared autopilot run no longer hands out every weapon: it carries only the Riot
     Drone the Tideworks gives.
   - The Vellum route picks the Gauntlet up (`gauntlet_found`).
   - A fresh-run test finds it, and the campaign reaches it from New Game.
6. **Rebinding against kept defaults.** Fixed. `Controls.blocker_for()` checks the whole effective
   binding set. Taking another rebindable action's primary still swaps; any other collision is refused,
   and the Options screen names the keeper. `Controls.conflicts()` is empty for the shipped bindings,
   after swaps, and after loading.
7. **Normalization holes.** Fixed.
   - `Controls.normalized()` checks kinds, codes, axis ids and ±1 directions. Saved bindings that are
     malformed or clash are dropped quietly.
   - `RunState.from_dict` adds the starting tools back if a save owns nothing playable.
   - The loadout screen no longer indexes an empty pick.
8. **Boss requirements unvalidated.** Fixed. `LevelCatalog.boss_problems()` runs in `check()` (at boot
   and in tests) and in `Level._ready`, where a failure refuses the level before any barrier is built.
   Unit tests cover each bad case, and a laneless Conductor fixture shows the level refusing to load.
9. **Autopilot monolith; prepared runs hid omissions.** Fixed.
   - `autoload/autopilot.gd` (511 lines) is now only infrastructure. Scenarios live in
     `autoload/autopilot/scenarios/`, one route per district in `autoload/autopilot/routes/`.
   - Dispatch is explicit: an unknown scenario or a district without a route is refused, and a unit
     test fails while a district in `LevelCatalog` has no route.
   - The new `campaign` scenario plays one run from New Game through Kestrel Heights, the Loop (signing
     an order it keeps), save and return to title, Continue (the progress must match), the Tideworks
     and the Vellum to the Archive. Every district's checks are tagged with the district's name.
   - It is the gate's long run now; the prepared runs remain for working on one district.
10. **Voice and subtitle clocks.** Fixed. Subtitles keep processing while paused and count real
    seconds. A test pauses and then slows time during a voiced line.
11. **Stage 5 passed silently on a bad listing.** Fixed. The listing goes to `districts.log`. Its exit
    status, its problem lines and its count (now printed last) are all checked. Tested against a stand-in
    `godot` that fails, lists nothing, or lists only part.
12. **Default volumes not applied in automated runs.** Fixed. `Options.reset_all()`, which
    `use_path()` calls, puts the default volumes on the buses at once. Tested.
13. **Option feedback.** Fixed. The hint bar reads the four move bindings (`Controls.move_prompt()`)
    and refreshes on `Controls.bindings_changed`, as do the loadout slot headers. The Options screen
    shows one save-failure notice if writing the settings fails. Both are tested.

Also fixed, found in the campaign's screenshots: the run summary drew over the Loop map on a
translucent backing at the same layer, so the map's labels showed through its text. It's now opaque and
one layer above, and tested.

Not verified here (needs hardware or ears): the Steam Deck, real controllers, Windows and macOS
builds, and how the voice and synthesized audio sound.

## Round 2 findings (verbatim from sol_analyst)

I would keep milestone 2 open. **Eleven findings are fixed; findings 6 and 8 are partly fixed.** The campaign also weakens an existing gate assertion, and some regression tests fall short of the requested behaviour coverage.

I reviewed `git diff e244859`, the untracked modules and fixtures, the design sources, and the tests. I made no edits. I did not rely on `reports/check/` or rerun commands that write imports, logs, settings or saves. “Fixed” below describes the implementation; it does not claim a fresh Godot test pass.

1. **Fixed: friendly Lamplighters as combat targets.** `Lamplighter.is_hittable()` requires hunting, and `is_threat` now follows hunting. Projectile collisions and melee queries use the filtered enemy list; Steward targeting and assistance respect eligibility. The new tests execute tuned and manual baton swings and check actual damage, including a muted positive case. Evidence: [lamplighter.gd:56](/home/homebox/Documents/rookmate/undertow/game/enemies/lamplighter.gd:56), [level.gd:199](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:199), [projectile.gd:46](/home/homebox/Documents/rookmate/undertow/game/weapons/projectile.gd:46), [test_kestrel.gd:75](/home/homebox/Documents/rookmate/undertow/tests/integration/test_kestrel.gd:75).

2. **Fixed: aim assistance toward boss weak points.** Assistance now considers `steward_targets()`, which excludes weak points through `steward_will_aim()`. The new test compares an eight-degree raw direction against assisted output and adds an ordinary enemy as a positive control. This catches the original forbidden pull without using already-assisted aim as the expected value. Evidence: [operator.gd:255](/home/homebox/Documents/rookmate/undertow/game/player/operator.gd:255), [enemy.gd:65](/home/homebox/Documents/rookmate/undertow/game/enemies/enemy.gd:65), [test_bosses.gd:110](/home/homebox/Documents/rookmate/undertow/tests/integration/test_bosses.gd:110).

3. **Fixed, with incomplete regression coverage: weapon lifecycle and profiling.** Adding and taking weapons now affect only the relevant node. Remaining nodes retain their state, and firing reaches `StewardWatch` through the stable Operator signal. The new test checks node identity, an in-progress baton swing, slot reassignment and profiling after return. However, its newly acquired Drone “fires” through a direct `announce_fired()` call; it does not create a shot. See the validation gaps below. Evidence: [operator.gd:88](/home/homebox/Documents/rookmate/undertow/game/player/operator.gd:88), [operator.gd:111](/home/homebox/Documents/rookmate/undertow/game/player/operator.gd:111), [steward_watch.gd:31](/home/homebox/Documents/rookmate/undertow/game/level/steward_watch.gd:31), [test_tideworks.gd:68](/home/homebox/Documents/rookmate/undertow/tests/integration/test_tideworks.gd:68).

4. **Fixed for the production speech paths: standing orders.** Boss calls, finds, Waiting refusals and Workshop replies now use purpose-aware fixed narration. The warning calls are classified as warnings, the tuned Workshop reply as praise, and the three flattering override replies have been rewritten. Tests cover purpose policy and an actual Crane encounter with warnings forbidden. The public narration APIs still have a maintenance weakness described below. Evidence: [narrator.gd:84](/home/homebox/Documents/rookmate/undertow/autoload/narrator.gd:84), [boss.gd:89](/home/homebox/Documents/rookmate/undertow/game/bosses/boss.gd:89), [workshop_screen.gd:98](/home/homebox/Documents/rookmate/undertow/ui/ark/workshop_screen.gd:98), [test_overrides.gd:95](/home/homebox/Documents/rookmate/undertow/tests/integration/test_overrides.gd:95).

5. **Fixed: the missing Vellum Gauntlet.** The map places a real weapon find at `17,22`, on the unindexed old quay. The fresh-run test acquires it through `WeaponFind.interact()`. The prepared Vellum route supplies only the previous district’s Drone, and the campaign reaches the Gauntlet through movement and interaction without preparing or granting a replacement run. Evidence: [vellum_street.txt:30](/home/homebox/Documents/rookmate/undertow/data/levels/vellum_street.txt:30), [vellum_route.gd:40](/home/homebox/Documents/rookmate/undertow/autoload/autopilot/routes/vellum_route.gd:40), [vellum_route.gd:164](/home/homebox/Documents/rookmate/undertow/autoload/autopilot/routes/vellum_route.gd:164), [test_weapons.gd:187](/home/homebox/Documents/rookmate/undertow/tests/integration/test_weapons.gd:187).

6. **Partly fixed: binding conflicts with retained defaults.** Ordinary attempts to take another action’s secondary binding are refused. But the swap exception incorrectly permits a primary binding that is also retained as a secondary default. A two-step rebind still creates opposite movement actions on the same key. The new tests omit this sequence. Evidence: [controls.gd:92](/home/homebox/Documents/rookmate/undertow/autoload/controls.gd:92), [controls.gd:123](/home/homebox/Documents/rookmate/undertow/autoload/controls.gd:123), [controls.gd:142](/home/homebox/Documents/rookmate/undertow/autoload/controls.gd:142), [test_options.gd:99](/home/homebox/Documents/rookmate/undertow/tests/integration/test_options.gd:99).

7. **Fixed: the two persisted-data crash cases.** Binding normalization checks axis element types, axis ranges and directions before constructing input events. A save owning only the unplayable Signal Jammer receives the Baton, and the loadout’s empty-pick indexing is guarded. Tests exercise malformed bindings through registration and confirm a usable loadout from the Signal-Jammer-only save. Evidence: [controls.gd:187](/home/homebox/Documents/rookmate/undertow/autoload/controls.gd:187), [controls.gd:215](/home/homebox/Documents/rookmate/undertow/autoload/controls.gd:215), [run_state.gd:147](/home/homebox/Documents/rookmate/undertow/core/run_state.gd:147), [loadout.gd:29](/home/homebox/Documents/rookmate/undertow/ui/loadout/loadout.gd:29), [test_run_state.gd:96](/home/homebox/Documents/rookmate/undertow/tests/unit/test_run_state.gd:96).

8. **Partly fixed: boss content validation.** Unsupported boss IDs, missing or duplicate boss/weak-point markers, missing lanes, singleton lanes and boss markers on bossless maps are rejected before spawning. The laneless fixture exercises actual level refusal. However, the requested lane geometry and barrier configuration validation are absent. Maps can still pass while their boss and weak point are inaccessible and a barrier permanently blocks progression. Evidence: [level_catalog.gd:137](/home/homebox/Documents/rookmate/undertow/core/level_catalog.gd:137), [level.gd:54](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:54), [test_level_catalog.gd:50](/home/homebox/Documents/rookmate/undertow/tests/unit/test_level_catalog.gd:50), [test_modals_and_routing.gd:98](/home/homebox/Documents/rookmate/undertow/tests/integration/test_modals_and_routing.gd:98).

9. **Fixed structurally and for continuous progression, with a gate regression.** The infrastructure file is now 511 lines, with separate scenario and district route modules. Dispatch rejects unsupported scenario names. The campaign starts through New Game, carries one run through all four districts, signs an order, saves through the pause menu, Continues and compares accumulated progress. Route checks are tagged by district. The old prepared-route check lists are preserved, but the default campaign disables an existing ending assertion. Evidence: [autopilot.gd:111](/home/homebox/Documents/rookmate/undertow/autoload/autopilot.gd:111), [campaign.gd:31](/home/homebox/Documents/rookmate/undertow/autoload/autopilot/scenarios/campaign.gd:31), [campaign.gd:66](/home/homebox/Documents/rookmate/undertow/autoload/autopilot/scenarios/campaign.gd:66), [campaign.gd:95](/home/homebox/Documents/rookmate/undertow/autoload/autopilot/scenarios/campaign.gd:95), [test_autopilot.gd:18](/home/homebox/Documents/rookmate/undertow/tests/unit/test_autopilot.gd:18).

10. **Fixed for pause and slow-motion timing, with limited audio verification.** Subtitles process while paused and divide scaled delta by the time scale. The new test exercises both conditions and would catch the old timer behaviour. It checks the subtitle timer, however, rather than synchronization with an advancing recording. Evidence: [subtitles.gd:17](/home/homebox/Documents/rookmate/undertow/ui/hud/subtitles.gd:17), [subtitles.gd:58](/home/homebox/Documents/rookmate/undertow/ui/hud/subtitles.gd:58), [test_voice.gd:80](/home/homebox/Documents/rookmate/undertow/tests/integration/test_voice.gd:80).

11. **Fixed: silent skipping of district tours.** Stage 5 captures diagnostics and checks the listing command’s exit status, nonempty output, final count and problem lines. The producer prints its count last. A read-only execution of the guard expressions rejected failed, empty, truncated and count-mismatched listings and accepted a complete four-district listing. There is no retained regression harness for this failure behaviour. Evidence: [check.sh:86](/home/homebox/Documents/rookmate/undertow/tools/check.sh:86), [autopilot.gd:59](/home/homebox/Documents/rookmate/undertow/autoload/autopilot.gd:59).

12. **Fixed: isolated defaults now affect audio buses.** `use_path()` calls `reset_all()`, which applies default volumes immediately while leaving display application to the existing display policy. The new test first changes actual bus volumes and then verifies the applied defaults. Evidence: [options.gd:27](/home/homebox/Documents/rookmate/undertow/autoload/options.gd:27), [options.gd:35](/home/homebox/Documents/rookmate/undertow/autoload/options.gd:35), [test_options.gd:49](/home/homebox/Documents/rookmate/undertow/tests/integration/test_options.gd:49).

13. **Fixed: stale prompts and silent settings-save failures.** Binding registration emits a change signal. Movement hints read current bindings, and hint/slot headers subscribe to binding changes. All Options save callers now use the error-reporting helper. Tests check rendered hint text after same-device rebinding and a single notice after failed persistence. Evidence: [controls.gd:80](/home/homebox/Documents/rookmate/undertow/autoload/controls.gd:80), [level_hints.gd:43](/home/homebox/Documents/rookmate/undertow/ui/hud/level_hints.gd:43), [options_screen.gd:210](/home/homebox/Documents/rookmate/undertow/ui/options/options_screen.gd:210), [test_options.gd:148](/home/homebox/Documents/rookmate/undertow/tests/integration/test_options.gd:148).

The remaining problems and the regressions introduced by this round are:

- **Medium, remaining gameplay bug: a permitted swap still creates a binding conflict.** Starting from defaults, bind Move Up to Up Arrow, then bind Move Down to Up Arrow. Both operations succeed. Move Up receives `S` as its primary but retains Up Arrow as its secondary; Move Down receives Up Arrow as its primary. Pressing Up Arrow therefore activates both directions. I confirmed the resulting binding sets with a read-only transcription of the source’s binding/swap logic, not a Godot runtime reproduction. The cause is the exemption at [controls.gd:148](/home/homebox/Documents/rookmate/undertow/autoload/controls.gd:148): matching the primary does not establish that replacing it releases the input. Validate the complete prospective binding sets before committing a swap, and add this sequence for keyboard and d-pad inputs.

- **Medium, remaining content-boundary failure: boss counts do not establish a playable fight.** `boss_problems()` never checks lane contiguity or straightness, boss/weak-point accessibility, or accessibility with barriers closed. `LevelGrid.validate()` treats `y` as walkable during its Reliquary reachability check, although the spawned barrier is solid. An in-memory reproduction of these predicates accepted a Crane map with a Reliquary behind a corridor barrier and the boss/weak point in an isolated chamber eleven rows below. The boss cannot engage or be struck, so the barrier cannot open. This is a conditional content failure; the shipped maps are not shown to have it. Evidence: [level_catalog.gd:140](/home/homebox/Documents/rookmate/undertow/core/level_catalog.gd:140), [level_grid.gd:128](/home/homebox/Documents/rookmate/undertow/core/level_grid.gd:128), [boss_barrier.gd:13](/home/homebox/Documents/rookmate/undertow/game/bosses/boss_barrier.gd:13), [shunt_lane.gd:67](/home/homebox/Documents/rookmate/undertow/game/bosses/shunt_lane.gd:67). Add independent geometry/access checks and fixtures that demonstrate refusal.

- **Medium, introduced validation regression: the default gate drops the Rewrite-locked assertion.** The campaign sets `expect_rewrite_locked` to false at [campaign.gd:28](/home/homebox/Documents/rookmate/undertow/autoload/autopilot/scenarios/campaign.gd:28). Its final check then compares `rewrite` with the same checklist expression used to calculate `rewrite` inside `EndingRules`. That comparison cannot establish that the ending remains locked. This campaign carries one truth core from each of four districts; the current threshold is five. It therefore has a concrete reason to retain the old locked assertion. Evidence: [vellum_route.gd:249](/home/homebox/Documents/rookmate/undertow/autoload/autopilot/routes/vellum_route.gd:249), [ending_rules.gd:39](/home/homebox/Documents/rookmate/undertow/core/ending_rules.gd:39), [tunables.gd:15](/home/homebox/Documents/rookmate/undertow/core/tunables.gd:15). Restore that assertion in the campaign or preserve an equally substantive check elsewhere in the default gate.

- **Low, introduced maintainability weakness: narration purpose is optional at the public boundary.** `speak_text()` and `voice_over()` default to “fact”, even for an ID whose metadata says warning or praise. For example, `voice_over("workshop_tuned")` passes the no-praise policy unless the caller supplies the praise argument. Current production fixed-line callers use the correct path, so this is not a newly established gameplay violation. But every future caller must remember which API or argument preserves the order. Resolve known IDs’ purposes centrally and require an explicit purpose for ad-hoc text. Evidence: [narrator.gd:98](/home/homebox/Documents/rookmate/undertow/autoload/narrator.gd:98), [narrator.gd:115](/home/homebox/Documents/rookmate/undertow/autoload/narrator.gd:115), [test_overrides.gd:105](/home/homebox/Documents/rookmate/undertow/tests/integration/test_overrides.gd:105).

- **Regression coverage still misses requested behaviour.** The weapon lifecycle test should acquire through the find, snatch/recover through the Salvager and produce actual attacks followed by profile/commentary assertions. The new test currently synthesizes the Drone’s firing signal. The no-praise test should buy a tuned Workshop upgrade through the real screen with the order signed; directly testing `say_fixed()` would not catch a Workshop caller reverting to the unrestricted default-purpose route. The subtitle test runs under the headless gate, where `Sound.audible` is false and recordings are not started; it verifies timer processing, not actual audio synchronization or a perfect-dodge transition. Stage 5’s failure tests also need a retained harness rather than only the reported one-off stand-in run. Evidence: [test_tideworks.gd:74](/home/homebox/Documents/rookmate/undertow/tests/integration/test_tideworks.gd:74), [test_overrides.gd:103](/home/homebox/Documents/rookmate/undertow/tests/integration/test_overrides.gd:103), [sound.gd:72](/home/homebox/Documents/rookmate/undertow/autoload/sound.gd:72), [sound.gd:222](/home/homebox/Documents/rookmate/undertow/autoload/sound.gd:222).

The read-only checks found **291 → 313 test methods, with none removed**. The prepared routes preserve every previous required check name, with `gauntlet_found` added. Gate stages 1–3 and the per-tour exit/result/error scans remain intact; stage 4 defaults to the campaign as requested. `bash -n tools/check.sh` and `git diff e244859 --check` passed. All **140** voice IDs have clips and matching manifest text, with no orphan manifest entries.

The run-summary opacity/layer fix is present and covered by the new assertions. Decisions 111–121 and the revised workflow documentation are present. I found no new Steam-wrapper breach or Steward-gold misuse.

The claim in `reviews/act-1.md` that every finding is fixed should be corrected until findings 6 and 8 are completed. A fresh full-gate result, Steam Deck/controller/platform testing and listening validation remain unverified by this review.
## Round 2 fixes (Claude Code)

- **Finding 6, the swap that still shared a key.** `Controls.blocker_for()` now tries the swap on the
  choices, checks `conflicts()` on the result, and puts the choices back; a swap that would leave an
  input on two actions is refused. A new test plays the reported sequence (Move Up to Up Arrow, then
  Move Down to Up Arrow) on the keyboard and on the d-pad; it fails on the round 1 code.
- **Finding 8, a fight you can't reach.** `LevelGrid.reachable_from()` can treat map characters as shut.
  `boss_problems()` now requires each lane to be one straight, unbroken track, and the boss and its weak
  point to be reachable from the start with the barriers shut. New unit cases: the sealed Crane chamber
  Sol described, a barrier across the only way to the boss, and a Conductor lane broken in two and bent.
- **The campaign's ending check.** Restored. The Vellum route always checks
  `endings_offered_with_rewrite_locked` (Reboot and Unplug offered, Rewrite locked), in the campaign
  too: Act 1 and the Vellum give four truth cores at most, one short.
- **Optional purpose at the narration boundary.** `VoiceLines.purpose_of(id)` gives every Steward line's
  purpose: fixed lines their own, pooled lines their event's, core and log comments and order replies
  "fact". `Narrator.speak_text()` judges one of the Steward's own lines by that, whatever the caller
  passes. Its purpose argument is now required, and only counts for text that isn't one of the lines.
  `voice_over(id)` takes no purpose and reports an id that isn't a line. Tests: a praise line called a
  fact is still silenced, and every line has a purpose.
- **Regression coverage.**
  - The weapon test now uses real presses: Interact at a find, the drone's trigger producing real shots,
    a Salvager left to come and take the drone by itself, beaten, and the drone fired again. It checks
    profiling and the Steward's manual-weapon remark.
  - A new Workshop test presses the screen's rows with "Stop praising me" signed: no praise is said or
    shown, and the plain remark still comes.
  - Subtitles now share the voice's own clock. `Sound.voice_left()` uses the recording's position, or
    with no audio device the same real-time advance. The test checks the text's remaining time equals
    the voice's plus the fade through a pause, and through slowed time from a real perfect dodge (a blow
    evaded mid-roll).
  - The listing check moved to `tools/district_listing.sh`. Its kept test, `tools/test_district_listing.sh`
    (error exit, time-out, nothing, cut short, too few, no count, good), runs in the gate before the tours.
- **Found by the gate: a leak at exit.** A Vellum tour leaked eight objects. With `--verbose` they were
  the playbacks of the respawn cue and the Steward's respawn line, started inside the 0.15 s quit window
  after everything had been silenced. Once quitting, `Sound.closing` stops any new cue, line or
  ambience. Tested.

The review file's claim that every finding was fixed in round 1 has been corrected above.

## Round 3 findings (verbatim from sol_analyst)

**All 13 round 1 implementation findings now stand fixed.** The round 2 code and gate defects are resolved. Its regression-coverage item is **partly resolved**, because the headless audio test still does not exercise an advancing recording through a real audio driver.

I found no new confirmed gameplay bug, crash risk, brief or design violation, or worsening maintainability problem in the current fixes, including decision 122’s `Sound.closing` guard.

I reviewed `git diff e244859`, the untracked files, the review record and the design sources. I made no edits and did not use `reports/check/`. The reported 317-test pass remains supplied evidence; I did not rerun Godot commands that write imports, saves or settings.

The round 2 items now have these statuses:

| Item | Status | Primary evidence |
|---|---|---|
| Finding 6: swapping a primary that also remains a secondary default | **Resolved** | `blocker_for()` applies the prospective swap to the choices, checks the complete effective binding sets, then restores the original choices. The reported two-step sequence is rejected for both keyboard and d-pad. [controls.gd:143](/home/homebox/Documents/rookmate/undertow/autoload/controls.gd:143), [test_options.gd:116](/home/homebox/Documents/rookmate/undertow/tests/integration/test_options.gd:116). |
| Finding 8: unreachable fights and malformed lanes | **Resolved** | Each lane must be straight and contiguous. Boss and weak-point accessibility is checked with `y` barriers closed. Tests reject the sealed Crane chamber, a barrier across the only approach, and broken/bent Conductor lanes. The Level performs this validation before spawning anything. [level_catalog.gd:139](/home/homebox/Documents/rookmate/undertow/core/level_catalog.gd:139), [test_level_catalog.gd:69](/home/homebox/Documents/rookmate/undertow/tests/unit/test_level_catalog.gd:69), [level.gd:54](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:54). |
| Weakened campaign ending assertion | **Resolved** | The conditional escape is gone. The Vellum route always requires Reboot and Unplug to be offered, Rewrite to remain locked, and three checklist entries. The campaign registers that route’s complete checks. [vellum_route.gd:240](/home/homebox/Documents/rookmate/undertow/autoload/autopilot/routes/vellum_route.gd:240), [campaign.gd:30](/home/homebox/Documents/rookmate/undertow/autoload/autopilot/scenarios/campaign.gd:30). |
| Optional narration purpose at the public boundary | **Resolved** | Known IDs resolve their purpose centrally. `speak_text()` requires an explicit purpose for ad-hoc text, and a caller cannot reclassify a known praise line as fact. `voice_over()` accepts only a known ID and uses its recorded purpose. Tests cover attempted misclassification and unknown IDs. [voice_lines.gd:49](/home/homebox/Documents/rookmate/undertow/core/voice_lines.gd:49), [narrator.gd:100](/home/homebox/Documents/rookmate/undertow/autoload/narrator.gd:100), [test_overrides.gd:95](/home/homebox/Documents/rookmate/undertow/tests/integration/test_overrides.gd:95). |
| Regression-coverage gaps | **Partly resolved** | Weapon acquisition, firing, autonomous snatching, recovery and profiling now run through production behaviour. Workshop purchases use the real screen buttons. The listing failure harness is retained and invoked by the gate. The subtitle test now performs a real perfect-dodge transition and checks the shared voice clock, but headless execution exercises Sound’s simulated clock rather than actual recording playback. |

The coverage changes are substantive:

- The weapon lifecycle test presses Interact at a find, produces actual Drone projectiles, lets a Salvager approach and steal the Drone, recovers it through the Salvager’s death path, then fires again. It checks retained Baton identity/state, profiling and manual-weapon commentary. [test_tideworks.gd:69](/home/homebox/Documents/rookmate/undertow/tests/integration/test_tideworks.gd:69).
- The Workshop test presses tuned and manual purchase buttons with “Stop praising me” signed. It checks both spoken and displayed replies, with the manual reply as a positive control. [test_workshop.gd:88](/home/homebox/Documents/rookmate/undertow/tests/integration/test_workshop.gd:88).
- The subtitle test pauses, starts a dodge, delivers a hit during its invulnerability, confirms slow motion and checks voice/subtitle timing through completion. The remaining limitation is the actual audio branch: `voice_left()` uses playback position only when `audible` is true; the headless test advances `_voice_at`. A retained test using a real audio driver or Movie Maker would complete that coverage. [test_voice.gd:82](/home/homebox/Documents/rookmate/undertow/tests/integration/test_voice.gd:82), [sound.gd:249](/home/homebox/Documents/rookmate/undertow/autoload/sound.gd:249), [sound.gd:307](/home/homebox/Documents/rookmate/undertow/autoload/sound.gd:307).
- The listing harness retains good, failed, timed-out, empty, truncated, count-mismatched and count-missing cases. I independently exercised the actual parser against those seven inputs using anonymous memory-backed logs; all produced the expected results. [test_district_listing.sh:17](/home/homebox/Documents/rookmate/undertow/tools/test_district_listing.sh:17), [check.sh:89](/home/homebox/Documents/rookmate/undertow/tools/check.sh:89).

All round 1 findings now stand as follows:

| # | Finding | Status and evidence |
|---|---|---|
| 1 | Friendly Lamplighters remain combat targets | **Fixed.** Hittability follows hunting; melee/projectile queries and Steward targeting respect it. Tuned/manual swings have friendly and muted cases. [lamplighter.gd:56](/home/homebox/Documents/rookmate/undertow/game/enemies/lamplighter.gd:56), [test_kestrel.gd:109](/home/homebox/Documents/rookmate/undertow/tests/integration/test_kestrel.gd:109). |
| 2 | Aim assistance targets boss weak points | **Fixed.** Assistance uses `steward_targets()`. The test compares against raw aim and includes an ordinary enemy as a positive control. [operator.gd:256](/home/homebox/Documents/rookmate/undertow/game/player/operator.gd:256), [test_bosses.gd:110](/home/homebox/Documents/rookmate/undertow/tests/integration/test_bosses.gd:110). |
| 3 | Weapon changes disconnect profiling and reset unaffected weapons | **Fixed.** Only the affected node changes; the stable Operator firing signal reaches `StewardWatch`. The behaviour test now covers actual firing after acquisition and recovery. [operator.gd:111](/home/homebox/Documents/rookmate/undertow/game/player/operator.gd:111), [steward_watch.gd:31](/home/homebox/Documents/rookmate/undertow/game/level/steward_watch.gd:31). |
| 4 | Standing orders do not govern all speech | **Fixed.** Boss calls and Workshop replies use purpose-aware narration; known public-boundary calls cannot bypass their purpose. Actual Crane and Workshop tests cover forbidden warnings/praise. [boss.gd:89](/home/homebox/Documents/rookmate/undertow/game/bosses/boss.gd:89), [workshop_screen.gd:98](/home/homebox/Documents/rookmate/undertow/ui/ark/workshop_screen.gd:98). |
| 5 | Fresh runs cannot obtain the Vellum Gauntlet | **Fixed.** A production find exists on the old quay. Fresh-run acquisition is tested, and the campaign reaches it without a prepared grant. [test_weapons.gd:187](/home/homebox/Documents/rookmate/undertow/tests/integration/test_weapons.gd:187), [vellum_route.gd:155](/home/homebox/Documents/rookmate/undertow/autoload/autopilot/routes/vellum_route.gd:155). |
| 6 | Rebinding conflicts with retained defaults | **Fixed.** Complete prospective binding sets govern swaps, including the previously missed duplicate-default sequence. [controls.gd:143](/home/homebox/Documents/rookmate/undertow/autoload/controls.gd:143). |
| 7 | Malformed persisted input/weapon data can crash | **Fixed.** Bindings are normalized before event construction; ownership without a playable weapon receives starting tools; empty loadout indexing is guarded. [controls.gd:223](/home/homebox/Documents/rookmate/undertow/autoload/controls.gd:223), [run_state.gd:147](/home/homebox/Documents/rookmate/undertow/core/run_state.gd:147), [loadout.gd:29](/home/homebox/Documents/rookmate/undertow/ui/loadout/loadout.gd:29). |
| 8 | Catalog accepts impossible boss configurations | **Fixed.** IDs, marker counts, lane counts/geometry and access with barriers closed are checked before spawning. [level_catalog.gd:139](/home/homebox/Documents/rookmate/undertow/core/level_catalog.gd:139). |
| 9 | Autopilot monolith and prepared runs conceal progression omissions | **Fixed.** Infrastructure, scenarios and district routes are separated. The campaign uses New Game, continuous progression and a save/Continue comparison. Infrastructure is 511 lines. [campaign.gd:39](/home/homebox/Documents/rookmate/undertow/autoload/autopilot/scenarios/campaign.gd:39), [campaign.gd:65](/home/homebox/Documents/rookmate/undertow/autoload/autopilot/scenarios/campaign.gd:65). |
| 10 | Subtitle and voice clocks diverge during pause/slow motion | **Fixed in implementation.** Subtitles process while paused and follow Sound’s voice clock, with a reading-time floor and fade. Live recording verification remains partial as explained above. [subtitles.gd:24](/home/homebox/Documents/rookmate/undertow/ui/hud/subtitles.gd:24), [subtitles.gd:76](/home/homebox/Documents/rookmate/undertow/ui/hud/subtitles.gd:76). |
| 11 | Stage 5 silently skips tours after a bad listing | **Fixed.** Listing exit status, nonempty output and count are validated; diagnostics are scanned; the retained failure harness runs before tours. [check.sh:86](/home/homebox/Documents/rookmate/undertow/tools/check.sh:86). |
| 12 | Automated defaults do not reset applied audio state | **Fixed.** Reset applies default bus volumes immediately, and the test changes actual volumes before checking the reset. [options.gd:35](/home/homebox/Documents/rookmate/undertow/autoload/options.gd:35), [test_options.gd:49](/home/homebox/Documents/rookmate/undertow/tests/integration/test_options.gd:49). |
| 13 | Stale binding prompts and silent settings-save failures | **Fixed.** Binding changes refresh hints and slot headers; Options saves use the failure-notice helper. Rendered prompts and notice deduplication are tested. [test_options.gd:161](/home/homebox/Documents/rookmate/undertow/tests/integration/test_options.gd:161), [options_screen.gd:210](/home/homebox/Documents/rookmate/undertow/ui/options/options_screen.gd:210). |

The shutdown guard addresses the reported race directly. `quit()` sets `closing` **before** silencing players and awaiting the 0.15-second audio-thread window. Cue, voice and both ambience entry points return before loading or starting anything. Silencing also zeroes current and target ambience levels, so `_process()` cannot restart those layers during the window. I found no alternative direct game quit path bypassing Sound. The regression test exercises attempted respawn cue, voice and ambience starts while closing; it does not reproduce an actual audio-thread leak. [sound.gd:150](/home/homebox/Documents/rookmate/undertow/autoload/sound.gd:150), [sound.gd:175](/home/homebox/Documents/rookmate/undertow/autoload/sound.gd:175), [sound.gd:218](/home/homebox/Documents/rookmate/undertow/autoload/sound.gd:218), [test_audio.gd:131](/home/homebox/Documents/rookmate/undertow/tests/integration/test_audio.gd:131).

The gate retains all prior required district check names: Kestrel 24, Loop 20, Tideworks 19, and Vellum 42 plus `gauntlet_found`. The campaign registers them with district prefixes. Import/test/run exit checks, passing-result requirements and error/warning scans remain enforced. I found **291 → 317 test methods, with none removed**, and no newly skipped tests. All 140 voice IDs have clips and matching manifest text.

Shell syntax checks passed. One minor cleanup remains: `git diff e244859 --check` exits **2** for added blank lines at EOF in `DECISIONS.md:405`, `tests/integration/test_audio.gd:143` and `tests/unit/test_level_catalog.gd:80`.

The final full-gate result, actual shutdown leak absence, Steam Deck/controllers, Windows/macOS and listening validation remain unverified by this review.
## Round 3 fixes (Claude Code)

- **Real-audio coverage of the voice clock.** The Vellum route now has `subtitles_keep_the_voice`.
  Mid-line, it opens the pause menu for a second and measures, against real elapsed time, that the
  recording and its subtitle both advanced, and that the subtitle doesn't end before the voice. It runs
  in every Vellum run, the gate's campaign included, and those are windowed with the machine's real audio
  driver. Measured: 0.99 s real, voice 0.99 s, text 1.01 s, audible.
- **Blank lines at the end of three files.** Removed; `git diff --check` is clean.
- **Found while adding that check:** with a route script that failed to load, the autopilot still
  printed PASS with only the title checks; the gate would have failed it only on the error lines.
  Scenarios now report `problem()`, and a scenario whose route doesn't load is refused
  (`AUTOPILOT FAIL: scenario_ready`). This was verified by breaking a route temporarily, and the unit
  test requires every scenario to be ready.

- **Found while recording the progress video:** that check first measured wall-clock time. Movie Maker
  renders slower than real time, so it failed there (2.25 s wall clock, against 1.02 s for both voice
  and text), although voice and text were in step on the movie's own clock. It now measures against the
  autopilot's unscaled run clock (`Autopilot.run_seconds()`): real time live, movie time when recording.
  It passes both ways (live: 1.01 s run, voice 0.98 s, text 1.00 s; recorded: 1.03 s, 1.04 s, 1.04 s).

Milestone closed: all 13 findings fixed and confirmed by sol_analyst; the gate passes (see PROGRESS.md).
