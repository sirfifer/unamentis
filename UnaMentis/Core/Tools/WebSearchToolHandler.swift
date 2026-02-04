// UnaMentis - Web Search Tool Handler
// Tool handler for on-device LLM web search capability
//
// Registers a "web_search" tool that the LLM can call
// to search the web for current information.
//
// Part of Core/Tools

import Foundation
import Logging

// MARK: - Web Search Tool Arguments

/// Arguments for the web_search tool
private struct WebSearchArguments: Decodable {
    let query: String
    let num_results: Int?
}

// MARK: - Web Search Tool Handler

/// Tool handler that gives the on-device LLM web search capability
///
/// Usage:
/// 1. Configure with a WebSearchProvider (e.g., BraveSearchService)
/// 2. Register with ToolCallProcessor
/// 3. LLM can call "web_search" tool during conversations
public actor WebSearchToolHandler: ToolHandler {

    // MARK: - Properties

    private let logger = Logger(label: "com.unamentis.tools.websearch")

    /// The search provider
    private var searchProvider: (any WebSearchProvider)?

    /// Default number of results
    private let defaultResultCount: Int = 5

    /// Shared singleton
    public static let shared = WebSearchToolHandler()

    // MARK: - Initialization

    public init() {}

    // MARK: - Configuration

    /// Configure with a search provider
    public func configure(provider: any WebSearchProvider) {
        self.searchProvider = provider
        logger.info("WebSearchToolHandler configured with search provider")
    }

    // MARK: - ToolHandler Conformance

    /// Tool definition for the web_search tool
    public nonisolated var toolDefinitions: [LLMToolDefinition] {
        [WebSearchTools.webSearch]
    }

    /// Handle a web search tool call
    public func handle(_ toolCall: LLMToolCall) async throws -> LLMToolResult {
        switch toolCall.name {
        case "web_search":
            return await handleWebSearch(toolCall)
        default:
            throw ToolCallError.unknownTool(toolCall.name)
        }
    }

    // MARK: - Tool Implementation

    /// Handle the web_search tool call
    private func handleWebSearch(_ toolCall: LLMToolCall) async -> LLMToolResult {
        // Parse arguments
        let args: WebSearchArguments
        do {
            args = try toolCall.parseArguments()
        } catch {
            return .error(
                toolCallId: toolCall.id,
                error: "Invalid search arguments: \(error.localizedDescription)"
            )
        }

        // Check provider is configured
        guard let provider = searchProvider else {
            return .error(
                toolCallId: toolCall.id,
                error: "Web search not configured. Add a Brave Search API key in Settings."
            )
        }

        let resultCount = args.num_results ?? defaultResultCount

        logger.info("Web search: '\(args.query)' (max \(resultCount) results)")

        // Execute search
        do {
            let response = try await provider.search(
                query: args.query,
                maxResults: resultCount
            )

            return .success(
                toolCallId: toolCall.id,
                content: response.formattedForLLM
            )
        } catch {
            logger.error("Web search failed: \(error.localizedDescription)")

            return .error(
                toolCallId: toolCall.id,
                error: "Search failed: \(error.localizedDescription)"
            )
        }
    }
}

// MARK: - Tool Definitions

/// Static tool definitions for web search
private enum WebSearchTools {
    static let webSearch = LLMToolDefinition(
        name: "web_search",
        description: """
            Search the web for current information. Use this when the user asks about \
            recent events, facts you're unsure about, or anything that requires up-to-date \
            information. Returns titles, URLs, and descriptions of relevant web pages.
            """,
        inputSchema: ToolInputSchema(
            type: "object",
            properties: [
                "query": ToolProperty(
                    type: "string",
                    description: "The search query to look up on the web"
                ),
                "num_results": ToolProperty(
                    type: "integer",
                    description: "Number of results to return (1-10, default 5)"
                )
            ],
            required: ["query"]
        )
    )
}
