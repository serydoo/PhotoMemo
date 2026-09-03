#if os(iOS) && MEMOMARK_SHARE_EXTENSION
import Foundation
import Photos
import UniformTypeIdentifiers
import UIKit

private final class ShareProviderTimeoutTask:
    @unchecked Sendable {

    private let lock = NSLock()
    private var isCancelled = false
    private var task: Task<Void, Never>?

    func install(_ task: Task<Void, Never>) {
        lock.lock()
        guard !isCancelled else {
            lock.unlock()
            task.cancel()
            return
        }
        self.task = task
        lock.unlock()
    }

    func cancel() {
        lock.lock()
        isCancelled = true
        let task = self.task
        self.task = nil
        lock.unlock()

        task?.cancel()
    }

    deinit {
        cancel()
    }
}

private final class ShareProviderCompletionGate:
    @unchecked Sendable {

    private let lock = NSLock()
    private var isClaimed = false

    func claim() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !isClaimed else {
            return false
        }
        isClaimed = true
        return true
    }

    func hasBeenClaimed() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return isClaimed
    }
}

@MainActor
struct ShareManagedFileImporter {

    enum ManagedImportOutcome {

        case imported(
            ManagedImportRecord
        )

        case skippedDuplicate

        case skippedUnsupported(
            MemoMarkMediaIntakeRejectionReport
        )

        case failed(
            MemoMarkShareIntakeFailureContext
        )
    }

    struct ManagedImportRecord {

        let item:
            ExternalPhotoIntakeItem

        let dedupeKey: String

        let livePhotoStaticFallback:
            Bool

        init(
            item: ExternalPhotoIntakeItem,
            dedupeKey: String,
            livePhotoStaticFallback: Bool = false
        ) {
            self.item = item
            self.dedupeKey = dedupeKey
            self.livePhotoStaticFallback =
                livePhotoStaticFallback
        }

        var managedURL: URL {
            item.managedURL
        }
    }

    struct FileRepresentationLoadResult {

        let importRecord:
            ManagedImportRecord?

        let failureContext:
            MemoMarkShareIntakeFailureContext?
    }

    private let intakeStore:
        ExternalPhotoIntakeStore

    private let materializer:
        ShareManagedImportMaterializer

    private let providerLoader:
        ShareItemProviderLoader

    private let livePhotoRecovery:
        ShareLivePhotoRecovery

    private let providerLoadTimeoutNanoseconds:
        UInt64

    init(
        intakeStore: ExternalPhotoIntakeStore,
        providerLoader: ShareItemProviderLoader,
        livePhotoRecovery: ShareLivePhotoRecovery,
        providerLoadTimeoutNanoseconds:
            UInt64 = 15_000_000_000
    ) {
        self.intakeStore = intakeStore
        self.materializer =
            ShareManagedImportMaterializer(
                intakeStore: intakeStore
            )
        self.providerLoader = providerLoader
        self.livePhotoRecovery =
            livePhotoRecovery
        self.providerLoadTimeoutNanoseconds =
            providerLoadTimeoutNanoseconds
    }

