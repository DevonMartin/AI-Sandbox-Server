//
//  Message.swift
//
//
//  Created by Devon Martin on 9/21/23.
//

import Vapor
import ChatGPT

struct AISandboxServer {
	struct Input: Content {
		let messages: [ChatCompletion.Message]
		let model: ChatGPTModel
		let temperature: Double
		let userID: String
		
		enum CodingKeys: String, CodingKey {
			case messages
			case model
			case temperature
			case userID = "user"
		}
		
		private init(
			messages: [ChatCompletion.Message],
			model: ChatGPTModel,
			temperature: Double,
			userID: String
		) {
			self.messages = messages
			self.model = model
			self.temperature = temperature
			self.userID = userID
		}
	}

	struct Output: Content {
		var message: ChatCompletion.Message
		var cost: Double
		var newBalance: Double?
	}
	
	private init() {}
}
