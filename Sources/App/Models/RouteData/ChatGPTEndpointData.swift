//
//  Message.swift
//
//
//  Created by Devon Martin on 9/21/23.
//

import Vapor
import ChatGPT

struct AISandboxServerInput: Content {
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
}

struct AISandboxServerOutput: Content {
	var message: ChatCompletion.Message? = nil
	var cost: Double? = nil
	var newBalance: Double? = nil
}
