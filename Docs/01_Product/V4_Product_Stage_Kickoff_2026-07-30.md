# MemoMark V4 Product Stage Kickoff

Date: 2026-07-30

Status: Accepted

Product stage: `V4 Expression Style System`

Active subphase: `V4.0 Research And Product Definition`

## Objective

Formally conclude V3 as the product-quality and delivery phase and start V4 as
the research-first definition of MemoMark's Expression Style System and the
final sustained refinement stage for the existing product.

V4 extends the established local-first Memory Presentation Engine. It does not
replace the Configuration Center, Memory Engine, Presentation Engine, Layout
Engine, Renderer, durable configuration aggregate, or Apple Photos lifecycle.
It continues bounded work on the main interface, existing features, interaction
logic, accessibility, and device fit without a large-scale core-flow rewrite.

## Stage Decision

MemoMark V1, V2, and V3 are concluded product stages. V4 begins on 2026-07-30
from verified repository baseline `864d6cdf`.

V3 is recorded as:

```text
Concluded With Certification Carryover
```

This wording is deliberate. V3 delivered the durable configuration, real
Apple Photos workflow, product-quality regression coverage, signed-device
installation evidence, and MemoMark `2.0.1 (48)` release candidate. The latest
complete automated evidence at the transition baseline is `1,214` passed,
`1` existing skip, and `0` failed tests, plus successful unsigned macOS and
generic iOS Debug builds.

The 2026-07-20 V3 Production Reliability Certification remains historically
accurate as `FAIL (Conditional)`. No later record formally supersedes its two
P0 findings:

1. `TX-001` Export Commit Protocol and crash-recovery reconciliation.
2. `BP-001` enforced single-task memory contract and 48MP/RAW peak-memory
   evidence.

The stage transition does not convert those findings into a pass or silently
waive them. They become the V4 Entry Engineering Gate and retain P0 priority.

## Primary Loop

This kickoff is a `Product Loop` decision. It begins from the accepted product
direction that users choose how a memory is expressed, not renderer metrics or
an expanding catalog of unrelated templates.

V4 then proceeds through two separate loops:

```text
Product Loop
-> User Expression Scenarios
-> Style Dimension Taxonomy
-> Synthetic Visual Studies
-> Measurable Style Specifications
-> Product Design Review

Product Loop, as observed
-> Bounded existing-product and device-fit refinement

Engineering Loop
-> TX-001 Export Commit Protocol
-> BP-001 Enforced Single-Task Memory Contract
-> Superseding Production Reliability Certification
```

An item must belong to one primary loop. Product research and bounded
existing-product refinement may proceed while the Engineering Loop closes the
entry gate, but Expression Style production implementation or a broader
production-capability claim may not begin until both loops reach their approval
gate.

## Evidence And Observed State

- `Docs/CURRENT_STATUS.md` records the July 27-30 persistence, recovery,
  background-lifecycle, UI, localization, output, test, build, and signed-device
  results.
- `Docs/07_Releases/2026-07-29-2.0.1-v3-production-quality-update.md` records the
  final V3 release candidate and its remaining manual verification boundaries.
- `Docs/07_Releases/MemoMark_V3_Production_Reliability_Certification_2026-07-20.md`
  remains the authority for the open P0 certification findings.
- `Research/ExpressionStyles/README.md` provides the V4 research seed. It is a
  starting thesis, not a frozen product or architecture specification.

## Ownership And Dependency Boundaries

The accepted dependency direction remains:

```text
Photo
-> Metadata Engine
-> Memory Engine
-> Presentation Engine
-> Layout Engine
-> Renderer
-> Export
```

V4 adds no alternate path around this pipeline. In particular:

- `Preset` remains the user-owned saved configuration concept.
- Memory Behavior owns semantic priorities.
- Expression Style may define presentation grammar only after PDR approval.
- Layout Engine remains the sole future owner of measurable layout decisions.
- Renderer remains stateless and draws resolved output.
- Apple Photos continues to own original assets and the photo library.
- MemoMark continues to generate a new output without modifying the original.

## Apple-Native Evaluation

This kickoff changes documentation and product-stage governance only. It adds
no Apple framework, permission, entitlement, background mode, network service,
PhotoKit behavior, StoreKit behavior, or App Store submission claim.

