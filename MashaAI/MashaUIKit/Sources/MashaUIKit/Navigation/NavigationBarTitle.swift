import SwiftUI

public struct NavigationBarTitle<
    TitleView: View,
    SubtitleView: View
>: NavigationBarLeadingItem, NavigationBarCenterItem {

    let title: TitleView
    let subtitle: SubtitleView

    @Environment(\.navigationBarStyle)
    private var navigationBarStyle

    @State
    private var titleHeight: CGFloat?

    public init(
        @ViewBuilder title: () -> TitleView,
        @ViewBuilder subtitle: () -> SubtitleView = { EmptyView() }
    ) {
        self.title = title()
        self.subtitle = subtitle()
    }

    public var body: some View {
        VStack(spacing: 4) {
            title
                .typography(navigationBarStyle.typography)
                .foregroundColor(.palette.primary800)
                .lineLimit(1)
                .measure { titleHeight = $0?.height }
            subtitle
                .multilineTextAlignment(.center)
        }
        .padding(.top, 32 - (titleHeight ?? 0) / 2)
        .padding(.bottom, 15)
    }
}

extension NavigationBarTitle {

    public init(
        title: String,
        @ViewBuilder subtitle: () -> SubtitleView = { EmptyView() }
    ) where TitleView == Text {
        self.init(
            title: { Text(title) },
            subtitle: subtitle
        )
    }

    public init(
        @ViewBuilder title: () -> TitleView,
        subtitle: String
    ) where SubtitleView == Text {
        self.init(
            title: title,
            subtitle: { Text(subtitle) }
        )
    }

    public init(
        title: String,
        subtitle: String?
    ) where TitleView == Text, SubtitleView == Text? {
        self.init(
            title: { Text(title) },
            subtitle: {
                if let subtitle = subtitle {
                    Text(subtitle)
                }
            }
        )
    }
}
