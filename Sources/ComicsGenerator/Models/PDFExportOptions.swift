import Foundation

/// Configuration for PDF export operation
public struct PDFExportOptions: Codable {
    public let resolution: Int
    public let includeMetadata: Bool
    public let seriesName: String
    public let albumName: String
    public let pageRange: PageRange
    public let outputURL: URL

    public init(
        resolution: Int = 300,
        includeMetadata: Bool = true,
        seriesName: String,
        albumName: String,
        pageRange: PageRange = .all,
        outputURL: URL
    ) {
        // Validation: resolution must be 300 DPI (per FR-076)
        precondition(resolution == 300, "PDF resolution must be 300 DPI")

        // Validation: metadata must be included (per FR-075)
        precondition(includeMetadata == true, "PDF metadata must be included")

        // Validation: names must be non-empty and within length limits
        precondition(!seriesName.isEmpty && seriesName.count <= 200, "Series name must be 1-200 characters")
        precondition(!albumName.isEmpty && albumName.count <= 200, "Album name must be 1-200 characters")

        // Validation: output URL must be writable (basic check for valid path)
        precondition(!outputURL.path.isEmpty, "Output URL must be a valid file path")

        self.resolution = resolution
        self.includeMetadata = includeMetadata
        self.seriesName = seriesName
        self.albumName = albumName
        self.pageRange = pageRange
        self.outputURL = outputURL
    }
}

/// Range of pages to export (all pages or single page)
public enum PageRange: Codable, Equatable {
    case all
    case single(pageIndex: Int)

    // Custom Codable implementation to handle associated values
    enum CodingKeys: String, CodingKey {
        case type
        case pageIndex
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "all":
            self = .all
        case "single":
            let pageIndex = try container.decode(Int.self, forKey: .pageIndex)
            self = .single(pageIndex: pageIndex)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Invalid page range type: \(type)"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .all:
            try container.encode("all", forKey: .type)
        case .single(let pageIndex):
            try container.encode("single", forKey: .type)
            try container.encode(pageIndex, forKey: .pageIndex)
        }
    }
}
