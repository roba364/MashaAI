import SwiftUI

public extension Animation {
    ///  timing curve: [0.3, 0.9, 0.5, 1]
    static func cubic1(duration: Double) -> Animation {
        .timingCurve(0.3, 0.9, 0.5, 1, duration: duration)
    }

    /// timing curve:  [0.7, 0, 0.5, 1]
    static func cubic2(duration: Double) -> Animation {
        .timingCurve(0.7, 0, 0.5, 1, duration: duration)
    }

    /// timing curve: [0.5, 0, 0.7, 0]
    static func cubic3(duration: Double) -> Animation {
        .timingCurve(0.5, 0, 0.7, 0, duration: duration)
    }

    /// timing curve:  [0.9, 0, 0.6, 1]
    static func cubic4(duration: Double) -> Animation {
        .timingCurve(0.9, 0, 0.6, 1, duration: duration)
    }

    /// timing curve:  [0.17, 0.17, 0.83, 0.83]
    static func cubic5(duration: Double) -> Animation {
        .timingCurve(0.17, 0.17, 0.83, 0.83, duration: duration)
    }

    /// timing curve:  [0.17, 0.00, 0.83, 1.00]
    static func cubic6(duration: Double) -> Animation {
        .timingCurve(0.17, 0.0, 0.83, 1.0, duration: duration)
    }

    /// timing curve:  [1.00, 0.00, 0.26, 1.44]
    static func cubic7(duration: Double) -> Animation {
        .timingCurve(1.0, 0.0, 0.26, 1.44, duration: duration)
    }

    /// timing curve:  [0.58, 0.00, 0.21, 1.00]
    static func cubic8(duration: Double) -> Animation {
        .timingCurve(0.58, 0, 0.21, 1.0, duration: duration)
    }
}

public extension View {
    func animateAppear(_ config: TransitionAnimationConfig) -> some View {
        modifier(TransitionAnimation(config: config, startOnAppear: true))
    }

    func animateTransition(_ config: TransitionAnimationConfig,
                           shouldStart: Bool) -> some View {
        modifier(TransitionAnimation(config: config,
                                     startTransition: shouldStart))
    }
}

public extension TransitionAnimationConfig {
    static func optionButton(delay: Double) -> Self {
        .opacity(from: 0, to: 1, animation: .timingCurve(0.12, 0.56, 0.37, 1.00, duration: 1).delay(delay))
        .offset(from: .init(x: 0, y: 20),
                animation: .timingCurve(0.12, 0.56, 0.37, 1.00, duration: 1).delay(delay))
    }

    static func alertAppear(delay: Double) -> Self {
        .offset(from: .init(x: 0, y: -100),
                animation: .timingCurve(0.12, 0.56, 0.37, 1.00, duration: 1).delay(delay))
    }
}

public struct TransitionAnimationConfig {
    public struct ViewState {
        public var rotation: Angle
        public var opacity: Double
        public var scale: Double
        public var offset: CGPoint
        public var glow: Bool

        public static var identity: Self { .init() }

        public init(rotation: Angle = .zero,
                    opacity: Double = 1,
                    scale: Double = 1,
                    offset: CGPoint = .zero,
                    glow: Bool = false) {
            self.rotation = rotation
            self.opacity = opacity
            self.scale = scale
            self.offset = offset
            self.glow = glow
        }

        public func with(
            xOffset: CGFloat? = nil,
            yOffset: CGFloat? = nil,
            rotation: Angle? = nil,
            opacity: Double? = nil,
            scale: Double? = nil
        ) -> Self {
            var state = self

            if let xOffset = xOffset {
                state.offset.x = xOffset
            }

            if let yOffset = yOffset {
                state.offset.y = yOffset
            }

            if let rotation = rotation {
                state.rotation = rotation
            }

            if let opacity = opacity {
                state.opacity = opacity
            }

            if let scale = scale {
                state.scale = scale
            }

            return state
        }
    }

    struct AnimationConfig {
        let modifier: (inout ViewState) -> Void
        let animation: Animation
    }

    var state: ViewState
    var animations: [AnimationConfig] = []

    public init(initialState: ViewState) {
        self.state = initialState
    }

    public func keyframe(
        _ modifier: @escaping (inout ViewState) -> Void,
        animation: Animation
    ) -> Self {
        var updated = self
        updated.animations.append(.init(modifier: modifier, animation: animation))
        return updated
    }
}

