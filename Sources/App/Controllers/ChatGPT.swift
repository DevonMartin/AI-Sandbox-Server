//
//  File.swift
//  
//
//  Created by Devon Martin on 9/21/23.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Vapor
import ChatGPT

class ChatGPT {
	
	private init() {}
	
	// MARK: - API
	
	static func chatCompletion(_ req: Request) async throws -> AISandboxServerOutput {
		guard let inputData = try? req.content.decode(AISandboxServerInput.self) else {
			throw Abort(.badRequest)
		}
		
		let chatCompReq = try await generateRequestData(from: inputData, req: req)
		return try await getResponse(to: chatCompReq, req: req)
	}
	
	static func getAvailableModels(_ req: Request) async throws -> [ChatGPTModel] {
		let apiKey = try getKey()
		return try await Models.fetchChatCompletion(with: apiKey, priceAdjustmentFactor: 2)
	}
	
	
	// MARK: - Helper Functions
	
	private static func generateRequestData(
		from inputData: AISandboxServerInput,
		req: Request
	) async throws -> ChatCompletion.Request {
		guard let user = try? await User.find(inputData.userID, on: req.db) else {
			throw self.ServerError.noUser
		}
		
		let balance = await user.getBalance(req)
		
		let (messages, maxTokens) = try await inputData.model.filterMessagesToFitBudget(
			inputData.messages,
			maxBudget: balance
		)
		
		return .init(
			model: inputData.model.id,
			messages: messages,
			temperature: inputData.temperature,
			maxTokens: maxTokens,
			user: inputData.userID
		)
	}
	
	private static func getKey() throws -> String {
		guard let apiKey = Environment.get("API_KEY") else {
			throw Abort(.internalServerError, reason: "Failed to fetch API key from the environment.")
		}
		return apiKey
	}
	
	private static func getResponse(
		to chatCompReq: ChatCompletion.Request,
		req: Request
	) async throws -> AISandboxServerOutput {
		
		let response: ClientResponse
		let uri: URI = .init(string: ChatCompletion.endpointURL)
		let apiKey = try getKey()
		
		response = try await req.client.post(uri) { req in
			try req.content.encode(chatCompReq, as: .json)
			req.headers.bearerAuthorization = .init(token: apiKey)
		}
		
		guard let body = response.body else { throw Abort(.failedDependency) }
		
		let output: ChatCompletion.Response
		
		do {
			output = try JSONDecoder().decode(ChatCompletion.Response.self, from: body)
		} catch {
			print("###\(#function): \(error.localizedDescription)")
			let badResponse = try JSONDecoder().decode(ChatCompletion.BadResponse.self, from: body)
			
			// Error message from API call is descriptive enough to be returned to the user.
			throw badResponse.error
		}
		
		return try await generateDataFromResponse(output, chatCompReq: chatCompReq, req: req)
	}
	
	private static func generateDataFromResponse(
		_ response: ChatCompletion.Response,
		chatCompReq: ChatCompletion.Request,
		req: Request
	) async throws -> AISandboxServerOutput {
		
		let usage = response.usage
		let sendTokens = usage.promptTokens
		let receiveTokens = usage.completionTokens
		let model = ChatGPTModel(id: chatCompReq.model)
		let costPerToken = model.tokens.cost
		let sendCost = costPerToken.input * Double(sendTokens)
		let receiveCost = costPerToken.output * Double(receiveTokens)
		let totalCost = sendCost + receiveCost
		
		let userID = chatCompReq.user
		
		var newBalance: Double?
		
		if let user = try? await User.find(userID, on: req.db) {
			user.usedCredits = (user.usedCredits ?? 0) + totalCost
			
			do {
				try await user.save(on: req.db)
			} catch {
				throw ChatGPT.ServerError.database
			}
			newBalance = await user.getBalance(req)
		}
		
		let content = response.choices[0].message.content
		let message = ChatCompletion.Message(role: .assistant, content: content)
		return .init(message: message, cost: totalCost, newBalance: newBalance)
	}
	
	enum ServerError: Error {
		case database, noUser
		
		var description: String {
			switch self {
				case .database:
					return "Unable to process your request due to an internal database error."
				case .noUser:
					return "No user found with the provided ID. Please log out and back in."
			}
		}
	}
}
