import Testing
@testable import PhotoMemo

@Suite("Media pipeline runtime gate")
struct MediaPipelineRuntimeGateTests {

    @Test("Default gate keeps VNext unavailable to production runtime")
    func defaultGateKeepsVNextUnavailableToProductionRuntime() {
        let gate =
            MediaPipelineRuntimeGate.defaultOff

        #expect(gate.mode == .disabled)
        #expect(gate.permitsPlanning(for: .livePhoto) == false)
        #expect(gate.permitsUserVisibleOutputControls == false)
        #expect(gate.permitsPhotoLibraryWrites == false)
    }

    @Test("Shadow gate is observational and discards outputs")
    func shadowGateIsObservationalAndDiscardsOutputs() {
        let gate =
            MediaPipelineRuntimeGate.shadow

        #expect(gate.mode == .shadow)
        #expect(gate.permitsPlanning(for: .livePhoto))
        #expect(gate.requiresDiscardedOutputs)
        #expect(gate.permitsUserVisibleOutputControls == false)
        #expect(gate.permitsPhotoLibraryWrites == false)
    }

    @Test("Internal testing gate can expose Live Photo without enabling Photo Library writes by default")
    func internalTestingGateCanExposeLivePhotoWithoutPhotoLibraryWritesByDefault() {
        let gate =
            MediaPipelineRuntimeGate.internalTesting(
                allowedRoutes: [.stillImage, .livePhoto],
                exposesUserVisibleOutputControls: true,
                permitsPhotoLibraryWrites: false
            )

        #expect(gate.mode == .internalTesting)
        #expect(gate.permitsPlanning(for: .livePhoto))
        #expect(gate.permitsPlanning(for: .rawStillImage) == false)
        #expect(gate.permitsUserVisibleOutputControls)
        #expect(gate.permitsPhotoLibraryWrites == false)
    }
}