    func loadManagedURL(
        from provider: NSItemProvider,
        requestID: UUID,
        index: Int,
        itemProviderCount: Int,
        supportedProviderCount: Int,
        mediaOutputModeRawValue: String?,
        livePhotoPolicyRawValue: String?,
        seenSourceKeys: inout Set<String>
    ) async -> ManagedImportOutcome {

        let registeredTypeIdentifiers =
            provider
            .registeredTypeIdentifiers
        let preferredTypeIdentifier =
            providerLoader
            .preferredImportTypeIdentifier(
                from:
                    registeredTypeIdentifiers
            )
        let preferredStaticImageTypeIdentifier =
            providerLoader
            .preferredImageTypeIdentifier(
                from:
                    registeredTypeIdentifiers
            )
        let livePhotoTypeIdentifier =
            providerLoader
            .preferredLivePhotoTypeIdentifier(
                from: registeredTypeIdentifiers
            )
        let diagnosticsSeed =
            MemoMarkShareIntakeOperationSeed(
                itemProviderCount:
                    itemProviderCount,
                supportedProviderCount:
                    supportedProviderCount,
                providerIndex: index,
                requestedTypeIdentifier:
                    UTType.image.identifier,
                preferredRegisteredTypeIdentifier:
                    preferredTypeIdentifier
            )

        ShareIntakeDiagnostics.notice(
            "Provider[\(index)] selectedUTType=\(UTType.image.identifier) preferredUTType=\(preferredTypeIdentifier ?? "unknown")"
        )

        var firstLoadFailureContext:
            MemoMarkShareIntakeFailureContext?

        if let livePhotoTypeIdentifier {
            let liveFileLoadResult =
                await loadFileRepresentationResult(
                    from: provider,
                    requestID: requestID,
                    index: index,
                    diagnosticsSeed:
                        MemoMarkShareIntakeOperationSeed(
                            itemProviderCount:
                                itemProviderCount,
                            supportedProviderCount:
                                supportedProviderCount,
                            providerIndex: index,
                            requestedTypeIdentifier:
                                livePhotoTypeIdentifier,
                            preferredRegisteredTypeIdentifier:
                                livePhotoTypeIdentifier
                        ),
                    requestedTypeIdentifier:
                        livePhotoTypeIdentifier,
                    allowsDirectoryPackage:
                        true
                )

            if let importRecord =
                liveFileLoadResult.importRecord {
                return outcomeForImportedRecord(
                    importRecord,
                    livePhotoTypeIdentifier:
                        livePhotoTypeIdentifier,
                    requestID: requestID,
                    index: index,
                    diagnosticsSeed:
                        diagnosticsSeed,
                    seenSourceKeys:
                        &seenSourceKeys
                )
            }

            if let failureContext =
                liveFileLoadResult
                .failureContext {
                firstLoadFailureContext =
                    firstLoadFailureContext
                    ?? failureContext
            }

            let liveInPlaceLoadResult =
                await loadInPlaceFileRepresentationResult(
                    from: provider,
                    requestID: requestID,
                    index: index,
                    diagnosticsSeed:
                        MemoMarkShareIntakeOperationSeed(
                            itemProviderCount:
                                itemProviderCount,
                            supportedProviderCount:
                                supportedProviderCount,
                            providerIndex: index,
                            requestedTypeIdentifier:
                                livePhotoTypeIdentifier,
                            preferredRegisteredTypeIdentifier:
                                livePhotoTypeIdentifier
                        ),
                    requestedTypeIdentifier:
                        livePhotoTypeIdentifier,
                    allowsDirectoryPackage:
                        true
                )

            if let importRecord =
                liveInPlaceLoadResult.importRecord {
                return outcomeForImportedRecord(
                    importRecord,
                    livePhotoTypeIdentifier:
                        livePhotoTypeIdentifier,
                    requestID: requestID,
                    index: index,
                    diagnosticsSeed:
                        diagnosticsSeed,
                    seenSourceKeys:
                        &seenSourceKeys
                )
            }

            if
                let failureContext =
                    liveInPlaceLoadResult
                .failureContext,
                firstLoadFailureContext == nil {
                firstLoadFailureContext =
                    failureContext
            }

            let liveObjectLoadResult =
                await loadLivePhotoObjectRepresentationResult(
                    from: provider,
                    requestID: requestID,
                    index: index,
                    diagnosticsSeed:
                        MemoMarkShareIntakeOperationSeed(
                            itemProviderCount:
                                itemProviderCount,
                            supportedProviderCount:
                                supportedProviderCount,
                            providerIndex: index,
                            requestedTypeIdentifier:
                                livePhotoTypeIdentifier,
                            preferredRegisteredTypeIdentifier:
                                livePhotoTypeIdentifier
                        ),
                    requestedTypeIdentifier:
                        livePhotoTypeIdentifier
                )

            if let importRecord =
                liveObjectLoadResult.importRecord {
                return outcomeForImportedRecord(
                    importRecord,
                    livePhotoTypeIdentifier:
                        livePhotoTypeIdentifier,
                    requestID: requestID,
                    index: index,
                    diagnosticsSeed:
                        diagnosticsSeed,
                    seenSourceKeys:
                        &seenSourceKeys
                )
            }

            if
                let failureContext =
                    liveObjectLoadResult
                    .failureContext,
                firstLoadFailureContext == nil {
                firstLoadFailureContext =
                    failureContext
            }

            if
                let failureContext =
                    liveObjectLoadResult
                    .failureContext
                    ?? firstLoadFailureContext,
                LivePhotoStaticFallbackPolicy
                .shouldStopAfterLiveRepresentationFailure(
                    errorCode:
                        failureContext
                        .errorSummary?
                        .code,
                    mediaOutputModeRawValue:
                        mediaOutputModeRawValue,
                    livePhotoPolicyRawValue:
                        livePhotoPolicyRawValue
                )
            {
                return .failed(
                    failureContext
                )
            }
        }

        let staticDiagnosticsSeed =
            MemoMarkShareIntakeOperationSeed(
                itemProviderCount:
                    itemProviderCount,
                supportedProviderCount:
                    supportedProviderCount,
                providerIndex: index,
                requestedTypeIdentifier:
                    UTType.image.identifier,
                preferredRegisteredTypeIdentifier:
                    preferredStaticImageTypeIdentifier
                    ?? UTType.image.identifier
            )

        let fileLoadResult =
            await loadFileRepresentationResult(
                from: provider,
                requestID: requestID,
                index: index,
                diagnosticsSeed:
                    staticDiagnosticsSeed
            )

        if let importRecord =
            fileLoadResult.importRecord {
            return outcomeForImportedRecord(
                importRecord,
                livePhotoTypeIdentifier:
                    livePhotoTypeIdentifier,
                requestID: requestID,
                index: index,
                diagnosticsSeed:
                    staticDiagnosticsSeed,
                seenSourceKeys:
                    &seenSourceKeys
            )
        }

        if let failureContext =
            fileLoadResult.failureContext,
           firstLoadFailureContext == nil {
            firstLoadFailureContext =
                failureContext
        }

        let inPlaceLoadResult =
            await loadInPlaceFileRepresentationResult(
                from: provider,
                requestID: requestID,
                index: index,
                diagnosticsSeed:
                    staticDiagnosticsSeed
            )

        if let importRecord =
            inPlaceLoadResult.importRecord {
            return outcomeForImportedRecord(
                importRecord,
                livePhotoTypeIdentifier:
                    livePhotoTypeIdentifier,
                requestID: requestID,
                index: index,
                diagnosticsSeed:
                    staticDiagnosticsSeed,
                seenSourceKeys:
                    &seenSourceKeys
            )
        }

        if let failureContext =
            inPlaceLoadResult.failureContext,
           firstLoadFailureContext == nil {
            firstLoadFailureContext =
                failureContext
        }

        let fallbackResult =
            await loadFallbackItem(
                from: provider,
                requestID: requestID,
                index: index,
                diagnosticsSeed:
                    staticDiagnosticsSeed
            )

        if case .failed(let failureContext) =
            fallbackResult {
            return .failed(
                failureContext
            )
        }

        if case .imported(let imported) =
            fallbackResult {
            return outcomeForImportedRecord(
                imported,
                livePhotoTypeIdentifier:
                    livePhotoTypeIdentifier,
                requestID: requestID,
                index: index,
                diagnosticsSeed:
                    staticDiagnosticsSeed,
                seenSourceKeys:
                    &seenSourceKeys
            )
        }

        if let failureContext =
            firstLoadFailureContext {
            return .failed(
                failureContext
            )
        }

        let error =
            MemoMarkShareIntakeDiagnosticError
            .make(
                description:
                    "Share intake finished without a loadable file or fallback item.",
                code: 1006
            )

        return .failed(
            diagnosticsSeed
            .failureContext(
                stage: .completion,
                operation:
                    "loadManagedURL.noLoadableResult",
                error: error
            )
        )
    }
}

