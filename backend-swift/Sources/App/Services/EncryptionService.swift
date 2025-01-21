import Foundation
import CryptoKit

class EncryptionService {
    private let masterKey: SymmetricKey
    private let salt: Data
    
    init() throws {
        // Generate a random salt for key derivation
        var saltBytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, saltBytes.count, &saltBytes)
        self.salt = Data(saltBytes)
        
        // Generate a random master key
        var keyBytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, keyBytes.count, &keyBytes)
        self.masterKey = SymmetricKey(data: Data(keyBytes))
    }
    
    func encrypt(_ data: Data) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: masterKey)
        return sealedBox.combined!
    }
    
    func decrypt(_ data: Data) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: masterKey)
    }
}
