//
//  FilterEnrichmentService.swift
//  life-encyclopedia
//
//  Service for AI-enriching person data with filter metadata using Claude
//

import Foundation

@Observable
final class FilterEnrichmentService {
    
    // MARK: - Errors
    
    enum EnrichmentError: LocalizedError {
        case invalidURL
        case invalidResponse
        case networkError(Error)
        case decodingError(Error)
        case apiError(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL configuration"
            case .invalidResponse:
                return "Invalid response from AI service"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .decodingError(let error):
                return "Failed to parse response: \(error.localizedDescription)"
            case .apiError(let message):
                return "API error: \(message)"
            }
        }
    }
    
    // MARK: - Response Models
    
    private struct ClaudeResponse: Codable {
        let content: [ContentBlock]
        
        struct ContentBlock: Codable {
            let type: String
            let text: String?
        }
    }
    
    private struct EnrichmentResponse: Codable {
        // Core Identity
        let birthYear: Int?
        let deathYear: Int?
        let birthplace: BirthplaceResponse?
        let nationality: [String]?
        let culturalRegion: String?
        let century: Int?
        let historicalPeriod: String?
        
        // Domain of Impact
        let primaryDomain: String?
        let secondaryDomains: [String]?
        let subRole: String?
        
        // Type of Influence (scored 0-5)
        let influenceModes: [String: Int]?
        
        // Scale & Reach
        let geographicReach: String?
        let influenceLongevity: String?
        let recognitionLevel: String?
        
        // Narrative
        let archetype: String?
        let moralValence: String?
        let lifeArc: String?
        
        struct BirthplaceResponse: Codable {
            let city: String?
            let country: String?
            let continent: String?
        }
    }
    
    // MARK: - Public Methods
    
    /// Enrich a person with filter metadata using Claude AI
    /// - Parameters:
    ///   - person: The person to enrich
    ///   - additionalContext: Optional additional context from search results
    /// - Returns: FilterMetadata populated by AI analysis
    func enrichPerson(_ person: Person, additionalContext: String? = nil) async throws -> FilterMetadata {
        guard let url = URL(string: "\(APIConfig.anthropicBaseURL)/messages") else {
            throw EnrichmentError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(APIConfig.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let systemPrompt = buildSystemPrompt()
        let userMessage = buildUserMessage(for: person, additionalContext: additionalContext)
        
        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 2048,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": userMessage]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw EnrichmentError.invalidResponse
            }
            
            if httpResponse.statusCode != 200 {
                if let errorText = String(data: data, encoding: .utf8) {
                    throw EnrichmentError.apiError(errorText)
                }
                throw EnrichmentError.invalidResponse
            }
            
            let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)
            
            guard let textContent = claudeResponse.content.first(where: { $0.type == "text" }),
                  let jsonText = textContent.text else {
                throw EnrichmentError.invalidResponse
            }
            
            let cleanedJSON = extractJSON(from: jsonText)
            
            guard let jsonData = cleanedJSON.data(using: .utf8) else {
                throw EnrichmentError.decodingError(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON text"]))
            }
            
            let enrichmentResponse = try JSONDecoder().decode(EnrichmentResponse.self, from: jsonData)
            
            return convertToFilterMetadata(enrichmentResponse)
            
        } catch let error as EnrichmentError {
            throw error
        } catch let error as DecodingError {
            throw EnrichmentError.decodingError(error)
        } catch {
            throw EnrichmentError.networkError(error)
        }
    }
    
    // MARK: - Private Helpers
    
    private func buildSystemPrompt() -> String {
        """
        You are a historian and classifier analyzing historical figures. Your task is to categorize a person across multiple dimensions for a searchable encyclopedia.
        
        RESPOND ONLY WITH VALID JSON. No additional text before or after.
        
        Classification schema:
        
        {
            "birthYear": <integer or null>,
            "deathYear": <integer or null if living>,
            "birthplace": {
                "city": "<string or null>",
                "country": "<string or null>",
                "continent": "<string or null>"
            },
            "nationality": ["<country1>", "<country2>"],
            "culturalRegion": "<one of: westernEurope, easternEurope, northAmerica, latinAmerica, eastAsia, southAsia, southeastAsia, middleEast, northAfrica, subSaharanAfrica, oceania, centralAsia>",
            "century": <integer, e.g., 19 for 1800s, 20 for 1900s>,
            "historicalPeriod": "<one of: ancientWorld, medieval, renaissance, enlightenment, industrial, modernEra, coldWar, digitalAge>",
            
            "primaryDomain": "<one of: politics, science, business, arts, philosophy, military, religion, sports, entertainment, activism, technology>",
            "secondaryDomains": ["<domain1>", "<domain2>"],
            "subRole": "<specific role, e.g., 'theoretical physicist', 'novelist', 'head of state'>",
            
            "influenceModes": {
                "intellectual": <0-5>,
                "institutional": <0-5>,
                "cultural": <0-5>,
                "technological": <0-5>,
                "political": <0-5>,
                "military": <0-5>,
                "symbolic": <0-5>
            },
            
            "geographicReach": "<one of: local, national, regional, global>",
            "influenceLongevity": "<one of: shortLived, generational, multiCentury, ongoing>",
            "recognitionLevel": "<one of: obscure, fieldFamous, publiclyFamous, canonical>",
            
            "archetype": "<one of: founder, reformer, rebel, tyrant, visionary, martyr, polymath, operator, tragicFigure>",
            "moralValence": "<one of: widelyAdmired, contested, widelyCondemned>",
            "lifeArc": "<one of: steadyAscent, lateBlocker, riseAndFall, posthumousRecognition, unfulfilledPotential>"
        }
        
        INFLUENCE MODE SCORING (0-5):
        0 = Not applicable
        1 = Minor influence
        2 = Moderate influence
        3 = Significant influence
        4 = Major influence
        5 = Defining/Revolutionary influence
        
        Be accurate and nuanced. A scientist can also have cultural influence. A politician can be a polymath. Consider the full picture.
        """
    }
    
    private func buildUserMessage(for person: Person, additionalContext: String?) -> String {
        var message = """
        Classify this historical figure:
        
        Name: \(person.name)
        Birth: \(person.birthDate ?? "Unknown")
        Death: \(person.deathDate ?? "Living/Unknown")
        
        Summary: \(person.summary)
        
        """
        
        // Add key life events for context
        if !person.events.isEmpty {
            message += "\nKey Life Events:\n"
            for event in person.events.prefix(10) {
                message += "- \(event.date): \(event.title)\n"
            }
        }
        
        if let context = additionalContext, !context.isEmpty {
            message += "\nAdditional Context:\n\(context)"
        }
        
        return message
    }
    
    private func extractJSON(from text: String) -> String {
        var content = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove markdown code fences
        if content.hasPrefix("```") {
            if let firstNewline = content.firstIndex(of: "\n") {
                content = String(content[content.index(after: firstNewline)...])
            } else {
                content = String(content.dropFirst(3))
            }
        }
        
        if content.hasSuffix("```") {
            content = String(content.dropLast(3))
        }
        
        content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Find JSON object
        if !content.hasPrefix("{") {
            if let startIndex = content.firstIndex(of: "{"),
               let endIndex = content.lastIndex(of: "}") {
                content = String(content[startIndex...endIndex])
            }
        }
        
        return content
    }
    
    private func convertToFilterMetadata(_ response: EnrichmentResponse) -> FilterMetadata {
        // Convert string values to enums
        let culturalRegion = response.culturalRegion.flatMap { CulturalRegion(rawValue: $0) }
        let historicalPeriod = response.historicalPeriod.flatMap { HistoricalPeriod(rawValue: $0) }
        let primaryDomain = response.primaryDomain.flatMap { Domain(rawValue: $0) }
        let secondaryDomains = (response.secondaryDomains ?? []).compactMap { Domain(rawValue: $0) }
        let geographicReach = response.geographicReach.flatMap { GeographicReach(rawValue: $0) }
        let influenceLongevity = response.influenceLongevity.flatMap { InfluenceLongevity(rawValue: $0) }
        let recognitionLevel = response.recognitionLevel.flatMap { RecognitionLevel(rawValue: $0) }
        let archetype = response.archetype.flatMap { Archetype(rawValue: $0) }
        let moralValence = response.moralValence.flatMap { MoralValence(rawValue: $0) }
        let lifeArc = response.lifeArc.flatMap { LifeArc(rawValue: $0) }
        
        // Convert birthplace
        var birthplace: Birthplace?
        if let bp = response.birthplace {
            birthplace = Birthplace(
                city: bp.city,
                country: bp.country,
                continent: bp.continent
            )
        }
        
        return FilterMetadata(
            birthYear: response.birthYear,
            deathYear: response.deathYear,
            birthplace: birthplace,
            nationality: response.nationality ?? [],
            culturalRegion: culturalRegion,
            century: response.century,
            historicalPeriod: historicalPeriod,
            primaryDomain: primaryDomain,
            secondaryDomains: secondaryDomains,
            subRole: response.subRole,
            influenceModes: response.influenceModes ?? [:],
            geographicReach: geographicReach,
            influenceLongevity: influenceLongevity,
            recognitionLevel: recognitionLevel,
            archetype: archetype,
            moralValence: moralValence,
            lifeArc: lifeArc
        )
    }
}
