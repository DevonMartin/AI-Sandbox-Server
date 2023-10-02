//
//  Message.swift
//
//
//  Created by Devon Martin on 9/21/23.
//

import Vapor

struct SendMessagesInput: VerifyFundsDataProtocol {
	let systemMessage: String
	let messages: [Message]
	let model: String
	let responseBudget: Double
	let temperature: Double
	let userID: String
}

struct SendMessagesOutput: Content {
	let message: Message?
	let cost: Double?
	let newBalance: Double?
	let error: String?
}

struct Message: Content {
	let content: String
	let sentByUser: Bool
	let timestamp: Double
}
