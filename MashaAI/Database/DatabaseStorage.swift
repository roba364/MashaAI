import Combine
import Foundation
import RealmSwift

struct DBQuery<T: DBEntity> {
  let query: (Query<T>) -> Query<Bool>
}

protocol DBEntity: Object {}

protocol DBEntityWithID: DBEntity {
  associatedtype Identifier
  var id: Identifier { get }
}

struct SortParams<T: DBEntity, V: Comparable> {
  let keyPath: KeyPath<T, V>
  let ascending: Bool

  init(keyPath: KeyPath<T, V>, ascending: Bool = true) {
    self.keyPath = keyPath
    self.ascending = ascending
  }
}

// Extension для работы с String keyPath (для совместимости с Realm)
extension SortParams {
  var keyPathString: String {
    return _name(for: keyPath)
  }
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
  func get<T: DBEntity, V: Comparable>(
    _ type: T.Type,
    query: DBQuery<T>?,
    sort: SortParams<T, V>?,
    while pred: (T) -> Bool
  ) -> [T]
  func get<T: DBEntityWithID>(_ type: T.Type, by id: T.Identifier) -> T?
  func `where`<T: Object>(_ type: T.Type) -> Results<T>
}

protocol DatabaseWrite {
  func delete<T: DBEntity>(_ entity: T)
  func delete<T: DBEntity>(_ type: T.Type, query: DBQuery<T>?)
  func add<T: DBEntity>(_ entities: [T])
}
