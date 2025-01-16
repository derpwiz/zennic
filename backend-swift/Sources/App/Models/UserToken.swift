import Vapor
import Fluent
import JWT

final class UserToken: Model, Content {
    static let schema = "user_tokens"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "value")
    var value: String
    
    @Parent(key: "user_id")
    var user: User
    
    @Field(key: "expires_at")
    var expiresAt: Date
    
    init() { }
    
    init(id: UUID? = nil, value: String, userID: User.IDValue, expiresAt: Date) {
        self.id = id
        self.value = value
        self.$user.id = userID
        self.expiresAt = expiresAt
    }
}

extension UserToken {
    struct Payload: JWTPayload {
        var exp: ExpirationClaim
        var sub: SubjectClaim
        
        func verify(using signer: JWTSigner) throws {
            try self.exp.verifyNotExpired()
        }
    }
    
    struct Response: Content {
        let token: String
        let user: User.Public
    }
    
    static func generate(for user: User, on db: Database, app: Application) async throws -> UserToken {
        let expiresAt = Date().addingTimeInterval(86400) // 24 hours
        
        let payload = Payload(
            exp: .init(value: expiresAt),
            sub: .init(value: user.id?.uuidString ?? "")
        )
        
        let token = try app.jwt.signers.sign(payload)
        let userToken = UserToken(value: token, userID: user.id!, expiresAt: expiresAt)
        try await userToken.save(on: db)
        return userToken
    }
}

extension UserToken: ModelTokenAuthenticatable {
    static let valueKey = \UserToken.$value
    static let userKey = \UserToken.$user
    
    var isValid: Bool {
        expiresAt > Date()
    }
}
