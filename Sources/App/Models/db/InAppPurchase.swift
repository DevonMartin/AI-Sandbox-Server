//
//  File.swift
//  
//
//  Created by Devon Martin on 9/25/23.
//

import Vapor
import Fluent

final class InAppPurchase: Model, Content {
	static let schema = "in_app_purchases"
	
	@ID(key: .id)
	var id: UUID?
	
	@Parent(key: "user_id")
	var user: User
	
	@Field(key: "product_id")
	var productId: String
	
	@Field(key: "transaction_id")
	var transactionId: String
	
	@Field(key: "purchase_date")
	var purchaseDate: Date
	
	@Timestamp(key: "created_at", on: .create)
	var createdAt: Date?
	
	@Timestamp(key: "updated_at", on: .update)
	var updatedAt: Date?
	
	var credits: Double {
		let strippedID = transactionId.replacingOccurrences(of: "Tokens", with: "")
		return Double(strippedID) ?? 0
	}
	
	init() { }
	
	init(id: UUID? = nil, userId: User.IDValue, productId: String, transactionId: String, purchaseDate: Date) {
		self.id = id
		self.$user.id = userId
		self.productId = productId
		self.transactionId = transactionId
		self.purchaseDate = purchaseDate
	}
}
