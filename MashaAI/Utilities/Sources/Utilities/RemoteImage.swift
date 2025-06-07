import SwiftUI
import Kingfisher

public struct RemoteImage: View {

    private let url: URL?
    private let size: CGSize?

    public init(_ url: URL?, size: CGSize? = nil) {
        self.url = url
        self.size = size
    }

    public var body: some View {
        VStack {
            if let size = size {
                KFImage(url)
                    .cancelOnDisappear(true)
                    .downsampling(
                        size: CGSize(
                            width: size.width * UIScreen.main.scale,
                            height: size.height * UIScreen.main.scale
                        )
                    )
                    .resizable()
            } else {
                KFImage(url)
                    .cancelOnDisappear(true)
                    .resizable()
            }
        }
    }
}
