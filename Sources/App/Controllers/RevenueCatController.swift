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
		try SecretClearance.validate(req)
		
		guard let event = try getEvent(from: req) else {
			throw Abort(.badRequest, reason: "No event provided in the payload.")
		}
		
		guard let user = await getUser(from: event, req: req) else {
			throw Abort(.badRequest, reason: "No user ID provided.")
		}
		
		do {
			try await user.addToBalance(event, req: req)
		} catch {
			throw Abort(.internalServerError, reason: "Could not add to balance: \(error)")
		}
		
		let balance = await user.getBalance(req)
		let reasonPhrase = "User with ID \(user.id as Any) has a balance of $\(balance)"
		
		return .init(statusCode: 200, reasonPhrase: reasonPhrase)
	}
	
	private static func getEvent(from req: Request) throws -> RevenueCatPayload.Event? {
		do {
			let payload = try req.content.decode(RevenueCatPayload.self)
			return payload.event
		} catch {
			throw Abort(.internalServerError, reason: "Could not decode payload: \(error)")
		}
	}
	
	private static func getUser(
		from event: RevenueCatPayload.Event,
		req: Request
	) async -> User? {
		
		var aliases = event.aliases ?? []
		if let id = event.app_user_id { aliases.append(id) }
		if let id = event.original_app_user_id { aliases.append(id) }
		guard !aliases.isEmpty else { return nil }
			
		guard let user = await User.get(from: aliases, req: req) else {
			return User(id: aliases.first!, aliases: aliases.unique())
		}
		
		user.aliases = (aliases + user.aliases).unique()
		return user
	}
}
