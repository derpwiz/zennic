import Fluent

struct CreateAlpacaKeys: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(AlpacaKeys.schema)
            .id()
            .field("user_id", .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
            .field("api_key", .string, .required)
            .field("secret_key", .string, .required)
            .field("is_paper", .bool, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "user_id")
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(AlpacaKeys.schema).delete()
    }
}
