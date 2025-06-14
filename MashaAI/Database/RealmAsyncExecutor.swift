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

  func readAsync<T>(
    _ block: @escaping (Realm) -> T,
    completion: @escaping (Result<T, Error>) -> Void
  ) {
    readWorker.execute { [weak self] in
      guard let realm = self?.realmProvider.realm else {
        completion(.failure(RealmAsyncExecutorError.executorDeallocated))
        return
      }
      let result = block(realm)
      completion(.success(result))
    }
  }

  func writeAsync<T>(
    _ block: @escaping (Realm) throws -> T,
    completion: @escaping (Result<T, Error>) -> Void
  ) {
    writeWorker.execute { [weak self] in
      guard let realm = self?.realmProvider.realm else {
        completion(.failure(RealmAsyncExecutorError.executorDeallocated))
        return
      }

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
    let result = await withCheckedContinuation {
      (cont: CheckedContinuation<Result<T, Error>, Never>) in
      self.readAsync(block) { result in
        cont.resume(returning: result)
      }
    }

    switch result {
    case .success(let value):
      return value
    case .failure(let error):
      // Для сохранения обратной совместимости, можем либо:
      // 1. Падать с fatalError (текущее поведение)
      // 2. Возвращать дефолтное значение если T имеет default
      // Выбираем первый вариант для явности проблемы
      fatalError("RealmAsyncExecutor read failed: \(error)")
    }
  }

  func write<T>(_ block: @escaping (Realm) throws -> T) async throws -> T {
    try await withCheckedThrowingContinuation { cont in
      self.writeAsync(block) { cont.resume(with: $0) }
    }
  }
}

enum RealmAsyncExecutorError: Error {
  case executorDeallocated
}
