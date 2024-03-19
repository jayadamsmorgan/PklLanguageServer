import Foundation

struct ParseImportQueueElement: Hashable {
    let importDepth: Int
    let importingDocument: Document
    let documentToBeImported: Document
    let importType: PklModuleImportType
    let moduleImport: PklModuleImport
}

class BlockingQueue<T: Hashable> {
    private var queue: [T] = []
    private let lock = NSLock()
    private let semaphore = DispatchSemaphore(value: 0)

    func enqueue(_ element: T) {
        lock.lock()
        queue.append(element)
        lock.unlock()
        semaphore.signal()
    }

    func dequeue() -> T {
        semaphore.wait()
        lock.lock()
        defer { lock.unlock() }
        return queue.removeFirst()
    }

    func contains(_ element: T) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return queue.contains(element)
    }

    var isEmpty: Bool {
        lock.lock()
        defer { lock.unlock() }
        return queue.isEmpty
    }
}
