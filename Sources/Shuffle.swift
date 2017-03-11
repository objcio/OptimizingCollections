import Foundation

extension Array {
    public mutating func shuffle() {
        for i in 0 ..< count {
            let j = Int(arc4random_uniform(UInt32(count)))
            if i != j {
                swap(&self[i], &self[j])
            }
        }
    }
}

extension Sequence {
    public func shuffled() -> [Iterator.Element] {
        var contents = Array(self)
        contents.shuffle()
        return contents
    }
}