private extension ShareManagedFileImporter {

    func loadLivePhotoObjectRepresentationResult(
        from provider: NSItemProvider,
        requestID: UUID,
        index: Int,
        diagnosticsSeed:
            MemoMarkShareIntakeOperationSeed,
        requestedTypeIdentifier: String
    ) async -> FileRepresentationLoadResult {

        let livePhotoObjectClass:
            NSItemProviderReading.Type =
            PHLivePhoto.self

        guard provider.canLoadObject(
            ofClass: livePhotoObjectClass
        ) else {
            let error =
                MemoMarkShareIntakeDiagnosticError
                .make(
                    description:
                        "The provider advertised a Live Photo but does not expose a PHLivePhoto object representation.",
                    code: 3014
                )
            let failureContext =
                diagnosticsSeed
                .failureContext(
                    stage: .load,
                    operation:
                        "loadObject(PHLivePhoto).unsupported",
                    error: error
                )
            MemoMarkShareDiagnostics.record(
                stage:
                    .extensionLivePhotoRepresentationProbe,
                message:
                    MemoMarkShareLivePhotoRepresentationProbe
                    .message(
                        operation:
                            "loadObject(PHLivePhoto)",
                        providerIndex: index,
                        typeIdentifier:
                            requestedTypeIdentifier,
                        resultDescription:
                            "supported=false",
                        url: nil,
                        error: error
                    ),
                requestID: requestID
            )
            return FileRepresentationLoadResult(
                importRecord: nil,
                failureContext: failureContext
            )
        }

        let suggestedName = provider.suggestedName

        return await withCheckedContinuation {
            (
                continuation:
                    CheckedContinuation<
                        FileRepresentationLoadResult,
                        Never
                    >
            ) in

            let timeoutTask =
                ShareProviderTimeoutTask()
            // The provider may call its completion more than once. That is a
            // different concern from the final result: materializing the
            // PHLivePhoto resources is asynchronous and must remain covered
            // by the same timeout as the provider request.
            let providerResponseGate =
                ShareProviderCompletionGate()
            let completionGate =
                ShareProviderCompletionGate()
            let materializationTask =
                ShareProviderTimeoutTask()
            let progress =
                provider.loadObject(
                ofClass: livePhotoObjectClass
            ) { [materializer] object, error in
                guard providerResponseGate.claim(),
                      !completionGate.hasBeenClaimed()
                else {
                    return
                }

                if let error {
                    guard completionGate.claim() else {
                        return
                    }
                    let wrappedError =
                        MemoMarkShareIntakeDiagnosticError
                        .make(
                            description:
                                "loadObject(PHLivePhoto) returned an error.",
                            code: 3015,
                            underlyingError: error
                        )
                    let failureContext =
                        diagnosticsSeed
                        .failureContext(
                            stage: .load,
                            operation:
                                "loadObject(PHLivePhoto)",
                            error: wrappedError
                        )
                    MemoMarkShareDiagnostics.record(
                        stage:
                            .extensionLivePhotoRepresentationProbe,
                        message:
                            MemoMarkShareLivePhotoRepresentationProbe
                            .message(
                                operation:
                                    "loadObject(PHLivePhoto)",
                                providerIndex: index,
                                typeIdentifier:
                                    requestedTypeIdentifier,
                                url: nil,
                                error: error
                            ),
                        requestID: requestID
                    )
                    timeoutTask.cancel()
                    continuation.resume(
                        returning:
                            FileRepresentationLoadResult(
                                importRecord: nil,
                                failureContext: failureContext
                            )
                    )
                    return
                }

                guard let livePhoto =
                    object as? PHLivePhoto else {
                    guard completionGate.claim() else {
                        return
                    }
                    let failureContext =
                        diagnosticsSeed
                        .failureContext(
                            stage: .load,
                            operation:
                                "loadObject(PHLivePhoto).missingObject",
                            error:
                                MemoMarkShareIntakeDiagnosticError
                                .make(
                                    description:
                                        "loadObject(PHLivePhoto) completed without an object.",
                                    code: 3016
                                )
                        )
                    timeoutTask.cancel()
                    continuation.resume(
                        returning:
                            FileRepresentationLoadResult(
                                importRecord: nil,
                                failureContext: failureContext
                            )
                    )
                    return
                }

                let resourceTask = Task { @MainActor in
                    let result =
                        await materializer
                        .materializeLivePhotoObject(
                            livePhoto,
                            requestID: requestID,
                            index: index,
                            preferredName: suggestedName,
                            diagnosticsSeed: diagnosticsSeed
                        )
                    guard completionGate.claim() else {
                        return
                    }
                    timeoutTask.cancel()
                    continuation.resume(
                        returning: result
                    )
                }
                materializationTask.install(
                    resourceTask
                )
            }

            let timeoutWork = Task {
                try? await Task.sleep(
                    nanoseconds:
                        providerLoadTimeoutNanoseconds
                )
                guard !Task.isCancelled else {
                    return
                }
                guard completionGate.claim() else {
                    return
                }

                progress.cancel()
                materializationTask.cancel()
                let failureContext =
                    diagnosticsSeed
                    .failureContext(
                        stage: .load,
                        operation:
                            "loadObject(PHLivePhoto).timeout",
                        supportID:
                            ProductionDiagnosticSupportID
                            .make(
                                prefix: "SHR",
                                operationID: requestID
                            ),
                        error:
                            MemoMarkShareIntakeDiagnosticError
                            .make(
                                description:
                                    "The source app did not provide the Live Photo object within 15 seconds.",
                                code: 3017
                            )
                    )
                MemoMarkShareDiagnostics.record(
                    stage:
                        .extensionProviderLoadTimedOut,
                    message:
                        "operation=loadObject(PHLivePhoto), providerIndex=\(index), requestedType=\(requestedTypeIdentifier)",
                    requestID: requestID
                )
                continuation.resume(
                    returning:
                        FileRepresentationLoadResult(
                            importRecord: nil,
                            failureContext: failureContext
                        )
                )
            }
            timeoutTask.install(timeoutWork)
        }
    }

