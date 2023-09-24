//
//  File.swift
//  
//
//  Created by Devon Martin on 9/21/23.
//

import Foundation
import Vapor

class ChatGPT {
	
	private static var shared = ChatGPT()
	
	private var task: Task<String, Error>?
	
	enum APIError: Error, CaseIterable {
		case unknown, timeout, cancellationError
		
		var description: String {
			switch self {
				case .unknown:
					return "Something went wrong. Please try again."
				case .timeout:
					return "Your request timed out. Try again, or consider a different prompt."
				case .cancellationError:
					return "Your task was cancelled."
			}
		}
		
		static func isError(_ string: String) -> Bool {
			Self.allCases
				.map { $0.description }
				.contains(string)
		}
	}
	
	private init() {}
	
	
	// MARK: API
	
	/// This function sends a sequence of messages to the OpenAI GPT-3 API and retrieves a response.
	///
	/// This function acts as a wrapper around the API request process. It organizes the messages to send, generates the appropriate
	/// request object, and then sends the request. It also handles various potential errors from the API and returns informative error
	/// descriptions. An important feature of this function is the use of cancellation. If a new request is initiated while a previous one is
	/// still processing, the ongoing request is cancelled. This prevents confusion from multiple responses coming in at different times
	/// and ensures that the API only responds to the most recent set of messages.
	///
	/// - Throws: An `APIError` of type `cancellationError` if the function was cancelled before it could finish
	/// processing a request.
	///
	/// - Parameter messages: An array of `Message` objects that will be sent to the GPT-3 API. The array is empty by default.
	///
	/// - Returns: A `String` containing the content of the API's response, or a descriptive error message if the API request
	/// failed.
	///
	/// ```
	/// do {
	///     let response = try await sendMessages([message1, message2])
	///     print(response) // Prints the response from the API
	/// } catch {
	///     print(error.localizedDescription) // Prints "The operation was cancelled."
	/// }
	/// ```
	static func sendMessages(_ data: SendMessagesData) async throws -> String {
		
		let messages = generateMessagesArray(
			messages: data.messages,
			systemMessage: data.systemMessage
		)
		
		let request = await generateRequestObject(
			messages: messages,
			model: data.model,
			temperature: data.temperature,
			maxTokens: data.maxTokens
		)
		
		do {
			return try await getCancellableResponse(request: request)
		} catch let error as APIError {
			if error == .cancellationError {
				throw error
			} else {
				return error.description
			}
		} catch {
			return APIError.unknown.description
		}
	}
	
	static func getRandomPrompt(data: RandomPromptData) async -> String {
		
		let category = data.category
		
		let systemMessage = "Generate a random topic related to this category: \(category). Your topic should be related to \(category), but not the same thing as \(category). For example, if your category is food, you should return 'pineapple' or 'pasta'. Reply only with your random topic."
		
		let messages = [
			["role": "system", "content": systemMessage]
		]
		
		let request = await generateRequestObject(
			messages: messages,
			model: "gpt-3.5-turbo",
			temperature: 0.8
		)
		
		do {
			let topic = try await getResponse(request: request)
				.lowercased()
				.trimmingCharacters(in: .punctuationCharacters)
				.trimmingCharacters(in: .whitespacesAndNewlines)
			
			let prompt = getRandomPrompt(about: topic)
			
			return try await correctGrammar(for: prompt)
		} catch {
			return getRandomPrompt()
		}
	}
	
	static func getTitle(for messages: [Message]) async throws -> String {
		
		let systemMessage = """
   Generate a title for the following conversation. Keep it to four words or less. Respond with ONLY the title with no extra formatting.
   Ensure the following criteria is met:
   -No additional comments, return just the title itself
   -Be concise but creative
   -Do NOT include "Title:" in your response
  """
		
		let messagesArray = generateMessagesArray(messages: messages, systemMessage: systemMessage)
		let request = await generateRequestObject(
			messages: messagesArray, 
			model: "gpt-3.5-turbo",
			temperature: 0.7
		)
		
		do {
			let title = try await getCancellableResponse(request: request)
			return title
				.replacingOccurrences(of: "Title: ", with: "")
				.trimmingCharacters(in: .whitespacesAndNewlines)
				.trimmingCharacters(in: .punctuationCharacters)
				.trimmingCharacters(in: ["\""])
		} catch let error as APIError {
			if error == .cancellationError {
				throw error
			}
		} catch {
			throw APIError.unknown
		}
		return "Error generating title."
	}
	
	
	// MARK: Helper Functions
	
