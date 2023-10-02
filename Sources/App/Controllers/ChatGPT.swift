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
import Tiktoken

class ChatGPT {
	
	private init() {}
	
	// MARK: - API
	
	static func sendMessages(_ req: Request) async throws -> SendMessagesOutput {
		guard let data = try? req.content.decode(SendMessagesInput.self) else {
			throw Abort(.badRequest)
		}
		
		let messages = generateMessagesArray(
			systemMessage: data.systemMessage,
			messages: data.messages
		)
		
		let chatRequestData = try await generateRequestData(
			messages: messages,
			data: data,
			req: req
		)
		
		do {
			return try await getResponse(to: chatRequestData, req: req)
		} catch let error as ChatGPT.error {
			return .init(
				message: nil,
				cost: nil,
				newBalance: nil,
				error: error.localizedDescription
			)
		} catch {
			return .init(
				message: nil,
				cost: nil,
				newBalance: nil,
				error: ChatGPT.error.unknown.description
			)
		}
	}
	
	static func getRandomPrompt(_ req: Request) async throws -> SimpleRequestOutput {
		guard let data = try? req.content.decode(RandomPromptInput.self) else {
			throw Abort(.badRequest)
		}
		
		let verifyFundsData = VerifyFundsData(
			userID: data.userID,
			temperature: 0.8
		)
		let category = data.category
		
		let systemMessage = "Generate a random topic related to this category: \(category). Your topic should be related to \(category), but not the same thing as \(category). For example, if your category is food, you should return 'pineapple' or 'pasta'. Reply only with your random topic."
		
		let messages = [ChatRequestMessageData(role: .system, content: systemMessage)]
		let chatRequestData = try await generateRequestData(
			messages: messages,
			data: verifyFundsData,
			req: req
		)
		
		let promptResponse = try await getResponse(to: chatRequestData, req: req)
		
		guard var topic = promptResponse.message?.content else {
			throw Abort(.failedDependency)
		}
			
		topic = topic
			.lowercased()
			.trimmingCharacters(in: .punctuationCharacters)
			.trimmingCharacters(in: .whitespacesAndNewlines)
			
		let prompt = getRandomPrompt(about: topic)
		let correctedPromptResponse = try await correctGrammar(
			for: prompt,
			userID: data.userID,
			req: req
		)
		
		guard let correctedPrompt = correctedPromptResponse.message?.content,
			  let balance = correctedPromptResponse.newBalance
		else {
			throw Abort(.failedDependency)
		}
		
		return .init(content: correctedPrompt, newBalance: balance)
	}
	
	static func getTitle(_ req: Request) async throws -> SimpleRequestOutput {
		guard let data = try? req.content.decode(TitleInput.self) else { throw Abort(.badRequest) }
		
		let systemMessage = """
	 Generate a title for the following conversation. Keep it to four words or less. Respond with ONLY the title with no extra formatting.
	 Ensure the following criteria is met:
	 - No additional comments, return just the title itself
	 - Be concise but creative
	 - Prefer shorter words
	 - Do NOT include "Title:" in your response
	"""
		
		let messages = generateMessagesArray(systemMessage: systemMessage, messages: data.messages)
		let verifyFundsData = VerifyFundsData(
			userID: data.userID,
			temperature: 0.7
		)
		
		let chatRequestData = try await generateRequestData(
			messages: messages,
			data: verifyFundsData,
			req: req
		)
		
		let titleResponse: SendMessagesOutput
		
		do {
			titleResponse = try await getResponse(to: chatRequestData, req: req)
		} catch {
			throw ChatGPT.error.unknown
		}
		
		guard var title = titleResponse.message?.content,
			  let balance = titleResponse.newBalance else {
			throw Abort(.failedDependency)
		}
		title = title
			.replacingOccurrences(of: "Title: ", with: "")
			.trimmingCharacters(in: .whitespacesAndNewlines)
			.trimmingCharacters(in: .punctuationCharacters)
			.trimmingCharacters(in: ["\""])
		
		return .init(content: title, newBalance: balance)
	}
	
	static func getAvailableModels(_ req: Request) async throws -> [ModelListResponse.Model] {
		guard let apiKey = Environment.get("API_KEY") else {
			throw Abort(.internalServerError, reason: "Failed to fetch API key from the environment.")
		}
		
		let uri: URI = "https://api.openai.com/v1/models"
		
		let response = try? await req.client.get(uri) { req in
			req.headers.bearerAuthorization = .init(token: apiKey)
		}
		
		guard let body = response?.body else {
			throw Abort(.badGateway, reason: "Failed to fetch data from OpenAI.")
		}
		
		let decoder = JSONDecoder()
		
		guard let modelList = try? decoder.decode(ModelListResponse.self, from: body) else {
			throw Abort(.internalServerError, reason: "Failed to convert Model data.")
		}
		
		return modelList.data.filter {
			$0.id.contains("gpt") &&
			!$0.id.contains("instruct")
		}
	}
	
	
	// MARK: - Helper Functions
	
