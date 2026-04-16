//
//  AppError.swift
//  vjr.
//
//  App-wide error type. All ViewModels catch into this type.
//  Expand cases here as new features are added.

import Foundation

enum AppError: LocalizedError {
    case network(String)
    case server(Int, String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .network(let msg):
            return "Network error: \(msg)"
        case .server(let code, let msg):
            return "Server error (\(code)): \(msg)"
        case .unknown:
            return "An unexpected error occurred."
        }
    }
}

extension AppError {
    /// Maps any thrown error into an `AppError`.
    static func from(_ error: Error) -> AppError {
        if let app = error as? AppError { return app }
        return .network(error.localizedDescription)
    }
}
