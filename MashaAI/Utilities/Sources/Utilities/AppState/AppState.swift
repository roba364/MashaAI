import Foundation
import Combine

public enum AppState {
    case active, inactive, background
}

public protocol AppStateControlling {
    var state: AppState { get }
    func observeState() -> AnyPublisher<AppState, Never>
}
