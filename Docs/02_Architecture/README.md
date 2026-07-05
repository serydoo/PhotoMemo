# 02 Architecture

Architecture overview, RFCs, ADRs, workflow boundaries, and engine ownership documents belong here.

Canonical architecture artifacts in the current repository line:

- `PhotoMemo_V1_Engineering_Baseline.md`
- `RFC-001-Memory-Enters-the-Production-Pipeline.md`
- `RFC-001-Implementation-Plan.md`
- `V1_Render_Contract_Freeze_2026-07-03.md`

The V2 target architecture is:

```text
Photo -> Metadata Engine -> Memory Engine -> Presentation Engine -> Layout Engine -> Renderer -> Export
```

Memory Engine calculates Life Position from objective photo facts and emotional Life Anchors.

Presentation Engine expresses those relationships.

Layout Engine decides how the resolved meaning is presented.

Renderer draws.

Current active architecture artifacts:

## ADR

Architecture Decision Records explain why a design direction was chosen.

- `ADR/`

## Proposal

Architecture Proposal documents define candidate directions before they become
ADRs or Freeze documents.

- `Proposal/`

## Freeze

Architecture Freeze documents define decisions that should not be reopened
without an explicit review.

- `PhotoMemo_V1_Engineering_Baseline.md`
- `RFC-001-Memory-Enters-the-Production-Pipeline.md`
- `RFC-001-Implementation-Plan.md`
- `V1_Render_Contract_Freeze_2026-07-03.md`

## Contract

Architecture Contract documents define rules that production code must obey.

- `Contract/Expression_System_Contract.md`
- `V1_Configuration_State_Boundary.md`

## Inventory

Boundary Inventory and review documents map current system seams, drift, and
follow-up risks.

- `PI-2_Renderer_Dependency_Isolation_Boundary_Scan.md`
- `V1_Preview_Renderer_Export_Contract_Review_2026-07-03.md`
