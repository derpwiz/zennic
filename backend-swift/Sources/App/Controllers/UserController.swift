import Vapor
import Fluent

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("users")
        users.post("register", use: register)
        
        let tokenProtected = users.grouped(UserToken.authenticator())
        tokenProtected.get("me", use: getCurrentUser)
        
        let passwordProtected = users.grouped(User.authenticator())
        passwordProtected.post("login", use: login)
        
        let alpacaKeys = users.grouped("alpaca-keys")
            .grouped(UserToken.authenticator())
            .grouped(User.guardMiddleware())
        alpacaKeys.post(use: saveAlpacaKeys)
        alpacaKeys.get(use: getAlpacaKeys)
        alpacaKeys.delete(use: deleteAlpacaKeys)
    }
    
    func register(req: Request) async throws -> User.Public {
        try User.Create.validations().validate(request: req)
        let create = try req.content.decode(User.Create.self)
        
        guard try await User.query(on: req.db)
            .filter(\.$email == create.email)
            .first() == nil else {
            throw Abort(.conflict, reason: "A user with this email already exists")
        }
        
        guard try await User.query(on: req.db)
            .filter(\.$username == create.username)
            .first() == nil else {
            throw Abort(.conflict, reason: "A user with this username already exists")
        }
        
        let passwordHash = try await req.password.async.hash(create.password)
        
        let user = User(
            email: create.email,
            username: create.username,
            passwordHash: passwordHash,
            fullName: create.fullName
        )
        
        try await user.save(on: req.db)
        return User.Public(user: user)
    }
    
    func login(req: Request) async throws -> UserToken.Response {
        let user = try req.auth.require(User.self)
        let token = try await UserToken.generate(for: user, on: req.db, app: req.application)
        return UserToken.Response(token: token.value, user: User.Public(user: user))
    }
    
    func getCurrentUser(req: Request) async throws -> User.Public {
        let user = try req.auth.require(User.self)
        return User.Public(user: user)
    }
    
    func saveAlpacaKeys(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        guard let userId = user.id else {
            throw Abort(.internalServerError, reason: "User ID not found")
        }
        let create = try req.content.decode(AlpacaKeys.Create.self)
        
        // Check if user already has keys
        if let existingKeys = try await AlpacaKeys.query(on: req.db)
            .filter(\.$user.$id == userId)
            .first() {
            try await existingKeys.delete(on: req.db)
        }
        
        // Create new keys
        let keys = AlpacaKeys(
            id: nil,
            userId: userId,
            apiKey: create.apiKey,
            secretKey: create.secretKey
        )
        
        try await keys.save(on: req.db)
        return .ok
    }
    
    func getAlpacaKeys(req: Request) async throws -> AlpacaKeys.Public {
        let user = try req.auth.require(User.self)
        guard let userId = user.id else {
            throw Abort(.internalServerError, reason: "User ID not found")
        }
        
        guard let keys = try await AlpacaKeys.query(on: req.db)
            .filter(\.$user.$id == userId)
            .first() else {
            throw Abort(.notFound, reason: "No Alpaca keys found for user")
        }
        
        return keys.public
    }
    
    func deleteAlpacaKeys(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        guard let userId = user.id else {
            throw Abort(.internalServerError, reason: "User ID not found")
        }
        
        try await AlpacaKeys.query(on: req.db)
            .filter(\.$user.$id == userId)
            .delete()
        
        return .ok
    }
}
