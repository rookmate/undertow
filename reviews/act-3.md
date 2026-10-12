# Milestone review: Act 3 and the ending (milestone 4)

Reviewer: **sol_analyst** (Sol 6.1, xhigh, read-only) via the "Sol analysis" skill, run through
`codex exec -s read-only`. Scope: `git diff 3a24472~1` against the working tree (steps 25–32: Act 3's
plan, Reduce flashing, Harbor Ward and its Wardens, the Signal Jammer, the quiet trail, the
Warden-Prime and Noor's turn, the Mast and the Commons' people, the Spire and Teo's turn, the Council
Chamber, the final choice and the epilogues, the campaign to an ending). Author of the code under
review: Claude Code (Claude Opus 5.5).

## Round 1 findings (verbatim from sol_analyst)

Milestone 4 is not ready to call done. I found five P2 issues. No P0 or P1 defect was confirmed.

Reviewed `git diff 3a24472~1` against the working tree, including uncommitted Step 32. No files were edited. Findings below distinguish code facts confirmed by inspection from inferred player-visible consequences.

1. **P2 — Spire confessions can interrupt one another and be cut off by the Reliquary screen.**

   Confirmed: [autoload/narrator.gd:67](/home/homebox/Documents/rookmate/undertow/autoload/narrator.gd:67) protects pooled narration with `in_full_in_progress()`. Neither `speak_text()` at line 109 nor `voice_over()` at line 150 applies that guard. `say_in_full()` uses this unprotected fixed-line path, and [autoload/sound.gd:240](/home/homebox/Documents/rookmate/undertow/autoload/sound.gd:240) stops the previous recording when another starts. [game/props/confession.gd:42](/home/homebox/Documents/rookmate/undertow/game/props/confession.gd:42) marks a confession said before attempting narration, with no retry.

   Inferred consequence: walking onward normally truncates important admissions. The Quiet and Need triggers are only five grid steps apart, at [data/levels/the_spire.txt:22](/home/homebox/Documents/rookmate/undertow/data/levels/the_spire.txt:22). `ffprobe` reports the Quiet recording lasts 4.3 seconds; that walk takes approximately 1.6 seconds at normal speed. Opening the nearby Reliquary can likewise replace the 9.5-second Need recording with a core voice-over.

   The campaign masks this by deliberately waiting after each confession, [autoload/autopilot/routes/spire_route.gd:129](/home/homebox/Documents/rookmate/undertow/autoload/autopilot/routes/spire_route.gd:129). Queue protected narration at the shared boundary and test continuous movement and opening the Reliquary during a confession.

2. **P2 — Retrying Noor’s carry accumulates additional curfew patrols.**

   Confirmed: every carry calls the patrol spawner, [ui/hud/noor_choice.gd:75](/home/homebox/Documents/rookmate/undertow/ui/hud/noor_choice.gd:75). [game/level/level.gd:648](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:648) creates fresh Wardens at both patrol markers without checking for an existing patrol. Dropping Noor resets only her `carried` flag at line 657; respawning does not remove those Wardens.

   Inferred consequence: carry, die, and carry again with the first patrol alive produces four patrol Wardens, then six on another retry. The intended two-Warden escape becomes progressively harder precisely when the player is struggling.

   Track the encounter’s patrol and reuse or reset it on retries. [tests/integration/test_warden_prime.gd:172](/home/homebox/Documents/rookmate/undertow/tests/integration/test_warden_prime.gd:172) checks dropping Noor, but never checks the next pickup.

3. **P2 — A failed ending save still proceeds to the epilogue and leaves the saved run continuable.**

   Confirmed: [ui/ark/final_choice.gd:131](/home/homebox/Documents/rookmate/undertow/ui/ark/final_choice.gd:131) chooses the ending, ignores `SaveFlow.checkpoint()`’s result, and transitions immediately. Checkpoint failure produces only a temporary notice. [ui/epilogue/epilogue.gd:98](/home/homebox/Documents/rookmate/undertow/ui/epilogue/epilogue.gd:98) returns to the title without another save attempt. The title determines completion from the saved file, [ui/title/title.gd:94](/home/homebox/Documents/rookmate/undertow/ui/title/title.gd:94), and its Quit button calls `Sound.quit()` directly at line 50.

   Inferred consequence: if the final write fails, the player can watch the ending, quit from the title, relaunch, and Continue the old pre-ending save. That contradicts the final choice and finished-run requirements.

   Use the existing retry/leave/stay save flow before relinquishing the run. Add an ending test with the existing failing-store fixture.

