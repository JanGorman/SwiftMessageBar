//
//  Copyright © 2020 Schnaub. All rights reserved.
//

@testable import SwiftMessageBar
import XCTest

final class QueueTests: XCTestCase {

  func testEmpty() {
    var queue = Queue<String>()

    XCTAssertTrue(queue.isEmpty)
    XCTAssertNil(queue.dequeue())
  }

  func testEnqueueDequeue() {
    var queue = Queue<String>()
    queue.enqueue("foo")
    queue.enqueue("bar")

    XCTAssertEqual(queue.dequeue(), "foo")
    XCTAssertEqual(queue.dequeue(), "bar")
    XCTAssertNil(queue.dequeue())
  }

  func testRemoveAll() {
    var queue = Queue<String>()
    queue.enqueue("foo")
    queue.enqueue("bar")

    queue.removeAll()

    XCTAssertNil(queue.dequeue())
  }

  func testRemoveElement() {
    var queue = Queue<String>()
    queue.enqueue("foo")
    queue.enqueue("bar")
    queue.enqueue("baz")
    queue.enqueue("bat")

    queue.removeElement("foo")

    XCTAssertEqual(queue.dequeue(), "bar")

    queue.removeElement("baz")

    XCTAssertEqual(queue.dequeue(), "bat")
  }

}
