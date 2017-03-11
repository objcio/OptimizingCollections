//
//  Slides.swift
//
//  Copyright © 2017 Károly Lőrentey.
//

// This file contains the raw source code that I presented on my slides.
// The slides were put together by taking manual screenshots of this file as displayed by Xcode.
// This approach was rather labor intensive, but it did produce nicely syntax highlighted code.
// I wouldn't recommend doing this, though -- changing stuff was not fun at all. :-)

import Foundation

//protocol OrderedSet {
//    associatedtype Element: Comparable
//
//    init()
//
//    func forEach(_ body: (Element) throws -> Void) rethrows
//
//    @discardableResult
//    mutating func insert(_ newElement: Element)
//        -> (inserted: Bool, memberAfterInsert: Element)
//
//    func contains(_ element: Element) -> Bool
//}

protocol OrderedSet {
    associatedtype Element: Comparable

    init()
    func forEach(_ body: (Element) -> Void)
    mutating func insert(_ newElement: Element)
}


/*******************************************************************/
//MARK: NSOrderedSet

class MyOrderedSet<Element: Comparable>: OrderedSet {
    let storage = NSMutableOrderedSet()

    required init() {}

    static func compare(_ a: Any, _ b: Any) -> ComparisonResult {
        let a = a as! Element, b = b as! Element
        return a < b ? .orderedAscending
             : a > b ? .orderedDescending
             : .orderedSame
    }

    func insert(_ newElement: Element) {
        let index = storage.index(
            of: newElement, inSortedRange: NSRange(0 ..< storage.count),
            options: .insertionIndex, usingComparator: MyOrderedSet.compare)
        storage.insert(newElement, at: index)
    }

    func forEach(_ body: (Element) -> Void) {
        storage.forEach { body($0 as! Element) }
    }
}


do {
    var set = MyOrderedSet<Int>()
    set.insert(9)
    set.insert(5)
    set.insert(12)
    set.insert(2)
    set.forEach { print($0) }
}

/*******************************************************************/
//MARK: SortedArray

struct SortedArray<Element: Comparable>: OrderedSet {
    var storage: [Element] = []

    func forEach(_ body: (Element) -> Void) {
        storage.forEach(body)
    }
}

extension SortedArray: RandomAccessCollection {
    typealias Indices = CountableRange<Int>

    var startIndex: Int { return 0 }
    var endIndex: Int { return storage.count }

    subscript(_ i: Int) -> Element { return storage[i] }
}

extension SortedArray {
    func slot(of element: Element) -> Int {
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
    mutating func insert(_ newElement: Element) {
        let slot = self.slot(of: newElement)
        if slot == storage.count || storage[slot] != newElement {
            storage.insert(newElement, at: slot)
        }
    }
}

extension SortedArray {
    func contains(_ element: Element) -> Bool {
        let slot = self.slot(of: element)
        return slot < storage.count && storage[slot] == element
    }
}

/*******************************************************************/
// MARK: Algebraic Red-Black Tree

enum Color {
    case black
    case red
}

enum AlgebraicTree<Element: Comparable> {
    case empty
    indirect case node(Color, AlgebraicTree, Element, AlgebraicTree)
}

extension AlgebraicTree: CustomStringConvertible {
    var hasChildren: Bool {
        guard case let .node(_, left, _, right) = self else { return false }
        guard case .empty = left else { return true }
        guard case .empty = right else { return true }
        return false
    }
    private func visitLines(_ leftPrefix: String, _ rootPrefix: String, _ rightPrefix: String, _ body: (String) -> Void) {
        guard case let .node(color, left, value, right) = self else {
            body(rootPrefix + "▪︎")
            return
        }
        guard hasChildren else { body(rootPrefix + "\(color) \(value)"); return }
        left.visitLines(leftPrefix + "     ",
                        leftPrefix + "┌─── ",
                        leftPrefix + "│    ",
                        body)
        body(rootPrefix + "\(color) \(value)")
        right.visitLines(rightPrefix + "│    ",
                         rightPrefix + "└─── ",
                         rightPrefix + "     ",
                         body)
    }
    var description: String {
        var result = ""
        self.visitLines("l", ".", "r") { line in result += line; result += "\n" }
        return result
    }
}

let tree: AlgebraicTree<Int> =
    .node(.black,
          .node(.red,
                .node(.black,
                      .empty,
                      1,
                      .node(.red, .empty, 4, .empty)),
                5,
                .node(.black, .empty, 8, .empty)),
          9,
          .node(.red,
                .node(.black, .empty, 11, .empty),
                12,
                .node(.black,
                      .node(.red, .empty, 14, .empty),
                      16,
                      .node(.red, .empty, 17, .empty))))

let a = AlgebraicTree<Int>.empty
let b = AlgebraicTree<Int>.empty
let c = AlgebraicTree<Int>.empty
let d = AlgebraicTree<Int>.empty
let x = 1
let y = 2
let z = 3

print("Foo \(a)")
print("Foo \(tree)")

let n1: AlgebraicTree<Int> =

