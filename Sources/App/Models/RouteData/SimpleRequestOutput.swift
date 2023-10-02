//
//  File.swift
//  
//
//  Created by Devon Martin on 10/2/23.
//

import Vapor

struct SimpleRequestOutput: Content {
	let content: String
	let newBalance: Double
}
