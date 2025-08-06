@testable import App
import VaporTesting
import Testing
import FluentSQLiteDriver
import struct ChatGPT.ChatCompletion

@Suite("App Tests")
struct AppTests {
	private let testUserID = "user123"
	
	private func withApp(_ test: (Application) async throws -> ()) async throws {
		// build, configure, migrate, and tear down in one place
		let app = try await Application.make(.testing)
		app.databases.use(.sqlite(.memory), as: .sqlite)
		
		do {
			try await configure(app)
			try await app.autoMigrate()
			try await test(app)
			try await app.autoRevert()
		} catch {
			try? await app.autoRevert()
			try await app.asyncShutdown()
			throw error
		}
		
		try await app.asyncShutdown()
	}
	
	@Test("Base Route")
	func testBaseEndpoint() async throws {
		try await withApp { app in
			try await app.testing().test(.GET, "") { res async in
				#expect(res.status == .ok)
				#expect(res.body.string == "It works!")
			}
		}
	}
	
	@Test("Available Models Route")
	func testGetAvailableModelsEndpoint() async throws {
		try await withApp { app in
			try await app.testing().test(.GET, "/api/availableModels") { res async in
				#expect(res.status == .ok)
				let body = res.body.string
				#expect(body.contains("gpt"))
				print(body)
			}
		}
	}
	
	@Test("All User Data Route")
	func testGetAllUserDataEndpoint() async throws {
		try await withApp { app in
			_ = try await seedUserAndPurchase(app)
			
			let secret = Environment.get("SECRET")!
			let headers = HTTPHeaders([("Authorization", "\(secret)")])
			try await app.testing(
			).test(.GET,
				   "/api/data",
				   headers: headers
			) { res async in
				#expect(res.status == .ok)
				let body = res.body.string
				
				// It should:
				// mention our user ID,
				#expect(body.contains("ID: \(testUserID)"))
				// list the 10 purchased tokens,
				#expect(body.contains("$10.00"))
				// subtract the 2 used,
				#expect(body.contains("$2.00"))
				// and show the 8 remaining tokens
				#expect(body.contains("$8.00"))
			}
		}
	}
	
	@Test("Send Message Route")
	func testSendMessageEndpoint() async throws {
		try await withApp { app in
			_ = try await seedUserAndPurchase(app)
			
			let secret = Environment.get("SECRET")!
			let headers = HTTPHeaders([("Authorization", "\(secret)")])
			
			// TODO: Move AISandboxServer to ChatGPT package, remove from Server.
			let payload = AISandboxServer.Input(
			  messages: [.init(role: .system, content: "Respond only \"test\"")],
			  model: .init(.gpt35Turbo),
			  temperature: 0,
			  userID: testUserID
			)
			
			try await app.test(.POST, "/api/chatCompletion", headers: headers) { req in
				try req.content.encode(payload, as: .json)
			} afterResponse: { res in
				#expect(res.status == .ok)
				let body = res.body
				let message = try JSONDecoder().decode(
					AISandboxServer.Output.self,
					from: body
				).message
				#expect(message.content == "test")
			}
		}
	}
	
	private func seedUserAndPurchase(_ app: Application) async throws -> (User, InAppPurchase) {
		let user = User(id: "user123", aliases: ["user123"])
		user.usedCredits = 2.0
		try await user.save(on: app.db)
		
		let purchase = InAppPurchase(
			id: "txn-001",
			userId: "user123",
			productId: "10Tokens",
			purchaseDate: Date()
		)
		try await purchase.save(on: app.db)
		
		return (user, purchase)
	}
}
