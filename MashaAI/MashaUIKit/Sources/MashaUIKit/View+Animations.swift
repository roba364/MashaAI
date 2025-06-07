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
