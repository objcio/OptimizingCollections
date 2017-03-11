public struct COWTree<Element: Comparable>: OrderedSet {
    var root: COWNode<Element>? = nil
    
    public init() {}
}

final class COWNode<Element: Comparable> {
    var color: Color
    var left: COWNode<Element>? = nil
    var value: Element
    var right: COWNode<Element>? = nil
    var mutationCount: Int = 0

    init(_ color: Color, _ left: COWNode?, _ value: Element, _ right: COWNode?) {
        self.color = color
        self.left = left
        self.value = value
        self.right = right
    }
}

extension COWTree {
    public func forEach(_ body: (Element) throws -> Void) rethrows {
        try root?.forEach(body)
    }
}

extension COWNode {
    func forEach(_ body: (Element) throws -> Void) rethrows {
        try left?.forEach(body)
        try body(value)
        try right?.forEach(body)
    }
}

extension COWTree {
    public func contains(_ element: Element) -> Bool {
        var node = root
        while let n = node {
            if n.value < element {
                node = n.right
            }
            else if n.value > element {
                node = n.left
            }
            else {
                return true
            }
        }
        return false
    }
}

private func diagram<Element: Comparable>(for node: COWNode<Element>?, _ top: String = "", _ root: String = "", _ bottom: String = "") -> String {
    guard let node = node else {
        return root + "•\n"
    }
    if node.left == nil && node.right == nil {
        return root + "\(node.color.symbol) \(node.value)\n"
    }
    return diagram(for: node.right, top + "    ", top + "┌───", top + "│   ")
        + root + "\(node.color.symbol) \(node.value)\n"
        + diagram(for: node.left, bottom + "│   ", bottom + "└───", bottom + "    ")
}

extension COWTree: CustomStringConvertible {
    public var description: String {
        return diagram(for: root)
    }
}

extension COWNode {
    func clone() -> COWNode {
        return COWNode(color, left, value, right)
    }
}

extension COWTree {
    mutating func makeRootUnique() -> COWNode<Element>? {
        if root != nil, !isKnownUniquelyReferenced(&root) {
            root = root!.clone()
        }
        return root
    }
}

extension COWNode {
    func makeLeftUnique() -> COWNode? {
        if left != nil, !isKnownUniquelyReferenced(&left) {
            left = left!.clone()
        }
        return left
    }

    func makeRightUnique() -> COWNode? {
        if right != nil, !isKnownUniquelyReferenced(&right) {
            right = right!.clone()
        }
        return right
    }
}

extension COWTree {
    @discardableResult
    public mutating func insert(_ element: Element) -> (inserted: Bool, memberAfterInsert: Element) {
        guard let root = makeRootUnique() else {
            self.root = COWNode(.black, nil, element, nil)
            return (true, element)
        }
        defer { root.color = .black }
        return root.insert(element)
    }
}

extension COWNode {
    func insert(_ element: Element)  -> (inserted: Bool, memberAfterInsert: Element) {
        mutationCount += 1
        if element < self.value {
            if let next = makeLeftUnique() {
                let result = next.insert(element)
                if result.inserted { self.balance() }
                return result
            }
            else {
                self.left = COWNode(.red, nil, element, nil)
                return (inserted: true, memberAfterInsert: element)
            }
        }
        if element > self.value {
            if let next = makeRightUnique() {
                let result = next.insert(element)
                if result.inserted { self.balance() }
                return result
            }
            else {
                self.right = COWNode(.red, nil, element, nil)
                return (inserted: true, memberAfterInsert: element)
            }
        }
        return (inserted: false, memberAfterInsert: self.value)
    }
}

extension COWNode {
    func balance() {
        if self.color == .red  { return }
        if left?.color == .red {
            if left?.left?.color == .red {
                let l = left!
                let ll = l.left!
                swap(&self.value, &l.value)
                (self.left, l.left, l.right, self.right) = (ll, l.right, self.right, l)
                self.color = .red
                l.color = .black
                ll.color = .black
                return
            }
            if left?.right?.color == .red {
                let l = left!
                let lr = l.right!
                swap(&self.value, &lr.value)
                (l.right, lr.left, lr.right, self.right) = (lr.left, lr.right, self.right, lr)
                self.color = .red
                l.color = .black
                lr.color = .black
                return
            }
        }
        if right?.color == .red {
            if right?.left?.color == .red {
                let r = right!
                let rl = r.left!
                swap(&self.value, &rl.value)
                (self.left, rl.left, rl.right, r.left) = (rl, self.left, rl.left, rl.right)
                self.color = .red
                r.color = .black
                rl.color = .black
                return
            }
            if right?.right?.color == .red {
                let r = right!
                let rr = r.right!
                swap(&self.value, &r.value)
                (self.left, r.left, r.right, self.right) = (r, self.left, r.left, rr)
                self.color = .red
                r.color = .black
                rr.color = .black
                return
            }
        }
    }
}

