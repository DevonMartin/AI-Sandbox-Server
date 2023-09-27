//
//  VerificationRequest.swift
//
//
//  Created by Devon Martin on 9/22/23.
//

import Vapor

struct VerificationRequest: Content {
	let jwsRepresentation: String
}
