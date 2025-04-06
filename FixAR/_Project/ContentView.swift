//
//  ContentView.swift
//  _Project
//
//  Created by Shashwath Dinesh on 4/5/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @State private var isActive = false
    @State private var isLoading = false
    @State var problemDesc: String = ""
    @State var geminiResponse: String = ""
    @StateObject var cameraViewModel = CameraViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 220/255, green: 245/255, blue: 230/255)
                    .ignoresSafeArea()

                VStack(spacing: 30) {
                    Spacer()

                    Text("FixAR")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 30/255, green: 100/255, blue: 60/255))
                        .shadow(radius: 4)

                    Text("Instant object detection & repair guidance, powered by AR and AI.")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding(.horizontal)

                    Spacer()

                    TextField(
                        "What's the problem?",
                        text: $problemDesc
                    )
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 50/255, green: 140/255, blue: 90/255))
                        .cornerRadius(16)
                        .padding(.horizontal, 40)
                        .shadow(radius: 5)

                    Button(action: {
                        isLoading = true

                        let fullPrompt = """
                        You are a helpful AI technician specializing in hardware troubleshooting.

                        A user reported the following issue with their device:

                        \"\(problemDesc)\"

                        Based on this description, identify the key physical areas or components on the device that may be responsible and a list of those specific parts that may be the culprit.
                        
                        ONLY return a list of the specific problem parts.
                        """

                        GeminiManager.shared.sendPrompt(fullPrompt) { response in
                            DispatchQueue.main.async {
                                self.geminiResponse = response ?? "No response"
                                self.isLoading = false
                                self.isActive = true
                            }
                        }
                    }) {
                        Text(isLoading ? "Loading..." : "Submit")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(red: 50/255, green: 140/255, blue: 90/255))
                            .cornerRadius(16)
                            .padding(.horizontal, 40)
                            .shadow(radius: 5)
                    }

                    Spacer()

                    .navigationDestination(isPresented: $isActive) {
                        TransitionView(geminiResponse: geminiResponse, problemDesc: problemDesc, viewModel: cameraViewModel)
                    }
                    
                    NavigationLink(destination: GuideListView(viewModel: cameraViewModel)) {
                        Text("View My Guides")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(red: 30/255, green: 100/255, blue: 60/255))
                            .cornerRadius(16)
                            .padding(.horizontal, 40)
                            .shadow(radius: 5)
                    }
                }
            }
        }
    }
}


class GeminiManager {
    
    static let shared = GeminiManager()
    private let apiKey = "API-KEY"
    
    func sendPrompt(_ prompt: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(apiKey)") else {
            completion(nil)
            return
        }

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = json["candidates"] as? [[String: Any]],
                  let content = candidates.first?["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let text = parts.first?["text"] as? String else {
                completion(nil)
                return
            }

            completion(text)
        }.resume()
    }
    
    func getDetailedExplanation(originalProblem: String, part: String, completion: @escaping (String?) -> Void) {
        let prompt = """
        A user reported the following issue: "\(originalProblem)"
        
        They suspect the problem is with the \(part).
        
        Please provide a concise but thorough explanation of why this part might be causing the issue and how to fix it.
        """
        sendPrompt(prompt, completion: completion)
    }
}


#Preview {
    ContentView()
}
