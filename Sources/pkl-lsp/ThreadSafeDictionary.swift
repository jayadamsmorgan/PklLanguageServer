import Foundation

class ThreadSafeDictionary<Key: Hashable, Value> {
    private var dictionary: [Key: Value] = [:]
    private var waitDictionary: [Key: DispatchSemaphore] = [:]
    private let queue = DispatchQueue(label: "com.yourapp.threadSafeDictionary", attributes: .concurrent)
    private let semaphore = DispatchSemaphore(value: 1)

    public func updateValue(_ value: Value, forKey key: Key) {
        queue.async(flags: .barrier) {
            self.dictionary[key] = value
            if let semaphore = self.waitDictionary[key] {
                semaphore.signal()
                self.waitDictionary.removeValue(forKey: key)
            }
        }
    }

    public func removeValue(forKey key: Key) {
        queue.async(flags: .barrier) {
            self.dictionary.removeValue(forKey: key)
            self.waitDictionary.removeValue(forKey: key)
        }
    }

    public func value(forKey key: Key) -> Value? {
        var result: Value?
        queue.sync {
            result = self.dictionary[key]
        }
        return result
    }

    public func waitForValue(forKey key: Key, timeout: DispatchTime = .distantFuture) -> Value? {
        if let value = value(forKey: key) {
            return value
        }

        semaphore.wait()
        let semaphoreForKey: DispatchSemaphore
        if let existingSemaphore = waitDictionary[key] {
            semaphoreForKey = existingSemaphore
        } else {
            semaphoreForKey = DispatchSemaphore(value: 0)
            waitDictionary[key] = semaphoreForKey
        }
        semaphore.signal()

        _ = semaphoreForKey.wait(timeout: timeout)
        return value(forKey: key)
    }

    public var allValues: [Key: Value] {
        var result: [Key: Value] = [:]
        queue.sync {
            result = self.dictionary
        }
        return result
    }
}
