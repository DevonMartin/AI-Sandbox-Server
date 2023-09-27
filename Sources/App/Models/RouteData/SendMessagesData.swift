//
//  Message.swift
//
//
//  Created by Devon Martin on 9/21/23.
//

import Foundation
import Vapor

struct SendMessagesData: Content {
	let systemMessage: String
	let messages: [Message]
	let model: String
	let responseBudget: Double?
	let temperature: Double
	let userID: String
}

struct Message: Content {
	let content: String
	let sentByUser: Bool
	let timestamp: Date
}
