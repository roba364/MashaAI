import Foundation

@resultBuilder
public struct ArrayBuilder<Element> {
    public static func buildBlock() -> [Element] {
        []
    }

    public static func buildEither(first: [Element]) -> [Element] {
        first
    }

    public static func buildEither(second: [Element]) -> [Element] {
        second
    }

    public static func buildOptional(_ children: [Element]?) -> [Element] {
        children ?? []
    }

    public static func buildPartialBlock(first: Never) -> [Element] {}

    public static func buildPartialBlock(first: Element) -> [Element] {
        [first]
    }

    public static func buildPartialBlock(first: [Element]) -> [Element] {
        first
    }

    public static func buildPartialBlock(accumulated: [Element],
                                         next: Element) -> [Element] {
        accumulated + [next]
    }

    public static func buildPartialBlock(accumulated: [Element],
                                         next: [Element]) -> [Element] {
        accumulated + next
    }

    public static func buildBlock(_ components: [Element]...) -> [Element] {
        components.flatMap { $0 }
    }

    public static func buildArray(_ components: [[Element]]) -> [Element] {
        components.flatMap { $0 }
    }

    public static func buildExpression(_ expression: Element) -> [Element] {
        [expression]
    }

    public static func buildExpression(_ expression: [Element]) -> [Element] {
        expression
    }
}

public extension Array {
    init(@ArrayBuilder<Element> builder: () -> [Element]) {
        self = builder()
    }
}

