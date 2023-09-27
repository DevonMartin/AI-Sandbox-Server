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
	
	init() {}
	
	init(id: String) {
		self.id = id
		self.usedCredits = 0
	}
	
	func getBalance(_ req: Request) async -> Double {
		guard let id else { return 0 }
		
		let purchases = try? await InAppPurchase.query(on: req.db)
			.filter(\.$user.$id == id)
			.all()
		
		guard let purchases else { return 0 }
		
		let totalPurchasedCredits = purchases.map { $0.credits }.reduce(0, +)
		return totalPurchasedCredits - (usedCredits ?? 0)
	}
	
	func addToBalance(_ event: Event, req: Request) async throws {
		
		let purchaseDate = Date(timeIntervalSince1970: TimeInterval(event.purchased_at_ms) / 1000)
		
		let purchase = InAppPurchase(
			id: event.transaction_id,
			userId: id!,
			productId: event.product_id,
			purchaseDate: purchaseDate
		)
		
		try await purchase.save(on: req.db)
		try await save(on: req.db)
	}
}
