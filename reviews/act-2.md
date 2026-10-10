# Milestone review: Act 2 (milestone 3)

Reviewer: **sol_analyst** (Sol 6.1, xhigh, read-only) via the "Sol analysis" skill, run through
`codex exec -s read-only`. Scope: `git diff e03edd7..34158aa` (steps 17–24: Noor and Teo join, Mercy
General and the Surgeon, the Clinic, Greywater and the Lung, the Pumphouse, the Vellum's east bank, the
Feed flash and the Editor, the companion conversations). Author of the code under review: Claude Code
(Claude Opus 5.5).

## Round 1 findings (verbatim from sol_analyst)

I would keep milestone 3 open. The review found one high-severity combat bug, several confirmed gameplay and validation defects, and three smaller contract or maintenance problems.

Reviewed `e03edd7..34158aa` without editing files. “Confirmed” below means established from code, shipped data, or read-only calculations; it does not imply a fresh gameplay reproduction.

1. **High — The Surgeon’s mist damages the player throughout Mercy General, including after respawning. Confirmed.**

   [surgeon.gd:118](/home/homebox/Documents/rookmate/undertow/game/bosses/surgeon.gd:118) defines mist exposure solely as being more than two tiles from the boss. There is no outer boundary, theatre boundary, or obstruction check. [surgeon.gd:146](/home/homebox/Documents/rookmate/undertow/game/bosses/surgeon.gd:146) then damages any living player satisfying that predicate.

   Once engaged, the boss keeps fighting regardless of player distance ([boss.gd:68](/home/homebox/Documents/rookmate/undertow/game/bosses/boss.gd:68)). Respawning revives the player at a checkpoint without resetting the fight ([level.gd:263](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:263)). Both shipped Mercy checkpoints are outside the safe radius. Retreating or dying therefore leaves the player exposed to subsequent mist phases elsewhere in the hospital.

   Bound the mist to the theatre using geometry shared by rendering and damage. Add a regression check that retreating and respawning outside that area cannot receive mist damage.

2. **Medium — The Lung’s visible flood area and damaging area disagree. Confirmed.**

   [lung.gd:119](/home/homebox/Documents/rookmate/undertow/game/bosses/lung.gd:119) damages a circular quadrant with radius six tiles. [lung.gd:207](/home/homebox/Documents/rookmate/undertow/game/bosses/lung.gd:207) draws a square quadrant extending only `6 × 0.72 = 4.32` tiles along each axis.

   This creates unmarked damaging ground. For example, the shipped boss is at `(38,8)`, and the walkable seawall at `(37,3)` is in its FAR quadrant, about 5.10 tiles away. It satisfies `in_flood()` while lying outside the drawn flood polygon. Conversely, the polygon’s far corner extends slightly beyond the damaging circle.

   Use one shape definition for the telegraph, fill, and damage predicate. Test points near every edge and corner; testing quarter selection alone cannot catch this mismatch.

3. **Medium — New tall props block movement but let sight, swings, and shots pass through. Confirmed.**

   [level_grid.gd:255](/home/homebox/Documents/rookmate/undertow/core/level_grid.gd:255) still recognizes only buildings and the old `"Kt|R"` characters as line blockers. New ambulances, turbines, and newsroom desks are solid, but none qualifies under that predicate ([level_grid.gd:43](/home/homebox/Documents/rookmate/undertow/core/level_grid.gd:43)).

   The shipped Mercy ambulance cells `(9,21)`, `(10,21)`, and `(11,21)` consequently block walking while providing no cover from projectiles. Projectile collision uses this grid predicate ([projectile.gd:41](/home/homebox/Documents/rookmate/undertow/game/weapons/projectile.gd:41)). Feed flashes also use it ([level.gd:660](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:660)), so newsroom desks do not screen the Feed.

   Add explicit tile traits for movement and line blocking, including the new tall props. Keep low partitions distinguishable from tall blockers. This classification should live alongside the named tiles rather than remain a separate string of legacy characters.

4. **Medium — Greywater entity markers erase the terrain properties underneath them. Confirmed.**

   The grid gives shared entity markers their old fixed floor types: Custodians and Salvagers become cobble; Waiting figures become pavement ([level_grid.gd:14](/home/homebox/Documents/rookmate/undertow/core/level_grid.gd:14), [level_grid.gd:27](/home/homebox/Documents/rookmate/undertow/core/level_grid.gd:27)). Flooding and Marrow detection inspect those stored types or characters ([level_grid.gd:241](/home/homebox/Documents/rookmate/undertow/core/level_grid.gd:241)).

   In the shipped map, Custodian `(9,10)` and Salvager `(23,17)` replace low-street cells. Their cells never flood, even after the enemies move away. Waiting figure `(28,10)` replaces a cell surrounded entirely by Marrow, so that cell is not treated as Marrow and appears indexed on the Steward’s map ([minimap.gd:148](/home/homebox/Documents/rookmate/undertow/ui/hud/minimap.gd:148)).

   The renderer already borrows surrounding terrain for markers, but explicitly does so for drawing only ([floor_layer.gd:84](/home/homebox/Documents/rookmate/undertow/game/level/floor_layer.gd:84)). That creates disagreement between appearance and gameplay.

   Preserve terrain separately from entity placement and make drawing, flooding, footing, fog, and routing consume the same terrain value. More Act 3 terrain types will multiply this problem otherwise.

5. **Medium — The Surgeon repeatedly interrupts its incision warning before the recording finishes. Confirmed timing defect; audible impact not assessed.**

   Each MARK starts `surgeon_incision` ([surgeon.gd:88](/home/homebox/Documents/rookmate/undertow/game/bosses/surgeon.gd:88)). The next MARK starts approximately 1.65 seconds later: one second marking plus the 0.35-second cut and 0.30-second recovery ([surgeon.gd:139](/home/homebox/Documents/rookmate/undertow/game/bosses/surgeon.gd:139)).

   Read-only `ffprobe` inspection gives the shipped recording a duration of **2.335 seconds**. `Sound.say()` stops the previous recording when a new one starts ([sound.gd:223](/home/homebox/Documents/rookmate/undertow/autoload/sound.gd:223)). During an uninterrupted three-cut cycle, the first two incision recordings therefore lose approximately their final 0.69 seconds. The first cut also lands approximately 1.175 seconds after speech begins.

   Match recording length and warning cadence so the actionable instruction can finish. A voice-file existence check does not establish that combat dialogue is actually delivered. Listening is still needed to determine precisely what words are lost.