	private static func generateRequestData(
		messages: [ChatRequestMessageData],
		data: any VerifyFundsDataProtocol,
		req: Request
	) async throws -> ChatRequestData {
		guard let user = try? await User.find(data.userID, on: req.db) else {
			print("No user with provided ID found: \(data.userID)")
			throw self.error.noUser
		}
		
		let balance = await user.getBalance(req)
		let model = GPTModel(model: data.model)
		
		let maxInputCost = min(balance, model.maxInputExpense)
		
		let maxOutputTokens: Int? = if data.responseBudget > model.maxOutputExpense * 0.75 { nil }
		else { Int(floor(data.responseBudget / model.costPerToken.output)) }
		
		let inputBudget: Double = if maxOutputTokens != nil {
			maxInputCost - data.responseBudget
		} else {
			maxInputCost
		}
		
		var messages = messages
		
		let minimumMessages = min(2, messages.count)
		
		while await messages.inputCost(with: model) > inputBudget
				&& messages.count >= minimumMessages {
			messages.remove(at: 1)
		}
		
		guard messages.count >= minimumMessages else { throw Abort(.paymentRequired) }
		
		return ChatRequestData(
			model: data.model,
			messages: messages,
			temperature: data.temperature,
			max_tokens: maxOutputTokens == 0 ? nil : maxOutputTokens,
			user: data.userID
		)
	}
	
	private static func correctGrammar(
		for prompt: String,
		userID: String,
		req: Request
	) async throws -> SendMessagesOutput {
		
		let systemMessage = "Correct the grammar in the following sentence, and rewrite anything from it that does not make sense so that it makes sense. Sentence: \n\n'\(prompt)'\n\n Please response only with the fixed sentence. For example, if the sentence is 'hello, World!', your response should be 'Hello, world!'"
		
		let messages = [ChatRequestMessageData(role: .system, content: systemMessage)]
		
		let verifyFundsData = VerifyFundsData(
			userID: userID,
			model: GPTModel.Base.gpt3.rawValue,
			responseBudget: 0,
			temperature: 0.2)
		
		let chatRequestData = try await generateRequestData(
			messages: messages,
			data: verifyFundsData,
			req: req
		)
		
		return try await getResponse(to: chatRequestData, req: req)
	}
	
	private static func generateMessagesArray(
		systemMessage: String,
		messages: [Message]
	) -> [ChatRequestMessageData] {
		[.init(role: .system, content: systemMessage)] + messages.map { message in
				.init(role: message.sentByUser ? .user : .assistant, content: message.content)
		}
	}
	
	private static func getResponse(
		to chatRequestData: ChatRequestData,
		req: Request
	) async throws -> SendMessagesOutput {
		guard let apiKey = Environment.get("API_KEY") else {
			throw Abort(.internalServerError, reason: "Failed to fetch API key from the environment.")
		}
		let uri: URI = "https://api.openai.com/v1/chat/completions"
		let response: ClientResponse
		
		do {
			response = try await req.client.post(uri) { req in
				try req.content.encode(chatRequestData, as: .json)
				req.headers.bearerAuthorization = .init(token: apiKey)
			}
		} catch {
				
			// This occurs if the server can't respond quickly enough. The prompt can impact
			// this. For example, I found this error from the following prompt: "Hello. This
			// is a test. Please write me a very, very long response. Like, the length of an
			// essay." This prompt consistently results in a timeout.
			if error.localizedDescription == "The request timed out." {
				throw ChatGPT.error.timeout
			} else {
				print(error.localizedDescription)
				throw ChatGPT.error.unknown
			}
		}
		
		guard let body = response.body else { throw Abort(.failedDependency) }
		
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		
		let receivedData: ChatCompletion
		
		do {
			receivedData = try decoder.decode(ChatCompletion.self, from: body)
		} catch {
			print("###\(#function): \(error.localizedDescription)")
			let error = try decoder.decode(ResponseError.self, from: body).error
			
			// Error message from API call is descriptive enough to be returned to the user.
			return .init(message: nil, cost: nil, newBalance: nil, error: error.message)
		}
		
		return await generateDataFromResponse(receivedData, requestData: chatRequestData, req: req)
	}
	
	private static func generateDataFromResponse(
		_ response: ChatCompletion,
		requestData: ChatRequestData,
		req: Request
	) async -> SendMessagesOutput {
		
		let usage = response.usage
		let sendTokens = usage.promptTokens
		let receiveTokens = usage.completionTokens
		let model = GPTModel(model: requestData.model)
		let costPerToken = model.costPerToken
		let sendCost = costPerToken.input * Double(sendTokens)
		let receiveCost = costPerToken.output * Double(receiveTokens)
		let totalCost = sendCost + receiveCost
		
		let userID = requestData.user
		
		var balance: Double?
		
		if let user = try? await User.find(userID, on: req.db) {
			user.usedCredits = (user.usedCredits ?? 0) + totalCost
			
			do {
				try await user.save(on: req.db)
			} catch {
				return .init(
					message: nil,
					cost: nil,
					newBalance: nil,
					error: ChatGPT.error.database.localizedDescription
				)
			}
			balance = await user.getBalance(req)
		}
		
		let choice = response.choices[0]
		let content = choice.message.content.trimmingCharacters(in: ["\n", " "])
		
		return .init(
			message: Message(content: content, sentByUser: false, timestamp: Date.now.timeIntervalSince1970),
			cost: totalCost,
			newBalance: balance,
			error: nil
		)
	}
	
	enum error: Error, CaseIterable {
		case unknown, timeout, database, noUser
		
		var description: String {
			switch self {
				case .unknown:
					return "Something went wrong. Please try again."
				case .timeout:
					return "Your request timed out. Try again, or consider a different prompt."
				case .database:
					return "Unable to process your request due to an internal database error."
				case .noUser:
					return "No user found with the provided ID. Please log out and back in."
			}
		}
		
		static func isError(_ string: String) -> Bool {
			Self.allCases
				.map { $0.description }
				.contains(string)
		}
	}
}

// MARK: - Available Models

extension ChatGPT {
	
	struct ModelListResponse: Decodable {
		var data: [Model]
		
		struct Model: Content {
			let id: String
		}
	}
}