    func outcomeForImportedRecord(
        _ importRecord: ManagedImportRecord,
        livePhotoTypeIdentifier: String?,
        requestID: UUID,
        index: Int,
        diagnosticsSeed:
            MemoMarkShareIntakeOperationSeed,
        seenSourceKeys: inout Set<String>
    ) -> ManagedImportOutcome {

        let resolvedImportRecord =
            recoverLivePhotoStaticPayloadIfNeeded(
                importRecord,
                livePhotoTypeIdentifier:
                    livePhotoTypeIdentifier,
                requestID: requestID,
                index: index
            )

        if let unsupportedOutcome =
            unsupportedManagedImportOutcomeIfNeeded(
                resolvedImportRecord,
                diagnosticsSeed:
                    diagnosticsSeed
            ) {
            return unsupportedOutcome
        }

        let sourceKey =
            resolvedImportRecord.dedupeKey

        guard seenSourceKeys.insert(sourceKey)
            .inserted else {
            intakeStore
                .cleanupManagedSourceIfNeeded(
                    at: resolvedImportRecord.managedURL
                )
            return .skippedDuplicate
        }

        return .imported(
            resolvedImportRecord
        )
    }

    func recoverLivePhotoStaticPayloadIfNeeded(
        _ importRecord: ManagedImportRecord,
        livePhotoTypeIdentifier: String?,
        requestID: UUID,
        index: Int
    ) -> ManagedImportRecord {

        guard let livePhotoTypeIdentifier else {
            return importRecord
        }

        return livePhotoRecovery
            .recordStaticLivePhotoPayloadIfNeeded(
                importRecord,
                requestedTypeIdentifier:
                    livePhotoTypeIdentifier,
                requestID: requestID,
                index: index
            )
    }

