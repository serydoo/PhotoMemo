# Classic White Snapshot References

This directory stores the committed snapshot references for Classic White.

Current scope:

- `full-card/`

These files are used by:

- `Tests/PhotoMemoTests/RendererTests/ClassicWhiteSnapshotTests.swift`

Record mode:

```bash
PHOTOMEMO_RECORD_SNAPSHOTS=1 xcodebuild \
  -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj \
  -scheme PhotoMemoTests \
  -destination 'platform=macOS' \
  -only-testing:PhotoMemoTests/ClassicWhiteSnapshotTests \
  test
```

Normal verification:

```bash
xcodebuild \
  -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj \
  -scheme PhotoMemoTests \
  -destination 'platform=macOS' \
  -only-testing:PhotoMemoTests/ClassicWhiteSnapshotTests \
  test
```

If a snapshot fails, diff artifacts are written to:

- `/tmp/MemoMarkSnapshotDiffs/ClassicWhite/`
