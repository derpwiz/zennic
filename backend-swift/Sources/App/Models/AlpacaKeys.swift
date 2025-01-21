import Fluent
import Vapor

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
    
    init() { }
    
    init(id: UUID? = nil, userId: User.IDValue, apiKey: String, secretKey: String) {
        self.id = id
        self.$user.id = userId
        self.apiKey = apiKey
        self.secretKey = secretKey
    }
}

extension AlpacaKeys {
    struct Create: Content {
        var apiKey: String
        var secretKey: String
    }
    
    struct Public: Content {
        var id: UUID?
        var apiKey: String
        var userId: UUID
        
        init(keys: AlpacaKeys) {
            self.id = keys.id
            self.apiKey = keys.apiKey
            self.userId = keys.$user.id
        }
    }
    
    var `public`: Public {
        .init(keys: self)
    }
}

extension AlpacaKeys: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("apiKey", as: String.self, is: !.empty)
        validations.add("secretKey", as: String.self, is: !.empty)
    }
}
