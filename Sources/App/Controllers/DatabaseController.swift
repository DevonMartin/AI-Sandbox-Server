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
		let user = await User.get(from: userID, req: req)
		let balance = await user?.getBalance(req)
		return BalanceData(userID: userID, balance: balance)
	}
	
	static func mergeAccounts(_ req: Request) async throws -> BalanceData {
		let userIDs = try req.content.decode([String].self)
		let user = try await mergeAccounts(userIDs, req: req)
		let balance = await user.getBalance(req)
		return .init(userID: user.id!, balance: balance)
	}
	
	static func mergeAccounts(_ userIDs: [String], req: Request) async throws -> User {
		var userIDs = userIDs.unique()
		guard userIDs.count > 1 else {
			throw Abort(.badRequest, reason: "Not enough IDs provided to perform merge operation.")
		}
		
		var users = try await User.query(on: req.db).all().filter {
			$0.id != nil && userIDs.contains($0.id!)
		}
		
		var mergedUser: User?
		
		for userID in userIDs {
			if let i = users.firstIndex(where: { $0.id == userID }) {
				mergedUser = users.remove(at: i)
				break
			}
		}
		
		guard let mergedUser else {
			let user = User(id: userIDs.first!, aliases: userIDs)
			try await user.save(on: req.db)
			throw Abort(.badRequest, reason: "No users found with provided IDs.")
		}
		
		guard !users.isEmpty else { return mergedUser }
		
		var usedCredits: Double = mergedUser.usedCredits ?? 0
		userIDs += mergedUser.aliases
		
		for user in users {
			usedCredits += user.usedCredits ?? 0
			userIDs += user.aliases
		}
		
		mergedUser.aliases = userIDs.unique()
		mergedUser.usedCredits = usedCredits
		
		try await mergedUser.save(on: req.db)
		
		var IAPs = try await InAppPurchase.query(on: req.db).all()
		
		for user in users {
			guard let id = user.id else { continue }
			
			let filteredIAPs = IAPs.filter { $0.$user.id == id }
			
			for IAP in filteredIAPs {
				IAP.$user.id = mergedUser.id!
				try await IAP.save(on: req.db)
				if let i = IAPs.firstIndex(where: { $0.id == IAP.id }) {
					IAPs.remove(at: i)
				}
			}
			
			try await user.delete(on: req.db)
		}
		
		return mergedUser
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
		
		guard let user = await User.get(from: userID, req: req) else {
			return "User not found."
		}
		
		return await user.dataString(req.db)
	}
}
