//
//  File.swift
//  
//
//  Created by Devon Martin on 9/25/23.
//

import Vapor

struct ChatRequestData: Content {
	let model: String
	let messages: [ChatRequestMessageData]
	let temperature: Double
	let maxTokens: Int?
	let user: String
}

struct ChatRequestMessageData: Content {
	public let role: Role
	let content: String
}

typealias Role = String

extension Role {
	static let user = "user"
	static let assistant = "assistant"
}
