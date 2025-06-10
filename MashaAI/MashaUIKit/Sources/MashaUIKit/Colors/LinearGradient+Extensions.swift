import SwiftUI

public extension Array where Element == Gradient.Stop {
    static let voiceChatBackground: Self = [
        .init(color: .palette.yellowNotActive, location: 0.0),
        .init(color: .palette.yellowNotActive, location: 1.0)
    ]
}
