import Foundation

struct StoredKeyData: Codable {
    var apiKey: String
    var secretKey: String
}

actor APIKeyService {
    private let fileManager = FileManager.default
    private let keysURL: URL
    private let encryptionService: EncryptionService
    
    init(keysPath: String, encryptionService: EncryptionService) async throws {
        self.keysURL = URL(fileURLWithPath: keysPath)
        self.encryptionService = encryptionService
        
        // Initialize storage if needed
        try await initializeStorage()
    }
    
    private func initializeStorage() async throws {
        if !fileManager.fileExists(atPath: keysURL.path) {
            let emptyData = try JSONEncoder().encode([String: StoredKeyData]())
            let encryptedData = try encryptionService.encrypt(emptyData)
            try encryptedData.write(to: keysURL)
        }
    }
    
    func saveAlpacaKeys(userId: String, apiKey: String, secretKey: String) async throws {
        do {
            let encryptedData = try Data(contentsOf: keysURL)
            let decryptedData = try encryptionService.decrypt(encryptedData)
            
            // Parse and update data
            var storedData = try JSONDecoder().decode([String: StoredKeyData].self, from: decryptedData)
            
            storedData[userId] = StoredKeyData(apiKey: apiKey, secretKey: secretKey)
            
            // Save updated data
            let updatedData = try JSONEncoder().encode(storedData)
            let encryptedUpdatedData = try encryptionService.encrypt(updatedData)
            try encryptedUpdatedData.write(to: keysURL)
        } catch {
            print("Error saving keys: \(error)")
            throw error
        }
    }
    
    func getAlpacaKeys(userId: String) async throws -> AlpacaKeyPair? {
        do {
            let encryptedData = try Data(contentsOf: keysURL)
            let decryptedData = try encryptionService.decrypt(encryptedData)
            
            let storedData = try JSONDecoder().decode([String: StoredKeyData].self, from: decryptedData)
            
            guard let userData = storedData[userId] else {
                return nil
            }
            
            return AlpacaKeyPair(apiKey: userData.apiKey, secretKey: userData.secretKey)
        } catch {
            print("Error retrieving keys: \(error)")
            return nil
        }
    }
    
    func deleteAlpacaKeys(userId: String) async throws {
        do {
            let encryptedData = try Data(contentsOf: keysURL)
            let decryptedData = try encryptionService.decrypt(encryptedData)
            
            var storedData = try JSONDecoder().decode([String: StoredKeyData].self, from: decryptedData)
            storedData.removeValue(forKey: userId)
            
            let updatedData = try JSONEncoder().encode(storedData)
            let encryptedUpdatedData = try encryptionService.encrypt(updatedData)
            try encryptedUpdatedData.write(to: keysURL)
        } catch {
            print("Error deleting keys: \(error)")
            throw error
        }
    }
}

struct AlpacaKeyPair: Codable {
    let apiKey: String
    let secretKey: String
}
