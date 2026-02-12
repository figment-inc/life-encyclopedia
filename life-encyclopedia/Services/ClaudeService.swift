//
//  ClaudeService.swift
//  life-encyclopedia
//
//  Service for generating historical events using Claude API
//

import Foundation

@Observable
final class ClaudeService {
    
    // MARK: - Errors
    
    enum ClaudeError: LocalizedError {
        case invalidURL
        case invalidResponse
        case networkError(Error)
        case decodingError(Error)
        case apiError(String)
        case fictionalCharacter
        
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
            case .fictionalCharacter:
                return "This appears to be a fictional character. Please search for a real historical person."
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
    
    private struct GeneratedPerson: Codable {
        let isFictional: Bool?
        let name: String?
        let birthDate: String?
        let deathDate: String?
        let summary: String?
        let events: [GeneratedEvent]?
        
        struct GeneratedEvent: Codable {
            let date: String
            let title: String
            let description: String
            let citation: String?
            let sourceURL: String?
            // Enhanced fields
            let eventType: String?
            let datePrecision: String?
            let sources: [GeneratedSource]?
        }
        
        struct GeneratedSource: Codable {
            let title: String
            let url: String
            let type: String?
            let relevantQuote: String?
            let deepLinkHint: String?
        }
    }
    
    // MARK: - Public Methods
    
