# 2026-10-06 Commerce / Live Photo incident

## Decision before implementation

- Engineering Loop, P1: user reports no lifetime purchase surface and Live Photo export failure JOB-E783BF88C353; ten-photo failure is a separate batch scenario.
- Verified commerce cause: loader requests only subscriptions, purchase action resolves only selected subscription. Approved non-consumable 6793883583 is available in all countries; ASC current schedule has AUTO_FREE. Existing restore precedence remains lifetime > subscription > sandbox > free.
- Owner amendment: user explicitly requests lifetime purchase below subscriptions, superseding restore-only presentation in Commerce v1.1/build104. Reuse the existing lifetime SKU and Apple Product.purchase/currentEntitlements; no locally minted entitlement, no new durable schema or product.
- UI pass: separate lifetime card below subscription action; localized StoreKit price, free claim wording only for price == 0, one-time/non-renewing disclosure. Show to subscribers who do not own lifetime, with warning that existing subscription must be managed with Apple. Product unavailable remains retryable. Shared purchase operation prevents overlapping actions.
- Tests: product-loading set, missing lifetime retry, overlapping actions, lifetime/subscription precedence; macOS host tests and signed physical iOS build. No simulator.
- Live Photo: collect existing diagnostic/queue evidence before installing over device; preserve originals/pair identity/keyframe/color, no guessed fallback. devicectl cannot access root-level ProductionDiagnostics due to Apple container restrictions. Await existing app diagnostic export, inspect available tmp files and pipeline.
- Store assets Product Loop/P2: current first slide has four tiny output/UI previews; prioritize one real output, one short claim per slide, baby photo/age story. Prepare local reviewable assets before public replacement; verify Release availability.
- No commit/push/submission or public campaign change implicit in local code repair.

## Live Photo evidence and bounded repair decision

Supplied export: 2.3.5 (122), iOS 27.2 (24B5089g). JOB-E783BF88C353 fails with Swift NSError domain LivePhotoVideoCompositionError/code8. Local enum bridge independently confirms code8 = nativeBackdropColorUnsupported (exportFailed is code6). Batch E25B1710 has 12 distinct tasks and two failed attempts each, same code8, ~0.8–1.4 sec. Queue processes all pending tasks serially. No evidence supports disk exhaustion or first-item abort. Preset display title does not define presentation style.

Native compositor deliberately admits SDR/8bit/narrow gamut only, uses sRGB RGBA8. Do not remove color guard or silently convert source to sRGB. For unsupported source motion color, select the already accepted darkLayerV1 renderer recipe before pair composition, pass the SAME artifact to still and motion. Presentation planner owns recipe/geometry; generic media capability owns admission. No style branches in media, no durable schema migration, no static-only success. Record fallback in diagnostics. HDR/P3 output readback remains a physical gate; fallback must not be described as HDR certification.

## Verification and commercial transition

Full macOS host xcresult: 1984 passed, 0 failed, 1 existing skipped; 2027 parameterized executions. Two existing export readback QoS warnings remain. Focused commerce 53 executions and media 45 executions passed. The overlapping-loader regression was subsequently made deterministic with an explicitly suspended continuation; focused rerun is recorded separately. No simulator used.

Signed physical iPhone 17 Pro Max build, installation and launch succeeded. This is a local 2.3.5 (122) debug repair package, not an updated App Store binary. Original failing single task / original batch retry, Photos paired-output readback and lifetime visual/purchase/restore acceptance are pending owner device results. No HDR/P3 certification claim.

Owner accepted: repaired public release first; retain lifetime free for two further days; restore mainland CNY 68 afterward; withdraw temporary annual first-year-free at repaired-release availability. No guessed calendar date or public backend mutation. Detailed commerce amendment is in the contract folder.

Store visual draft is outside repository at /Users/rui/Desktop/MemoMark_AppStore_第五版草稿_2026-10-06. Three reviewed compositions use real existing screenshot crops. Final first slide still needs an authorized baby photo and actual saved output, and example avatar/content selection. No screenshot upload or test creation.

Focused deterministic purchase-serialization rerun: all three CommerceStore tests passed after replacing scheduler-dependent Task.yield with a suspended continuation. Full xcresult remains 1984 unique passed / 2027 executions, not the 2026 counted by text-log parsing.

Signed physical-target Release build also passed (xcodebuild exit 0); package remains 2.3.5 (122), signature verification passed. Release artifact /tmp/MemoMarkIncidentReleaseDerived/Build/Products/Release-iphoneos/MemoMarkiOS.app. No upload/submission.


2026-10-06 owner acceptance: original fault checks have no issue; close the observed incident and revisit only if new evidence appears. Owner directs formal2.3.6 (124), baseline public2.3.5, Xcode build followed by all-language release. Scope accepted; broader media/performance certification is not inferred.