    func loadFileRepresentationResult(
        from provider: NSItemProvider,
        requestID: UUID,
        index: Int,
        diagnosticsSeed:
            MemoMarkShareIntakeOperationSeed,
        requestedTypeIdentifier: String =
            UTType.image.identifier,
        allowsDirectoryPackage: Bool = false
    ) async -> FileRepresentationLoadResult {

        ShareIntakeDiagnostics.notice(
            "Provider[\(diagnosticsSeed.providerIndex ?? -1)] loadFileRepresentation start for \(requestedTypeIdentifier)"
        )

        let suggestedName =
            provider.suggestedName

        return await withCheckedContinuation {
            (
                continuation:
                    CheckedContinuation<
                        FileRepresentationLoadResult,
                        Never
                    >
            ) in

            let timeoutTask =
                ShareProviderTimeoutTask()
            let gate =
                ShareProviderCompletionGate()
            let progress =
                provider.loadFileRepresentation(
                forTypeIdentifier:
                    requestedTypeIdentifier
            ) { [materializer] url, error in
                guard gate.claim() else {
                    return
                }

                if let error {
                    MemoMarkShareDiagnostics.record(
                        stage:
                            .extensionLivePhotoRepresentationProbe,
                        message:
                            MemoMarkShareLivePhotoRepresentationProbe
                            .message(
                                operation:
                                    "loadFileRepresentation",
                                providerIndex: index,
                                typeIdentifier:
                                    requestedTypeIdentifier,
                                url: nil,
                                error: error
                            ),
                        requestID: requestID
                    )

                    let wrappedError =
                        MemoMarkShareIntakeDiagnosticError
                        .make(
                            description:
                                "loadFileRepresentation returned an error.",
                            code: 3001,
                            underlyingError: error
                        )
                    let failureContext =
                        diagnosticsSeed
                        .failureContext(
                            stage: .load,
                            operation:
                                "loadFileRepresentation",
                            returnedURL:
                                url,
                            error:
                                wrappedError
                        )

                    ShareIntakeDiagnostics.error(
                        "Provider[\(diagnosticsSeed.providerIndex ?? -1)] loadFileRepresentation failed.\n\(failureContext.debugDescription)"
                    )

                    timeoutTask.cancel()
                    continuation.resume(
                        returning:
                            FileRepresentationLoadResult(
                                importRecord: nil,
                                failureContext:
                                    failureContext
                            )
                    )
                    return
                }

                guard let url else {
                    let failureContext =
                        diagnosticsSeed
                        .failureContext(
                            stage: .load,
                            operation:
                                "loadFileRepresentation.missingURL",
                            error:
                                MemoMarkShareIntakeDiagnosticError
                                .make(
                                    description:
                                        "loadFileRepresentation completed without returning a URL.",
                                    code: 3002
                                )
                        )

                    ShareIntakeDiagnostics.error(
                        "Provider[\(diagnosticsSeed.providerIndex ?? -1)] loadFileRepresentation returned nil URL.\n\(failureContext.debugDescription)"
                    )

                    timeoutTask.cancel()
                    continuation.resume(
                        returning:
                            FileRepresentationLoadResult(
                                importRecord: nil,
                                failureContext:
                                    failureContext
                            )
                    )
                    return
                }

                ShareIntakeDiagnostics.notice(
                    "Provider[\(diagnosticsSeed.providerIndex ?? -1)] loadFileRepresentation returned a file URL."
                )

                timeoutTask.cancel()
                continuation.resume(
                    returning:
                        materializer
                        .materializeFileURL(
                            url,
                            requestID: requestID,
                            index: index,
                            preferredName: suggestedName,
                            diagnosticsSeed: diagnosticsSeed,
                            requiresReadableImage:
                                !allowsDirectoryPackage,
                            dedupeKey:
                                url
                                .standardizedFileURL
                                .path,
                            copyDiagnosticPrefix: "",
                            missingManagedURLOperation:
                                "loadFileRepresentation.copyURL.missingManagedURL",
                            missingManagedURLDescription:
                                "File representation copy did not produce a managed URL.",
                            missingManagedURLErrorCode: 3007
                        )
                )
            }

            let task = Task {
                try? await Task.sleep(
                    nanoseconds:
                        providerLoadTimeoutNanoseconds
                )
                guard !Task.isCancelled else {
                    return
                }
                guard gate.claim() else {
                    return
                }

                progress.cancel()
                let failureContext =
                    diagnosticsSeed
                    .failureContext(
                        stage: .load,
                        operation:
                            "loadFileRepresentation.timeout",
                        supportID:
                            ProductionDiagnosticSupportID
                            .make(
                                prefix: "SHR",
                                operationID: requestID
                            ),
                        error:
                            MemoMarkShareIntakeDiagnosticError
                            .make(
                                description:
                                    "The source app did not provide the photo within 15 seconds.",
                                code: 3010
                            )
                    )
                MemoMarkShareDiagnostics.record(
                    stage:
                        .extensionProviderLoadTimedOut,
                    message:
                        "operation=loadFileRepresentation, providerIndex=\(index), requestedType=\(requestedTypeIdentifier)",
                    requestID: requestID
                )
                continuation.resume(
                    returning:
                        FileRepresentationLoadResult(
                            importRecord: nil,
                            failureContext:
                                failureContext
                        )
                )
            }
            timeoutTask.install(task)
        }
    }

