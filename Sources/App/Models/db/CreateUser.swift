//
//  File.swift
//  
//
//  Created by Devon Martin on 9/28/23.
//

import Fluent

struct CreateUser: Migration {
	func prepare(on database: Database) -> EventLoopFuture<Void> {
		return database.schema("users")
			.field("id", .string, .identifier(auto: false))
			.field("used_credits", .double)
			.field("created_at", .datetime)
			.field("updated_at", .datetime)
			.field("aliases", .array(of: .string))
			.create()
	}
	
	func revert(on database: Database) -> EventLoopFuture<Void> {
		return database.schema("users").delete()
	}
}