    /// Generate historical events for a verified person
    /// - Parameters:
    ///   - name: The person's name
    ///   - context: Additional context from Tavily search
    /// - Returns: A Person object with generated events
    func generateHistoricalEvents(name: String, context: String) async throws -> Person {
        guard let url = URL(string: "\(APIConfig.anthropicBaseURL)/messages") else {
            throw ClaudeError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(APIConfig.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let systemPrompt = """
        You are a historian researching \(name). Your task is to provide accurate, well-sourced historical events from their life.
        
        CRITICAL RULES:
        1. ONLY process REAL people who actually lived. If this is a fictional character (from books, movies, TV shows, games, comics, anime, mythology, folklore, or any other fiction), respond ONLY with: {"isFictional": true}
        2. Generate 15-30 KEY EVENTS covering major life milestones. Focus on quality over quantity - include only the most significant, well-documented events.
        3. Every event SHOULD have citations/sources when available. Use ONLY authoritative sources from the provided context.
        4. Each date MUST include the year and specify the precision level (exact, monthYear, yearOnly, approximate, decade).
        5. Classify each event by type: birth, childhood, education, career, personal, achievement, death, or historical.
        
        IMPORTANT: Respond with ONLY valid JSON. No additional text before or after the JSON.
        
        If this is a REAL person, respond with valid JSON in this exact format:
        {
            "isFictional": false,
            "name": "Full Name",
            "birthDate": "YYYY" or "Month DD, YYYY",
            "deathDate": "YYYY" or "Month DD, YYYY" or null if still alive,
            "summary": "A 2-3 sentence biography summary",
            "events": [
                {
                    "date": "Date string with year",
                    "title": "Short event title",
                    "description": "Brief description (1-2 sentences)",
                    "eventType": "birth|childhood|education|career|personal|achievement|death|historical",
                    "datePrecision": "exact|monthYear|yearOnly|approximate|decade",
                    "citation": "Primary source name or null",
                    "sourceURL": "URL from provided sources or null",
                    "sources": [
                        {
                            "title": "Source title",
                            "url": "URL from provided sources",
                            "type": "wikipedia|news|academic|biography|official|archive|encyclopedia",
                            "relevantQuote": "Short 1-sentence evidence quote (max ~180 chars) or null",
                            "deepLinkHint": "Optional direct URL or fragment (example: #Early_life) or null"
                        }
                    ]
                }
            ]
        }
        
        EVENT TYPE GUIDELINES:
        - birth: Birth event only
        - childhood: Events from ages 0-12
        - education: School, university, training events
        - career: Work, professional achievements, jobs
        - personal: Marriage, children, relationships, health
        - achievement: Awards, recognition, major accomplishments
        - death: Death event only
        - historical: Major world events they witnessed/participated in
        
        DATE PRECISION GUIDELINES:
        - exact: Full date known (e.g., "March 14, 1879")
        - monthYear: Month and year known (e.g., "March 1879")
        - yearOnly: Only year known (e.g., "1879")
        - approximate: Approximate date (e.g., "circa 1879", "around 1880")
        - decade: Only decade known (e.g., "1870s", "early 1880s")
        
        Generate events in chronological order covering their entire life. Include the most significant:
        - Birth
        - Key childhood/education events
        - Career milestones and achievements
        - Important personal life events
        - Death (if applicable)
        
        CRITICAL: Only cite sources from the AVAILABLE AUTHORITATIVE SOURCES list provided in the context. Do not invent URLs.
        Include a short relevantQuote for each source when possible so users can quickly fact-check.
        deepLinkHint is optional. Only include it when you are confident (absolute URL or valid fragment).
        """
        
        let userMessage = """
        Research and provide historical events for: \(name)
        
        Context from search:
        \(context)
        """
        
        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 8192,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": userMessage]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ClaudeError.invalidResponse
            }
            
            if httpResponse.statusCode != 200 {
                if let errorText = String(data: data, encoding: .utf8) {
                    throw ClaudeError.apiError(errorText)
                }
                throw ClaudeError.invalidResponse
            }
            
            let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)
            
            guard let textContent = claudeResponse.content.first(where: { $0.type == "text" }),
                  let jsonText = textContent.text else {
                throw ClaudeError.invalidResponse
            }
            
            // Parse the JSON from Claude's response (handle markdown code fences)
            let cleanedJSON = extractJSON(from: jsonText)
            
            #if DEBUG
            print("=== Claude Response Debug ===")
            print("Original response length: \(jsonText.count) characters")
            print("Cleaned JSON length: \(cleanedJSON.count) characters")
            print("First 300 chars: \(cleanedJSON.prefix(300))")
            print("Last 300 chars: \(cleanedJSON.suffix(300))")
            print("=============================")
            #endif
            
            guard let jsonData = cleanedJSON.data(using: .utf8) else {
                print("ERROR: Could not convert cleaned JSON to Data")
                throw ClaudeError.decodingError(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON text - could not convert to data"]))
            }
            
            let generatedPerson: GeneratedPerson
            do {
                generatedPerson = try JSONDecoder().decode(GeneratedPerson.self, from: jsonData)
            } catch {
                // Log detailed error information for debugging
                print("=== JSON Decoding Error ===")
                print("Error: \(error)")
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("Missing key: '\(key.stringValue)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                    case .typeMismatch(let type, let context):
                        print("Type mismatch: expected \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                    case .valueNotFound(let type, let context):
                        print("Value not found: expected \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                    case .dataCorrupted(let context):
                        print("Data corrupted at path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - \(context.debugDescription)")
                    @unknown default:
                        print("Unknown decoding error")
                    }
                }
                print("Raw JSON (first 1000 chars):\n\(cleanedJSON.prefix(1000))")
                print("===========================")
                throw ClaudeError.decodingError(error)
            }
            
            // Check if Claude identified this as a fictional character
            if generatedPerson.isFictional == true {
                throw ClaudeError.fictionalCharacter
            }
            
            // Validate required fields for real person
            guard let name = generatedPerson.name,
                  let summary = generatedPerson.summary,
                  let events = generatedPerson.events else {
                throw ClaudeError.invalidResponse
            }
            
            // Convert to our Person model
            let historicalEvents = events.map { event in
                // Parse event type
                let eventType: EventType
                if let typeString = event.eventType {
                    eventType = EventType(rawValue: typeString) ?? .historical
                } else {
                    eventType = .historical
                }
                
                // Parse date precision
                let datePrecision: DatePrecision
                if let precisionString = event.datePrecision {
                    datePrecision = DatePrecision(rawValue: precisionString) ?? .unknown
                } else {
                    datePrecision = .unknown
                }
                
                // Convert sources
                let sources: [Source] = event.sources?.map { generatedSource in
                    let sourceType: SourceType
                    if let typeString = generatedSource.type {
                        sourceType = SourceType(rawValue: typeString) ?? .unknown
                    } else {
                        sourceType = .unknown
                    }
                    
                    return Source(
                        title: generatedSource.title,
                        url: generatedSource.url,
                        sourceType: sourceType,
                        reliabilityScore: sourceType.baseReliabilityScore,
                        relevantQuote: generatedSource.relevantQuote,
                        deepLinkURL: generatedSource.deepLinkHint
                    )
                } ?? []
                
                return HistoricalEvent(
                    date: event.date,
                    title: event.title,
                    description: event.description,
                    citation: event.citation,
                    sourceURL: event.sourceURL,
                    eventType: eventType,
                    datePrecision: datePrecision,
                    sources: sources
                )
            }
            
            return Person(
                name: name,
                birthDate: generatedPerson.birthDate,
                deathDate: generatedPerson.deathDate,
                summary: summary,
                events: historicalEvents
            )
            
        } catch let error as ClaudeError {
            throw error
        } catch let error as DecodingError {
            throw ClaudeError.decodingError(error)
        } catch {
            throw ClaudeError.networkError(error)
        }
    }
    
    // MARK: - Candidate Descriptions

    /// Response model for batch candidate descriptions
    private struct CandidateDescriptionsResponse: Codable {
        let descriptions: [CandidateDescription]

        struct CandidateDescription: Codable {
            let name: String
            let description: String
        }
    }

    /// Generate clean one-sentence descriptions for a batch of person candidates.
    /// Uses a lightweight model for cost efficiency. Returns a dictionary mapping name -> description.
    /// Fails gracefully: returns an empty dictionary on any error so callers can fall back.
    func generateCandidateDescriptions(
        candidates: [(name: String, rawSummary: String)]
    ) async -> [String: String] {
        guard !candidates.isEmpty else { return [:] }
        guard let url = URL(string: "\(APIConfig.anthropicBaseURL)/messages") else { return [:] }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(APIConfig.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let candidateList = candidates
            .enumerated()
            .map { index, c in "\(index + 1). \(c.name): \(c.rawSummary)" }
            .joined(separator: "\n")

        let systemPrompt = """
        You are an encyclopedic editor. For each person listed, write ONE clean, elegant sentence describing who they are. \
        The sentence should read like a dictionary biography entry — factual, concise, and authoritative. \
        Do NOT include birth/death years in the sentence (those are shown separately). \
        Strip any markdown formatting. If a person is fictional or you cannot identify them, write "Unknown person."

        Respond with ONLY valid JSON in this exact format:
        {"descriptions": [{"name": "Full Name", "description": "One sentence."}]}
        """

        let userMessage = "Write one-sentence descriptions for these people:\n\n\(candidateList)"

        let body: [String: Any] = [
            "model": "claude-haiku-4-20250514",
            "max_tokens": 2048,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": userMessage]
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return [:] }

            let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)

            guard let textContent = claudeResponse.content.first(where: { $0.type == "text" }),
                  let jsonText = textContent.text else { return [:] }

            let cleanedJSON = extractJSON(from: jsonText)
            guard let jsonData = cleanedJSON.data(using: .utf8) else { return [:] }

            let parsed = try JSONDecoder().decode(CandidateDescriptionsResponse.self, from: jsonData)

            var result: [String: String] = [:]
            for item in parsed.descriptions {
                let normalizedName = item.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                result[normalizedName] = item.description
            }
            return result
        } catch {
            #if DEBUG
            print("generateCandidateDescriptions failed: \(error.localizedDescription)")
            #endif
            return [:]
        }
    }

