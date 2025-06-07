import SwiftUI

public extension LinearGradient {
    static var buttonPrimary: Self {
        LinearGradient(
            gradient: .init(
                stops: [
                    .init(color: .init(hex: 0x1CD9B7), location: 0),
                    .init(color: .init(hex: 0x398FDE), location: 1)
                ]
            ),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var buttonPurchasePrimary: Self {
        LinearGradient(
            gradient: .init(
                stops: [
                    .init(color: .init(hex: 0xFD8F00), location: 0),
                    .init(color: .init(hex: 0xFEFD30), location: 1)
                ]
            ),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var buttonPurchasePrimaryWhite: Self {
        LinearGradient(
            gradient: .init(
                stops: [
                    .init(color: .white, location: 0),
                    .init(color: .white, location: 1)
                ]
            ),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var buttonDeletePrimary: Self {
        LinearGradient(
            gradient: .init(
                stops: [
                    .init(color: Color.palette.error900, location: 0),
                    .init(color: Color.palette.error900, location: 1)
                ]
            ),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var topBottomBlackWithOpacity: Self {
        .init(
            stops: [
                .init(color: .palette.mainBackground.opacity(0.0), location: 0),
                .init(color: .palette.mainBackground, location: 0.4)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var topBottomBlackOverlayImage: Self {
        .init(
            stops: [
                .init(color: .black.opacity(0.7), location: 0),
                .init(color: .black.opacity(0.0), location: 1.0)
            ],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    static var progressSummary: Self {
        .init(
            colors: [.white, .palette.talentGreen],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var yogaLessonGradient: Self {
        LinearGradient(
            gradient: .init(
                stops: [
                    .init(color: .black.opacity(0.7), location: 0),
                    .init(color: .black.opacity(0.4), location: 0.34),
                    .init(color: .black.opacity(0.4), location: 0.63),
                    .init(color: .black.opacity(0.7), location: 1)
                ]
            ),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var topBottomDailyOpacity: Self {
        .init(
            stops: [
                .init(color: .palette.dailyAffirmation.opacity(0.0), location: 0),
                .init(color: .palette.dailyAffirmation, location: 0.3)
            ],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    static var comparingFeedHeader: Self {
        .init(
            stops: [
                .init(color: .black.opacity(0.0), location: 0),
                .init(color: .black.opacity(0.2), location: 0.5)
            ],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    static var specialOfferGradient: Self {
        .init(
            stops: [
                .init(color: .palette.black800.opacity(0.0), location: 0),
                .init(color: .palette.black800.opacity(0.75), location: 0.3),
                .init(color: .palette.black800.opacity(0.9), location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var chatListEvaGradient: Self {
        .init(
            colors: [
                .palette.chatEvaTop,
                .palette.chatEvaBottom
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
