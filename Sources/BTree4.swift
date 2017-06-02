private let internalOrder = 16

public struct BTree4<Element: Comparable> {
    fileprivate var root: Node

    public init(order: Int) {
        self.root = Node(order: order)
    }
}

extension BTree4 {
    public init() {
        let order = (cacheSize ?? 32768) / (4 * MemoryLayout<Element>.stride)
        self.init(order: Swift.max(16, order))
    }
}

extension BTree4 {
    class Node {
        let order: Int
        var mutationCount: Int64 = 0
        var elementCount: Int = 0
        let elements: UnsafeMutablePointer<Element>
        var children: ContiguousArray<Node> = []

        init(order: Int) {
            self.order = order
            self.elements = .allocate(capacity: order)
        }

        deinit {
            elements.deinitialize(count: elementCount)
            elements.deallocate(capacity: order)
        }
    }
}

extension BTree4 {
    public func forEach(_ body: (Element) throws -> Void) rethrows {
        try root.forEach(body)
    }
}

extension BTree4.Node {
    func forEach(_ body: (Element) throws -> Void) rethrows {
        if children.isEmpty {
            for i in 0 ..< elementCount {
                try body(elements[i])
            }
        }
        else {
            for i in 0 ..< elementCount {
                try children[i].forEach(body)
                try body(elements[i])
            }
            try children[elementCount].forEach(body)
        }
    }
}

extension BTree4.Node {
    internal func slot(of element: Element) -> (match: Bool, index: Int) {
        var start = 0
        var end = elementCount
        while start < end {
            let mid = start + (end - start) / 2
            if elements[mid] < element {
                start = mid + 1
            }
            else {
                end = mid
            }
        }
        let match = start < elementCount && elements[start] == element
        return (match, start)
    }
}

extension BTree4 {
    public func contains(_ element: Element) -> Bool {
        return root.contains(element)
    }
}

extension BTree4.Node {
    func contains(_ element: Element) -> Bool {
        let slot = self.slot(of: element)
        if slot.match { return true }
        guard !children.isEmpty else { return false }
        return children[slot.index].contains(element)
    }
}

extension BTree4.Node {
    func clone() -> BTree4<Element>.Node {
        let node = BTree4<Element>.Node(order: order)
        node.elementCount = self.elementCount
        node.elements.initialize(from: self.elements, count: self.elementCount)
        if !children.isEmpty {
            node.children.reserveCapacity(order + 1)
            node.children += self.children
        }
        return node
    }
}

extension BTree4.Node {
    var maxChildren: Int { return order }
    var minChildren: Int { return (maxChildren + 1) / 2 }
    var maxElements: Int { return maxChildren - 1 }
    var minElements: Int { return minChildren - 1 }

    var isLeaf: Bool { return children.isEmpty }
    var isTooLarge: Bool { return elementCount > maxElements }
}

extension BTree4 {
    struct Splinter {
        let separator: Element
        let node: Node
    }
}

extension BTree4.Node {
    func split() -> BTree4<Element>.Splinter {
        let count = self.elementCount
        let middle = count / 2

        let separator = elements[middle]
        let node = BTree4<Element>.Node(order: self.order)

        let c = count - middle - 1
        node.elements.moveInitialize(from: self.elements + middle + 1, count: c)
        node.elementCount = c
        self.elementCount = middle

        if !isLeaf {
            node.children.reserveCapacity(self.order + 1)
            node.children += self.children[middle + 1 ... count]
            self.children.removeSubrange(middle + 1 ... count)
        }
        return .init(separator: separator, node: node)
    }
}

extension UnsafeMutablePointer {
    @inline(__always)
    fileprivate mutating func advancingInitialize(to value: Pointee, count: Int = 1) {
        self.initialize(to: value, count: count)
        self += count
    }

    @inline(__always)
    fileprivate mutating func advancingInitialize(from source: UnsafePointer<Pointee>, count: Int) {
        self.initialize(from: source, count: count)
        self += count
    }
}

