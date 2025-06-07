import Foundation
import UIKit
import Combine

public extension AppState {
    var isActive: Bool { self == .active }
}

public class AppStateController: ObservableObject, AppStateControlling {
    @Published
    public private(set) var state: AppState

    public init(notificationCenter: NotificationCenter = .default) {
        self.state = .init(UIApplication.shared.applicationState)

        let isActive = notificationCenter
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .map { _ in AppState.active }

        let isInactive = notificationCenter
            .publisher(for: UIApplication.willResignActiveNotification)
            .map { _ in AppState.inactive }

        let isBackground = notificationCenter
            .publisher(for: UIApplication.didEnterBackgroundNotification)
            .map { _ in AppState.background }

        Publishers.MergeMany([
            isActive, isInactive, isBackground
        ])
        .receive(on: DispatchQueue.main)
        .removeDuplicates()
        .assign(to: &$state)
    }

    public func observeState() -> AnyPublisher<AppState, Never> {
        $state.eraseToAnyPublisher()
    }
}

extension AppState {
    init(_ state: UIApplication.State) {
        switch state {
        case .active: self = .active
        case .inactive: self = .inactive
        case .background: self = .background
        @unknown default: self = .inactive
        }
    }
}
