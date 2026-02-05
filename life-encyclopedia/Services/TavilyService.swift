//
//  TavilyService.swift
//  life-encyclopedia
//
//  Service for verifying people and fact-checking using Tavily search API
//

import Foundation

// MARK: - Person Discovery Result

struct PersonDiscovery {
    let name: String
    let isVerified: Bool
    let isFictional: Bool
    let summary: String
    let sources: [Source]
    let rawResults: [TavilySearchResult]
    
    static let notFound = PersonDiscovery(
        name: "",
        isVerified: false,
        isFictional: false,
        summary: "",
        sources: [],
        rawResults: []
    )
}

// MARK: - Event Verification Result

struct EventVerification {
    let event: String
    let date: String
    let isVerified: Bool
    let matchingSources: [Source]
    let datePrecision: DatePrecision
    let discrepancies: [String]
}

@Observable
final class TavilyService {
    
    // MARK: - Properties
    
    private let sourceFilter = SourceFilter()
    
    // MARK: - Constants
    
    /// Strong indicators that definitively identify a fictional character
    /// These phrases explicitly state the subject IS fictional, not just related to fiction
    private let strongFictionalIndicators = [
        "is a fictional character",
        "is a fictional",
        "fictional character in",
        "fictional character from",
        "fictional character created",
        "fictional character who",
        "fictional protagonist",
        "fictional antagonist",
        "fictional superhero",
        "fictional villain",
        "main character in the",
        "protagonist of the",
        "antagonist in",
        "character created by",
        "character portrayed by",
        "played by",  // For fictional characters played by actors
        "voiced by",  // For animated/game characters
        "appears in the"
    ]
    
    /// Moderate indicators that suggest fictional (need multiple to confirm)
    private let moderateFictionalIndicators = [
        "fictional character",
        "comic book character",
        "anime character",
        "manga character",
        "video game character",
        "mythological figure",
        "legendary figure",
        "fairy tale character",
        "folklore character",
        "literary character"
    ]
    
    /// Strong indicators that confirm a REAL person (used as counter-evidence)
    private let realPersonIndicators = [
        "was born",
        "born on",
        "born in",
        "date of birth",
        "died on",
        "died in",
        "date of death",
        "biography",
        "biographical",
        "autobiography",
        "early life",
        "personal life",
        "career",
        "graduated from",
        "attended",
        "married",
        "children",
        "net worth",
        "award",
        "nobel",
        "pulitzer",
        "grammy",
        "oscar",
        "emmy",
        "founded",
        "ceo of",
        "president of",
        "prime minister",
        "elected",
        "politician",
        "businessman",
        "businesswoman",
        "entrepreneur",
        "scientist",
        "researcher",
        "professor",
        "historian",
        "real-life",
        "real life",
        "historical figure"
    ]
    
    /// Search query templates for comprehensive person research
    private let discoveryQueries = [
        "biography",
        "life timeline important dates",
        "career achievements"
    ]
    
    // MARK: - Errors
    
    enum TavilyError: LocalizedError {
        case invalidURL
        case invalidResponse
        case networkError(Error)
        case personNotFound
        case fictionalCharacter
        case rateLimitExceeded
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL configuration"
            case .invalidResponse:
                return "Invalid response from search service"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .personNotFound:
                return "Person not found. Please check the name and try again."
            case .fictionalCharacter:
                return "This appears to be a fictional character. Please search for a real historical person."
            case .rateLimitExceeded:
                return "Search rate limit exceeded. Please try again later."
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Comprehensive person discovery with multiple parallel searches
    /// - Parameter name: The person's name to research
    /// - Returns: PersonDiscovery with aggregated sources
    func discoverPerson(name: String) async throws -> PersonDiscovery {
        // Run parallel searches for comprehensive coverage
        let queries = discoveryQueries.map { "\(name) \($0)" }
        
        var allResults: [TavilySearchResult] = []
        
        // Execute searches concurrently
        try await withThrowingTaskGroup(of: [TavilySearchResult].self) { group in
            for query in queries {
                group.addTask {
                    try await self.performSearch(query: query, depth: "advanced", maxResults: 10)
                }
            }
            
            for try await results in group {
                allResults.append(contentsOf: results)
            }
        }
        
        // Filter for relevant results
        let relevantResults = filterRelevantResults(allResults, personName: name)
        
        if relevantResults.isEmpty {
            return .notFound
        }
        
        // Check for fictional character
        if isFictionalPerson(results: relevantResults) {
            return PersonDiscovery(
                name: name,
                isVerified: false,
                isFictional: true,
                summary: "",
                sources: [],
                rawResults: relevantResults
            )
        }
        
        // Filter authoritative sources and convert
        let authoritativeResults = sourceFilter.filterAuthoritativeSources(relevantResults)
        let sources = sourceFilter.convertToSources(authoritativeResults)
        let uniqueSources = sourceFilter.deduplicateSources(sources)
        
        // Build summary from best sources
        let summary = buildSummary(from: uniqueSources)
        
        return PersonDiscovery(
            name: name,
            isVerified: true,
            isFictional: false,
            summary: summary,
            sources: uniqueSources,
            rawResults: relevantResults
        )
    }
    
