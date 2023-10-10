import Vapor

func routes(_ app: Application) throws {
	// http://127.0.0.1:8080
    app.get { req async in
        "It works!"
    }
	
	// http://127.0.0.1:8080/revenueCat
	app.post("revenueCat", use: RevenueCatController.handleWebhook(req:))
	
	let api = app.grouped("api")
	let gpt = ChatGPT.self
	
	// http://127.0.0.1:8080/api/chatCompletion
	api.post("chatCompletion", use: gpt.chatCompletion)
	
	// http://127.0.0.1:8080/api/availableModels
	api.get("availableModels", use: gpt.getAvailableModels)
	
	let db = DatabaseController.self
	
	// http://127.0.0.1:8080/api/getBalance
	api.post("getBalance", use: db.getUserBalance)
	
	// http://127.0.0.1:8080/api/merge
	api.put("merge", use: db.mergeAccounts)
	
	// http://127.0.0.1:8080/api/data
	api.get("data", use: db.getAllUserData)
	
	// http://127.0.0.1:8080/api/data/{userID}
	api.get("data", ":userID", use: db.getUserDataString)
}
