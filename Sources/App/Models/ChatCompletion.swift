//
//  File.swift
//  
//
//  Created by Devon Martin on 9/21/23.
//

struct ChatCompletion: Decodable {
	let usage: Usage
	let choices: [Choice]
	
	struct Usage: Decodable {
		let promptTokens: Int
		let completionTokens: Int
		let totalTokens: Int
	}
	
	struct Choice: Decodable {
		let message: Message
		let finishReason: String?
		
		struct Message: Decodable {
			let content: String
		}
	}
}
