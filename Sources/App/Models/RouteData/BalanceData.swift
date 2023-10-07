//
//  File.swift
//
//
//  Created by Devon Martin on 9/25/23.
//

import Vapor

struct BalanceData: Content {
	let userID: String
	let balance: Double?
}
