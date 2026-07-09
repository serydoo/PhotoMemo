# Scripts

This folder contains local automation helpers.

Current scripts:

- `auto_sync_to_github.sh`
- `install_autosync.sh`
- `com.serydoo.photomemo.autosync.plist`
- `export_options_v1_testing.plist` - local debugging export options
- `export_options_testflight.plist` - App Store Connect/TestFlight upload export options
- `collect-ios-runtime-evidence.sh` - pulls iPhone runtime diagnostics,
  shared defaults, queue summaries, and PhotoMemo crash reports for MGF-2B
  evidence review without copying private media.

## TestFlight Export

Use `export_options_testflight.plist` only after creating a Release archive
that is signed with an Apple Distribution path.

The current Xcode-supported App Store Connect method is:

```text
method = app-store-connect
destination = upload
```

Keep `export_options_v1_testing.plist` for local/debugging exports. It uses
`method = debugging`, which is not the TestFlight upload path.

V2 note: the target structure names this bucket `Scripts`, but the existing repository uses lowercase `scripts`. Keep the current folder name unless a dedicated rename migration is planned.
