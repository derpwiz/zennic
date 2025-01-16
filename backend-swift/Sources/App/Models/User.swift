import Vapor
import Fluent

final class User: Model, Content, Authenticatable {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "password_hash")
    var passwordHash: String
    
    @Field(key: "full_name")
    var fullName: String?
    
    @Field(key: "is_active")
    var isActive: Bool
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }
    
    init(id: UUID? = nil,
         email: String,
         username: String,
         passwordHash: String,
         fullName: String? = nil,
         isActive: Bool = true) {
        self.id = id
        self.email = email
        self.username = username
        self.passwordHash = passwordHash
        self.fullName = fullName
        self.isActive = isActive
    }
}

extension User {
    struct Create: Content, Validatable {
        var email: String
        var username: String
        var password: String
        var fullName: String?
        
        static func validations(_ validations: inout Validations) {
            validations.add("email", as: String.self, is: .email)
            validations.add("username", as: String.self, is: .alphanumeric && .count(3...))
            validations.add("password", as: String.self, is: .count(8...))
        }
    }
    
    struct Public: Content {
        var id: UUID?
        var email: String
        var username: String
        var fullName: String?
        var isActive: Bool
        
        init(user: User) {
            self.id = user.id
            self.email = user.email
            self.username = user.username
            self.fullName = user.fullName
            self.isActive = user.isActive
        }
    }
}

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$passwordHash
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}

extension User: ModelCredentialsAuthenticatable {
    static let credentialsKey = \User.$email
}

extension User: ModelSessionAuthenticatable {}
