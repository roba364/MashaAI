import Foundation
import RealmSwift
import Combine

struct DBQuery<T: DBEntity> {
    let query: (Query<T>) -> Query<Bool>
}

protocol DBEntity: Object {}

protocol DBEntityWithID: DBEntity {
    associatedtype Identifier
    var id: Identifier { get }
}

struct SortParams {
    let keyPath: String
    let ascending: Bool
}

protocol DatabaseTrigger: AnyObject {
    func willImport<T: DBEntity>(_ entities: [T], ctx: DatabaseContext)
    func willDelete<T: DBEntity>(_ entities: [T], ctx: DatabaseContext)
}

typealias DatabaseContext = DatabaseRead & DatabaseWrite

protocol DatabaseStorage {
    func observeChanges<T: DBEntity>(
        _ type: T.Type,
        keyPaths: [PartialKeyPath<T>]?,
        query: DBQuery<T>?
    ) -> AnyPublisher<Void, Never>

    func writeTransaction<Model>(
        _ block: @escaping (DatabaseContext) throws -> Model
    ) async throws -> Model

    func readTransaction<Model>(
        _ block: @escaping (DatabaseRead) -> Model
    ) async -> Model
}

protocol DatabaseRead {
    func get<T: DBEntity>(_ type: T.Type,
                          query: DBQuery<T>?,
                          sort: SortParams?,
                          while pred: (T) -> Bool) -> [T]
    func get<T: DBEntityWithID>(_ type: T.Type, by id: T.Identifier) -> T?
    func `where`<T: Object>(_ type: T.Type) -> Results<T>
}

protocol DatabaseWrite {
    func delete<T: DBEntity>(_ entity: T)
    func delete<T: DBEntity>(_ type: T.Type, query: DBQuery<T>?)
    func add<T: DBEntity>(_ entities: [T])
}
