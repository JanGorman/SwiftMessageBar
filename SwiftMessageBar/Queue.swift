//
//  Copyright © 2018 Schnaub. All rights reserved.
//

import Foundation

struct Queue<T: Equatable> {

  private var left: [T]
  private var right: [T]

  var isEmpty: Bool {
    return left.isEmpty && right.isEmpty
  }

  init() {
    left = []
    right = []
  }

  mutating func dequeue() -> T? {
    guard !(left.isEmpty && right.isEmpty) else { return nil }

    if left.isEmpty {
      left = right.reversed()
      right.removeAll(keepingCapacity: true)
    }
    return left.removeLast()
  }

  mutating func enqueue(_ newElement: T) {
    right.append(newElement)
  }

  mutating func removeAll() {
    left.removeAll()
    right.removeAll()
  }

  mutating func removeElement(_ element: T) {
    if let idx = left.index(of: element) {
      left.remove(at: idx)
    }
    if let idx = right.index(of: element) {
      right.remove(at: idx)
    }
  }

}