4. **P2 — Rewrite memory bypasses the established safe-write contract and silently ignores failure.**

   Confirmed: [autoload/save_service.gd:49](/home/homebox/Documents/rookmate/undertow/autoload/save_service.gd:49) opens `legacy.json` directly for writing, overwrites the previous file, and returns `OK` without checking the write result. It has no temporary-file verification or backup. [autoload/game_state.gd:197](/home/homebox/Documents/rookmate/undertow/autoload/game_state.gd:197) ignores even an explicitly returned open error. The existing protected persistence pattern is in [core/save_store.gd:43](/home/homebox/Documents/rookmate/undertow/core/save_store.gd:43).

   Inferred consequence: an I/O failure can lose the permanent Rewrite ring despite a successfully saved ending. A short write can also destroy a previously remembered Rewrite. Nothing retries or reconstructs that memory from the completed run.

   Reuse the verified-write pattern and make legacy persistence failure visible and recoverable. Cover failed writes, short writes, and malformed legacy data.

5. **P2 — Harbor content required by the plan is absent without a recorded departure.**

   Confirmed: [design/act-3.md:47](/home/homebox/Documents/rookmate/undertow/design/act-3.md:47) requires a dark Mast on Harbor’s highest roof and talkable Wardfolk who later come to the Commons. Harbor’s map has neither Wardfolk placement nor a roof Mast. Wardfolk are instantiated only on the Ark, [game/ark/ark_level.gd:81](/home/homebox/Documents/rookmate/undertow/game/ark/ark_level.gd:81), and roof-Mast drawing exists only for the Commons, [game/level/building_cell.gd:100](/home/homebox/Documents/rookmate/undertow/game/level/building_cell.gd:100).

   DECISIONS 144–168 describe the Commons additions but do not explicitly record dropping these Harbor requirements. Implement them or record the departure before claiming the plan is met.

The three questioned older-test changes are appropriate. They retain routing and invalid-location checks, update the Spire from unbuilt to locked, and verify that “still to come” matches catalog availability. I found no disabled tests or weakened gate checks in this diff. The two-frame screenshot wait retains assertions and addresses the described timing race. Gold/font allowlist additions have ownership explanations consistent with their uses; Steam calls remain inside the wrapper.

Existing logs confirm 451 passing tests, the 30-second smoke run, all three ending runs, and all eight district tours, with no matching error/warning lines. The campaign log was being rewritten during review and had no terminal PASS when inspected, so I cannot independently certify the latest complete gate. `bash -n tools/check.sh` passed. I did not rerun the write-producing gate during this read-only review.

I inspected the stored Spire and Council screenshots. The confession text is visibly dim when muted; readability on a small display remains a concern, not a confirmed functional failure. Real controller behavior and audible Unplug silence still require the stated hardware checks.

## Round 1 fixes

1. **Confessions are heard out, never cut.** `Narrator.say_in_full` queues a confession asked for while
   another is being said; the next is said when the last is over (dropped if the Steward can't say it
   then: muted, out of reach). While one is said, no other line cuts it: pool lines and other fixed
   lines don't start (`speak_text`), and screen voice-overs give way (`voice_over`), so opening the
   Reliquary doesn't replace the last one with a core card's line. Leaving the district drops what's
   still waiting. Test: `test_spire::test_walking_on_it_queues_what_it_says_next` (walking straight
   from the Quiet to the Need, a voice-over and another line tried meanwhile, leaving).
