import Foundation
import Testing
@testable import PhotoMemo

@Suite("Expression Module Configuration Contract")
struct ExpressionModuleConfigurationContractTests {

    @Test("Given token options When encoded and decoded Then module configuration is preserved")
    func givenTokenOptionsWhenEncodedAndDecodedThenModuleConfigurationIsPreserved() throws {
        let configuration =
            ExpressionModuleConfiguration(
                token: "location",
                options: [
                    "presentationMode": "provinceCity",
                    "fallback": "empty"
                ]
            )

        let data =
            try JSONEncoder()
            .encode(
                configuration
            )

        let decoded =
            try JSONDecoder()
            .decode(
                ExpressionModuleConfiguration.self,
                from: data
            )

        #expect(decoded == configuration)
        #expect(decoded.token == "location")
        #expect(decoded.options["presentationMode"] == "provinceCity")
        #expect(decoded.options["fallback"] == "empty")
    }

    @Test("Boundary Given module configuration source When inspected Then carrier is provider neutral")
    func boundaryGivenModuleConfigurationSourceWhenInspectedThenCarrierIsProviderNeutral() throws {
        let source =
            try String(
                contentsOfFile: "/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Expression/ExpressionModuleConfiguration.swift",
                encoding: .utf8
            )

        #expect(source.contains("ExpressionToken"))
        #expect(!source.contains("LocationPresentationMode"))
        #expect(!source.contains("LocationResolutionConfiguration"))
        #expect(!source.contains("LocationResolver"))
        #expect(!source.contains("LocationFormatter"))
        #expect(!source.contains("LocationExpressionProvider"))
    }

    @Test("Given legacy inserted module When created Then expression configuration is absent by default")
    func givenLegacyInsertedModuleWhenCreatedThenExpressionConfigurationIsAbsentByDefault() {
        let module =
            IOSInsertedModule(
                title: "位置",
                value: "河南 · 商丘",
                systemImage: "location.fill"
            )

        #expect(module.title == "位置")
        #expect(module.value == "河南 · 商丘")
        #expect(module.systemImage == "location.fill")
        #expect(module.expressionConfiguration == nil)
    }

    @Test("Given inserted module When configured Then provider neutral configuration travels with instance")
    func givenInsertedModuleWhenConfiguredThenProviderNeutralConfigurationTravelsWithInstance() {
        let configuration =
            ExpressionModuleConfiguration(
                token: "location",
                options: [
                    "presentationMode": "provinceCity"
                ]
            )

        let module =
            IOSInsertedModule(
                title: "位置",
                value: "河南 · 商丘",
                systemImage: "location.fill",
                expressionConfiguration: configuration
            )

        #expect(module.expressionConfiguration == configuration)
        #expect(module.expressionConfiguration?.token == "location")
        #expect(
            module.expressionConfiguration?
                .options["presentationMode"]
            == "provinceCity"
        )
    }
}
