import Combine
import Foundation

// MARK: - Memory Controller

@Observable
final class MemoryController: MemoryControlling {
    private let repository: MemoryRepositoring
    private var cancellables = Set<AnyCancellable>()

    // Observable property for SwiftUI
    private(set) var memories: [Memory] = []

    init(repository: MemoryRepositoring) {
        self.repository = repository
    }

    // MARK: - MemoryControlling Implementation

    func addMemory(_ memory: Memory) async throws {
        try await repository.save(memory)
    }

    func getMemories() async -> [Memory] {
        await repository.getAll()
    }

    func getRecentMemories(limit: Int) async -> [Memory] {
        await repository.getRecent(limit: limit)
    }

    func clearMemories() async throws {
        try await repository.deleteAll()
    }

    func observeMemories() -> AnyPublisher<[Memory], Never> {
        repository.observeChanges()
            .asyncMap { [weak self] _ in
                await self?.repository.getAll() ?? []
            }
            .replaceError(with: [])
            .eraseToAnyPublisher()
    }

    func getContextForAI(maxMessages: Int = 10) async -> String {
        let recentMemories = await getRecentMemories(limit: maxMessages)
        return recentMemories
            .map { $0.formattedContent }
            .joined(separator: "\n")
    }
}
