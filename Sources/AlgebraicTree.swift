public enum Color {
    case black
    case red
}

public enum AlgebraicTree<Element: Comparable> {
    case empty
    indirect case node(Color, Element, AlgebraicTree, AlgebraicTree)
}

public extension AlgebraicTree {
    func contains(_ element: Element) -> Bool {
        switch self {
        case .empty:
            return false
        case .node(_, element, _, _):
            return true
        case let .node(_, value, left, _) where value > element:
            return left.contains(element)
        case let .node(_, _, _, right):
            return right.contains(element)
        }
    }
}

public extension AlgebraicTree {
    func forEach(_ body: (Element) throws -> Void) rethrows {
        switch self {
        case .empty:
            break
        case let .node(_, value, left, right):
            try left.forEach(body)
            try body(value)
            try right.forEach(body)
        }
    }
}

extension Color {
    var symbol: String {
        switch self {
        case .black: return "■"
        case .red:   return "□"
        }
    }
}

extension AlgebraicTree: CustomStringConvertible {
    func diagram(_ top: String, _ root: String, _ bottom: String) -> String {
        switch self {
        case .empty:
            return root + "•\n"
        case let .node(color, value, .empty, .empty):
            return root + "\(color.symbol) \(value)\n"
        case let .node(color, value, left, right):
            return right.diagram(top + "    ", top + "┌───", top + "│   ")
                + root + "\(color.symbol) \(value)\n"
                + left.diagram(bottom + "│   ", bottom + "└───", bottom + "    ")
        }
    }

    public var description: String {
        return self.diagram("", "", "")
    }
}

extension AlgebraicTree {
    @discardableResult
    public mutating func insert(_ element: Element) -> (inserted: Bool, memberAfterInsert: Element) 
    {
        let (tree, old) = inserting(element)
        self = tree
        return (old == nil, old ?? element)
    }
}

extension AlgebraicTree {
    public func inserting(_ element: Element) -> (tree: AlgebraicTree, existingMember: Element?) 
    {
        let (tree, old) = _inserting(element)
        if case let .node(.red, value, left, right) = tree {
            return (.node(.black, value, left, right), old)
        }
        return (tree, old)
    }
}

extension AlgebraicTree {
    func _inserting(_ element: Element) -> (tree: AlgebraicTree, old: Element?) 
    {
        switch self {

        case .empty:
            return (.node(.red, element, .empty, .empty), nil)

        case let .node(_, value, _, _) where value == element:
            return (self, value)

        case let .node(color, value, left, right) where value > element:
            let (l, old) = left._inserting(element)
            if let old = old { return (self, old) }
            return (balanced(color, value, l, right), nil)

        case let .node(color, value, left, right):
            let (r, old) = right._inserting(element)
            if let old = old { return (self, old) }
            return (balanced(color, value, left, r), nil)
        }
    }
}

extension AlgebraicTree {
    func balanced_(_ color: Color, _ value: Element, _ left: AlgebraicTree, _ right: AlgebraicTree) -> AlgebraicTree {
        switch (color, value, left, right) {
        case let (.black, z, .node(.red, y, .node(.red, x, a, b), c), d),
            let (.black, z, .node(.red, x, a, .node(.red, y, b, c)), d),
            let (.black, x, a, .node(.red, z, .node(.red, y, b, c), d)),
            let (.black, x, a, .node(.red, y, b, .node(.red, z, c, d))):
            return .node(.red, y, .node(.black, x, a, b), .node(.black, z, c, d))
        default:
            return .node(color, value, left,  right)
        }
    }
}

extension AlgebraicTree {
    func balanced(_ color: Color, _ value: Element, _ left: AlgebraicTree, _ right: AlgebraicTree) -> AlgebraicTree {
        switch (color, value, left, right) {
        case let (.black, z, .node(.red, y, .node(.red, x, a, b), c), d):
            return .node(.red, y, .node(.black, x, a, b), .node(.black, z, c, d))
        case let (.black, z, .node(.red, x, a, .node(.red, y, b, c)), d):
            return .node(.red, y, .node(.black, x, a, b), .node(.black, z, c, d))
        case let (.black, x, a, .node(.red, z, .node(.red, y, b, c), d)):
            return .node(.red, y, .node(.black, x, a, b), .node(.black, z, c, d))
        case let (.black, x, a, .node(.red, y, b, .node(.red, z, c, d))):
            return .node(.red, y, .node(.black, x, a, b), .node(.black, z, c, d))
        default:
            return .node(color, value, left, right)
        }
    }
}

public struct AlgebraicIndex<Element: Comparable> {
    fileprivate var value: Element?
}

extension AlgebraicIndex: Comparable {
    public static func ==(left: AlgebraicIndex, right: AlgebraicIndex) -> Bool {
        return left.value == right.value
    }

    public static func <(left: AlgebraicIndex, right: AlgebraicIndex) -> Bool {
        if let lv = left.value, let rv = right.value { return lv < rv }
        return left.value != nil
    }
}

extension AlgebraicTree {
    var minimum: Element? {
        switch self {
        case .empty: 
            return nil 
        case let .node(_, value, left, _): 
            return left.minimum ?? value
        }
    }
}

extension AlgebraicTree {
    var maximum: Element? {
        var node = self
        var maximum: Element? = nil
        while case let .node(_, value, _, right) = node {
            maximum = value
            node = right
        }
        return maximum
    }
}

extension AlgebraicTree: Collection {
    public typealias Index = AlgebraicIndex<Element>

    public var startIndex: Index { return Index(value: self.minimum) }
    public var endIndex: Index { return Index(value: nil) }

    public subscript(i: Index) -> Element {
        return i.value!
    }
}

extension AlgebraicTree {
    public var count: Int {
        switch self {
        case .empty:
            return 0
        case let .node(_, _, left, right):
            return left.count + 1 + right.count
        }
    }
}

extension AlgebraicTree: BidirectionalCollection {
    public func formIndex(after i: inout Index) {
        let v = self.value(following: i.value!)
        precondition(v.found)
        i.value = v.next
    }

    public func index(after i: Index) -> Index {
        let v = self.value(following: i.value!)
        precondition(v.found)
        return Index(value: v.next)
    }
}

extension AlgebraicTree {
    func value(following element: Element) -> (found: Bool, next: Element?) {
        switch self {
            case .empty:
                return (false, nil)
            case .node(_, element, _, let right):
                return (true, right.minimum)
            case let .node(_, value, left, _) where value > element:
                let v = left.value(following: element)
                return (v.found, v.next ?? value)
            case let .node(_, _, _, right):
                return right.value(following: element)
        }
    }
}

extension AlgebraicTree {
    func value(preceding element: Element) -> (found: Bool, next: Element?) {
        var node = self
        var next: Element? = nil
        while case let .node(_, value, left, right) = node {
            if element > value {
                next = value
                node = right
            }
            else if element < value {
                node = left
            }
            else {
                return (true, left.maximum)
            }
        }
        return (false, next)
    }

    public func formIndex(before i: inout Index) {
        let v = self.value(preceding: i.value!)
        precondition(v.found)
        i.value = v.next
    }

    public func index(before i: Index) -> Index {
        let v = self.value(preceding: i.value!)
        precondition(v.found)
        return Index(value: v.next)
    }
}

extension AlgebraicTree: OrderedSet {
    public init() {
        self = .empty
    }
}
