import Foundation
import Testing

@Suite("Cross-target localization contracts")
struct CrossTargetLocalizationTests {

    private let languageCodes = ["en", "zh-Hans", "ja", "ko"]

    private let shareSurfaceFiles = [
        "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareExtensionViewStateRenderer.swift",
        "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionViewController.swift",
        "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareExtensionPreviewController.swift"
    ]

    private let widgetSurfaceFiles = [
        "Source/PhotoMemo/PhotoMemo/iOS/Activity/PhotoMemoLiveActivityPresentation.swift"
    ]

    private let macOSSurfaceFiles = [
        "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationCenterView.swift",
        "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Sidebar/MemorySubjectListView.swift",
        "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCardConfigurationContext.swift",
        "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/InspectorView.swift",
        "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorConfigurationPickerSection.swift",
        "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorCustomFieldsSection.swift",
        "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorSystemModulesSection.swift"
    ]

    private let shareKeys = [
        "share.brand",
        "share.summary.title",
        "share.preview.title",
        "share.preview.caption.empty",
        "share.preview.caption.single",
        "share.preview.caption.multiple",
        "share.preview.caption.processing",
        "share.preview.photo_index",
        "share.preview.detail.queued",
        "share.preview.detail.completed",
        "share.preview.detail.failed",
        "share.preview.detail.cancelled",
        "share.preview.detail.processing",
        "share.status.title",
        "share.status.stage.receiving",
        "share.status.stage.submitted",
        "share.status.stage.waiting",
        "share.status.stage.configuration_required",
        "share.status.stage.free_records_completed",
        "share.status.stage.batch_too_large",
        "share.status.stage.unsupported",
        "share.status.message.configuration_required",
        "share.status.message.free_records_completed",
        "share.status.message.batch_too_large",
        "share.status.message.unsupported",
        "share.status.footer.configuration_required",
        "share.status.footer.free_records_completed",
        "share.status.footer.batch_too_large",
        "share.status.button.submitting",
        "share.status.button.submitted",
        "share.status.button.configure",
        "share.status.button.open_app",
        "share.status.button.share_smaller_batches",
        "share.status.button.create_record",
        "share.status.button.close",
        "share.status.button.try_again",
        "share.checklist.original_unchanged",
        "share.checklist.capture_preserved",
        "share.checklist.background_processing",
        "share.checklist.notification",
        "share.success.received_format",
        "share.success.skipped_format",
        "share.success.failed_format",
        "share.success.live_photo_still_format",
        "share.success.completed_format",
        "share.success.remaining_note",
        "share.reading_icloud_original",
        "share.no_processable_photos",
        "share.no_configuration.subtitle",
        "share.ready.subtitle"
    ]

    private let widgetKeys = [
        "widget.brand",
        "widget.count.completed",
        "widget.count.failed",
        "widget.count.total",
        "widget.stale",
        "widget.source",
        "widget.title.preparing",
        "widget.title.processing_format",
        "widget.title.completed",
        "widget.title.partial_success",
        "widget.title.needs_attention",
        "widget.title.unsupported",
        "widget.accessibility.progress",
        "widget.accessibility.current_step",
        "widget.queue.overflow_format"
    ]

    private let macOSKeys = [
        "不同记忆对象拥有不同的锚点，也拥有不同的回忆角度。",
        "时光记用锚点帮助你阅读回忆。",
        "重命名记忆预设",
        "重置当前总体配置",
        "从当前状态创建新的配置",
        "将当前总体配置保存到当前配置",
        "对象检查器",
        "删除自定义内容",
        "移除此模块",
        "此区域由用户自定义。可以在下方添加字段，并插入照片信息、记忆或系统模块。",
        "删除默认模块"
    ]

    private let accessibilityKeys = [
        "accessibility.avatar_zoom",
        "accessibility.object_name_required",
        "accessibility.choose_crop",
        "accessibility.delete_avatar",
        "accessibility.anchor_date",
        "accessibility.anchor_actions",
        "accessibility.clear_format"
    ]

    @Test("Share Extension UI no longer branches on bilingual literals")
    func shareExtensionDoesNotUseLegacyBilingualBranches() throws {
        for relativePath in shareSurfaceFiles {
            let source = try String(
                contentsOf: repositoryRoot.appendingPathComponent(relativePath),
                encoding: .utf8
            )
            #expect(!source.contains("localized(_ simplifiedChinese:"))
            #expect(!source.contains("interfaceStored == .english"))
            #expect(!source.contains("interfaceStored == .english ?"))
        }
    }

    @Test("Share Extension active keys have four-language values")
    func shareKeysHaveFourLanguageValues() throws {
        let resources = try Dictionary(uniqueKeysWithValues: languageCodes.map { code in
            let source = try String(
                contentsOf: repositoryRoot.appendingPathComponent(
                    "Source/PhotoMemo/PhotoMemo/\(code).lproj/Localizable.strings"
                ),
                encoding: .utf8
            )
            return (code, parse(source))
        })

        for key in shareKeys {
            for code in languageCodes {
                let value = resources[code]?[key]
                #expect(value != nil, "Missing \(code) Share Extension value for \(key)")
                #expect(value?.isEmpty == false, "Empty \(code) Share Extension value for \(key)")
            }

            guard key != "share.brand" else {
                continue
            }

            let english = try #require(resources["en"]?[key])
            #expect(resources["ja"]?[key] != english, "Japanese fallback for \(key)")
            #expect(resources["ko"]?[key] != english, "Korean fallback for \(key)")
        }
    }

