//
//  Codable+KeyPathExtensions
//
//  Created by Andrey Bogushev on 8/12/18.
//  Copyright © 2018 Andrey Bogushev. All rights reserved.
//


import Foundation

public extension DecodingError {
    public static let emptyKeyPath: Error = {
        let userInfo: [String: Any] = [
            NSLocalizedDescriptionKey: "Array of keys is empty",
            NSDebugDescriptionErrorKey: "Expected non-empty array of keys"
        ]
        
        return NSError(domain: "DecodingErrorDomain", code: 10001, userInfo: userInfo)
    }()
}

public extension KeyedDecodingContainer {
    private var codingStringPath: String {
        return codingPath.map { $0.description }.joined(separator: ".")
    }
    
    public func decode<T: Decodable>(_ key: Key) throws -> T {
        return try decode(T.self, forKey: key)
    }
    
    public func decodeIfPresent<T: Decodable>(_ key: Key) throws -> T? {
        return try decodeIfPresent(T.self, forKey: key)
    }
    
    /// Decodes a value of the given type for the given keyPath.
    ///
    /// - Parameter keyPath: array of keys
    /// - Returns: A value of the requested type, if present for the given key and convertible to the requested type.
    /// - Throws:
    ///     - DecodingError.**emptyKeyPath** error if keyPath array is empty
    ///     - DecodingError.**valueNotFound** if self has a null entry for the given key.
    public func decode<T: Decodable>(_ keyPath: [Key]) throws -> T {
        guard !keyPath.isEmpty else {
            throw DecodingError.emptyKeyPath
        }
        
        if keyPath.count == 1 {
            return try decode(keyPath[0])
        }
        
        let container = try nestedContainer(keyedBy: Key.self, forKey: keyPath[0])
        
        return try container.decode(Array(keyPath.dropFirst()))
    }
    
    /// Decodes a value of the given type for the given key, if present.
    /// This method returns nil if the container does not have a value associated with key, or if the value is null. The difference between these states can be distinguished with a contains(_:) call.
    ///
    /// - Parameter keyPath: array of keys
    /// - Returns: A decoded value of the requested type, or nil if the Decoder does not have an entry associated with the given key, or if the value is a null value.
    /// - Throws:
    ///     - DecodingError.**emptyKeyPath** error if keyPath array is empty.
    ///     - DecodingError.**typeMismatch** if the encountered encoded value is not convertible to the requested type.
    public func decodeIfPresent<T: Decodable>(_ keyPath: [Key]) throws -> T? {
        guard !keyPath.isEmpty else {
            throw DecodingError.emptyKeyPath
        }
        
        if keyPath.count == 1 {
            return try decodeIfPresent(keyPath[0])
        }
        
        guard let container = try? nestedContainer(keyedBy: Key.self, forKey: keyPath[0]) else {
            return nil
        }
        
        return try container.decodeIfPresent(Array(keyPath.dropFirst()))
    }

    
    /// Decodes a value of the given type for the given keyPath.
    ///
    /// - Parameters:
    ///     - keyPath: array of keys
    ///     - containers: dictionary of cached containers for performance
    /// - Returns: A value of the requested type, if present for the given key and convertible to the requested type.
    /// - Throws:
    ///     - DecodingError.**emptyKeyPath** error if keyPath array is empty
    ///     - DecodingError.**valueNotFound** if self has a null entry for the given key.
    public func decode<T: Decodable>(_ keyPath: [Key], containers: inout [String: KeyedDecodingContainer]) throws -> T {
        guard !keyPath.isEmpty else {
            throw DecodingError.emptyKeyPath
        }
        
        if keyPath.count == 1 {
            return try decode(keyPath[0])
        }
        
        let path = codingStringPath
        var container: KeyedDecodingContainer! = containers[path]
        
        if container == nil {
            container = try nestedContainer(keyedBy: Key.self, forKey: keyPath[0])
            containers[path] = container
        }
        
        return try container.decode(Array(keyPath.dropFirst()), containers: &containers)
    }
    
    
    /// Decodes a value of the given type for the given key, if present.
    /// This method returns nil if the container does not have a value associated with key, or if the value is null. The difference between these states can be distinguished with a contains(_:) call.
    ///
    /// - Parameters:
    ///     - keyPath: array of keys
    ///     - containers: dictionary of cached containers for performance
    /// - Returns: A decoded value of the requested type, or nil if the Decoder does not have an entry associated with the given key, or if the value is a null value.
    /// - Throws:
    ///     - DecodingError.**emptyKeyPath** error if keyPath array is empty.
    ///     - DecodingError.**typeMismatch** if the encountered encoded value is not convertible to the requested type.
    public func decodeIfPresent<T: Decodable>(_ keyPath: [Key], containers: inout [String: KeyedDecodingContainer]) throws -> T? {
        guard !keyPath.isEmpty else {
            throw DecodingError.emptyKeyPath
        }
        
        if keyPath.count == 1 {
            return try decodeIfPresent(keyPath[0])
        }
        
        let path = codingStringPath
        var container: KeyedDecodingContainer! = containers[path]
        
        if container == nil {
            if let nested = try? nestedContainer(keyedBy: Key.self, forKey: keyPath[0]) {
                container = nested
                containers[path] = container
            } else {
                return nil
            }
        }
        
        return try container.decodeIfPresent(Array(keyPath.dropFirst()), containers: &containers)
    }
}


//MARK: -
//MARK: Encoding

public extension EncodingError {
    public static let emptyKeyPath: Error = {
        let userInfo: [String: Any] = [
            NSLocalizedDescriptionKey: "Array of keys is empty",
            NSDebugDescriptionErrorKey: "Expected non-empty array of keys"
        ]
        
        return NSError(domain: "EncodingErrorDomain", code: 10002, userInfo: userInfo)
    }()
}

public extension KeyedEncodingContainer {
    private var codingStringPath: String {
        return codingPath.map { $0.description }.joined(separator: ".")
    }
    
    
    /// Encodes the given value for the given key.
    ///
    /// - Parameters:
    ///   - value: The value to encode.
    ///   - keyPath: The keyPath to associate the value with.
    ///   - containers: dictionary of cached containers for performance.
    /// - Throws:
    ///     - EncodingError.**emptyKeyPath** error if keyPath array is empty.
    ///     - EncodingError.**invalidValue** if the given value is invalid in the current context for this format
    mutating public func encode<T: Encodable>(_ value: T?, keyPath: [Key], containers: inout [String: KeyedEncodingContainer]) throws {
        guard !keyPath.isEmpty else {
            throw DecodingError.emptyKeyPath
        }
        
        guard value != nil else {
            return
        }
        
        if keyPath.count == 1 {
            try encode(value, forKey: keyPath[0])
        }
        else {
            let path = codingStringPath
            var container: KeyedEncodingContainer! = containers[path]
            
            if container == nil {
                container = nestedContainer(keyedBy: Key.self, forKey: keyPath[0])
                containers[path] = container
            }
            
            try container.encode(value, keyPath: Array(keyPath.dropFirst()), containers: &containers)
        }
    }
}

