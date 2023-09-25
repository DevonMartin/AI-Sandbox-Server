//
//  File.swift
//  
//
//  Created by Devon Martin on 9/24/23.
//

import Vapor

final class RevenueCatController {
	private let secret = Environment.get("SECRET")
	
	func handleWebhook(req: Request) throws -> HTTPStatus {
		
		guard let authorizationHeader = req.headers.bearerAuthorization else {
			throw Abort(.networkAuthenticationRequired, reason: "Missing Authorization header")
		}
		guard authorizationHeader.token == secret else {
			throw Abort(.unauthorized, reason: "Authorizastion header is incorrect.")
		}
		
		let payload = try req.content.decode(RevenueCatPayload.self)
		
		// TODO: Process the payload (e.g., store data, update user entitlements, etc.)
		
		return .ok
	}
}
