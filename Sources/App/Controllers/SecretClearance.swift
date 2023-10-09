//
//  File.swift
//  
//
//  Created by Devon Martin on 10/7/23.
//

import Vapor

struct SecretClearance {
	private static let secret = Environment.get("SECRET")
	
	static func validate(_ req: Request) throws {
		guard let secret else {
			throw Abort(.internalServerError, reason: "Failed to fetch SECRET from the environment.")
		}
		
		guard let authorizationHeader = req.headers.first(name: "Authorization") else {
			throw Abort(.networkAuthenticationRequired, reason: "Missing Authorization header")
		}
		guard authorizationHeader == secret else {
			throw Abort(.unauthorized, reason: "Authorization header is incorrect.")
		}
	}
}
