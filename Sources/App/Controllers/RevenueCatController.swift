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
		
		let headers = req.headers
		
		guard let authorizationHeader = req.headers.first(name: "Authorization") else {
			throw Abort(.networkAuthenticationRequired, reason: "Missing Authorization header")
		}
		guard authorizationHeader == secret else {
			throw Abort(.unauthorized, reason: "Authorization header is incorrect.")
		}
		
		let payload: RevenueCatPayload
		
		do {
			payload = try req.content.decode(RevenueCatPayload.self)
		} catch {
			throw Abort(.internalServerError, reason: "Could not decode payload: \(error.localizedDescription)")
		}
		
		guard let event = payload.event else {
			throw Abort(.badRequest, reason: "No event provided in the payload.")
		}
		
		guard let userID = event.app_user_id else {
			throw Abort(.badRequest, reason: "No user ID provided.")
		}
		
		let user = (try? await User.find(userID, on: req.db)) ?? User(id: userID)
		
		do {
			try await user.addToBalance(event, req: req)
		} catch {
			throw Abort(.internalServerError, reason: "Could not add to balance: \(error.localizedDescription)")
		}
		let balance = await user.getBalance(req)
		
		let reasonPhrase = "User with ID \(userID) has a balance of $\(balance)"
		return .init(statusCode: 200, reasonPhrase: reasonPhrase)
	}
}
