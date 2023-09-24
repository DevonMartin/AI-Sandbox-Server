//
//  SendMessagesData.swift
//  
//
//  Created by Devon Martin on 9/21/23.
//

import Foundation

struct SendMessagesData: Codable {
	let systemMessage: String
	let messages: [Message]
	let model: String
	let maxTokens: Int?
	let temperature: Double
}
