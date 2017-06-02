# Optimizing Collections in Swift

[![Book Cover](Images/cover@2x.png)][booklink]

This repository contains the sample code from the book [Optimizing Collections][booklink].

In this book, we show how to write very efficient Swift collection code. Throughout the book, we benchmark everything — with some surprising results. We implement custom data structures with value semantics and copy-on-write behavior such as sorted arrays, binary trees, red-black trees, and B-trees.

Even if you never implement your own collections, this book helps you reason about the performance of Swift code.

## The Code

This repository includes the full source code of every algorithm discussed in the book:

1. [`MyOrderedSet`](./Sources/NSOrderedSet.swift): A rudimentary Swift wrapper for the `NSOrderedSet` class in Foundation.
2. [`SortedArray`](./Sources/SortedArray.swift): A simple collection storing elements in a sorted array, with O(n) insertions.
3. [`AlgebraicTree`](./Sources/AlgebraicTree.swift): A purely functional implementation of [red-black trees][rbt] using algebraic data types.
4. [`COWTree`](./Sources/COWTree.swift):
    A procedural, structs-and-classes variant of red-black trees that implements the [copy-on-write optimization][cow].
5. [`BTree`](./Sources/BTree.swift): 
    An implementation of in-memory [B-trees][btree-wiki], based on my [`BTree` package][btree].

[rbt]: https://en.wikipedia.org/wiki/Red–black_tree
[cow]: https://en.wikipedia.org/wiki/Copy-on-write
[btree-wiki]: https://en.wikipedia.org/wiki/B-tree
[btree]: https://github.com/lorentey/BTree

As a bonus, all five data structures implement `BidirectionalCollection`, and
they all have full value semantics.

Note that while this repository contains nice illustrations of various coding
techniques, I don't recommend you use any of this code in your own projects. I
had to cut some corners to make sure the code remains relatively easy to
understand; full implementations would include lot more functionality that
would just obfuscate my point here. For example, none of these collections
implement support for removing elements, or in fact any of method in
`SetAlgebra` other than `contains` and `insert`.

For production-ready implementations of ordered collections, please
check out my [BTree package][btree] instead.

## The Video

You can watch the video of my talk at dotSwift 2017 about optimizing collections by clicking on the image below.

[![dotSwift 2017 - Optimizing Swift Collections](https://img.youtube.com/vi/UdZP6JeTCkM/0.jpg)](https://www.youtube.com/watch?v=UdZP6JeTCkM)

My slides are available on [Speaker Deck][speakerdeck].

[speakerdeck]: https://speakerdeck.com/lorentey/optimizing-swift-collections

## The App

The custom microbenchmarking app I wrote to generate my charts is called
[Attabench], and it is available in a [separate repository][Attabench]. The
insertion benchmark I demonstrated is included in the app by default, so you
can easily reproduce my results on your own computer. 

[![Attabench screenshot](Images/Attabench-screenshot.png)][Attabench]

[Attabench]: https://github.com/lorentey/Attabench

Tip: try implementing
your own optimization ideas, and race them with my code! I'm sure you'll easily
beat me if you try.


[booklink]: https://www.objc.io/books/optimizing-collections