// MARK: Convenience

public extension TransitionAnimationConfig {

    static var opacity: Self { .opacity() }
    static func opacity(from: CGFloat = 0, to: CGFloat = 1, animation: Animation = .default) -> Self {
        self.init(initialState: .init(opacity: from))
            .keyframe({ $0.opacity = to }, animation: animation)
    }

    static var scale: Self { .scale() }
    static func scale(from: CGFloat = .leastNonzeroMagnitude, to: CGFloat = 1, animation: Animation = .default) -> Self {
        self.init(initialState: .init(scale: from))
            .keyframe({ $0.scale = to }, animation: animation)
    }

    static func rotation(from: Angle, to: Angle = .zero, animation: Animation = .default) -> Self {
        self.init(initialState: .init(rotation: from))
            .keyframe({ $0.rotation = to }, animation: animation)
    }

    static func offset(from: CGPoint, to: CGPoint = .zero, animation: Animation = .default) -> Self {
        self.init(initialState: .init(offset: from))
            .keyframe({ $0.offset = to }, animation: animation)
    }

    static var glow: Self { .glow() }
    static func glow(from: Bool = false, to: Bool = true, animation: Animation = .default) -> Self {
        self.init(initialState: .init(glow: from))
            .keyframe({ $0.glow = to }, animation: animation)
    }
}

public extension TransitionAnimationConfig {

    func opacity(from: Double = 0.0, to: Double = 1, animation: Animation = .default) -> Self {
        var updated = self
        updated.state.opacity = from
        return updated.opacityFromCurrent(to: to, animation: animation)
    }

    func opacityFromCurrent(to: Double = 1, animation: Animation = .default) -> Self {
        keyframe({ $0.opacity = to }, animation: animation)
    }

    func scale(from: Double = .leastNonzeroMagnitude, to: CGFloat = 1, animation: Animation = .default) -> Self {
        var updated = self
        updated.state.scale = from
        return updated.scaleFromCurrent(to: to, animation: animation)
    }

    func scaleFromCurrent(to: CGFloat = 1, animation: Animation = .default) -> Self {
        keyframe({ $0.scale = to }, animation: animation)
    }

    func rotation(from: Angle, to: Angle = .zero, animation: Animation = .default) -> Self {
        var updated = self
        updated.state.rotation = from
        return updated.rotationFromCurrent(to: to, animation: animation)
    }

    func rotationFromCurrent(to: Angle = .zero, animation: Animation = .default) -> Self {
        keyframe({ $0.rotation = to }, animation: animation)
    }

    func offset(from: CGPoint, to: CGPoint = .zero, animation: Animation = .default) -> Self {
        var updated = self
        updated.state.offset = from
        return updated.offsetFromCurrent(to: to, animation: animation)
    }

    func offsetFromCurrent(to: CGPoint = .zero, animation: Animation = .default) -> Self {
        keyframe({ $0.offset = to }, animation: animation)
    }

    func glow(from: Bool = false, to: Bool = true, animation: Animation = .default) -> Self {
        var updated = self
        updated.state.glow = from
        return updated.glowFromCurrent(to: to, animation: animation)
    }

    func glowFromCurrent(to: Bool = true, animation: Animation = .default) -> Self {
        keyframe({ $0.glow = to }, animation: animation)
    }
}

struct TransitionAnimation: ViewModifier {
    typealias ViewState = TransitionAnimationConfig.ViewState

    @State
    private var config: TransitionAnimationConfig
    private var startTransition: Bool
    private let startOnAppear: Bool

    init(config: TransitionAnimationConfig,
         startTransition: Bool = false,
         startOnAppear: Bool = false) {
        self.config = config
        self.startTransition = startTransition
        self.startOnAppear = startOnAppear
    }

    private var state: ViewState {
        config.state
    }

    func body(content: Content) -> some View {
        return content
            .rotationEffect(state.rotation)
            .offset(.init(width: state.offset.x, height: state.offset.y))
            .opacity(state.opacity)
            .scaleEffect(state.scale)
            .onChange(of: startTransition, perform: { start in
                guard start else { return }
                startAnimations()
            })
            .onAppear {
                guard startOnAppear || startTransition else { return }
                startAnimations()
            }
    }

    private func startAnimations() {
        for keyframe in config.animations {
            withAnimation(keyframe.animation) {
                keyframe.modifier(&config.state)
            }
        }
    }
}
