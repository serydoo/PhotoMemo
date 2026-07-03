# 02 Architecture

Architecture overview, RFCs, ADRs, workflow boundaries, and engine ownership documents belong here.

The V2 target architecture is:

```text
Photo -> Metadata Engine -> Memory Engine -> Presentation Engine -> Layout Engine -> Renderer -> Export
```

Memory Engine calculates Life Position from objective photo facts and emotional Life Anchors.

Presentation Engine expresses those relationships.

Layout Engine decides how the resolved meaning is presented.

Renderer draws.

Current active architecture artifacts:

- `PhotoMemo_V1_Engineering_Baseline.md`
- `RFC-001-Memory-Enters-the-Production-Pipeline.md`
- `RFC-001-Implementation-Plan.md`
- `V1_Preview_Renderer_Export_Contract_Review_2026-07-03.md`
- `V1_Render_Contract_Freeze_2026-07-03.md`