extension BTree4.Node {
    fileprivate func _insertElement(_ element: Element, at slot: Int) {
        assert(slot >= 0 && slot <= elementCount)
        (elements + slot + 1).moveInitialize(from: elements + slot, count: elementCount - slot)
        (elements + slot).initialize(to: element)
        elementCount += 1
    }
}


extension BTree4.Node {
    func _splittingInsert(_ element: Element, with child: BTree4<Element>.Node? = nil, at slot: Int) -> BTree4<Element>.Splinter? {
        _insertElement(element, at: slot)
        if let child = child {
            children.insert(child, at: slot + 1)
        }
        if elementCount <= maxElements {
            return nil
        }
        return split()
    }

    func insert(_ element: Element) -> (old: Element?, splinter: BTree4<Element>.Splinter?) {
        let slot = self.slot(of: element)
        if slot.match {
            // The element is already in the tree.
            return (self.elements[slot.index], nil)
        }
        mutationCount += 1
        if self.isLeaf {
            _insertElement(element, at: slot.index)
            return (nil, isTooLarge ? split() : nil)
        }

        if isKnownUniquelyReferenced(&children[slot.index]) {
            let (old, splinter) = children[slot.index].insert(element)
            guard let s = splinter else { return (old, nil) }
            _insertElement(s.separator, at: slot.index)
            children.insert(s.node, at: slot.index + 1)
            return (nil, isTooLarge ? split() : nil)
        }

        let (old, trunk, splinter) = children[slot.index].inserting(element)
        children[slot.index] = trunk
        if let s = splinter {
            _insertElement(s.separator, at: slot.index)
            children.insert(s.node, at: slot.index + 1)
            return (nil, isTooLarge ? split() : nil)
        }
        return (old, nil)
    }
}

extension BTree4.Node {
    private func _inserting(_ element: Element, with neighbors: (BTree4<Element>.Node, BTree4<Element>.Node)? = nil, at slot: Int) -> (trunk: BTree4<Element>.Node, splinter: BTree4<Element>.Splinter?) {
        if elementCount < maxElements {
            let trunk = BTree4<Element>.Node(order: order)
            trunk.elementCount = elementCount + 1
            var p = trunk.elements
            p.advancingInitialize(from: elements, count: slot)
            p.advancingInitialize(to: element)
            p.advancingInitialize(from: elements + slot, count: elementCount - slot)
            if let neighbors = neighbors {
                trunk.children = self.children
                trunk.children.insert(neighbors.1, at: slot + 1)
                trunk.children[slot] = neighbors.0
            }
            return (trunk, nil)
        }
        // Split
        let middle = (elementCount + 1) / 2
        let separator: Element
        let left = BTree4<Element>.Node(order: order)
        let right = BTree4<Element>.Node(order: order)
        left.elementCount = middle
        right.elementCount = elementCount - middle
        if middle < slot {
            separator = elements[middle]

            left.elements.initialize(from: elements, count: middle)

            var p = right.elements
            p.advancingInitialize(from: elements + middle + 1, count: slot - middle - 1)
            p.advancingInitialize(to: element)
            p.advancingInitialize(from: elements + slot, count: elementCount - slot)

            if let neighbors = neighbors {
                left.children += children[0 ... middle]
                right.children += children[middle + 1 ..< slot]
                right.children.append(neighbors.0)
                right.children.append(neighbors.1)
                if slot < elementCount {
                    right.children += children[slot + 1 ... elementCount]
                }
            }
        }
        else if middle > slot {
            separator = elements[middle - 1]

            var p = left.elements
            p.advancingInitialize(from: elements, count: slot)
            p.advancingInitialize(to: element)
            p.advancingInitialize(from: elements + slot, count: middle - slot - 1)

            right.elements.initialize(from: elements + middle, count: elementCount - middle)

            if let neighbors = neighbors {
                left.children += children[0 ..< slot]
                left.children.append(neighbors.0)
                left.children.append(neighbors.1)
                left.children += children[slot + 1 ..< middle]
                right.children += children[middle ... elementCount]
            }
        }
        else { // median == slot
            separator = element

            left.elements.initialize(from: elements, count: middle)
            right.elements.initialize(from: elements + middle, count: elementCount - middle)

            if let neighbors = neighbors {
                left.children += children[0 ..< middle]
                left.children.append(neighbors.0)

                right.children.append(neighbors.1)
                right.children += children[middle + 1 ... elementCount]
            }
        }
        return (left, BTree4<Element>.Splinter(separator: separator, node: right))
    }

