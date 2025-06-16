import Combine
import Foundation
import RealmSwift
import Utilities

final class RealmStorage: DatabaseStorage {
    private let executor: RealmAsyncExecutor

    private let triggers: [DatabaseTrigger]

    private var tokens: Set<NotificationToken> = []
    private let tokensQueue = DispatchQueue(label: "realm.storage.tokens", attributes: .concurrent)

    init(
        realmProvider: RealmProvider,
        triggers: [DatabaseTrigger] = []
    ) {
        self.executor = .init(realmProvider: realmProvider)
        self.triggers = triggers
    }

    deinit {
        // Clean up all observation tokens
        tokensQueue.sync(flags: .barrier) {
            tokens.removeAll()
        }
    }

    private func addToken(_ token: NotificationToken) {
        tokensQueue.async(flags: .barrier) { [weak self] in
            self?.tokens.insert(token)
        }
    }

    private func removeToken(_ token: NotificationToken) {
        tokensQueue.async(flags: .barrier) { [weak self] in
            self?.tokens.remove(token)
        }
    }

    func observeChanges<T: DBEntity>(
        _ type: T.Type,
        keyPaths: [PartialKeyPath<T>]?,
        query: DBQuery<T>?
    ) -> AnyPublisher<Void, Never> {
        _observeChanges(
            type,
            keyPaths: keyPaths,
            query: query
        )
        .retry(3)
        .ignoreFailure()
    }

    private func _observeChanges<T: DBEntity>(
        _ type: T.Type,
        keyPaths: [PartialKeyPath<T>]?,
        query: DBQuery<T>?
    ) -> AnyPublisher<Void, Error> {
        let subject = PassthroughSubject<Void, Error>()

        executor.readAsync { [weak self] realm in
            var collection = realm.objects(type.self)
            if let query = query {
                collection = collection.where(query.query)
            }

            let keyPaths = keyPaths?.map(_name(for:))
            let token = collection.observe(keyPaths: keyPaths) { [weak subject] changes in
                switch changes {
                case .initial, .update:
                    subject?.send(())
                case let .error(error):
                    subject?.send(completion: .failure(error))
                }
            }

            // Store the token to keep the observation alive
            self?.addToken(token)
            return token
        } completion: { [weak subject] result in
            switch result {
            case .success(let token):
                // Token is now stored and observation is active
                break
            case .failure(let error):
                subject?.send(completion: .failure(error))
            }
        }

        return subject
            .handleEvents(
                receiveSubscription: { _ in
                    // Keep reference to self to ensure tokens are maintained
                },
                receiveCompletion: { [weak self] completion in
                    // Remove all tokens when publisher completes
                    self?.tokensQueue.async(flags: .barrier) { [weak self] in
                        self?.tokens.removeAll()
                    }
                },
                receiveCancel: { [weak subject] in
                    // Properly finish the publisher when cancelled
                    subject?.send(completion: .finished)
                    // Note: tokens will be cleaned up in deinit if needed
                }
            )
            .eraseToAnyPublisher()
    }

    func writeTransaction<Model>(
        _ block: @escaping (DatabaseContext) throws -> Model
    ) async throws -> Model {
        try await executor.write { [triggers] in
            let result = try block(
                RealmContext(
                    realm: $0,
                    triggers: triggers))
            assert(!(result is DBEntity), "Model should not be db entity")
            return result
        }
    }

    func readTransaction<Model>(
        _ block: @escaping (DatabaseRead) -> Model
    ) async -> Model {
        await executor.read { [triggers] realm in
            realm.refresh()
            let result = block(RealmContext(realm: realm, triggers: triggers))
            assert(!(result is DBEntity), "Model should not be db entity")
            return result
        }
    }

}

private class RealmContext: DatabaseContext {

    private let realm: Realm
    private let triggers: [DatabaseTrigger]

    init(realm: Realm, triggers: [DatabaseTrigger]) {
        self.realm = realm
        self.triggers = triggers
    }

    func get<T: DBEntity, V: Comparable>(
        _ type: T.Type,
        query: DBQuery<T>?,
        sort: SortParams<T, V>?,
        while pred: (T) -> Bool
    ) -> [T] {
        let collection = self.collection(T.self, query: query, sort: sort)
        return collection.prefix(while: pred)
    }

    func get<T: DBEntityWithID>(_ type: T.Type, by id: T.Identifier) -> T? {
        return realm.object(ofType: T.self, forPrimaryKey: id)
    }

    func delete<T: DBEntity>(_ type: T.Type, query: DBQuery<T>?) {
        let collection = self.collection(T.self, query: query)
        let objects = Array(collection)
        triggers.forEach { $0.willDelete(objects, ctx: self) }
        realm.delete(collection)
    }

    func delete<T: DBEntity>(_ entity: T) {
        triggers.forEach { $0.willDelete([entity], ctx: self) }
        realm.delete(entity)
    }

    func add<T: DBEntity>(_ entities: [T]) {
        triggers.forEach { $0.willImport(entities, ctx: self) }
        realm.add(entities, update: .modified)
    }

    func `where`<T: Object>(_ type: T.Type) -> Results<T> {
        realm.objects(type)
    }

    private func collection<T: DBEntity>(
        _ type: T.Type,
        query: DBQuery<T>?
    ) -> Results<T> {
        var collection = realm.objects(T.self)

        if let query = query {
            collection = collection.where(query.query)
        }

        return collection
    }

    private func collection<T: DBEntity, V: Comparable>(
        _ type: T.Type,
        query: DBQuery<T>?,
        sort: SortParams<T, V>?
    ) -> Results<T> {
        var collection = realm.objects(T.self)

        if let query = query {
            collection = collection.where(query.query)
        }

        if let sort = sort {
            collection = collection.sorted(
                byKeyPath: sort.keyPathString,
                ascending: sort.ascending)
        }

        return collection
    }
}