    func loadInPlaceFileRepresentationResult(
        from provider: NSItemProvider,
        requestID: UUID,
        index: Int,
        diagnosticsSeed:
            MemoMarkShareIntakeOperationSeed,
        requestedTypeIdentifier: String =
            UTType.image.identifier,
        allowsDirectoryPackage: Bool = false
    ) async -> FileRepresentationLoadResult {

        ShareIntakeDiagnostics.notice(
            "Provider[\(diagnosticsSeed.providerIndex ?? -1)] loadInPlaceFileRepresentation start for \(requestedTypeIdentifier)"
        )

        let suggestedName =
            provider.suggestedName

        return await withCheckedContinuation {
            (
                continuation:
                    CheckedContinuation<
                        FileRepresentationLoadResult,
                        Never
                    >
            ) in

            let timeoutTask =
                ShareProviderTimeoutTask()
            let gate =
                ShareProviderCompletionGate()
            let progress =
                provider.loadInPlaceFileRepresentation(
                    forTypeIdentifier:
                        requestedTypeIdentifier
                ) { [materializer] url, isInPlace, error in
                    MemoMarkShareDiagnostics.record(
                        stage:
                            .extensionLivePhotoRepresentationProbe,
                        message:
                            MemoMarkShareLivePhotoRepresentationProbe
                            .message(
                                operation:
                                    "loadInPlaceFileRepresentation",
                                providerIndex: index,
                                typeIdentifier:
                                    requestedTypeIdentifier,
                                resultDescription:
                                    "isInPlace=\(isInPlace)",
                                url: url,
                                error: error
                            ),
                        requestID: requestID
                    )

                    guard gate.claim() else {
                        return
                    }

                    if let error {
                        let wrappedError =
                            MemoMarkShareIntakeDiagnosticError
                            .make(
                                description:
                                    "loadInPlaceFileRepresentation returned an error.",
                                code: 3012,
                                underlyingError: error
                            )
                        let failureContext =
                            diagnosticsSeed
                            .failureContext(
                                stage: .load,
                                operation:
                                    "loadInPlaceFileRepresentation",
                                returnedURL:
                                    url,
                                error:
                                    wrappedError
                            )

                        ShareIntakeDiagnostics.error(
                            "Provider[\(diagnosticsSeed.providerIndex ?? -1)] loadInPlaceFileRepresentation failed.\n\(failureContext.debugDescription)"
                        )

                        timeoutTask.cancel()
                        continuation.resume(
                            returning:
                                FileRepresentationLoadResult(
                                    importRecord: nil,
                                    failureContext:
                                        failureContext
                                )
                        )
                        return
                    }

                    guard let url else {
                        let failureContext =
                            diagnosticsSeed
                            .failureContext(
                                stage: .load,
                                operation:
                                    "loadInPlaceFileRepresentation.missingURL",
                                error:
                                    MemoMarkShareIntakeDiagnosticError
                                    .make(
                                        description:
                                            "loadInPlaceFileRepresentation completed without returning a URL.",
                                        code: 3013
                                    )
                            )

                        ShareIntakeDiagnostics.error(
                            "Provider[\(diagnosticsSeed.providerIndex ?? -1)] loadInPlaceFileRepresentation returned nil URL.\n\(failureContext.debugDescription)"
                        )

                        timeoutTask.cancel()
                        continuation.resume(
                            returning:
                                FileRepresentationLoadResult(
                                    importRecord: nil,
                                    failureContext:
                                        failureContext
                                )
                        )
                        return
                    }

                    let normalizedURL =
                        url.standardizedFileURL
                    ShareIntakeDiagnostics.notice(
                        "Provider[\(diagnosticsSeed.providerIndex ?? -1)] loadInPlaceFileRepresentation returned a file URL. isInPlace=\(isInPlace)"
                    )

                    timeoutTask.cancel()
                    continuation.resume(
                        returning:
                            materializer
                            .materializeFileURL(
                                normalizedURL,
                                requestID: requestID,
                                index: index,
                                preferredName: suggestedName,
                                diagnosticsSeed: diagnosticsSeed,
                                requiresReadableImage:
                                    !allowsDirectoryPackage,
                                dedupeKey:
                                    "inPlace:\(normalizedURL.path)",
                                copyDiagnosticPrefix: "inPlace",
                                missingManagedURLOperation:
                                    "loadInPlaceFileRepresentation.copyURL.missingManagedURL",
                                missingManagedURLDescription:
                                    "In-place file representation copy did not produce a managed URL.",
                                missingManagedURLErrorCode: 3014
                            )
                    )
                }

            let task = Task {
                try? await Task.sleep(
                    nanoseconds:
                        providerLoadTimeoutNanoseconds
                )
                guard !Task.isCancelled else {
                    return
                }
                guard gate.claim() else {
                    return
                }

                progress.cancel()
                let failureContext =
                    diagnosticsSeed
                    .failureContext(
                        stage: .load,
                        operation:
                            "loadInPlaceFileRepresentation.timeout",
                        supportID:
                            ProductionDiagnosticSupportID
                            .make(
                                prefix: "SHR",
                                operationID: requestID
                            ),
                        error:
                            MemoMarkShareIntakeDiagnosticError
                            .make(
                                description:
                                    "The source app did not provide the in-place photo within 15 seconds.",
                                code: 3015
                            )
                    )
                MemoMarkShareDiagnostics.record(
                    stage:
                        .extensionProviderLoadTimedOut,
                    message:
                        "operation=loadInPlaceFileRepresentation, providerIndex=\(index), requestedType=\(requestedTypeIdentifier)",
                    requestID: requestID
                )
                continuation.resume(
                    returning:
                        FileRepresentationLoadResult(
                            importRecord: nil,
                            failureContext:
                                failureContext
                        )
                )
            }
            timeoutTask.install(task)
        }
    }

