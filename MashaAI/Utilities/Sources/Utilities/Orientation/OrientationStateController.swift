import Foundation
import UIKit
import Combine

public class OrientationStateController: ObservableObject, OrientationStateControlling {
    private let notificationCenter: NotificationCenter
    private var cancellables = Set<AnyCancellable>()

    deinit {
        cancellables.forEach { $0.cancel() }
        cancellables = []
    }

    public init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
        startTracking()
    }
    
    private func startTracking() {
        notificationCenter.publisher(for: UIDevice.orientationDidChangeNotification)
            .compactMap { _ in UIDevice.current.orientation }
            .map { orientation -> DeviceOrientation in
                switch orientation {
                case .portrait: return .portrait
                case .landscapeLeft: return .landscapeLeft
                case .landscapeRight: return .landscapeRight
                case .portraitUpsideDown: return .portraitUpsideDown
                case .faceUp: return .faceUp
                case .faceDown: return .faceDown
                default: return .unknown
                }
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] orientation in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    public func observeSimplifiedOrientation() -> AnyPublisher<SimplifiedOrientation, Never> {
        notificationCenter.publisher(for: UIDevice.orientationDidChangeNotification)
            .compactMap { _ in UIDevice.current.orientation }
            .map { orientation -> SimplifiedOrientation? in
                switch orientation {
                case .portrait, .portraitUpsideDown:
                    return .portrait
                case .landscapeLeft, .landscapeRight:
                    return .landscape
                case .faceUp, .faceDown:
                    return nil
                default:
                    return nil
                }
            }
            .compactMap { $0 }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    public func observeOrientation() -> AnyPublisher<DeviceOrientation, Never> {
        notificationCenter.publisher(for: UIDevice.orientationDidChangeNotification)
            .compactMap { _ in UIDevice.current.orientation }
            .map { self.mapOrientation($0) }
            .prepend(mapOrientation(UIDevice.current.orientation))
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    private func mapOrientation(_ orientation: UIDeviceOrientation) -> DeviceOrientation {
        switch orientation {
        case .portrait: return .portrait
        case .landscapeLeft: return .landscapeLeft
        case .landscapeRight: return .landscapeRight
        case .portraitUpsideDown: return .portraitUpsideDown
        case .faceUp: return .faceUp
        case .faceDown: return .faceDown
        default: return .unknown
        }
    }
} 
