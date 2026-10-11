# Four-card Share physical acceptance — 2026-10-11

Primary loop: Engineering Loop. Risk: P1, production Share lifecycle and visible saved-content correctness.

Observed evidence: Classic White direct CPU layer rasterization completed 15 pinned inputs without foreground return. This does not certify Minimal, FilmMark or GlassCard. Earlier black footer false positives show that decode and dark pixels alone do not prove meaningful Renderer output.

Scope: signed Release physical QA harness, existing saved configuration style selection, notification-center baseline, actual saved PhotoKit resources, and acceptance evidence. Production ownership remains Memory → Presentation → Layout → Renderer → Export. No new layout decisions, media-format change, upload, or original modification.

Plan: use the same 15 assets in pinned MemoMark QA Inputs. Before each style round, clear only MemoMark notification history through partial left swipe and its visible Clear/Delete control; capture the resulting baseline. Require QA Outputs empty. Select and save each existing card style through UI. Share all inputs, close Share, observe native progress with host remaining background through output readback. Export each saved full composition for visual inspection; Classic White additionally retains the strict light-footer/content check. For floating/dark styles, manual per-image text/logo/photo integration acceptance is required rather than a white-footer heuristic. Verify metadata, original identity, and Live Photo pairing separately. Restore original style and caption after each round. Archive evidence before deleting only QA Outputs and confirm Inputs remain unchanged.

Apple capabilities: native segmented Picker, system notification controls, BGContinuedProcessing progress, PhotoKit resource readback. No simulator or cloud services.

Completion requires four separate round records, all saved images inspected, explicit remaining failures, restored user configuration, and zero QA Outputs between rounds. Ordinary Share RAW inputs may arrive as JPEG representations; this gate does not certify full original RAW ingestion.

## Initial round evidence

Classic White attempt `/tmp/MemoMarkFourCardClassic20261011.xcresult`: 15 actual outputs; per-image footer and full-composition inspection found all configured text/logo visible. Request `5F1F3BDD-B116-4EF5-883A-645477023F9D` finished with all 15 phases completed, processed=true, cancelled=false. A pre-Share foreground-state assertion raced Photos activation, so the XCTest result is Failed and this attempt is not the final all-gates pass. System screenshot `/tmp/MemoMarkFourCardClassicProcessing.png` shows 60%, 9/15 while on SpringBoard. Cleanup `/tmp/MemoMarkFourCardCleanupClassic20261011.xcresult` Passed; outputs cleared and source identities preserved.

Minimal initial attempt did not submit Share. Notification-center navigation became unstable, and description restoration initially failed; a subsequent dedicated restore `/tmp/MemoMarkFourCardRestore20261011.xcresult` Passed and returned the known pre-QA empty/off description. No Minimal output or Renderer claim is established by that attempt. Added explicit waiting for application activation, notification history expansion, and a cover-sheet presence gate to reject a dismissed notification center rather than treating missing cells as a clean baseline.

A real phone call interrupted a standalone baseline check. Device interaction stopped until the user explicitly confirmed that the call ended. This is a test interruption, not a production media failure.

## User-requested pause

User explicitly paused physical work on 2026-10-11. No further configuration switching, Share, notification dismissal or output cleanup is authorized while paused. The active Xcode test command was checked and is no longer running. The second Minimal attempt has not been accepted; inspect its result and current device configuration on resume before any new round. Dedicated empty/off description restoration previously Passed. Notification baseline attempt 3 returned Passed, but its screenshot did not match its cover-sheet AX hierarchy, so it is not sufficient clean-baseline visual evidence; the actual screenshot and UI surface must agree before the next Share. FilmMark and GlassCard have not been tested in this four-card matrix. Classic's complete output evidence exists, but its all-gates test needs a fresh pass. Keep all existing private device evidence in `/tmp/MemoMarkShareRestore20261011/`, not in Git.

Second Minimal attempt `/tmp/MemoMarkFourCardMinimal2_20261011.xcresult` stopped at its nonempty-output precondition (`CocoaError.fileWriteFileExists`), before launching or switching the host. This is deliberately not a media-processing failure. QA Outputs were no longer empty at that moment; do not assume they are owned by the preceding matrix attempt. Resume must inventory and identify those assets before scoped cleanup. No deletion was performed after this observation.
