import AudioToolbox.AudioServices
import UIKit
import CoreHaptics

public protocol HapticSoundsPlayer {
    func playSound(with url: URL)
}

public class HapticController {
    public static let shared = HapticController()

    private let feedbackGenerator: HapticFeedbackGenerating
    private var soundsPlayer: HapticSoundsPlayer?

    private init() {
        feedbackGenerator = HapticFeedbackGenerator()
    }

    public func configure(with soundsPlayer: HapticSoundsPlayer) {
        self.soundsPlayer = soundsPlayer
    }

    public func play(_ event: HapticEvent) {
        if let feeback = event.type {
            feedbackGenerator.generate(feeback)
        }

        if let sound = event.sound {
            playSound(sound)
        }
    }

    private func playSound(_ sound: HapticEvent.SoundResource) {
        guard let soundsPlayer = soundsPlayer else {
            assertionFailure("Haptic controller should be configured")
            return
        }
        soundsPlayer.playSound(with: sound.fileURL)
    }
}

private protocol HapticFeedbackGenerating {
    func generate(_ haptic: HapticEvent.FeedbackType)
}

private class HapticFeedbackGenerator: HapticFeedbackGenerating {

    func generate(_ haptic: HapticEvent.FeedbackType) {
        switch haptic {
        case .select:
            UISelectionFeedbackGenerator().selectionChanged()
        case let .impact(style):
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        case let .notification(type):
            UINotificationFeedbackGenerator().notificationOccurred(type)
        }
    }
}
