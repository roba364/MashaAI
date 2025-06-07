//import SwiftUI
//
//public struct AsyncValueView<
//    Value,
//    Content: View,
//    ErrorView: View,
//    Placeholder: View
//>: View {
//    enum ViewState {
//        case idle
//        case loading
//        case content(Value)
//        case failed(Error)
//    }
//
//    let content: (Value) -> Content
//    let error: (Error) -> ErrorView
//    let placeholder: Placeholder
//    let value: AsyncValue<Value>?
//
//    @StateObject
//    private var state = StateController()
//
//    public init(
//        value: AsyncValue<Value>?,
//        @ViewBuilder content: @escaping (Value) -> Content,
//        @ViewBuilder error: @escaping (Error) -> ErrorView,
//        @ViewBuilder placeholder: () -> Placeholder
//    ) {
//        self.value = value
//        self.content = content
//        self.error = error
//        self.placeholder = placeholder()
//    }
//
//    public var body: some View {
//        Group {
//            switch state.state {
//            case .idle, .loading:
//                placeholder
//            case .failed(let e):
//                error(e)
//            case .content(let value):
//                content(value)
//            }
//        }
//        .onAppear {
//            guard !state.isLoading else { return }
//            state.update(with: value)
//        }
//        .onChange(of: value) { newValue in
//            state.update(with: newValue)
//        }
//        .onDisappear {
//            state.cancelUpdate()
//        }
//    }
//}
//
//extension AsyncValueView where Content == ErrorView, Content == Placeholder {
//
//    public enum ValueState {
//        case loading
//        case data(Value)
//        case error(Error)
//    }
//
//    public init(
//        value: AsyncValue<Value>?,
//        content: @escaping (ValueState) -> Content
//    ) {
//        self.init(value: value) { value in
//            content(.data(value))
//        } error: { error in
//            content(.error(error))
//        } placeholder: {
//            content(.loading)
//        }
//    }
//}
//
//private extension AsyncValueView {
//
//    @MainActor
//    final class StateController: ObservableObject {
//
//        @Published
//        private(set) var state: ViewState = .idle
//
//        private var updateTask: Task<Void, Never>?
//
//        var isLoading: Bool {
//            if case .loading = state { return true }
//            return false
//        }
//
//        func cancelUpdate() {
//            updateTask?.cancel()
//        }
//
//        func update(with value: AsyncValue<Value>?) {
//            cancelUpdate()
//
//            if let syncValue = try? value?.syncValue {
//                state = .content(syncValue)
//                return
//            }
//
//            state = .loading
//            guard let value else { return }
//
//            updateTask = Task { @MainActor in
//                do {
//                    state = .content(try await value.value)
//                } catch {
//                    state = .failed(error)
//                }
//            }
//        }
//    }
//}
