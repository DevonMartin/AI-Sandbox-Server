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
	
	static func chatCompletion(_ req: Request) async throws -> AISandboxServer.Output {
		let inputData: AISandboxServer.Input
		
		do {
			inputData = try req.content.decode(AISandboxServer.Input.self)
		} catch {
			throw Abort(.badRequest, reason: "\(error)")
		}
		
		let (chatCompReq, user) = try await generateRequestData(from: inputData, req: req)
		
		return try await getResponse(
			to: chatCompReq,
			model: inputData.model,
			user: user,
			req: req
		)
	}
	
	static func getAvailableModels(_ req: Request) async throws -> [ChatGPTModel] {
		let apiKey = try getKey()
		return try await Models.fetchChatCompletion(with: apiKey, priceAdjustmentFactor: 2)
	}
	
	
	// MARK: - Helper Functions
	
	private static func generateRequestData(
		from inputData: AISandboxServer.Input,
		req: Request
	) async throws -> (req: ChatCompletion.Request, user: User) {
		guard let user = await User.get(from: inputData.userID, req: req) else {
			throw Abort(.notFound, reason: ServerError.noUser.description)
		}
		
		let balance = await user.getBalance(req)
		
		let (messages, maxTokens) = try await inputData.model.filterMessagesToFitBudget(
			inputData.messages,
			maxBudget: balance
		)
		
		return (.init(
			model: inputData.model.id,
			messages: messages,
			temperature: inputData.temperature,
			maxTokens: maxTokens,
			user: inputData.userID
		),
				user)
	}
	
	private static func getKey() throws -> String {
		guard let apiKey = Environment.get("API_KEY") else {
			throw Abort(.internalServerError, reason: "Failed to fetch API key from the environment.")
		}
		return apiKey
	}
	
	private static func getResponse(
		to chatCompReq: ChatCompletion.Request,
		model: ChatGPTModel,
		user: User,
		req: Request
	) async throws -> AISandboxServer.Output {
		
		let response: ClientResponse
		
		response = try await req.client.post(.init(string: ChatCompletion.endpointURL)) { req in
			try req.content.encode(chatCompReq, as: .json)
			req.headers.bearerAuthorization = .init(token: try getKey())
		}
		
		guard let body = response.body else { throw Abort(.failedDependency) }
		let data = Data(buffer: body)
		let text = String(decoding: data, as: UTF8.self)
		print("Response body (utf8-decoded):\n\(text)")
		
		let output: ChatCompletion.Response
		
		do {
			output = try JSONDecoder().decode(ChatCompletion.Response.self, from: body)
		} catch let error as DecodingError {
			req.logger.warning("###\(#function): Failed to decode JSON response body: \(error.localizedDescription)")
			throw Abort(.internalServerError, reason: "OpenAI response could not be decoded.")
		} catch {
			print("###\(#function): \(error.localizedDescription)")
			let badResponse = try JSONDecoder().decode(ChatCompletion.BadResponse.self, from: body)
			
			// Error message from API call is descriptive enough to be returned to the user.
			throw Abort(.badRequest, reason: badResponse.error.description)
		}
		
		return try await generateDataFromResponse(output, model: model, user: user, req: req)
	}
	
	private static func generateDataFromResponse(
		_ response: ChatCompletion.Response,
		model: ChatGPTModel,
		user: User,
		req: Request
	) async throws -> AISandboxServer.Output {
		
		let usage = response.usage
		let sendTokens = usage.promptTokens
		let receiveTokens = usage.completionTokens
		let costPerToken = model.tokens.costPerToken
		let sendCost = costPerToken.input * Double(sendTokens)
		let receiveCost = costPerToken.output * Double(receiveTokens)
		let totalCost = sendCost + receiveCost
		
		user.usedCredits = (user.usedCredits ?? 0) + totalCost
		
		do {
			try await user.save(on: req.db)
		} catch {
			throw ChatGPT.ServerError.database
		}
		let newBalance = await user.getBalance(req)
		
		let content = response.choices[0].message.content
		let message = ChatCompletion.Message(role: .assistant, content: content)
		return .init(message: message, cost: totalCost, newBalance: newBalance)
	}
	
	enum ServerError: Error {
		case database, noUser
		
		var description: String {
			switch self {
				case .database:
					return "dbError"
				case .noUser:
					return "noUser"
			}
		}
	}
}
