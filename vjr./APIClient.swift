//
//  APIClient.swift
//  vjr.
//
//  Single networking entry point. All API calls go through this singleton.
//  Base URL points to the local Vapor server (api/).

import Foundation

final class APIClient {
    static let shared = APIClient()
    private init() {}

    private let base = URL(string: "http://localhost:8080")!
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    // MARK: - GET

    func fetch<T: Decodable>(_ path: String, query: [String: String] = [:]) async throws -> T {
        let url = buildURL(path: path, query: query)
        let (data, response) = try await URLSession.shared.data(from: url)
        try validate(response, data: data)
        return try decoder.decode(T.self, from: data)
    }

    // MARK: - POST

    func post<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        var request = URLRequest(url: base.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response, data: data)
        return try decoder.decode(T.self, from: data)
    }

    // MARK: - Helpers

    private func buildURL(path: String, query: [String: String]) -> URL {
        var components = URLComponents(url: base.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        return components.url!
    }

    private func validate(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.httpError(statusCode: http.statusCode, message: message)
        }
    }
}

// MARK: - Errors

enum APIError: LocalizedError {
    case httpError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .httpError(let code, let message):
            return "HTTP \(code): \(message)"
        }
    }
}
