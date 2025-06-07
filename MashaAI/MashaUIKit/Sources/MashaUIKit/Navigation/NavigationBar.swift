import SwiftUI

public struct NavigationBar<
    LeadingItems: View,
    CenterItem: NavigationBarCenterItem,
    TrailingItems: View
>: View {
    let leading: LeadingItems
    let center: CenterItem
    let trailing: TrailingItems

    @State
    private var leadingWidths: [Int: CGFloat] = [:]
    @State
    private var trailingWidths: [Int: CGFloat] = [:]

    public init(
        @LeadingItemsBuilder leading: () -> LeadingItems = { EmptyView() },
        @CenterItemsBuilder center: () -> CenterItem = { EmptyView() },
        @TrailingItemsBuilder trailing: () -> TrailingItems = { EmptyView() }
    ) {
        self.leading = leading()
        self.center = center()
        self.trailing = trailing()
    }

    public var body: some View {
        let contentPadding: CGFloat = 20
        let itemPadding: CGFloat = 7.5
        HStack(alignment: .top, spacing: 0) {
            Spacer().frame(width: contentPadding - itemPadding)
            // using variadic view to preserve child view layout priorities
            leading.variadic { items in
                ForEach(items.indices, id: \.self) { index in
                    items[index]
                        .padding(.horizontal, itemPadding)
                        .measure(\.size.width, assignTo: $leadingWidths[index])
                }
                .onChange(of: items.count) { _ in
                    leadingWidths = [:]
                }
            }

            let leadingWidth = leadingWidths.values.reduce(0, +)
            let trailingWidth = trailingWidths.values.reduce(0, +)

            center
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, itemPadding)
                .padding(.leading, max(0, trailingWidth - leadingWidth))
                .padding(.trailing, max(0, leadingWidth - trailingWidth))

            // when center is empty, spacer separates leading and trailing items
            Spacer(minLength: 0)

            trailing.variadic { items in
                ForEach(items.indices, id: \.self) { index in
                    items[index]
                        .padding(.horizontal, itemPadding)
                        .measure(\.size.width, assignTo: $trailingWidths[index])
                }
                .onChange(of: items.count) { _ in
                    trailingWidths = [:]
                }
            }
            Spacer().frame(width: contentPadding - itemPadding)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

// Thanks to Chris Eidhof https://chris.eidhof.nl/post/variadic-views/
private struct VariadicHelper<Result: View>: _VariadicView_MultiViewRoot {
    var _body: (_VariadicView.Children) -> Result

    func body(children: _VariadicView.Children) -> some View {
        _body(children)
    }
}

private extension View {

    func variadic<R: View>(@ViewBuilder process: @escaping (_VariadicView.Children) -> R) -> some View {
        _VariadicView.Tree(
            VariadicHelper(_body: process),
            content: { self }
        )
    }
}

public struct NavigationBar_Previews: PreviewProvider {

    public static var previews: some View {
        Color.yellow.safeAreaInset(edge: .top, spacing: 0) {
            NavigationBar(
                center: {
                    NavigationBarTitle(
                        title: "Long long long long long long long long long long Title"
                    )
                }
            )
            .background(.orange)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            NavigationBar(
                leading: {
                    NavigationBarCustomItem {
                        Text(Array(repeating: "Leading", count: 5).joined(separator: ""))
                            .lineLimit(1)
                            .frame(height: 64)
                            .background(.cyan)
                    }
                },
                trailing: {
                    NavigationBarCustomItem {
                        Text(Array(repeating: "Trailing", count: 5).joined(separator: ""))
                            .lineLimit(1)
                            .frame(height: 64)
                            .background(.cyan)
                    }
                }
            )
            .background(.red)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            NavigationBar(
                leading: { BackButton { print("Back") }.navigationBarItem },
                center: {
                    NavigationBarTitle(
                        title: "Title",
                        subtitle: "Short subtitle"
                    )
                }
            )
            .background(.purple)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            NavigationBar(
                leading: { BackButton { print("Back") }.navigationBarItem },
                center: {
                    NavigationBarTitle(
                        title: "Title",
                        subtitle: {
                            HStack {
                                Text("Subtitle 1")
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(.cyan)

                                Text("Subtitle 2 which is pretty long, and allows 3 lines")
                                    .lineLimit(3)
                                    .frame(maxWidth: .infinity)
                                    .background(.red)
                            }
                        }
                    )
                }
            )
            .background(.blue)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            NavigationBar(
                leading: {
                    BackButton { print("Back") }.navigationBarItem
                },
                center: {
                    NavigationBarTitle(
                        title: "Title",
                        subtitle: "Subtitle which is pretty long, blah blah blah blah blah"
                    )
                }
            )
            .background(.green)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            NavigationBar(
                center: {
                    NavigationBarTitle(
                        title: {
                            HStack(alignment: .center) {
                                Text("Title")
                                Color.orange
                                    .frame(width: 40, height: 40)
                                    .overlay {
                                        Text(":)").foregroundColor(.black)
                                    }
                            }
                        }
                    )
                },
                trailing: {
                    CloseButton { print("Close") }.navigationBarItem
                }
            )
            .background(.yellow)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            NavigationBar(
                leading: {
                    BackButton { print("Back") }.navigationBarItem
                },
                center: {
                    NavigationBarTitle(
                        title: "Title",
                        subtitle: "Subtitle which is pretty long, blah blah blah blah blah"
                    )
                },
                trailing: {
                    CloseButton { print("Close1") }.navigationBarItem
                    CloseButton { print("Close2") }.navigationBarItem
                }
            )
            .background(.orange)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            NavigationBar(
                leading: {
                    BackButton {
                        print("Back")
                    }
                    .navigationBarItem
                },
                trailing: {
                    CloseButton { print("Close1") }.navigationBarItem
                    CloseButton { print("Close2") }.navigationBarItem
                    CloseButton { print("Close2") }.navigationBarItem
                    CloseButton { print("Close2") }.navigationBarItem
                    CloseButton { print("Close2") }.navigationBarItem
                    CloseButton { print("Close2") }.navigationBarItem
                }
            )
            .background(.red)
        }
        .background(.blue)
    }
}

