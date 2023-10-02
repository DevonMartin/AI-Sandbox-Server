//
//  VerifyFundsData.swift
//
//
//  Created by Devon Martin on 10/2/23.
//

import Vapor

protocol VerifyFundsDataProtocol: Content {
	var userID: String { get }
	var model: String { get }
	var responseBudget: Double { get }
	var temperature: Double { get }
}

struct VerifyFundsData: VerifyFundsDataProtocol {
	var userID: String
	var model: String = GPTModel.Base.gpt3.rawValue
	var responseBudget: Double = 0
	var temperature: Double
}
