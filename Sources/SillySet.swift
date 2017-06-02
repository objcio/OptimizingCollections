struct SillySet<Element: Hashable & Comparable>: SortedSet, RandomAccessCollection {
    typealias Indices = CountableRange<Int>

    class Storage {
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

    private var storage = Storage([])
    
    var startIndex: Int { return 0 }
    
    var endIndex: Int { return storage.s.count + storage.extras.count }
    
    // Complexity: `O(n*log(n))`, where `n` is the number of insertions since the last time `subscript` was called.
    subscript(i: Int) -> Element {
        storage.commit()
        return storage.v[i]
    }
    
    // Complexity: O(1)
    func contains(_ element: Element) -> Bool {
        return storage.s.contains(element) || storage.extras.contains(element)
    }
    
    // Complexity: O(1) unless storage is shared.
    mutating func insert(_ element: Element) -> (inserted: Bool, memberAfterInsert: Element) {
        if !isKnownUniquelyReferenced(&storage) {
            storage = Storage(storage.v)
        }
        if let i = storage.s.index(of: element) { return (false, storage.s[i]) }
        return storage.extras.insert(element)
    }
}
