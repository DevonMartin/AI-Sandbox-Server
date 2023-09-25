import Vapor

func routes(_ app: Application) throws {
	// http://127.0.0.1:8080
    app.get { req async in
        "It works!"
    }

	// http://127.0.0.1:8080/hello
    app.get("hello") { req async -> String in
        "Hello, world!"
    }
	
	// http://127.0.0.1:8080/revenueCat
	let rcController = RevenueCatController()
	app.post("revenueCat", use: rcController.handleWebhook(req:))
	
	let api = app.grouped("api")
	
	// http://127.0.0.1:8080/api/sendMessages/
	api.post("sendMessages") { req async throws -> Message in
		let data = try req.content.decode(SendMessagesData.self)
		
		do {
			let content = try await ChatGPT.sendMessages(data)
			let message = Message(content: content, sentByUser: false, timestamp: Date.now)
			return message
		} catch {
			throw Abort(.badRequest)
		}
	}
}
