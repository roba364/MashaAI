import Foundation
import SwiftUI
import Combine

/// Task lifcycle and owning helper.
///
/// Cancels task when deinited. Also exposes task's process state to external property.
public class TaskHolder {
    fileprivate var isPending: Bool = false {
        didSet {
            onChange(isPending)
        }
    }
    fileprivate var operation: AnyTask?

    private var onChange: (Bool) -> Void

    /// - Parameters:
    ///     - key: Bool keypath to property to which assign task execution state (`true` - task is executing, `false` - task is finished)
    ///     - root: object which owns property
    public init<T: AnyObject>(_ key: WritableKeyPath<T, Bool>, on root: T) {
        onChange = { [weak root] value in
            DispatchQueue.main.async {
                root?[keyPath: key] = value
            }
        }
    }

    init() {
        onChange = { _ in }
    }

    deinit {
        operation?.cancel()
    }
}

public protocol AnyTask {
    func cancel()
}

extension Task: AnyTask {

}

public extension Task where Failure == Error {
    @discardableResult
    init(_ pending: TaskHolder,
         priority: TaskPriority? = nil,
         operation: @escaping @Sendable () async throws -> Success) {

        pending.operation?.cancel()

        self.init(priority: priority) { [weak pending] in
            pending?.isPending = true
            defer { pending?.isPending = false }

            return try await operation()
        }

        pending.operation = self
    }
}
