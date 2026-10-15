# Settings hierarchy implementation and iPhone delivery preparation

2026-10-15 owner explicitly accepts reviewed structure and asks to write it into the App and then organize all code / prepare delivery to paired iPhone17. Presentation Feature P2. Base main d17bf849, local candidate2.3.7(132), dirty V5 worktree preserved with before copies/fingerprints. This authorizes local signed build/install on the paired17ProMax if available; no Git push or AppStore/TestFlight release requested.

## Scope / contract

Root: unchanged MemoMark+ → compact time-expression feature entry → visible native interface preferences → Usage/Data navigation rows → feedback/rating support rows → installed version/Store updates/log/story. Feature title时间锚点，让照片有了前后, button看看照片会怎么说; reuse SettingsExpressionGuide, five canonical AnchorType categories and existing style catalog / illustrative formulas. No new runtime formula calculation or configuration state. No synthetic real photo output.

Long usage content moves to child, preserving welcome/workflow/guide/story routes. Photo/data child reuses existing read-only contents and commerceSnapshot.batchLimit; feedback child reuses email/XHS/diagnostics/conditionalTestFlight. Two existing interface AppStorage keys, bindings and language-versus-output distinction retained; remove obsolete accordion UI/readers without deleting historical preferences. Settings children remain within current NavigationStack and return to Settings; no new independent root stack or application tab switches except existing explicit configuration action.

Replace unused SettingsDisclosureSection with a small stateless section surface; remove obsolete summary API. Keep DynamicType wrapping, semantic colors, native pickers, VoiceOver section headers, readable centered column on iPad, no forced2cols or custom animation. Four-locale additive structure copy and concise existing language explanation. No services/framework/dependency, permissions, network polling or business/Photos/Share/LivePhoto/renderer/config/Commerce responsibilities changed.

## Increment / evidence

Update superseded layout contracts with meaningful root-order/navigation/preference ownership and four-language constraints; RED on old root, then implementation. Build SimulatorDebug, focused host tests incl settings/guide/native layout/localization, signed iOS build. On13inch simulator capture root/feature guide/usage/data/feedback/versions and back navigation; ordinary phone minimum root/navigation smoke. Save rawPNG/AX, original failed records, scoped patch and code inventory. Install candidate to paired17ProMax if reachable/unlocked, verify installedbundle/version and launch; install/launch is not owner visual or media certification. Keep version unchanged unless specifically requested. No broad staging/reset/clean; review only incremental files and document cumulative V5 source/build boundaries.

## Native interaction findings and bounded repairs

Centered row taps initially left Settings on screen: plain Button labels contained non-hittable spacer regions. Shared SettingsActionRow and linked SettingsContentRow now define a Rectangle contentShape after padding, preserving appearance while making the full padded row tappable. Raw initial05-usage screenshot/AX and command receipt are retained as native RED evidence.

Root-owned sibling boolean destinations replaced the usage child when its workflow action was selected, making Back return straight to Settings. UsageGuideDestination is a private presentation-only enum whose item destination is attached to usageGuidePage. Expression/story/welcome/workflow callbacks now push from that child; the original root workflow binding remains for the existing Home shortcut. No new NavigationStack or business state owner is introduced. Native06-workflow screenshot retains the wrong Back context; NavigationSuiteRED covers child attachment before repair. A first overly narrow test filter selected zero tests (NavigationRED); it is explicitly not counted as a pass or RED. Corrected suite selection exposed the failure.

The standalone identifier settings.story matched the active-localization audit's key pattern. Rename to settings.about-story to follow existing kebab action identifiers, with no placeholder translation inserted. Final description uses device rather than iPhone across four locales. Initial and final runs remain separated; final native acceptance and device receipt are recorded in the results document.
