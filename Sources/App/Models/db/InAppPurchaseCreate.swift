//
//  File.swift
//  
//
//  Created by Devon Martin on 9/28/23.
//

import Fluent

struct CreateInAppPurchase: Migration {
	func prepare(on database: Database) -> EventLoopFuture<Void> {
		return database.schema("in_app_purchases")
			.field("id", .string, .identifier(auto: false))
			.field("user_id", .string, .references("users", "id"))
			.field("product_id", .string)
			.field("purchase_date", .datetime)
			.field("created_at", .datetime)
			.field("updated_at", .datetime)
			.create()
	}
	
	func revert(on database: Database) -> EventLoopFuture<Void> {
		return database.schema("in_app_purchases").delete()
	}
}
