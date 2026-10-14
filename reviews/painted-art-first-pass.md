# Painted art first pass

Reviewed by the read-only `sol_analyst` agent on 2026-10-13. No art integration bugs or acceptance
blockers found.

## Scope and confirmed checks

Five opaque painted materials are selected only for Kestrel Heights. One transparent two-pose
Operator sheet renders in every district. Original PNGs, mipmap import recipes and generation
prompts are in `assets/art/`. Floors retain the 128 by 72 projection, shared UV edges, chunking and
ground depth. Buildings retain exposed-face selection and the separate base, glow and gilt layers.
The Operator's source regions preserve aspect ratio, visible height and boots at the origin; the
earpiece still responds to the voice toggle. Full directional animation and other placeholder art
remain unfinished.

- Normal and empty-cache imports contain no errors or warnings.
- All 509 existing tests pass.
- Smoke gameplay, all eight district tours, all three endings, the revisit and tool-door scenarios pass.
- Windowed Kestrel and Vellum tours pass. Kestrel screenshots were inspected while listening and muted.
- Movie Maker recordings cover Kestrel's tour and Operator gameplay.

Logs, screenshots and videos are in `reports/art-first-pass/`, ignored by git.

## Full gate limitations

The full gate is **FAIL**, because the campaign stalls in Harbor Ward. It was run with an external
wrapper that adds `--fixed-fps 60` and strips `--autopilot-shots` for headless calls. The unmodified
headless gate requests screenshots, and `Autopilot.snap()` awaits `RenderingServer.frame_post_draw`,
which never arrives headless. Sol reproduced that screenshot stall on unchanged HEAD; the same
baseline tour without screenshot requests passes. Windowed recordings provide the visual evidence.

With screenshot requests omitted, the campaign gets past the Warden-Prime and stalls while walking
to Noor:

```text
harbor:warden_prime_beaten
harbor:barriers_opened
advance_to (43, 24) timed out at (43, 17)
```

Sol reproduced the exact failure on unchanged HEAD, exported to a separate directory, with fresh
isolated user data and the same headless fixed-fps campaign invocation. Both runs exit 1 with the
same missing Harbor and Spire checks. The baseline log is copied to
`reports/art-first-pass/baseline-campaign.log`. This failure predates the art changes.

The likely obstruction is a navigation and physics mismatch: the relay mast's `Z` cell is walkable
to navigation, but `WeakPoint.retire()` leaves its collision active when the boss dies. The stalled
cell borders that mast and a solid lamp. The exact collider was not instrumented, so this explanation
is an inference. Maps, navigation, collision and the screenshot helper were not changed in this pass.
