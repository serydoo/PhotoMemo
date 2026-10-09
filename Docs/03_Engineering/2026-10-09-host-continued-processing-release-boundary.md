# Host Continued Processing release boundary

## Scope and owner

MemoMark's core processing intent, frozen configuration, original protection, media executor, receipt/readback and accounting remain shared. Share receives durable files. The containing-app adapter owns app-origin BGContinuedProcessingTask, system progress and expiration; BackgroundBatchQueueWorker owns preparation and invokes the existing queue under an exact system execution lease. The Beta-only extension experiment is a separate development probe. The re-audit below establishes that Share-origin continued work is granted to the extension on the tested OS, not this containing-app adapter; its original Share-handoff candidacy is superseded by that evidence.

## Platform evidence

The installed formal Xcode 27.0 SDK `BGTaskScheduler.h` registration documentation states that extensions may submit some requests, but only the host app launches to handle background work. `BGTaskRequest.h` explicitly mentions creation from apps/extensions and foreground association. These are different boundaries; task construction does not prove acceptance, callback ownership or completed processing. Public Apple registration documentation separately requires registration once and describes host background launch: https://developer.apple.com/documentation/backgroundtasks/bgtaskscheduler/register(fortaskwithidentifier:using:launchhandler:).

The iOS 27.2 Beta extension-owned callback/output rounds are real evidence for that device only. The previous host-handoff marker did not receive a host callback. Production readiness therefore cannot be inferred from the successful Beta extension route.

## Implemented host adapter candidate

- A stable host task identifier, permitted wildcard prefix and registration once on iOS 26+.
- Existing BackgroundBatchQueueWorker supports bgProcessing and continuedProcessing owners, without a second renderer or receipt implementation. The worker is now unit-testable on macOS; no new macOS system scheduling path is invoked.
- Actual ExecutionSession progress drives the native title/subtitle/Progress. A presentation heartbeat suppresses ActivityKit fallback while the native callback owns presentation.
- Expiration cancels the exact run; processing quiesces before its lease releases. A stale run cannot cancel a successor.
- Native success requires a nonempty session with every task completed. Held, failed, cancelled or missing work cannot masquerade as success simply because the scheduler has no runnable work.
- The host handler is compiled/registered, but Share submission to this new host identifier is not enabled yet. No claim that it already solves Photos-only host launch. That exact signed-device handoff test has now failed; the ownership re-audit below supersedes this route for Share-origin processing.

## Additional reliability findings

A resubmitted held intent previously reserved allowance again. Admission must compare the canonical successfulSaveAccountingID (processing intent, legacy task UUID fallback), reserve unique unfinished intents, and recognize completed saved intents. Different semantics remain distinct and capacity check stays within the cross-process ledger transaction. Batch size is checked before expensive identity compilation; identity-dependent allowance is checked afterward. Neither receipts nor successful-save accounting identifiers change.

## Original host-handoff gates (superseded by the ownership re-audit below)

1. Formal host handler registration accepted, Share submission accepted by daemon, host callback invoked while the UI stays in Photos/Home.
2. Frozen configurations and requested source IDs agree, save/readback succeeds, originals unchanged; still and Live Photo routes separately checked.
3. Multiple shares append/drain without duplicate native tasks, false completion or abandoned intake.
4. Cancel/expiration/process kill, resending a partial result, permissions changes and legacy schema recover without duplicate saves or automatic resurrection.
5. Stable iOS 26 and old-system BGProcessing/foreground recovery evidence; no immediate completion guarantee for 18–25. Unsupported surfaces/devices remain explicit unverified coverage.

The host adapter is a candidate, not production acceptance. Do not remove the fallback or promote the extension probe based on compilation alone.

## Re-audit of the original research and dispatch diagnosis

The referenced research initially inferred that extension request construction plus generic host registration documentation established a Photos Share → containing-app launch route. Its later answer correctly made that route conditional on a signed-device spike. Preserve that condition: foreground association, scheduler acceptance, process dispatch, and actual output are separate gates. Neither the original diagram nor a native activity establishes that the containing app obtained execution time.