6. **Medium — Conversation trust checks do not independently verify Decision 137. Confirmed validation gap; current data is correct.**

   Decision 137 requires siding with one companion to give **+2/-1**, and saying nothing to give **0/0** ([DECISIONS.md:510](/home/homebox/Documents/rookmate/undertow/DECISIONS.md:510)).

   The integration test computes its expected values from the same JSON choice that `GameState.have_conversation()` applies ([test_conversations.gd:33](/home/homebox/Documents/rookmate/undertow/tests/integration/test_conversations.gd:33)). The campaign repeats that pattern ([autopilot_route.gd:142](/home/homebox/Documents/rookmate/undertow/autoload/autopilot/autopilot_route.gd:142)). Content validation checks only that trust changes are whole numbers ([conversations.gd:57](/home/homebox/Documents/rookmate/undertow/core/conversations.gd:57)).

   Changing all conversation deltas to zero would still satisfy these trust assertions and the content validator. They verify application of the data, not the required rule.

   Assert the independent +2/-1/0 contract for all three answers, both companions, and clamping at trust limits. Keep the existing data-application checks as additional coverage.

7. **Low — The conversation mutation API permits conversations when a companion is absent. Confirmed API defect; normal UI currently guards it.**

   [run_state.gd:108](/home/homebox/Documents/rookmate/undertow/core/run_state.gd:108) correctly suppresses pending conversations unless both companions have joined and remain present. However, [game_state.gd:160](/home/homebox/Documents/rookmate/undertow/autoload/game_state.gd:160) checks only district completion, previous consumption, side validity, and choice existence.

   Calling `have_conversation()` for a completed district with either companion absent still changes trust and permanently consumes the conversation, contradicting Decision 137. Ordinary Ark entry currently prevents that call, so this is an exposed contract inconsistency rather than a demonstrated normal-play failure. Future departure handling or alternate conversation entry points can bypass the UI guard.

   Enforce companion eligibility at the mutation boundary and test that rejected answers leave both trust and `conversations_had` unchanged.

8. **Low — Malformed conversation content produces runtime script errors before validation can explain the problem. Confirmed conditional failure; shipped JSON is valid.**

   [conversations.gd:35](/home/homebox/Documents/rookmate/undertow/core/conversations.gd:35) casts `choices` to `Dictionary` and immediately calls `.get()`. An array, string, or null produces an invalid call. `problems()` uses that accessor before validating the nested shape ([conversations.gd:53](/home/homebox/Documents/rookmate/undertow/core/conversations.gd:53)). The screen also assumes the same dictionary shape ([conversation_screen.gd:36](/home/homebox/Documents/rookmate/undertow/ui/ark/conversation_screen.gd:36)).

   As conversations expand, a writer’s JSON mistake can abort validation or partially construct a screen instead of producing an actionable content diagnostic. Validate nested shapes and required string fields before exposing conversation data to callers; test malformed input explicitly.

9. **Low — Human companion dialogue uses the Steward-exclusive font. Confirmed brief violation.**

   Noor’s and Teo’s opening lines and replies use `UiFonts.narration()` ([conversation_screen.gd:44](/home/homebox/Documents/rookmate/undertow/ui/ark/conversation_screen.gd:44), [conversation_screen.gd:69](/home/homebox/Documents/rookmate/undertow/ui/ark/conversation_screen.gd:69)). That function returns Fraunces Italic and explicitly reserves it for Steward speech ([ui_fonts.gd:33](/home/homebox/Documents/rookmate/undertow/ui/theme/ui_fonts.gd:33)).

   The brief makes the same restriction ([undertow-design-brief.md:191](/home/homebox/Documents/rookmate/undertow/undertow-design-brief.md:191)). Use the permitted human UI type treatment for companion speech and replies.

The stored gate evidence is consistent with the reported successful runs: **374 tests**, **198 campaign checks in 687.5 seconds**, the **30-second smoke run**, and **six district tours** passed. Those logs contain no `SCRIPT ERROR`, `ERROR`, or `WARNING` entries. I inspected that evidence rather than rerunning `tools/check.sh`, which imports and writes artifacts.

The passing gate does not cover the mist’s behavior after retreat or respawn, flood geometry boundaries, the new props’ line-blocking classification, or independent conversation trust values. Voice intelligibility, real controller and Steam Deck behavior, Feed flash photosensitivity, and human boss balance remain unverified.
## Round 1: what was done

All nine findings were fixed (DECISIONS 138). Each has a regression test that fails on the old code.

1. **Surgeon mist everywhere (high).** `Surgeon.in_mist()` is now an annulus: beyond `MIST_SAFE` (2) and
   within `MIST_REACH` (5.5 tiles) of the table. The drawing uses the same two radii: the red-orange
   clear ring, the mist's outer ring and the fill between them. Tests:
   `test_surgeon::test_the_mist_stays_in_the_theatre` (backing off past its reach) and
   `test_back_at_a_checkpoint_the_mist_cant_reach_you` (the real Mercy General: engaged, respawned,
   mist phase, no damage).
2. **Lung flood shape (medium).** One shape: `Lung.flood_rect(quarter)` (a 4.5-tile square) drives
   the warning outline, the water fill and `in_flood()`. Test: `test_lung::test_the_flood_is_exactly_the_square_drawn`
   (just inside every corner of each quarter is wet; just outside each edge is dry).
3. **Tall props didn't block lines (medium).** `LevelGrid.TALL` and `LevelGrid.LOW` (with `Tiles.TALL`
   and `Tiles.LOW` for named tiles) classify every solid thing. `blocks_line()` uses `TALL`: ambulances,
   turbines and crane legs now stop sight, swings and shots. Ward partitions (cut to waist height),
   newsroom and nurses' desks, beds and tide gauges stay low, deliberately. Test:
   `test_level_grid::test_every_solid_thing_is_tall_or_low` (every solid character is exactly one of
   building, tall or low, so a new prop can't come in unclassified; plus an ambulance, a partition and
   a turbine checked on the real maps).
