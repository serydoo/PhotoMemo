#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct MemoryConfigurationRecord:
    Identifiable,
    Codable,
    Hashable {

    struct Editor:
        Codable,
        Hashable {

        private struct RegionBinding:
            Codable {

            let region: CardRegion
            let templateID: String
        }

        struct MemoryCopy:
            Codable,
            Hashable {

            var usesCustomText: Bool
            var customText: String
        }

        var template: Template
        var regionTemplateIDs: [CardRegion: String]
        var memoryCopy: MemoryCopy

        private enum CodingKeys:
            String,
            CodingKey {

            case template
            case regionTemplateIDs
            case memoryCopy
        }

        init(
            template: Template,
            regionTemplateIDs: [CardRegion: String],
            memoryCopy: MemoryCopy
        ) {
            self.template = template
            self.regionTemplateIDs = regionTemplateIDs
            self.memoryCopy = memoryCopy
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(
                keyedBy: CodingKeys.self
            )
            self.template = try container.decode(
                Template.self,
                forKey: .template
            )
            let bindings = try container.decode(
                [RegionBinding].self,
                forKey: .regionTemplateIDs
            )
            var seenRegions: Set<CardRegion> = []
            if let duplicate = bindings.first(where: {
                !seenRegions.insert($0.region).inserted
            }) {
                throw DecodingError.dataCorruptedError(
                    forKey: .regionTemplateIDs,
                    in: container,
                    debugDescription:
                        "Duplicate region binding: \(duplicate.region.rawValue)"
                )
            }
            self.regionTemplateIDs = bindings.reduce(
                into: [:]
            ) { result, binding in
                result[binding.region] =
                    binding.templateID
            }
            self.memoryCopy = try container.decode(
                MemoryCopy.self,
                forKey: .memoryCopy
            )
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(
                keyedBy: CodingKeys.self
            )
            try container.encode(
                template,
                forKey: .template
            )
            let bindings = regionTemplateIDs
                .map {
                    RegionBinding(
                        region: $0.key,
                        templateID: $0.value
                    )
                }
                .sorted {
                    $0.region.rawValue
                    < $1.region.rawValue
                }
            try container.encode(
                bindings,
                forKey: .regionTemplateIDs
            )
            try container.encode(
                memoryCopy,
                forKey: .memoryCopy
            )
        }
    }

    struct Presentation:
        Codable,
        Hashable {

        enum Route:
            String,
            Codable,
            Hashable {

            case classicWhite
        }

        struct Logo:
            Codable,
            Hashable {

            struct BadgeDescriptor:
                Codable,
                Hashable {

                let id: UUID
                var name: String
                var type: BadgeType
                var imageName: String?
                var systemSymbol: String?
                var isSystemDefault: Bool
                var assetReference:
                    PortableAssetReference?

                init(
                    id: UUID,
                    name: String,
                    type: BadgeType,
                    imageName: String? = nil,
                    systemSymbol: String? = nil,
                    isSystemDefault: Bool = false,
                    assetReference:
                        PortableAssetReference? = nil
                ) {
                    self.id = id
                    self.name = name
                    self.type = type
                    self.imageName = imageName
                    self.systemSymbol = systemSymbol
                    self.isSystemDefault = isSystemDefault
                    self.assetReference = assetReference
                }
            }

            var mode: V1LogoMode
            var badge: BadgeDescriptor?
        }

        var route: Route
        var locationConfiguration:
            ExpressionModuleConfiguration?
        var logo: Logo
    }

    struct Output:
        Codable,
        Hashable {

        enum LivePhotoPolicy:
            String,
            Codable,
            Hashable {

            case preserveMotion
            case staticImageOnly
        }

        struct PhotosDescriptionPolicy:
            Codable,
            Hashable {

            var isEnabled: Bool
            var overrideText: String
        }

        struct AlbumDescriptor:
            Codable,
            Hashable {

            enum Destination:
                String,
                Codable,
                Hashable {

                case automatic
                case applePhotos
                case existingAlbum
                case newAlbum
            }

            var destination: Destination
            var identifier: String
            var title: String

            static let automatic = AlbumDescriptor(
                destination: .automatic,
                identifier: "",
                title: ""
            )
        }

        var mediaMode: V1MediaOutputMode
        var livePhotoPolicy: LivePhotoPolicy
        var photosDescriptionPolicy:
            PhotosDescriptionPolicy
        var album: AlbumDescriptor
    }

    let id: UUID
    var title: String
    var revision: Int
    var savedAt: Date
    var selectedTimeAnchorID: UUID?
    var editor: Editor
    var presentation: Presentation
    var output: Output

    init(
        id: UUID = UUID(),
        title: String,
        revision: Int,
        savedAt: Date,
        selectedTimeAnchorID: UUID?,
        editor: Editor,
        presentation: Presentation,
        output: Output
    ) {
        self.id = id
        self.title = title
        self.revision = revision
        self.savedAt = savedAt
        self.selectedTimeAnchorID = selectedTimeAnchorID
        self.editor = editor
        self.presentation = presentation
        self.output = output
    }

    static func fallbackID(
        for subjectID: UUID
    ) -> UUID {
        deterministicUUID(
            basedOn: subjectID,
            discriminator: 0xF1
        )
    }

    static func isValidRevision(
        _ revision: Int
    ) -> Bool {
        revision >= 1 && revision < Int.max
    }

    private enum CodingKeys:
        String,
        CodingKey {

        case id
        case title
        case revision
        case savedAt
        case selectedTimeAnchorID
        case editor
        case presentation
        case output
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )
        self.id = try container.decode(
            UUID.self,
            forKey: .id
        )
        self.title = try container.decode(
            String.self,
            forKey: .title
        )
        let revision = try container.decode(
            Int.self,
            forKey: .revision
        )
        guard Self.isValidRevision(revision) else {
            throw DecodingError.dataCorruptedError(
                forKey: .revision,
                in: container,
                debugDescription:
                    "Configuration revision must be in 1..<Int.max"
            )
        }
        self.revision = revision
        self.savedAt = try container.decode(
            Date.self,
            forKey: .savedAt
        )
        self.selectedTimeAnchorID =
            try container.decodeIfPresent(
                UUID.self,
                forKey: .selectedTimeAnchorID
            )
        self.editor = try container.decode(
            Editor.self,
            forKey: .editor
        )
        self.presentation = try container.decode(
            Presentation.self,
            forKey: .presentation
        )
        self.output = try container.decode(
            Output.self,
            forKey: .output
        )
    }

    func encode(to encoder: Encoder) throws {
        guard Self.isValidRevision(revision) else {
            throw EncodingError.invalidValue(
                revision,
                .init(
                    codingPath: encoder.codingPath,
                    debugDescription:
                        "Configuration revision must be in 1..<Int.max"
                )
            )
        }
        var container = encoder.container(
            keyedBy: CodingKeys.self
        )
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(revision, forKey: .revision)
        try container.encode(savedAt, forKey: .savedAt)
        try container.encodeIfPresent(
            selectedTimeAnchorID,
            forKey: .selectedTimeAnchorID
        )
        try container.encode(editor, forKey: .editor)
        try container.encode(
            presentation,
            forKey: .presentation
        )
        try container.encode(output, forKey: .output)
    }
}

extension MemoryConfigurationRecord {

    static func deterministicUUID(
        basedOn baseID: UUID,
        discriminator: UInt8
    ) -> UUID {
        var bytes = baseID.uuid
        withUnsafeMutableBytes(of: &bytes) { buffer in
            buffer[0] ^= discriminator
            buffer[6] = (buffer[6] & 0x0F) | 0x50
            buffer[8] = (buffer[8] & 0x3F) | 0x80
        }
        return UUID(uuid: bytes)
    }
}
#endif
