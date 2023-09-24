@testable import App
import XCTVapor

final class AppTests: XCTestCase {
    func testHelloWorld() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)

        try app.test(.GET, "hello") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "Hello, world!")
        }
    }
	
	func testSendMessages() async throws {
		let app = Application(.testing)
		defer { app.shutdown() }
		try await configure(app)
		
//		let data: SendMessagesData = .init(
//			systemMessage: "Respond only \"test\"",
//			messages: [
//				.init(content: "Hello!", sentByUser: true, timestamp: Date.now)
//			],
//			model: "gpt-3.5-turbo",
//			maxTokens: nil,
//			temperature: 0.2
//		 )
		
		try app.test(.POST, "api/sendMessages") { res in
			
		}
	}
	
	func testTest() async throws {
		let app = Application(.testing)
		defer { app.shutdown() }
		try await configure(app)
		
		
	}
}
