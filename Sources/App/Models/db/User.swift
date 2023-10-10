//
//  File.swift
//  
//
//  Created by Devon Martin on 9/25/23.
//

import Vapor
import Fluent

final class User: Model, Content {
	static let schema = "users"
	
	@ID(custom: "id", generatedBy: .user)
	var id: String?
	
	@Timestamp(key: "created_at", on: .create)
	var createdAt: Date?
	
	@Timestamp(key: "updated_at", on: .update)
	var updatedAt: Date?
	
	@Field(key: "aliases")
	var aliases: [String]
	
	@Field(key: "used_credits")
	var usedCredits: Double?
	
	init() {}
	
	init(id: String, aliases: [String] = []) {
		self.id = id
		self.usedCredits = 0
		self.aliases = aliases
	}
	
	static func get(from aliases: [String], req: Request) async -> User? {
		guard !aliases.isEmpty else { return nil }
		guard let users = try? await User.query(on: req.db).all().filter( {
			$0.id != nil && aliases.contains($0.id!)
		} ) else {
			return nil
		}
		
		return await merge(users: users, req: req)
	}
	
	static func get(from id: String?, req: Request) async -> User? {
		await get(from: [id].compactMap({$0}), req: req)
	}
	
	private static func merge(users: [User], req: Request) async -> User? {
		if users.isEmpty { return nil }
		if users.count > 1 {
			let aliases = users.reduce(into: [String]()) {
				$0 += $1.aliases
			}
			return try? await DatabaseController.mergeAccounts(aliases, req: req)
		}
		
		return users.first!
	}
	
	func getBalance(_ req: Request) async -> Double {
		guard let id,
			  let purchases = try? await InAppPurchase.query(on: req.db)
			.filter(\.$user.$id == id)
			.all()
		else {
			return 0
		}
		
		let totalPurchasedCredits = purchases.map { $0.credits }.reduce(0, +)
		return totalPurchasedCredits - (usedCredits ?? 0)
	}
	
	func addToBalance(_ event: RevenueCatPayload.Event, req: Request) async throws {
		do {
			try await save(on: req.db)
		} catch {
			throw Abort(
				.internalServerError,
				reason: "Unable to save user to database: \(String(reflecting: error))"
			)
		}
		
		guard let transactionID = event.transaction_id,
			  let purchaseAtMS = event.purchased_at_ms,
			  let productID = event.product_id else {
			throw Abort(.badRequest, reason: "Necessary data not provided.")
		}
		let purchaseDate = Date(timeIntervalSince1970: TimeInterval(purchaseAtMS) / 1000)
		
		let purchase = InAppPurchase(
			id: transactionID,
			userId: self.id!,
			productId: productID,
			purchaseDate: purchaseDate
		)
		
		do {
			try await purchase.save(on: req.db)
		} catch {
			let reason = "Unable to save in-app purchase to database: \(error.localizedDescription)"
			throw Abort(.internalServerError, reason: reason)
		}
	}
}

extension User: CustomStringConvertible {
	var description: String {
  """
User:
	ID: \(id ?? "None")
	Aliases: \(aliases.reduce("", { $0 + "\n\t\t\($1)" } ) )
	Used Credits: \(String(format: "%.2f", usedCredits ?? 0))

"""
	}
	
	func dataString(_ db: Database) async -> String {
		var string =   """
User:

\tID: \(id ?? "None")

"""
		
		if aliases.count > 1 {
			string += "\n\tAliases:\n\(aliases.reduce("", { $0 + "\n\t\t\($1)" } ) )\n"
		}
		
		guard let id,
			  let IAPs = try? await InAppPurchase.query(on: db)
			.filter(\.$user.$id == id)
			.sort(\.$createdAt)
			.all()
		else {
			return string
		}
		
		let paid = IAPs.map(\.credits).reduce(0, +)
		
		if let used = usedCredits, used > 0 {
			
			let left = paid - used
			
			var spaces = [
				"paid": String(Int(paid)).count,
				"used": String(Int(used)).count,
				"left": String(Int(left)).count
			]
			
			spaces["max"] = spaces.values.max() ?? 0
			
			func spacesFor(_ s: String) -> String {
				String(repeating: " ", count: spaces["max"]! - spaces[s]!)
			}
			
			string += "\n\tCredits:\n"
			string += "\n\t\tPurchased:  \(spacesFor("paid")) \(paid.usd)"
			string += "\n\t\tUsed:      -\(spacesFor("used")) \(used.usd)"
			string += "\n\t\t\(String(repeating: "-", count: spaces["max"]! + 17))"
			string += "\n\t\tRemaining:  \(spacesFor("left")) \(left.usd)"
			
		} else {
			string += "\n\tCredits:\n"
			string += "\n\t\tPurchased:   \(paid.usd)"
		}
		
		string += "\n\n\tIn-App Purchases:\n"
		
		for IAP in IAPs {
			string += "\(IAP)"
		}
		
		return string
	}
}


private extension Double {
	var usd: String { "$\(String(format: "%.2f", self))" }
}
