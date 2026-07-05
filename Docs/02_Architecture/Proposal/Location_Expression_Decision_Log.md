# Location Expression Decision Log

Status: Working Log
Scope: Location Expression implementation decisions
Branch: codex/地址模块
Date: 2026-07-05

This log captures small architecture decisions proven during phased
implementation. It is not an ADR. When Phase 3 or Phase 4 provides enough
engineering evidence, these entries can be consolidated into a formal ADR for
Provider-Based Expression Architecture.

## Decision Format

Each entry records only:

- phase
- decision
- boundary protected

## Decisions

### 2026-07-05 / Provider Lifecycle

Decision:

- Canonical Providers consist of three responsibilities: Builder, Resolver,
  and Formatter.

Boundary protected:

- Builder builds facts and never formats.
- Resolver owns resolution strategy and never builds facts.
- Formatter shapes text and never owns strategy.
- Resolution is transient and request-scoped. It must never become persisted
  domain data, Configuration state, Renderer input state, or cached asset
  value.
- Resolvers are deterministic. For the same Context and Configuration, a
  Resolver must always produce the same Resolution.
- Resolvers must not depend on time, UI state, renderer state, global state,
  or external services.

### 2026-07-05 / Phase 0

Decision:

- Location Expression starts as isolated skeleton types only.

Boundary protected:

- Phase 0 must not connect to Renderer, Export, UI, Share Extension, Photo
  Library behavior, or production metadata mutation.

### 2026-07-05 / Phase 1

Decision:

- `LocationContextBuilder` maps normalized `PhotoMetadata` facts into
  `LocationContext`.

Boundary protected:

- Builder owns fact extraction only.
- Builder must not format display strings.
- Builder must not resolve presentation fallback.
- Builder must not emit expression tokens.
- `LocationContext` must not store preformatted presentation strings.

### 2026-07-05 / Phase 2

Decision:

- `LocationFormatter` is a stateless pure formatter.

Boundary protected:

- Formatter owns string shape only.
- Formatter must not fetch source data.
- Formatter must not own fallback strategy.
- Formatter must not depend on Provider, Renderer, Template, Inspector, or UI.
- Formatter may trim empty parts and deduplicate repeated hierarchy values.
- Formatter may format coordinate presentation only when explicitly asked for
  `.coordinate`.

### 2026-07-05 / Phase 3

Decision:

- `LocationResolver` owns resolution strategy, including fallback,
  presentation selection, downgrade decisions, and future policy decisions.
- `LocationResolution` is a transient domain event for one resolver request,
  not a persistent data model.
- `LocationResolution` is immutable and records decisions only. It does not
  store formatted text or hold `LocationContext`.
- Resolver behavior is deterministic: the same `LocationContext` and
  `LocationResolutionConfiguration` produce the same `LocationResolution`.

Boundary protected:

- Resolver must not read `PhotoMetadata` directly.
- Resolver must not render pixels.
- Resolver must not write module configuration.
- Resolver must not persist or cache `LocationResolution`.
- Resolver must be deterministic for the same `LocationContext` and
  configuration.
- Formatter formats the resolved decision and must not re-evaluate resolver
  strategy.

### 2026-07-05 / Phase 4-B and Phase 4-C

Decision:

- `ExpressionValue` is the canonical provider-neutral output unit.
- `ExpressionValue` carries a semantic `ExpressionToken` and resolved text.
- `ExpressionContext` is a token-addressable map of `ExpressionValue`.
- Duplicate semantic tokens are rejected at `ExpressionContext` construction.

Boundary protected:

- Expression values are not bare strings.
- Expression values do not carry provider-specific Context, Resolution,
  Renderer, Template, Inspector, or UI state.
- ExpressionContext is a container, not a semantic resolver.
- ExpressionContext does not replace `MetadataContext` or connect to
  production rendering in Phase 4-C.

### 2026-07-05 / Expression System Smoke

Decision:

- The expression language kernel can support multiple provider-like sources
  producing `ExpressionValue` into one `ExpressionContext`.
- Renderer consumption can be modeled as `ExpressionContext` input only.
- Duplicate semantic token conflicts remain owned by `ExpressionContext`.

Boundary protected:

- Smoke-test fake providers are test fixtures, not production Provider API.
- No Location Provider, Renderer, Metadata adapter, UI, Export, Share
  Extension, or Photo Library production wiring is introduced.

### 2026-07-06 / Phase 4-D

Decision:

- `LocationExpressionProvider` is the first Canonical Provider compiler
  validation point.
- Phase 4-D supports only the `location` semantic token.
- `LocationExpressionProvider` consumes `LocationContext`,
  `LocationResolver`, and `LocationFormatter` output to produce
  provider-neutral `ExpressionValue`.
- `LocationExpressionProvider` produces values by semantic token instead of
  returning a provider-owned collection model.

Boundary protected:

- Provider must not read `PhotoMetadata` directly.
- Provider must not reimplement Builder, Resolver, or Formatter logic.
- Provider must not own presentation strategy, fallback, downgrade, or string
  shaping.
- Provider must not output Metadata or Memory tokens.
- Provider must not depend on Renderer, Template, Inspector, UI, Export, Share
  Extension, or Photo Library behavior.
- Raw `latitude`, `longitude`, and `altitude` tokens remain future Location
  Provider expansion work and are not part of Phase 4-D output support.
- Provider output must be `ExpressionValue`, not a bare `String` or
  provider-specific result model.
