# Review: the regular enemies after the painted rigs

The user, on main after PR #2 (the painted rigs): "there are some issues with the existing regular
enemies, like they don't face player when attacking him, there seem to not be any collision detection
and such."

## What the probe showed

A temporary windowed scene staged each of the six regular families (Custodian, Clerk, Salvager,
Sterilizer, Warden, Lamplighter) attacking a standing Operator from the four ground directions, with
neutral light, and took screenshots at the windup and the strike. In all 24 cases the machine's logical
facing pointed straight at the Operator: the AI turned correctly. What looked wrong was drawn: the new
windup pulled the weapon back, away from you, for 70% of the warning; the Custodian's lunge carried it
into the Operator's body; and the Salvager was nearly invisible on cobble. The collision layers showed
why there was "no collision": machines didn't have the Operator's layer in their mask.

## Sol's review (verbatim from sol_analyst)

Reviewer: **sol_analyst** (Sol 6.1, xhigh, read-only) via the "Sol analysis" skill. Scope: the six
regular families and their rigs on a5d142e, and `git diff 139a7b9 a5d142e` for what PR #2 introduced.

The report points to real collision and attack defects, but the supplied facing diagnosis is partly wrong. The AI turns correctly. The Clerk's front torso faces correctly, and a Warden baton pointing backward during windup is its backswing. PR #2 did introduce incorrect Clerk rear artwork and several gaps between the new animation and the existing attack mechanics.

No P0 found. “Confirmed” below means established from code, source artwork, supplied captures, or numerical evaluation of the production transforms. Where gameplay consequences remain untested, I say so.

