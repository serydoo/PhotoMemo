# FilmMark COS review closure

## Scope and decision gate

Engineering Loop, based on the completed COS second review in
`评审FM架构方向` (turn `f9ea4f50-5331-40c6-982d-7283f828e2d0`)
and independent source inspection on HEAD `53f91dc` plus the existing dirty FM
worktree. The user authorized continued debugging, fixes, review and preparation
for physical-device validation. Existing unrelated work remains user-owned.

P0: FM content currently has an in-memory style draft but no independent durable
carrier. Share Extension builds a legacy-default snapshot plus a reference;
its empty FM Codable placeholder drops the real appearance/placement fields.
P1: incomplete CoreText fit can still look successful, unavailable persisted
font candidates measure differently from drawing, and calibration drawing uses
1200-pixel coordinates in a smaller SwiftUI view without scaling.

Canonical ownership: Configuration aggregate owns saved content/appearance;
the existing Card Content adapter owns authored text/modules; Layout Engine
owns dimensions and diagnostics; Renderer draws resolved output. Share only
transports a frozen snapshot. Foundation Codable and existing App Group storage
provide transport; CoreText/SwiftUI provide measuring/drawing. No new permissions
or network/photo upload are required.

## Bounded increments and evidence

1. Add an optional versioned FM primary-output carrier under the existing Editor
   aggregate. Reuse TemplateArea as the existing content AST and project a runtime
   Template only at the existing Card Content boundary. Keep FM out of the legacy
   style dictionary. Test save/reload/production and Classic/Minimal preservation.
2. Replace the empty Share FM placeholder with shared value types. Publish a
   complete encoded production snapshot as one derived shared-default value after
   canonical save. Carry app-only canonical semantics as opaque Data through Share;
   validate when the main app decodes. Test rev N handoff, rev N+1 save and rev N
   drain. Malformed snapshots must fail closed, not select a Classic default.
3. Carry full-string fit explicitly into layout diagnostics and reject overflowing
   production rendering. Use the same resolved font name for measurement/drawing.
   Scale compact preview geometry to its actual displayed frame.
4. FM main page keeps Time Anchor, style, content, font/size/color, position summary,
   output destination and Photo Description. Move expression/time/location options
   into an FM secondary sheet; hide inapplicable Logo. Reuse all existing controls.
   Classic/Minimal branches and their orientation layouts stay as they are.
5. Run focused tests using MemoMarkTests, relevant full tests, macOS build and
   signed iPhoneOS build serially. Obtain a fresh COS read-only final review.
   Physical iPhone UI/Photos/Live Photo acceptance is a separate gate.

COS connection proof: Core session search and read-only command successfully
resolved `/photomemo` to `/Users/rui/Desktop/PhotoMemo`. Calls from this Codex
thread are reported Unattributed, so worker identity is not inferred. Continue
independent review through the existing ChatGPT conversation; avoid the failed
worker startup path and concurrent Xcode runs.

## Results

Local engineering gates are green: the full `MemoMarkTests` run completed with
1,848 passed, 1 skipped, and 0 failed; the macOS `MemoMark` build passed; the
generic iOS `MemoMarkiOS` and `MemoMarkShareExtension` builds passed; the COS
Core read-only workspace command passed; and both `git diff --check` and the
repository governance check passed.

The earlier COS review findings have been addressed in the local FM slice, but
a fresh ChatGPT review body has not been obtained yet. `c2c doctor` reports the
Bridge, MCP, and OAuth layers healthy while `tunnel.start` times out. A direct
HTTP/2 Quick Tunnel diagnostic confirmed that DNS, UDP, and Cloudflare API
prechecks pass, while TCP/7844 is blocked and the edge TLS handshake returns
EOF. A follow-up forced-QUIC diagnostic could register a node, but it then
failed with `no recent network activity` and could not keep a tunnel alive. Both
diagnostic processes were terminated cleanly. The Mac is also currently
locked, so the in-app connector repair cannot be completed from this session.

No physical-device acceptance or production certification is claimed. No
commit, push, or upload was performed.