    /// Verify a specific event and date using Tavily search
    /// - Parameters:
    ///   - name: The person's name
    ///   - event: The event description
    ///   - date: The claimed date
    /// - Returns: EventVerification with confidence score and sources
    func verifyEvent(name: String, event: String, date: String) async throws -> EventVerification {
        // Search for the specific event with date
        let query = "\(name) \(event) \(date)"
        let results = try await performSearch(query: query, depth: "advanced", maxResults: 8)
        
        // Filter for authoritative sources
        let authoritativeResults = sourceFilter.filterAuthoritativeSources(results)
        let sources = sourceFilter.convertToSources(authoritativeResults)
        
        // Check how many sources mention the date
        let dateMatches = results.filter { result in
            let content = result.content.lowercased()
            return content.contains(extractYear(from: date)) ||
                   content.contains(date.lowercased())
        }
        
        // Calculate confidence based on source agreement
        let confidence = calculateConfidence(
            totalSources: authoritativeResults.count,
            dateMatches: dateMatches.count
        )
        
        // Check for discrepancies in dates
        let discrepancies = findDateDiscrepancies(results: results, expectedDate: date)
        
        // Determine date precision
        let precision = determineDatePrecision(date)
        
        return EventVerification(
            event: event,
            date: date,
            isVerified: confidence >= 0.7 && discrepancies.isEmpty,
            matchingSources: sources,
            datePrecision: precision,
            discrepancies: discrepancies
        )
    }
    
    /// Find authoritative sources for a specific query
    /// - Parameters:
    ///   - query: The search query
    ///   - limit: Maximum number of sources to return
    /// - Returns: Array of authoritative sources
    func findAuthoritativeSources(query: String, limit: Int = 10) async throws -> [Source] {
        let results = try await performSearch(query: query, depth: "advanced", maxResults: limit * 2)
        let authoritativeResults = sourceFilter.filterAuthoritativeSources(results)
        let sources = sourceFilter.convertToSources(authoritativeResults)
        return sourceFilter.topSources(sourceFilter.deduplicateSources(sources), limit: limit)
    }
    
    /// Search for a person and verify they exist as a real (non-fictional) person
    /// - Parameter name: The person's name to search for
    /// - Returns: PersonVerification with search results
    func verifyPerson(name: String) async throws -> PersonVerification {
        // Search for real person indicators (born, biography)
        let query = "\(name) real person biography born"
        let results = try await performSearch(query: query, depth: "basic", maxResults: 5)
        
        // Check if we found relevant results
        let relevantResults = filterRelevantResults(results, personName: name)
        
        if relevantResults.isEmpty {
            return .notFound
        }
        
        // Check if this is a fictional character
        if isFictionalPerson(results: relevantResults) {
            return PersonVerification(
                isVerified: false,
                name: name,
                summary: "",
                sources: [],
                isFictional: true
            )
        }
        
        // Build a summary from the top result
        let topResult = relevantResults[0]
        let summary = String(topResult.content.prefix(500))
        
        return PersonVerification(
            isVerified: true,
            name: name,
            summary: summary,
            sources: relevantResults,
            isFictional: false
        )
    }
    
