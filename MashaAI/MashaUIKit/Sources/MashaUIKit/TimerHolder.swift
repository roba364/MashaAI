import Foundation
import SwiftUI
import Combine

public class TimerHolder: ObservableObject {

    private let interval: TimeInterval

    private var timer: Timer?

    @Published
    public private(set) var intervalFromStart: TimeInterval?

    public init(interval: TimeInterval) {
        self.interval = interval
    }

    public func start() {
        DispatchQueue.main.async {
            self.startTimer()
        }
    }

    public func pause() {
        DispatchQueue.main.async {
            self.timer?.invalidate()
            self.timer = nil
        }
    }

    public func stop() {
        DispatchQueue.main.async {
            self.timer?.invalidate()
            self.timer = nil
            self.intervalFromStart = nil
        }
    }

    public func restart() {
        stop()
        start()
    }

    private func startTimer() {
        guard timer == nil else { return }

        if intervalFromStart == nil {
            intervalFromStart = 0
        }

        timer = .scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.intervalFromStart = self.interval + (self.intervalFromStart ?? 0)
        }
    }
}