    // MARK: - Private Helpers
    
    /// Extract JSON from text that may contain markdown code fences or be truncated
    private func extractJSON(from text: String) -> String {
        var content = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove markdown code fences (```json or ``` at start, ``` at end)
        if content.hasPrefix("```") {
            // Find the end of the first line (which might be ```json or just ```)
            if let firstNewline = content.firstIndex(of: "\n") {
                content = String(content[content.index(after: firstNewline)...])
            } else {
                // Remove just the backticks if no newline
                content = String(content.dropFirst(3))
            }
        }
        
        // Remove trailing code fence
        if content.hasSuffix("```") {
            content = String(content.dropLast(3))
        }
        
        content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If still not valid JSON, try to find JSON object in the text
        if !content.hasPrefix("{") {
            if let startIndex = content.firstIndex(of: "{"),
               let endIndex = content.lastIndex(of: "}") {
                content = String(content[startIndex...endIndex])
            }
        }
        
        // Handle truncated JSON - attempt to close open structures
        content = attemptToRepairTruncatedJSON(content)
        
        return content
    }
    
    /// Attempt to repair truncated JSON by closing open braces and brackets
    private func attemptToRepairTruncatedJSON(_ json: String) -> String {
        var content = json
        
        // Count open/close braces and brackets
        var openBraces = 0
        var openBrackets = 0
        var inString = false
        var escapeNext = false
        
        for char in content {
            if escapeNext {
                escapeNext = false
                continue
            }
            
            if char == "\\" && inString {
                escapeNext = true
                continue
            }
            
            if char == "\"" {
                inString = !inString
                continue
            }
            
            if !inString {
                switch char {
                case "{": openBraces += 1
                case "}": openBraces -= 1
                case "[": openBrackets += 1
                case "]": openBrackets -= 1
                default: break
                }
            }
        }
        
        // If we're still in a string, close it
        if inString {
            content += "\""
        }
        
        // Close any remaining open brackets first, then braces
        // This handles cases like truncated arrays within objects
        while openBrackets > 0 {
            content += "]"
            openBrackets -= 1
        }
        
        while openBraces > 0 {
            content += "}"
            openBraces -= 1
        }
        
        return content
    }
}
