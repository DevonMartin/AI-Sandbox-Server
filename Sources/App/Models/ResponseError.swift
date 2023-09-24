//
//  File.swift
//  
//
//  Created by Devon Martin on 9/21/23.
//

struct ResponseError: Decodable {
	let error: ErrorMessage
	
	struct ErrorMessage: Decodable, CustomStringConvertible {
		let type: String
		let code: String
		let param: String
		let message: String
		
		var description: String {
			"Error from ChatGPT API of type \(type) with code \(code): \(message)"
		}
	}
}