1. **P1 · Confirmed · Predates PR #2. Enemy movement ignores the Operator's body.**

   `Enemy.setup()` assigns layer `4` and mask `5`, which includes walls and enemies but excludes the Operator's layer `2`. The Operator includes enemies in its own mask while walking. Consequently, walking into an enemy stops the Operator, but an enemy's movement does not stop against the Operator. Enemy lunges and knockback can enter the player's body; subsequent player collision recovery can displace the player.

   Evidence: `game/enemies/enemy.gd:43–57`, `game/enemies/enemy.gd:149–153`, `game/player/operator.gd:64–74`, `game/player/operator.gd:164–180`. Godot's character motion filtering uses the moving body's mask, as confirmed in its [motion query](https://github.com/godotengine/godot/blob/4.7.2-stable/modules/godot_physics_2d/godot_space_2d.cpp#L465) and [`collides_with` implementation](https://github.com/godotengine/godot/blob/4.7.2-stable/modules/godot_physics_2d/godot_collision_object_2d.h#L177).

   **Fix:** establish symmetric contact for regular enemies and the walking Operator. Preserve roll-through explicitly on both sides, using scoped collision exceptions or removing the Operator's actor-contact layer for the full roll. Simply adding the player bit to `Enemy.collision_mask` would break rolling because enemies would still detect the rolling player's unchanged layer. Review bosses separately because they inherit `Enemy`.

2. **P1 · Confirmed · Predates PR #2. Sterilizer mist follows a retreating player beyond its advertised reach and ignores cover.**

   Windup starts within `1.6` tiles, but `_release()` uses the player's current position without checking range, life, or line of sight. It places the cloud at 70% of the distance to that position. The cloud subsequently checks only distance and lifetime.

   A player running directly away at `3.2` tiles/s during the `0.8`-second windup can reach approximately `4.16` tiles from the drone. The cloud still appears `2.91` tiles from the drone, only `1.25` tiles behind the player, inside its `1.35`-tile damage radius. Leaving the drawn `1.6`-tile warning ring therefore does not evade the attack. Walls can lie between drone, cloud, and victim without preventing damage.

   Evidence: `game/enemies/sterilizer.gd:44–52`, `game/enemies/sterilizer.gd:65–73`, `game/enemies/sterilizer.gd:85`; `game/hazards/sterile_cloud.gd:22–35`.

   **Fix:** bound deployment to a reachable attack point, validate cover at release, and draw the actual cloud footprint before release. Decide whether walls partition an existing cloud, then enforce that rule in `covers()`.

3. **P1 · Confirmed · Predates PR #2. Warden baton damage has no cover or strike-geometry check.**

   On release, the Warden damages any living Operator within `1.5` tiles. It checks neither line of sight nor an attack arc. Hearing deliberately works through nearby cover, and `_hunt()` can begin windup using that detection, so hearing must not also authorize a baton hit through cover.

   Evidence: `game/enemies/warden.gd:65–71`, `game/enemies/warden.gd:101–107`, `game/enemies/warden.gd:116–120`.

   **Fix:** validate line of sight and a committed strike region at impact. Use the same strike definition for telegraph, painted baton motion, and damage. Adding an arc against facing freshly recomputed toward the player would be ineffective because that target would always be centered in it.

4. **P1 · Confirmed · Predates PR #2. Salvagers can steal through cover and beyond the warning ring.**

   `_snatch()` checks distance up to `1.5` tiles and roll invulnerability, but no line of sight or claw reach. Its warning ring is only `1.1` tiles. A weapon or scrap can disappear while the player is outside the ring or separated by a blocking corner.

   Evidence: `game/enemies/salvager.gd:51–59`, `game/enemies/salvager.gd:69–78`, `game/enemies/salvager.gd:110–111`.

   **Fix:** give snatching one authoritative reach and cover check. Draw that reach and drive the claw toward the same attack point.

5. **P2 · Confirmed · Predates PR #2. Body contact is much smaller than gameplay and painted footprints.**

   Every regular enemy receives the same `12`-radius, `40`-height horizontal screen-space capsule, regardless of `radius_tiles` or artwork. The Operator receives `13`/`46`. Their combined capsule geometry allows center spacing around `0.48–0.49` ground tiles, depending on direction. The Custodian's gameplay radius plus the Operator's is `0.68` tiles.

   Thus fixing the masks alone will still leave substantial painted overlap. Enemy-to-enemy capsules likewise prevent total physical coincidence while permitting visibly crowded bodies. “No enemy collision exists” is incorrect; the contact geometry is undersized and separate from combat geometry.

   Evidence: `game/enemies/enemy.gd:17`, `game/enemies/enemy.gd:51–56`; `game/enemies/custodian.gd:19`; `game/player/operator.gd:22`, `game/player/operator.gd:68–73`; `core/iso.gd:15–20`.

   **Fix:** define ground footprints deliberately. Use projected ground shapes or obstacle-aware actor separation derived from those footprints. Keep every individual footprint narrower than a one-tile passage, and verify real doors and opposing traffic. The reported `0.75`-tile visual clearance is a useful Custodian art measurement, not a universal radius for all six families.

6. **P2 · Confirmed · Predates PR #2. The Custodian lunges through its target and can overshoot its own damage check.**

   It begins within one tile, then travels at `7` tiles/s for roughly `0.16` seconds, over one tile of displacement. It neither stops at contact nor limits travel to the available gap. Damage is sampled once, late in the lunge, against an arc from the enemy's already moved position.

   At close starting distances, the Custodian can pass the player before sampling the hit, leaving the player behind its attack arc. The asymmetric collision mask makes this especially visible. It also returns lunge velocity on the frame that changes state to recovery.

   Evidence: `game/enemies/custodian.gd:8–12`, `game/enemies/custodian.gd:46–63`.

   **Fix:** stop the lunge at actor contact or its committed endpoint, resolve a swept attack over the actual travel, and return zero once recovery begins. Preserve the intended attack timing explicitly.

7. **P2 · Confirmed · Introduced by PR #2. The Clerk's “back” rig contains a front-facing head.**

   The old `clerk_back` artwork has a rear head. The new `rig_clerk_back_torso` retains the same open, front-facing helmet as the new front torso, while replacing its monitor with a blank plate. Selecting the rear rig therefore produces contradictory orientation cues. Feed windup also paints its white rectangle over that blank plate.

   Evidence: `assets/art/complete/enemy_light_rig.png`; `assets/art/complete/catalog.json:2073`, `assets/art/complete/catalog.json:2157`; `game/actors/painted_biped.gd:7–13`; `game/enemies/clerk.gd:113–116`.

   **Fix:** supply an actual rear torso/head and appropriate screen/emitter artwork and anchors. Keep the rig's front/back and horizontal-facing conventions explicit.

   **Do not globally reverse Clerk mirroring.** Its front artwork faces screen-right, and production mirroring correctly makes it face screen-left when required. A near shoulder left of the hip does not prove left-facing artwork. The supplied front-view captures show the head facing the player while the arm is drawn back.

8. **P2 · Confirmed · Animation mismatch introduced by PR #2; underlying attack rules predate it. Painted strikes and projectile origins do not share gameplay geometry.**

   The Warden's damage reach is `1.5` tiles, but its painted baton follows a fixed arm rotation unrelated to target distance or aim elevation. Evaluating the production transforms at release gives unmirrored weapon anchors approximately `(33.85, -57.87)` for front view and `(15.41, -95.89)` for back view. A target at the normal `1.25`-tile attack distance can remain visibly well beyond that painted strike.

   The Clerk throws from its new animated hand, but the bale actually appears at a fixed half-tile ground offset and fixed `64`-pixel chest height. In the front cardinal view, that places release roughly `42` screen pixels from the animated hand.

   Evidence: `game/actors/painted_biped.gd:37–53`; `core/painted_parts.gd:21–26`; `game/enemies/warden.gd:104–105`; `game/enemies/clerk.gd:94–103`; `game/weapons/projectile.gd:8`, `game/weapons/projectile.gd:89–95`.

   **Fix:** expose attack attachment transforms and a committed attack target. Align baton motion and hit region, and launch the bale visually from the hand while retaining correct ground-space collision and wall checks.

   The supplied Warden windup screenshot does **not** establish a reversed release. The rear baton moves from approximately `(-7.54, -59.38)` at backswing to `(15.41, -95.89)` at release, forward toward an up-right target. Its backward windup pose is intentional.

9. **P2 · Confirmed · Introduced by PR #2. Hover appendage extension does not aim at the attack point.**

   `PaintedHover` extends every claw/nozzle by the fixed screen vector `(4, 12)`, then mirrors only its x coordinate. Rear-view extension still travels downward even when the player is above the drone. The Salvager's newly advertised reaching motion therefore does not reach toward the victim, and the Sterilizer's deployment does not identify the cloud's actual placement.

   Evidence: `game/actors/painted_hover.gd:17–27`; `game/enemies/salvager.gd:98–107`; `game/enemies/sterilizer.gd:80–85`.

   **Fix:** pass a local attack point or deployment direction into the hover rig. Keep vertical lowering as a separate component, and attach carried loot through a real claw-grip anchor.

10. **P2 · Confirmed · Predates PR #2. A Lamplighter can hook an invulnerable rolling player.**

    `_hook()` calls `take_hit()` and then unconditionally installs the pull. The damage can be evaded while the hook still takes hold. Unlike Salvager snatching, hook acquisition has no explicit invulnerability check.

    Evidence: `game/enemies/lamplighter.gd:142–153`; `game/player/operator.gd:233–234`, `game/player/operator.gd:302–305`.

    **Fix:** apply the intended roll-evasion rule to hook acquisition before installing the pull. Do not blindly use every failed damage result as “hook missed,” because ordinary hurt grace and roll invulnerability are different policies.

11. **P2 · Confirmed · Predates PR #2. Multiple Lamplighters overwrite and release each other's pulls.**

    The Operator has one pull target and timer. Every lamp overwrites it through `pull_toward()`, and any hooked lamp's `_release()` clears it without checking ownership. One lamp losing sight, dying, or being struck can therefore release another lamp's active hook.

    Evidence: `game/player/operator.gd:55–58`, `game/player/operator.gd:185–192`; `game/enemies/lamplighter.gd:152–162`.

    **Fix:** give pulls an owner/token and release only that owner's effect, or explicitly arbitrate a single active hook.

12. **P2 · Confirmed · Predates PR #2, only partly addressed by it. Hostile Lamplighter facing becomes stale.**

    Hostile lamps update facing when acquiring or winding up a hook. They do not update it while chasing without sight or while holding the beam. `visual_facing()` uses that stale logical facing whenever hunting, so a moving lamp can face its previous target direction, and its directional head can remain turned away while the beam tracks a player crossing behind it.

    Evidence: `game/enemies/lamplighter.gd:95–117`, `game/enemies/lamplighter.gd:186–200`.

    **Fix:** use actual travel for chase orientation and current beam aim while hooking. Preserve deliberate facing during committed windup. PR #2 fixed the friendly travel view, not the hostile cases.

13. **P2 · Confirmed implementation limitation; frequency inferred · Predates PR #2. Retreating and fleeing enemies get stuck against obstacles.**

    The Clerk backs directly away from the player, the Sterilizer retreats directly, and a loaded Salvager flees directly. These movements bypass `steer_to()`. None selects another route when a wall blocks that direction. A Salvager can consequently remain pinned against a wall with the stolen weapon instead of escaping around it.

    `steer_to()` also bypasses navigation whenever the target is within `1.2` tiles, even if a blocking corner separates them; an empty path falls back to direct movement into the obstacle.

    Evidence: `game/enemies/clerk.gd:56–59`; `game/enemies/sterilizer.gd:58–60`; `game/enemies/salvager.gd:37–40`; `game/enemies/enemy.gd:211–223`.

    **Fix:** choose reachable retreat/flee waypoints and steer to them. Permit direct approach only when the local route is clear. Detect sustained blockage and repath without widening bodies beyond passage clearance.

14. **P2 · Confirmed visual problem · Predates PR #2. The Salvager is difficult to distinguish from dark cobble.**

    The supplied neutral-light captures confirm poor hull and claw contrast. The hover rig uses the original source pixels, original height, and white tint; PR #2 did not introduce the dark Salvager painting. A `56`-pixel full-body height further reduces its small details.

    Evidence: `assets/art/complete/enemies_front.png`, `assets/art/complete/enemies_back.png`; `game/enemies/salvager.gd:104–107`; `game/actors/painted_hover.gd:10–14`. Those source PNGs are unchanged between `139a7b9` and `a5d142e`.

    **Fix:** raise local value contrast and silhouette separation in the Salvager artwork, or add restrained, consistent readability treatment. Check it against actual district floors in neutral and muted lighting. Increasing attack-marker brightness does not make the body readable.

15. **P3 · Confirmed · Predates PR #2. Ground warnings and shadows share the actor's draw order.**

    Enemy shadows, sight cones, and warning rings are drawn inside each enemy's `_draw()`. The complete draw command set sorts at that enemy's ground y coordinate. A ring or cone can therefore paint over another actor instead of staying on the ground.

    Evidence: `game/level/level.gd:95–103`; `game/enemies/enemy.gd:234–249`; `game/enemies/warden.gd:154–164`.

    **Fix:** render ground warnings and shadows in `fx_ground`, following their owning enemy. Keep painted bodies in the existing foot-based world y-sort.

    The world itself already has y-sorting enabled, and enemies are added at their ground positions. I found no general missing-y-sort regression in PR #2.

16. **P3 · Confirmed lifecycle gap; exact visible persistence depends on frame order · Predates PR #2. Death does not request a final redraw.**

    `_die()` changes state, removes collision, and starts fading, but does not call `queue_redraw()`. Dead enemies immediately stop running the base physics redraw loop. Depending on when the killing hit lands, cached warning rings, attack lamps, or a released Lamplighter beam can remain in the fading drawing.

    Evidence: `game/enemies/enemy.gd:136–138`, `game/enemies/enemy.gd:197–207`; `game/enemies/lamplighter.gd:80–82`, `game/enemies/lamplighter.gd:156–162`.

    **Fix:** request a final redraw that suppresses active attack effects and preserves an intentional death pose.

    Articulated collapse is not an omitted PR requirement: the review explicitly retains the existing fade. Stun already interrupts AI and stops stride advancement; most families lack a distinct sustained stun pose, which is a readability improvement rather than a confirmed combat regression.

The eight supplied observations resolve as follows:

| Observation | Verdict |
|---|---|
| Logical facing points at the player | Supported by the windup branches and supplied probe. |
| Clerk faces away in all four directions | Refuted as stated. Front torso faces correctly; rear torso/head artwork is wrong. Windup arm backswing is intentional. |
| Warden rear arm points away | True during backswing, not evidence of a reversed release. Actual release moves forward. |
| Custodian faces correctly | Supported by its artwork and supplied captures. |
| Custodian lunge enters the player | Confirmed by movement distance and contact filtering. |
| Enemies do not collide with the Operator | Enemy-initiated movement ignores the Operator; Operator-initiated movement still detects enemies. |
| Contact spacing is smaller than gameplay/art spacing | Confirmed. The `0.75` visual threshold should remain family-specific. |
| Salvager is almost invisible on cobble | Supported by the neutral-light captures; source-art issue predates PR #2. |

Knockback is already processed through `move_and_slide()` for both actors, so I found no unconditional position-based knockback-through-walls bug. Enemy knockback can enter the Operator because of finding 1. Lamplighter pulling toward the Lattice rather than necessarily toward the lamp is intentional, as are Clerk and Sterilizer retreating while facing the player.

I independently ran the focused actor-animation suite: **6 tests passed**. Godot also emitted an initial sandbox-related failure to open its requested log file, so this was not a clean full-gate run. The existing animation tests validate stride math, attack-pose timing, and forward baton displacement. They do not validate body clearance, cover checks, hook evasion, actual painted facing, or contact between painted strikes and victims. The native enemy preview disables Operator physics and only requires observing windup, so it cannot establish player-contact correctness.

No files or tests were edited. The next implementation should keep movement/contact rules in the actor layer and attack geometry in authoritative attack definitions, with rigs consuming those definitions. Add regressions for both directions of contact, roll-through, one-tile passages, close lunges, attacks around cover, moving Sterilizer targets, multiple hooks, and front/rear rendered release alignment. Then run the unchanged `tools/check.sh` gate, including boss and autopilot coverage.

Sol corrected one of the probe's readings: the Clerk's front view faces you (its arms were in the
backswing); its rear view is what's wrong, painted with a face.

## Fixes (steps 47 to 49)

All sixteen findings were fixed, in three steps (DECISIONS 209 to 211).

1. **Contact** (finding 1). A regular machine's mask includes the Operator's layer except while the
   Operator rolls; the Operator's mask already drops machines mid-roll. Bosses and weak points keep
   their own physics. Tests: `test_enemy_contact::test_a_machine_stops_against_you`,
   `test_knocked_back_into_you_it_stops_at_you`, `test_a_roll_passes_through_a_machine`.
2. **Footprints** (finding 5). A regular machine's body is a ground ellipse of its radius_tiles.
   Test: `test_enemy_contact::test_every_body_fits_a_one_tile_passage` (all six through a passage one
   tile wide and ten long).
3. **The Custodian's lunge** (finding 6): commits its direction and start as the windup ends, is
   judged from there, hits on contact, stops at what it meets, and returns no velocity once it
   recovers. Test: `test_enemy_contact::test_a_close_lunge_ends_at_you`.
4. **Getting away** (finding 13). `Enemy.retreat_from` takes the open way of eight that ends farthest
   from the threat within five tiles; the Clerk, the Sterilizer and a loaded Salvager use it.
   `steer_to` goes straight at a near target only when nothing stands between. Test:
   `test_enemy_contact::test_a_cornered_machine_backs_out_round_the_wall` (backed into a corner).
5. **The Sterilizer** (finding 2) commits its mist's place at the start of its windup and draws it
   there; it winds up only in sight; walls cut the mist off (`SterileCloud.covers`). Tests:
   `test_enemy_attacks::test_stepping_out_of_the_drawn_mist_escapes_it`, `test_a_wall_cuts_the_mist_off`.
6. **The Warden** (findings 3, 8) winds up only in sight, turns with you for 55% of the windup, then
   commits, steps in up to half a tile, and lands only inside its 120° swing, in reach and sight.
   Tests: `test_enemy_attacks::test_a_warden_swings_only_at_what_it_can_reach`,
   `test_stepping_out_of_a_committed_swing_makes_it_miss`.
7. **The Salvager** (finding 4): one reach, the ring it draws (`Salvager.catch_reach()`), and never round
   a corner. Test: `test_enemy_attacks::test_a_salvager_takes_nothing_from_beyond_its_ring_or_round_a_corner`.
8. **The Lamplighter** (findings 10, 11): a roll evades the hook (no pull, an evasion); the Operator's
   pull is owned by the lamp that cast it. Test:
   `test_enemy_attacks::test_a_roll_evades_the_hook_and_lamps_keep_their_own_pulls`.
9. **The windup** (the user's "doesn't face me"). `Enemy.attack_pose` cocks only to -0.35 and strokes
   forward through the last 40% of the warning. PR #2's test asserted the old full backswing; it now
   asserts the new pose as strictly (never past the cock at any point of the windup, cocked by the
   middle, impact exactly at release): `test_actor_animation::test_attack_pose_reaches_release_at_the_gameplay_deadline`.
10. **The Clerk's back** (finding 7): the original rear painting, on its stride's bob, until the rig
    gets a real back.
11. **The bale** (finding 8) leaves the Clerk's hand, drawn at the hand's height (`Projectile.height`).
    Test: `test_enemy_readability::test_a_clerks_bale_leaves_from_its_hand`.
12. **Hover appendages** (finding 9) reach toward their target (`PaintedHover.paint`'s aim): the
    Salvager's claw at you, the Sterilizer's nozzles at its mist. Test:
    `test_enemy_readability::test_a_hover_drones_claw_reaches_toward_its_target`.
13. **The Lamplighter's facing** (finding 12): at you while it winds up or holds you (it turns to keep
    you in the beam), the way it walks otherwise. Test: `test_enemy_readability::test_a_lamp_holding_you_keeps_facing_you`.
14. **The Salvager reads** (finding 14): drawn at 64 px (from 56) and lifted 1.45.
15. **Ground marks** (finding 15): shadows, sight cones and warning rings of regular machines are drawn
    by a `GroundMarks` node in the level's ground layer, under every body. Test:
    `test_enemy_readability::test_shadows_and_warnings_lie_on_the_ground_under_every_body`.
16. **Death** (finding 16): `_die` redraws once; rings and cones only draw in their states.

The contact tests were run against the old enemy code too: the four about bodies (a machine stopping
against you, knockback, a close lunge, a corner) failed there and pass now.

## Round 1 findings (verbatim from sol_analyst)

The work is **not done**. Most fixes are sound, but findings 3, 6, 7, 8 and 13 still have gaps. I found five actionable issues, all P2. No P0 or P1 remains confirmed.

1. **P2 · Confirmed · The Warden’s warning, painted baton and damage still describe different reaches.**

   [`_strike_lands()`](/home/homebox/Documents/rookmate/undertow/game/enemies/warden.gd:132) accepts an Operator center up to **1.80 tiles** away: `REACH 1.25 + 0.25 + Operator.RADIUS_TILES 0.30`. HEAD accepted 1.50. Its [warning ring](/home/homebox/Documents/rookmate/undertow/game/enemies/warden.gd:187) remains 1.25 tiles, so damage can land when the Operator’s entire combat footprint is outside it.

   The baton still uses the [unchanged fixed arm rotation](/home/homebox/Documents/rookmate/undertow/game/actors/painted_biped.gd:45), independent of target distance and committed strike geometry. Evaluating the production transforms still gives release anchors `(33.85, -57.87)` in front view and `(15.41, -95.89)` behind. At a valid 1.79-tile impact distance, those anchors are about 100 pixels from the target’s chest. Stepping forward helps at close range but does not close original finding 8.

   **Fix:** define one committed strike region and endpoint. Use them for the warning, baton motion and impact query. Remove the extra reach unless the warning and artwork explicitly advertise it. Test radial escape and rendered release alignment in all four directions.

2. **P2 · Confirmed · A Custodian can spend its blow on a miss, then make contact without hitting.**

   [`custodian.gd:65`](/home/homebox/Documents/rookmate/undertow/game/enemies/custodian.gd:65) sets `_struck = true` before determining whether the attack reaches the player. After the 60% sample, later contact cannot land the blow.

   A concrete case follows from the production timing. Begin the committed lunge with the Operator 1.90 tiles ahead, walking toward it at 3.2 tiles/s. At the approximately 0.10-second sample, the Operator remains about 1.58 tiles from `_lunge_from`, outside the 1.55-tile query. The blow is spent. The two bodies meet before the 0.16-second lunge ends, but the subsequent `touching` condition is ignored.

   **Fix:** resolve the active attack over actual, collision-limited travel, or keep a missed blow available until contact or the explicit end of its active window. Add this returning-player case alongside the passing close-lunge test. Original finding 6 is only partly fixed.

3. **P2 · Confirmed · The Clerk’s rear fallback removes its Feed warning.**

   The [rear-view branch](/home/homebox/Documents/rookmate/undertow/game/enemies/clerk.gd:120) returns before the [Feed windup drawing](/home/homebox/Documents/rookmate/undertow/game/enemies/clerk.gd:130). The attack itself still calls `_flash_feed()` and can blind an Operator looking toward it from that side.

   Using the original rear painting is a reasonable fallback. Losing the attack cue is a new defect, especially while the Steward is muted.

   **Fix:** preserve an appropriate Feed warning in the rear branch, using the existing rear screen anchor or another readable emitter cue. Verify that each direction visibly warns before a successful flash.

4. **P2 · Confirmed · The Clerk’s new projectile origin changes its trajectory, and gameplay depends on its last drawing.**

   [`_throw()`](/home/homebox/Documents/rookmate/undertow/game/enemies/clerk.gd:96) aims from the Clerk’s feet, then [moves the physical projectile origin sideways](/home/homebox/Documents/rookmate/undertow/game/enemies/clerk.gd:105) without recalculating that aim. This produces a parallel, displaced trajectory.

   In the supplied contact arena, place the Clerk at ground `(5.4, 4.2)` and the Operator at `(9.4, 4.5)`. The warning line clears the wall. The front release hand shifts the projectile origin to approximately `(5.685, 3.915)`. Its unchanged direction crosses `x = 6` at `y ≈ 3.939`, inside the wall. The advertised clear shot hits cover.

   Furthermore, `hand` is [updated by `_draw()`](/home/homebox/Documents/rookmate/undertow/game/enemies/clerk.gd:119), so rendering frequency and the last rendered facing affect physical spawning.

   The [new regression test](/home/homebox/Documents/rookmate/undertow/tests/integration/test_enemy_readability.gd:54) misses both problems. It stages the static rear fallback, disables physics, never enters the throwing windup, and compares against the same cached `hand` value used to construct the projectile.

   **Fix:** compute the current attachment through a pure transform shared by drawing and release. Resolve a valid physical origin, then aim from that origin toward the attack target. Test an actual front release, mirrored directions, the wall-corner case and release without an intervening draw.

5. **P2 · Confirmed algorithmic limitation; occurrence in shipped encounters inferred · Retreat still cannot navigate some escapable corners.**

   [`_retreat_point()`](/home/homebox/Documents/rookmate/undertow/game/enemies/enemy.gd:288) considers only eight straight rays and rejects every endpoint that does not immediately increase separation. It never searches around a bend or permits a necessary initial approach toward the threat. [`retreat_from()`](/home/homebox/Documents/rookmate/undertow/game/enemies/enemy.gd:283) then returns zero indefinitely.

   For example, a loaded Salvager at `(2.34, 2.5)` with the Operator at `(6.5, 2.5)` returns no destination in a corridor running through cells `(2,2)…(6,2)`, with an open escape bending through `(5,3)…(5,7)` and back to `(2,7)`. An escape route exists; none of the eight rays finds it. I confirmed this calculation from the production algorithm, not a native gameplay reproduction.

   **Fix:** score reachable navigation destinations and follow their routes, allowing temporary approach when required. Detect sustained blockage and reject or replace the failed destination. Add a bent-corridor test. The current open-corner test establishes a useful improvement, but does not close original finding 13.

Every original finding was checked:

| Original finding | Result |
|---|---|
| 1. Enemy-initiated contact | Fixed. Regular enemies include the walking Operator and exclude a rolling Operator. |
| 2. Sterilizer pursuit and cover | Fixed. Deployment is committed, release checks cover, and walls partition damage. |
| 3. Warden cover and strike geometry | Cover and commitment fixed; warning/reach mismatch remains above. |
| 4. Salvager reach and cover | Fixed. Warning and snatch use `catch_reach()`; cover is checked. |
| 5. Undersized footprints | Fixed for regular enemies. Keeping the Operator capsule and boss capsules is consistent with the stated scope. |
| 6. Custodian lunge | Contact, overshoot and recovery velocity fixed; late-contact miss remains above. |
| 7. Clerk rear artwork | Rear-facing artwork corrected by the permitted fallback; Feed cue regressed. |
| 8. Painted strikes and projectile origins | Incomplete. Warden alignment and Clerk spawning remain defective. |
| 9. Hover appendage direction | Directional extension fixed; mirrored aim is handled correctly. |
| 10. Hook acquisition during roll invulnerability | Fixed without treating ordinary hurt grace as an evasion. |
| 11. Multiple pull ownership | Fixed through ownership and the explicit latest-pull policy. |
| 12. Hostile Lamplighter facing | Fixed for travel and beam tracking. |
| 13. Retreat/flee obstruction | Improved, but incomplete as described above. |
| 14. Salvager contrast | Size and brightness treatment implemented. I did not independently repeat the district lighting probe. |
| 15. Ground draw order | Fixed through `GroundMarks` in `fx_ground`. |
| 16. Death redraw | Fixed. Final redraw removes state-gated warnings and released beams. |

I found no new gold/serif ownership violation or weakening of an existing test/check. Rewriting the attack-pose test for the explicitly changed 0.35 cock is justified; it still checks the limit, mid-windup pose and release deadline.

I independently ran the **16 new enemy tests: all passed**, with sandbox-denied log/save writes. The current gate log records **573 tests passing** and the smoke run passing. The campaign was still running when I checked; the older ending and tour logs do not establish this tree’s completed gate. Play feel remains unverified.

No low-value nits included. No files were edited.

## Round 1 fixes

1. **The Warden's ring is its reach.** One strike region: the ring it draws is `STRIKE_REACH` (0.7
   tiles, where its baton reaches), and the blow lands if any of you is inside that ring, inside the
   committed 120° swing, in sight (centre within 1.0 tiles, down from 1.8). It steps into the swing until
   it meets you (up to 0.9 tiles), so at release the painted baton is at your chest. Test:
   `test_enemy_attacks::test_a_wardens_ring_is_its_reach_and_its_baton_meets_you` (just inside the ring
   lands, just outside misses; facing each of the four ways, the baton at release is within 50 px of
   your chest at the edge of its reach, from `PaintedBiped.weapon_at`).
2. **A Custodian's blow isn't spent on a miss.** From 60% of the lunge (or on contact) it checks every
   frame until it lands or the lunge ends. Test: `test_enemy_contact::test_walking_into_a_lunge_late_still_meets_it`
   (you 1.9 tiles ahead, walking into it).
3. **The Feed warns from behind too.** Seen from behind, its screen faces you and away from us: the
   light spills round its head, behind it, brightening through the windup.
4. **The bale.** Its origin comes from the rig at release (`PaintedBiped.weapon_at`, pure, shared with
   drawing; `Clerk.hand_at_release`), not from the last frame drawn. It leaves the hand only if both the
   hand's ground point and the line from it to you are clear, else from where it stands (where the
   warning line ran), and it's aimed from wherever it leaves. Tests:
   `test_enemy_readability::test_a_clerks_bale_leaves_from_its_hand` (facing both ways, hidden so no
   frame is drawn: the bale appears at the hand), `test_a_clear_throw_by_a_corner_still_reaches_you`
   (Sol's corner: the bale reaches you).
5. **Getting out of a bent dead end.** Retreat now searches the reachable cells within ten steps
   (breadth first over the machines' own navigation) and takes the one that ends farthest from you,
   following its route even when that passes you; getting nowhere for 1.2 s, it gives that way up.
   Walking a route, a machine now goes well into each cell before turning for the next, so a body
   turns into a one-tile passage instead of catching its corner. Test:
   `test_enemy_contact::test_a_dead_end_with_a_bend_doesnt_trap_it` (Sol's bend, `tests/fixtures/retreat_arena`).

## Round 2 findings (verbatim from sol_analyst)

The work is **not done**. The five round 1 findings were addressed, but original finding 6 still has a confirmed gap. No P0 or P1 found.

1. **P2 · Confirmed · A blocked Custodian lunge can damage an Operator it never reaches.**

   The [attack query](/home/homebox/Documents/rookmate/undertow/game/enemies/custodian.gd:65) becomes active at 60% of the lunge and accepts targets within `1.55` tiles of `_lunge_from`. It checks neither actual travel nor whether the ram reached the Operator. Another machine can stop the Custodian while the origin-based query still lands.

   I reproduced this in native Godot using the contact arena and an in-memory probe. The Custodian began at ground `(6.5, 8.5)`, with a stationary Clerk at `(7.25, 8.5)` between it and the Operator. The Custodian moved only **0.051 tiles**, then dealt **8 damage** while the Operator remained **1.485 tiles** away. The Clerk’s physics processing was disabled, so it could not have caused the damage.

   The round 1 fix correctly preserves a missed blow for later contact. It does not finish the original requirement to resolve the attack over collision-limited travel.

   **Fix:** retain the committed origin and direction as filters, but require intersection with the attack footprint swept along the Custodian’s actual movement. Add a regression with another machine blocking the lunge, alongside the existing close-contact and returning-player tests.

The other round 1 fixes hold up:

- The Warden’s ring and damage now use `STRIKE_REACH`; its shorter reach and step-in address the previous excessive reach and large visual separation.
- The Clerk’s rear fallback now draws a Feed warning before painting the body.
- Clerk spawning uses a pure release transform, checks the proposed origin’s clear lines, and recalculates aim from the chosen origin. Drawing no longer determines gameplay.
- Retreat searches reachable navigation cells and passes the supplied bent-corridor regression. The search remains deliberately bounded to ten steps.

All sixteen original findings were rechecked:

| Original finding | Round 2 result |
|---|---|
| 1. Enemy-initiated contact | Fixed. Regular enemies detect the walking Operator and exclude a rolling Operator. |
| 2. Sterilizer pursuit and cover | Fixed. Deployment is committed and advertised; release and cloud damage check cover. |
| 3. Warden cover and strike geometry | Fixed. Sight, committed direction, arc and advertised reach govern impact. |
| 4. Salvager reach and cover | Fixed. Warning and snatch share `catch_reach()`; cover prevents theft. |
| 5. Undersized footprints | Fixed for regular enemies. Operator and boss capsules remain as explicitly scoped. |
| 6. Custodian lunge | Incomplete. Close contact, recovery velocity and the returning-player miss are fixed; blocked lunges still cause remote hits. |
| 7. Clerk rear artwork | Fixed through the accepted static rear fallback, now with its Feed cue restored. |
| 8. Painted strikes and projectile origins | Addressed by the Warden reach adjustment and Clerk’s pure release transform and corrected aim. |
| 9. Hover appendage direction | Fixed. Extension follows screen-space aim, including mirroring. |
| 10. Hook acquisition during roll invulnerability | Fixed. Rolling prevents acquisition without confusing ordinary hurt grace with evasion. |
| 11. Multiple pull ownership | Fixed under the explicit latest-pull policy. Release checks ownership. |
| 12. Hostile Lamplighter facing | Fixed for travel and active beam tracking. |
| 13. Retreat/flee obstruction | The reported corner and bent-corridor cases are fixed. No additional confirmed encounter defect found. |
| 14. Salvager contrast | Size and brightness treatment implemented. I did not independently repeat the district-lighting probe. |
| 15. Ground draw order | Fixed through `GroundMarks` in `fx_ground`. |
| 16. Death redraw | Fixed. Final redraw suppresses state-dependent attack effects. |

I found no gold/serif ownership violation or weakened existing check. The attack-pose test rewrite is justified by the accepted `0.35` cock and retains checks for its limit, mid-windup pose and release deadline.

I independently ran **33 focused tests**, all passing: 20 enemy, six actor-animation, six colour-rule and one font-rule tests. Sandbox restrictions denied log/save writes, so these were not clean full-gate runs. The current gate logs record **577 tests passing**, clean import and passing smoke gameplay; the campaign had no completed result when checked. Play feel remains unverified.

No low-value nits included. No files were edited.

## Round 2 fixes

1. **A lunge lands on what it reached.** The Custodian's blow now also needs you within its brushes'
   reach (`BRUSH_TILES`, 0.35 past its body) of the ground it actually covered in this lunge, from where
   it set off to where it got (`_swept_distance`), as well as inside the reach and swing it committed
   to. Stopped short by another machine, it doesn't hit you from where it meant to be. Test:
   `test_enemy_contact::test_a_lunge_stopped_short_doesnt_hit_from_afar` (held where it set off, you
   1.45 tiles out, inside its old reach: no blow; moved up to you: it lands). It fails without the fix
   (the blow landed from 1.45 tiles). A first version of the test staged the block with another machine
   in a running scene; drift before the lunge left you out of reach either way, so it proved nothing, and
   was replaced by this one.

## Round 3 findings (verbatim from sol_analyst)

Round 2's finding is **fixed correctly**. I found no remaining actionable P0–P3 defects in the reviewed scope. The fixes pass code review; the current gate still needs to finish before the steps can be declared fully verified.

The Custodian now requires the Operator to intersect its brush footprint along collision-limited travel, while retaining the committed arc and cover checks. A missed blow remains available for later contact, and recovery returns zero velocity. See [the impact query](/home/homebox/Documents/rookmate/undertow/game/enemies/custodian.gd:65) and [ground-space distance calculation](/home/homebox/Documents/rookmate/undertow/game/enemies/custodian.gd:99).

I independently staged a stationary Clerk blocking the lunge in native Godot, facing each of the four ground directions. **All four caused zero damage.** The [new regression](/home/homebox/Documents/rookmate/undertow/tests/integration/test_enemy_contact.gd:183) also meaningfully distinguishes a stopped-short miss from a reachable hit. The existing close-contact and returning-player tests still pass.

All sixteen original findings were rechecked:

| Original finding | Round 3 result |
|---|---|
| 1. Enemy-initiated contact | Fixed. Walking contact works both ways; rolling excludes contact on both moving bodies. |
| 2. Sterilizer pursuit and cover | Fixed. Deployment stays committed and advertised; release and cloud damage check cover. |
| 3. Warden cover and strike geometry | Fixed. Sight, committed direction, arc and advertised reach govern impact. |
| 4. Salvager reach and cover | Fixed. Warning and snatch share `catch_reach()`; cover prevents theft. |
| 5. Undersized footprints | Fixed for regular enemies. Operator and boss capsules remain as explicitly scoped. |
| 6. Custodian lunge | Fixed, including the round 2 blocked-lunge case. Close contact and late interception remain covered. |
| 7. Clerk rear artwork | Fixed through the accepted static rear painting, with its Feed glow preserved. |
| 8. Painted strikes and projectile origins | Addressed by the Warden's shorter reach and step-in, and the Clerk's pure release transform, validated origin and corrected aim. |
| 9. Hover appendage direction | Fixed. Extension follows screen-space aim and handles mirroring. |
| 10. Hook acquisition during roll invulnerability | Fixed. Acquisition respects roll evasion without treating ordinary hurt grace as an evasion. |
| 11. Multiple pull ownership | Fixed under the explicit latest-pull policy. Only the owning lamp releases that pull. |
| 12. Hostile Lamplighter facing | Fixed for travel and active beam tracking. |
| 13. Retreat/flee obstruction | The corner and bent-corridor cases are fixed. The ten-step search remains a deliberate bound; no further encounter defect confirmed. |
| 14. Salvager contrast | The 64-pixel size and 1.45 brightness treatment are implemented. I did not repeat the district-lighting probe. |
| 15. Ground draw order | Fixed through `GroundMarks` in `fx_ground`, with following, fading and cleanup. |
| 16. Death redraw | Fixed. Final redraw suppresses state-dependent warnings; Lamplighter death releases its beam. |

The scoped decisions hold up. Bosses and weak points opt out of regular-enemy contact and footprint changes. Keeping the Operator capsule is consistent with that scope. The reduced `0.35` cock and Clerk rear fallback are accepted presentation choices.

I found no gold/serif ownership violation or weakened existing check. The [attack-pose test rewrite](/home/homebox/Documents/rookmate/undertow/tests/integration/test_actor_animation.gd:44) checks the accepted cock limit, mid-windup pose and release deadline.

I independently ran **34 focused tests, all passing**: 21 enemy, six actor-animation, six colour-rule and one font-rule tests. Sandbox restrictions denied log/save writes during these runs. The current gate logs show clean import, **578 tests passing**, and the 30-second smoke run passing. The campaign had no completed result when checked; older ending/tour logs do not establish completion for this run. Play feel remains unverified.

No low-value nits. No files were edited.

## Closed

**Review closed after 3 rounds.** No finding remains, and the gate passes on this tree (import, 578
tests, the 30 s run, the campaign, three endings, the revisit, the tool door and the district tours).

Still to settle by playing: how the machines feel to fight now that they stop against you, step into
their swings and commit to them (the Warden is harder to stand next to and easier to dodge), whether the
0.35 cock reads as a telegraph, and whether the Salvager is readable in the Tideworks' and Greywater's
own light. The Clerk needs a real rear torso in its rig; until then it's seen from behind in its
original painting.
