do {
    print((0 ..< 20).shuffled())
    print((0 ..< 20).shuffled())
    print((0 ..< 20).shuffled())
}

do {
    var a = [2, 3, 4]
    var b = a
    a.insert(1, at: 0)
    print(a)
    print(b)
}

do {
    var set = SortedArray<Int>()
    for i in (0 ..< 22).shuffled() {
        set.insert(2 * i)
    }
    print(set)
    
    print(set.contains(42))
    
    print(set.contains(13))

    let copy = set
    set.insert(13)
    
    print(set.contains(13))
    
    print(copy.contains(13))
}

do {
    var set = OrderedSet<Int>()
    for i in (1 ... 20).shuffled() {
        set.insert(i)
    }

    print(set)

    print(set.contains(7))
    print(set.contains(42))

    print(set.reduce(0, +))

    let copy = set
    set.insert(42)
    print(copy)
    print(set)
}

import Foundation

struct Value: Comparable {
    let value: Int
    init(_ value: Int) { self.value = value }
    
    static func ==(left: Value, right: Value) -> Bool {
        return left.value == right.value
    }
    
    static func <(left: Value, right: Value) -> Bool {
        return left.value < right.value
    }
}

do {
    let value = Value(42)
    let a = value as AnyObject
    let b = value as AnyObject
    print(a.isEqual(b))
    print(a.hash)
    print(b.hash)

    var values = OrderedSet<Value>()
    (1 ... 20).shuffled().map(Value.init).forEach { values.insert($0) }
    print(values.contains(Value(7)))
    print(values.contains(Value(42)))
}

do {
        let emptyTree: RedBlackTree<Int> = .empty
    print(emptyTree)

        let tinyTree: RedBlackTree<Int> = .node(.black, 42, .empty, .empty)
    print(tinyTree)

        let smallTree: RedBlackTree<Int> = 
            .node(.black, 2, 
                .node(.red, 1, .empty, .empty), 
                .node(.red, 3, .empty, .empty))
    print(smallTree)

    let bigTree: RedBlackTree<Int> =
        .node(.black, 9,
            .node(.red, 5,
                .node(.black, 1, .empty, .node(.red, 4, .empty, .empty)),
                .node(.black, 8, .empty, .empty)),
            .node(.red, 12,
                .node(.black, 11, .empty, .empty),
                .node(.black, 16,
                    .node(.red, 14, .empty, .empty),
                    .node(.red, 17, .empty, .empty))))
    print(bigTree)

    var set = RedBlackTree<Int>.empty
    for i in (1 ... 20).shuffled() {
        set.insert(i)
    }
    print(set)

    print(set.lazy.filter { $0 % 2 == 0 }.map { "\($0)" }.joined(separator: ", "))
}

do {
    var set = RedBlackTree2<Int>()
    for i in (1 ... 20).shuffled() {
        set.insert(i)
    }
    print(set)
    
    print(set.contains(13))
    
    print(set.contains(42))
    
    print(set.filter { $0 % 2 == 0 })
}

do {
    var set = BTree<Int>(order: 5)
    for i in (1 ... 250).shuffled() {
        set.insert(i)
    }
    print(set)

    let evenMembers = set.reversed().lazy.filter { $0 % 2 == 0 }.map { "\($0)" }.joined(separator: ", ")
    print(evenMembers)
}

do {
    func factorial(_ n: Int) -> Int {
        return (1 ... max(1, n)).reduce(1, *)
    }
    print(factorial(4))
    print(factorial(10))

    var set = Set<Int>() // "set" is also a keyword for defining property setters
    set.insert(42)
    print(set.contains(42))
}
