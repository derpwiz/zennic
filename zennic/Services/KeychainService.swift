import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()
    
    // MARK: - Properties
    
    private let serviceName = "com.zennic.app"
    private let queue = DispatchQueue(label: "com.zennic.keychain", qos: .userInitiated)
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    func store(key: String, data: Data) throws {
        try queue.sync {
            let query: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: serviceName,
                kSecAttrAccount: key,
                kSecValueData: data,
                kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
                kSecAttrSynchronizable: false
            ]
            
            var status = SecItemAdd(query as CFDictionary, nil)
            
            if status == errSecDuplicateItem {
                // Item already exists, update it
                let updateQuery: [CFString: Any] = [
                    kSecClass: kSecClassGenericPassword,
                    kSecAttrService: serviceName,
                    kSecAttrAccount: key
                ]
                
                let attributes: [CFString: Any] = [
                    kSecValueData: data
                ]
                
                status = SecItemUpdate(updateQuery as CFDictionary, attributes as CFDictionary)
            }
            
            guard status == errSecSuccess else {
                throw KeychainError.unableToStore(status: status)
            }
        }
    }
    
    func retrieve(key: String) throws -> Data {
        try queue.sync {
            let query: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: serviceName,
                kSecAttrAccount: key,
                kSecReturnData: true,
                kSecMatchLimit: kSecMatchLimitOne,
                kSecAttrSynchronizable: false
            ]
            
            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)
            
            guard status == errSecSuccess,
                  let data = result as? Data else {
                throw KeychainError.unableToRetrieve(status: status)
            }
            
            return data
        }
    }
    
    func delete(key: String) throws {
        try queue.sync {
            let query: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: serviceName,
                kSecAttrAccount: key,
                kSecAttrSynchronizable: false
            ]
            
            let status = SecItemDelete(query as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else {
                throw KeychainError.unableToDelete(status: status)
            }
        }
    }
    
    func deleteAll() throws {
        try queue.sync {
            let query: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: serviceName,
                kSecAttrSynchronizable: false
            ]
            
            let status = SecItemDelete(query as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else {
                throw KeychainError.unableToDelete(status: status)
            }
        }
    }
    
    // MARK: - Convenience Methods
    
    func storeString(_ string: String, forKey key: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        try store(key: key, data: data)
    }
    
    func retrieveString(forKey key: String) throws -> String {
        let data = try retrieve(key: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        return string
    }
}

// MARK: - Error Types

extension KeychainService {
    enum KeychainError: LocalizedError {
        case unableToStore(status: OSStatus)
        case unableToRetrieve(status: OSStatus)
        case unableToDelete(status: OSStatus)
        case invalidData
        
        var errorDescription: String? {
            switch self {
            case .unableToStore(let status):
                return "Failed to store item in keychain: \(SecCopyErrorMessageString(status, nil) as String? ?? "Unknown error")"
            case .unableToRetrieve(let status):
                return "Failed to retrieve item from keychain: \(SecCopyErrorMessageString(status, nil) as String? ?? "Unknown error")"
            case .unableToDelete(let status):
                return "Failed to delete item from keychain: \(SecCopyErrorMessageString(status, nil) as String? ?? "Unknown error")"
            case .invalidData:
                return "Invalid data format"
            }
        }
    }
}

// MARK: - Testing Support

#if DEBUG
extension KeychainService {
    /// Resets the keychain (for testing purposes only)
    func resetKeychain() throws {
        try deleteAll()
    }
}
#endif