    /// Batch verify multiple events for a person
    /// - Parameters:
    ///   - name: Person's name
    ///   - events: Array of (event, date) tuples to verify
    /// - Returns: Array of EventVerification results
    func batchVerifyEvents(name: String, events: [(event: String, date: String)]) async throws -> [EventVerification] {
        var verifications: [EventVerification] = []
        
        // Process in batches of 5 to avoid rate limiting
        let batchSize = 5
        for batch in stride(from: 0, to: events.count, by: batchSize) {
            let endIndex = min(batch + batchSize, events.count)
            let currentBatch = events[batch..<endIndex]
            
            try await withThrowingTaskGroup(of: EventVerification.self) { group in
                for (event, date) in currentBatch {
                    group.addTask {
                        try await self.verifyEvent(name: name, event: event, date: date)
                    }
                }
                
                for try await verification in group {
                    verifications.append(verification)
                }
            }
            
            // Small delay between batches to avoid rate limiting
            if endIndex < events.count {
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
        }
        
        return verifications
    }
    
    // MARK: - Private Helpers
    
    /// Perform a Tavily search request
    private func performSearch(query: String, depth: String, maxResults: Int) async throws -> [TavilySearchResult] {
        guard let url = URL(string: "\(APIConfig.tavilyBaseURL)/search") else {
            throw TavilyError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "api_key": APIConfig.tavilyAPIKey,
            "query": query,
            "search_depth": depth,
            "include_answer": false,
            "include_raw_content": false,
            "max_results": maxResults
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TavilyError.invalidResponse
            }
            
            if httpResponse.statusCode == 429 {
                throw TavilyError.rateLimitExceeded
            }
            
            guard httpResponse.statusCode == 200 else {
                throw TavilyError.invalidResponse
            }
            
            let tavilyResponse = try JSONDecoder().decode(TavilyResponse.self, from: data)
            return tavilyResponse.results
            
        } catch let error as TavilyError {
            throw error
        } catch {
            throw TavilyError.networkError(error)
        }
    }
    
    /// Filter results to only those relevant to the person
    private func filterRelevantResults(_ results: [TavilySearchResult], personName: String) -> [TavilySearchResult] {
        let nameParts = personName.lowercased().split(separator: " ")
        
        return results.filter { result in
            let lowercasedContent = result.content.lowercased()
            let lowercasedTitle = result.title.lowercased()
            
            // Check if full name or last name appears
            let fullNameMatch = lowercasedContent.contains(personName.lowercased()) ||
                               lowercasedTitle.contains(personName.lowercased())
            
            // Also match if last name appears prominently
            let lastNameMatch = nameParts.count > 1 &&
                               (lowercasedContent.contains(String(nameParts.last!)) ||
                                lowercasedTitle.contains(String(nameParts.last!)))
            
            return fullNameMatch || lastNameMatch
        }
    }
    
    /// Check if search results indicate a fictional character using weighted evidence
    /// Returns true only when there's strong evidence of fiction AND lack of real person indicators
    private func isFictionalPerson(results: [TavilySearchResult]) -> Bool {
        var strongFictionalMatches = 0
        var moderateFictionalMatches = 0
        var realPersonMatches = 0
        var resultsWithFictionalIndicators = 0
        
        for result in results {
            let content = result.content.lowercased()
            let title = result.title.lowercased()
            let combinedText = title + " " + content
            
            var hasStrongFictional = false
            var hasModerateFictional = false
            var hasRealIndicator = false
            
            // Check for strong fictional indicators (definitive statements)
            for indicator in strongFictionalIndicators {
                if combinedText.contains(indicator) {
                    strongFictionalMatches += 1
                    hasStrongFictional = true
                    break  // One strong match per result is enough
                }
            }
            
            // Check for moderate fictional indicators
            if !hasStrongFictional {
                for indicator in moderateFictionalIndicators {
                    if combinedText.contains(indicator) {
                        moderateFictionalMatches += 1
                        hasModerateFictional = true
                        break
                    }
                }
            }
            
            // Check for real person indicators (counter-evidence)
            for indicator in realPersonIndicators {
                if combinedText.contains(indicator) {
                    realPersonMatches += 1
                    hasRealIndicator = true
                    break
                }
            }
            
            if hasStrongFictional || hasModerateFictional {
                resultsWithFictionalIndicators += 1
            }
        }
        
        // Decision logic with multiple safeguards against false positives:
        
        // 1. If we have MORE real person indicators than fictional, assume real
        if realPersonMatches > (strongFictionalMatches + moderateFictionalMatches) {
            return false
        }
        
        // 2. Strong fictional indicator in title + multiple results = likely fictional
        //    But only if real person indicators are minimal
        if strongFictionalMatches >= 2 && realPersonMatches <= 1 {
            return true
        }
        
        // 3. Single strong fictional match is only conclusive if NO real person indicators
        if strongFictionalMatches >= 1 && realPersonMatches == 0 {
            return true
        }
        
        // 4. Moderate indicators need strong consensus (majority of results)
        //    AND very few real person indicators
        let totalResults = results.count
        if totalResults > 0 {
            let fictionalRatio = Double(resultsWithFictionalIndicators) / Double(totalResults)
            if fictionalRatio > 0.6 && moderateFictionalMatches >= 3 && realPersonMatches <= 1 {
                return true
            }
        }
        
        // Default: assume real person (false positives are worse than false negatives)
        return false
    }
    
