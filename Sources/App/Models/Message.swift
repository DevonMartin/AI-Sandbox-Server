//
//  Message.swift
//
//
//  Created by Devon Martin on 9/21/23.
//

import Foundation
import Vapor

struct Message: Content {
	let content: String
	let sentByUser: Bool
	let timestamp: Date
}
