//
//  MapTable.swift
//  MapTableDemo
//
//  Created by Robert Ryan on 11/30/23.
//

import Foundation

public class MapTable<Key: AnyObject & Hashable, Value> {
    private let dictionary = SynchronizedValue(wrappedValue: Dictionary<HashableWeakBox<Key>, Value>())

    public init() {}

    public init(dictionary: Dictionary<Key, Value>) {
        for (k, v) in dictionary {
            setValue(v, forKey: k)
        }
    }

    public subscript(key: Key) -> Value? {
        get { value(forKey: key) }
        set { setValue(newValue, forKey: key) }
    }

    public func value(forKey key: Key) -> Value? {
        dictionary.get { $0[HashableWeakBox(key)] }
    }

    public func setValue(_ value: Value?, forKey key: Key) {
        let hashableBox = HashableWeakBox(key)

        if let value {
            let watcher = DeallocWatcher { [weak self] in
                guard let self else { return }
                syncedRemoveValue(forKey: hashableBox)
            }

            setAssociatedObject(key, watcher)
            dictionary.access { $0[hashableBox] = value }
        } else {
            setAssociatedObject(key, nil, .OBJC_ASSOCIATION_ASSIGN)
        }
    }

    func setAssociatedObject(
        _ object: Any,
        _ value: Any?,
        _ policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC
    ) {
        withUnsafePointer(to: self) { pointer in
            objc_setAssociatedObject(object, pointer, value, policy)
        }
    }

    @discardableResult
    public func removeValue(forKey key: Key) -> Value? {
        setAssociatedObject(key, nil, .OBJC_ASSOCIATION_ASSIGN)
        return syncedRemoveValue(forKey: HashableWeakBox(key))
    }

    @discardableResult
    private func syncedRemoveValue(forKey key: HashableWeakBox<Key>) -> Value? {
        dictionary.access { $0.removeValue(forKey: key) }
    }

    public var count: Int { dictionary.get { $0.count } }
    public var isEmpty: Bool { dictionary.get { $0.isEmpty } }

    public var keyValues: [(Key, Value)] {
        dictionary.get { dict in
            dict.keys
                .filter { k in k.value != nil }
                .map { k -> (Key, Value) in (k.value!, dict[k]!) }
        }
    }

    public var keys: [Key] {
        dictionary.get { dict in
            dict.keys
                .filter { $0.value != nil }
                .map { $0.value! }
        }
    }

    public var values: [Value] {
        dictionary.get { dict in
            dict.keys
                .filter { $0.value != nil }
                .map { dict[$0]! }
        }
    }

    deinit {
        // Callback is not called when deallocing the helpers because in this case (inside deinit) 'self' is already nil
        dictionary.access {
            $0.keys
                .compactMap { $0.value }
                .forEach { setAssociatedObject($0, nil, .OBJC_ASSOCIATION_ASSIGN) }
        }
    }
}

extension MapTable: CustomStringConvertible {
    public var description: String  {
        let string = dictionary.get { dict in
            dict.keys
                .filter { $0.value != nil }
                .map {
                    if let value = dict[$0] {
                        "\($0.value!) : \(value)"
                    } else {
                        "\($0.value!) : null"
                    }
                }
                .joined(separator: ",\n    ")
        }

        return "[\n    " + string + "\n]"
    }
}

// I have preserved this “original hash” concept, but seems fundamentally flawed, IMHO

private class HashableWeakBox<T: AnyObject & Hashable>: Hashable {
    private(set) weak var value: T?
    var originalHashValue: Int

    init(_ v: T) {
        value = v
        originalHashValue = v.hashValue
    }

    static func == (lhs: HashableWeakBox, rhs: HashableWeakBox) -> Bool {
        lhs.value == rhs.value && lhs.originalHashValue == rhs.originalHashValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(originalHashValue)
    }
}

private class DeallocWatcher {
    let callback: () -> Void
    init(_ c: @escaping () -> Void) { callback = c }
    deinit { callback() }
}

public class SynchronizedValue<Wrapped> {
    fileprivate let serialQueue = DispatchQueue(label: "SynchronizedValue serial queue")
    fileprivate var _wrappedValue: Wrapped

    var wrappedValue: Wrapped {
        get { serialQueue.sync { _wrappedValue } }
        set { serialQueue.sync { _wrappedValue = newValue } }
    }

    public init(wrappedValue v: Wrapped) { _wrappedValue = v }

    /// Should only return value types or thread-safe reference types
    public func get<T>(execute work: (Wrapped) throws -> T) rethrows -> T {
        try serialQueue.sync {
            try work(_wrappedValue)
        }
    }

    public func access<T>(action: (inout Wrapped) throws -> T) rethrows -> T {
        try serialQueue.sync {
            try action(&_wrappedValue)
        }
    }
}
