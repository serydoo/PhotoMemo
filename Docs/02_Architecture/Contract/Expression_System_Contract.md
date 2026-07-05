# Expression System Contract

Date: 2026-07-05
Status: proposed
Scope: Expression System / Provider Pipeline
Branch: codex/地址模块

## 1. Purpose

This contract defines the shared expression pipeline that future Metadata,
Location, Memory, Weather, People, AI, and other capabilities must follow.

Its purpose is to prevent each capability from inventing its own token,
preview, resolver, formatter, or renderer path.

The core contract is:

```text
Facts
        |
        v
Builder
        |
        v
Context
        |
        v
Resolver
        |
        v
Resolution
        |
        v
Formatter
        |
        v
Expression Value
        |
        v
Provider
        |
        v
ExpressionContext
        |
        v
Renderer
```

Location is the first validation case. This contract is not Location-specific.

## 2. Canonical Flow

### Facts

Facts are objective source inputs.

Examples:

- normalized photo metadata
- capture time
- GPS coordinates
- reverse-geocoded address facts
- user-saved memory configuration

Facts may come from EXIF, user configuration, local services, adapters, or
other approved fact-acquisition stages.

### Builder

Builder owns fact acquisition and fact mapping.

Builder may:

- read source facts
- call local or service adapters needed to acquire facts
- normalize facts into a provider-owned context

Builder must not:

- format final text
- choose presentation fallback
- emit expression tokens
- depend on Renderer, Template, Inspector, or UI

### Context

Context is the provider-owned factual model.

Context may contain availability helpers and normalized facts. It must not
contain preformatted presentation strings or request-specific resolution state.

### Resolver

Resolver owns deterministic meaning selection.

Resolver consumes only:

- provider Context
- explicit Configuration

Resolver produces:

- request-scoped Resolution

Resolver must be deterministic:

```text
same Context + same Configuration -> same Resolution
```

Resolver must not depend on:

- current time
- UI state
- Renderer state
- Template state
- global mutable state
- network calls
- cache state
- external services
- direct source metadata reads

External fact acquisition belongs before Context construction, not inside
Resolver.

### Resolution

Resolution is a transient domain event for one resolver request.

Resolution records the decision that was made. It is not persistent domain
data.

Resolution must:

- be immutable after creation
- be request-scoped
- record decision metadata, such as requested presentation, resolved
  presentation, and resolution policy

Resolution must not:

- hold Context
- hold source metadata
- hold formatted text
- be stored in Configuration
- be persisted
- be cached as asset data
- be passed into Renderer as renderer state

### Formatter

Formatter owns text representation.

Formatter consumes:

- provider Context
- resolved decision

Formatter produces:

- final display text for the expression value

Formatter must not:

- fetch facts
- choose fallback
- downgrade presentation
- re-evaluate resolver strategy
- depend on Provider, Renderer, Template, Inspector, or UI

### Expression Value

Expression Value is the provider-neutral output that can be stored in
ExpressionContext.

It must represent a resolved semantic token value. It should carry the minimum
stable data needed by ExpressionContext and downstream rendering.

Phase 4 must define this contract before implementing provider integration.

Provider integration must not expose bare strings as the only long-term
provider output shape.

### Provider

Provider coordinates the provider-owned pipeline.

Provider is not the place to implement fact acquisition, strategy, or string
formatting directly. It composes Builder, Resolver, and Formatter, then emits
Expression Values.

Provider owns exactly one semantic domain.

### ExpressionContext

ExpressionContext is the canonical expression value store.

It is the stable boundary between Providers and expression consumption.

ExpressionContext must:

- store values by semantic token
- reject or test-detect duplicate canonical token ownership
- remain independent from Renderer, Template, Inspector, and UI
- be usable by both preview and production

Preview and production may have different ExpressionContext sources. They must
not have different core ExpressionContext models.

### Renderer

Renderer consumes resolved expression values and layout instructions. It
produces pixels.

Renderer must not:

- read provider Context
- run Resolver
- run Builder
- perform reverse geocoding
- decide fallback
- know how a semantic value was produced

## 3. Hard Rules

### Rule 1: Token Ownership

Every semantic token has exactly one canonical Provider.

No Provider may overwrite or regenerate another Provider's semantic token.

### Rule 2: Token Means Semantic

Tokens represent semantic meaning.

Different presentations of the same semantic should be configuration, not new
tokens.

Raw facts with distinct semantics may be separate tokens.

### Rule 3: Presentation Is Configuration

Presentation, fallback, decoration, locale preference, and similar policies
belong to Configuration.

Configuration must store rules and preferences, not resolved asset-specific
text.

### Rule 4: Context Is Factual

Context contains facts and availability. It does not contain formatted output
or request-scoped resolution state.

### Rule 5: Resolver Is Deterministic

For the same Context and Configuration, Resolver must always produce the same
Resolution.

### Rule 6: Resolution Is Transient

Resolution is a request-scoped decision record. It must not become persisted
domain data.

### Rule 7: Formatter Does Not Decide

Formatter formats the resolved decision. It never re-evaluates facts to choose
strategy.

### Rule 8: Provider Is A Coordinator

Provider composes the pipeline. It must not collapse Builder, Resolver, and
Formatter responsibilities into one untestable unit.

### Rule 9: Single ExpressionContext Model

Preview and production both feed Renderer through ExpressionContext.

Only the source differs:

```text
Preview sample facts -> Providers or fixtures -> ExpressionContext
Production facts -> Providers -> ExpressionContext
```

### Rule 10: Renderer Produces Pixels

Providers produce meaning. Renderer produces pixels.

Renderer must not become a semantic resolver.

## 4. Extension Rule

Any new capability must implement this pipeline without modifying existing
stages owned by other capabilities.

Examples:

- Location adds Location Builder, Context, Resolver, Formatter, Provider.
- Memory adds Memory Builder, Context, Resolver, Formatter, Provider.
- Weather adds Weather Builder, Context, Resolver, Formatter, Provider.
- People adds People Builder, Context, Resolver, Formatter, Provider.

A new capability may add its own provider-owned stages. It must not:

- add semantic fields directly to legacy adapters as the primary model
- make Renderer understand provider-specific facts
- make Formatter own fallback strategy
- make Resolver fetch external facts
- store resolved text in Configuration
- introduce a preview-only context model

## 5. Phase 4 Entry Criteria

Before Phase 4 provider integration begins, the implementation must define:

- the provider-neutral Expression Value shape
- ExpressionContext storage rules
- duplicate semantic token ownership behavior
- preview and production source equivalence rules
- focused tests for the ExpressionContext contract

LocationProvider should be implemented only after these contracts are testable.

## 6. Review Checklist

For every provider or expression-system change, review:

1. Which Provider owns this token?
2. Is this token semantic, or is it only presentation?
3. Is presentation stored as Configuration rather than resolved text?
4. Does Builder own fact acquisition only?
5. Does Context remain factual?
6. Is Resolver deterministic?
7. Is Resolution immutable, transient, and decision-only?
8. Does Formatter format without strategy decisions?
9. Does Provider only coordinate the pipeline?
10. Does Renderer remain unaware of provider-specific facts?
11. Do preview and production use the same ExpressionContext model?
12. Is the behavior covered by focused behavior and boundary tests?
