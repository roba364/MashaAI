import Foundation
import RealmSwift
import Combine

extension DatabaseStorage {
    func get<T: DBEntity, Model>(
        _ type: T.Type = T.self,
        query: DBQuery<T>? = nil,
        sort: SortParams? = nil,
        while pred: @escaping (T) -> Bool = { _ in true },
        mapper: @escaping (T) -> Model
    ) async -> [Model] {
        await readTransaction { context in
            context.get(T.self,
                        query: query,
                        sort: sort,
                        while: pred).map(mapper)
        }
    }

    func get<T: DBEntityWithID, Model>(
        _ type: T.Type = T.self,
        by id: T.Identifier,
        mapper: @escaping (T) -> Model
    ) async -> Model? {
        await readTransaction { context in
            context.get(T.self, by: id).map(mapper)
        }
    }
}

extension DatabaseRead {
    func get<T: DBEntity>(_ type: T.Type = T.self,
                          query: DBQuery<T>? = nil,
                          sort: SortParams? = nil,
                          limit: Int = Int.max) -> [T] {
        var count = 0
        return get(type, query: query, sort: sort, while: { _ in
            guard count < limit else { return false }
            count += 1
            return true
        })
    }

    func get<T: DBEntityWithID>(by id: T.Identifier) -> T? {
        get(T.self, by: id)
    }
}

extension DatabaseWrite {
    func add<T: DBEntity>(_ entities: T...) {
        self.add(entities)
    }

    func delete<T: DBEntity>(_ type: T.Type = T.self) {
        delete(type, query: nil)
    }

    func delete<T: DBEntityWithID>(_ type: T.Type, by id: T.Identifier) where T.Identifier: Equatable {
        delete(type,
               query: .init(query: { $0.id == id }))
    }
}

extension DatabaseWrite where Self: DatabaseRead {
    func updateIfExists<T: DBEntityWithID>(_ type: T.Type = T.self,
                                           by id: T.Identifier,
                                           modify: (T) -> Void) {
        guard let entity: T = get(type, by: id) else { return }
        modify(entity)
        add(entity)
    }
}
