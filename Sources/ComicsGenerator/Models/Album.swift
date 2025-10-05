import Foundation

/// Temporary stub for Album model (to be fully implemented in future feature)
struct Album: Codable, Identifiable {
    let id: UUID
    let name: String
    let pages: [Page]

    init(id: UUID = UUID(), name: String, pages: [Page] = []) {
        self.id = id
        self.name = name
        self.pages = pages
    }
}

/// Temporary stub for Page model (to be fully implemented in future feature)
struct Page: Codable, Identifiable {
    let id: UUID
    let layout: PageLayout?
    let drawings: [Drawing]

    init(id: UUID = UUID(), layout: PageLayout? = nil, drawings: [Drawing] = []) {
        self.id = id
        self.layout = layout
        self.drawings = drawings
    }
}

/// Temporary stub for PageLayout
struct PageLayout: Codable {
    let bounds: CGRect

    init(bounds: CGRect = CGRect(x: 0, y: 0, width: 800, height: 600)) {
        self.bounds = bounds
    }
}

/// Temporary stub for Drawing
struct Drawing: Codable, Identifiable {
    let id: UUID

    init(id: UUID = UUID()) {
        self.id = id
    }
}
