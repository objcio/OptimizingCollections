import Darwin // for arc4random

extension Sequence {
    public func shuffled() -> [Iterator.Element] {
        var contents = Array(self)
        for i in 0 ..< contents.count {
            // FIXME: This breaks if we have 2^32 elements or more.
            let j = Int(arc4random_uniform(UInt32(contents.count)))
            if i != j {
                swap(&contents[i], &contents[j])
            }
        }
        return contents
    }
}
