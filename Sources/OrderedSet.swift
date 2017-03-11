public protocol OrderedSet: BidirectionalCollection, CustomStringConvertible {
    associatedtype Element: Comparable

    init()
    func contains(_ element: Element) -> Bool
    func forEach(_ body: (Element) throws -> Void) rethrows
    mutating func insert(_ newElement: Element) -> (inserted: Bool, memberAfterInsert: Element)
}

extension OrderedSet {
    public var description: String {
        let contents = self.lazy.map { "\($0)" }.joined(separator: ", ")
        return "[\(contents)]"
    }
}
