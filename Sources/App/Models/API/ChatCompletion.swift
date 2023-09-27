//
//  File.swift
//  
//
//  Created by Devon Martin on 9/21/23.
//

import Vapor

struct ChatCompletion: Content {
	let usage: Usage
	let choices: [Choice]
	
	struct Usage: Content {
		let promptTokens: Int
		let completionTokens: Int
		let totalTokens: Int
	}
	
	struct Choice: Content {
		let message: Message
		let finishReason: String?
		
		struct Message: Content {
			let content: String
		}
	}
}
