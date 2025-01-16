import Vapor
import Fluent

final class AlpacaKeys: Model, Content {
    static let schema = "alpaca_keys"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "user_id")
    var user: User
    
    @Field(key: "api_key")
    var apiKey: String
    
    @Field(key: "secret_key")
    var secretKey: String
    
    @Field(key: "is_paper")
    var isPaper: Bool
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }
    
    init(id: UUID? = nil,
         userID: User.IDValue,
         apiKey: String,
         secretKey: String,
         isPaper: Bool = true) {
        self.id = id
        self.$user.id = userID
        self.apiKey = apiKey
        self.secretKey = secretKey
        self.isPaper = isPaper
    }
}

extension AlpacaKeys {
    struct Create: Content {
        var apiKey: String
        var secretKey: String
        var isPaper: Bool
    }
    
    struct Public: Content {
        var id: UUID?
        var apiKey: String
        var secretKey: String
        var isPaper: Bool
        var createdAt: Date?
        var updatedAt: Date?
        
        init(keys: AlpacaKeys) {
            self.id = keys.id
            self.apiKey = keys.apiKey
            self.secretKey = keys.secretKey
            self.isPaper = keys.isPaper
            self.createdAt = keys.createdAt
            self.updatedAt = keys.updatedAt
        }
    }
}
