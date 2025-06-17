import Foundation

// MARK: - Agent Model

struct Agent {
    let id: String
    let name: String
    let description: String

    static let masha: Self = .init(
        id: "w63wjugjg9aztG1H9JDa",
        name: "Masha",
        description: "AI Assistant"
    )
}
