import Foundation

// add this method for better usability in iOS 15 and below

public extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: TimeInterval) async {
        let nanoseconds = UInt64(seconds * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanoseconds)
    }
}
