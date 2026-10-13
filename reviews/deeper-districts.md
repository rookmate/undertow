# Milestone review: deeper districts, harder bosses (milestone 5)

Reviewer: **sol_analyst** (Sol 6.1, xhigh, read-only) via the "Sol analysis" skill, run through
`codex exec -s read-only`. Scope: `git diff 4bef46f` against the working tree (steps 33–42: the Mast's
count, boss fights restarted on death and the unkillable autopilot, boss stages for every boss, holds and
descents in six districts, revisits, tool doors, Rewrite's threshold). Author of the code under review:
Claude Code (Claude Opus 5.5).

## Round 1 findings (verbatim from sol_analyst)

No. Steps 33–42 are implemented, but milestone 5 is not ready to close. I found nine P2 issues and one P3 issue. No P0 or P1 defect was established.

I reviewed `git diff 4bef46f` through HEAD `5c343a9`, including the working tree. The findings below distinguish confirmed code behavior from conclusions that still need playtesting.

1. **P2 — Boss retries do not guarantee the arena checkpoint. Confirmed.**  
   `restart_boss_fight()` rebuilds the boss but never selects `arena_checkpoint()`. Respawning uses whichever checkpoint the player last touched, initially the district start. The arena-checkpoint helper has no gameplay callers. A read-only traversal of the shipped maps found routes into boss engagement range without touching any checkpoint in the Vellum, Tideworks and Harbor. For example, the Vellum route goes from `(12,39)` through `(14,11)`, `(15,7)`, `(25,6)` to `(34,6)`. Dying there returns the player to the start, contrary to decision 177. The restart test conceals this by assigning the arena checkpoint itself. Select the checkpoint as part of encounter entry or retry, and test the gameplay path without that assignment. Evidence: [level.gd:275](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:275), [level.gd:392](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:392), [level.gd:871](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:871), [test_boss_restart.gd:66](/home/homebox/Documents/rookmate/undertow/tests/integration/test_boss_restart.gd:66).

2. **P2 — A posthumous boss kill bypasses the full restart. Confirmed control-flow defect.**  
   Going down waits 1.6 seconds before deciding whether to restart the encounter. During that interval, player projectiles continue damaging enemies. If a projectile finishes the boss, its death opens the barriers; the later restart sees a dead or freed boss and returns without rebuilding it. A final-stage Warden-Prime fight with its summoned Wardens provides a plausible normal trigger: the player goes down while a fatal drone shot is still travelling. Capture the failed encounter when the player goes down, rather than determining it from the boss’s later state. Evidence: [operator.gd:345](/home/homebox/Documents/rookmate/undertow/game/player/operator.gd:345), [projectile.gd:45](/home/homebox/Documents/rookmate/undertow/game/weapons/projectile.gd:45), [boss.gd:194](/home/homebox/Documents/rookmate/undertow/game/bosses/boss.gd:194), [level.gd:872](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:872). The timing scenario was traced from code, not reproduced in a mortal run.

3. **P2 — Hardening changes the reported windup, but not the actual attack timing; elite Wardens also lose their speed increase. Confirmed.**  
   All six enemy types now return `WINDUP * windup_scale`, but their attack state machines still compare elapsed time against the original `WINDUP` constant. A hardened Custodian reports 0.44 seconds and finishes its telegraph then, while still beginning its attack after 0.55 seconds. The revisit test checks only the reported value. Separately, `make_elite()` multiplies Warden speed by 1.15, but `_hunt()` and `_walk_beat()` overwrite it with the unscaled speeds on subsequent updates. Use the effective timings and speeds in the state machines, and verify elapsed attack time and movement after AI updates. Evidence: [custodian.gd:25](/home/homebox/Documents/rookmate/undertow/game/enemies/custodian.gd:25), [custodian.gd:52](/home/homebox/Documents/rookmate/undertow/game/enemies/custodian.gd:52), [enemy.gd:63](/home/homebox/Documents/rookmate/undertow/game/enemies/enemy.gd:63), [warden.gd:115](/home/homebox/Documents/rookmate/undertow/game/enemies/warden.gd:115), [warden.gd:139](/home/homebox/Documents/rookmate/undertow/game/enemies/warden.gd:139), [test_revisits.gd:119](/home/homebox/Documents/rookmate/undertow/tests/integration/test_revisits.gd:119).

4. **P2 — Stage transitions can cut off the boss’s preceding call. Confirmed.**  
   Opening calls start when the boss becomes vulnerable. A threshold-crossing hit immediately starts the next stage and issues its urgent call, which replaces the current recording. For example, `conductor_vent.ogg` lasts approximately 2.126 seconds, but a hit immediately after venting can replace it with `conductor_express` within one frame. The declared three-second vent gap is therefore not the shortest possible gap. The same interruption exists for the other bosses’ opening calls. `test_boss_calls` compares recordings against declared constants; it does not verify these damage-driven transitions. Account for transitions in the call scheduling and add runtime checks around threshold hits. Evidence: [conductor.gd:165](/home/homebox/Documents/rookmate/undertow/game/bosses/conductor.gd:165), [boss.gd:121](/home/homebox/Documents/rookmate/undertow/game/bosses/boss.gd:121), [boss.gd:132](/home/homebox/Documents/rookmate/undertow/game/bosses/boss.gd:132), [narrator.gd:113](/home/homebox/Documents/rookmate/undertow/autoload/narrator.gd:113), [sound.gd:229](/home/homebox/Documents/rookmate/undertow/autoload/sound.gd:229), [test_boss_calls.gd:28](/home/homebox/Documents/rookmate/undertow/tests/integration/test_boss_calls.gd:28).

5. **P2 — New hatch and tool-door explanations use the Steward’s gold and serif. Confirmed rule violation.**  
   The HUD renders every blocked interaction reason as Steward narration. The new passages and doors supply ordinary environmental explanations through that interface. Harbor’s ferry hatch consequently speaks in Steward gold and serif even though its text describes the Ward’s own mast circuit and decision 186 explicitly says the Steward cannot hear it. This also happens while muted. The color and font tests pass because they allowlist the entire HUD file. Give interaction explanations an explicit speaker or presentation type, preserving Steward styling for its actual refusals. Evidence: [hud_view.gd:169](/home/homebox/Documents/rookmate/undertow/ui/hud/hud_view.gd:169), [passage.gd:43](/home/homebox/Documents/rookmate/undertow/game/props/passage.gd:43), [tool_door.gd:60](/home/homebox/Documents/rookmate/undertow/game/props/tool_door.gd:60), [holds.json:153](/home/homebox/Documents/rookmate/undertow/data/holds.json:153), [test_font_rules.gd:10](/home/homebox/Documents/rookmate/undertow/tests/unit/test_font_rules.gd:10).

6. **P2 — The Lung’s deep-water damage extends beyond its drawn basin. Confirmed.**  
   `in_deep()` checks only whether the player is farther away than the shallow-water radius. There is no outer limit or terrain restriction. Once stage 2 starts, retreating anywhere farther away, including back into a descent, satisfies the damage condition. The drawn water ends at `BASIN_TILES + 2.0`, so distant damage has no matching visual warning. Bound the damage to the same region used for drawing. Evidence: [lung.gd:152](/home/homebox/Documents/rookmate/undertow/game/bosses/lung.gd:152), [lung.gd:248](/home/homebox/Documents/rookmate/undertow/game/bosses/lung.gd:248), [lung.gd:330](/home/homebox/Documents/rookmate/undertow/game/bosses/lung.gd:330).

7. **P2 — The hold progress display can freeze or linger. Confirmed.**  
   The new hold drawing was added without adding hold state to the HUD’s redraw signature. A running hold also stops qualifying as an interaction target. With no changing health, weapon state, threats or nearby prompts, progress advances without redrawing the percentage or bar. Completion can likewise leave the last display visible until something else causes a redraw. The recorded Greywater hold screenshot shows 0% when the route has already observed the first spawned wave, which requires at least 6% progress. Include hold identity, progress, running and turning state in redraw tracking. Evidence: [hud_view.gd:70](/home/homebox/Documents/rookmate/undertow/ui/hud/hud_view.gd:70), [hud_view.gd:83](/home/homebox/Documents/rookmate/undertow/ui/hud/hud_view.gd:83), [hud_view.gd:132](/home/homebox/Documents/rookmate/undertow/ui/hud/hud_view.gd:132), [hold.gd:35](/home/homebox/Documents/rookmate/undertow/game/props/hold.gd:35), [recorded screenshot](/home/homebox/Documents/rookmate/undertow/reports/check/shots_full_campaign/greywater_hold.png).

8. **P2 — Legacy saves can restore map truths previously left at a Reliquary. Confirmed compatibility gap.**  
   Older saves load with an empty `cores_left`. Before milestone 5, confirming a Reliquary cleared `found_core_ids` without preserving the abandoned IDs. A previously found and rejected map truth is therefore available again on a revisit: it appears in neither the carried lists nor `cores_left`. New saves preserve abandonment correctly, but old saves do not preserve this earlier trade-off. The old data cannot distinguish a rejected map truth from one never found, so this needs an explicit legacy policy and coverage, rather than an assumed faithful migration. Evidence: commit `4bef46f`, `core/core_choice.gd::apply`; [run_state.gd:189](/home/homebox/Documents/rookmate/undertow/core/run_state.gd:189), [truth_cache.gd:24](/home/homebox/Documents/rookmate/undertow/game/props/truth_cache.gd:24).

9. **P2 — Encounter and traversal responsibilities push `Level` past the project’s maintainability threshold. Confirmed structural regression.**  
   `level.gd` grows from 897 to 1,094 lines. It now owns passage animation and teleportation, descent queries, hold-wave spawning, revisit policy, boss teardown and reconstruction, alongside existing rendering and map construction. The retry defects above reflect the missing encounter lifecycle owner: checkpoint selection, death, defeat and outstanding projectiles are handled separately. Extract encounter management and traversal before closing the milestone, with explicit ownership of retry state and boss-owned objects. Evidence: `git diff --numstat 4bef46f -- game/level/level.gd` reports 208 additions and 11 deletions; [level.gd:286](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:286), [level.gd:311](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:311), [level.gd:867](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:867).

10. **P3 — The city map says the skiff is unavailable when revisits are available. Confirmed.**  
    After all districts are completed, its initial selection considers only unfinished districts and displays “THE SKIFF ISN'T READY.” Completed district buttons still permit revisits, so this is misleading rather than a travel blockage. It occurs precisely when a player may need revisits to make up Rewrite’s truth count. Include revisitable districts when selecting the initial destination and deciding whether travel is available. Evidence: [city_map.gd:68](/home/homebox/Documents/rookmate/undertow/ui/ark/city_map.gd:68), [city_map.gd:154](/home/homebox/Documents/rookmate/undertow/ui/ark/city_map.gd:154), [level_catalog.gd:294](/home/homebox/Documents/rookmate/undertow/core/level_catalog.gd:294).

The truth count and threshold check out. A read-only content audit found all 24 truth cores placed. Each of the eight Reliquaries offers one truth, so carrying those reaches eight without depending on tool-door rewards. District-specific hardening counts, revisit boss suppression, immediate Archive filing, and serialization of the three new state arrays are present. I found no unexplained weakening of the changed assertions or gate checks; the immortal autopilot is explicitly authorized by decision 178.

The remaining validation gaps are material. The restart test exercises stage 1 only: directly reducing `Integrity` does not advance `Boss.stage`. Deaths during later stages and transitions, Warden reinforcements, and death inside descents need coverage. Human district duration, mortal boss fairness, hardening balance, darkness readability and controller-only play remain unverified. The recorded Harbor descent already shows Warden-Prime engaged; unintended overlap between the hold and boss encounter is worth checking, but I have not established a balance defect from that screenshot.

The existing test log reports **494 passing tests**. I independently ran the color, font and RunState subsets: all 16 assertions passed, but Godot emitted a log-file setup error under the read-only sandbox, so those were not clean gate runs. I did not rerun the writing gate. At final inspection, the current step-42 campaign was still in Mercy and had no final PASS; the other recorded scenario passes predate that gate. No files were edited.

## Round 1 fixes

1. **Back by the arena's door.** The fight's lifecycle moved out of Level into `BossEncounter`
   (`game/level/boss_encounter.gd`): building the boss and its barriers, losing the fight, starting it
   over. When a lost fight starts over, the checkpoint becomes `LevelGrid.arena_checkpoint()`, whichever
   one you'd touched. Test: `test_boss_restart::test_every_boss_fight_starts_over_when_you_die` no
   longer sets the checkpoint itself; it walks in from the start, dies (in its second stage where it has
   one) and checks you're back at the arena's door.
2. **A lost fight is settled as you go down.** `Operator._really_go_down` tells the level at once;
   `BossEncounter.player_went_down` marks the fight lost, holds the boss off (`Boss.hold_off`: nothing
   hurts it) and clears your shots in the air; back on your feet it starts over whatever happened
   meanwhile. Test: `test_boss_restart::test_a_shot_still_in_the_air_cant_finish_it_once_youre_down`.
3. **Hardening is real.** Every enemy's state machine strikes at `windup_seconds()` (its scaled
   telegraph), and elites carry a `speed_scale` the Warden's hunt and beat speeds use. Tests:
   `test_revisits::test_a_quicker_windup_strikes_sooner` (between the two windups, the hardened one has
   struck and the plain one hasn't), `test_revisits::test_an_elite_warden_keeps_its_speed`.
4. **A new stage waits for the call being said.** `Boss._begin_stage` holds its word until the Steward
   has finished saying one of this boss's own calls (its `CALL_GAPS`) or a warning, at most
   `STAGE_CALL_WAIT` (3 s); the pause between stages counts from its word. Ambient lines give way. Test:
   `test_boss_stages::test_a_new_stage_waits_for_the_call_being_said` (vent call, threshold hit: the
   vent call plays out, then "Express", then the full pause). The stage tests now wait for the pause to
   end (`TestCase.wait_until`) instead of a fixed 3.3 s.
5. **Only the Steward's refusals are its.** `Interactable.blocked_by_steward()` (true only for the ward
   seals and the Waiting it won't wake); the HUD draws other blocked reasons (a shut hatch, a locked
   door, the Reliquary, Noor, the boat) in plain type and ivory (`HudView.reason_font`/`reason_color`).
   Test: `test_blocked_reasons`.
