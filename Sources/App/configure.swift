import Vapor
import Fluent
import FluentPostgresDriver

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
//     app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
	
	guard let databaseURL = Environment.get("DATABASE_URL") else {
		fatalError("DATABASE_URL is not set. Did you forget to add it to `docker‑compose.yml`?")
	}
	
	app.logger.info("🌐 Database URL: `\(databaseURL)`")
	
	app.databases.use(try .postgres(url: databaseURL), as: .psql)
	
	app.migrations.add(CreateUser())
	app.migrations.add(CreateInAppPurchase())
//	app.migrations.add(AddAliasesToUser())
	try await app.autoMigrate()
	
//	Task { try await resetTables(app.db) }
	
    try routes(app)
}

private func resetTables(_ db: Database) async throws {
	let IAPs = try await InAppPurchase.query(on: db).all()
	let users = try await User.query(on: db).all()
	for object: any Model in IAPs + users { try await object.delete(on: db) }
}
