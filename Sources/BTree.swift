public struct BTree<Element: Comparable> {
    fileprivate var root: Node

    init(order: Int) {
        self.root = Node(order: order)
    }
}

extension BTree {
    final class Node {
        let order: Int
        var mutationCount: Int64 = 0
        var elements: [Element] = []
        var children: [Node] = []

        init(order: Int) {
            self.order = order
        }
    }
}

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#elseif os(Linux)
import Glibc
#endif

let cacheSize: Int? = {
    #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
        var result: Int = 0
        var size = MemoryLayout<Int>.size
        let status = sysctlbyname("hw.l1dcachesize", &result, &size, nil, 0)
        guard status != -1 else { return nil }
        return result
    #elseif os(Linux)
        let result = sysconf(Int32(_SC_LEVEL1_DCACHE_SIZE))
        guard result != -1 else { return nil }
        return result
    #else
        return nil // Unknown platform
    #endif
}()

extension BTree {
    public init() {
        let order = (cacheSize ?? 32768) / (4 * MemoryLayout<Element>.stride)
        self.init(order: Swift.max(16, order))
    }
}

extension BTree {
    public func forEach(_ body: (Element) throws -> Void) rethrows {
        try root.forEach(body)
    }
}

extension BTree.Node {
    func forEach(_ body: (Element) throws -> Void) rethrows {
        if children.isEmpty {
            try elements.forEach(body)
        }
        else {
            for i in 0 ..< elements.count {
                try children[i].forEach(body)
                try body(elements[i])
            }
            try children[elements.count].forEach(body)
        }
    }
}

extension BTree.Node {
    internal func slot(of element: Element) -> (match: Bool, index: Int) {
        var start = 0
        var end = elements.count
        while start < end {
            let mid = start + (end - start) / 2
            if elements[mid] < element {
                start = mid + 1
            }
            else {
                end = mid
            }
        }
        let match = start < elements.count && elements[start] == element
        return (match, start)
    }
}

extension BTree {
    public func contains(_ element: Element) -> Bool {
        return root.contains(element)
    }
}

extension BTree.Node {
    func contains(_ element: Element) -> Bool {
        let slot = self.slot(of: element)
        if slot.match { return true }
        guard !children.isEmpty else { return false }
        return children[slot.index].contains(element)
    }
}

extension BTree {
    fileprivate mutating func makeRootUnique() -> Node {
        if isKnownUniquelyReferenced(&root) { return root }
        root = root.clone()
        return root
    }
}

extension BTree.Node {
    func clone() -> BTree<Element>.Node {
        let clone = BTree<Element>.Node(order: order)
        clone.elements = self.elements
        clone.children = self.children
        return clone
    }
}

extension BTree.Node {
    func makeChildUnique(at slot: Int) -> BTree<Element>.Node {
        guard !isKnownUniquelyReferenced(&children[slot]) else {
            return children[slot]
        }
        let clone = children[slot].clone()
        children[slot] = clone
        return clone
    }
}

extension BTree.Node {
    var isLeaf: Bool { return children.isEmpty }
    var isTooLarge: Bool { return elements.count >= order }
}

extension BTree {
    struct Splinter {
        let separator: Element
        let node: Node
    }
}

extension BTree.Node {
    func split() -> BTree<Element>.Splinter {
        let count = self.elements.count
        let middle = count / 2

        let separator = self.elements[middle]

        let node = BTree<Element>.Node(order: order)
        node.elements.append(contentsOf: self.elements[middle + 1 ..< count])
        self.elements.removeSubrange(middle ..< count)
        
        if !isLeaf {
            node.children.append(contentsOf: self.children[middle + 1 ..< count + 1])
            self.children.removeSubrange(middle + 1 ..< count + 1)
        }
        return .init(separator: separator, node: node)
    }
}

extension BTree.Node {
    func insert(_ element: Element) -> (old: Element?, splinter: BTree<Element>.Splinter?) {

        let slot = self.slot(of: element)
        if slot.match {
            // The element is already in the tree.
            return (self.elements[slot.index], nil)
        }

        mutationCount += 1

        if self.isLeaf {
            elements.insert(element, at: slot.index)
            return (nil, self.isTooLarge ? self.split() : nil)
        }

        let (old, splinter) = makeChildUnique(at: slot.index).insert(element)
        guard let s = splinter else { return (old, nil) }
        elements.insert(s.separator, at: slot.index)
        children.insert(s.node, at: slot.index + 1)
        return (nil, self.isTooLarge ? self.split() : nil)
    }
}

extension BTree {
    @discardableResult
    public mutating func insert(_ element: Element) -> (inserted: Bool, memberAfterInsert: Element) {
        let root = makeRootUnique()
        let (old, splinter) = root.insert(element)
        if let splinter = splinter {
            let r = Node(order: root.order)
            r.elements = [splinter.separator]
            r.children = [root, splinter.node]
            self.root = r
        }
        return (old == nil, old ?? element)
    }
}