4. **Markers erased terrain (medium).** `LevelGrid` now keeps the terrain under each marker (the
   commonest of its four neighbours) and `floor_at()`, `floods()`, `is_marrow()` and `is_indexed()` read
   it. The floor layer draws `grid.floor_at()` (its own borrowing rule is gone), so drawing and gameplay
   agree. Off-path markers (`T`, `U`, `w`) are never indexed, whatever they stand on: the Loop's cache
   sits on a cab floor. Test: `test_level_grid::test_placed_things_stand_on_the_ground_around_them`
   (Greywater's Custodian and Salvager cells flood; the Waiting at (28,10) stand in the Marrow; the
   Loop's cache stays off the Lattice).
5. **Calls cut mid-word (medium).** Every boss now lists its calls with the soonest the next call can
   come (`CALL_GAPS`, built from its own timing constants). `test_boss_calls` checks every recording
   ends at least 0.1 s before that, and that every boss line is listed. This found more than the
   Surgeon: the Crane's drop and swing, the Lung's left basin and surge, and both of the Editor's
   warnings were cut too. Those lines were shortened (the Crane's timing is unchanged).
   Two more ways a warning got cut:
   - Each boss's introduction (its `boss_engaged` line) was cut in the same frame by its first call.
     A fight now waits while the Steward introduces it: at once if muted or cut short, six seconds at
     most.
   - "Priority" narration could interrupt a warning. Narration now never cuts off a warning being
     said.

   Tests: `test_the_fight_waits_for_the_introduction` and `test_narration_never_cuts_a_warning_off`.
6. **Conversation trust not independently checked (medium).** The +2/−1/0 rule is now code
   (`Conversations.TRUST`), not JSON. Tests assert the literal rule for each answer and companion,
   check the applied sequence (2/−1, then 1/1, then unchanged) against literal values, and check
   clamping at both limits. The campaign's check uses literal moves too.
7. **Conversation API ignored absent companions (low).** `GameState.have_conversation()` refuses
   unless both are here. Test: `test_with_one_of_them_gone_nothing_is_had` (trust and
   `conversations_had` unchanged).
8. **Malformed conversation content (low).** `Conversations.problems_in()` validates any shape
   (non-table, wrong-typed lines, answers missing or not tables) and reports instead of failing. The
   accessors (`line()`, `answer_text()`) only ever return strings, and the screen uses them. Test:
   `test_malformed_conversations_are_explained_not_crashed_on`.
9. **Companions in the Steward's font (low).** Noor's and Teo's lines and replies use Barlow
   (`UiFonts.label()`). New `test_font_rules` keeps `UiFonts.narration()` to an allow-list of
   Steward-speech scripts.

## Round 2 findings (verbatim from sol_analyst)

Scope: `git diff e03edd7..c4a61dd`, the round 1 fixes being `34158aa..c4a61dd`.

I would keep milestone 3 open. Eight Round 1 findings are resolved; finding 5 is only partly resolved. Two confirmed medium-severity problems remain.

Reviewed `e03edd7..c4a61dd`, including the fixes in `34158aa..c4a61dd`, without editing files. “Confirmed” means established from source, shipped content, or read-only calculations. It does not imply a fresh gameplay reproduction.

1. **Medium — Fixed narration still interrupts warnings, including during the Lung fight. Confirmed.**

   The new protection applies only to [narrator.gd:66](/home/homebox/Documents/rookmate/undertow/autoload/narrator.gd:66). `say_fixed()` goes through `speak_text()`, which emits the replacement line without checking whether a warning is still playing. See [narrator.gd:103](/home/homebox/Documents/rookmate/undertow/autoload/narrator.gd:103). [sound.gd:234](/home/homebox/Documents/rookmate/undertow/autoload/sound.gd:234) then stops the previous recording.

   This occurs between autonomous hazards in the shipped Greywater district: [tide.gd:80](/home/homebox/Documents/rookmate/undertow/game/level/tide.gd:80) speaks `tide_swell`, while [lung.gd:93](/home/homebox/Documents/rookmate/undertow/game/bosses/lung.gd:93) speaks each basin warning. Their schedules are independent.

   Read-only `ffprobe` measurements give `lung_near` **2.660 seconds** and `tide_swell` **3.569 seconds**. A tide warning starting one second into `lung_near` cuts its remaining 1.660 seconds. The next basin call, normally 2.8 seconds after the first, then cuts the tide warning with approximately 1.769 seconds remaining. Fixed facts, such as `waiting_refusal`, also bypass the protection.

   [test_boss_calls.gd:17](/home/homebox/Documents/rookmate/undertow/tests/integration/test_boss_calls.gd:17) compares recordings only against their own boss’s declared cadence. Its interruption test exercises `notify("multi_kill")`, not fixed narration or competing hazards. The campaign likewise checks that a Lung call appears, not that it finishes: [greywater_route.gd:146](/home/homebox/Documents/rookmate/undertow/autoload/autopilot/routes/greywater_route.gd:146).

   Protect warnings at the common narration boundary and explicitly resolve tide/boss timing conflicts. Add tests for a fixed fact interrupting a warning and for the real Greywater tide overlapping a Lung call.

2. **Medium — Upgrading from Act 1 silently removes valid saved Q/LB bindings. Confirmed.**

   Act 2 assigns Q and LB to `use_item`: [controls.gd:31](/home/homebox/Documents/rookmate/undertow/autoload/controls.gd:31). Neither input belonged to a default action at `e03edd7`, so a player could legitimately save Dodge on Q or LB.

   Loading those settings now produces a conflict with the new default. [controls.gd:207](/home/homebox/Documents/rookmate/undertow/autoload/controls.gd:207) resolves conflicts by deleting saved overrides, restoring Dodge to Space/A. The previously saved dodge input now uses a dressing.

   I followed the loader’s conflict algorithm in a read-only calculation using an old valid configuration. Both Dodge overrides were removed. [options.gd:58](/home/homebox/Documents/rookmate/undertow/autoload/options.gd:58) uses this loader directly, with no migration.

   The existing round-trip test misses the upgrade case. It binds Dodge to Q under the new input map, which also saves a compensating `use_item` swap: [test_options.gd:34](/home/homebox/Documents/rookmate/undertow/tests/integration/test_options.gd:34).

   Preserve existing valid choices when introducing an action, assigning the new action a nonconflicting binding. Test loading Act 1 settings with Q and LB occupied and no `use_item` entry.

The Round 1 closure check is:

| Finding | Result | Evidence and regression coverage |
|---|---|---|
| 1. Surgeon mist throughout the hospital | Resolved | [surgeon.gd:129](/home/homebox/Documents/rookmate/undertow/game/bosses/surgeon.gd:129) bounds exposure to the shared 2–5.5 tile annulus. [test_surgeon.gd:85](/home/homebox/Documents/rookmate/undertow/tests/integration/test_surgeon.gd:85) checks retreat beyond its reach; the following test checks respawn in shipped Mercy General. |
| 2. Lung drawing/damage mismatch | Resolved | [lung.gd:132](/home/homebox/Documents/rookmate/undertow/game/bosses/lung.gd:132) supplies one rectangle to damage and drawing. [test_lung.gd:62](/home/homebox/Documents/rookmate/undertow/tests/integration/test_lung.gd:62) checks all quarters’ corners and outer edges. |
| 3. Tall props allow shots through | Resolved under Decision 138’s revised classification | [level_grid.gd:301](/home/homebox/Documents/rookmate/undertow/core/level_grid.gd:301) uses `TALL`. Ambulances, turbines and crane legs block lines; desks and partitions deliberately remain low. [test_level_grid.gd:171](/home/homebox/Documents/rookmate/undertow/tests/unit/test_level_grid.gd:171) checks complete solid classification and real-map examples. |
| 4. Markers erase underlying terrain | Resolved | [level_grid.gd:123](/home/homebox/Documents/rookmate/undertow/core/level_grid.gd:123) records neighbouring terrain, consumed by floor, flood, Marrow and indexing queries. [test_level_grid.gd:153](/home/homebox/Documents/rookmate/undertow/tests/unit/test_level_grid.gd:153) covers the reported Greywater cells and the Loop cache. |
| 5. Interrupted boss calls | Partly resolved | Shortened recordings fit their bosses’ own cadences, and introduction waiting is implemented at [boss.gd:75](/home/homebox/Documents/rookmate/undertow/game/bosses/boss.gd:75). Fixed narration and competing hazards remain uncovered, as finding 1 above explains. |
| 6. Trust checks derive expectations from JSON | Resolved | [test_conversations.gd:29](/home/homebox/Documents/rookmate/undertow/tests/integration/test_conversations.gd:29) asserts literal +2/−1/0 values, applied sequences and clamping. Trust now belongs to code. |
| 7. Mutation permits absent companions | Resolved | [game_state.gd:164](/home/homebox/Documents/rookmate/undertow/autoload/game_state.gd:164) checks both companions before mutation. The absence test checks unchanged trust and conversation consumption. |
| 8. Malformed conversations crash validation | Resolved | [conversations.gd:63](/home/homebox/Documents/rookmate/undertow/core/conversations.gd:63) validates nested shapes; accessors return strings safely. [test_conversations.gd:65](/home/homebox/Documents/rookmate/undertow/tests/integration/test_conversations.gd:65) supplies malformed documents. |
| 9. Companions use Steward-exclusive typeface | Resolved | [conversation_screen.gd:42](/home/homebox/Documents/rookmate/undertow/ui/ark/conversation_screen.gd:42) and its speech builder use `UiFonts.label()`. [test_font_rules.gd:20](/home/homebox/Documents/rookmate/undertow/tests/unit/test_font_rules.gd:20) would reject the old conversation-screen use of `UiFonts.narration()`. |

I found no additional confirmed break in run-save serialization, targeting eligibility, colour/typeface ownership, or the earlier voice-table checks. The new weak points inherit the existing targeting exclusions. The terrain change retains explicit off-path exclusions, and the crane-leg line blocking follows Decision 138.

The stored evidence reports **388 passing tests**, **198 campaign checks in 705.6 seconds**, the **30-second smoke run**, and **six passing district tours**. I scanned all 17 check logs and found no engine errors, script errors, warnings or failed-result markers. See [tests.log:400](/home/homebox/Documents/rookmate/undertow/reports/check/tests.log:400) and [full_campaign.log:216](/home/homebox/Documents/rookmate/undertow/reports/check/full_campaign.log:216).

I inspected the regression assertions but did not execute old-code mutation checks or rerun the artifact-writing gate. The exact words lost during overlapping warnings, their frequency in ordinary play, re-voiced line intelligibility, and real hardware behaviour remain unverified.
## Round 2: what was done

Both findings fixed (DECISIONS 139), with tests that fail on the round 1 code.

1. **Fixed narration and competing hazards still cut warnings (medium).** The protection moved to the
   shared boundary: `Narrator.warning_in_progress()` is checked in `notify()` (all pooled narration)
   and in `speak_text()` (every fixed line). While a warning is being said, nothing else is, except a
   boss's own call (`Boss.call_out()` passes `urgent`). A boss's calls never cut each other, because
   its fight spaces them (`CALL_GAPS`, round 1). The Greywater conflict is resolved explicitly: the tide
   doesn't call while a boss is fighting in its district (`Tide.boss_fighting()`). The Lung's island is
   high ground; the tide still turns and its gauges still show it. Tests:
   `test_boss_calls::test_only_a_boss_call_cuts_a_warning_off` (a fixed fact and a non-boss warning
   wait; a boss call cuts in) and `test_the_tide_keeps_quiet_while_the_lung_fights` (the real
   Greywater: the tide calls before the fight, not during it).
2. **Act 1 settings lost Dodge on Q / LB (medium).** `Controls.set_overrides()` now first resolves any
   clash between a saved choice and another action's untouched default by moving that default to the
   first free spare (`Controls.SPARES`: F, R, G, C, X; RB, B). Only clashes left after that drop a
   saved choice, as before. Test: `test_controls::test_an_older_choice_keeps_its_input_when_a_new_action_wants_it`
   (Act 1 settings with Dodge on Q and LB and no use_item entry: Dodge keeps both, the dressing gets a
   spare key and button, nothing is shared, it survives a save and load, and a fresh start still has
   the dressing on Q).

## Round 3 findings (verbatim from sol_analyst)

Scope: `git diff e03edd7..13fa388`, the round 2 fixes being `c4a61dd..13fa388`.

I would keep milestone 3 open. The nine Round 1 defects are resolved under Decisions 138–139, and Round 2's narration fix holds. Round 2's input migration is still incomplete. I also found one smaller prompt regression.

Reviewed `e03edd7..13fa388`, including both fix ranges, without editing files. “Confirmed” means established from source, shipped data, or read-only calculations; it does not imply a fresh gameplay reproduction.

Confirmed findings, ranked by severity:

1. **Medium — Valid Act 1 bindings are still discarded when the declared spares are occupied.**

   [controls.gd:38](/home/homebox/Documents/rookmate/undertow/autoload/controls.gd:38) offers only RB and B as controller spares. [controls.gd:239](/home/homebox/Documents/rookmate/undertow/autoload/controls.gd:239) gives up if both are occupied, after which [controls.gd:219](/home/homebox/Documents/rookmate/undertow/autoload/controls.gd:219) deletes the conflicting saved override.

   A valid Act 1 configuration is:

   - Dodge on LB.
   - Primary attack on RB.
   - Secondary attack on B.

   I reproduced the loader's algorithm in a read-only calculation using the actual old and current binding tables. This configuration has **no Act 1 conflicts**. Loading it under Act 2 removes Dodge's LB override, restores Dodge to A, and assigns LB to the dressing. A and the old attack triggers were available for the new action.

   This still violates Decision 139's promise to preserve earlier choices. The new test at [test_controls.gd:53](/home/homebox/Documents/rookmate/undertow/tests/unit/test_controls.gd:53) supplies only Dodge overrides, leaving every spare free.

   Extend migration to use other available inputs, including defaults freed by existing remaps, before discarding a valid choice. Add occupied-spare upgrade cases for controller and keyboard, then verify save/load preservation.

2. **Low — The Clinic's dressing prompt becomes stale after rebinding while the screen remains open.**

   [clinic_screen.gd:35](/home/homebox/Documents/rookmate/undertow/ui/ark/clinic_screen.gd:35) constructs its instruction from `Controls.prompt("use_item")` once in `_ready()`. The screen has no binding-change or device-change refresh.

   The supported modal flow permits opening Pause and Options over the Clinic. See [pause_menu.gd:58](/home/homebox/Documents/rookmate/undertow/ui/pause/pause_menu.gd:58). Open the Clinic with Q assigned, rebind the dressing through Options, then return: its instruction still names Q although the binding changed.

   This violates Decision 89's requirement that prompts everywhere reflect current bindings, [DECISIONS.md:274](/home/homebox/Documents/rookmate/undertow/DECISIONS.md:274). Refresh the instruction on binding and device changes, and cover returning from nested Options. The Clinic tests currently do not exercise that flow.

The fix audit is:

| Recorded finding | Result and evidence |
|---|---|
| **R1 #1 — Surgeon mist reaches the whole hospital** | **Resolved.** [surgeon.gd:129](/home/homebox/Documents/rookmate/undertow/game/bosses/surgeon.gd:129) bounds exposure to the shared 2–5.5 tile annulus. [test_surgeon.gd:85](/home/homebox/Documents/rookmate/undertow/tests/integration/test_surgeon.gd:85) checks retreat; [test_surgeon.gd:97](/home/homebox/Documents/rookmate/undertow/tests/integration/test_surgeon.gd:97) checks respawn in shipped Mercy General. |
| **R1 #2 — Lung drawing and damage disagree** | **Resolved.** [lung.gd:132](/home/homebox/Documents/rookmate/undertow/game/bosses/lung.gd:132) defines the rectangle used by damage, outline and fill. [test_lung.gd:62](/home/homebox/Documents/rookmate/undertow/tests/integration/test_lung.gd:62) checks every quarter's inner corners and outer edges. |
| **R1 #3 — Tall props let lines through** | **Resolved under Decision 138.** [level_grid.gd:301](/home/homebox/Documents/rookmate/undertow/core/level_grid.gd:301) uses the explicit tall classification. [test_level_grid.gd:171](/home/homebox/Documents/rookmate/undertow/tests/unit/test_level_grid.gd:171) checks classification completeness and shipped props. Desks and partitions deliberately remain low; crane legs deliberately gained line blocking. |
| **R1 #4 — Markers erase terrain** | **Resolved for the reported cells.** [level_grid.gd:123](/home/homebox/Documents/rookmate/undertow/core/level_grid.gd:123) records neighbouring terrain; floor drawing and gameplay queries consume it. [test_level_grid.gd:153](/home/homebox/Documents/rookmate/undertow/tests/unit/test_level_grid.gd:153) checks both flooding spawns, the Marrow resident and the Loop cache's retained off-path exclusion. |
| **R1 #5 — Boss recordings are interrupted** | **Resolved for the recorded interruption causes.** Clips fit their declared cadences; [boss.gd:75](/home/homebox/Documents/rookmate/undertow/game/bosses/boss.gd:75) waits for introductions. [test_boss_calls.gd:17](/home/homebox/Documents/rookmate/undertow/tests/integration/test_boss_calls.gd:17) checks durations, and its subsequent tests cover introduction waiting and narration interruption. Actionable warning timing remains an inference below. |
| **R1 #6 — Trust assertions repeat content data** | **Resolved.** [conversations.gd:11](/home/homebox/Documents/rookmate/undertow/core/conversations.gd:11) owns the rule in code. [test_conversations.gd:29](/home/homebox/Documents/rookmate/undertow/tests/integration/test_conversations.gd:29) asserts literal deltas and applied outcomes; the following test checks clamping. |
| **R1 #7 — Absent companions permit mutation** | **Resolved.** [game_state.gd:164](/home/homebox/Documents/rookmate/undertow/autoload/game_state.gd:164) checks both companions before mutation. [test_conversations.gd:56](/home/homebox/Documents/rookmate/undertow/tests/integration/test_conversations.gd:56) checks unchanged trust and consumption after rejection. |
| **R1 #8 — Malformed conversations crash** | **Resolved.** [conversations.gd:63](/home/homebox/Documents/rookmate/undertow/core/conversations.gd:63) validates nested shapes; accessors safely return strings. [test_conversations.gd:65](/home/homebox/Documents/rookmate/undertow/tests/integration/test_conversations.gd:65) supplies malformed documents. |
| **R1 #9 — Companions use the Steward's font** | **Resolved.** [conversation_screen.gd:42](/home/homebox/Documents/rookmate/undertow/ui/ark/conversation_screen.gd:42) and its speech builder use Barlow. [test_font_rules.gd:20](/home/homebox/Documents/rookmate/undertow/tests/unit/test_font_rules.gd:20) rejects the previous narration-font use. |
| **R2 #1 — Fixed speech and tide interrupt warnings** | **Resolved under Decision 139.** [narrator.gd:103](/home/homebox/Documents/rookmate/undertow/autoload/narrator.gd:103) protects fixed speech; pooled speech also checks the warning. Boss calls retain their explicit exception. [tide.gd:84](/home/homebox/Documents/rookmate/undertow/game/level/tide.gd:84) suppresses tide narration during fighting. [test_boss_calls.gd:79](/home/homebox/Documents/rookmate/undertow/tests/integration/test_boss_calls.gd:79) covers fixed interruptions and the following test covers shipped Greywater. |
| **R2 #2 — Upgrade loses saved Q/LB choices** | **Partly resolved.** The ordinary case passes; occupied spares still cause finding 1 above. |

The regression assertions address the original faults and would reject the old behaviour. I did **not** execute old-code mutation checks, so this is source-based verification rather than independently reproduced mutation-test evidence.

One medium-severity concern remains **inferred**: some instructions may finish too late for their hazard. `ffprobe` measures `surgeon_mist` at **2.950 seconds**, while mist starts damaging after approximately **1.1 seconds**, [surgeon.gd:153](/home/homebox/Documents/rookmate/undertow/game/bosses/surgeon.gd:153). `lung_near` lasts **2.660 seconds**, while flood damage can begin after approximately **1.5 seconds**, [lung.gd:154](/home/homebox/Documents/rookmate/undertow/game/bosses/lung.gd:154). `CALL_GAPS` verifies completion before the next call, not before damage. Listening is needed to establish when the actionable words arrive and whether the lead time is sufficient.

I found no additional confirmed break in run-save serialization, targeting eligibility, voice-table purposes, or colour/typeface ownership. All **187 voice IDs** have clips and matching manifest text, with no orphan manifest entries. Stable core, log and override IDs remain present. Earlier route checks are preserved, apart from the approved Gauntlet move and expanded Vellum card check.

The **17 stored check logs** contain no error, warning or failed-result markers. They substantiate [391 passing tests](/home/homebox/Documents/rookmate/undertow/reports/check/tests.log:403), [198 campaign checks in 713.9 seconds](/home/homebox/Documents/rookmate/undertow/reports/check/full_campaign.log:216), the 30-second run and six district tours. I inspected this evidence without rerunning the artifact-writing gate. Re-voiced line intelligibility and real hardware remain unverified.
## Round 3: what was done

Both confirmed findings and the inferred one were fixed (DECISIONS 140).

1. **The bindings migration still dropped choices with the spares taken (medium).**
   `Controls.spare_inputs(slot)` now offers, in order:
   - `SPARES`;
   - every action's default (so a default the player's own choices freed, like A once Dodge moved to
     LB);
   - any face, shoulder or stick button, or any letter or digit.

   A valid saved choice is only dropped if none of these is free. Test:
   `test_controls::test_an_older_choice_keeps_its_input_with_the_spares_taken`. It loads Act 1
   settings with every keyboard and controller spare occupied: every choice is kept, the dressing gets
   a key and a button, nothing is shared, and everything survives a save and load.
2. **The Clinic's prompt went stale (low).** The instruction is rebuilt on `Controls.bindings_changed`
   and `device_changed`. Test: `test_clinic::test_the_clinics_instruction_follows_the_binding`
   (rebinding to T while it's open, then switching to a controller).
3. **Warnings finishing after their hazard (inferred medium; acted on).** Each boss now lists how soon
   each warning's hazard lands (`WARN_LEADS`, from its own timing constants). New
   `test_every_warning_is_said_before_its_hazard_lands` requires every warning's recording to be no
   longer, and every boss warning to be listed. The old lines fail it, as Sol inferred: the Lung's
   basins (2.07–2.66 s against 1.5 s), the surge, the Surgeon's mist, the Editor's rollers, the Crane's
   swing and the Conductor's middle track.

   The calls are now a word or two ("In close.", "Left basin.", "Roll.", "Find the gap.", "Closer.",
   "Middle track."), all within their leads. The visible tells stay first; the voice confirms them.
   Listening is still needed to judge them.

## Round 4 findings (verbatim from sol_analyst)

Scope: `git diff e03edd7..26b712d`, the round 3 fixes being `13fa388..26b712d`.

The Round 3 fixes hold. I found no confirmed high- or medium-severity defect, but one low-severity gap remains in the warning-protection contract.

Reviewed `e03edd7..26b712d` and all three fix ranges without editing files. “Confirmed” means established from source, shipped content, or read-only calculations, not a fresh gameplay reproduction.

1. **Low — Screen voice-overs still cut off warnings. Confirmed contract defect.**

   The protection in [narrator.gd:107](/home/homebox/Documents/rookmate/undertow/autoload/narrator.gd:107) covers `speak_text()`, and pooled narration checks it separately. However, [narrator.gd:129](/home/homebox/Documents/rookmate/undertow/autoload/narrator.gd:129) lets `voice_over()` call `Sound.say()` without checking `warning_in_progress()`. [sound.gd:234](/home/homebox/Documents/rookmate/undertow/autoload/sound.gd:234) then stops the current recording.

   With the voice enabled, calling `Narrator.voice_over("core_greywater_power_pumps")` during `tide_swell` therefore replaces the warning. This also has a reachable screen transition: opening Greywater's Reliquary during the tide warning changes scene, and the first core card automatically receives focus and starts its voice-over. See [reliquary.gd:24](/home/homebox/Documents/rookmate/undertow/game/props/reliquary.gd:24), [core_choice.gd:32](/home/homebox/Documents/rookmate/undertow/ui/core_choice/core_choice.gd:32), and [core_choice.gd:96](/home/homebox/Documents/rookmate/undertow/ui/core_choice/core_choice.gd:96). Neither the scene router nor the level exit clears that warning first.

   The demonstrated normal-flow impact is limited because the player has left the hazard scene. Nevertheless, Decision 139's promise that only a boss call can interrupt a warning is still false. The interruption tests at [test_boss_calls.gd:85](/home/homebox/Documents/rookmate/undertow/tests/integration/test_boss_calls.gd:85) and [test_boss_calls.gd:100](/home/homebox/Documents/rookmate/undertow/tests/integration/test_boss_calls.gd:100) never exercise `voice_over()`.

   Apply the warning guard to `voice_over()` and add a regression assertion that an attempted core or log voice-over leaves the active warning unchanged. I did not execute the sequence above in Godot.

The fix audit is:

| Recorded finding | Result and evidence |
|---|---|
| R1 #1 — Surgeon mist reaches the whole hospital | **Resolved.** [surgeon.gd:135](/home/homebox/Documents/rookmate/undertow/game/bosses/surgeon.gd:135) bounds damage to the shared 2–5.5 tile annulus. [test_surgeon.gd:85](/home/homebox/Documents/rookmate/undertow/tests/integration/test_surgeon.gd:85) checks retreat beyond its reach; [test_surgeon.gd:97](/home/homebox/Documents/rookmate/undertow/tests/integration/test_surgeon.gd:97) checks respawn in shipped Mercy General. |
| R1 #2 — Lung drawing and damage disagree | **Resolved.** [lung.gd:141](/home/homebox/Documents/rookmate/undertow/game/bosses/lung.gd:141) defines the rectangle used by damage, outline and fill. [test_lung.gd:62](/home/homebox/Documents/rookmate/undertow/tests/integration/test_lung.gd:62) checks every quarter's inner corners and outer edges. |
| R1 #3 — Tall props allow lines through | **Resolved under Decision 138.** [level_grid.gd:301](/home/homebox/Documents/rookmate/undertow/core/level_grid.gd:301) uses the explicit tall classification. [test_level_grid.gd:171](/home/homebox/Documents/rookmate/undertow/tests/unit/test_level_grid.gd:171) checks classification completeness and shipped props. Desks and partitions deliberately remain low; crane legs deliberately gained line blocking. |
| R1 #4 — Markers erase terrain | **Resolved.** [level_grid.gd:123](/home/homebox/Documents/rookmate/undertow/core/level_grid.gd:123) derives marker terrain. Floor drawing uses that same value at [floor_layer.gd:21](/home/homebox/Documents/rookmate/undertow/game/level/floor_layer.gd:21); flooding, footing, indexing and Marrow detection consume it too. [test_level_grid.gd:153](/home/homebox/Documents/rookmate/undertow/tests/unit/test_level_grid.gd:153) covers the reported Greywater cells and the Loop cache's off-path exclusion. |
| R1 #5 — Boss recordings are interrupted | **Resolved for the original combat causes.** Recordings fit their declared cadences, and [boss.gd:75](/home/homebox/Documents/rookmate/undertow/game/bosses/boss.gd:75) waits for the introduction. The broader warning-protection promise remains incomplete as described above. |
| R1 #6 — Trust assertions repeat content data | **Resolved.** [conversations.gd:11](/home/homebox/Documents/rookmate/undertow/core/conversations.gd:11) owns the rule in code. [test_conversations.gd:29](/home/homebox/Documents/rookmate/undertow/tests/integration/test_conversations.gd:29) asserts literal +2/−1/0 values and applied outcomes; the following test checks clamping. The campaign also uses literal deltas. |
| R1 #7 — Absent companions permit mutation | **Resolved.** [game_state.gd:164](/home/homebox/Documents/rookmate/undertow/autoload/game_state.gd:164) checks both companions before mutation. [test_conversations.gd:56](/home/homebox/Documents/rookmate/undertow/tests/integration/test_conversations.gd:56) checks unchanged trust and consumption after rejection. |
| R1 #8 — Malformed conversations crash | **Resolved.** [conversations.gd:63](/home/homebox/Documents/rookmate/undertow/core/conversations.gd:63) checks nested shapes; accessors safely return strings. [test_conversations.gd:65](/home/homebox/Documents/rookmate/undertow/tests/integration/test_conversations.gd:65) supplies malformed documents. |
| R1 #9 — Companions use the Steward's font | **Resolved.** [conversation_screen.gd:42](/home/homebox/Documents/rookmate/undertow/ui/ark/conversation_screen.gd:42) and its speech builder use Barlow. [test_font_rules.gd:20](/home/homebox/Documents/rookmate/undertow/tests/unit/test_font_rules.gd:20) rejects the previous narration-font use. |
| R2 #1 — Fixed narration and tide interrupt warnings | **Resolved for fixed/pooled narration and the Lung/tide conflict; incomplete across all speech entry points.** The fixed guard and tide suppression hold. The remaining `voice_over()` bypass is the finding above. |
| R2 #2 / R3 #1 — Migration discards earlier bindings | **Resolved.** [controls.gd:249](/home/homebox/Documents/rookmate/undertow/autoload/controls.gd:249) includes spares, freed defaults and additional inputs, checking actual ownership before assigning one. [test_controls.gd:73](/home/homebox/Documents/rookmate/undertow/tests/unit/test_controls.gd:73) occupies every declared spare and checks preservation, conflict absence and save/load. |
| R3 #2 — Clinic prompt becomes stale | **Resolved.** [clinic_screen.gd:41](/home/homebox/Documents/rookmate/undertow/ui/ark/clinic_screen.gd:41) refreshes on binding and device changes. [test_clinic.gd:121](/home/homebox/Documents/rookmate/undertow/tests/integration/test_clinic.gd:121) checks rebinding while open and switching device. It changes Controls directly rather than navigating through nested Options. |
| R3 inferred concern — Instructions finish after their hazards | **Resolved for recording duration versus programmed lead time.** [test_boss_calls.gd:37](/home/homebox/Documents/rookmate/undertow/tests/integration/test_boss_calls.gd:37) checks every boss warning against `WARN_LEADS`; those declarations agree with the actual phase transitions. |

Independent `ffprobe` measurements confirm that all 14 boss warning recordings now fit their programmed leads. For example, `surgeon_mist` lasts **1.036 seconds** against its **1.1-second** lead; the Lung's basin calls last **0.943–1.080 seconds** against **1.5 seconds**. These measurements establish completion timing, not intelligibility or sufficient human reaction time.

I found no additional confirmed regression in run-save serialization, targeting eligibility, colour/typeface ownership, or the voice table. The new save fields have backward-compatible defaults, and existing weapon normalization remains intact. All **187 voice IDs** have clips and matching manifest text, with no orphan manifest entries. No earlier core, log, override or voice ID was removed. The earlier route checks remain, apart from the approved Gauntlet relocation and expanded Vellum coverage.

The regression assertions address the original failures and would reject the old behaviour. I inspected them in source; I did **not** execute historical mutation checks or rerun the artifact-writing gate.

All **17 stored check logs** are free of error, warning and failed-result markers. They substantiate [394 passing tests](/home/homebox/Documents/rookmate/undertow/reports/check/tests.log:406), [198 campaign checks in 724.0 seconds](/home/homebox/Documents/rookmate/undertow/reports/check/full_campaign.log:216), the 30-second run and six passing district tours.

No further inferred defect is established by this review. Listening to the re-voiced lines, human boss balance, and real controller/Steam Deck behaviour remain unverified.
## Round 4: what was done

The one finding (low) was fixed (DECISIONS 141).

1. **Screen voice-overs cut warnings (low).** `Narrator.voice_over()` now checks
   `warning_in_progress()` like every other entry point. That leaves `Boss.call_out` as the only way to
   cut a warning. Sol's example (opening a Reliquary during the tide warning) is now also resolved at
   its source: a level hushes a warning still being said as it leaves (`Level._exit_tree`). Its hazard
   is behind you, so the next screen's voice-over is heard. Test:
   `test_boss_calls::test_a_voice_over_waits_and_leaving_ends_the_warning`. During a warning, a card's
   and a record's voice-over both wait. Once the level is freed the warning has stopped, and the
   card's voice-over is said.

## Round 5 findings (verbatim from sol_analyst)

Scope: `git diff e03edd7..7526e3a`, the round 4 fix being `26b712d..7526e3a`.

All nine round 1 findings are resolved, and the round 2–4 fixes address the subsequent findings. I found **no confirmed new defect**. One low-severity, inferred Marrow edge case remains; its underlying behaviour is confirmed, but the design contract is ambiguous.

Reviewed clean HEAD `7526e3a` against `e03edd7`, including the four fix ranges. No files were changed.

**Inferred finding, ranked by severity**

1. **Low — guidance can reappear while the Operator stands inside the Marrow during a rising or high tide.**  
   Greywater blocks floodable navigation cells whenever the tide is above LOW ([level.gd:101](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:101)). When the current cell becomes blocked, the predictor starts from a nearby open cell ([path_predictor.gd:69](/home/homebox/Documents/rookmate/undertow/core/path_predictor.gd:69)); its Marrow check examines the resulting route, rather than the Operator’s current cell ([path_predictor.gd:79](/home/homebox/Documents/rookmate/undertow/core/path_predictor.gd:79)).

   On the shipped map, `(25, 7)` is Marrow and `(25, 6)` is dry seawall ([greywater.txt:39](/home/homebox/Documents/rookmate/undertow/data/levels/greywater.txt:39)). A read-only calculation using the map and navigation rules confirmed that HIGH tide closes `(25, 7)`, selects `(25, 6)` as the nearest open start, and leaves a 26-cell dry route to the actual goal `(39, 17)`. The predictor can therefore return guidance outside the fog while the Operator remains inside it. The renderer accepts that guidance without another Marrow check ([predicted_path.gd:41](/home/homebox/Documents/rookmate/undertow/game/path/predicted_path.gd:41)).

   **Why inferred:** Decision 129 says no path is drawn *into* the Marrow, which could permit visible guidance outside it. However, the integration test describes the stronger behaviour—no prediction while standing inside—and only checks an interior cell at LOW tide ([test_greywater.gd:102](/home/homebox/Documents/rookmate/undertow/tests/integration/test_greywater.gd:102)). If that stronger contract is intended, reject prediction when `here` is Marrow and test boundary cells through all tide phases. I did not reproduce the rendered effect in Godot.

**Confirmed fix verification**

| Recorded finding | Result and evidence |
|---|---|
| Surgeon mist damages the whole hospital | Resolved. Damage is bounded by the same inner and outer radii used for drawing ([surgeon.gd:135](/home/homebox/Documents/rookmate/undertow/game/bosses/surgeon.gd:135)). Tests cover retreat and checkpoint respawn ([test_surgeon.gd:85](/home/homebox/Documents/rookmate/undertow/tests/integration/test_surgeon.gd:85), [test_surgeon.gd:97](/home/homebox/Documents/rookmate/undertow/tests/integration/test_surgeon.gd:97)). |
| Lung flood damage differs from its drawn square | Resolved. Drawing and damage share `flood_rect`; tests probe all quarters’ edges and corners ([lung.gd:141](/home/homebox/Documents/rookmate/undertow/game/bosses/lung.gd:141), [test_lung.gd:62](/home/homebox/Documents/rookmate/undertow/tests/integration/test_lung.gd:62)). |
| Tall props fail to block targeting and shots | Resolved under Decision 138’s height classification. Ambulances, turbines and crane legs block lines; deliberately low desks and partitions do not ([level_grid.gd:49](/home/homebox/Documents/rookmate/undertow/core/level_grid.gd:49), [test_level_grid.gd:171](/home/homebox/Documents/rookmate/undertow/tests/unit/test_level_grid.gd:171)). |
| Marker cells erase flooding and Marrow terrain | Resolved. Floor, flooding, Marrow and indexing read the shared terrain value. Regression assertions cover the reported Greywater cells and preserve an earlier milestone’s off-path cache ([level_grid.gd:236](/home/homebox/Documents/rookmate/undertow/core/level_grid.gd:236), [test_level_grid.gd:153](/home/homebox/Documents/rookmate/undertow/tests/unit/test_level_grid.gd:153)). |
| Boss calls are cut short or arrive after damage | Resolved for recorded clip durations. Tests check every boss call against its gap and every boss warning against its hazard lead; they also exercise introduction waiting and narration interruptions ([test_boss_calls.gd:25](/home/homebox/Documents/rookmate/undertow/tests/integration/test_boss_calls.gd:25), [test_boss_calls.gd:37](/home/homebox/Documents/rookmate/undertow/tests/integration/test_boss_calls.gd:37), [test_boss_calls.gd:57](/home/homebox/Documents/rookmate/undertow/tests/integration/test_boss_calls.gd:57)). |
| Trust tests merely repeat incorrect data | Resolved. Trust is code-owned `+2 / -1 / 0`; tests assert literal expected changes and the resulting state ([conversations.gd:11](/home/homebox/Documents/rookmate/undertow/core/conversations.gd:11), [test_conversations.gd:29](/home/homebox/Documents/rookmate/undertow/tests/integration/test_conversations.gd:29)). |
| Conversations mutate state with a companion absent | Resolved at the mutation boundary, before consumption or trust changes ([game_state.gd:164](/home/homebox/Documents/rookmate/undertow/autoload/game_state.gd:164), [test_conversations.gd:56](/home/homebox/Documents/rookmate/undertow/tests/integration/test_conversations.gd:56)). |
| Malformed conversation choices crash validation | Resolved. Validation checks nested shapes and text types; accessors also guard their casts ([conversations.gd:43](/home/homebox/Documents/rookmate/undertow/core/conversations.gd:43), [conversations.gd:63](/home/homebox/Documents/rookmate/undertow/core/conversations.gd:63), [test_conversations.gd:65](/home/homebox/Documents/rookmate/undertow/tests/integration/test_conversations.gd:65)). |
| Companion dialogue uses the Steward’s typeface | Resolved. Companion speech and replies use the human label font; the source-scanning ownership test excludes the conversation screen ([conversation_screen.gd:42](/home/homebox/Documents/rookmate/undertow/ui/ark/conversation_screen.gd:42), [test_font_rules.gd:20](/home/homebox/Documents/rookmate/undertow/tests/unit/test_font_rules.gd:20)). |

The regression assertions distinguish the reported old failures from the current behaviour. I checked that against the historical implementations; I did **not** run the tests against historical checkouts.

The later fixes also hold:

- Saved Q/LB bindings survive the new dressing defaults, including when every original spare is occupied. Tests preserve all earlier choices and reload the migrated configuration ([test_controls.gd:53](/home/homebox/Documents/rookmate/undertow/tests/unit/test_controls.gd:53), [test_controls.gd:73](/home/homebox/Documents/rookmate/undertow/tests/unit/test_controls.gd:73)).
- The Clinic prompt subscribes to binding and device changes, with a live-screen regression test ([clinic_screen.gd:41](/home/homebox/Documents/rookmate/undertow/ui/ark/clinic_screen.gd:41), [test_clinic.gd:121](/home/homebox/Documents/rookmate/undertow/tests/integration/test_clinic.gd:121)).
- Pooled narration, fixed speech and screen voice-overs respect warnings. Boss calls retain the explicit urgent exception, tide narration yields during fights, and leaving a level hushes its remaining warning ([narrator.gd:103](/home/homebox/Documents/rookmate/undertow/autoload/narrator.gd:103), [narrator.gd:130](/home/homebox/Documents/rookmate/undertow/autoload/narrator.gd:130), [level.gd:166](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:166)). Tests cover each interruption path and the level-exit transition ([test_boss_calls.gd:85](/home/homebox/Documents/rookmate/undertow/tests/integration/test_boss_calls.gd:85), [test_boss_calls.gd:136](/home/homebox/Documents/rookmate/undertow/tests/integration/test_boss_calls.gd:136)).

I found no additional break in the checked save, voice, targeting, colour/typeface, input or autopilot contracts. New save fields have compatible defaults and preserve the existing weapon migration ([run_state.gd:174](/home/homebox/Documents/rookmate/undertow/core/run_state.gd:174)). All **187 voice IDs** have matching manifest text and clips; manifest hashes are current, and earlier voice/core/log IDs remain. Independent duration inspection confirmed that the 14 boss warning recordings fit their declared leads. Earlier autopilot assertions remain or have explicit design-backed replacements, including the moved Gauntlet and expanded Vellum offer.

Stored validation corroborates **395 passing tests**, **198 campaign checks in 712.5 seconds**, the **30-second smoke run**, and six district tours ([tests.log:407](/home/homebox/Documents/rookmate/undertow/reports/check/tests.log:407), [full_campaign.log:216](/home/homebox/Documents/rookmate/undertow/reports/check/full_campaign.log:216), [smoke.log:20](/home/homebox/Documents/rookmate/undertow/reports/check/smoke.log:20)). I did not rerun the gate because it writes repository artifacts and user state. Re-voiced intelligibility and real hardware remain unverified; timing and manifest consistency do not establish either.
## Round 5: what was done

No confirmed defect. The one inferred finding (low) was acted on, taking the stronger contract (the
existing test's "no path in the fog", DECISIONS 142).

1. **Guidance from inside the Marrow at high tide (low, inferred).** `PathPredictor.predict()` returns
   nothing when the Operator's own cell is Marrow, before it looks for an open start nearby. Test:
   `test_greywater::test_no_path_from_anywhere_in_the_marrow_whatever_the_tide`. It covers every
   walkable Marrow cell beside open ground, (25, 7) included, in all four tide phases. It was run
   against the old predictor and fails there (SWELL at (25, 7) to (29, 7) drew a path), and it passes
   with the fix.
