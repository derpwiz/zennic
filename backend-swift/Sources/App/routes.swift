import Vapor

func routes(_ app: Application) throws {
    // Health check
    app.get("health") { req -> String in
        "OK"
    }
    
    try app.register(collection: UserController())
    try app.register(collection: StockController())
}
