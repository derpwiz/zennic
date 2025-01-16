import Vapor
import Fluent
import FluentPostgresDriver
import Redis
import JWT

public func configure(_ app: Application) throws {
    // MARK: - Database
    let configuration = SQLPostgresConfiguration(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? 5432,
        username: Environment.get("DATABASE_USERNAME") ?? "postgres",
        password: Environment.get("DATABASE_PASSWORD") ?? "postgres",
        database: Environment.get("DATABASE_NAME") ?? "aihedgefund",
        tls: .disable
    )
    
    app.databases.use(.postgres(
        configuration: configuration,
        maxConnectionsPerEventLoop: 2,
        connectionPoolTimeout: .seconds(10)
    ), as: .psql)
    
    // MARK: - Redis
    app.redis.configuration = try RedisConfiguration(
        hostname: Environment.get("REDIS_HOST") ?? "localhost",
        port: Environment.get("REDIS_PORT").flatMap(Int.init(_:)) ?? 6379
    )
    
    // MARK: - JWT
    app.jwt.signers.use(.hs256(key: Environment.get("JWT_SECRET") ?? "development-secret-key"))
    
    // MARK: - Middleware
    app.middleware = .init()
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    // MARK: - Routes
    try routes(app)
    
    // MARK: - Migrations
    app.migrations.add(CreateUser())
    app.migrations.add(CreateAlpacaKeys())
    
    // Run migrations automatically in development
    if app.environment == .development {
        try app.autoMigrate().wait()
    }
}