Apple's initializer explicitly associates the request with the currently foregrounded app and mentions extensions. This does not specify the containing-app handoff observed in Photos. Source: https://developer.apple.com/documentation/backgroundtasks/bgcontinuedprocessingtaskrequest/init(identifier:title:subtitle:).

Apple DTS describes submission and dispatch as separate stages, warns that task identifiers must be unique per task, and advises against making already-runnable foreground work wait for a scheduler callback. Source: https://developer.apple.com/forums/thread/807370. Its described system failure is a relevant hypothesis, not proof that MemoMark has the same cause. The fixed candidate identifier must therefore be tested against a fresh concrete identifier before blaming extension lifetime, resource pressure, or OS dispatch.

Two DEBUG-only foreground controls now exercise the production host adapter, using its fixed identifier and a freshly registered UUID identifier under the permitted prefix respectively. They use the iOS 27 asynchronous submission API off the main actor. These controls do not enable production Share submission. Device UI test completion alone is insufficient: independently read the matching registration/submission/callback/finish events without relaunching the app. A callback after foreground activation cannot certify Photos-only execution.

The coordinator is retained by MemoMarkAppRuntime; its weak handler capture is not by itself evidence of premature deallocation. The corrected frozen-configuration QA fixture is also rerun separately so the earlier deleted-output receipt mismatch cannot contaminate pipeline diagnosis. No receipt is erased to force a successful retest.

### Signed-device control results, 2026-10-09

- Corrected Photos-only fixture: submission accepted, three durable inputs, Share dismissed; no host callback and zero outputs in four minutes. `MemoMarkRootHandoffCorrectedFixture.xcresult` fails its independent-output gate as intended. This is not the earlier QA production-reference mismatch.
- Same host adapter, app-origin foreground submission: both the fixed ID and a fresh UUID ID invoke `host.continuedQueueCallback`. `MemoMarkRootFormalControls.xcresult` has two passed stimulus tests; the independent App Group evidence proves actual callbacks. Work completion is deliberately not inferred from these controls. Two runtime QoS warnings remain.
- The first unique-ID Share round stopped before sharing: three outputs from foreground recovery violated the required empty-album baseline. It proves neither success nor failure of unique-ID Share dispatch. Clean only those QA outputs and rerun before drawing that conclusion.

These controls narrow the observed failure to the Share-origin dispatch boundary. They disprove an unregistered host handler and a universally broken scheduler/host adapter on this device. They do not yet prove whether foreground association, cross-process task ownership, or a Beta scheduler implementation accounts for the boundary failure.

## Observed ownership root cause on iOS 27.2 Beta

The device unified log resolves the prior ambiguity. At 15:49:20.861 the scheduler identifies client PID 2634 as MemoMarkShareExtension and host PID 1857 as Photos (`com.apple.mobileslideshow`). The native activity is associated with the Photos bundle. At 15:49:20.863 it acquires the Continued Processing assertion for PID 2634 and a host jetsam assertion for PID 1857. It does not grant that task to MemoMarkiOS. These lines are saved in `root-scheduler-ownership-evidence.log`; the full raw device archive stays local under /tmp.

Thus the erroneous assumption is that an extension's currently foregrounded host is necessarily its containing app. During a Photos Share it is Photos. A MemoMark-prefixed task identifier and registration in MemoMarkiOS do not redirect the extension-origin execution grant to that process. The observed successful extension-owned rounds and failed host-only rounds are consistent with this concrete ownership evidence. This establishes the route mismatch on the tested Beta; it does not establish behavior on every stable iOS version or classify the implementation as an Apple bug.

