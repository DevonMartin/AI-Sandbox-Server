//
//  File.swift
//  
//
//  Created by Devon Martin on 10/2/23.
//

import Vapor

struct TitleInput: Content {
	let messages: [Message]
	let userID: String
}
