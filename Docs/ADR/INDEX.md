# ADR Index

| ADR | Title | Status | Date | Summary |
|---|---|---|---|---|
| ADR-001 | Single Source of Truth for Batch Configuration | Accepted | 2026-06-20 | Batch configuration snapshots are constructed through one provider to avoid configuration drift. |
| ADR-002 | BatchQueueStore as a Stable Public Facade | Accepted | 2026-06-20 | Batch queue internals may be decomposed, but the public queue entry point remains stable. |
| ADR-003 | Incremental Workspace Session Migration | Accepted | 2026-06-20 | MainView workflow migration proceeds incrementally through workspace session types instead of a rewrite. |
| ADR-004 | Template String as the Canonical Model | Accepted | 2026-06-20 | Template strings remain the canonical content model across editor, renderer, export, batch, and persistence. |
| ADR-005 | Editor Projection Engine | Accepted | 2026-06-20 | Editor-only projection logic is isolated from MainView while remaining outside renderer, export, and batch boundaries. |
| ADR-006 | Memory Engine Foundation | Accepted | 2026-06-20 | Memory-oriented variables are derived through a dedicated local-first domain layer between metadata inputs and the variable pipeline. |
| ADR-007 | Provider-Based Expression Architecture | Accepted | 2026-07-06 | Canonical Providers compile domain facts into provider-neutral Expression Values before values enter ExpressionContext and Renderer. |
| ADR-008 | Media Geometry Foundation | Accepted | 2026-07-08 | Geometry is resolved once into immutable CanonicalGeometry and consumed read-only by Renderer, Composer, and Exporter. |
| ADR-009 | Configuration Aggregate And Local Backup Library | Accepted | 2026-07-11 | MemorySubject owns complete versioned configurations; one aggregate is durable truth and local documents are explicit backups. |

Future ADRs should be appended to this table.
