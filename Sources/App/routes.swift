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
	app.post("revenueCat", use: RevenueCatController.handleWebhook(req:))
	
	let api = app.grouped("api")
	
	// http://127.0.0.1:8080/api/getBalance/
	api.post("getBalance") { req async throws -> BalanceData in
		let userID = try req.content.decode(String.self)
		let user = try? await User.find(userID, on: req.db)
		let balance = await user?.getBalance(req)
		return BalanceData(userID: userID, balance: balance)
	}
	
	// http://127.0.0.1:8080/api/sendMessages/
	api.post("sendMessages", use: ChatGPT.sendMessages)
}
