//
//  RandomPromptData.swift
//
//
//  Created by Devon Martin on 9/21/23.
//

import Vapor

struct RandomPromptInput: Content {
	let category: String
	let userID: String
}
