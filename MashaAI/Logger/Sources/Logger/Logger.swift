import Foundation
import Pulse

public enum LogOutput {
    case pulse, crashlytics
}

public struct Trace {
    public let file: String
    public let method: String
    public let line: UInt

    public init(
        file: String,
        method: String,
        line: UInt
    ) {
        self.file = file
        self.method = method
        self.line = line
    }
}

public protocol LoggerOutput {
    var output: LogOutput { get }

    func log(
        _ message: @autoclosure () -> String,
        category: LogCategory,
        level: LogLevel,
        params: [String : Any]?,
        _ context: Trace
    )
}

public protocol AppLogging {
    var outputs: [LoggerOutput] { get }
    func log(
        message: String,
        category: LogCategory,
        level: LogLevel,
        params: [String: Any]?,
        to outputs: [LogOutput],
        file: String,
        method: String,
        line: UInt
    )
}

extension AppLogging {
    public func log(
        message: String,
        category: LogCategory,
        level: LogLevel,
        params: [String: Any]? = nil,
        to outputs: [LogOutput] = [],
        file: String = #file,
        method: String = #function,
        line: UInt = #line
    ) {
        let context = Trace(file: file, method: method, line: line)

        self.outputs.forEach { output in
            if outputs.isEmpty || outputs.contains(output.output) {
                output.log(
                    message,
                    category: category,
                    level: level, 
                    params: params,
                    context
                )
            }
        }
    }
}

public enum LogLevel {
    case trace
    case debug
    case info
    case notice
    case warning
    case error
    case critical
}

public enum LogCategory: String {
    case appState = "App"
    case analytics = "Analytics"
    case error = "Error"
    case notification = "Notification"

    public func toDescription() -> String {
        switch self {
        case .appState:
            return "[APP_STATE]"
        case .analytics:
            return "[EVENT]"
        case .error:
            return "[ERROR]"
        case .notification:
            return "[NOTIFICATION]"
        }
    }
}

public extension Pulse.LoggerStore.Level {
    init(level: LogLevel) {
        switch level {
        case .trace:
            self = .trace
        case .debug:
            self = .debug
        case .info:
            self = .info
        case .notice:
            self = .notice
        case .warning:
            self = .warning
        case .error:
            self = .error
        case .critical:
            self = .critical
        }
    }
}
