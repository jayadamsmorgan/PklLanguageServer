import Foundation

struct ParseQueueElement: Hashable {
    let importDepth: Int
    let importingDocument: Document
    let documentToBeImported: Document
    let importType: PklModuleImportType
    let moduleImport: PklModuleImport
}

class ParseQueue {
    private var queue: [ParseQueueElement] = []
    private let lock = NSLock()
    private let semaphore = DispatchSemaphore(value: 0)

    func enqueue(_ element: ParseQueueElement) {
        lock.lock()
        queue.append(element)
        lock.unlock()
        semaphore.signal()
    }

    func dequeue() -> ParseQueueElement {
        semaphore.wait()
        lock.lock()
        defer { lock.unlock() }
        return queue.removeFirst()
    }

    func contains(_ element: ParseQueueElement) -> Bool {
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
