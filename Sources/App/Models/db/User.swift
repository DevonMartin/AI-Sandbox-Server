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
	
	@Field(key: "used_credits")
	var usedCredits: Double?
	
	init() { }
	
	init(id: String? = nil) {
		self.id = id
		self.usedCredits = 0
	}
	
	func getBalance(_ req: Request) -> Double? {
		guard let id else { return nil }
		
		let purchasesRequest = InAppPurchase.query(on: req.db)
			.filter(\.$user.$id == id)
			.all()
		
		guard let purchases = try? purchasesRequest.wait() else { return nil }
		let totalPurchasedCredits = purchases.map { $0.credits }.reduce(0, +)
		return (usedCredits ?? 0) - totalPurchasedCredits
	}
}
