import Foundation
import RealmSwift

/// Executes async read / write realm storage operations
class RealmAsyncExecutor {
    private let realmProvider: RealmProvider

    private lazy var readWorker = BackgroundWorker()
    private lazy var writeWorker = BackgroundWorker()

    init(realmProvider: RealmProvider) {
        self.realmProvider = realmProvider
    }

    func readAsync<T>(_ block: @escaping (Realm) -> T,
                      completion: @escaping (T) -> Void) {
        readWorker.execute { [weak self] in
            guard let realm = self?.realmProvider.realm else { return }
            completion(block(realm))
        }
    }

    func writeAsync<T>(_ block: @escaping (Realm) throws -> T,
                       completion: @escaping (Result<T, Error>) -> Void) {
        writeWorker.execute { [weak self] in
            guard let realm = self?.realmProvider.realm else { return }

            do {
                let result = try realm.write { try block(realm) }
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Swift concurrency extensions

extension RealmAsyncExecutor {
    func read<T>(_ block: @escaping (Realm) -> T) async -> T {
        await withCheckedContinuation({ cont in
            self.readAsync(block) {
                cont.resume(returning: $0)
            }
        })
    }

    func write<T>(_ block: @escaping (Realm) throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { cont in
            self.writeAsync(block) { cont.resume(with: $0) }
        }
    }
}