    func inserting(_ element: Element) -> (old: Element?, trunk: BTree4<Element>.Node, splinter: BTree4<Element>.Splinter?) {
        let slot = self.slot(of: element)
        if slot.match {
            // The element is already in the tree.
            return (self.elements[slot.index], self, nil)
        }
        if isLeaf {
            let (trunk, splinter) = self._inserting(element, at: slot.index)
            return (nil, trunk, splinter)
        }
        else {
            let (old, trunk, splinter) = self.children[slot.index].inserting(element)
            if let old = old { return (old, self, nil) }
            if let splinter = splinter {
                let (t, s) = self._inserting(splinter.separator, with: (trunk, splinter.node), at: slot.index)
                return (nil, t, s)
            }
            else {
                let node = self.clone()
                node.children[slot.index] = trunk
                return (nil, node, nil)
            }
        }
    }
}

extension BTree4.Node {
    convenience init(trunk: BTree4<Element>.Node, splinter: BTree4<Element>.Splinter) {
        self.init(order: internalOrder)
        self.elementCount = 1
        self.elements.initialize(to: splinter.separator)
        self.children = [trunk, splinter.node]
    }
}

extension BTree4 {
    @discardableResult
    public mutating func insert(_ element: Element) -> (inserted: Bool, memberAfterInsert: Element) {
        if isKnownUniquelyReferenced(&root) {
            let (old, splinter) = root.insert(element)
            if let splinter = splinter {
                self.root = Node(trunk: self.root, splinter: splinter)
            }
            return (old == nil, old ?? element)
        }
        else {
            let (old, trunk, splinter) = root.inserting(element)
            if let splinter = splinter {
                self.root = Node(trunk: trunk, splinter: splinter)
            }
            else {
                self.root = trunk
            }
            return (old == nil, old ?? element)
        }
    }
}

extension BTree4 {
    struct UnsafePathElement: Equatable {
        unowned(unsafe) let node: Node
        var slot: Int

        init(_ node: Node, _ slot: Int) {
            self.node = node
            self.slot = slot
        }

        var isLeaf: Bool { return node.isLeaf }
        var isAtEnd: Bool { return slot == node.elementCount }
        var value: Element? {
            guard slot < node.elementCount else { return nil }
            return node.elements[slot]
        }
        var child: Node {
            return node.children[slot]
        }

        static func ==(left: UnsafePathElement, right: UnsafePathElement) -> Bool {
            return left.node === right.node && left.slot == right.slot
        }
    }
}

extension BTree4 {
    public struct Index: Comparable {
        fileprivate weak var root: Node?
        fileprivate let mutationCount: Int64

        fileprivate var path: [UnsafePathElement]
        fileprivate var current: UnsafePathElement

        init(startOf tree: BTree4<Element>) {
            self.root = tree.root
            self.mutationCount = tree.root.mutationCount
            self.path = []
            self.current = UnsafePathElement(tree.root, 0)
            while !current.isLeaf { push(0) }
        }

        init(endOf tree: BTree4<Element>) {
            self.root = tree.root
            self.mutationCount = tree.root.mutationCount
            self.path = []
            self.current = UnsafePathElement(tree.root, tree.root.elementCount)
        }
    }
}

