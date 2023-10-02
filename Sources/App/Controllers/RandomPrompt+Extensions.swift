//
//  File.swift
//  
//
//  Created by Devon Martin on 9/21/23.
//

import Foundation

extension ChatGPT {
	
	static func getRandomPrompt(about topic: String) -> String {
		
		let prompts = [
			"Write a short essay about \(topic).",
			"Tell me five fun facts about \(topic).",
			"Summarize \(topic).",
			"Create a fictional story that revolves around \(topic).",
			"Write a poem about \(topic).",
			"Explain \(topic) like I'm 5 years old.",
			"Explain the pros and cons of \(topic).",
			"Explain the importance of \(topic) in today's world.",
			"Describe the history and development of \(topic).",
			"Imagine a future where \(topic) plays a major role. What would it look like?",
			"How can we apply \(topic) to solve real-world problems?",
			"Analyze the impact of \(topic) on society and the environment.",
			"Discuss the ethical implications of \(topic).",
			"Explain the technological aspects of \(topic).",
			"What are the major challenges and opportunities with \(topic)?",
			"Discuss how \(topic) is affecting global politics.",
			"What does the future hold for \(topic)?",
			"Explain how \(topic) works and why it's important.",
			"What are some potential solutions related to \(topic)?",
			"What are the psychological aspects of \(topic)?",
			"Discuss the impact of \(topic) on the global economy.",
			"What are the latest advancements in \(topic)?",
			"Explain the scientific theory behind \(topic).",
			"How is \(topic) changing the world of healthcare?",
			"What are the philosophical implications of \(topic)?",
			"How does \(topic) influence our day-to-day life?",
			"Discuss the cultural significance of \(topic).",
			"What are the environmental impacts of \(topic)?",
			"How is \(topic) transforming modern education?",
			"Discuss the current trends and future prospects of \(topic).",
			"Explain the role of \(topic) in sustainable development.",
			"How is \(topic) influencing the dynamics of social interaction?",
			"Discuss the future implications of \(topic) in the realm of artificial intelligence.",
			"What is the potential of \(topic) as a future energy source?",
			"How is \(topic) affecting the mental health of the population?",
			"What is the global impact of \(topic) on climate change?",
			"How does \(topic) affect the structure of international relations?",
			"Discuss the application of \(topic) in space exploration."
		]
		
		return prompts.randomElement()!
	}
}
