import Foundation

public extension Bundle {
    func url(for file: String) -> URL? {
        guard !file.isEmpty else { return nil}

        var components = file.components(separatedBy: ".")
        guard components.count > 1 else {
            assertionFailure()
            return nil
        }

        let fileExt = components.removeLast()
        let filename = components.joined(separator: ".")

        return url(forResource: filename, withExtension: fileExt)
    }
}
