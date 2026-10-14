# Milestone review: the writing pass (milestone 6)

Reviewer: **sol_analyst** (Sol 6.1, xhigh, read-only) via the "Sol analysis" skill, run through
`codex exec -s read-only`. Scope: `git diff 0d17e13` against the working tree (steps 43 to 46: deep
district pools and the Waiting's own words, places, the arc, the logs and the ending menu). Author of the
code and the lines under review: Claude Code (Claude Opus 5.5).

## Round 1 findings (verbatim from sol_analyst)

Milestone 6 is substantially implemented, but I would not close it yet. The district writing, individual Waiting lines, Teo's stronger arguments and ending menu are real improvements. The remaining defects affect what the player hears, when they hear it, and whether the narration earns its claimed knowledge.

No P0 or P1 findings. The findings below are P2, ordered by impact. “Confirmed” means supported by the current code or content; inferred intent is identified separately.

1. **P2: “knows” means recovered, although the lines say the player has read the record.**

   Confirmed: [narrator.gd:108](/home/homebox/Documents/rookmate/undertow/autoload/narrator.gd:108) supplies `logs_unlocked` as the knowledge context. Taking a core unlocks its log immediately in [core_choice.gd:59](/home/homebox/Documents/rookmate/undertow/core/core_choice.gd:59). The Archive initially conceals that record until replayed, as [archive_screen.gd:189](/home/homebox/Documents/rookmate/undertow/ui/archive/archive_screen.gd:189) shows.

   Consequently, “You've read about the bridge” and “You've read the Council's order” become eligible before the player has seen either record ([steward_lines.json:3392](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:3392)). This spoils and misstates the player's discovery. Track records actually shown or read. Account for the Clinic's separate reading flow when choosing that state.

2. **P2: Continue forgets the narration history of the same run.**

   Confirmed: narration history lives in `selector.recent`; [narrator.gd:35](/home/homebox/Documents/rookmate/undertow/autoload/narrator.gd:35) connects every run replacement to `reset_session()`, which clears it. Continue calls `GameState.replace_run()` ([title.gd:123](/home/homebox/Documents/rookmate/undertow/ui/title/title.gd:123)). [run_state.gd:135](/home/homebox/Documents/rookmate/undertow/core/run_state.gd:135) saves no narration history.

   Saving and continuing therefore makes previously heard place lines and knowledge beats fresh again, and restarts reactive selection before its tone has been heard out. That breaks Decisions 192–194's promises about “this run.” Persist the relevant history and restore it on Continue; clear it for New Game.

3. **P2: Knowledge and revisit beats remain in the repeating pool.**

   Confirmed: [line_selector.gd:157](/home/homebox/Documents/rookmate/undertow/core/line_selector.gd:157) gives unheard beats priority, but the later ordinary selection and oldest-line fallback still include heard beats. A source-equivalent neutral selection trace using the current data produces:

   ```
   IDLE_KNOWS_BRIDGE
   LOOP_IDLE_N1
   LOOP_IDLE_N2
   IDLE_N1
   IDLE_KNOWS_BRIDGE
   ```

   Harbor's sole revisit greeting repeats on every subsequent revisit. This trace is a read-only model of the selection branches, not an engine reproduction.

   Decision 194 describes these learned-story lines as said “before the others, once.” The implementation guarantees their priority only once. If delivery is meant to be once per run, exclude heard beats from ordinary repetition and define the exhausted-pool fallback.

4. **P2: New beats can cut off important hold lines, and the gap does not protect silence after a recording.**

   Confirmed: [narrator.gd:65](/home/homebox/Documents/rookmate/undertow/autoload/narrator.gd:65) protects warnings and `say_in_full` lines. Ordinary facts have no equivalent protection. Hold lines use `say_fixed()` ([hold.gd:110](/home/homebox/Documents/rookmate/undertow/game/props/hold.gd:110)), and `path_left` is priority.

   For example, `greywater_pumps_done` says, “I could have done it in a minute. I didn't.” Its recording lasts 5.2 seconds. Leaving the Lattice during it can immediately replace it with `OFFPATH_LATE_N1`, losing the admission. This interruption mechanism predates the milestone, but the new beats use it unchanged.

   Also, `MIN_GAP` measures from a line's **start**. A 7.5-second place recording satisfies that gap before finishing, so another nearby place can begin as soon as it ends. Place selection itself does correctly avoid interrupting existing speech. Protect consequential hold lines and measure the intended silence from recording completion.

5. **P2: “Stop praising me” suppresses the new factual knowledge beats.**

   Confirmed: the bridge, Vashti and Council-order beats are `idle` lines, and `idle` has purpose `praise` ([steward_lines.json:47](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:47)). `Narrator.notify()` rejects that purpose before selecting a line.

   These beats discuss the Steward's history and reasoning without praising the player. They disappear under an order whose stated effect preserves warnings and facts ([overrides.json](/home/homebox/Documents/rookmate/undertow/data/overrides.json)). Give those beats a factual purpose without enabling the idle flattery alongside them.

6. **P2: Several new “precise” reactive remarks assert observations the game never checks.**

   Confirmed: `LOOP_HURT_B1` says, “It hit you and you hit back harder. That's three times today”; `LOOP_HURT_B2` says, “That's twice now” ([steward_lines.json:1263](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:1263)). Both can be selected on the first qualifying hurt event, before any counterattack. `MERCY_BOSSDOWN_B1` claims the Surgeon “never touched you.”

   [steward_watch.gd:116](/home/homebox/Documents/rookmate/undertow/game/level/steward_watch.gd:116) reports the hurt event, while [playstyle_profile.gd](/home/homebox/Documents/rookmate/undertow/core/playstyle_profile.gd) stores aggregate risk and caution scores. Neither selection context verifies those counts, counterattacks or flawless fights.

   The result undermines the intended impression that the Steward notices the player closely. Gate literal claims on actual observations, or rewrite them so they remain true for the event being reported.

7. **P2: The new Loop writing conflicts with its established history.**

   Confirmed: [steward_fixed.json:349](/home/homebox/Documents/rookmate/undertow/data/narration/steward_fixed.json:349) claims eleven years of announcements at Platform A. The authoritative world bible says the Loop opened six years ago ([undertow-world-bible.md:24](/home/homebox/Documents/rookmate/undertow/undertow-world-bible.md:24)).

   Teo's rewritten procurement reaction also claims human drivers ran red signals “on that ring” before its cabs were welded ([memory_logs.json:314](/home/homebox/Documents/rookmate/undertow/data/logs/memory_logs.json:314)). Its incompatibility is an inference from the bible's driverless opening and the procurement record's “NO MANUAL CONTROL FITTED.” A predecessor railway could justify the argument, but the line currently names this ring. Align both lines with the canon.

8. **P2: The live pools retain writing explicitly rejected by this pass's criteria.**

   Confirmed: “Two at once. The street's clearer,” “Both of them. You were made for this,” and “Just in time” remain selectable ([steward_lines.json:202](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:202)). The review explicitly identifies those constructions as play-by-play and cheerleader praise.

   They are reachable fallbacks, not unused legacy content. After Mercy's one neutral multi-kill line, the next neutral selection reaches `MULTI_N1`. The new Mercy line itself is “Two drones. That corridor's clear.”

   Rewrite or retire these reachable lines. Adding district nouns does not repair the absence of subtext or a continuing story.

The positive checks held. All **681 Steward lines** have Ogg files and matching manifest text, with no orphan manifest entries. The 465 pooled texts contain no exact duplicates or “I decided.” The new place path respects existing warnings and Spire confessions. I found no condition-induced empty pool for the checked Harbor, Spire, Ark or fixture events. Gold and serif ownership tests passed in the recorded run.

I found no weakened existing assertion: the adaptive-narration test now checks the selected event instead of an obsolete ID prefix, which is appropriate. The bot changes alter navigation rather than bypassing gameplay checks. The 2700-second campaign limit matches Decision 194.

Low-value nits, separate from findings: repeated “By hand,” “There,” “Halfway” and “You're badly hurt” openings remain conspicuous; several district lines share sentence templates. Individual instances are not blockers. `git diff --check` also reports a trailing blank line in `test_line_selector.gd`.

Validation limits: I reviewed `git diff 0d17e13`, the working tree, canon, code and recorded results without editing anything. Steps 43 and 44 have recorded full gate passes. The current gate passed import, **523 tests** and the smoke run; its campaign was still running when I finished. Actor delivery and narration density still need listening in play.

## Round 1 fixes

1. **"Knows" is what you've read.** `RunState.logs_read` (saved): a log replayed in the Archive
   (`ArchiveModel.replay`) or opened at the Clinic (`ClinicScreen.read`) goes in through
   `GameState.mark_log_read`. `Narrator.context_for` gives the lines `logs_read`, not `logs_unlocked`. An
   older save counts what it replayed as read. Test:
   `test_adaptive_narration::test_it_knows_what_youve_read` (carried isn't read; replayed is).
2. **Continue remembers what it said.** The heard-this-run list is `RunState.narration_heard`, saved with
   the run; `Narrator.selector.recent` is that list, so a new run starts with nothing heard and a
   continued one with what it had. Test: `test_adaptive_narration::test_continue_remembers_what_it_said`.
3. **A beat is said once.** Heard, a line for something you've come to know leaves the pool for the rest
   of the run, unless nothing else would be left (a district's only revisit greeting still greets every
   revisit). Test: `test_line_selector::test_a_beat_is_said_once` (twelve idle picks knowing the bridge:
   the bridge line once).
4. **Its story lines aren't cut off, and a place waits for a silence.** A hold's lines and a place's line
   go through `Narrator.say_story`; while one is being said, no remark starts over it, not even for
   leaving the path (a warning still can). A place's line also waits `PLACE_QUIET` (1.5 s) after the
   Steward last stopped talking, measured from when the recording ended, not when it began. Tests:
   `test_adaptive_narration::test_it_never_talks_over_its_story` (the pumps line, then `path_left`: still
   the pumps line), `test_places::test_it_waits_for_a_silence_after_a_long_line`.
   A first try made every line uninterruptible. Four test files failed: pool remarks could no longer
   replace each other, and in the Warden-Prime test a hurt remark no longer cut the boss's stage call,
   which made the stage pause long enough for its Wardens to finish you. The rule now covers only what
   the finding named: holds and places. A find's line and a boss's calls keep the old timing.
   `test_places`'s helper now waits that breath of silence after hushing the entry line, as the game does.
5. **Facts under "Stop praising me".** A line can carry its own `purpose`. The bridge, Vashti and
   Council-order idle beats, the late kill lines and the late on-path line are facts. `Narrator.notify`
   no longer refuses an event by its purpose up front; it passes `LineSelector.pick` the purposes
   allowed now, so those still play and the idle flattery stays silent. Test:
   `test_line_selector::test_what_it_knows_is_a_fact`.
6. **Only what it can see.** No counts it doesn't keep and no flawless fights it can't vouch for:
   LOOP_HURT_B1 "It hit you, and you went straight back at it. You always do."; LOOP_HURT_B2 "Bleeding,
   and still going forward. I've stopped being surprised."; TIDE_HURT_B2 "You took that on the arm and
   kept coming. I've started a list."; MERCY_BOSSDOWN_B1 "You went in under its lamp to finish it. I'd
   have stayed back." The careful multi-kill and halfway lines that claimed dry feet, no hits or eyes off
   the screens all the way now say what the moment shows (TIDE/GREY/VEL_MULTI_C1,
   MERCY/TIDE/GREY/VEL_CHECK_C1).
7. **Canon.** Platform A: "the same voice for six years" (the Loop opened six years ago). Teo's
   procurement reaction: "The old line had drivers, and they ran red signals twice a month. Nobody has
   died on this ring. Not once." (a predecessor railway, not this ring).
8. **The old lines for anywhere.** MULTI_N1 "Two of mine at once. They were built to work in pairs.";
   MULTI_B1 "Both. I've started planning around you."; DODGE_N1 "They were never built to miss. That one
   did."; KILL_N2 "One less thing still doing its last job."; KILL_C1 "You waited for it. I noticed. I
   notice everything you do."; HURT_B1 "You took that standing. I'll remember."; DODGE_B2 "Through it,
   not around it. Every time."

All 19 changed lines were voiced again (`tools/make_voice.py`); `test_voice` checks every recording
against its text.

Not fixed, with reasons:

- **Repeated openings ("By hand", "There", "Halfway", "You're badly hurt") and shared templates.**
  Sol lists these as nits, not blockers. Each instance reads fine where it is; they show only when the
  pools are read side by side. The writer and the voice actor take this further (this pass is first
  drafts, by design), and that's the right place to vary them.
- **The trailing blank line in `test_line_selector.gd`.** Already gone: `git diff --check` is clean.

## Round 2 findings (verbatim from sol_analyst)

Milestone 6 is not ready to close. The fixes for read state, Continue, protected story delivery and Loop continuity are sound. Three findings remain: two P2 defects and one P3 writing issue. No P0 or P1 findings.

1. **P2. Knowledge beats still repeat under "Stop praising me".**

   Confirmed: [line_selector.gd:146](/home/homebox/Documents/rookmate/undertow/core/line_selector.gd:146) removes heard beats only when that leaves a nonempty pool. Otherwise it restores the original pool. Under the override, [narrator.gd:89](/home/homebox/Documents/rookmate/undertow/autoload/narrator.gd:89) filters out ordinary idle praise, leaving only the factual knowledge beats.

   With just the bridge record read, the idle pool therefore contains only `IDLE_KNOWS_BRIDGE`. A read-only model of the actual purpose, condition and exhaustion branches produces that same ID on five consecutive selections. The runtime [idle path](/home/homebox/Documents/rookmate/undertow/game/level/steward_watch.gd:65) continues requesting narration while the player stands still, so this is reachable gameplay behavior.

   The exception for a district's sole revisit greeting is reasonable. Applying it to idle admissions brings back round 1's repetition defect, especially after the player has requested less flattery. Exhausted knowledge beats should leave silence; reserve repeatable greetings for the intended exception. The new tests separately check once-only selection and factual selection under the override, but [never combine those conditions](/home/homebox/Documents/rookmate/undertow/tests/unit/test_line_selector.gd:209).

2. **P2. Several rewritten observations still claim actions the game does not establish.**

   Confirmed: [LOOP_HURT_B1](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:1263) now says, "It hit you, and you went straight back at it." The hit handler [emits `hurt` immediately](/home/homebox/Documents/rookmate/undertow/game/player/operator.gd:318), and [StewardWatch](/home/homebox/Documents/rookmate/undertow/game/level/steward_watch.gd:116) immediately requests the line. It has not observed a subsequent advance or counterattack. Removing the count fixed half of the original problem.

   The rewritten [GREY_MULTI_C1](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:2327) says, "Two, from the high ground." Selection checks no terrain or player position. Greywater's low streets also [have Lattice coverage](/home/homebox/Documents/rookmate/undertow/core/level_grid.gd:309), so coverage does not make that claim true. [GREY_CHECK_C1](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:2495) still claims the player waited on the tide "all the way here", without tracking that behavior.

   Confirmed selection eligibility does not establish how often players will encounter these mismatches. The inferred consequence is the same as round 1: the supposedly attentive voice can contradict the action on screen. Gate these specific observations on actual behavior, or rewrite them around what the reported event establishes. Aggregate tone preference is insufficient evidence for a particular movement, position or uninterrupted history.

3. **P3. Round 1's writing finding is only partly fixed.**

   Confirmed: [MERCY_MULTI_N1](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:1942) remains "Two drones. That corridor's clear." Round 1 explicitly identified this line. It contributes the same play-by-play as the rewritten generic line used to, and is Mercy's first fresh neutral multi-kill remark.

   The reachable generic pool also retains ["You're hurt. Keep moving."](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:250), an exact example rejected by [the writing review](/home/homebox/Documents/rookmate/undertow/design/writing-review.md:87), and sports praise such as ["Clean. You don't hesitate."](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:166) and ["You make it look easy. It isn't."](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:178). These remain ordinary fallbacks after a district's corresponding tone is heard out.

   This is narrower and lower impact than the original finding because several conspicuous offenders were rewritten successfully. Rewrite or retire these remaining examples; their failure follows the pass's stated criteria rather than a preference about sentence rhythm.

The other round 1 fixes held up:

- **Read state and Continue.** The Archive marks reading after its record replay finishes; the Clinic marks records when it displays them. Narration uses `logs_read`, and older saves inherit replayed records. `narration_heard` round-trips with the run, and the selector follows the loaded run's history while New Game gets an empty history.
- **Story protection and silence.** Both hold call sites use `say_story`; pooled remarks, including priority `path_left`, respect it. Place lines wait for speech to end and then for `PLACE_QUIET`. The narrowed protection preserves the previous interruption behavior for ordinary remarks, finds and boss calls. That matches the stated design choice. The added wait in the place-test helper accommodates the new silence requirement without removing an assertion.
- **Purpose and canon.** Factual knowledge beats can now be selected under "Stop praising me" while ordinary idle praise remains excluded. Finding 1 concerns their subsequent repetition. Platform A now says six years, and Teo distinguishes the old driver-operated line from this ring, resolving the original continuity conflict.
- **Project checks.** All 681 Steward lines have Ogg files and matching manifest text, with no orphan manifest entries. All 19 rewritten lines have changed Ogg files. The pooled texts have no exact duplicates or "I decided". Recorded gold-ownership and serif-ownership checks pass. I found no weakened existing assertion or removed gate check.

Low-value nits remain separate: repeated openings and shared district templates are conspicuous when reading the pools together, but individual instances do not warrant findings. `git diff --check HEAD` is clean.

I reviewed `git diff HEAD` and the milestone's writing changes in `git diff 0d17e13`, traced their callers and checked the recorded validation without editing anything. The current gate confirms clean import, **535 passing tests** and the **30-second smoke pass**. Its campaign remains in progress; the existing ending, revisit, tool-door and tour logs predate these fixes, so they do not establish a completed gate on this tree. The selection reproductions above are read-only models of the source branches, not engine reproductions. Real actor delivery and narration density in play remain unverified.

## Round 2 fixes

1. **A spent beat leaves silence.** Heard, a beat is out of the pool; if that empties it, the Steward
   says nothing. The exception is now only for an own_only event (a district's entry, boss and
   Reliquary lines), so a district's only revisit greeting still greets every revisit. Test:
   `test_line_selector::test_a_spent_beat_leaves_silence` (with only facts allowed and the bridge read:
   the bridge once, then four times nothing; the Ward's greeting on three revisits).
2. **It says what it saw, and only that.** Sol named three lines, but the same fault ran through the
   bold and careful pools, so all of them were checked against what each event knows:
   - A kill knows how far away it was. `StewardWatch` already measures it (up close within 1.8 tiles,
     at range from 3), and now passes it on as `reach`. A line can carry `when: {"reach": "close"}` or
     `"far"`, and is said only when that's what it saw; between the two, those lines aren't said.
     Thirty-four kill and two-kill lines carry it ("Right up close. Not many would.", "From across the
     street. The paper can keep its news."). Lines that named ground it can't check (the high ground,
     the walk, the causeway, the doorway, a crane between you) say a distance now, or nothing about
     where you were.
   - A hit knows you were hit, not what you did next. The bold lines for it say what it expects of
     you ("It hit you. You'll go straight back at it. You always do.") instead of what you did.
   - A close dodge knows it slowed time and the blow nearly landed, not which way you rolled ("I slowed
     it down for you. You'd have made it anyway.").
   - Halfway knows you got there, not how ("Wait for the tide from here on. It always goes back out.").
   - A boss down knows what you beat, not where you stood ("You fought a train. I'll remember that.").
   94 lines rewritten and voiced; 5 more only gained `reach`. A bad `reach` value is a load error.
   Test: `test_line_selector::test_it_says_how_near_only_when_it_saw` (kills and two-kills in the
   Tideworks, bold and careful, unseen, close and far: no "up close" line unless it saw you up close, no
   "at range" line unless it saw you at range).
3. **The rest of round 1's examples.** MERCY_MULTI_N1 "Two drones. They were still on the night round.
   In here it's always that night."; HURT_N1 "That one landed. I used to be able to send someone.";
   KILL_B1 "You don't hesitate. I was built to, a little. People trusted me more for it."; KILL_B3 "Nine
   years without a fault, that one. You were its first."

With only distance lines left for careful kills anywhere, one generic careful line would have come round
straight after itself (`test_no_immediate_repeats_within_a_tone` caught it). So KILL_C1 has no
condition: "You pick your moments. I notice that. I notice everything you do."

## Round 3 findings (verbatim from sol_analyst)

Milestone 6 is not ready to close. Most fixes hold, including the spent-beat correction, but the observation rewrite remains incomplete. I found two P2 defects and one P3 writing issue. No P0 or P1 findings.

1. **P2. The new `reach` condition proves the latest kill’s distance, not both kills or their history.**

   Confirmed: [steward_watch.gd:139](/home/homebox/Documents/rookmate/undertow/game/level/steward_watch.gd:139) measures distance to the enemy currently dying. For `multi_kill`, it retains only the previous kill’s timestamp and passes the current enemy’s `reach`.

   Nevertheless, [TIDE_MULTI_B1](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:1626) and [MERCY_MULTI_B1](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:2015) say “Both of them, up close.” A first kill four tiles away followed by a second one tile away satisfies their conditions. Conversely, [MULTI_C1](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:220) and [TIDE_MULTI_C1](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:1636) say the second enemy **never** came near. Being far away when it dies cannot establish that.

   The new [test](/home/homebox/Documents/rookmate/undertow/tests/unit/test_line_selector.gd:248) verifies filtering against supplied `reach` values, but does not check how a pair of kills produces those values. Rewrite around the latest death’s distance, or track the additional observations the wording requires.

   Inferred consequence: these remarks can contradict the fight the player just saw. Encounter frequency remains unmeasured.

2. **P2. Some rewritten dodge remarks still assert observations the event does not establish.**

   Confirmed: [MERCY_DODGE_B2](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:2049) now says, “You always roll at them, not away. I’ve watched.” Yet [SlowMo._on_dodged](/home/homebox/Documents/rookmate/undertow/game/level/slow_mo.gd:57) ignores direction, and [StewardWatch](/home/homebox/Documents/rookmate/undertow/game/level/steward_watch.gd:33) requests `dodge_close` without passing it. Rolling away from a nearby winding-up enemy qualifies. Recording retreat as caution does not exclude bold lines.

   [VEL_DODGE_B1](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:2808) retains “You’re getting faster. I’ve measured.” It can be selected on the first qualifying dodge. Neither the event context nor [PlaystyleProfile](/home/homebox/Documents/rookmate/undertow/core/playstyle_profile.gd:26) contains a speed or reaction-time comparison.

   These are still reported observations, rather than the expectations used successfully in the rewritten hurt lines. Gate them on actual observations or rewrite them. The inferred player-facing effect is the same loss of credibility identified in rounds 1 and 2.

3. **P3. An exact play-by-play example rejected by the writing review remains reachable.**

   Confirmed: [CHECK_B1](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:409) still says “Halfway, and barely winded.” [design/writing-review.md:89](/home/homebox/Documents/rookmate/undertow/design/writing-review.md:89) quotes that exact sentence as commentary that adds nothing the player could not know.

   It is a live fallback. Once Kestrel’s bold checkpoint line has been heard, the [fresh-line selection](/home/homebox/Documents/rookmate/undertow/core/line_selector.gd:180) selects `CHECK_B1` on a subsequent bold checkpoint request, such as a revisit. A read-only model of those branches confirmed this sequence.

   The specific Mercy, hurt and kill examples named in round 2 were repaired. This remaining example still fails the pass’s stated criterion. Rewrite or retire it.

The other fixes held up:

- **Spent beats and purpose filtering.** [line_selector.gd:146](/home/homebox/Documents/rookmate/undertow/core/line_selector.gd:146) now leaves an exhausted ordinary pool empty. The facts-only bridge sequence produces the admission once, then silence; Harbor’s `own_only` revisit greeting remains repeatable. The regression test now combines the previously missing conditions.
- **Read state and Continue.** Archive reading is marked after the record finishes displaying; Clinic reading is marked when displayed. Narration uses `logs_read`. Both read state and narration history serialize, older saves inherit Archive replays, and the selector follows the replaced run’s history.
- **Story protection and timing.** Both hold call sites and place delivery use `say_story`; pooled remarks respect that protection. Finds and boss calls retain their previous interruption behavior. Places wait for speech to finish and then for `PLACE_QUIET`. The place-test helper’s added wait accommodates that requirement without removing an assertion.
- **Canon and project rules.** Platform A says six years, and Teo distinguishes the predecessor railway from this ring. All 681 Steward lines have Ogg files and matching manifest text, with no orphan manifest entries. Every rewritten recording changed. Gold and serif ownership checks pass. I found no weakened existing assertion or gate check.

Low-value nits remain separate: repeated openings and shared district sentence templates are noticeable when reading the pools together, but individual instances do not warrant findings.

I reviewed `git diff HEAD`, the milestone’s writing changes against `0d17e13`, their callers and the recorded validation without editing anything. Current logs confirm clean import, **537 passing tests** and the **30-second smoke pass**; `git diff --check HEAD` is clean. The current campaign has no final result yet, and the existing ending, revisit, tool-door and tour results predate these fixes. The selection reproductions above are source-branch models, not engine reproductions. Real actor delivery and narration density in play remain unverified.

## Round 3 fixes

1. **Two at once: near only if both were.** `StewardWatch` keeps the last kill's reach; a two-kill
   carries "close" or "far" only when both kills had it. "Both of them, up close" is true now. The
   careful two-kill lines that said the second "never" came near say what it saw instead: MULTI_C1 "Two,
   both from a distance. Careful work."; TIDE_MULTI_C1 "Two, both out of grabbing distance. Put that in
   the dock log." Test: `test_adaptive_narration::test_two_at_once_are_near_only_if_both_were` (real
   kills in the Vellum: one at range then one up close says neither; two up close says close; one in
   between says nothing). `Narrator.last_seen` keeps what it was last told it saw, for the test.
2. **Dodges.** MERCY_DODGE_B2 "Closer than I'd have cut it. I've stopped saying so."; VEL_DODGE_B1
   "That close, in the Vellum. Someone would have written it up." The rest of the dodge pool was
   checked for the same fault: DODGE_B2 (no "every time"), DODGE_C1 (a close dodge isn't distance),
   KES_DODGE_B1, LOOP_DODGE_N1 (not "on the rail") and LOOP_DODGE_C2 (not "I saw you watching").
3. **Halfway.** CHECK_B1 "Halfway already. I'd have sent a train for you, once. You wouldn't have waited
   for it."; and its Kestrel twin, KES_CHECK_B1 "Halfway up. The residents took the funicular. You never
   would."

Eleven lines rewritten and voiced.

## Round 4 findings (verbatim from sol_analyst)

Milestone 6 is not ready to close. Round 3’s pair-distance fix and the named Mercy, Vellum and halfway rewrites are correct. The read-state, Continue and spent-beat fixes also hold. Two P2 defects remain, plus one P3 writing issue. No P0 or P1 findings.

1. **P2. Fixed factual replies can still cut off protected story lines.**

   Confirmed: only [Narrator.notify](/home/homebox/Documents/rookmate/undertow/autoload/narrator.gd:87) checks `story_in_progress()`. `say_fixed()` goes through [speak_text](/home/homebox/Documents/rookmate/undertow/autoload/narrator.gd:172), which protects warnings and `say_in_full` lines, but ignores `_story`. Its emitted signal makes Sound replace the current recording.

   There is a concrete gameplay path. Completing Greywater’s pumps starts the protected admission through [Hold._finish](/home/homebox/Documents/rookmate/undertow/game/props/hold.gd:105). The crank is at `20,3` and a Waiting resident at `18,3`, with indexed, walkable ground between them. During the admission, approaching that resident and pressing Interact calls [TheWaiting.refused](/home/homebox/Documents/rookmate/undertow/game/props/the_waiting.gd:92), which immediately starts `waiting_refusal`. That line is a **fact**, not the permitted warning exception. The pumps recording lasts 5.2 seconds, confirmed with `ffprobe`.

   Consequently, “I could have done it in a minute. I didn’t” can still be lost. The call path and replacement behavior are confirmed from source; encounter frequency is unmeasured.

   Apply the active-story protection to fixed factual replacements too. This does not require making ordinary remarks, finds or boss calls uninterruptible when they themselves are speaking, so it need not restore the behavior that broke the earlier tests.

2. **P2. The observation rewrite still leaves unverified direction and journey claims.**

   Confirmed: [DODGE_B2](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:241) now says, “Through it, not around it. You like the hard way.” Removing “Every time” repaired the historical claim, but the line still describes the current roll’s direction. [SlowMo._on_dodged](/home/homebox/Documents/rookmate/undertow/game/level/slow_mo.gd:57) ignores direction, and [StewardWatch’s callback](/home/homebox/Documents/rookmate/undertow/game/level/steward_watch.gd:35) supplies none. Rolling away from a nearby winding-up enemy qualifies.

   Also, [TIDE_CHECK_B1](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:1800) remains “Halfway down the quay, and nothing’s slowed you yet.” The [checkpoint trigger](/home/homebox/Documents/rookmate/undertow/game/level/steward_watch.gd:91) establishes arrival at the cell, without checking whether the player previously stopped, struggled or took their time.

   Both lines are live. A source-branch selection model selects `DODGE_B2` after Kestrel’s other bold dodge lines are heard, and `TIDE_CHECK_B1` on a fresh bold Tideworks checkpoint selection. These were selection models, not engine reproductions.

   The inferred player-facing effect is the same credibility problem identified in the earlier rounds. Rewrite these claims around the event’s evidence, or supply the observations they require.

3. **P3. The repaired generic cautious two-kill line now provides only play-by-play and praise.**

   Confirmed: [MULTI_C1](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:220) says, “Two, both from a distance. Careful work.” Its distance claim is now properly supported, but the line contains no history, motive or continuing story. The player already knows both facts it reports.

   This is a writing judgment against [the pass’s own subtext criterion](/home/homebox/Documents/rookmate/undertow/design/writing-review.md:85), rather than a preference about rhythm. The fallback is reachable: successive cautious, far two-kill selections in the Tideworks select `TIDE_MULTI_C1`, then `MULTI_C1`. Rewrite or retire it so the accurate observation also earns its moment.

The other repairs held up:

- **Two-kill distance.** `_last_kill_reach` is updated after each death; a pair receives `close` or `far` only when both measurements agree. Mixed and intermediate distances supply neither. The added integration test exercises real kill notifications and passed.
- **Read state and Continue.** Archive reading is marked after the record finishes displaying; Clinic reading is marked when displayed. Narration uses `logs_read`. Read state and narration history serialize, older saves inherit Archive replays, and replacing the run attaches the selector to the loaded history.
- **Spent beats and purpose filtering.** The facts-only bridge sequence produces the admission once, then silence. Harbor’s `own_only` revisit greeting remains repeatable. Factual knowledge beats remain available under “Stop praising me.”
- **Timing and previous regressions.** Places wait for speech to finish and then for `PLACE_QUIET`. Pooled remarks respect protected stories. Ordinary remarks and boss calls retain their previous behavior. The place-test helper’s added wait accommodates the new requirement without removing an assertion.
- **Canon and project rules.** Platform A says six years; Teo distinguishes the predecessor railway from this ring. All 681 Steward lines pass the current recording check. Every changed pooled text has a changed Ogg file. Gold and serif ownership checks pass. I found no weakened existing assertion or removed gate check.

Low-value nits remain separate: repeated openings and shared district sentence templates are noticeable when reading the pools together, but do not warrant additional findings.

I reviewed `git diff HEAD` at `d7d950d`, the milestone changes against `0d17e13`, callers, writing criteria and primary validation logs without editing anything. The current gate confirms clean import, **538 passing tests** and the **30-second smoke pass**. Its campaign has reached the Tideworks but has no final result yet; the ending, revisit, tool-door and tour results still predate these fixes. Real actor delivery and narration density in play remain unverified.

## Round 4 fixes

1. **A hold's line holds against replies too.** While a hold's story line is being said, no other
   fixed line starts over it (a reply such as one of the Waiting refusing you, a find's line, a tool
   door's): only a warning or a boss's call. The Waiting's refusal is still on screen in the Steward's
   type, so you still get its answer. A place's line protects itself from remarks only; a reply is said
   over it. Making places hold too was tried first: a place line at a level's start then held up
   `test_voice` and `test_audio`'s own lines, and in play it would have held up Noor's homecoming or a
   find's line for a remark about the scenery. Tests:
   `test_adaptive_narration::test_it_never_talks_over_its_story` (the pumps line: no remark, no reply; a
   warning cuts in), `test_places::test_a_reply_isnt_held_up_by_a_place`.
2. **Two more claims.** DODGE_B2 "You like the hard way. I've given up offering you the easy one.";
   TIDE_CHECK_B1 "Halfway down the quay. The night shift used to stop here for tea. You won't."
3. **The two-kill line earns its moment.** MULTI_C1 "Two, both from a distance. They were built to be
   walked up to. You don't oblige them."

Three lines rewritten and voiced.

## Round 5 findings (verbatim from sol_analyst)

Round 4’s fixes are correct, and the earlier state, selection and distance fixes hold. I found no new code regression in the latest story guard. Milestone 6 is still not ready to close: one P2 observation defect and one P3 writing issue remain. No P0 or P1 findings.

1. **P2. A remaining reactive line invents tide history during a brief mute.**

   Confirmed: [GREY_BACK_N1](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:2656) says, “There you are. The tide turned twice while you were gone.” Unmuting immediately requests `voice_restored` in [level.gd:171](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:171). Neither that caller nor [Narrator.context_for](/home/homebox/Documents/rookmate/undertow/autoload/narrator.gd:143) supplies elapsed mute time or tide transitions, and the line has no condition.

   This is reachable after switching the voice off and immediately back on, while covered and clear of protected speech. `voice_restored` is a priority event, so `MIN_GAP` does not prevent it. A source-branch selection model selects `GREY_BACK_N1` on a fresh neutral Greywater unmute. Under “Stop praising me,” this factual event requests that neutral tone directly. Greywater’s [tide phases](/home/homebox/Documents/rookmate/undertow/game/level/tide.gd:13) take several seconds each, so that brief mute can contain no turns at all.

   [TIDE_RESPAWN_N2](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:1744) retains the same unsupported count during a respawn. The [death path](/home/homebox/Documents/rookmate/undertow/game/player/operator.gd:345) waits `DOWNED_SECONDS`, defined as 1.6 seconds, without measuring tide history.

   These are remaining milestone defects, not regressions introduced by round 4. The inferred effect is another contradiction from the supposedly observant voice; encounter frequency is unmeasured. Rewrite the literal counts around what those events establish, or gate them on actual observations.

2. **P3. An exact generic boss line rejected by the writing review remains reachable.**

   Confirmed: [BOSS_DOWN_B1](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:562) still says, “That’s it down. I knew you would.” [design/writing-review.md:98](/home/homebox/Documents/rookmate/undertow/design/writing-review.md:98) quotes that exact line as writing that could belong to any game.

   It is live gameplay content. The [Warden-Prime’s death](/home/homebox/Documents/rookmate/undertow/game/bosses/warden_prime.gd:266) requests `boss_down`; Harbor has only a neutral district line for that event. Because `boss_down` does not use `own_only`, its bold selection reaches the generic line immediately. A source-branch model confirmed that selection.

   This is a writing judgment against the pass’s explicit criterion, not a rhythm preference. Rewrite or retire the line so this boss’s defeat contributes history, motive or continuing story.

The repairs checked out:

- Hold lines now reject non-warning, non-urgent fixed replacements through [Narrator.speak_text](/home/homebox/Documents/rookmate/undertow/autoload/narrator.gd:177). Both hold call sites use `say_story`. Place lines pass `false`, preserving factual replies, while pooled remarks wait. Ordinary remarks, finds and boss calls retain their previous interruption behavior.
- The three round 4 rewrites resolve their named defects. The pair-distance calculation requires both measurements to agree; mixed and intermediate distances supply neither. The earlier named dodge and halfway rewrites also hold.
- Archive and Clinic display paths mark records read. Narration uses that read state. Read state and narration history serialize, older saves inherit Archive replays, and Continue attaches selection to the loaded history.
- Exhausted ordinary knowledge beats leave silence, factual knowledge beats survive “Stop praising me,” and the intended revisit greeting remains available.
- Loop continuity is repaired. All 681 Steward lines have clips and matching manifest text, with no orphan entries. All 109 pooled texts changed against HEAD have changed Ogg files. Gold and serif checks pass. I found no weakened assertion or removed gate check; the place helper’s added wait preserves its assertions.

Low-value nits remain separate: repeated openings and shared district templates are noticeable when reading the pools together, but do not warrant additional findings.

I reviewed both requested diffs and the relevant callers without editing anything. Current primary logs confirm clean import, **539 passing tests**, and the **30-second native smoke pass**; `git diff --check HEAD` is clean. The current campaign has reached the Tideworks but has no final result. The remaining scenario logs predate these fixes, so the full gate is still unverified on this tree. The selection models above were not engine reproductions. Real actor delivery and narration density in play remain unverified.

## Round 5 fixes

1. **No tide count it didn't keep.** GREY_BACK_N1 "There you are. The tide doesn't wait for me to be
   listening. Mind it."; TIDE_RESPAWN_N2 "Again. Down here the tide keeps the time, not me. It can keep
   it a while longer." The other voice-back, respawn, back-on-the-path and by-hand lines were read for
   the same fault. The ones that presume something ask it ("Did the dark carriages tell you anything?")
   and the respawn lines predict rather than report ("Up. You'll want the same carriage. I know."), so
   they stay.
2. **The last stock boss line.** BOSS_DOWN_B1 "Down. It was one of my best. I'd have bet on it, once.
   Not now." (every boss is one of its machines).

Three lines rewritten and voiced.

## Round 6 findings (verbatim from sol_analyst)

Round 5's fixes are correct, but milestone 6 is still not ready to close. One P2 observation defect and one P3 writing issue remain. No P0 or P1 findings. Neither remaining issue was introduced by the three round 5 rewrites.

1. **P2. A Greywater low-health line announces a rising tide without checking its phase.**

   Confirmed: [GREY_LOW_B1](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:2495) says, "You're barely standing, and the tide's coming in. I've done that sum. Please." It has no condition.

   [StewardWatch._on_hurt](/home/homebox/Documents/rookmate/undertow/game/level/steward_watch.gd:119) requests `low_integrity` from the player's health alone. Neither that request nor [Narrator.context_for](/home/homebox/Documents/rookmate/undertow/autoload/narrator.gd:143) supplies the tide's phase. Enemy damage can trigger it during the ebb, when [Tide.water_level](/home/homebox/Documents/rookmate/undertow/game/level/tide.gd:58) explicitly decreases the water level.

   A read-only model of the selection branches selects `GREY_LOW_B1` for a fresh bold Greywater low-health request, including during the ebb. This was not an engine reproduction.

   The inferred player-facing effect is a false statement about the current hazard from the voice meant to notice it closely. Encounter frequency remains unmeasured. Rewrite the phase claim or gate it on the actual tide phase.

2. **P3. A reachable generic kill fallback still supplies the play-by-play this pass was meant to replace.**

   Confirmed: [KILL_N1](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:154) remains "That one's done scrubbing." It reports the visible result without adding history, motive or a continuing story. [The writing review](/home/homebox/Documents/rookmate/undertow/design/writing-review.md:87) rejects that kind of commentary and [uses this exact sentence as a rewrite example](/home/homebox/Documents/rookmate/undertow/design/writing-review.md:170).

   It is live content. The milestone's [selection logic](/home/homebox/Documents/rookmate/undertow/core/line_selector.gd:180) exhausts fresh district lines and then selects fresh generic lines. With Kestrel's four neutral kill lines and `KILL_N2` heard, a read-only source-branch model selects `KILL_N1` next. At `0d17e13`, a district with its own kill pool excluded these generic fallbacks entirely.

   This is a writing judgment against the pass's stated criterion, rather than a preference about rhythm. Rewrite or retire the line.

The round 5 repairs checked out:

- `GREY_BACK_N1` and `TIDE_RESPAWN_N2` no longer invent elapsed tide counts. Their new wording remains valid after a brief mute or respawn.
- `BOSS_DOWN_B1` replaces the rejected stock congratulation with the Steward's attachment to its machine and its changed expectations.
- All three Ogg files changed and decode cleanly. Independent checks found **681 Steward lines**, matching manifest text and clips for every line, and no orphan manifest entries.

The earlier read-state, Continue, spent-beat, purpose-filtering, pair-distance and story-protection repairs still hold. Gold and serif ownership checks pass in the current test log. I found no weakened assertion or removed gate check; the updated narration assertion checks the event, and the campaign timeout increase retains the gameplay checks.

Low-value nits remain separate: repeated openings and shared district sentence templates are noticeable when reading the pools together, but do not warrant findings.

I reviewed both requested diffs, the writing criteria and relevant callers without editing anything. Current primary logs confirm clean import, **539 passing tests** and the **30-second native smoke pass**. Both requested diffs pass `git diff --check`. The current campaign has beaten the Conductor but has no final result; the remaining scenario logs predate round 5's fixes, so the full gate remains unverified on this tree. Real actor delivery and narration density in play remain unverified.

## Round 6 fixes

1. **No tide it didn't check.** GREY_LOW_B1 "You're barely standing, in a district that floods. I've done
   that sum. Please." The pools were searched for every line naming the tide, water, fog, mist, the
   dark or the light outside an entry or boss line, and each was checked for a claim about the present
   state. Three more were wrong: GREY_IDLE_N1 said the tide ran "on a six-minute cycle" (it's 54 s:
   now "The tide comes every minute now. It used to come when I said."), and two respawn lines said the
   water was what downed you (GREY_RESPAWN_N1 "Back, and dry. Down here, I pull people out before the
   sea can. Mostly."; TIDE_RESPAWN_N1 "Back on the quay. I bring people back. I used to be better at
   it.").
   The voice-back questions that suppose you went somewhere while it couldn't hear you ("Did the dark
   carriages tell you anything?", "Did you find what you went into the fog for?") stay. They're its
   suspicion of what you did out of its hearing, asked, not reported.
2. **The last play-by-play kill.** KILL_N1 "I gave that one a name, once. I'll stop using it."

Five lines rewritten and voiced.

## Round 7 findings (verbatim from sol_analyst)

Round 6's findings were fixed correctly, but milestone 6 is still not ready to close. Two P2 defects and one P3 writing issue remain. No P0 or P1 findings. These are remaining milestone issues, not regressions introduced by the eight uncommitted rewrites.

1. **P2. Some reactive lines still describe a location or attack the event never establishes.**

   Confirmed: [KES_LOW_B1](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:989) says, "Nearly at the top, and nearly done in." [StewardWatch._on_hurt](/home/homebox/Documents/rookmate/undertow/game/level/steward_watch.gd:119) requests `low_integrity` from health alone. Kestrel has Custodians on the [bottom terrace beside the starting area](/home/homebox/Documents/rookmate/undertow/data/levels/kestrel_heights.txt:62), so the line can announce progress up the hill before the player has climbed it.

   Confirmed: [MERCY_DODGE_N1](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:2038) says, "That cloud would have gone straight to your lungs." However, [SlowMo._threat_near](/home/homebox/Documents/rookmate/undertow/game/level/slow_mo.gd:75) accepts any nearby winding-up enemy. Mercy also contains Custodians, whose [attack is a melee lunge](/home/homebox/Documents/rookmate/undertow/game/enemies/custodian.gd:59). The [dodge notification](/home/homebox/Documents/rookmate/undertow/game/level/steward_watch.gd:35) supplies no attack type.

   Read-only models of the selection branches select `KES_LOW_B1` for a fresh bold Kestrel low-health request and `MERCY_DODGE_N1` for a fresh neutral Mercy dodge request, regardless of those missing observations.

   The inferred consequence is another contradiction between the supposedly attentive voice and the action on screen. Encounter frequency is unmeasured. Rewrite the literal claims or gate them on the observations they need.

2. **P2. The Vellum can say its press still runs after the player stopped it.**

   Confirmed: [VEL_IDLE_N1](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:2923) says, "The press downstairs still runs. One page, over and over." It has no condition.

   The defeat line explicitly says [the press has stopped](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:3063), and the learned revisit greeting says [it is quiet now](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:3394). On a revisit, [BossEncounter.build](/home/homebox/Documents/rookmate/undertow/game/level/boss_encounter.gd:21) leaves the Editor defeated, but idle requests continue unchanged.

   A read-only selection model with `revisit: true` and `VEL_IDLE_N2` already heard selects `VEL_IDLE_N1` next for the neutral tone. Remembering narration history does not retire this ordinary repeating line.

   The contradiction is confirmed from the content and selection rules. Its frequency in play remains unknown. Make the line valid after the defeat, or restrict it to the state where the press still runs.

3. **P3. A reachable generic kill fallback still provides only observation and stock praise.**

   Confirmed: [KILL_B2](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:175) remains "Right up close. Not many would." Its distance condition now makes the observation accurate, but the line supplies no history, motive or continuing story beyond a generic compliment.

   That fails the pass's [subtext and flattery criteria](/home/homebox/Documents/rookmate/undertow/design/writing-review.md:85). This is a writing judgment against those criteria, not a preference about rhythm.

   It is reachable through the milestone's [generic fallback selection](/home/homebox/Documents/rookmate/undertow/core/line_selector.gd:189). A source-branch model selects it for a close bold Kestrel kill after that district's bold lines and the other eligible generic bold lines have been heard. At the milestone baseline, a district's own kill pool excluded this fallback. Rewrite or retire it.

The round 6 repairs themselves hold. `GREY_LOW_B1` now describes a district that floods without asserting the current phase. `KILL_N1` adds the Steward's attachment to the machine. The additional idle and respawn rewrites remove the erroneous cycle length and unsupported rescue circumstances. Round 5's tide-count and boss-line repairs also remain correct.

All **681 Steward lines** have clips and matching manifest text and settings hashes, with no orphan manifest entries. All eight updated Ogg files changed and decode cleanly. The earlier read-state, Continue, spent-beat, purpose-filtering, pair-distance and story-protection repairs still hold. Gold and serif ownership checks pass in the current test log. I found no weakened assertion or removed gate check.

Low-value nits remain separate: repeated openings and shared district sentence templates are noticeable when reading the pools together, but do not warrant further findings.

I reviewed both requested diffs and the relevant callers without editing anything. Current primary logs confirm clean import, **539 passing tests** and the **30-second native smoke pass**. Both diffs pass `git diff --check`. The current campaign has reached the Tideworks but has no final result; the remaining scenario logs predate these fixes, so the full gate is still unverified on this tree. The selection checks above were source-branch models, not engine reproductions. Real actor delivery and narration density in play remain unverified.

## Round 7 fixes, and an audit of every pool

Each round since round 2 has found two or three more lines of the same kind, so this time every pooled
line was read against what its event knows (a kill: its distance; a hit or low health: your health; a
close dodge: that it nearly landed; idle: that you stood still; halfway: that you got there; a boss
down: which boss), not just the ones named. Sixteen rewritten and voiced:

1. **Sol's.** KES_LOW_B1 "Nearly done in, on a hill built for strolling. Slow down." (not "nearly at
   the top"); MERCY_DODGE_N1 "That one nearly had you. In here, I'd have had to write it up." (not a
   cloud: Mercy has Custodians too); VEL_IDLE_N1 "The press downstairs ran every night for eleven years.
   One page, over and over. I never read it." (true before and after you stop the Editor); KILL_B2
   "Right up close. I designed them for people who'd keep their distance."
2. **Dodges that named the attack.** TIDE_DODGE_N1 (a hook), VEL_DODGE_N1 (a bale), VEL_DODGE_B2 (a
   throw), TIDE_DODGE_C2 (a grab) now say only that it nearly landed.
3. **Idle.** Standing still knows nothing about what's near or what's left: IDLE_C1 "Rest a moment. I'll
   tell you if anything moves." (not "Nothing's close"); IDLE_B1, KES_IDLE_B1, TIDE_IDLE_B1 and
   MERCY_IDLE_B1 no longer promise that enemies will come ("If any are left, they'll find you.").
4. **The rest.** LOOP_LOW_B1 (not "you've done it before"), MERCY_HURT_C1 (not "the mist"),
   ARK_IDLE_N2 "I can still count heads. I do, every hour." (not "Everyone's in": Noor may be out in the
   Ward).

Left as they are, with the reason: the off-path lines name each district's off-path area, which is
what they were written for; the entry, Reliquary and boss lines are said at those places; the
voice-back questions are its suspicion of what you did out of its hearing.

## Round 8 findings (verbatim from sol_analyst)

This round was asked to check every pooled line, not a sample.

Round 7’s three named findings were fixed correctly, but milestone 6 is not ready to close. The additional pool audit remains incomplete: `VEL_DODGE_B2` still claims anticipation after its rewrite.

I checked all **465 pooled lines across all 17 events** against their callers, selection conditions and relevant world state. The remaining lines worth fixing are listed below, grouped by cause. No P0 or P1 findings.

1. **P2. Dodge lines still claim anticipation that the event does not establish.**

   | Line | Unsupported claim |
   |---|---|
   | [DODGE_C2](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:253) | “You saw it coming.” |
   | [KES_DODGE_C1](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:930) | “You saw that before I did.” |
   | [MERCY_DODGE_C2](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:2063) | “You read that one early.” |
   | [GREY_DODGE_C2](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:2446) | “You read that before it came.” |
   | [VEL_DODGE_B2](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:2815) | “You read it before it moved.” |
   | [VEL_DODGE_C2](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:2829) | “You saw it coming.” |

   Confirmed: [SlowMo](/home/homebox/Documents/rookmate/undertow/game/level/slow_mo.gd:57) can trigger from rolling near a windup, an already moving projectile, or an attack striking existing roll invulnerability. [Operator.take_hit](/home/homebox/Documents/rookmate/undertow/game/player/operator.gd:299) emits `evaded` at that last moment. [StewardWatch](/home/homebox/Documents/rookmate/undertow/game/level/steward_watch.gd:35) then requests `dodge_close` without reporting reaction timing or whether the player anticipated that attack.

   The round 7 rewrite removes the named throw from `VEL_DODGE_B2`, but preserves the unsupported timing claim. An already flying bale is a direct counterexample to “before it moved.” The other listed lines similarly credit foreknowledge that the event cannot distinguish from an incidental evasion.

   Rewrite around the close dodge itself, the Steward’s intervention or its expectations. These are claims about this particular action, rather than broad judgments about the player.

2. **P2. Four Vellum lines assume the enemy’s identity or an attack it performed.**

   | Line | Unsupported claim |
   |---|---|
   | [VEL_KILL_N1](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:2698) | Calls the defeated unit “that clerk.” |
   | [VEL_KILL_N3](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:2712) | “It flashed the Feed at you.” |
   | [VEL_KILL_C1](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:2753) | “Its screen’s gone dark.” |
   | [VEL_MULTI_N1](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:2777) | Calls both defeated units “two clerks.” |

   Confirmed: the Vellum contains both Custodians and Clerks, and its paper-lift hold also produces mixed waves. [Level._spawn_enemies](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:727) constructs the distinct families. [StewardWatch._on_enemy_died](/home/homebox/Documents/rookmate/undertow/game/level/steward_watch.gd:139) supplies distance, including the pair-distance check, but no enemy family or attack history.

   A Custodian kill can therefore receive any of the three single-kill lines, and two Custodian kills can receive `VEL_MULTI_N1`. Even a genuine Clerk can die before flashing the Feed: [Clerk](/home/homebox/Documents/rookmate/undertow/game/enemies/clerk.gd:25) starts with a bale attack and alternates afterward.

   Gate the identity and attack claims on those observations, or make the wording apply to either family.

3. **P2. Three lines describe machinery without checking whether the stated change or state exists.**

   - [GREY_KILL_N4](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:2336) says, “It doesn’t know the pumps are off.” The player can already have completed `greywater_pumps`; on a completed district’s revisit, the restored Pumphouse also runs the pumps. [CoreChoice.apply](/home/homebox/Documents/rookmate/undertow/core/core_choice.gd:53) restores the district’s building, and the [Pumphouse’s own line](/home/homebox/Documents/rookmate/undertow/data/narration/steward_fixed.json:108) explicitly says people run the pumps again. The kill line has no corresponding condition.
   - [MERCY_BACK_N1](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:2273) says, “The wards are still sealed.” The player can crank all the seals open while muted and then unmute. [WardSeal.interact](/home/homebox/Documents/rookmate/undertow/game/level/ward_seal.gd:64) leaves each opened door open; restoring the voice does not reseal it.
   - [KES_BACK_B1](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:1147) says, “The gate opened the moment you let me in.” A brief mute can end before the gate’s closing delay, so it never closed. [SmartGate](/home/homebox/Documents/rookmate/undertow/game/level/smart_gate.gd:9) also waits if the player occupies the gate.

   Confirmed: [the unmute caller](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:171) reports only `voice_restored`, and [Narrator.context_for](/home/homebox/Documents/rookmate/undertow/autoload/narrator.gd:143) supplies none of these machinery states or transitions. All three lines remain eligible in the counterexamples above.

4. **P2. Two lines still claim circumstances beyond the reported fight result.**

   - [VEL_MULTI_C1](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:2791) says, “Two, and not a step closer than you needed.” Its `far` condition establishes the distance at each death. It does not establish the player’s earlier approach or that no closer steps were taken. Fighting near both enemies and retreating before each killing shot satisfies the condition. This retains the journey claim behind round 3’s “never came near” finding.
   - [VEL_BOSSDOWN_B1](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:3067) says, “It ran out of paper before you ran out of nerve.” The Editor dies through damage, not paper exhaustion. [Its bale production](/home/homebox/Documents/rookmate/undertow/game/bosses/editor.gd:310) has no paper supply, and [its death notification](/home/homebox/Documents/rookmate/undertow/game/bosses/editor.gd:341) reports only `boss_down`.

   Confirmed: neither claim has supporting observation state. Rewrite the first around the verified distances and the second around the defeated press.

5. **P2. Two checkpoint lines name a landmark that the checkpoint event does not identify.**

   [GREY_CHECK_N1](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:2565) says it marked “the causeway”; [VEL_CHECK_N1](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:2948) says it marked “the bridge.” Both promise to return the player “here.”

   Confirmed: [StewardWatch](/home/homebox/Documents/rookmate/undertow/game/level/steward_watch.gd:91) requests the district’s checkpoint pool on the first checkpoint cell reached, without passing which checkpoint it was. The maps have multiple checkpoints. Greywater’s [checkpoint beside the pump room](/home/homebox/Documents/rookmate/undertow/data/levels/greywater.txt:59) is not the causeway; the Vellum’s [west-street checkpoint](/home/homebox/Documents/rookmate/undertow/data/levels/vellum_street.txt:87) is well away from its footbridge.

   The respawn location itself is correctly updated by [Level._update_checkpoint](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:286). The narration names the wrong place. Use a location-neutral checkpoint line or select wording for the actual checkpoint.

6. **P2. A Tideworks hurt line states that nobody has been hurt immediately after an injury.**

   [TIDE_HURT_C2](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:1709) says, “Careful. Nobody’s been hurt on this quay in five years.”

   Confirmed: this line is requested because the player has just taken damage, and remains eligible after previous injuries too. Unlike a historical statement that the quay *went* five years without an injury, its present-perfect wording says the record remains intact.

   Make the former safety record explicitly historical. This is a contradiction in the reported moment, not a request for another injury counter.

7. **P3. Two checkpoint lines still provide only progress commentary and stock praise.**

   - [CHECK_C1](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:415): “Halfway. You’ve been careful. Keep being careful.”
   - [TIDE_CHECK_C1](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:1807): “One crossing at a time. You’ve been careful.”

   Both remain reachable. The generic line follows a district’s fresh cautious line through [the fallback selection](/home/homebox/Documents/rookmate/undertow/core/line_selector.gd:180).

   These add no history, motive or continuing story to the visible progress and compliment. That directly fails [the writing review’s subtext and flattery criteria](/home/homebox/Documents/rookmate/undertow/design/writing-review.md:85). Adding “crossing” does not repair it. This is a narrower writing finding than the observation defects above.

The named round 7 repairs hold. `KES_LOW_B1` no longer invents progress up the hill; `MERCY_DODGE_N1` no longer identifies a cloud; `VEL_IDLE_N1` remains valid after the Editor’s defeat; and `KILL_B2` now adds the Steward’s design intent to its correctly gated distance observation.

The earlier read-state, saved narration history, spent-beat, purpose-filtering, pair-distance and story-protection repairs remain in place. I found no weakened assertion or removed gate check in the reviewed writing changes. The current log confirms the gold ownership checks passed; round 7 changes no colour or font ownership.

Independent checks confirmed **681 Steward lines**, matching manifest text and settings hashes, clips for every line, and no orphan manifest entries. All **sixteen** rewritten texts have changed Ogg files, and all sixteen recordings decode cleanly. Both requested diffs pass `git diff --check`.

Low-value nits remain separate. Repeated openings and shared sentence templates are noticeable together, but are not additional blockers. `TIDE_REVISIT_N1`’s “a hundred times” is imprecise, but does not explicitly say “since you left,” so I would not report it as another confirmed elapsed-time defect. `VEL_IDLE_N1` can read as though the same page ran for eleven years; the bridge-and-auditor chronology makes that interpretation doubtful, but the line does not establish when the page changed. That is an inference and a clarification opportunity, rather than a confirmed chronology finding.

The player-facing contradictions above follow from source and selection eligibility. Their frequency and effect on players are inferred; I did not reproduce them in the engine. Current primary logs confirm clean import, **539 passing tests** and the **30-second native smoke pass**. The current full gate is still running its campaign, so a completed gate on this tree remains unverified. Real actor delivery and narration density in play also remain unverified.

## Round 8 fixes

All of them, and the two nits that were cheap; 22 lines rewritten and voiced.

1. **A close dodge: that it missed, not that you saw it coming.** DODGE_C2 "That one missed. I'd rather
   they all did."; KES_DODGE_C1 "Missed. Up here they never missed. They never had to."; MERCY_DODGE_C2
   "Missed. In here, a near miss went on the chart too."; GREY_DODGE_C2 "That would have been my job,
   once. Keeping things from landing on people."; VEL_DODGE_B2 "Close. The Post would have run that as
   a photograph."; VEL_DODGE_C2 "Missed. Good. I'd rather you read about danger than meet it."
2. **The Vellum has Custodians too.** VEL_KILL_N1 "That one kept the Post in order for eleven years.";
   VEL_KILL_N3 "A million people read the Feed here every morning. I wrote most of it."; VEL_KILL_C1
   "Keep your eyes off the screens, even now."; VEL_MULTI_N1 "Two of them."
3. **Machines whose state it isn't told.** GREY_KILL_N4 "It was still sweeping toward the drains. It
   never knew what the pumps were doing."; MERCY_BACK_N1 "I sealed the wards to keep them safe. I'd
   still have them sealed."; KES_BACK_B1 "Did you try the gates while I couldn't hear? They don't know
   you."; and its twin KES_BACK_N1 "There. The Heights don't open a door without me."
4. **A fight's result, not its course.** VEL_MULTI_C1 "Two, both at a distance. The Vellum always kept
   its readers at arm's length."; VEL_BOSSDOWN_B1 "You stopped the press. Nobody's done that since it was
   built. Remarkable."
5. **Halfway doesn't know which checkpoint.** GREY_CHECK_N1 "I've marked this spot."; VEL_CHECK_N1
   "I've marked this stretch of street."
6. **The record is history.** TIDE_HURT_C2 "Careful. This quay went five years without anyone hurt,
   once."
7. **Something under halfway.** CHECK_C1 "Halfway. Careful people got home, in this city. Mostly.";
   TIDE_CHECK_C1 "One crossing at a time. That's how they taught it here, before me."

From the nits: VEL_IDLE_N1 now says the one page ran "at the end", not for eleven years. TIDE_REVISIT_N1's
"a hundred times" is left (Sol: imprecise, not a claim about since you left).

## Round 9 findings (verbatim from sol_analyst)

Round 8's fixes are mostly correct, but milestone 6 is still not ready to close. Two P2 defects and one P3 writing issue remain. No P0 or P1 findings.

1. **P2. Kill narration still assigns the wrong job to the defeated enemy.**

   The rewritten [GREY_KILL_N4](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:2339) removes the unsupported pump state, but retains "It was still sweeping toward the drains."

   Confirmed: Greywater also has [Salvagers](/home/homebox/Documents/rookmate/undertow/data/levels/greywater.txt:71), whose behavior is to steal metal and flee, rather than sweep. [StewardWatch](/home/homebox/Documents/rookmate/undertow/game/level/steward_watch.gd:141) supplies kill distance, without enemy family or activity. This line has no condition excluding a Salvager.

   The same remaining defect affects:

   | Line | Counterexample |
   |---|---|
   | [GREY_KILL_N2](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:2325), "It was mopping a street…" | A Salvager kill. |
   | [VEL_KILL_N2](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:2708), "It was still sorting yesterday's paper." | A Custodian kill. |
   | [TIDE_KILL_N4](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:1561), "It moved a container every ninety seconds." | A Custodian kill. |

   These distinctions are explicit in the [world bible's enemy definitions](/home/homebox/Documents/rookmate/undertow/undertow-world-bible.md:144). Custodians appear on the indexed streets in both [Vellum](/home/homebox/Documents/rookmate/undertow/data/levels/vellum_street.txt:83) and [Tideworks](/home/homebox/Documents/rookmate/undertow/data/levels/tideworks.txt:57).

   Source-branch checks confirmed that each line becomes the sole fresh neutral district option after its peers have been heard. They remain reachable ordinary lines. GREY_KILL_N4 is an incomplete round 8 repair; the other three are remaining milestone defects.

   Rewrite these lines so they apply to either family, or supply the family and behavior their wording requires. Selection eligibility and the contradictory enemy roles are confirmed. Encounter frequency and the effect on players remain unmeasured.

2. **P2. The replacement Kestrel unmute line makes a false blanket claim about doors.**

   [KES_BACK_N1](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:517) now says, "The Heights don't open a door without me."

   Confirmed: the Kestrel gatehouse opens with the Signal Jammer. [ToolDoor.can_interact](/home/homebox/Documents/rookmate/undertow/game/props/tool_door.gd:52) requires the equipped tool, without requiring the Steward's voice. [Interaction](/home/homebox/Documents/rookmate/undertow/game/props/tool_door.gd:73) opens the door permanently. The player can therefore open it while muted, then unmute and hear this line. Neutral selection chooses KES_BACK_N1 immediately; neither its conditions nor the [unmute caller](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:171) excludes that situation.

   The [gate-list record](/home/homebox/Documents/rookmate/undertow/data/logs/memory_logs.json:865) also explicitly documents a person opening a Kestrel gate by hand.

   The original transition claim is gone, but this replacement overstates the Steward's control. Narrow it to the automated gates' dependence on its signal. Whether the author intended a deliberate bluff is unknown; the current neutral factual line gives no indication of that intent.

3. **P3. The rewritten Vellum two-kill line retains the rejected play-by-play structure.**

   [VEL_MULTI_N1](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:2780) now says, "Two of them. The street's almost readable again."

   Confirmed: removing "clerks" fixes the enemy-identity assumption. This is also Vellum's sole fresh neutral district two-kill line, so it is immediately reachable.

   Writing judgment: the replacement still reports two defeats and a clearer street, with a paper-themed word substituted. It adds no history, motive or continuing story. That closely reproduces the construction explicitly rejected in [design/writing-review.md](/home/homebox/Documents/rookmate/undertow/design/writing-review.md:89), "Two at once. The street's clearer." Give the line something beneath the visible result.

I checked every round 8 replacement:

- **Dodge timing:** DODGE_C2, KES_DODGE_C1, MERCY_DODGE_C2, GREY_DODGE_C2, VEL_DODGE_B2 and VEL_DODGE_C2 remove the unsupported anticipation claims.
- **Vellum identity and attacks:** VEL_KILL_N1, VEL_KILL_N3, VEL_KILL_C1 and VEL_MULTI_N1 resolve the named identity, flashing and screen-state assumptions. VEL_MULTI_N1 has the separate writing issue above.
- **Machinery:** MERCY_BACK_N1 now describes the Steward's motive and preference; KES_BACK_B1 asks about the muted interval. Both are sound. GREY_KILL_N4 repairs pump state but retains the enemy-action defect; KES_BACK_N1 introduces the door claim above.
- **Fight results:** VEL_MULTI_C1's pair distance is supported by the existing two-kill calculation. VEL_BOSSDOWN_B1 no longer invents paper exhaustion.
- **Checkpoints:** GREY_CHECK_N1 and VEL_CHECK_N1 remove the incorrect landmark names.
- **Safety history:** TIDE_HURT_C2 makes the five-year record explicitly historical.
- **Checkpoint writing:** CHECK_C1 and TIDE_CHECK_C1 now add history and the Steward's perspective.
- **Chronology clarification:** VEL_IDLE_N1 separates the press's eleven-year history from the final repeated page. I found no confirmed chronology conflict in that replacement.

The other round 7 rewrites also retain their repairs. Earlier read-state, saved narration history, spent-beat, purpose-filtering, pair-distance and story-protection changes remain intact.

Independent read-only checks confirmed **681 Steward lines**, current manifest text and voice-settings hashes, clips for every line, and no orphan manifest entries. All **465 pooled texts** are distinct. The current diff contains **36 distinct rewritten texts**, because two lines were rewritten in both rounds 7 and 8. Every corresponding Ogg changed and decoded cleanly. Both requested diffs pass `git diff --check`.

Current primary logs confirm clean import, **539 passing tests**, gold and serif ownership checks, and the **30-second native smoke pass**. I found no weakened assertion or removed gate check. The campaign is still running, so a completed full gate on this tree remains unverified.

Low-value nits remain separate: repeated openings and shared sentence templates are noticeable together, but do not warrant further findings. Historical detail, broad profiling judgments and the deliberately retained voice-back questions are not additional observation defects merely because the runtime does not measure them.

I made no edits. The reachability checks were source-branch models, not engine reproductions. Real actor delivery and narration density in play remain unverified and belong to the later writing and voice polish identified in PROGRESS.md.

## Round 9 fixes

1. **It knows what it killed.** Like the distance, `StewardWatch` now passes the kind of machine that
   died ("custodian", "salvager", "clerk", "sterilizer"...), and a line can carry `when: {"kind": ...}`;
   two at once carry a kind only if both were the same. Every kill line about a machine's job now says
   which machine (Tideworks and Greywater have Custodians and Salvagers, the Vellum Custodians and
   Clerks, Mercy Custodians and Sterilizers): the mopping and sweeping lines are the Custodians', the
   lost manifests and the metal the Salvagers', the filing the Clerks', the contamination and theatre
   four the Sterilizers'. Three lines added so every kind in those districts has its own (GREY_KILL_N5
   "A cargo drone, this far from the quay. It lost its manifest and followed the metal.", GREY_KILL_N6
   "It was carrying off the pump fittings. I'd have stopped it, once.", VEL_KILL_N5 "It swept the same
   doorstep every morning. The paper came back every night."), and the lines that called any of them
   "drones" or said they grab now don't (TIDE_MULTI_N1, MERCY_MULTI_N1, TIDE_DODGE_B2, TIDE_DODGE_C2,
   TIDE_IDLE_B1 "If any salvagers are left"). An unknown kind is a load error. Tests:
   `test_line_selector::test_it_says_what_it_killed_only_when_it_was` (in each of those districts, for
   each kind: always something to say, never another kind's line),
   `test_adaptive_narration::test_it_knows_what_it_killed` (real kills: a Custodian, then a Clerk close
   behind says no kind; two Clerks say Clerk).
2. **The gates.** KES_BACK_N1 "There. Most of the gates up here only open on my signal."
3. **The Vellum's two-kill line.** VEL_MULTI_N1 "Two of them. The Post would have had a word for that.
   It had a word for everything."

Ten lines voiced (three new, seven rewritten); 684 Steward lines in all.

## Round 10 findings (verbatim from sol_analyst)

Round 9's named fixes are sound, but milestone 6 is not ready to close. Three P2 observation defects and one P3 writing issue remain. No P0 or P1 findings.

1. **P2. The Loop can call a Conductor-and-Custodian pair "two cleaners."**

   Confirmed: bosses also enter ordinary kill bookkeeping. [Boss._die](/home/homebox/Documents/rookmate/undertow/game/bosses/boss.gd:225) calls `Enemy._die`, which [emits `died`](/home/homebox/Documents/rookmate/undertow/game/enemies/enemy.gd:184). [Level.add_enemy](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:821) forwards that signal to StewardWatch. The Conductor's separate [boss-down notification](/home/homebox/Documents/rookmate/undertow/game/bosses/conductor.gd:192) does not remove it from the previous-kill state.

   Defeat the Conductor, then a Custodian within two seconds, with cooldowns clear. [StewardWatch](/home/homebox/Documents/rookmate/undertow/game/level/steward_watch.gd:157) correctly supplies no shared kind, but [LOOP_MULTI_N1](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:1233) has no kind condition. Its "Two cleaners" remains the sole fresh neutral district option. The priority multi-kill event can replace the ordinary boss-down speech.

   This is a remaining milestone defect. Keep bosses out of ordinary kill/pair bookkeeping, or require `custodian` for the Loop's cleaning lines. The new kind test covers four mixed districts but [omits the Loop and boss pairs](/home/homebox/Documents/rookmate/undertow/tests/unit/test_line_selector.gd:274).

2. **P2. The new Greywater line assumes cargo that the kind condition does not establish.**

   [GREY_KILL_N6](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:2389) says, "It was carrying off the pump fittings."

   Confirmed: a Salvager starts with [empty loot](/home/homebox/Documents/rookmate/undertow/game/enemies/salvager.gd:13). Its theft code takes [the player's weapon or scrap](/home/homebox/Documents/rookmate/undertow/game/enemies/salvager.gd:67), and it can die before stealing anything. StewardWatch supplies kind and distance, without cargo or theft history. After `GREY_KILL_N5` is heard, N6 is the sole fresh neutral Greywater option for any Salvager kill.

   The writing interpretation matters here. The line reads as the defeated machine's recent activity; an earlier, off-screen history is possible but unstated. Make that history explicit, or describe its metal-collecting motive without claiming it was carrying fittings. This new line needs more than identity gating.

3. **P2. A Tideworks kill line still announces the end of a safety record that may already have ended.**

   [TIDE_KILL_N3](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:1557) says, "Five years without an injury on this quay. That ends the record."

   Confirmed: it remains eligible after the player has already taken damage. [Operator.take_hit](/home/homebox/Documents/rookmate/undertow/game/player/operator.gd:311) applies injury and emits `hurt`; kill selection receives no first-injury state. The line is also an ordinary repeating line.

   The historical record is supported by [Log 0412](/home/homebox/Documents/rookmate/undertow/data/logs/memory_logs.json:318). The claim that *this* kill ends it is unsupported after an earlier injury. Make the record explicitly historical, as round 8 correctly did for `TIDE_HURT_C2`. This is a remaining milestone defect, not a round 9 regression.

4. **P3. The rewritten Tideworks two-kill line still supplies the rejected play-by-play.**

   [TIDE_MULTI_N1](/home/homebox/Documents/rookmate/undertow/data/narration/steward_lines.json:1629) now says, "Two down. The quay's never been this tidy."

   Confirmed: removing "drones" fixes its identity assumption, and it remains Tideworks' sole fresh neutral district two-kill line.

   Writing judgment: it reports two defeats and a tidier location without adding history, motive or a continuing story. That follows the same construction as "Two at once. The street's clearer," explicitly rejected by [design/writing-review.md](/home/homebox/Documents/rookmate/undertow/design/writing-review.md:89). Give this line something beneath the visible result.

The round 9 repairs themselves checked out. [`kind` validation and filtering](/home/homebox/Documents/rookmate/undertow/core/line_selector.gd:88) reject unknown line kinds and exclude mismatches. StewardWatch passes the dying machine's class name, and supplies a shared kind only when both consecutive deaths match. Existing pair-distance checks remain intact. The named Greywater, Vellum and Tideworks job lines now select for the intended families. `KES_BACK_N1` narrows its claim to most automated gates; `VEL_MULTI_N1` now adds the Post's perspective rather than merely reporting a clearer street.

I checked every district's kill and two-kill pools against translated map markers, hold waves and revisit hardening:

| District | Ordinary machines placed | Hold waves |
|---|---|---|
| Kestrel | Custodians, Lamplighters | None |
| Loop | Custodians | Custodians |
| Tideworks | Custodians, Salvagers | Custodians |
| Mercy | Custodians, Sterilizers | Custodians |
| Greywater | Custodians, Salvagers | Custodians |
| Vellum | Custodians, Clerks | Custodians, Clerks |
| Harbor | Wardens, including patrol reinforcements | Wardens |
| Spire | None | None |

The [spawn code](/home/homebox/Documents/rookmate/undertow/game/level/level.gd:727) and [hold definitions](/home/homebox/Documents/rookmate/undertow/data/holds.json:21) support that matrix. Revisits add Custodians beside existing Custodian markers and adjust existing machines' stats; they introduce no new family. Lamplighters are hittable while muted, when narration is silent. Bosses also reach the ordinary death path, producing finding 1. Weak points retire without emitting a kill.

Independent checks confirmed **684 Steward lines**, matching manifest text and voice-settings hashes, clips for every line, and no orphan manifest entries. All **468 pooled texts are distinct**. All **42 new or rewritten texts** against HEAD have new or changed Ogg files, and every corresponding recording decodes cleanly. I found no additional canon conflict or newly introduced exact duplicate.

Earlier read-state, saved narration history, spent-beat, purpose-filtering and story-protection repairs remain intact. I found no weakened existing assertion or removed gate check. Replacing whole-dictionary distance assertions with assertions on `reach` preserves their intended checks while accommodating `kind`.

Low-value nits remain separate: repeated openings and shared sentence templates are noticeable when reading pools together, but do not warrant further findings. Historical detail and broad profiling judgments are not defects merely because gameplay does not measure them.

Current primary logs confirm clean import, **541 passing tests**, gold and serif ownership checks, and the **30-second native smoke pass**. Both requested diffs pass `git diff --check`. The current gate's campaign has reached Tideworks but has no final result; a completed full gate on this tree remains unverified.

I made no edits. Eligibility checks were read-only source models, not engine reproductions of these counterexamples. Encounter frequency, real actor delivery and narration density in play remain unmeasured.

## Round 10 fixes

1. **A boss is no part of a pair.** A boss's death is its own line (`boss_down`); `StewardWatch` no longer
   counts it as a kill, so a Custodian just after the Conductor is a kill, not "two cleaners". The Loop's
   "Two cleaners" also needs two Custodians now. Tests: `test_adaptive_narration::test_a_boss_is_no_part_of_a_pair`
   (the Editor goes down, then a Custodian: a Custodian on its own, nothing about two at once; it failed
   before the fix), and the kind test now covers the Loop and Kestrel, and pairs of different kinds.
2. **The Salvager's cargo.** GREY_KILL_N6 "Its kind took the pump fittings after the Quiet. I'd have
   stopped them, once." (history, not what this one carried).
3. **The quay's record.** TIDE_KILL_N3 "It worked this quay five years without hurting anyone. So did I."
4. **Under the Tideworks two-kill.** TIDE_MULTI_N1 "Two down. This quay moved forty ships a week on units
   like these."

Three lines rewritten and voiced.
