import Foundation

actor APIKeyService {
    private let encryptionService: EncryptionService
    private let fileManager = FileManager.default
    private let keysURL: URL
    
    init() throws {
        self.encryptionService = try EncryptionService()
        
        // Get the app's Documents directory
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.keysURL = documentsPath.appendingPathComponent("encrypted_keys")
        
        // Initialize storage if needed
        try initializeStorage()
    }
    
    private func initializeStorage() throws {
        if !fileManager.fileExists(atPath: keysURL.path) {
            let emptyData = try JSONEncoder().encode([String: [String: Any]]())
            let encryptedData = try encryptionService.encrypt(emptyData)
            try encryptedData.write(to: keysURL)
        }
    }
    
    func saveAlpacaKeys(userId: String, apiKey: String, secretKey: String, isPaper: Bool) async throws -> Bool {
        do {
            // Read existing data
            let encryptedData = try Data(contentsOf: keysURL)
            let decryptedData = try encryptionService.decrypt(encryptedData)
            
            // Parse and update data
            var storedData = try JSONDecoder().decode([String: [String: [String: Any]]].self, from: decryptedData)
            
            storedData[userId] = [
                "alpaca": [
                    "api_key": apiKey,
                    "secret_key": secretKey,
                    "is_paper": isPaper
                ]
            ]
            
            // Encrypt and save updated data
            let updatedData = try JSONEncoder().encode(storedData)
            let encryptedUpdatedData = try encryptionService.encrypt(updatedData)
            try encryptedUpdatedData.write(to: keysURL)
            
            return true
        } catch {
            print("Error saving keys: \(error)")
            return false
        }
    }
    
    func getAlpacaKeys(userId: String) async throws -> AlpacaKeys? {
        do {
            let encryptedData = try Data(contentsOf: keysURL)
            let decryptedData = try encryptionService.decrypt(encryptedData)
            
            let storedData = try JSONDecoder().decode([String: [String: [String: Any]]].self, from: decryptedData)
            
            guard let userData = storedData[userId],
                  let alpacaData = userData["alpaca"],
                  let apiKey = alpacaData["api_key"] as? String,
                  let secretKey = alpacaData["secret_key"] as? String,
                  let isPaper = alpacaData["is_paper"] as? Bool else {
                return nil
            }
            
            return AlpacaKeys(apiKey: apiKey, secretKey: secretKey, isPaper: isPaper)
        } catch {
            print("Error retrieving keys: \(error)")
            return nil
        }
    }
    
    func deleteAlpacaKeys(userId: String) async throws -> Bool {
        do {
            let encryptedData = try Data(contentsOf: keysURL)
            let decryptedData = try encryptionService.decrypt(encryptedData)
            
            var storedData = try JSONDecoder().decode([String: [String: [String: Any]]].self, from: decryptedData)
            storedData.removeValue(forKey: userId)
            
            let updatedData = try JSONEncoder().encode(storedData)
            let encryptedUpdatedData = try encryptionService.encrypt(updatedData)
            try encryptedUpdatedData.write(to: keysURL)
            
            return true
        } catch {
            print("Error deleting keys: \(error)")
            return false
        }
    }
}

struct AlpacaKeys: Codable {
    let apiKey: String
    let secretKey: String
    let isPaper: Bool
}