    .node(.black, .node(.red, .node(.red, a, x, b), y, c), z, d)

let n2: AlgebraicTree<Int> =

    .node(.black, .node(.red, a, x, .node(.red, b, y, c)), z, d)

let n3: AlgebraicTree<Int> =

    .node(.black, a, x, .node(.red, .node(.red, b, y, c), z, d))


let n4: AlgebraicTree<Int> =

    .node(.black, a, x, .node(.red, b, y, .node(.red, c, z, d)))

let n5: AlgebraicTree<Int> =

    .node(.red, .node(.black, a, x, b), y, .node(.black, c, z, d))


extension AlgebraicTree {
    func forEach(_ body: (Element) -> Void) {
        switch self {
        case .empty:
            return
        case let .node(_, left, value, right):
            left.forEach(body)
            body(value)
            right.forEach(body)
        }
    }
}

extension AlgebraicTree {
    func contains(_ element: Element) -> Bool {
        switch self {
        case .empty:
            return false
        case let .node(_, _, value, _) where element == value:
            return true
        case let .node(_, left, value, _) where element < value:
            return left.contains(element)
        case let .node(_, _, _, right):
            return right.contains(element)
        }
    }
}

extension AlgebraicTree {
    func _inserting(_ new: Element) -> AlgebraicTree {
        switch self {
        case .empty:
            // Replace the empty tree with a single node.
            return .node(.red, .empty, new, .empty)

        case let .node(_, _, value, _) where new == value:
            // The value was already in the tree; we're done.
            return self

        case let .node(color, left, value, right) where new < value:
            // Insert the new value to the left child.
            return balanced(color, left._inserting(new), value, right)

        case let .node(color, left, value, right): // new > value
            // Insert the new value to the right child.
            return balanced(color, left, value, right._inserting(new))
        }
    }
}


extension AlgebraicTree {
    func balanced(_ color: Color,
                  _ left: AlgebraicTree,
                  _ value: Element,
                  _ right: AlgebraicTree) -> AlgebraicTree {
        switch (color, left, value, right) {
        case let (.black, .node(.red, .node(.red, a, x, b), y, c), z, d),
             let (.black, .node(.red, a, x, .node(.red, b, y, c)), z, d),
             let (.black, a, x, .node(.red, .node(.red, b, y, c), z, d)),
             let (.black, a, x, .node(.red, b, y, .node(.red, c, z, d))):
            return .node(.red, .node(.black, a, x, b), y, .node(.black, c, z, d))
        default:
            return .node(color, left, value, right)
        }
    }
}

// The insert algorithm below is a simple transliteration of the
// algorithm in Chris Okasaki's 1999 paper, "Red-black trees in a functional setting".
// doi:10.1017/S0956796899003494


extension AlgebraicTree {
    func inserting(_ element: Element) -> AlgebraicTree {
        switch self._inserting(element) {
        case let .node(.red, left, value, right):
            return .node(.black, left, value, right)
        case let result:
            return result
        }
    }

