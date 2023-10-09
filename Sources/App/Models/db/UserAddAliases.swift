//
//  File.swift
//  
//
//  Created by Devon Martin on 10/9/23.
//

import Fluent

struct AddAliasesToUser: Migration {
	func prepare(on database: Database) -> EventLoopFuture<Void> {
		// Add the 'aliases' column with a default value of an empty array
		database.schema("users")
			.field("aliases", .array(of: .string), .sql(.default("{}")))
			.update()
	}
	
	func revert(on database: Database) -> EventLoopFuture<Void> {
		database.schema("users")
			.deleteField("aliases")
			.update()
	}
}