extension BTree {
    struct UnsafePathElement {
        unowned(unsafe) let node: Node
        var slot: Int

        init(_ node: Node, _ slot: Int) {
            self.node = node
            self.slot = slot
        }
    }
}

extension BTree.UnsafePathElement {
    var value: Element? {
        guard slot < node.elements.count else { return nil }
        return node.elements[slot]
    }
    var child: BTree<Element>.Node {
        return node.children[slot]
    }
    var isLeaf: Bool { return node.isLeaf }
    var isAtEnd: Bool { return slot == node.elements.count }
}

extension BTree.UnsafePathElement: Equatable {
    static func ==(left: BTree<Element>.UnsafePathElement, right: BTree<Element>.UnsafePathElement) -> Bool {
        return left.node === right.node && left.slot == right.slot
    }
}

extension BTree {
    public struct Index {
        fileprivate weak var root: Node?
        fileprivate let mutationCount: Int64

        fileprivate var path: [UnsafePathElement]
        fileprivate var current: UnsafePathElement

        init(startOf tree: BTree) {
            self.root = tree.root
            self.mutationCount = tree.root.mutationCount
            self.path = []
            self.current = UnsafePathElement(tree.root, 0)
            while !current.isLeaf { push(0) }
        }

        init(endOf tree: BTree) {
            self.root = tree.root
            self.mutationCount = tree.root.mutationCount
            self.path = []
            self.current = UnsafePathElement(tree.root, tree.root.elements.count)
        }
    }
}

extension BTree.Index {
    fileprivate func validate(for root: BTree<Element>.Node) {
        precondition(self.root === root)
        precondition(self.mutationCount == root.mutationCount)
    }

    fileprivate static func validate(_ left: BTree<Element>.Index, _ right: BTree<Element>.Index) {
        precondition(left.root === right.root)
        precondition(left.mutationCount == right.mutationCount)
        precondition(left.root != nil)
        precondition(left.mutationCount == left.root!.mutationCount)
    }
}

extension BTree.Index {
    fileprivate mutating func push(_ slot: Int) {
        path.append(current)
        let child = current.node.children[current.slot]
        current = BTree<Element>.UnsafePathElement(child, slot)
    }

    fileprivate mutating func pop() {
        current = self.path.removeLast()
    }
}

extension BTree.Index {
    fileprivate mutating func formSuccessor() {
        precondition(!current.isAtEnd, "Cannot advance beyond endIndex")
        current.slot += 1
        if current.isLeaf {
            // This loop will rarely execute even once.
            while current.isAtEnd, current.node !== root {
                // Ascend to the nearest ancestor that has further elements.
                pop()
            }
        }
        else {
            // Descend to the start of the leftmost leaf node under us.
            while !current.isLeaf {
                push(0)
            }
        }
    }
}

extension BTree.Index {
    fileprivate mutating func formPredecessor() {
        if current.isLeaf {
            while current.slot == 0, current.node !== root {
                pop()
            }
            precondition(current.slot > 0, "Cannot go below startIndex")
            current.slot -= 1
        }
        else {
            while !current.isLeaf {
                let c = current.child
                push(c.isLeaf ? c.elements.count - 1 : c.elements.count)
            }
        }
    }
}

extension BTree.Index: Comparable {
    public static func ==(left: BTree<Element>.Index, right: BTree<Element>.Index) -> Bool {
        BTree<Element>.Index.validate(left, right)
        return left.current == right.current
    }

    public static func <(left: BTree<Element>.Index, right: BTree<Element>.Index) -> Bool {
        BTree<Element>.Index.validate(left, right)
        switch (left.current.value, right.current.value) {
        case let (a?, b?): return a < b
        case (nil, _): return false
        default: return true
        }
    }
}

extension BTree: SortedSet {
    public var startIndex: Index { return Index(startOf: self) }
    public var endIndex: Index { return Index(endOf: self) }

    public subscript(index: Index) -> Element {
        index.validate(for: root)
        return index.current.value!
    }

    public func formIndex(after i: inout Index) {
        i.validate(for: root)
        i.formSuccessor()
    }

    public func formIndex(before i: inout Index) {
        i.validate(for: root)
        i.formPredecessor()
    }

    public func index(after i: Index) -> Index {
        i.validate(for: root)
        var i = i
        i.formSuccessor()
        return i
    }

    public func index(before i: Index) -> Index {
        i.validate(for: root)
        var i = i
        i.formPredecessor()
        return i
    }
}

extension BTree {
    public var count: Int {
        return root.count
    }
}

extension BTree.Node {
    var count: Int {
        return children.reduce(elements.count) { $0 + $1.count }
    }
}

extension BTree {
    public struct Iterator: IteratorProtocol {
        let tree: BTree
        var index: Index

        init(_ tree: BTree) {
            self.tree = tree
            self.index = tree.startIndex
        }

        public mutating func next() -> Element? {
            guard let result = index.current.value else { return nil }
            index.formSuccessor()
            return result
        }
    }
    
    public func makeIterator() -> Iterator {
        return Iterator(self)
    }
}
