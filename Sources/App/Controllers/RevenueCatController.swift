//
//  File.swift
//  
//
//  Created by Devon Martin on 9/24/23.
//

import Vapor

final class RevenueCatController {
	private let secret = "ZGZzZzozbmZmM25ucmNqdm5iZWZqaGt2YjNqaHIgZmhqa2VybmIgdmprZW52"
	
	func handleWebhook(req: Request) throws -> EventLoopFuture<HTTPStatus> {
		print(req.headers[.authorization].first as Any)
		guard let authorizationHeader = req.headers[.authorization].first,
		authorizationHeader == secret else {
			throw Abort(.unauthorized, reason: "Missing Authorization header")
		}
		// Decode the webhook payload
		let payload = try req.content.decode(RevenueCatPayload.self)
		
		// TODO: Process the payload (e.g., store data, update user entitlements, etc.)
		
		// For now, just print the received payload
		print(payload)
		
		// Return a 200 OK response
		return req.eventLoop.future(.ok)
	}
}