Future V4 specifications must evaluate Apple-native visual comparison,
accessibility, localization, Dynamic Type, Share Extension lifecycle, PhotoKit
save/recovery, Live Photo, and high-cost media behavior at the boundary where
each becomes relevant.

## Risk And Failure Modes

Risk: `P0`, because an inaccurate stage declaration could falsely certify
duplicate-save recovery, peak-memory safety, or permission to change frozen
render/export behavior.

The bounded controls are:

- preserve the V3 conditional certification verdict;
- carry `TX-001` and `BP-001` forward by name and priority;
- keep Expression Style production implementation and broader production
  claims unauthorized until the entry gates pass;
- allow only bounded existing-product refinement that preserves frozen
  ownership and carries scenario-specific verification;
- keep historical V1-V3 documents historically accurate;
- update only current-facing source-of-truth statements.

## Repository Structure

- `Docs/01_Product/` owns this product-stage kickoff record.
- `Docs/PRODUCT_VERSION_HISTORY.md` owns canonical stage boundaries.
- `Docs/MASTER_PLAN.md` owns active sequencing.
- `Research/ExpressionStyles/` owns V4 research until an accepted PDR and
  measurable specifications establish later owners.
- `Docs/CURRENT_STATUS.md` records the transition as a repository milestone.

## Commands And Verification

```bash
git diff --check
rg -n "V4 Expression Style System" \
  PROJECT_CONSTITUTION.md Docs/MASTER_PLAN.md Docs/PRODUCT_VERSION_HISTORY.md \
  Research/README.md README.md AI_CONTEXT.md HANDOFF.md AGENTS.md
! rg -n 'MemoMark is in `V3|remains in V3|active V3 product|Current Stage: V3' \
  PROJECT_CONSTITUTION.md Docs/MASTER_PLAN.md Docs/PRODUCT_VERSION_HISTORY.md \
  Research/README.md README.md AI_CONTEXT.md AGENTS.md
```

No application build is required for this documentation-only kickoff. The
last verified V3 build and test evidence must remain cited rather than rerun
and presented as V4 implementation evidence.

## Boundaries

Always:

- preserve local-first processing, original-photo integrity, memory truth, and
  frozen IA-002/IA-003 ownership;
- research before specification and specify before Renderer changes;
- keep Preview and final export tied to the same real Memory Card pipeline.

Review before:

- freezing Expression Style vocabulary or the product model;
- changing persistence or migration behavior;
- changing Layout Engine, Renderer, Export, Share Extension, or PhotoKit;
- authorizing the first Expression Style production implementation slice or
  expanding the supported production claim.

Never:

- report V3 Production Certification as passed without superseding evidence;
- use the V4 label to bypass `TX-001`, `BP-001`, or a Product Design Review;
- turn Expression Styles into a template marketplace or a parallel editor;
- migrate historical documents merely to replace V3 labels with V4.

## Success Criteria

V4 is formally started when:

1. the constitution, master plan, product-stage history, current status, README,
   AI/agent entry files, research index, and handoff agree that V4 is active;
2. V3 is recorded as concluded with certification carryover, not as fully
   certified;
3. `TX-001` and `BP-001` remain explicit P0 entry gates;
4. the Expression Style foundation is active research but still authorizes no
   production implementation;
5. historical V3 release and certification records remain unchanged;
6. repository consistency and whitespace checks pass.

## First V4 Work

Product Loop:

```text
ES-001 User Expression Scenarios
```

Engineering Loop:

```text
TX-001 Export Commit Protocol Specification And Failure Tests
```

These are separate work items. Neither authorizes new Renderer behavior.
Bounded refinement of existing product surfaces may continue as separately
scoped Product Loop work when it starts from observed behavior and preserves
the frozen architecture.

## Post-V4 Maintenance Boundary

V4 is the final sustained refinement stage. After its accepted Product Loop and
Engineering Loop scope is complete, MemoMark stops routine version updates.
Future releases require a material issue affecting normal use, an Apple-platform
or compatibility change, or a major reliability/privacy need. This maintenance
boundary never converts an open P0 finding into acceptance.

## Open Questions

The V4 Product Design Review must resolve the distinction between Preset,
Memory Behavior, Expression Style, Style Variant, and Content Composition. It
must also define switching, migration, capability declaration, preview/export
parity, and the first measurable Classic-versus-Minimal proof before code.
