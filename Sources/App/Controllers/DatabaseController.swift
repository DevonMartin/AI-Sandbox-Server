//
//  DatabaseController.swift
//
//
//  Created by Devon Martin on 10/7/23.
//

import Vapor

struct DatabaseController {
	static func getUserBalance(_ req: Request) async throws -> BalanceData {
		let userID = try req.content.decode(String.self)
		let user = await User.get(from: userID, db: req.db)
		let balance = await user?.getBalance(req)
		return BalanceData(userID: userID, balance: balance)
	}
	
	static func getAllUserData(_ req: Request) async throws -> String {
		try SecretClearance.validate(req)
		let users = try await User.query(on: req.db).all()
		
		var s = ""
		for user in users {
			s += await user.dataString(req.db) + "\n"
		}
		
		return s
	}
	
	static func getUserDataString(_ req: Request) async throws -> String {
		try SecretClearance.validate(req)
		let userID = req.parameters.get("userID")!
		
		guard let user = await User.get(from: userID, db: req.db) else {
			return "User not found."
		}
		
		return await user.dataString(req.db)
	}
}
