import Foundation

private class Canary {}

public struct MyOrderedSet<Element: Comparable>: OrderedSet {
    fileprivate var storage = NSMutableOrderedSet()
    fileprivate var canary = Canary()
    public init() {}
}

extension MyOrderedSet {
    public func contains(_ element: Element) -> Bool {
        return storage.contains(element)
    }
}

extension MyOrderedSet {
    public func forEach(_ body: (Element) -> Void) {
        storage.forEach { body($0 as! Element) }
    }
}

extension MyOrderedSet: RandomAccessCollection {
    public typealias Index = Int
    public typealias Indices = CountableRange<Int>

    public var startIndex: Int { return 0 }
    public var endIndex: Int { return storage.count }
    public subscript(i: Int) -> Element { return storage[i] as! Element }
}

extension MyOrderedSet {
    fileprivate mutating func makeUnique() {
        if !isKnownUniquelyReferenced(&canary) {
            storage = storage.mutableCopy() as! NSMutableOrderedSet
            canary = Canary()
        }
    }
}

extension MyOrderedSet {
    private static func compare(_ a: Any, _ b: Any) -> ComparisonResult 
    {
        let a = a as! Element, b = b as! Element
        return a < b ? .orderedAscending
            : a > b ? .orderedDescending
            : .orderedSame
    }

    fileprivate func index(for element: Element) -> Int {
        return storage.index(
            of: element, 
            inSortedRange: NSRange(0 ..< storage.count),
            options: .insertionIndex, 
            usingComparator: MyOrderedSet.compare)
    }

    @discardableResult
    public mutating func insert(_ newElement: Element) -> (inserted: Bool, memberAfterInsert: Element) 
    {
        let index = self.index(for: newElement)
        if index < storage.count, storage[index] as! Element == newElement {
            return (false, storage[index] as! Element)
        }
        makeUnique()
        storage.insert(newElement, at: index)
        return (true, newElement)
    }
}
