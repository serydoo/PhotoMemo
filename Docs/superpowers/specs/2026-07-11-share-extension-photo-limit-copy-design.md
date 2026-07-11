# Share Extension Photo Limit Copy Design

## Goal

When a Share Extension request contains more than 20 supported photos, explain
the safe processing limit with warm MemoMark language while keeping the next
action unambiguous.

## Interaction

- Title: `一次最多分享 20 张照片`
- Message: `美好的记忆不必一次整理完。每次分享不超过 20 张，让时光记稳稳地完成每一张。`
- Primary action: `返回分批分享`
- The request remains rejected before provider loading or persistence.
- The existing `extension.input.tooManyPhotos` diagnostic remains unchanged.

## Scope

Update both oversized-share presentation paths so service errors and UI
preflight use consistent wording. Do not change the 20-photo safety limit,
queue policy, media handling, or Share Extension architecture.

## Verification

- Add a source-level regression for the approved title, message, and action.
- Run the focused Share intake diagnostics tests.
- Build the Share Extension for generic iOS.
- Confirm the final copy on a signed physical device.