private struct Weak<Wrapped: AnyObject> {
    weak var value: Wrapped?

    init(_ value: Wrapped) {
        self.value = value
    }
}

public struct COWTreeIndex<Element: Comparable> {
    fileprivate weak var root: COWNode<Element>?
    fileprivate let mutationCount: Int
    
    fileprivate var path: [Weak<COWNode<Element>>]
    
    fileprivate init(root: COWNode<Element>?, path: [Weak<COWNode<Element>>]) {
        self.root = root
        self.mutationCount = root?.mutationCount ?? -1
        self.path = path
    }
}

extension COWTreeIndex {
    fileprivate func validate(for root: COWNode<Element>?) {
        precondition(self.root === root)
        precondition(self.mutationCount == root?.mutationCount ?? -1)
    }
}

extension COWTreeIndex {
    fileprivate static func validate(_ left: COWTreeIndex, _ right: COWTreeIndex) {
        precondition(left.root === right.root)
        precondition(left.mutationCount == right.mutationCount)
        precondition(left.mutationCount == left.root?.mutationCount ?? -1)
    }
}

extension COWTreeIndex {
    fileprivate var current: COWNode<Element>? {
        guard let ref = path.last else { return nil }
        return ref.value!
    }
}

extension COWTreeIndex: Comparable {
    public static func ==(left: COWTreeIndex, right: COWTreeIndex) -> Bool {
        COWTreeIndex.validate(left, right)
        return left.current === right.current
    }

    public static func <(left: COWTreeIndex, right: COWTreeIndex) -> Bool {
        COWTreeIndex.validate(left, right)
        switch (left.current, right.current) {
        case let (.some(a), .some(b)):
            return a.value < b.value
        case (.none, _):
            return false
        default:
            return true
        }
    }
}

extension COWTree: BidirectionalCollection {
    public typealias Index = COWTreeIndex<Element>

    public var endIndex: Index {
        return Index(root: root, path: [])
    }

    public var startIndex: Index {
        var path: [Weak<COWNode<Element>>] = []
        var node = root
        while let n = node {
            path.append(Weak(n))
            node = n.left
        }
        return Index(root: root, path: path)
    }
}

extension COWTree {
    public subscript(_ index: Index) -> Element {
        index.validate(for: root)
        return index.path.last!.value!.value
    }
}

extension COWTree {
    public func formIndex(after index: inout Index) {
        index.validate(for: root)
        index.formSuccessor()
    }

    public func index(after index: Index) -> Index {
        var result = index
        self.formIndex(after: &result)
        return result
    }
}

extension COWTreeIndex {
    mutating func formSuccessor() {
        guard let node = current else { preconditionFailure() }
        if var n = node.right {
            path.append(Weak(n))
            while let next = n.left {
                path.append(Weak(next))
                n = next
            }
        }
        else {
            path.removeLast()
            var n = node
            while let parent = self.current {
                if parent.left === n { return }
                n = parent
                path.removeLast()
            }
        }
    }
}

extension COWTree {
    public func formIndex(before index: inout Index) {
        index.validate(for: root)
        index.formPredecessor()
    }

    public func index(before index: Index) -> Index {
        var result = index
        self.formIndex(before: &result)
        return result
    }
}

extension COWTreeIndex {
    mutating func formPredecessor() {
        guard let node = current else { preconditionFailure() }
        if var n = node.left {
            path.append(Weak(n))
            while let next = n.right {
                path.append(Weak(next))
                n = next
            }
        }
        else {
            path.removeLast()
            var n = node
            while let parent = self.current {
                if parent.right === n { return }
                n = parent
                path.removeLast()
            }
        }
    }
}
