import Vapor
import Fluent
import FluentPostgresDriver

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
	
	guard let databaseURL = Environment.get("DATABASE_URL") else {
fatalError("Unable to retrieve database URL from the environment.")
	}
	
	app.databases.use(try .postgres(url: databaseURL), as: .psql)
	
//	app.migrations.add(CreateUser())
//	app.migrations.add(CreateInAppPurchase())
//	app.migrations.add(AddAliasesToUser())
	
//	Task { await testing(app.db) }
//	Task { try await resetTables(app.db) }
	
    try routes(app)
}

//private func testing(_ db: Database) async {
//	guard let users = try? await User.query(on: db).all() else { return }
//	
//	print("")
//	
//	for user in users where user.id != nil { await print(user.dataString(db)) }
//}

//private func resetTables(_ db: Database) async throws {
//	let IAPs = try await InAppPurchase.query(on: db).all()
//	for IAP in IAPs { try await IAP.delete(on: db) }
//	let users = try await User.query(on: db).all()
//	for user in users { try await user.delete(on: db) }
//}
