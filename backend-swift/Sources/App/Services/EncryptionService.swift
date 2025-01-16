import Foundation
import CryptoKit

class EncryptionService {
    private let keychain = KeychainService()
    private let keychainKey = "encryption_key"
    private let saltKey = "encryption_salt"
    
    private var key: SymmetricKey?
    
    init() throws {
        try initializeEncryption()
    }
    
    private func initializeEncryption() throws {
        // Try to retrieve existing key
        if let existingKey = try? keychain.retrieve(key: keychainKey) {
            self.key = SymmetricKey(data: existingKey)
            return
        }
        
        // Generate new salt
        let salt = generateSalt()
        try keychain.store(key: saltKey, data: salt)
        
        // Generate new key
        let masterKey = SymmetricKey(size: .bits256)
        let derivedKey = try deriveKey(from: masterKey.withUnsafeBytes { Data($0) }, salt: salt)
        try keychain.store(key: keychainKey, data: derivedKey.withUnsafeBytes { Data($0) })
        
        self.key = derivedKey
    }
    
    private func generateSalt() -> Data {
        return Data((0..<16).map { _ in UInt8.random(in: 0...255) })
    }
    
    private func deriveKey(from masterKey: Data, salt: Data) throws -> SymmetricKey {
        let derivedKeyData = try PBKDF2.SHA256.derive(
            fromPassword: masterKey,
            salt: salt,
            iterations: 480000,
            keyLength: 32
        )
        return SymmetricKey(data: derivedKeyData)
    }
    
    func encrypt(_ data: Data) throws -> Data {
        guard let key = self.key else {
            throw EncryptionError.keyNotInitialized
        }
        
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined ?? Data()
    }
    
    func decrypt(_ encryptedData: Data) throws -> Data {
        guard let key = self.key else {
            throw EncryptionError.keyNotInitialized
        }
        
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    enum EncryptionError: Error {
        case keyNotInitialized
        case encryptionFailed
        case decryptionFailed
    }
}
