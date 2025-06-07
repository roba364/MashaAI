import Foundation

public struct HexValue: Hashable, ExpressibleByIntegerLiteral {

    public let wrappedValue: UInt

    public init(_ wrappedValue: UInt) {
        self.wrappedValue = wrappedValue
    }

    public init(integerLiteral value: UInt) {
        self.wrappedValue = value
    }

    public init?(_ string: String) {
        if let wrappedValue = Self.translate(from: string) {
            self.init(wrappedValue)
        } else {
            return nil
        }
    }

    public static func translate(from serialized: String) -> UInt? {
        var hexString = serialized

        if hexString.hasPrefix("#") {
            hexString.removeFirst(1)
        } else if hexString.hasPrefix("0x") {
            hexString.removeFirst(2)
        }

        return UInt(hexString, radix: 16)
    }
}

extension HexValue: Decodable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let serialized = try container.decode(String.self)

        guard let translated = Self.translate(from: serialized) else {
            throw Swift.DecodingError.dataCorruptedError(
                in: container,
                debugDescription: """
                    Value \(serialized) is not representable as hex Int
                    with \(Self.self)
                """
            )
        }

        self.init(translated)
    }
}

extension HexValue: Encodable {

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(String(wrappedValue, radix: 16))
    }
}
