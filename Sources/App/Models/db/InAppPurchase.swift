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
	
	@ID(custom: "id", generatedBy: .user)
	var id: String?
	
	@Parent(key: "user_id")
	var user: User
	
	@Field(key: "product_id")
	var productId: String
	
	
	@Field(key: "purchase_date")
	var purchaseDate: Date
	
	@Timestamp(key: "created_at", on: .create)
	var createdAt: Date?
	
	@Timestamp(key: "updated_at", on: .update)
	var updatedAt: Date?
	
	var credits: Double {
		let creditsString = productId.replacingOccurrences(of: "Tokens", with: "")
		return Double(creditsString) ?? 0
	}
	
	init() {}
	
	init(id: String, userId: User.IDValue, productId: String, purchaseDate: Date) {
		self.id = id
		self.$user.id = userId
		self.productId = productId
		self.purchaseDate = purchaseDate
	}
}

extension InAppPurchase: CustomStringConvertible {
	var description: String {
  """

\t\tID:          \(id ?? "None")
\t\tProduct ID:  \(productId)
\t\tCredits:     $\((credits))0

"""
	}
}
