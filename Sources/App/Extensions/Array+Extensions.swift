//
//  File.swift
//  
//
//  Created by Devon Martin on 9/26/23.
//

import Tiktoken

extension Array<ChatRequestMessageData> {
	func inputCost(with model: GPTModel) async -> Double {
		var concatenatedMessages = ""
		for message in self {
			let role = "role: " + message.role  // Add labels and space.
			let content = "content: " + message.content  // Add labels and space.
			
			// Including both role and content, separated by a space.
			concatenatedMessages += "\(role) \(content)"
		}
		
		// Now, count the tokens for the entire string.
		let count = await Tiktoken.count(concatenatedMessages)
		return Double(count) * model.costPerToken.input
	}
}