    mutating func insert(_ element: Element) {
        self = self.inserting(element)
    }
}

/*******************************************************************/
//MARK: COWTree

/// A red-black tree with value semantics and copy-on-write optimization.
struct COWTree<Element: Comparable> {
    var root: COWNode<Element>? = nil
}

final class COWNode<Element: Comparable> {
    var color: Color
    var left: COWNode<Element>? = nil
    var value: Element
    var right: COWNode<Element>? = nil

    init(_ color: Color, _ left: COWNode?,
         _ value: Element, _ right: COWNode?) {
        self.color = color
        self.left = left
        self.value = value
        self.right = right
    }
}

extension COWTree {
    public func forEach(_ body: (Element) -> Void) {
        root?.forEach(body)
    }
}

extension COWNode {
    func forEach(_ body: (Element) -> Void) {
        left?.forEach(body)
        body(value)
        right?.forEach(body)
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

extension COWTree {
    mutating func makeRootUnique() -> COWNode<Element>? {
        if root != nil, !isKnownUniquelyReferenced(&root) {
            root = root!.clone()
        }
        return root
    }
}

extension COWNode {
    func clone() -> COWNode {
        return COWNode(color, left, value, right)
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
    public mutating func insert(_ element: Element) {
        switch makeRootUnique() {
        case .none:
            self.root = COWNode(.black, nil, element, nil)
        case .some(let node):
            node.insert(element)
            node.color = .black
        }
    }
}

extension COWNode {
    func insert(_ element: Element) {
        if element < self.value {
            if let next = makeLeftUnique() {
                next.insert(element)
                self.balance()
            }
            else {
                self.left = COWNode(.red, nil, element, nil)
            }
        }
        else if element > self.value {
            if let next = makeRightUnique() {
                next.insert(element)
                self.balance()
            }
            else {
                self.right = COWNode(.red, nil, element, nil)
            }
        }
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
                (self.left, l.left, l.right, self.right)
                    = (ll, l.right, self.right, l)
                self.color = .red
                l.color = .black
                ll.color = .black
                return
            }
            if left?.right?.color == .red {
                let l = left!
                let lr = l.right!
                swap(&self.value, &lr.value)
                (l.right, lr.left, lr.right, self.right)
                    = (lr.left, lr.right, self.right, lr)
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
                (self.left, rl.left, rl.right, r.left)
                    = (rl, self.left, rl.left, rl.right)
                self.color = .red
                r.color = .black
                rl.color = .black
                return
            }
            if right?.right?.color == .red {
                let r = right!
                let rr = r.right!
                swap(&self.value, &r.value)
                (self.left, r.left, r.right, self.right)
                    = (r, self.left, r.left, rr)
                self.color = .red
                r.color = .black
                rr.color = .black
                return
            }
        }
    }
}

/*******************************************************************/
//MARK: BTree

let l1CacheSize = 32_768

struct BTree<Element: Comparable> {
    typealias Node = BTreeNode<Element>
    var root: Node

    init(order: Int) {
        self.root = Node(order: order)
    }

    init() {
        let elementSize = MemoryLayout<Element>.stride
        self.init(order: max(8, l1CacheSize / 2 / elementSize))
    }
}

final class BTreeNode<Element: Comparable> {
    let order: Int
    var elementCount: Int
    let elements: UnsafeMutablePointer<Element>
    let children: UnsafeMutablePointer<BTreeNode>?

    init(order: Int = 1024, leaf: Bool = true) {
        self.order = order
        self.elementCount = 0
        self.elements = .allocate(capacity: order)
        self.children = leaf ? nil : .allocate(capacity: order)
    }

    deinit {
        elements.deinitialize(count: elementCount)
        elements.deallocate(capacity: order)
        if let children = self.children {
            children.deinitialize(count: elementCount + 1)
            children.deallocate(capacity: order)
        }
    }
}

extension BTree {
    public func forEach(_ body: (Element) -> Void) {
        root.forEach(body)
    }
}

extension BTreeNode {
    func forEach(_ body: (Element) -> Void) {
        for i in 0 ..< elementCount {
            children?[i].forEach(body)
            body(elements[i])
        }
        children?[elementCount].forEach(body)
    }
}

extension BTree {
    public func contains(_ element: Element) -> Bool {
        return root.contains(element)
    }
}

extension BTreeNode {
    func contains(_ element: Element) -> Bool {
        let slot = self.slot(of: element)
        if slot.match { return true }
        return children?[slot.index].contains(element) ?? false
    }
}

extension BTreeNode {
    var maxElements: Int { return order - 1 }
    var minElements: Int { return (order - 1) / 2 }
    var maxChildren: Int { return order }
    var minChildren: Int { return (order + 1) / 2 }

