//
//  OpenAIClient.swift
//  Snap Macros
//
//  Created by Preston Speidel on 10/27/25.
//

import Foundation
import UIKit

enum OpenAIClientError: LocalizedError {
    case missingKey
    case badImage
    case http(status: Int, body: String)
    case emptyContent
    case jsonDecode(String)

    var errorDescription: String? {
        switch self {
        case .missingKey: return "Missing OpenAI API key."
        case .badImage: return "Could not encode image."
        case .http(let status, let body): return "Server error (\(status)). \(body)"
        case .emptyContent: return "No content returned by the model."
        case .jsonDecode(let msg): return "Could not read model output. \(msg)"
        }
    }
}

/// Tiny REST client to analyze a meal photo and return structured macros.
struct OpenAIClient {
    /// Cheapest vision-capable model with good accuracy/cost balance.
    /// You may switch to "gpt-4o" for more accuracy (higher cost).
    /// Docs: Chat Completions + Vision support.
    /// Pricing reference indicates **gpt-4o mini** is vision-enabled and low-cost.
    /// (See citations in the chat response.)
    var model: String = "gpt-4o-mini"

    /// *** Put your key here for class/testing ***
    private let apiKey: String = "apikey"

    /// Main API: send image, get MealEstimate
    func analyzeMeal(from image: UIImage) async throws -> MealEstimate {
        guard !apiKey.isEmpty && apiKey != "apikey" else { throw OpenAIClientError.missingKey }
        guard let jpeg = image.jpegData(compressionQuality: 0.7) else { throw OpenAIClientError.badImage }
        let b64 = jpeg.base64EncodedString()
        let dataURL = "data:image/jpeg;base64,\(b64)"

        // Ask for STRICT JSON we can decode
        let systemPrompt = """
        You are a nutrition estimator. Return STRICT JSON ONLY:
        {
          "title": string,
          "calories": int,
          "protein": int,
          "carbs": int,
          "fats": int,
          "items": [
            { "name": string, "grams": int, "calories": int, "protein": int, "carbs": int, "fats": int }
          ]
        }
        If uncertain, give best reasonable estimates. No extra text, no markdown.
        """

        let userPrompt = "Estimate macros for this meal photo. Return ONLY the JSON object."

        // Chat Completions with image_url content
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": userPrompt],
                        ["type": "image_url", "image_url": ["url": dataURL]]
                    ]
                ]
            ],
            "temperature": 0.2,
            "max_tokens": 600
        ]

        var req = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!,
                             cachePolicy: .reloadIgnoringLocalCacheData,
                             timeoutInterval: 60)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        // Basic request
        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw OpenAIClientError.http(status: http.statusCode, body: msg)
        }

        // Decode Chat Completions
        struct ChatResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable { let content: String }
                let message: Message
            }
            let choices: [Choice]
        }
        let chat = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = chat.choices.first?.message.content, !content.isEmpty else {
            throw OpenAIClientError.emptyContent
        }

        // Sometimes models wrap JSON in code fences; strip if present
        let jsonText = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        struct WireItem: Decodable {
            let name: String
            let grams: Int
            let calories: Int
            let protein: Int
            let carbs: Int
            let fats: Int
        }
        struct WireMeal: Decodable {
            let title: String
            let calories: Int
            let protein: Int
            let carbs: Int
            let fats: Int
            let items: [WireItem]
        }

        guard let jsonData = jsonText.data(using: .utf8) else {
            throw OpenAIClientError.jsonDecode("Empty JSON buffer.")
        }
        let wire: WireMeal
        do {
            wire = try JSONDecoder().decode(WireMeal.self, from: jsonData)
        } catch {
            throw OpenAIClientError.jsonDecode(error.localizedDescription)
        }

        let items: [DetectedItem] = wire.items.map {
            DetectedItem(name: $0.name, grams: $0.grams,
                         calories: $0.calories, protein: $0.protein, carbs: $0.carbs, fats: $0.fats)
        }

        return MealEstimate(
            title: wire.title,
            calories: wire.calories,
            protein: wire.protein,
            carbs: wire.carbs,
            fats: wire.fats,
            items: items,
            imageData: jpeg,
            timestamp: Date()
        )
    }
}
