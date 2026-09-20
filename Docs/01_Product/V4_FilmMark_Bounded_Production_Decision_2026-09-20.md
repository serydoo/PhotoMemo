# V4 FilmMark bounded production decision

Date: 2026-09-20
Decision type: release decision record
Current status: `HOLD — local candidate; not production certified`

## Decision

FilmMark remains a bounded local candidate in the current 2.3.0 (105)
checkout. This record closes the source/documentation ambiguity identified in
the pre-release review; it is not a Product Design Review approval, App Store
submission authorization, or production certification.

The current code may continue to be validated and repaired behind the following
explicit boundaries:

- FM content remains an independent `FilmMarkContentSchemaV2` payload.
- FM appearance, placement, safe-area data, and content are frozen together at
  Share/Batch handoff; missing or inconsistent payloads fail closed.
- Preview, still output, and Live Photo overlay continue to consume the same
  resolved presentation/layout contract.
- The verified initial font choice remains the system monospaced face.
- `none`, `paperWhite`, and `softShadow` are the new selectable substrate
  choices.
- `systemGlass` remains decodable and renderable for compatibility with an
  existing local configuration, but is not offered for new production
  selection until the physical-device gates below pass.
- FM appearance persistence now carries an explicit recipe version. Payloads
  written before that field existed decode as recipe `v1`; unknown versions
  fail closed.

## Open release gates

The following items remain open and keep this decision at `HOLD`:

1. Product-owner acceptance of the bounded FM v1 scope and a formal Product
   Design Review outcome.
2. BP-001 high-resolution single-task memory evidence, including 48MP static
   and Live Photo cases with Instruments or equivalent physical-device
   measurement.
3. TX-001 physical Apple Photos commit, interruption, recovery, read-back, and
   duplicate-prevention evidence.
4. Signed iPhone 17 Pro Max acceptance for FM configuration persistence,
   preview/output parity, static output, Live Photo, Share processing,
   original-photo protection, accessibility, localization, and light/dark
   appearance.
5. A superseding production certification after the engineering and device
   gates above are closed.

Builds, unit tests, source audits, and this decision record do not close those
gates. No App Store Connect, TestFlight, GitHub push, or other external release
mutation is authorized by this document.

## Follow-up rule

When the open gates are closed, replace this `HOLD` record with a new scoped
decision that names the exact build, enabled substrates, device evidence,
PhotoKit evidence, and remaining unsupported media or platform paths. Do not
silently turn a local candidate into a production claim by changing only a
label or a picker list.
