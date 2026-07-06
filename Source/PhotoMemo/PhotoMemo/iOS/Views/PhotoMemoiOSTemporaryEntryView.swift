#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct PhotoMemoiOSTemporaryEntryView: View {

    @ObservedObject
    var backgroundStatusService:
        PhotoMemoBackgroundStatusService

    let refreshExternalIntake:
        () -> Void

    private let environment:
        AppEnvironment?

    @AppStorage
    private var selectedEntryRawValue: String

    private let configuration:
        PhotoMemoiOSTemporaryEntryConfiguration

    private let configurationCenterRuntime:
        PhotoMemoAppRuntime

    init(
        backgroundStatusService:
            PhotoMemoBackgroundStatusService,
        refreshExternalIntake:
            @escaping () -> Void = {},
        environment: AppEnvironment? = nil,
        configuration:
            PhotoMemoiOSTemporaryEntryConfiguration = .standard
    ) {
        self.backgroundStatusService =
            backgroundStatusService
        self.refreshExternalIntake =
            refreshExternalIntake
        self.environment =
            environment
        self.configuration =
            configuration
        self.configurationCenterRuntime =
            PhotoMemoAppRuntime(
                environment:
                    environment
                    ?? AppEnvironment
                    .live()
            )
        _selectedEntryRawValue =
            AppStorage(
                wrappedValue:
                    configuration.defaultEntry.rawValue,
                configuration.storageKey
            )
    }

    var body: some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker(
                            "临时入口",
                            selection: selectedEntryBinding
                        ) {
                            ForEach(
                                PhotoMemoiOSTemporaryEntry
                                    .allCases,
                                id: \.self
                            ) { entry in
                                Text(entry.displayTitle)
                                    .tag(entry)
                            }
                        }
                    } label: {
                        Label("临时入口", systemImage: "square.grid.2x2")
                    }
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch selectedEntry {
        case .v1Preview:
            PhotoMemoiOSV1View(
                backgroundStatusService:
                    backgroundStatusService,
                refreshExternalIntake:
                    refreshExternalIntake,
                previewCoordinator:
                    environment?
                    .coordinators
                    .preview,
                exportCoordinator:
                    environment?
                    .coordinators
                    .export,
                queueCoordinator:
                    environment?
                    .coordinators
                    .queue,
                configurationCoordinator:
                    environment?
                    .coordinators
                    .configuration,
                externalIntakeCenter:
                    environment?
                    .externalIntakeCenter
                    ?? .shared,
                diagnosticsRepository:
                    environment?
                    .repositories
                    .diagnostics
            )
        case .configurationCenter:
            ConfigurationCenteriOSView(
                runtime:
                    configurationCenterRuntime
            )
        }
    }

    private var selectedEntry:
        PhotoMemoiOSTemporaryEntry {

        PhotoMemoiOSTemporaryEntry.resolve(
            storedValue:
                selectedEntryRawValue,
            defaultEntry:
                configuration.defaultEntry
        )
    }

    private var selectedEntryBinding:
        Binding<PhotoMemoiOSTemporaryEntry> {

        Binding(
            get: {
                selectedEntry
            },
            set: { newEntry in
                selectedEntryRawValue =
                    newEntry.rawValue
            }
        )
    }
}
#endif
