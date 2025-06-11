import Foundation
import RealmSwift

// MARK: - Realm Entity

final class MemoryEntity: Object, DBEntityWithID {
    @Persisted var id: String = UUID().uuidString
    @Persisted var message: String = ""
    @Persisted var senderRaw: String = ""
    @Persisted var timestamp: Date = Date()

    var sender: MemorySender {
        get { MemorySender(rawValue: senderRaw) ?? .user }
        set { senderRaw = newValue.rawValue }
    }

    override static func primaryKey() -> String? {
        return "id"
    }

    convenience init(memory: Memory) {
        self.init()
        self.id = memory.id
        self.message = memory.message
        self.senderRaw = memory.sender.rawValue
        self.timestamp = memory.timestamp
    }
}

// MARK: - Conformance

extension MemoryEntity: DBEntity {}

// MARK: - Mapping

extension MemoryEntity {
    func toDomain() -> Memory {
        Memory(
            id: id,
            message: message,
            sender: sender,
            timestamp: timestamp
        )
    }
}

extension Memory {
    func toEntity() -> MemoryEntity {
        MemoryEntity(memory: self)
    }
}
