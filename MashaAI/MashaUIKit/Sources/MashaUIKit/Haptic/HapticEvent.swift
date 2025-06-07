import Foundation
import UIKit

public struct HapticEvent {
    public enum FeedbackType {
        case select
        case impact(UIImpactFeedbackGenerator.FeedbackStyle)
        case notification(UINotificationFeedbackGenerator.FeedbackType)
    }

    public struct SoundResource {
        let fileURL: URL

        public static func url(_ url: URL) -> Self {
            .init(fileURL: url)
        }

        public static func named(_ name: String,
                                 bundle: Bundle = .main,
                                 extenstion: String) -> Self {
            .init(fileURL: bundle.url(forResource: name,
                                      withExtension: extenstion)!)
        }
    }

    public let type: FeedbackType?
    public let sound: SoundResource?

    public init(type: FeedbackType? = nil,
                sound: SoundResource? = nil) {
        self.type = type
        self.sound = sound
    }
}

public extension HapticEvent {
    static let alertAppear = HapticEvent(type: .notification(.warning))

    //TODO: - setup haptics here
    static let navBarBtn = HapticEvent(type: .impact(.light))

    // Onboarding
    static let selection = HapticEvent(type: .impact(.light))
    static let rigid = HapticEvent(type: .impact(.rigid))

    // Chat
    static let messageSent = HapticEvent(type: .impact(.soft))
    static let chatStarted = HapticEvent(type: .impact(.medium))

    // Alerts
    static let tourNextStep = HapticEvent(type: .impact(.light))
    static let tourStarted = HapticEvent(type: .impact(.medium))
    static let tourFinished = HapticEvent(type: .impact(.heavy))
    static let alertBtnTap = HapticEvent(type: .select)
    
    static let light = HapticEvent(type: .impact(.light))
    static let medium = HapticEvent(type: .impact(.medium))
    static let heavy = HapticEvent(type: .impact(.heavy))
}
