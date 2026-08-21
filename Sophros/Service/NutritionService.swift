//
//  NutritionService.swift
//  Sophros
//
//  Created by Sohan Maurya on 19/08/26.
//


import Foundation

enum NutritionAPIService {
    private static let endpoint = URL(
        string: "https://sophros-nutrition-api.sophros.workers.dev"
    )!

    static func fetch(query: String) async throws -> NutritionResponse {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
        request.httpBody = try JSONEncoder().encode(
            ["query": query]
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard 200...299 ~= httpResponse.statusCode else {
            throw NutritionServiceError.requestFailed(
                statusCode: httpResponse.statusCode
            )
        }

        return try JSONDecoder().decode(
            NutritionResponse.self,
            from: data
        )
    }
}

enum NutritionServiceError: LocalizedError {
    case requestFailed(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .requestFailed(let statusCode):
            return "Nutrition lookup failed. Please try again. (\(statusCode))"
        }
    }
}