    func loadFallbackItem(
        from provider: NSItemProvider,
        requestID: UUID,
        index: Int,
        diagnosticsSeed:
            MemoMarkShareIntakeOperationSeed
    ) async -> ManagedImportOutcome {

        let suggestedName =
            provider.suggestedName

        let preferredExtension =
            providerLoader
            .preferredFileExtension(
                from:
                    provider
                    .registeredTypeIdentifiers
            )

        ShareIntakeDiagnostics.notice(
            "Provider[\(index)] loadItem start for \(UTType.image.identifier)"
        )

        return await withCheckedContinuation {
            (
                continuation:
                    CheckedContinuation<
                        ManagedImportOutcome,
                        Never
                    >
            ) in

            let timeoutTask =
                ShareProviderTimeoutTask()
            let gate =
                ShareProviderCompletionGate()
            provider.loadItem(
                forTypeIdentifier:
                    UTType.image.identifier,
                options: nil
            ) { [materializer] item, error in
                guard gate.claim() else {
                    return
                }

                if let error {
                    let wrappedError =
                        MemoMarkShareIntakeDiagnosticError
                        .make(
                            description:
                                "Fallback loadItem returned an error.",
                            code: 3003,
                            underlyingError: error
                        )

                    let failureContext =
                        diagnosticsSeed
                        .failureContext(
                            stage: .load,
                            operation:
                                "loadItem",
                            error:
                                wrappedError
                        )

                    ShareIntakeDiagnostics.error(
                        "Provider[\(index)] loadItem failed.\n\(failureContext.debugDescription)"
                    )

                    timeoutTask.cancel()
                    continuation.resume(
                        returning:
                            .failed(
                                failureContext
                            )
                    )
                    return
                }

                if let url = item as? URL {
                    let normalizedURL =
                        url.standardizedFileURL

                    MemoMarkShareDiagnostics.record(
                        stage:
                            .extensionLivePhotoRepresentationProbe,
                        message:
                            MemoMarkShareLivePhotoRepresentationProbe
                            .message(
                                operation: "loadItem",
                                providerIndex: index,
                                typeIdentifier:
                                    UTType.image.identifier,
                                resultDescription:
                                    "itemClass=URL",
                                url: normalizedURL,
                                error: nil
                            ),
                        requestID: requestID
                    )

                    ShareIntakeDiagnostics.notice(
                        "Provider[\(index)] loadItem returned a file URL."
                    )

                    let materialization =
                        materializer
                        .materializeFileURL(
                            normalizedURL,
                            requestID: requestID,
                            index: index,
                            preferredName: suggestedName,
                            diagnosticsSeed: diagnosticsSeed,
                            dedupeKey:
                                "url:\(normalizedURL.path)",
                            copyDiagnosticPrefix: "fallback",
                            missingManagedURLOperation:
                                "loadItem.copyURL.missingManagedURL",
                            missingManagedURLDescription:
                                "Fallback URL copy did not produce a managed URL.",
                            missingManagedURLErrorCode: 3004
                        )
                    timeoutTask.cancel()
                    continuation.resume(
                        returning:
                            Self.fallbackOutcome(
                                from: materialization
                            )
                    )
                    return
                }

                if let data = item as? Data {
                    MemoMarkShareDiagnostics.record(
                        stage:
                            .extensionLivePhotoRepresentationProbe,
                        message:
                            MemoMarkShareLivePhotoRepresentationProbe
                            .message(
                                operation: "loadItem",
                                providerIndex: index,
                                typeIdentifier:
                                    UTType.image.identifier,
                                resultDescription:
                                    "itemClass=Data, bytes=\(data.count)",
                                url: nil,
                                error: nil
                            ),
                        requestID: requestID
                    )

                    ShareIntakeDiagnostics.notice(
                        "Provider[\(index)] loadItem returnedDataBytes=\(data.count)"
                    )

                    let materialization =
                        materializer
                        .materializeData(
                            data,
                            requestID: requestID,
                            index: index,
                            preferredFileExtension:
                                preferredExtension,
                            preferredBaseName:
                                suggestedName,
                            diagnosticsSeed:
                                diagnosticsSeed
                        )
                    timeoutTask.cancel()
                    continuation.resume(
                        returning:
                            Self.fallbackOutcome(
                                from: materialization
                            )
                    )
                    return
                }

                let payloadClassDescription =
                    item.map {
                        "itemClass=\(String(reflecting: type(of: $0)))"
                    } ?? "itemClass=nil"

                MemoMarkShareDiagnostics.record(
                    stage:
                        .extensionLivePhotoRepresentationProbe,
                    message:
                        MemoMarkShareLivePhotoRepresentationProbe
                        .message(
                            operation: "loadItem",
                            providerIndex: index,
                            typeIdentifier:
                                UTType.image.identifier,
                            resultDescription:
                                payloadClassDescription,
                            url: nil,
                            error: nil
                        ),
                    requestID: requestID
                )

                let failureContext =
                    diagnosticsSeed
                    .failureContext(
                        stage: .load,
                        operation:
                            "loadItem.unsupportedPayload",
                        error:
                            MemoMarkShareIntakeDiagnosticError
                            .make(
                                description:
                                    "Fallback loadItem returned an unsupported payload type.",
                                code: 3006
                            )
                    )

                ShareIntakeDiagnostics.error(
                    "Provider[\(index)] loadItem returned unsupported payload.\n\(failureContext.debugDescription)"
                )

                timeoutTask.cancel()
                continuation.resume(
                    returning:
                        .failed(
                            failureContext
                        )
                )
            }

            let task = Task {
                try? await Task.sleep(
                    nanoseconds:
                        providerLoadTimeoutNanoseconds
                )
                guard !Task.isCancelled else {
                    return
                }
                guard gate.claim() else {
                    return
                }

                let failureContext =
                    diagnosticsSeed
                    .failureContext(
                        stage: .load,
                        operation:
                            "loadItem.timeout",
                        supportID:
                            ProductionDiagnosticSupportID
                            .make(
                                prefix: "SHR",
                                operationID: requestID
                            ),
                        error:
                            MemoMarkShareIntakeDiagnosticError
                            .make(
                                description:
                                    "The source app did not provide the photo within 15 seconds.",
                                code: 3011
                            )
                    )
                MemoMarkShareDiagnostics.record(
                    stage:
                        .extensionProviderLoadTimedOut,
                    message:
                        "operation=loadItem, providerIndex=\(index), requestedType=\(UTType.image.identifier)",
                    requestID: requestID
                )
                continuation.resume(
                    returning:
                        .failed(
                            failureContext
                        )
                )
            }
            timeoutTask.install(task)
        }
    }

