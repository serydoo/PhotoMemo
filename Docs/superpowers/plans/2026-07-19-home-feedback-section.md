# MemoMark Home Feedback Section

Date: 2026-07-19
Primary loop: Product Loop
Status: Approved for implementation

## Observation

The current Settings page already keeps TestFlight, email, and GitHub feedback
channels, but Home does not provide a persistent direct-developer contact
surface. During the current TestFlight-heavy phase, users need a visible place
for discussion, issue feedback, and customization requests.

## Decision

Add one Home card named `意见反馈` after the current configuration card.
The card remains present on Home, defaults to expanded, and can be collapsed.
Its expanded state is persisted locally.

The card communicates:

- search `MemoMark` on 小红书 or 抖音 to find the developer
- QQ group `955680366`
- users are welcome to discuss usage, report issues, and request customization
- TestFlight system feedback remains available in parallel

## Implementation Boundary

- Add one isolated `V1HomeFeedbackSection` SwiftUI component.
- Add one call site in `V1HomePageSurface`.
- Keep the existing Settings feedback section unchanged.
- Do not add network requests, account integration, deep links, or photo access.
- Do not change Configuration Center, Renderer, Metadata, Export, Share
  Extension, Photo Library, or Layout Engine behavior.
- Keep removal cheap: delete the component, its tests, and the single Home call
  site when the temporary TestFlight feedback phase ends.

## Interaction And Visual Contract

- Use the existing `V1CardSurface` and Configuration UI tokens.
- The card title remains visible while collapsed.
- Use a native text-and-chevron disclosure control with a 44-point minimum tap
  target and explicit accessibility label/value.
- Support narrow iPhone widths and Dynamic Type without fixed content height.
- Do not add copy buttons or outbound links in this slice.

## Verification

- Red/green architecture contract for placement, copy, local disclosure state,
  accessibility, TestFlight coexistence, and isolated removal boundary.
- Focused tests pass.
- `PhotoMemoiOS` Debug build passes.
- Signed build installs on `iPhone7` without clearing existing app data.
- Manual Home review confirms expanded and collapsed layouts.

## Channel Evidence Note

The channel names, search keyword, and QQ group are user-provided product
content. Agent Reach detected a running Xiaohongshu backend that is not wired to
the local query client, and it has no Douyin backend, so this implementation
does not claim independent external search verification.
