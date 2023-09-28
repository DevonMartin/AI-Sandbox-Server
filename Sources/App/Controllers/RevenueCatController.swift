//
//  File.swift
//  
//
//  Created by Devon Martin on 9/24/23.
//

import Vapor

final class RevenueCatController {
	private static let secret = Environment.get("SECRET")
	
	static func handleWebhook(req: Request) async throws -> HTTPStatus {
		guard let secret else {
			throw Abort(.internalServerError, reason: "Failed to fetch SECRET from the environment.")
		}
		
		guard let authorizationHeader = req.headers.bearerAuthorization else {
			throw Abort(.networkAuthenticationRequired, reason: "Missing Authorization header")
		}
		guard authorizationHeader.token == secret else {
			throw Abort(.unauthorized, reason: "Authorization header is incorrect.")
		}
		
		let payload = try req.content.decode(RevenueCatPayload.self)
		
		let event = payload.event
		let userID = event.app_user_id
		let user = (try? await User.find(userID, on: req.db)) ?? User(id: userID)
		
		try await user.addToBalance(event, req: req)
		let balance = await user.getBalance(req)
		
		let reasonPhrase = "User with ID \(userID) has a balance of $\(balance)"
		return .init(statusCode: 200, reasonPhrase: reasonPhrase)
	}
}