    /// Build a summary from the best sources
    private func buildSummary(from sources: [Source]) -> String {
        guard let bestSource = sources.first,
              let snippet = bestSource.contentSnippet else {
            return ""
        }
        
        // Take first 500 characters of best source
        return String(snippet.prefix(500))
    }
    
    /// Calculate confidence score based on source agreement
    private func calculateConfidence(totalSources: Int, dateMatches: Int) -> Double {
        guard totalSources > 0 else { return 0.0 }
        
        let matchRatio = Double(dateMatches) / Double(totalSources)
        
        // Base confidence on match ratio and total sources
        var confidence = matchRatio * 0.6
        
        // Bonus for multiple confirming sources
        if dateMatches >= 3 {
            confidence += 0.3
        } else if dateMatches >= 2 {
            confidence += 0.2
        } else if dateMatches >= 1 {
            confidence += 0.1
        }
        
        // Bonus for total source count
        if totalSources >= 5 {
            confidence += 0.1
        }
        
        return min(1.0, confidence)
    }
    
    /// Find date discrepancies in search results
    private func findDateDiscrepancies(results: [TavilySearchResult], expectedDate: String) -> [String] {
        var discrepancies: [String] = []
        let expectedYear = extractYear(from: expectedDate)
        
        // Pattern to find years near biographical context
        let yearPattern = "\\b(1[0-9]{3}|20[0-9]{2})\\b"
        guard let regex = try? NSRegularExpression(pattern: yearPattern) else {
            return []
        }
        
        for result in results {
            let content = result.content
            let range = NSRange(content.startIndex..., in: content)
            let matches = regex.matches(in: content, range: range)
            
            for match in matches {
                if let yearRange = Range(match.range, in: content) {
                    let foundYear = String(content[yearRange])
                    // Check if found year is significantly different but close (within 10 years)
                    if let expected = Int(expectedYear),
                       let found = Int(foundYear),
                       found != expected && abs(found - expected) <= 10 {
                        let discrepancy = "Source '\(result.title)' mentions year \(foundYear) instead of \(expectedYear)"
                        if !discrepancies.contains(discrepancy) {
                            discrepancies.append(discrepancy)
                        }
                    }
                }
            }
        }
        
        return Array(discrepancies.prefix(3)) // Limit to 3 discrepancies
    }
    
    /// Extract year from date string
    private func extractYear(from date: String) -> String {
        let pattern = "\\b(1[0-9]{3}|20[0-9]{2})\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: date, range: NSRange(date.startIndex..., in: date)),
              let range = Range(match.range, in: date) else {
            return date
        }
        return String(date[range])
    }
    
    /// Determine date precision from date string format
    private func determineDatePrecision(_ date: String) -> DatePrecision {
        let trimmed = date.trimmingCharacters(in: .whitespaces).lowercased()
        
        // Check for decade (e.g., "1870s")
        if trimmed.contains("s") && trimmed.count <= 6 {
            return .decade
        }
        
        // Check for approximate (e.g., "circa", "around", "approximately")
        if trimmed.contains("circa") || trimmed.contains("around") || trimmed.contains("approximately") || trimmed.contains("~") {
            return .approximate
        }
        
        // Check for exact date (has day, month, and year)
        let monthNames = ["january", "february", "march", "april", "may", "june", "july", "august", "september", "october", "november", "december"]
        let hasMonth = monthNames.contains { trimmed.contains($0) }
        let hasDay = try! NSRegularExpression(pattern: "\\b[0-9]{1,2}\\b").firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) != nil
        let hasYear = try! NSRegularExpression(pattern: "\\b(1[0-9]{3}|20[0-9]{2})\\b").firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) != nil
        
        if hasMonth && hasDay && hasYear {
            return .exact
        } else if hasMonth && hasYear {
            return .monthYear
        } else if hasYear {
            return .yearOnly
        }
        
        return .unknown
    }
}