2. **The curfew patrol comes once.** `Level.call_the_curfew_patrol` spawns the two Wardens the first
   time Noor is picked up; carried again after being downed, the ones still standing hunt again and
   none are added. Test: `test_warden_prime::test_carried_again_the_same_patrol_comes_after_you`.
3. **The ending is saved before it plays.** `FinalChoice.confirm` sets the ending and goes through
   `SaveFlow.before_leaving`: if the save fails the player is asked (try again, go on without it, or
   stay); staying takes the ending back (`GameState.take_back_ending`) and returns to the doors with
   focus. Test: `test_endings::test_an_ending_that_cant_be_saved_asks_first` (failing store; stay,
   then leave).
4. **The Rewrite is remembered safely, and recoverably.** `legacy.json` is written by
   `SaveStore.save_record` the way the save is (temp file read back, last good copy kept as `.bak`),
   read by `load_record` with the backup answering for a malformed main file. It's written only after
   the ending is saved; a failure shows a notice. A saved run that ended in a Rewrite counts on its own
   (`SaveService.rewritten`), and the title writes the record down if it's missing
   (`settle_legacy`). Test: `test_endings::test_a_rewrite_is_remembered_safely_and_recoverably`
   (failed write, short write, malformed main file, malformed backup).
5. **Harbor Ward has the Ward's own Mast and its Wardfolk.** The boat-house by the gate (above the
   radio log) has the Ward's mast on its roof, dark; two Wardfolk stand on Net Lane by their doors and
   talk (the curfew, Noor going by: `commons.json` "in_the_ward"); once the Commons is built two of
   them stand by it on the Ark. Tests: `test_harbor::test_the_wards_mast_and_its_people`; the harbor
   route checks `wardfolk_in_the_ward` and `ward_mast_dark`.

Not changed: the readability concern about the dim confession text when muted (noted, not a defect);
real controller hardware and audible silence on real audio stay on the hardware checklist in
PROGRESS.md.

## Round 2 findings (verbatim from sol_analyst)

Milestone 4 is still not ready to call done. Four round-1 findings are fixed; Rewrite persistence is only partially fixed. Two P2 issues remain. No P0 or P1 defect was confirmed.

Reviewed HEAD `3fd0b1d`, the fixes in `git diff ab8fb77..HEAD`, and the milestone in `git diff 3a24472~1..HEAD`. No files were edited. The consequences below follow from the code; I did not reproduce them through write-producing runtime tests.

1. **P2 — A second failed Rewrite-record write leaves New Game able to erase the recovery source.**

   Confirmed: [ui/title/title.gd:49](/home/homebox/Documents/rookmate/undertow/ui/title/title.gd:49) ignores `settle_legacy()`’s result. New Game remains available and replaces the in-memory run at [ui/title/title.gd:104](/home/homebox/Documents/rookmate/undertow/ui/title/title.gd:104). Entering the first district saves that new run at [game/level/level.gd:132](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:132). [autoload/save_service.gd:19](/home/homebox/Documents/rookmate/undertow/autoload/save_service.gd:19) saves without settling outstanding Rewrite memory first. Its fallback at [autoload/save_service.gd:44](/home/homebox/Documents/rookmate/undertow/autoload/save_service.gd:44) examines the loaded current save, not an older completed Rewrite behind a readable current save.

   Inferred consequence: successfully save a Rewrite, fail its legacy write, and fail the title’s repair attempt. Start New Game. Once the new run saves successfully, `rewritten()` becomes false despite the previous Rewrite initially remaining in the slot backup. Subsequent saves rotate that backup away. The permanent cyan ring can be forgotten permanently.

   Preserve or settle the completed Rewrite before another run overwrites its recovery source, and handle settlement failure explicitly. The added recovery test at [tests/integration/test_endings.gd:262](/home/homebox/Documents/rookmate/undertow/tests/integration/test_endings.gd:262) covers successful settlement and failed writes with an existing good record, but not this sequence.