    nonisolated static
    func fallbackOutcome(
        from materialization:
            FileRepresentationLoadResult
    ) -> ManagedImportOutcome {

        if let importRecord =
            materialization.importRecord {
            return .imported(importRecord)
        }

        if let failureContext =
            materialization.failureContext {
            return .failed(failureContext)
        }

        preconditionFailure(
            "Managed import materialization must return an import record or failure context."
        )
    }

    func unsupportedManagedImportOutcomeIfNeeded(
        _ importRecord: ManagedImportRecord,
        diagnosticsSeed:
            MemoMarkShareIntakeOperationSeed
    ) -> ManagedImportOutcome? {

        let verdict =
            PhotoProcessingInputPolicy(
                allowsLivePhoto: true
            )
            .verdict(
                fileURL:
                    importRecord.managedURL,
                declaredContentTypeIdentifier:
                    importRecord.item
                    .contentTypeIdentifier
            )

        guard !verdict.isSupported else {
            return nil
        }

        intakeStore.cleanupManagedSourceIfNeeded(
            at: importRecord.managedURL
        )

        ShareIntakeDiagnostics.notice(
            """
            Provider[\(diagnosticsSeed.providerIndex ?? -1)] skipped unsupported photo.
            reason=\(verdict.reason?.rawValue ?? "unknown")
            title=\(verdict.title)
            message=\(verdict.message)
            """
        )

        let rejectionReport =
            MemoMarkMediaIntakeRejectionReport(
                verdict: verdict,
                fileName:
                    importRecord
                    .managedURL
                    .lastPathComponent,
                contentTypeIdentifier:
                    importRecord.item
                    .contentTypeIdentifier,
                pixelSize:
                    MediaPixelSize(
                        fileURL:
                            importRecord
                            .managedURL
                    )
            )

        return .skippedUnsupported(
            rejectionReport
        )
    }

}
#endif