    @Test("Share Extension target includes the localized resource variant group")
    func shareExtensionTargetIncludesLocalizedResources() throws {
        let project = try String(
            contentsOf: repositoryRoot.appendingPathComponent(
                "Source/PhotoMemo/PhotoMemo.xcodeproj/project.pbxproj"
            ),
            encoding: .utf8
        )

        #expect(project.contains("Localizable.strings in Share Extension resources"))
        #expect(project.contains("A0C0A0010000000000000010 /* Localizable.strings */"))
        #expect(project.contains("A0C0A0010000000000000003 /* ja Localizable.strings */"))
        #expect(project.contains("A0C0A0010000000000000004 /* ko Localizable.strings */"))
    }

    @Test("Widget visible copy has no bilingual literal branches")
    func widgetDoesNotUseHardcodedLocalizedCopy() throws {
        for relativePath in widgetSurfaceFiles {
            let source = try String(
                contentsOf: repositoryRoot.appendingPathComponent(relativePath),
                encoding: .utf8
            )
            #expect(!source.contains("interfaceStored == .english"))
            #expect(!source.contains("Label(\n                    \"时光记\""))
            #expect(!source.contains("Text(\"来源\")"))
            #expect(!source.contains("Text(\"完成\")"))
            #expect(!source.contains("Text(\"失败\")"))
            #expect(!source.contains("Text(\"总数\")"))
            #expect(source.contains("widgetLocalized"))
            #expect(!source.contains("MemoMarkLanguage.stored"))
        }
    }

    @Test("Widget active keys have four-language values")
    func widgetKeysHaveFourLanguageValues() throws {
        let resources = try Dictionary(uniqueKeysWithValues: languageCodes.map { code in
            let source = try String(
                contentsOf: repositoryRoot.appendingPathComponent(
                    "Source/PhotoMemo/PhotoMemo/\(code).lproj/Localizable.strings"
                ),
                encoding: .utf8
            )
            return (code, parse(source))
        })

        for key in widgetKeys {
            for code in languageCodes {
                let value = resources[code]?[key]
                #expect(value != nil, "Missing \(code) Widget value for \(key)")
                #expect(value?.isEmpty == false, "Empty \(code) Widget value for \(key)")
            }

            guard key != "widget.brand" else {
                continue
            }

            let english = try #require(resources["en"]?[key])
            #expect(resources["ja"]?[key] != english, "Japanese fallback for \(key)")
            #expect(resources["ko"]?[key] != english, "Korean fallback for \(key)")
        }
    }

    @Test("Widget target includes the localized resource variant group")
    func widgetTargetIncludesLocalizedResources() throws {
        let project = try String(
            contentsOf: repositoryRoot.appendingPathComponent(
                "Source/PhotoMemo/PhotoMemo.xcodeproj/project.pbxproj"
            ),
            encoding: .utf8
        )

        #expect(project.contains("Localizable.strings in Widget Extension resources"))
        #expect(project.contains("F4A1B23D3A9C410100A10001"))
        #expect(project.contains("F4A1B23C3A9C410100A10001 /* Resources */"))
    }

    @Test("macOS active Configuration Center copy has four-language values")
    func macOSActiveSurfaceHasLocalizedValues() throws {
        for relativePath in macOSSurfaceFiles {
            let source = try String(
                contentsOf: repositoryRoot.appendingPathComponent(relativePath),
                encoding: .utf8
            )
            #expect(!source.contains("interfaceStored == .english"))
        }

        let resources = try Dictionary(uniqueKeysWithValues: languageCodes.map { code in
            let source = try String(
                contentsOf: repositoryRoot.appendingPathComponent(
                    "Source/PhotoMemo/PhotoMemo/\(code).lproj/Localizable.strings"
                ),
                encoding: .utf8
            )
            return (code, parse(source))
        })

        for key in macOSKeys {
            for code in languageCodes {
                let value = resources[code]?[key]
                #expect(value != nil, "Missing \(code) macOS value for \(key)")
                #expect(value?.isEmpty == false, "Empty \(code) macOS value for \(key)")
            }

            let english = try #require(resources["en"]?[key])
            #expect(resources["ja"]?[key] != english, "Japanese fallback for \(key)")
            #expect(resources["ko"]?[key] != english, "Korean fallback for \(key)")
        }
    }

    @Test("Accessibility labels and hints have four-language values")
    func accessibilityCopyHasFourLanguageValues() throws {
        let resources = try Dictionary(uniqueKeysWithValues: languageCodes.map { code in
            let source = try String(
                contentsOf: repositoryRoot.appendingPathComponent(
                    "Source/PhotoMemo/PhotoMemo/\(code).lproj/Localizable.strings"
                ),
                encoding: .utf8
            )
            return (code, parse(source))
        })

        for key in accessibilityKeys {
            for code in languageCodes {
                let value = resources[code]?[key]
                #expect(value != nil, "Missing \(code) accessibility value for \(key)")
                #expect(value?.isEmpty == false, "Empty \(code) accessibility value for \(key)")
            }

            let english = try #require(resources["en"]?[key])
            #expect(resources["ja"]?[key] != english, "Japanese fallback for \(key)")
            #expect(resources["ko"]?[key] != english, "Korean fallback for \(key)")
        }
    }

    private func parse(_ source: String) -> [String: String] {
        var result: [String: String] = [:]
        for line in source.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = String(line)
            guard line.first == "\"",
                  let separator = line.range(of: "\" = \"") else {
                continue
            }
            let key = String(line[line.index(after: line.startIndex)..<separator.lowerBound])
            let valueStart = separator.upperBound
            let valueEnd = line.lastIndex(of: "\"") ?? line.endIndex
            guard valueStart <= valueEnd else { continue }
            result[key] = String(line[valueStart..<valueEnd])
        }
        return result
    }

    private var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