2. **P2 — A malformed legacy dictionary suppresses a valid backup.**

   Confirmed: [core/save_store.gd:55](/home/homebox/Documents/rookmate/undertow/core/save_store.gd:55) accepts any nonempty parsed dictionary as the main record. [core/save_store.gd:67](/home/homebox/Documents/rookmate/undertow/core/save_store.gd:67) checks JSON syntax and dictionary shape, without validating the legacy fields. The caller defaults a missing `rewrite` field to false at [autoload/save_service.gd:45](/home/homebox/Documents/rookmate/undertow/autoload/save_service.gd:45).

   Inferred consequence: with `legacy.json` containing `{"version":1}`, a valid `legacy.json.bak` containing `{"version":1,"rewrite":true}`, and a current non-Rewrite run, the title forgets the Rewrite. The good backup is never consulted, and `settle_legacy()` cannot recover it.

   Validate the legacy record before accepting the main file, falling back to a valid backup for missing or mistyped fields. The malformed-data cases at [tests/integration/test_endings.gd:281](/home/homebox/Documents/rookmate/undertow/tests/integration/test_endings.gd:281) cover broken JSON and an array, but miss malformed dictionaries.

The five round-1 findings stand as follows:

- **1, confession interruption — fixed.** [autoload/narrator.gd:134](/home/homebox/Documents/rookmate/undertow/autoload/narrator.gd:134) queues protected lines; `speak_text()` and `voice_over()` guard them at lines 117 and 172. District exit drops pending lines at [game/level/level.gd:177](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:177). The added Spire test verifies overlap, competing fixed lines, voice-overs, queue advancement and exit. No further defect was confirmed.
- **2, accumulating curfew patrols — fixed.** [game/level/level.gd:665](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:665) spawns once and reuses living patrol members. The retry test verifies enemy counts and renewed hunting.
- **3, silently proceeding after ending-save failure — fixed.** [ui/ark/final_choice.gd:130](/home/homebox/Documents/rookmate/undertow/ui/ark/final_choice.gd:130) awaits retry/leave/stay; staying rolls back the ending and restores door focus. Proceeding without saving now requires the player’s explicit choice.
- **4, unsafe and unrecoverable Rewrite memory — partially fixed.** The shared verified temporary-write implementation protects existing records against failed and short writes. The two recovery gaps above remain.
- **5, missing Harbor content — fixed.** The map places the dark mast and two Wardfolk. [game/level/level.gd:311](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:311) configures the mast; [game/level/level.gd:542](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:542) spawns talkable Wardfolk using the Ward-specific dialogue. Their Commons presence remains intact.

I found no other confirmed blocker in the milestone, no disabled tests or weakened gate checks, and no new gold, serif or Steam-boundary violation.

Stored gate evidence supports the reported pass: [456 tests](/home/homebox/Documents/rookmate/undertow/reports/check/tests.log:472), the 30-second smoke run, the completed campaign, all three ending runs and all eight district tours, with no matching error/warning lines. `bash -n tools/check.sh` passed. I did not rerun the write-producing gate. Real controller hardware, audible Unplug silence and small-display confession readability remain unverified.

## Round 2 fixes

1. **No save replaces an unrecorded Rewrite.** `SaveService.save_run` writes the Rewrite's record down
   first whenever a run on file (the save or its backup, read without side effects:
   `SaveStore.saved_runs`) ended in a Rewrite the record doesn't know about; if that write fails, the
   save fails too, so the player is told (a checkpoint notice, or the question before leaving) and the
   finished run stays on file. The title shows a notice if its own attempt fails. Test:
   `test_endings::test_a_new_run_cant_save_over_an_unrecorded_rewrite` (only the record's file fails:
   the Rewrite saves, the record can't be written, a new run can't save over it; once it can, the record
   is written first).
2. **A record is validated, not just parsed.** `save_record` / `load_record` take a validator
   (`SaveService.legacy_valid`: a true-or-false "rewrite"); an invalid main file is passed over for a
   valid backup, and is never rotated over it. Test:
   `test_endings::test_a_malformed_record_doesnt_hide_its_backup` (`{"version": 1}` over a good
   backup).

## Round 3 findings (verbatim from sol_analyst)

