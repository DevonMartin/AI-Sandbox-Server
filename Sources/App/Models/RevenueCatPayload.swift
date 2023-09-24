//
//  File.swift
//  
//
//  Created by Devon Martin on 9/24/23.
//

import Vapor

struct RevenueCatPayload: Content {
	let type: String
	let appUserID: String
	let originalTransactionID: String
	// Add more fields as necessary based on the RevenueCat webhook payload structure
}