Correction: a Share-origin Continued Processing adapter must register/handle where the scheduler actually grants execution, and invoke the existing shared durable queue/media/save pipeline there. The extension remains thin for intake, but its explicitly granted system task may own a bounded executor; it must not rely on ordinary extension lifetime after dismissal. The containing app retains foreground recovery and BGProcessing recovery. An app-origin Continued Processing adapter can continue to own app-origin work. Arbiter/lease and presentation authority remain shared across both processes. No private wake mechanism, foreground hijack or fake progress is introduced.

The extension route is still a DEBUG experiment. Before Release activation, certify stable iOS 26/27 task lifetime, resource limits, cancellation, process kill, multi-share and canonical frozen configuration/receipts. The generic registration header must not be used to override the observed task-specific ownership. Production acceptance remains open; these findings correct the execution route rather than weaken its acceptance gates.

The fresh UUID Photos-only round also fails its four-minute independent-output gate (`MemoMarkRootUniqueShareHandoffClean.xcresult`), with accepted submission and no MemoMarkiOS callback. Fixed-ID reuse is therefore not the cause of this route mismatch. Cancelling/deleting the resulting current session and verifying it stays deleted after relaunch passes; scoped output cleanup also passes, with all 15 original inputs preserved.

## Preparation and cancellation boundaries

A system lease suppresses enqueue auto-start: preparation durably admits intake, then the worker validates permission and cancellation before explicitly starting processing. If preparation starts work and is interrupted, the worker stops it before releasing ownership. Continued Processing interruption holds only its execution session, without a global paused switch; fresh Share can form a new executable session. Native cancellation does not schedule recovery that quietly resurrects cancelled work. BGProcessing retains its previous recovery semantics.

The cancellation/preparation regression suite passed 45 logical tests. Final macOS full suite: 2084 passed, 1 skipped, zero failures; two existing fixture QoS warnings remain. Formal Release archive succeeds with development signatures, build 124; no distribution or physical acceptance is implied.

## Canonical configuration root cause and bounded correction

The real saved-configuration 15-source test failed at production GlassCard health validation for both a long supplement and a seven-character supplement. `MemoryWriteTextComposer` inserts an explicit newline between automatic memory and the custom supplement, while production fit measurement and drawing enforced one line. This is a shared rendering contract failure, not evidence of background scheduler or memory failure. A metadata-only override had hidden this real-config boundary.

Production resolution and drawing now share the resolved line limit: explicit secondary text supports two lines, within existing rail bottom padding and bounded font scaling. Single-line slots and research resolution defaults remain unchanged; three authored lines retain overflow rejection. The actual production regression failed before the fix and passes after it. Full macOS suite: 2,087 passed, 1 skipped, no failures (two existing fixture QoS warnings).

`MemoMarkRootCanonicalGlassFixed.xcresult` passes the signed 15-source Photos-only gate on iOS 27.2 Beta: every output saved, creation dates and authored description verified, Live Photo MOV pairing verified, original inputs preserved, outputs cleaned to zero. Main app activation occurs only in configuration setup/restoration, outside the independent execution interval. The refreshed formal-Xcode Release archive and strict deep signature verification pass with development signatures. Neither archive nor this Beta test activates or certifies Release Share scheduling.

## Post-fix signed-device reliability gates

`MemoMarkRootGlassReliability.xcresult`: three passed, zero failed, no runtime warnings. Back-to-back overlapping Share selects 12 items but saves seven unique intents under one continuous session. Repeated identical frozen semantics preserve saved identifiers; a changed frozen description permits three additional outputs. Native cancellation after real partial output stops further saves independently; resending all 15 completes exactly 15 while preserving prior successful identifiers. Metadata and Live Photo pairing checks pass, all 15 original inputs remain, and each round clears only QA outputs to zero. These follow-up identity fixtures use the explicit metadata override; canonical authored-text coverage is supplied separately by the real-config 15-source gate.

Only the iOS 27.2 Beta physical device is currently connected. Stable-system and older-system physical acceptance remain unavailable; simulator, archive and Beta results cannot close those gates. Release Share Continued Processing is still disabled pending that certification and separation of the experimental adapter from its debug instrumentation.
