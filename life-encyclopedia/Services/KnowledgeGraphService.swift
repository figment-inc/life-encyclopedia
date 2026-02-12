//
//  KnowledgeGraphService.swift
//  life-encyclopedia
//
//  Service for fetching entity data from the Google Knowledge Graph Search API.
//  Requires a Google API key (free, 500 requests/day).
//

import Foundation

// MARK: - Knowledge Graph Result

struct KnowledgeGraphResult {
    let name: String
    let entityTypes: [String]
    let shortDescription: String?
    let detailedDescription: String?
    let detailedDescriptionURL: String?
    let imageURL: String?
    let sources: [Source]
    let contextBlock: String

    static let empty = KnowledgeGraphResult(
        name: "",
        entityTypes: [],
        shortDescription: nil,
        detailedDescription: nil,
        detailedDescriptionURL: nil,
        imageURL: nil,
        sources: [],
        contextBlock: ""
    )

    var isEmpty: Bool { name.isEmpty }
}

// MARK: - Knowledge Graph Service

@Observable
final class KnowledgeGraphService {

    // MARK: - Errors

    enum KGError: LocalizedError {
        case missingAPIKey
        case invalidResponse
        case networkError(Error)
        case entityNotFound
        case notAPerson

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "Google API key is not configured"
            case .invalidResponse:
                return "Invalid response from Google Knowledge Graph"
            case .networkError(let error):
                return "Knowledge Graph network error: \(error.localizedDescription)"
            case .entityNotFound:
                return "Entity not found in Google Knowledge Graph"
            case .notAPerson:
                return "Knowledge Graph entity is not a person"
            }
        }
    }

    // MARK: - Person-related schema.org types

    private let personTypes: Set<String> = [
        "Person", "Thing"
    ]

    // MARK: - Public Methods

    /// Search for a person entity in the Google Knowledge Graph
    /// - Parameter name: The person's name to search
    /// - Returns: KnowledgeGraphResult with entity data and sources
    func searchEntity(name: String) async throws -> KnowledgeGraphResult {
        let apiKey = APIConfig.googleAPIKey
        guard !apiKey.isEmpty else {
            throw KGError.missingAPIKey
        }

        var components = URLComponents(string: "\(APIConfig.knowledgeGraphBaseURL)/entities:search")
        components?.queryItems = [
            URLQueryItem(name: "query", value: name),
            URLQueryItem(name: "types", value: "Person"),
            URLQueryItem(name: "languages", value: "en"),
            URLQueryItem(name: "limit", value: "3"),
            URLQueryItem(name: "key", value: apiKey)
        ]

        guard let url = components?.url else {
            throw KGError.invalidResponse
        }

        let (data, response) = try await performRequest(url: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw KGError.invalidResponse
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let itemListElement = json["itemListElement"] as? [[String: Any]] else {
            throw KGError.invalidResponse
        }

        if itemListElement.isEmpty {
            throw KGError.entityNotFound
        }

        // Find the best matching person entity
        guard let bestMatch = findBestPersonMatch(items: itemListElement, query: name) else {
            throw KGError.notAPerson
        }

        return bestMatch
    }

    // MARK: - Private Methods

    /// Find the best person match from Knowledge Graph results
    private func findBestPersonMatch(items: [[String: Any]], query: String) -> KnowledgeGraphResult? {
        let lowercasedQuery = query.lowercased()

        for item in items {
            guard let result = item["result"] as? [String: Any] else { continue }

            let entityName = result["name"] as? String ?? ""
            let types = result["@type"] as? [String] ?? []

            // Ensure this is a Person type
            guard types.contains("Person") else { continue }

            // Check name relevance
            let nameMatch = entityName.lowercased().contains(lowercasedQuery) ||
                            lowercasedQuery.contains(entityName.lowercased())

            // Allow partial match (last name match)
            let queryParts = lowercasedQuery.split(separator: " ")
            let entityParts = entityName.lowercased().split(separator: " ")
            let lastNameMatch = queryParts.last.map { entityParts.contains($0) } ?? false

            guard nameMatch || lastNameMatch else { continue }

            // Extract descriptions
            let shortDescription = result["description"] as? String
            var detailedDescription: String?
            var detailedDescriptionURL: String?

            if let detailedObj = result["detailedDescription"] as? [String: Any] {
                detailedDescription = detailedObj["articleBody"] as? String
                detailedDescriptionURL = detailedObj["url"] as? String
            }

            // Extract image
            let imageURL: String?
            if let imageObj = result["image"] as? [String: Any] {
                imageURL = imageObj["contentUrl"] as? String
            } else {
                imageURL = nil
            }

            // Build context block
            let contextBlock = buildContextBlock(
                name: entityName,
                types: types,
                shortDescription: shortDescription,
                detailedDescription: detailedDescription
            )

            // Build sources
            let sources = buildSources(
                name: entityName,
                detailedDescriptionURL: detailedDescriptionURL,
                shortDescription: shortDescription,
                detailedDescription: detailedDescription
            )

            return KnowledgeGraphResult(
                name: entityName,
                entityTypes: types,
                shortDescription: shortDescription,
                detailedDescription: detailedDescription,
                detailedDescriptionURL: detailedDescriptionURL,
                imageURL: imageURL,
                sources: sources,
                contextBlock: contextBlock
            )
        }

        return nil
    }

    /// Build a text context block for Claude consumption
    private func buildContextBlock(
        name: String,
        types: [String],
        shortDescription: String?,
        detailedDescription: String?
    ) -> String {
        var lines: [String] = []
        lines.append("ENTITY DATA (from Google Knowledge Graph):")
        lines.append("Name: \(name)")
        if !types.isEmpty { lines.append("Types: \(types.joined(separator: ", "))") }
        if let desc = shortDescription { lines.append("Description: \(desc)") }
        if let detailed = detailedDescription { lines.append("Detailed: \(detailed)") }
        return lines.joined(separator: "\n")
    }

    /// Create Source objects from Knowledge Graph results
    private func buildSources(
        name: String,
        detailedDescriptionURL: String?,
        shortDescription: String?,
        detailedDescription: String?
    ) -> [Source] {
        var sources: [Source] = []

        // Primary Knowledge Graph source
        let kgURL = detailedDescriptionURL ?? "https://www.google.com/search?kgmid=\(name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name)"
        let snippet = [shortDescription, detailedDescription]
            .compactMap { $0 }
            .joined(separator: "\n\n")

        sources.append(Source(
            title: "\(name) - Google Knowledge Graph",
            url: kgURL,
            sourceType: .knowledgeGraph,
            publisher: "Google Knowledge Graph",
            reliabilityScore: 0.88,
            contentSnippet: snippet.isEmpty ? nil : snippet,
            relevantQuote: detailedDescription,
            deepLinkURL: detailedDescriptionURL
        ))

        return sources
    }

    // MARK: - Network Helper

    private func performRequest(url: URL) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: url)
        request.timeoutInterval = 15

        do {
            return try await URLSession.shared.data(for: request)
        } catch {
            throw KGError.networkError(error)
        }
    }
}
