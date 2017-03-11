do {
    var set = MyOrderedSet<Int>()
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
    let emptyTree: AlgebraicTree<Int> = .empty
    print(emptyTree)

    let tinyTree: AlgebraicTree<Int> = .node(.black, 42, .empty, .empty)
    print(tinyTree)

    let smallTree: AlgebraicTree<Int> = 
        .node(.black, 2, 
            .node(.red, 1, .empty, .empty), 
            .node(.red, 3, .empty, .empty))
    print(smallTree)

    let bigTree: AlgebraicTree<Int> =
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

    var set = AlgebraicTree<Int>.empty
    for i in (1 ... 20).shuffled() {
        set.insert(i)
    }
    print(set)

    print(set.lazy.filter { $0 % 2 == 0 }.map { "\($0)" }.joined(separator: ", "))
}

do {
    var set = COWTree<Int>()
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
        guard n > 1 else { return 1 }
        return n * factorial(n - 1)
    }
    print(factorial(4))
    print(factorial(10))

    var set = Set<Int>() // "set" is also a keyword for defining property setters
    set.insert(42)
    print(set.contains(42))
}
