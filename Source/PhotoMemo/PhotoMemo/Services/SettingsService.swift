import Foundation
import Combine

@MainActor
final class SettingsService: ObservableObject {

    private enum Keys {

        static let anchors = "photomemo.anchors"

        static let selectedTemplate = "photomemo.selectedTemplate"

        static let selectedBadge = "photomemo.selectedBadge"
    }

    @Published var anchors: [Anchor] = []

    @Published var selectedTemplate: Template?

    @Published var selectedBadge: Badge?

    init() {

        loadAnchors()

        loadTemplate()

        loadBadge()
    }

    func saveAnchors() {

        guard let data = try? JSONEncoder().encode(anchors) else {
            return
        }

        UserDefaults.standard.set(
            data,
            forKey: Keys.anchors
        )
    }

    func saveTemplate() {

        guard let selectedTemplate else {
            return
        }

        guard let data = try? JSONEncoder().encode(selectedTemplate) else {
            return
        }

        UserDefaults.standard.set(
            data,
            forKey: Keys.selectedTemplate
        )
    }

    func saveBadge() {

        guard let selectedBadge else {
            return
        }

        guard let data = try? JSONEncoder().encode(selectedBadge) else {
            return
        }

        UserDefaults.standard.set(
            data,
            forKey: Keys.selectedBadge
        )
    }

    private func loadAnchors() {

        guard
            let data = UserDefaults.standard.data(
                forKey: Keys.anchors
            )
        else {
            return
        }

        anchors =
            (try? JSONDecoder().decode(
                [Anchor].self,
                from: data
            )) ?? []
    }

    private func loadTemplate() {

        guard
            let data = UserDefaults.standard.data(
                forKey: Keys.selectedTemplate
            )
        else {
            return
        }

        selectedTemplate =
            try? JSONDecoder().decode(
                Template.self,
                from: data
            )
    }

    private func loadBadge() {

        guard
            let data = UserDefaults.standard.data(
                forKey: Keys.selectedBadge
            )
        else {
            return
        }

        selectedBadge =
            try? JSONDecoder().decode(
                Badge.self,
                from: data
            )
    }
}
