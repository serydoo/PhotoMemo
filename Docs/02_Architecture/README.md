# 02 Architecture

Architecture overview, ADRs, workflow boundaries, and engine ownership documents belong here.

The V2 target architecture is:

```text
Photo -> Metadata Engine -> Memory Engine -> Presentation Engine -> Layout Engine -> Renderer -> Export
```

Memory Engine calculates Life Position from objective photo facts and emotional Life Anchors.

Presentation Engine expresses those relationships.

Layout Engine decides how the resolved meaning is presented.

Renderer draws.
