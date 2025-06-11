import Combine
import Foundation

// MARK: - Memory Repository Protocol

protocol MemoryRepositoring {
    func save(_ memory: Memory) async throws
    func saveMultiple(_ memories: [Memory]) async throws
    func getAll() async -> [Memory]
    func getRecent(limit: Int) async -> [Memory]
    func deleteAll() async throws
    func observeChanges() -> AnyPublisher<Void, Never>
}

// MARK: - Memory Repository Implementation

final class MemoryRepository: MemoryRepositoring {
    private let databaseStorage: DatabaseStorage

    init(databaseStorage: DatabaseStorage) {
        self.databaseStorage = databaseStorage
    }

    func save(_ memory: Memory) async throws {
        try await saveMultiple([memory])
    }

    func saveMultiple(_ memories: [Memory]) async throws {
        let entities = memories.map { $0.toEntity() }

        try await databaseStorage.writeTransaction { context in
            context.add(entities)
        }
    }

    func getAll() async -> [Memory] {
        await databaseStorage.readTransaction { context in
            let sortParams = SortParams(keyPath: "timestamp", ascending: true)
            let entities = context.get(
                MemoryEntity.self,
                query: nil,
                sort: sortParams,
                while: { _ in true }
            )
            return entities.map { $0.toDomain() }
        }
    }

    func getRecent(limit: Int) async -> [Memory] {
        await databaseStorage.readTransaction { context in
            let sortParams = SortParams(keyPath: "timestamp", ascending: false)
            let entities = context.get(
                MemoryEntity.self,
                query: nil,
                sort: sortParams
            ) { _ in true }

            return Array(entities.prefix(limit))
                .map { $0.toDomain() }
                .reversed()  // Возвращаем в хронологическом порядке
        }
    }

    func deleteAll() async throws {
        try await databaseStorage.writeTransaction { context in
            context.delete(MemoryEntity.self, query: nil)
        }
    }

    func observeChanges() -> AnyPublisher<Void, Never> {
        databaseStorage.observeChanges(
            MemoryEntity.self,
            keyPaths: nil,
            query: nil
        )
    }
}
