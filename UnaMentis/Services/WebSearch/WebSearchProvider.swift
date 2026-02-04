// UnaMentis - Web Search Provider Protocol
// Protocol for web search implementations
//
// Part of Services/WebSearch

import Foundation

// MARK: - Web Search Result

/// A single web search result
public struct WebSearchResult: Codable, Sendable {
    /// Title of the web page
    public let title: String

    /// URL of the result
    public let url: String

    /// Snippet/description of the result
    public let description: String

    public init(title: String, url: String, description: String) {
        self.title = title
        self.url = url
        self.description = description
    }

    /// Formatted string for LLM context
    public var formatted: String {
        "[\(title)](\(url))\n\(description)"
    }
}

// MARK: - Web Search Response

/// Response from a web search query
public struct WebSearchResponse: Sendable {
    /// The original query
    public let query: String

    /// Search results
    public let results: [WebSearchResult]

    /// Total number of results (may be more than returned)
    public let totalResults: Int?

    public init(query: String, results: [WebSearchResult], totalResults: Int? = nil) {
        self.query = query
        self.results = results
        self.totalResults = totalResults
    }

    /// Format all results for LLM consumption
    public var formattedForLLM: String {
        if results.isEmpty {
            return "No results found for: \(query)"
        }

        var output = "Search results for: \(query)\n\n"
        for (index, result) in results.enumerated() {
            output += "\(index + 1). \(result.title)\n"
            output += "   URL: \(result.url)\n"
            output += "   \(result.description)\n\n"
        }
        return output
    }
}

// MARK: - Web Search Provider Protocol

/// Protocol for web search service implementations
public protocol WebSearchProvider: Actor {
    /// Perform a web search
    /// - Parameters:
    ///   - query: Search query string
    ///   - maxResults: Maximum number of results to return
    /// - Returns: Search response with results
    func search(query: String, maxResults: Int) async throws -> WebSearchResponse
}

// MARK: - Web Search Errors

/// Errors that can occur during web search
public enum WebSearchError: Error, Sendable, LocalizedError {
    case apiKeyMissing
    case requestFailed(String)
    case invalidResponse
    case rateLimited
    case quotaExceeded

    public var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "Web search API key not configured"
        case .requestFailed(let message):
            return "Search request failed: \(message)"
        case .invalidResponse:
            return "Invalid response from search API"
        case .rateLimited:
            return "Search rate limit exceeded"
        case .quotaExceeded:
            return "Search quota exceeded"
        }
    }
}