	private static func getNewRequest() async -> URLRequest {
		let url = URL(string: "https://api.openai.com/v1/chat/completions")!
		var request = URLRequest(url: url)
		
		guard let apiKey = Environment.get("API_KEY") else {
			fatalError("API key not accessible from the environment.")
		}
		
		request.httpMethod = "POST"
		request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		return request
	}
	
	private static func correctGrammar(for prompt: String) async throws -> String {
		
		let systemMessage = "Correct the grammar in the following sentence, and rewrite anything from it that does not make sense so that it makes sense. Sentence: \n\n'\(prompt)'\n\n Please response only with the fixed sentence. For example, if the sentence is 'hello, World!', your response should be 'Hello, world!'"
		
		let messages = [
			["role": "system", "content": systemMessage]
		]
		
		let request = await generateRequestObject(
			messages: messages,
			model: "gpt-3.5-turbo",
			temperature: 0.2
		)
		
		return try await getResponse(request: request)
	}
	
	private static func generateRequestObject(
		messages: [Dictionary<String, String>],
		model: String,
		temperature: Double,
		maxTokens: Int? = nil
	) async -> URLRequest {
		var request = await getNewRequest()
		
		var requestBody: [String: Any] = [
			"model": model,
			"messages": messages,
			"temperature": temperature
		]
		
		if let maxTokens {
			requestBody["max_tokens"] = maxTokens
		}
		
		request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
		return request
	}
	
	private static func generateMessagesArray(
		messages: [Message],
		systemMessage: String
	) -> Array<Dictionary<String, String>> {
		
		var messagesArray = [
			["role": "system", "content": systemMessage]
		]
		
		for message in messages {
			let role = message.sentByUser ? "user" : "assistant"
			messagesArray.append(["role": role, "content": message.content])
		}
		
		return messagesArray
	}
	
	private static func getCancellableResponse(request: URLRequest) async throws -> String {
		
		shared.task?.cancel()
		
		shared.task = Task {
			try await getResponse(request: request)
		}
		
		return try await shared.task!.value
	}
	
	private static func getResponse(request: URLRequest) async throws -> String {
		
		let session = URLSession.shared
		
		let data: Data
		let response: URLResponse
		do {
			(data, response) = try await session.data(for: request)
		} catch { // This occurs after so many attempts at removing a message and resending the
				  // request to combat error.code "context_length_exceeded." I don't know why this
				  // catches, but simply recursively calling the method again works.
			if error.localizedDescription == "The operation couldn’t be completed. Message too long" {
				return try await getResponse(request: request)
				// This occurs if the server can't respond quickly enough. The prompt can impact
				// this. For example, I found this error from the following prompt: "Hello. This
				// is a test. Please write me a very, very long response. Like, the length of an
				// essay." This prompt consistently results in a timeout.
			} else if error.localizedDescription == "The request timed out." {
				throw APIError.timeout
			} else if error.localizedDescription == "cancelled" {
				throw APIError.cancellationError
			} else {
				throw APIError.unknown
			}
		}
		
		let httpResponse = response as! HTTPURLResponse
		
		// 429 means "Too Many Requests." Requests reset after 20s. Cause 2.5s delay and try again.
		// Only applicable to free-tier API. Paid API has practically unlimited requests.
		guard httpResponse.statusCode != 429 else {
			try await Task.sleep(for: .seconds(2.5))
			return try await self.getResponse(request: request)
		}
		
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		
		do {
			let decodedResponses = try decoder.decode(ChatCompletion.self, from: data)
			let response = decodedResponses.choices[0]
			return response.message.content.trimmingCharacters(in: ["\n", " "])
			
		} catch {
			let error = try decoder.decode(ResponseError.self, from: data).error
			
			print("###\(#function): \(error)")
			
			// If context_length_exceeded, remove the first message other than the system message
			// and try again.
			if error.code == "context_length_exceeded" {
				
				let httpBody = try JSONSerialization.jsonObject(
					with: request.httpBody!
				) as! [String: Any]
				var messages = httpBody["messages"] as! [Dictionary<String, String>]
				if messages.count > 2 {
					messages.remove(at: 1)
					let model = httpBody["model"] as! String
					let temperature = httpBody["temperature"] as! Double
					let maxTokens = httpBody["maxTokens"] as? Int
					let request = await generateRequestObject(
						messages: messages,
						model: model,
						temperature: temperature,
						maxTokens: maxTokens
					)
					return try await getResponse(request: request)
				} else {
					// Error message from API call is descriptive enough to be returned to the
					// user if a message cannot be removed to try again.
					return error.message
				}
			}
		}
		throw APIError.unknown // Something went wrong that I haven't thought of or discovered yet.
	}
}
