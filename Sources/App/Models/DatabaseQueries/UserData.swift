//
//  File.swift
//  
//
//  Created by Devon Martin on 10/7/23.
//

import Vapor

struct UserData: Content {
	let user: User?
	let IAPs: [InAppPurchase]?
	let balance: Double?
}
