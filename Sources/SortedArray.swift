public struct SortedArray<Element: Comparable>: OrderedSet {
    fileprivate var storage: [Element] = []
    
    public init() {}
}

extension SortedArray {
    func index(for element: Element) -> Int {
        var i = 0
        var j = storage.count
        while i < j {
            let middle = i + (j - i) / 2
            if element > storage[middle] {
                i = middle + 1
            }
            else {
                j = middle
            }
        }
        return i
    }
}

extension SortedArray {
    public func index(of element: Element) -> Int? {
        let i = index(for: element)
        guard i < count, self[i] == element else { return nil }
        return i
    }
}

extension SortedArray {
    public func contains(_ element: Element) -> Bool {
        let index = self.index(for: element)
        return index < count && storage[index] == element
    }
}

extension SortedArray {
    public func forEach(_ body: (Element) throws -> Void) rethrows {
        try storage.forEach(body)
    }
}

extension SortedArray {
    @discardableResult
    public mutating func insert(_ newElement: Element) -> (inserted: Bool, memberAfterInsert: Element) 
    {
        let i = self.index(for: newElement)
        if i < count && storage[i] == newElement {
            return (false, storage[i])
        }
        storage.insert(newElement, at: i)
        return (true, newElement)
    }
}

extension SortedArray: RandomAccessCollection {
    public typealias Indices = CountableRange<Int>

    public var startIndex: Int { return 0 }
    public var endIndex: Int { return storage.count }

    public subscript(index: Int) -> Element { return storage[index] }
}