extension BTree4.Index {
    fileprivate func validate(for root: BTree4<Element>.Node) {
        precondition(self.root === root)
        precondition(self.mutationCount == root.mutationCount)
    }

    fileprivate static func validate(_ left: BTree4<Element>.Index, _ right: BTree4<Element>.Index) {
        precondition(left.root === right.root)
        precondition(left.mutationCount == right.mutationCount)
        precondition(left.root != nil)
        precondition(left.mutationCount == left.root!.mutationCount)
    }
}

extension BTree4.Index {
    fileprivate mutating func push(_ slot: Int) {
        path.append(current)
        let child = current.node.children[current.slot]
        current = BTree4<Element>.UnsafePathElement(child, slot)
    }

    fileprivate mutating func pop() {
        current = self.path.removeLast()
    }
}

extension BTree4.Index {
    fileprivate mutating func formSuccessor() {
        precondition(!current.isAtEnd, "Cannot advance beyond endIndex")
        current.slot += 1
        if current.isLeaf {
            while current.isAtEnd, current.node !== root {
                pop()
            }
        }
        else {
            while !current.isLeaf {
                push(0)
            }
        }
    }
}

extension BTree4.Index {
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
                push(c.isLeaf ? c.elementCount - 1 : c.elementCount)
            }
        }
    }
}

extension BTree4.Index {
    public static func ==(left: BTree4<Element>.Index, right: BTree4<Element>.Index) -> Bool {
        BTree4<Element>.Index.validate(left, right)
        return left.current == right.current
    }

    public static func <(left: BTree4<Element>.Index, right: BTree4<Element>.Index) -> Bool {
        BTree4<Element>.Index.validate(left, right)
        switch (left.current.value, right.current.value) {
        case let (a?, b?): return a < b
        case (nil, _): return false
        default: return true
        }
    }
}

extension BTree4: SortedSet {
    public var startIndex: Index { return Index(startOf: self) }
    public var endIndex: Index { return Index(endOf: self) }

    public subscript(index: Index) -> Element {
        get {
            index.validate(for: root)
            return index.current.value!
        }
    }

    public func formIndex(after i: inout Index) {
        i.validate(for: root)
        i.formSuccessor()
    }

    public func index(after i: Index) -> Index {
        i.validate(for: root)
        var i = i
        i.formSuccessor()
        return i
    }

    public func formIndex(before i: inout Index) {
        i.validate(for: root)
        i.formPredecessor()
    }

    public func index(before i: Index) -> Index {
        i.validate(for: root)
        var i = i
        i.formPredecessor()
        return i
    }
}

extension BTree4 {
    public var count: Int {
        return root.count
    }
}

extension BTree4.Node {
    var count: Int {
        return children.reduce(elementCount) { $0 + $1.count }
    }
}

extension BTree4 {
    public struct Iterator: IteratorProtocol {
        let tree: BTree4
        var index: Index

        init(_ tree: BTree4) {
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

extension BTree4 {
    public func validate() {
        _ = root.validate(level: 0)
    }
}

extension BTree4.Node {
    func validate(level: Int, min: Element? = nil, max: Element? = nil) -> Int {
        // Check balance.
        precondition(!isTooLarge)
        precondition(level == 0 || elementCount >= minElements)

        if elementCount == 0 {
            precondition(children.isEmpty)
            return 0
        }

        // Check element ordering.
        var previous = min
        for i in 0 ..< elementCount {
            let next = elements[i]
            precondition(previous == nil || previous! < next)
            previous = next
        }

        if isLeaf {
            return 0
        }

        // Check children.
        precondition(children.count == elementCount + 1)
        let depth = children[0].validate(level: level + 1, min: min, max: elements[0])
        for i in 1 ..< elementCount {
            let d = children[i].validate(level: level + 1, min: elements[i - 1], max: elements[i])
            precondition(depth == d)
        }
        let d = children[elementCount].validate(level: level + 1, min: elements[elementCount - 1], max: max)
        precondition(depth == d)
        return depth + 1
    }
}
