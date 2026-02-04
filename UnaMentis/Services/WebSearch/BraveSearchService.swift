// UnaMentis - Brave Search Service
// Web search implementation using Brave Search API
//
// Brave Search offers 2000 free queries/month
// API docs: https://api.search.brave.com/app/documentation/web-search
//
// Part of Services/WebSearch

import Foundation
import Logging

// MARK: - Brave Search Service

/// Web search service using the Brave Search API
///
/// Features:
/// - 2000 free queries/month
/// - No tracking
/// - Independent index
public actor BraveSearchService: WebSearchProvider {

    // MARK: - Properties

    private let logger = Logger(label: "com.unamentis.websearch.brave")
    private let apiKey: String
    private let baseURL = "https://api.search.brave.com/res/v1/web/search"
    private let session: URLSession

    // MARK: - Initialization

    /// Initialize with Brave Search API key
    /// - Parameter apiKey: Brave Search API key
    public init(apiKey: String) {
        self.apiKey = apiKey

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 15
        self.session = URLSession(configuration: config)

        logger.info("BraveSearchService initialized")
    }

    // MARK: - WebSearchProvider

    /// Perform a web search using Brave Search API
    public func search(query: String, maxResults: Int = 5) async throws -> WebSearchResponse {
        guard !apiKey.isEmpty else {
            throw WebSearchError.apiKeyMissing
        }

        // Build URL with query parameters
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "count", value: String(min(maxResults, 20)))
        ]

        guard let url = components?.url else {
            throw WebSearchError.requestFailed("Invalid URL")
        }

        // Build request
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-Subscription-Token")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        logger.debug("Searching Brave: '\(query)' (max \(maxResults) results)")

        // Execute request
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw WebSearchError.requestFailed(error.localizedDescription)
        }

        // Check HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WebSearchError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            break // Success
        case 429:
            throw WebSearchError.rateLimited
        case 402:
            throw WebSearchError.quotaExceeded
        default:
            throw WebSearchError.requestFailed("HTTP \(httpResponse.statusCode)")
        }

        // Parse response
        let searchResponse = try parseResponse(data: data, query: query)

        logger.info("Brave search returned \(searchResponse.results.count) results for '\(query)'")

        return searchResponse
    }

    // MARK: - Response Parsing

    /// Parse Brave Search API response
    private func parseResponse(data: Data, query: String) throws -> WebSearchResponse {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw WebSearchError.invalidResponse
        }

        var results: [WebSearchResult] = []

        // Parse web results
        if let web = json["web"] as? [String: Any],
           let webResults = web["results"] as? [[String: Any]] {
            for item in webResults {
                guard let title = item["title"] as? String,
                      let url = item["url"] as? String else {
                    continue
                }

                let description = item["description"] as? String ?? ""

                results.append(WebSearchResult(
                    title: title,
                    url: url,
                    description: description
                ))
            }
        }

        let totalCount = (json["web"] as? [String: Any])?["totalResults"] as? Int

        return WebSearchResponse(
            query: query,
            results: results,
            totalResults: totalCount
        )
    }
}
