import Foundation

@inlinable
@discardableResult
public func with<T>(_ val: T, _ block: (inout T) throws -> Void) rethrows -> T {
    var val = val
    try block(&val)
    return val
}
