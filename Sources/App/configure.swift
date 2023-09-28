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
	
	app.migrations.add(CreateUser())
	app.migrations.add(CreateInAppPurchase())
	
    try routes(app)
}
