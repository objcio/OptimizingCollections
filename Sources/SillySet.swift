struct SillySet<Element: Hashable & Comparable>: SortedSet, RandomAccessCollection {
    typealias Indices = CountableRange<Int>

    private var storage = SillyStorage<Element>([])
    
    var startIndex: Int { return 0 }
    var endIndex: Int { return storage.s.count + storage.extras.count }
    subscript(i: Int) -> Element {
        storage.commit()
        return storage.v[i]
    }
    
    func contains(_ element: Element) -> Bool {
        return storage.s.contains(element) || storage.extras.contains(element)
    }
    
    mutating func insert(_ element: Element) -> (inserted: Bool, memberAfterInsert: Element) {
        if !isKnownUniquelyReferenced(&storage) {
            storage = SillyStorage(storage.v)
        }
        if let i = storage.s.index(of: element) { return (false, storage.s[i]) }
        return storage.extras.insert(element)
    }
}

private class SillyStorage<Element: Hashable & Comparable> {
    var v: [Element]
    var s: Set<Element>
    var extras: Set<Element> = []
    
    init(_ v: [Element]) { 
        self.v = v
        self.s = Set(v) 
    }
    
    func commit() {
        guard !extras.isEmpty else { return }
        s.formUnion(extras)
        v += extras
        v.sort()
        extras = []
    }
}