6. **The Lung's deep water is only where it's drawn** (`Lung.DEEP_OUTER`, shared with the drawing; never
   below the street). Test: `test_boss_stages::test_the_lungs_deep_water_is_only_where_its_drawn`.
7. **A running hold's bar redraws**: its id, progress and turning are in the HUD's redraw signature.
   Test: `test_holds::test_the_hud_follows_it`.
8. **Old saves, an explicit policy** (DECISIONS 190): saves are version 3; a version-2 save counts
   nothing as left at a Reliquary, so a truth left then can be found again on a revisit. Test:
   `test_run_state::test_an_old_save_forgets_nothing_it_left`.
9. **Level is smaller.** `BossEncounter` (the fight) and `Descents` (`game/level/descents.gd`: placing
   the holds, ladders, tool doors and the dark; going down and back up; what's left below) moved out;
   Level keeps one-line accessors for what the rest of the game asks it. `level.gd` is 943 lines (from
   1,094). Tests: `test_holds::test_going_down_below_brings_you_back_up` (dying below ground).
10. **The Loop map with nothing new open** chooses the first district you can go back to, and the skiff
    goes. Test: `test_revisits::test_with_everything_done_the_skiff_still_goes_back`.

Also, from the review's note on the Harbor descent screenshot and from watching the recordings: the
Warden-Prime was being engaged during Harbor's hold (one of its spawn points sat by the border gate,
within reach of the Prime), so the Ward's hold now brings its Wardens off the middle pier, and the
Vellum's from the newsroom's far side; a test keeps every hold's spawns and crank well clear of the
district's boss (`test_holds::test_a_holds_machines_come_out_clear_of_the_boss`). And the loadout's
cards no longer spill their asset tags across the next card (the tag's size was set before its wrapping):
`test_loadout_screen`.

## Round 2 findings (verbatim from sol_analyst)

Milestone 5 should remain open. All ten Round 1 implementation findings are addressed, but the fixes introduce one P2 validation regression. I found no P0 or P1 issue and no new confirmed gameplay defect.

1. **P2: The replacement stage waits weaken the maximum-duration checks.**

   Confirmed: `TestCase.wait_until()` measures its timeout with `Time.get_ticks_msec()`, which is wall time. The gate runs tests with `--fixed-fps 60`, advancing game time as fast as the CPU permits. Boss transitions count physics delta, while the previous `wait_seconds()` checks used a SceneTree timer. Thus the new 6.7-second timeout does not enforce a 6.7-second limit on gameplay time. Evidence: [test_case.gd:58](/home/homebox/Documents/rookmate/undertow/tests/test_case.gd:58), [test_case.gd:64](/home/homebox/Documents/rookmate/undertow/tests/test_case.gd:64), [test_runner.gd:3](/home/homebox/Documents/rookmate/undertow/tests/test_runner.gd:3), [check.sh:60](/home/homebox/Documents/rookmate/undertow/tools/check.sh:60), [test_boss_stages.gd:46](/home/homebox/Documents/rookmate/undertow/tests/integration/test_boss_stages.gd:46).

   Inference: a regression that substantially lengthens a transition can pass these checks if accelerated frames finish it before the wall-clock deadline. I did not inject that regression.

   Waiting until the pause ends is appropriate now that its start can be delayed by the preceding call. Keep that change, but measure the timeout using a SceneTree timer or accumulated physics delta. The runner already has a separate wall-clock watchdog. Under the explicit rule against weakening checks, this needs correction before closing the review.

The Round 1 dispositions are:

| Finding | Round 2 result |
|---|---|
| 1. Arena checkpoint on retry | Fixed. `start_over_if_lost()` selects `arena_checkpoint()` before respawning. The test no longer assigns the checkpoint itself, although it teleports into engagement rather than walking a route. [boss_encounter.gd:45](/home/homebox/Documents/rookmate/undertow/game/level/boss_encounter.gd:45), [test_boss_restart.gd:65](/home/homebox/Documents/rookmate/undertow/tests/integration/test_boss_restart.gd:65). |
| 2. Posthumous boss kill bypassing restart | Fixed. Going down captures the lost encounter immediately, prevents further boss damage and queues player projectiles for deletion. Restart depends on the captured loss. [boss_encounter.gd:32](/home/homebox/Documents/rookmate/undertow/game/level/boss_encounter.gd:32), [boss.gd:118](/home/homebox/Documents/rookmate/undertow/game/bosses/boss.gd:118). |
| 3. Ineffective hardening | Fixed. All six attack state machines use `windup_seconds()`. Warden hunting and patrol speeds retain `speed_scale`. The added tests exercise AI updates and elapsed windup time. [custodian.gd:52](/home/homebox/Documents/rookmate/undertow/game/enemies/custodian.gd:52), [warden.gd:115](/home/homebox/Documents/rookmate/undertow/game/enemies/warden.gd:115), [test_revisits.gd:232](/home/homebox/Documents/rookmate/undertow/tests/integration/test_revisits.gd:232). |
| 4. Stage calls interrupting preceding calls | Runtime fix is correct. The stage call waits for the boss's current call or a warning, up to three seconds; the transition countdown starts afterward. The test-timeout problem above remains. [boss.gd:174](/home/homebox/Documents/rookmate/undertow/game/bosses/boss.gd:174). |
| 5. Environmental explanations using Steward styling | Fixed. The HUD selects font and color explicitly; only WardSeal and TheWaiting identify their blocked reasons as the Steward's. [hud_view.gd:174](/home/homebox/Documents/rookmate/undertow/ui/hud/hud_view.gd:174), [test_blocked_reasons.gd:7](/home/homebox/Documents/rookmate/undertow/tests/unit/test_blocked_reasons.gd:7). |
| 6. Lung damage beyond its drawn basin | Fixed. Damage and drawing share `DEEP_OUTER`; culvert terrain is excluded from deep-water damage. [lung.gd:154](/home/homebox/Documents/rookmate/undertow/game/bosses/lung.gd:154), [lung.gd:337](/home/homebox/Documents/rookmate/undertow/game/bosses/lung.gd:337). |
| 7. Frozen or lingering hold progress | Fixed. Hold identity, progress and turning state affect the redraw signature. Removing the running hold also changes the signature. [hud_view.gd:80](/home/homebox/Documents/rookmate/undertow/ui/hud/hud_view.gd:80). |
| 8. Legacy Reliquary abandonment | Resolved by the explicit decision 190 policy. Version 2 saves remain loadable and treat nothing as abandoned; version 3 preserves `cores_left`. This intentionally permits recovering previously rejected map truths from old saves. [run_state.gd:177](/home/homebox/Documents/rookmate/undertow/core/run_state.gd:177). |
| 9. Level responsibilities and size | Fixed. Level is 943 lines; BossEncounter owns retry lifecycle and construction, while Descents owns traversal and descent placement. I found no structural regression from the extraction. [boss_encounter.gd:3](/home/homebox/Documents/rookmate/undertow/game/level/boss_encounter.gd:3), [descents.gd:3](/home/homebox/Documents/rookmate/undertow/game/level/descents.gd:3). |
| 10. Misleading skiff availability | Fixed. With no unfinished destination open, initial selection includes revisitable districts and enables travel. [city_map.gd:68](/home/homebox/Documents/rookmate/undertow/ui/ark/city_map.gd:68). |

The additional spawn changes preserve routes from both moved spawn points to their cranks and separate the hold positions from boss engagement range. The loadout wrapping change also matches its containment test. A read-only content audit confirmed 24 truth cores: 16 map caches and eight Reliquary truths.

The current gate's [test log](/home/homebox/Documents/rookmate/undertow/reports/check/tests.log:526) reports **507 passing tests**. Import, tests and smoke logs contain no gate-matched problem lines. I independently ran the RunState and blocked-reason subsets: all 12 tests passed, but the read-only sandbox caused an engine log-file setup error, so those were not clean gate runs.

At final inspection, the current campaign was still in Mercy with no final PASS. The ending, revisit, tool-door and tour PASS logs predate this gate's import, so they do not establish completion of the current run.

Fix the gameplay-time timeout and obtain the current gate's final PASS before closing the code review. Human district duration, mortal boss fairness, hardening balance, controller-only interaction and descent readability remain unverified. No files were edited.

## Round 2 fixes

1. **The stage waits count game time.** `TestCase.wait_until` now adds up physics frames' delta (the
   game's own clock, which the bosses count) instead of reading the wall clock, so under the runner's
   fixed frame rate its timeout bounds the pause in game seconds again. The waits themselves stay (the
   pause starts once the stage's word is said, so a fixed wait no longer fits). The boss, stage and Lung
   tests pass with it.

## Round 3 findings (verbatim from sol_analyst)

Milestone 5 should remain open. The Round 2 timeout defect is fixed, and the Round 1 fixes still hold. I found one previously missed P2 issue. No P0, P1 or additional P3 defect was established.

1. **P2: The Crane's second load disappears during its damaging fall.**

   **Confirmed from code:** From stage 2 onward, the second container and its ground warning are drawn only inside `if phase == Phase.AIM`. Entering `DROP` removes both. The first container remains visible and falls using `load_height`, but the second container has no drawing during that fall. After `DROP_SECONDS`, configured as 0.25 seconds, the damage check still includes `_mark2`. Standing at that second mark can therefore produce a hit from a container that has vanished. This affects stages 2 and 3. Evidence: [crane.gd:193](/home/homebox/Documents/rookmate/undertow/game/bosses/crane.gd:193), [crane.gd:268](/home/homebox/Documents/rookmate/undertow/game/bosses/crane.gd:268), [crane.gd:271](/home/homebox/Documents/rookmate/undertow/game/bosses/crane.gd:271).

   The existing stage test checks the second mark's separation during `AIM`, then advances directly to stage 3. It does not exercise that second load's fall or impact. Evidence: [test_boss_stages.gd:84](/home/homebox/Documents/rookmate/undertow/tests/integration/test_boss_stages.gd:84).

   **Inference:** The disappearance can make the player read the second hazard as cancelled, especially while muted. The earlier aiming warning exists, so this is not an entirely untelegraphed attack. I have not established its effect on mortal fight difficulty through playtesting.

   Keep the second container visible through `DROP`, animate it with the fall height, and verify the second impact separately from the first.

The Round 2 correction is sound. `wait_until()` now accumulates physics delta after each physics frame, matching the clock that advances boss transitions. Accelerated `--fixed-fps 60` execution no longer turns its timeout into a wall-clock allowance. The comparison permits ordinary frame-boundary slack, not an unbounded gameplay delay. Evidence: [test_case.gd:65](/home/homebox/Documents/rookmate/undertow/tests/test_case.gd:65).

Replacing the fixed 3.3-second waits is justified. The stage call can wait up to three seconds for the preceding call, and the 3.2-second transition countdown starts afterward. The replacement checks still require completion within 6.7 game seconds, and the runtime narration test checks the preceding call and subsequent pause. I found no remaining weakening of those checks. Evidence: [boss.gd:174](/home/homebox/Documents/rookmate/undertow/game/bosses/boss.gd:174), [test_boss_stages.gd:46](/home/homebox/Documents/rookmate/undertow/tests/integration/test_boss_stages.gd:46), [test_boss_stages.gd:152](/home/homebox/Documents/rookmate/undertow/tests/integration/test_boss_stages.gd:152).

The other re-checks found no regression:

- Boss loss is captured immediately, further boss damage is blocked, encounter parts are removed, and retry selects the arena checkpoint.
- Hardened enemies use their effective windups; Wardens retain their speed multiplier.
- Blocked prompts select the correct speaker styling, hold progress triggers redraws, and Lung damage shares its drawn outer boundary.
- Version 3 preserves the new save fields; version 2 follows decision 190's explicit abandonment policy.
- The extraction leaves `Level` at 943 lines with clear encounter and descent owners. City-map revisits and loadout containment remain intact.

Independent read-only audits confirmed that all seven map generators match their shipped grids, all 24 truth cores are placed exactly once, and all six descents have accessible surface ladders, isolated underground areas and connected hold spawn routes.

The current [test log](/home/homebox/Documents/rookmate/undertow/reports/check/tests.log:526) reports **507 passing tests**. Import, tests and the 30-second smoke run contain no gate-matched problem lines. At final inspection, the current campaign had reached the Tideworks without a final PASS. The ending, revisit, tool-door and tour logs predate this gate's import and do not validate the current run.

Fix the second load's rendering and obtain the current gate's final PASS before calling milestone 5 done. Human district duration, mortal boss fairness, hardening balance, controller-only interaction and descent readability remain unverified. No files were edited.

## Round 3 fixes

1. **The Crane's second load is there through its fall.** From stage 2 the second container hangs beside
   the first on its own cable while it's aimed, falls and lands with it, and goes back up with it
   (`Crane.second_load_shown`, used by its drawing); only its ground ring is aim-only, like the first's.
   Test: `test_boss_stages::test_the_cranes_second_load_falls_where_its_shown` (marks set, you under the
   second load only: it's still shown as it lets go, and where it lands it hurts).

## Round 4 findings (verbatim from sol_analyst)

Milestone 5 should remain open. The Round 3 P2 is fixed, and the Round 1 and 2 fixes still hold. I found one P3 rendering regression. No P0, P1 or P2 defect was established in this round.

1. **P3. The Crane's second load draws at world origin during its first stage-2 lift.**

   **Confirmed from code:** `_mark2` starts at `Vector2.ZERO` and is assigned only during stage-2 `AIM`. When the stage transition ends, `_start_cycle()` enters `LIFT` without initializing it. The new `second_load_shown()` includes `LIFT`, and the drawing positions the second container using `_mark2`. For that first one-second lift, the second container therefore draws at world origin, with its cable running there from the jib. Evidence: [initial state and stage entry](/home/homebox/Documents/rookmate/undertow/game/bosses/crane.gd:78), [lift and mark assignment](/home/homebox/Documents/rookmate/undertow/game/bosses/crane.gd:173), [drawing](/home/homebox/Documents/rookmate/undertow/game/bosses/crane.gd:239).

   The new regression test jumps directly into `AIM`, skipping this lift, and checks visibility through the predicate rather than checking the container's position. Evidence: [test_boss_stages.gd:185](/home/homebox/Documents/rookmate/undertow/tests/integration/test_boss_stages.gd:185).

   **Inference:** In the shipped arena, the container will be outside the camera view and its cable may stretch across the scene until aiming initializes the mark. I did not inspect that frame visually. This is a presentation defect; the subsequent damaging drop uses the correct position.

   Compute or initialize the second container's lifting position beside the current first load before drawing `LIFT`. Cover the actual first lift after entering stage 2.

The Round 3 fix itself is sound. During `DROP`, the second container now stays visible, uses the same falling `load_height` as the first, and remains at the mark used by the damage check. The added test checks a hit under the second load, clear of the first.

The earlier fixes remain intact:

- Boss loss is captured immediately; subsequent boss damage is blocked; retry removes encounter objects and selects the arena checkpoint. [boss_encounter.gd:32](/home/homebox/Documents/rookmate/undertow/game/level/boss_encounter.gd:32).
- Hardened enemies use their scaled windups, and Wardens retain their speed multiplier during hunting and patrol.
- Blocked explanations select the appropriate font and color; hold progress triggers HUD redraws; the Lung's deep-water damage retains its outer boundary and descent exclusion.
- Version 3 preserves the new save fields, and older saves follow decision 190's explicit abandonment policy. [run_state.gd:177](/home/homebox/Documents/rookmate/undertow/core/run_state.gd:177).
- Encounter and descent ownership remain separated, with `Level` at 943 lines. Revisit selection and loadout containment still match their tests.

Replacing the fixed stage waits is justified. The preceding call can delay the pause's start by up to three seconds. `wait_until()` accumulates physics delta, so the replacement timeout still bounds gameplay time under accelerated tests. The narration test also checks that the preceding call survives and the subsequent pause completes. I found no remaining weakening of these checks. [test_case.gd:65](/home/homebox/Documents/rookmate/undertow/tests/test_case.gd:65).

Independent read-only audits confirmed that all seven map generators match their shipped grids and all 24 truth cores are placed exactly once.

The current [test log](/home/homebox/Documents/rookmate/undertow/reports/check/tests.log:527) reports **508 passing tests**. Import, tests and smoke logs contain no gate-matched problem lines. I independently ran the RunState and blocked-reason subsets: all 12 tests passed, but the sandbox caused an engine log-file setup error, so these were not clean gate runs.

At final inspection, the current campaign was in the Tideworks without a final PASS. The ending, revisit, tool-door and tour logs predate this gate's import.

Correct the P3 and obtain the current gate's final PASS before closing the implementation review. Human playtesting still needs to establish district duration, mortal boss fairness, hardening balance, controller-only interaction and descent readability. No files were edited.

## Round 4 fixes

1. **The second load comes up beside the first.** While it lifts (from stage 2) the second load's place
   follows the first's (`Crane._beside`, shared with its aim), so its first lift after the stage begins
   draws beside the first load, not at the world's origin. Test: the Crane stage test now checks that
   first lift (both loads shown, the second `SECOND_LOAD` from the first) before it aims.

## Round 5 findings (verbatim from sol_analyst)

Milestone 5 should remain open. The Round 4 fix corrects the sustained lift, but leaves one P3 defect on the transition frame. No P0, P1 or P2 defect, or additional P3 issue, was established.

1. **P3. The Crane's second load can still draw at world origin on the first frame of its stage-2 lift.**

   **Confirmed from code:** `_mark2` starts at `Vector2.ZERO`. When the transition finishes, `Boss._think()` calls `_on_stage()` and returns without running `_fight()`. The Crane's `_on_stage()` enters `LIFT`, which immediately satisfies `second_load_shown()`, but `_mark2` is initialized only by the following physics tick's `LIFT` branch. Until then, `_draw()` positions the second container at the zero mark. The fix therefore reduces the original one-second defect to one physics tick rather than eliminating it. Evidence: [boss.gd:181](/home/homebox/Documents/rookmate/undertow/game/bosses/boss.gd:181), [crane.gd:78](/home/homebox/Documents/rookmate/undertow/game/bosses/crane.gd:78), [crane.gd:113](/home/homebox/Documents/rookmate/undertow/game/bosses/crane.gd:113), [crane.gd:183](/home/homebox/Documents/rookmate/undertow/game/bosses/crane.gd:183), [crane.gd:248](/home/homebox/Documents/rookmate/undertow/game/bosses/crane.gd:248), [crane.gd:284](/home/homebox/Documents/rookmate/undertow/game/bosses/crane.gd:284).

   The revised test checks the lift's position only after waiting two physics frames, so it misses this invalid initial state. Evidence: [test_boss_stages.gd:188](/home/homebox/Documents/rookmate/undertow/tests/integration/test_boss_stages.gd:188).

   **Inference:** A render between those physics ticks can show the stretched cable or misplaced container. I did not capture that rendered frame, so its visibility during ordinary play remains unverified. The subsequent damaging drop uses the correct mark.

   Initialize `_mark2` when entering `LIFT`, before the second load becomes drawable, or derive its lifting position directly from `load_at`. Check the position immediately after the stage transition, before advancing another physics frame.

The Round 3 fix remains sound. The second container stays visible through `DROP`, follows the falling height, and uses the position checked for its damaging impact.

The earlier fixes still hold:

- Boss loss is captured immediately, subsequent boss damage is blocked, retry removes encounter objects and selects the arena checkpoint. [boss_encounter.gd:32](/home/homebox/Documents/rookmate/undertow/game/level/boss_encounter.gd:32).
- All six enemy attack state machines use their scaled windups; Warden hunting and patrol retain the speed multiplier.
- Blocked explanations select the appropriate font and color, hold progress changes the HUD redraw signature, and Lung deep-water damage retains its shared outer boundary and descent exclusion.
- Version 3 preserves the new save fields; older saves follow decision 190's explicit abandonment policy. [run_state.gd:177](/home/homebox/Documents/rookmate/undertow/core/run_state.gd:177).
- Encounter and descent ownership remain separated. `Level` is 943 lines, and no changed GDScript file crosses 1,000 lines. Revisit selection and loadout containment remain intact.

Replacing the fixed stage waits is justified. The preceding call can delay the transition countdown by up to three seconds. The replacement waits allow 6.7 game seconds with ordinary frame-boundary slack, and `wait_until()` accumulates physics delta rather than wall time. The narration test also checks that the preceding call survives and the subsequent pause completes. I found no unjustified weakening of the changed tests or gate checks. Evidence: [test_case.gd:65](/home/homebox/Documents/rookmate/undertow/tests/test_case.gd:65), [test_boss_stages.gd:152](/home/homebox/Documents/rookmate/undertow/tests/integration/test_boss_stages.gd:152).

Independent read-only audits confirmed that all seven generated grids match their shipped maps, all six descents have reachable surface ladders and isolated underground routes, hold spawn routes remain connected, tool doors guard their rewards, and all 24 truth cores are placed exactly once.

The current [test log](/home/homebox/Documents/rookmate/undertow/reports/check/tests.log:527) reports **508 passing tests**, and the [30-second smoke run](/home/homebox/Documents/rookmate/undertow/reports/check/smoke.log:21) passed. Import, tests and smoke logs contain no gate-matched problem lines. I independently ran the boss-stage and boss-restart subsets: all 10 tests passed, but sandbox restrictions caused engine log-file and save-write failures, so those were not clean gate runs.

At final inspection, the current campaign had reached the Tideworks without a final PASS. The ending, revisit, tool-door and tour logs still predate this gate's import.

Correct the remaining P3 and obtain the current gate's final PASS before closing the implementation review. Human playtesting must still establish the planned district duration, mortal boss fairness, hardening balance, controller-only interaction and descent readability before milestone 5 as a whole can be called done. No files were edited.

## Round 5 fixes

1. **No frame of a load anywhere it isn't.** The second load's drawn place is worked out, not left over:
   while it lifts it's beside the first (`Crane.second_load_at`), from its first frame. And aiming is
   marked from its first frame too: entering `AIM` sets the first mark on you (as near as the jib
   reaches) and the second beside it, so neither ring nor load draws at an old spot or the origin on the
   frame the aim begins (the first ring could, on the Crane's first aim ever; older than this milestone).
   Test: the Crane stage test checks the second load's place on the stage's first lift frame and both
   marks on the aim's first frame, with no frames advanced.

## Round 6 findings (verbatim from sol_analyst)

The Round 5 Crane defect is fixed. I found no new confirmed P0, P1, P2 or P3 issue, and no regression in the earlier fixes. **Milestone 5 should remain open pending the current gate’s completion and human playtesting.**

I reviewed the working tree on `a2f4760`, including the new untracked scripts and tests, against the milestone’s `4bef46f` baseline, plan and decisions.

The Crane fix holds from the first frame:

- During `LIFT`, `second_load_at()` derives the second container’s position from `load_at`. `_draw()` uses that result immediately, so the transition frame no longer depends on `_mark2` having been initialized by a later physics tick. Evidence: [crane.gd:257](/home/homebox/Documents/rookmate/undertow/game/bosses/crane.gd:257), [crane.gd:293](/home/homebox/Documents/rookmate/undertow/game/bosses/crane.gd:293).
- Entering `AIM` initializes both marks before returning. The first ring therefore starts at the player’s reachable position, and the second starts beside it. Evidence: [crane.gd:155](/home/homebox/Documents/rookmate/undertow/game/bosses/crane.gd:155).
- The regression test checks the lift position immediately after the transition and both aim marks immediately after phase entry, without advancing additional frames. It retains the separate second-load impact check. Evidence: [test_boss_stages.gd:185](/home/homebox/Documents/rookmate/undertow/tests/integration/test_boss_stages.gd:185).

The earlier fixes remain intact:

| Area | Confirmed result |
|---|---|
| Encounter loss and retry | Going down captures the lost encounter immediately and blocks subsequent boss damage. Retry removes encounter objects, rebuilds stage 1 and selects the arena checkpoint. [boss_encounter.gd:32](/home/homebox/Documents/rookmate/undertow/game/level/boss_encounter.gd:32). |
| Hardening | All six enemy attack state machines use their scaled windups. Warden hunting and patrol retain the speed multiplier. [warden.gd:100](/home/homebox/Documents/rookmate/undertow/game/enemies/warden.gd:100). |
| Presentation and hazards | Blocked explanations select the appropriate font and color; running hold progress changes the HUD redraw signature; Lung deep-water damage retains its shared outer boundary and descent exclusion. [hud_view.gd:80](/home/homebox/Documents/rookmate/undertow/ui/hud/hud_view.gd:80), [lung.gd:154](/home/homebox/Documents/rookmate/undertow/game/bosses/lung.gd:154). |
| Saves and revisits | Version 3 preserves the new state fields. Older saves follow decision 190’s explicit abandonment policy. City-map revisit selection remains available when nothing new is open. [run_state.gd:177](/home/homebox/Documents/rookmate/undertow/core/run_state.gd:177), [city_map.gd:68](/home/homebox/Documents/rookmate/undertow/ui/ark/city_map.gd:68). |
| Structure and loadout | Encounter and descent ownership remain separated. `Level` is 943 lines; no changed GDScript file exceeds 1,000 lines. Loadout tag wrapping precedes sizing. [descents.gd:14](/home/homebox/Documents/rookmate/undertow/game/level/descents.gd:14), [loadout.gd:127](/home/homebox/Documents/rookmate/undertow/ui/loadout/loadout.gd:127). |

Replacing the fixed stage waits is sound. The preceding call can delay the transition countdown by up to three seconds. `wait_until()` accumulates physics delta, so the replacement 6.7-second limit bounds gameplay time under accelerated tests. The runtime narration test also checks that the preceding call survives and the subsequent pause completes. I found no unjustified weakening of the changed tests or gate checks. Evidence: [test_case.gd:65](/home/homebox/Documents/rookmate/undertow/tests/test_case.gd:65), [test_boss_stages.gd:152](/home/homebox/Documents/rookmate/undertow/tests/integration/test_boss_stages.gd:152).

Independent read-only audits confirmed all seven generator/grid matches, all 24 truth cores placed exactly once, six reachable and isolated descents, connected hold spawn routes and guarded tool-door rewards.

The current [test log](/home/homebox/Documents/rookmate/undertow/reports/check/tests.log:527) reports **508 passing tests**, and the [30-second smoke run](/home/homebox/Documents/rookmate/undertow/reports/check/smoke.log:21) passed. Import, tests and smoke contain no gate-matched problem lines. I independently ran the boss-stage, boss-restart, RunState and blocked-reason subsets: all **22 tests passed**, but sandbox restrictions caused engine log-file and save-write failures, so those were not clean gate runs.

At final inspection, the current campaign had reached the [Tideworks hold](/home/homebox/Documents/rookmate/undertow/reports/check/full_campaign.log:75) without a final PASS. The ending, revisit, tool-door and tour logs predate the current import.

No new implementation blocker was established. Human playtesting still needs to establish the planned first-visit district duration, mortal boss fairness, hardening balance, controller-only interaction and descent readability. Those remain open questions; automated passes do not establish their quality. Milestone 5 as a whole cannot yet be called done. No files were edited.

## After round 6

Round 6 found nothing new. The gate passed on that tree, but its screenshot of Harbor's hold still
showed the Warden-Prime's bar: fighting the curfew patrol by the border gate brought the player within
its reach from across the fence, so it engaged before you'd walked into its plaza (moving the hold's
spawn point in round 1 wasn't enough). Now the Prime sees you only on its Lattice, the border and the
plaza past it (`Boss._may_engage`, `WardenPrime._may_engage`; DECISIONS 191). Test:
`test_harbor::test_the_prime_sees_you_only_on_its_lattice` (in the lane within its reach: nothing; at
the border: the fight).

## Round 7 findings (verbatim from sol_analyst)

I found no new confirmed P0, P1, P2 or P3 issue. The engagement change matches decision 191, and I found no regression in the earlier fixes. **The implementation review can close once this tree’s full gate passes. That validation is still pending.**

I reviewed the working tree on `a2f4760`, including untracked files, against the milestone baseline `4bef46f`, the plan and decisions 174–191.

Confirmed from code, maps and current test logs:

- The new predicate restricts initial engagement. It preserves the existing alive-player, distance and retry-grace conditions. `Boss._may_engage()` defaults to true, while the Prime uses the canonical `LevelGrid.is_indexed(player.cell())` query. Once engaged, it continues fighting when the player leaves indexed ground, as decision 191 specifies. No additional state or Harbor-specific branch leaked into encounter management. Evidence: [boss.gd:108](/home/homebox/Documents/rookmate/undertow/game/bosses/boss.gd:108), [boss.gd:163](/home/homebox/Documents/rookmate/undertow/game/bosses/boss.gd:163), [warden_prime.gd:130](/home/homebox/Documents/rookmate/undertow/game/bosses/warden_prime.gd:130).

- The Harbor regression test exercises the reported boundary correctly. Its fractional position remains in unindexed cell `(33,20)` while strictly inside engagement range; the Prime stays idle. Moving to indexed cell `(36,20)` engages it. This test passed in the current full suite. Evidence: [test_harbor.gd:149](/home/homebox/Documents/rookmate/undertow/tests/integration/test_harbor.gd:149), [tests.log:315](/home/homebox/Documents/rookmate/undertow/reports/check/tests.log:315).

- Death and retry still work. Harbor’s selected arena checkpoint `(37,22)` is reachable with the barriers shut, indexed and approximately 3.61 tiles from the rebuilt Prime. The restart test’s approach `(40,23)` is also indexed. The unchanged grace condition still applies before engagement, and rebuilding creates a fresh stage-1 Prime without another introduction. The current all-boss restart test passed, including its grace and subsequent engagement assertions. Evidence: [boss_encounter.gd:45](/home/homebox/Documents/rookmate/undertow/game/level/boss_encounter.gd:45), [test_boss_restart.gd:54](/home/homebox/Documents/rookmate/undertow/tests/integration/test_boss_restart.gd:54), [tests.log:211](/home/homebox/Documents/rookmate/undertow/reports/check/tests.log:211).

- The Prime arena fixture remains valid. Its engagement approaches are indexed cobble within range, so the predicate permits its fights. All 11 Prime tests and six Warden tests passed in the current suite. Evidence: [warden_prime_arena.txt](/home/homebox/Documents/rookmate/undertow/tests/fixtures/warden_prime_arena.txt), [tests.log:492](/home/homebox/Documents/rookmate/undertow/reports/check/tests.log:492).

The campaign’s Harbor approach remains reachable by static inspection. After the hold and descent it crosses to `(36,19)`, an indexed cell approximately 4.12 tiles from the Prime, then explicitly waits for engagement. **Inference:** the new condition should preserve that route’s runtime completion; the current campaign has not reached Harbor yet. Evidence: [harbor_route.gd:119](/home/homebox/Documents/rookmate/undertow/autoload/autopilot/routes/harbor_route.gd:119).

I rechecked the earlier encounter, hardening, narration, Crane rendering, Lung boundary, HUD, save, revisit and loadout fixes and found no additional regression. The stage waits still count gameplay time, and I found no unjustified weakening of tests or gate checks. `Level` remains 943 lines; no changed GDScript file reaches 1,000 lines. Independent read-only generator checks matched all eight shipped district grids after equivalent whitespace normalization.

The current import and smoke logs are clean, and [tests.log:528](/home/homebox/Documents/rookmate/undertow/reports/check/tests.log:528) reports **509 passing tests**. At final inspection, the current campaign was still in the Loop without a final PASS. The ending, revisit, tool-door and tour PASS logs predate this change.

No implementation blocker remains established. Obtain this tree’s full gate PASS before recording the implementation review as closed. Human playtesting of duration, mortal combat fairness, hardening balance, controller interaction and descent readability remains outstanding for milestone 5 overall. No files were edited.

## Closed

No issue remains: every fix holds, and the gate passes on this tree (see the commit). On judging
findings from here on: the user asked (2026-10-13) that review findings be weighed rather than all fixed,
so player-facing bugs and broken project rules get fixed, and one-frame cosmetic glitches and theoretical
edge cases are noted with a reason instead (round 5's one-frame Crane draw was fixed before that, and was
the kind of thing that would now be noted).

**Review closed after 7 rounds.** Still to settle by playing, not by the gate (Sol's list and mine): how
long a first visit to each district takes now (the plan's 20–30 minutes); whether the bosses' later
stages are fair for a player who can die (the unkillable bot's near-downs only hint at it: Harbor's hold
and Warden-Prime are where it struggles most); how the revisits' hardening steps feel; controller-only
use of the cranks, ladders and tool doors; and whether the descents, rooms edged by dark and lit only by
your lamp, are readable.

One more note for playing: the gate's campaign shows the Warden-Prime chipped a few percent before its
fight (the riot drone's tuned aim reaches it across the fence from Net Lane). It can't start the fight
from there any more; the chip is left as it is (minor, and older than this milestone).
