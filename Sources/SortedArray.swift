public struct SortedArray<Element: Comparable>: SortedSet {
    fileprivate var storage: [Element] = []
    
    public init() {}
}

extension SortedArray {
    func index(for element: Element) -> Int {
        var start = 0
        var end = storage.count
        while start < end {
            let middle = start + (end - start) / 2
            if element > storage[middle] {
                start = middle + 1
            }
            else {
                end = middle
            }
        }
        return start
    }
}

extension SortedArray {
    public func index(of element: Element) -> Int? {
        let index = self.index(for: element)
        guard index < count, storage[index] == element else { return nil }
        return index
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
    public func sorted() -> [Element] {
        return storage
    }
}

extension SortedArray {
    @discardableResult
    public mutating func insert(_ newElement: Element) -> (inserted: Bool, memberAfterInsert: Element) 
    {
        let index = self.index(for: newElement)
        if index < count && storage[index] == newElement {
            return (false, storage[index])
        }
        storage.insert(newElement, at: index)
        return (true, newElement)
    }
}

extension SortedArray: RandomAccessCollection {
    public typealias Indices = CountableRange<Int>

    public var startIndex: Int { return storage.startIndex }
    public var endIndex: Int { return storage.endIndex }

    public subscript(index: Int) -> Element { return storage[index] }
}

extension SortedArray {
    func index2(for element: Element) -> Int {
        var start = 0
        var end = storage.count
        while start < end {
            let middle = start + (end - start) / 2 + (end - start) >> 6
            if element > storage[middle] {
                start = middle + 1
            }
            else {
                end = middle
            }
        }
        return start
    }

    public func contains2(_ element: Element) -> Bool {
        let index = self.index2(for: element)
        return index < count && storage[index] == element
    }
    
    func index3(for element: Element) -> Int {
        var start = 0
        var end = storage.count
        while start < end {
            let diff = end - start
            if diff < 1024 {
                let middle = start + diff >> 1
                if element > storage[middle] {
                    start = middle + 1
                }
                else {
                    end = middle
                }
            }
            else {
                let third = diff / 3
                let m1 = start + third
                let m2 = end - third
                let v1 = storage[m1]
                let v2 = storage[m2]
                if element < v1 {
                    end = m1
                }
                else if element > v2 {
                    start = m2 + 1
                }
                else {
                    start = m1
                    end = m2 + 1
                }
            }
        }
        return start
    }
    
    public func contains3(_ element: Element) -> Bool {
        let index = self.index3(for: element)
        return index < count && storage[index] == element
    }
}