    var isLeaf: Bool { return children == nil }
    var isTooLarge: Bool { return elementCount > maxElements }
}

extension BTree {
    mutating func makeRootUnique() -> Node {
        if isKnownUniquelyReferenced(&root) { return root }
        root = root.clone()
        return root
    }
}

extension BTreeNode {
    func clone() -> BTreeNode {
        let clone = BTreeNode(order: order, leaf: self.isLeaf)
        clone.elements.initialize(
            from: self.elements, count: self.elementCount)
        if let children = children {
            clone.children!.initialize(
                from: children, count: self.elementCount + 1)
        }
        clone.elementCount = self.elementCount
        return clone
    }

    func makeChildUnique(_ slot: Int) -> BTreeNode {
        guard !isKnownUniquelyReferenced(&children![slot]) else {
            return children![slot]
        }
        let clone = children![slot].clone()
        children![slot] = clone
        return clone
    }
}

extension BTreeNode {
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

internal struct BTreeSplinter<Element: Comparable> {
    let separator: Element
    let node: BTreeNode<Element>
}

extension BTreeNode {
    typealias Splinter = BTreeSplinter<Element>

    func split() -> Splinter {
        let count = elementCount
        let median = count / 2
        let node = BTreeNode(order: order, leaf: self.isLeaf)
        let separator = (elements + median).move()
        let c = count - median - 1
        node.elements.moveInitialize(
            from: self.elements + median + 1, count: c)
        if self.children != nil {
            node.children!.moveInitialize(
                from: self.children! + median + 1, count: c + 1)
        }
        self.elementCount = median
        node.elementCount = c
        return Splinter(separator: separator, node: node)
    }
}

extension BTreeNode {
    func _insertElement(_ element: Element, at index: Int) {
        assert(index >= 0 && index <= elementCount)
        (elements + index + 1).moveInitialize(
            from: elements + index, count: elementCount - index)
        (elements + index).initialize(to: element)
        elementCount += 1
    }

    func _insertChild(_ child: BTreeNode, at index: Int) {
        assert(index >= 0 && index <= elementCount + 1)
        (children! + index + 1).moveInitialize(
            from: children! + index, count: elementCount + 1 - index)
        (children! + index).initialize(to: child)
    }

    func insert(_ element: Element) -> Splinter? {
        let slot = self.slot(of: element)
        if slot.match {
            return nil // The element is already in the tree.
        }
        if self.isLeaf {
            _insertElement(element, at: slot.index)
            return self.isTooLarge ? self.split() : nil
        }
        let splinter = makeChildUnique(slot.index).insert(element)
        guard let s = splinter else { return nil }
        _insertElement(s.separator, at: slot.index)
        _insertChild(s.node, at: slot.index + 1)
        return self.isTooLarge ? self.split() : nil
    }
}

extension BTree {
    public mutating func insert(_ element: Element) {
        let root = makeRootUnique()
        if let splinter = root.insert(element) {
            let oldRoot = root
            self.root = Node(order: root.order, leaf: false)
            self.root.elements.initialize(to: splinter.separator)
            self.root.children!.initialize(to: oldRoot)
            (self.root.children! + 1).initialize(to: splinter.node)
            self.root.elementCount = 1
        }
    }
}


do {
    var set = BTree<Int>(order: 4)
    set.insert(9)
    set.insert(6)
    set.insert(12)
    set.insert(2)
    set.insert(10)
    set.insert(3)
    set.insert(1)
    set.insert(13)
    set.insert(8)
    set.insert(5)
    set.insert(11)
    set.insert(7)
    set.insert(4)
    set.forEach { print($0) }
}
