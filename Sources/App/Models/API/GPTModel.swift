//
//  File.swift
//  
//
//  Created by Devon Martin on 9/26/23.
//

struct GPTModel {
	let costPerToken: (input: Double, output: Double)
	let maxTokens: Int
	var maxInputExpense: Double {
		Double(maxTokens) * costPerToken.input
	}
	var maxOutputExpense: Double {
		Double(maxTokens) * costPerToken.output
	}
	
	init(model: String) {
		let input: Double
		let output: Double
		
		if model.contains("16k") {
			input = 0.003
			output = 0.004
			maxTokens = 16385
		} else if model.contains("32k") {
			input = 0.06
			output = 0.12
			maxTokens = 32768
		} else if model.contains("3.5") {
			input = 0.0015
			output = 0.002
			maxTokens = 4097
		} else if model.contains("4") {
			input = 0.03
			output = 0.06
			maxTokens = 8192
		} else {
			fatalError("Failed to parse model name to find base model.")
		}
		
		// Actual cost is /1000. 500 is used to give a 50% buffer to cover expenses.
		costPerToken = (input: input / 500, output: output / 500)
	}
	
	enum Base: String {
		case gpt3 = "gpt-3.5-turbo"
		case gpt16k = "gpt-3.5-turbo-16k"
		case gpt4 = "gpt-4"
		case gpt32k = "gpt-4-32k"
	}
}