Milestone 4's code-review blockers are closed at `83d61fd`. Both round-2 P2 findings are fixed. I found no new confirmed P0, P1 or P2 blocker in `git diff 3fd0b1d..HEAD` or the full milestone, `git diff 3a24472~1..HEAD`. No files were changed.

1. **Former P2, New Game erasing an unrecorded Rewrite: fixed.**

   Confirmed: [autoload/save_service.gd:21](/home/homebox/Documents/rookmate/undertow/autoload/save_service.gd:21) settles legacy memory before calling `store.save()` and returns failure without replacing the run when settlement fails. Rewrite detection examines both slot files through [core/save_store.gd:67](/home/homebox/Documents/rookmate/undertow/core/save_store.gd:67), using reads that neither rename files nor invoke corrupt-save recovery. [ui/title/title.gd:50](/home/homebox/Documents/rookmate/undertow/ui/title/title.gd:50) reports a failed title settlement.

   The regression test at [tests/integration/test_endings.gd:306](/home/homebox/Documents/rookmate/undertow/tests/integration/test_endings.gd:306) covers the failed settlement, blocked new-run save and successful later recovery. Its stored result passes at [reports/check/tests.log:271](/home/homebox/Documents/rookmate/undertow/reports/check/tests.log:271).

   Inference from the control flow: the round-2 loss sequence can no longer rotate away the completed Rewrite before its permanent record is written. A Rewrite found only in the backup also receives this protection.

2. **Former P2, malformed legacy dictionary hiding a valid backup: fixed.**

   Confirmed: [autoload/save_service.gd:50](/home/homebox/Documents/rookmate/undertow/autoload/save_service.gd:50) requires a boolean `rewrite` field. [core/save_store.gd:57](/home/homebox/Documents/rookmate/undertow/core/save_store.gd:57) validates each candidate before accepting it. The record writer applies the same validator before rotating an existing main file into the backup, through [core/save_store.gd:51](/home/homebox/Documents/rookmate/undertow/core/save_store.gd:51) and [core/save_store.gd:105](/home/homebox/Documents/rookmate/undertow/core/save_store.gd:105).

   The malformed-dictionary regression test at [tests/integration/test_endings.gd:324](/home/homebox/Documents/rookmate/undertow/tests/integration/test_endings.gd:324) passes at [reports/check/tests.log:272](/home/homebox/Documents/rookmate/undertow/reports/check/tests.log:272).

   Inference from the validation branches: missing or mistyped `rewrite` fields cannot suppress a valid backup or be rotated over it.

The earlier confession, patrol, ending-save and Harbor-content fixes remain intact. I found no further confirmed correctness or structural blocker, disabled test, weakened gate check, gold/font ownership violation or Steam-wrapper violation. The new persistence behavior stays in the existing save layers and retains the shared verified-write path.

Stored validation evidence supports the reported gate pass: [458 tests](/home/homebox/Documents/rookmate/undertow/reports/check/tests.log:477), the [30-second smoke run](/home/homebox/Documents/rookmate/undertow/reports/check/smoke.log:20), the [completed campaign](/home/homebox/Documents/rookmate/undertow/reports/check/full_campaign.log:284), all three ending runs and all eight district tours. Scanning those logs found no gate-matching error or warning lines. `bash -n tools/check.sh` passed.

I did **not** rerun the write-producing gate under read-only access. Backup-only Rewrite recovery and mistyped legacy fields are verified by inspection rather than directly exercised by the two new tests. Real controller behavior, audible Unplug silence and small-display confession readability remain open validation checks.

## Round 3

No blocker remains. The two cases Sol verified only by inspection now have tests of their own:
`test_endings::test_a_mistyped_record_doesnt_hide_its_backup` and
`test_endings::test_a_rewrite_in_the_backup_still_counts`.

**Review closed after 3 rounds.** Still to confirm on hardware or by eye (PROGRESS.md, "What only
hardware can confirm"): a real controller through Act 3's screens, Unplug's silence on real audio, and
the confession text's readability on a small display.

