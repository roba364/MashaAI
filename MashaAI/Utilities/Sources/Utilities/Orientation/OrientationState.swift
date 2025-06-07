import Foundation
import Combine

public enum DeviceOrientation {
    case portrait
    case landscapeLeft
    case landscapeRight
    case portraitUpsideDown
    case faceUp
    case faceDown
    case unknown
}

public enum SimplifiedOrientation {
    case portrait
    case landscape
}

public protocol OrientationStateControlling {
    func observeOrientation() -> AnyPublisher<DeviceOrientation, Never>
    func observeSimplifiedOrientation() -> AnyPublisher<SimplifiedOrientation, Never>
}
