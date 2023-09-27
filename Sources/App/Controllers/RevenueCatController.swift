//
//  File.swift
//  
//
//  Created by Devon Martin on 9/24/23.
//

import Vapor

final class RevenueCatController {
	private static let secret = Environment.get("SECRET")
	
	static func handleWebhook(req: Request) throws -> HTTPStatus {
		
		guard let authorizationHeader = req.headers.bearerAuthorization else {
			throw Abort(.networkAuthenticationRequired, reason: "Missing Authorization header")
		}
		guard authorizationHeader.token == secret else {
			throw Abort(.unauthorized, reason: "Authorization header is incorrect.")
		}
		
		let payload = try req.content.decode(RevenueCatPayload.self)
		let event = payload.event
		print(event)
		
		
		return .ok
	}
}
