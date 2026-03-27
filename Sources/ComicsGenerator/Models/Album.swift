import Foundation

/// Temporary stub for Album model (to be fully implemented in future feature)
public struct Album: Codable, Identifiable {
    public let id: UUID
    public let name: String
    public let pages: [Page]

    public init(id: UUID = UUID(), name: String, pages: [Page] = []) {
        self.id = id
        self.name = name
        self.pages = pages
    }
}

/// Temporary stub for Page model (to be fully implemented in future feature)
public struct Page: Codable, Identifiable {
    public let id: UUID
    public let layout: PageLayout?
    public let drawings: [Drawing]

    public init(id: UUID = UUID(), layout: PageLayout? = nil, drawings: [Drawing] = []) {
        self.id = id
        self.layout = layout
        self.drawings = drawings
    }
}

/// Temporary stub for PageLayout
public struct PageLayout: Codable {
    public let bounds: CGRect
    public let polygons: [[CGPoint]]

    public init(bounds: CGRect = CGRect(x: 0, y: 0, width: 800, height: 600), polygons: [[CGPoint]] = []) {
        self.bounds = bounds
        self.polygons = polygons
    }
}

/// Temporary stub for Drawing
public struct Drawing: Codable, Identifiable {
    public let id: UUID

    public init(id: UUID = UUID()) {
        self.id = id
    }
}
