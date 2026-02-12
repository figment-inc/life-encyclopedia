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

    /// Search for people candidates from the web for the create flow.
    /// - Parameters:
    ///   - query: Partial query entered by the user.
    ///   - limit: Maximum number of unique candidates to return.
    /// - Returns: Relevance-ranked candidate list.
    func searchPeopleCandidates(query: String, limit: Int = 20) async throws -> [PersonCandidate] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return [] }

        let safeLimit = max(1, min(limit, 30))
        let searchQuery = "\(trimmedQuery) person biography"
        let wikipediaDomains = ["en.wikipedia.org", "wikipedia.org"]
        let rawResults = try await performSearch(
            query: searchQuery,
            depth: "basic",
            maxResults: safeLimit * 2,
            includeDomains: wikipediaDomains
        )

        let filteredResults = rawResults.filter { result in
            // Ensure the result is actually from Wikipedia
            let isWikipedia = result.url.lowercased().contains("wikipedia.org")
            guard isWikipedia else { return false }

            let lowercasedQuery = trimmedQuery.lowercased()
            return result.title.lowercased().contains(lowercasedQuery) ||
                   result.content.lowercased().contains(lowercasedQuery)
        }
        if filteredResults.isEmpty { return [] }

        var candidatesByID: [String: PersonCandidate] = [:]
        for result in filteredResults {
            guard let candidateName = candidateName(from: result),
                  isLikelyPersonName(candidateName) else {
                continue
            }

            let combinedText = (result.title + " " + result.content).lowercased()

            // Filter out fictional characters at search time
            let isFictional = strongFictionalIndicators.contains { combinedText.contains($0) }
            if isFictional { continue }

            // Require positive evidence this is about a real person
            guard isLikelyPersonResult(combinedText) else { continue }

            let candidate = PersonCandidate(
                name: candidateName,
                years: extractLifespan(from: result.content),
                summary: extractPersonDescription(from: result.content, name: candidateName),
                sourceTitle: result.title,
                sourceURL: result.url,
                relevanceScore: candidateRelevanceScore(
                    name: candidateName,
                    query: trimmedQuery,
                    sourceScore: result.score
                )
            )

            if let existing = candidatesByID[candidate.id], existing.relevanceScore >= candidate.relevanceScore {
                continue
            }
            candidatesByID[candidate.id] = candidate
        }

        let uniqueCandidatesByName = deduplicateCandidatesByName(Array(candidatesByID.values))

        return uniqueCandidatesByName
            .sorted { left, right in
                if left.relevanceScore != right.relevanceScore { return left.relevanceScore > right.relevanceScore }
                return left.name.localizedCaseInsensitiveCompare(right.name) == .orderedAscending
            }
            .prefix(safeLimit)
            .map { $0 }
    }
    
    /// Batch verify multiple events for a person
    /// - Parameters:
    ///   - name: Person's name
    ///   - events: Array of (event, date) tuples to verify
    /// - Returns: Array of EventVerification results
    func batchVerifyEvents(name: String, events: [(event: String, date: String)]) async throws -> [EventVerification] {
        var verifications = Array<EventVerification?>(repeating: nil, count: events.count)
        
        // Process in batches of 5 to avoid rate limiting
        let batchSize = 5
        for batch in stride(from: 0, to: events.count, by: batchSize) {
            let endIndex = min(batch + batchSize, events.count)
            let currentBatch = events[batch..<endIndex]
            
            try await withThrowingTaskGroup(of: (Int, EventVerification).self) { group in
                for (offset, eventTuple) in currentBatch.enumerated() {
                    let absoluteIndex = batch + offset
                    group.addTask {
                        let verification = try await self.verifyEvent(
                            name: name,
                            event: eventTuple.event,
                            date: eventTuple.date
                        )
                        return (absoluteIndex, verification)
                    }
                }
                
                for try await (index, verification) in group {
                    verifications[index] = verification
                }
            }
            
            // Small delay between batches to avoid rate limiting
            if endIndex < events.count {
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
        }
        
        // Preserve input order and gracefully skip missing results if any task failed silently.
        return verifications.compactMap { $0 }
    }
    
    // MARK: - Private Helpers

    private func candidateName(from result: TavilySearchResult) -> String? {
        let separators = [" - ", " | ", " — ", " – ", ":"]
        let trimmedTitle = result.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return nil }

        var candidate = trimmedTitle
        for separator in separators {
            if let range = candidate.range(of: separator) {
                candidate = String(candidate[..<range.lowerBound])
                break
            }
        }

        candidate = candidate
            .replacingOccurrences(of: "\"", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if candidate.count >= 3 { return candidate }
        return nil
    }

    private func isLikelyPersonName(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count < 3 { return false }

        let disallowedKeywords = [
            "wikipedia",
            "list of",
            "history of",
            "dynasty",
            "timeline",
            "category:",
            "portal:"
        ]
        let lowercased = trimmed.lowercased()
        if disallowedKeywords.contains(where: { lowercased.contains($0) }) {
            return false
        }

        // Reject names with parenthetical qualifiers that indicate fictional/non-person entries
        let fictionalQualifiers = [
            "(hero)", "(character)", "(comics)", "(fiction)", "(novel)",
            "(film)", "(tv series)", "(anime)", "(manga)", "(video game)",
            "(mythology)", "(folklore)", "(fairy tale)", "(legend)",
            "(marvel)", "(dc comics)", "(disney)", "(star wars)"
        ]
        if fictionalQualifiers.contains(where: { lowercased.contains($0) }) {
            return false
        }

        return true
    }

    /// Check whether a result's combined text (title + content, already lowercased) describes a real person.
    /// Requires at least one positive person indicator AND no non-person blocklist matches.
    private func isLikelyPersonResult(_ combinedText: String) -> Bool {
        // Non-person Wikipedia article indicators (places, events, concepts, objects, etc.)
        let nonPersonIndicators = [
            "is a city",
            "is a town",
            "is a village",
            "is a county",
            "is a municipality",
            "is a country",
            "is a state",
            "is a province",
            "is a region",
            "is a district",
            "is a river",
            "is a mountain",
            "is a lake",
            "is a building",
            "is a company",
            "is a brand",
            "is a band",
            "is a song",
            "is a film",
            "is a book",
            "is a novel",
            "is an album",
            "is a television",
            "is a tv",
            "is a genus",
            "is a species",
            "is a type of",
            "is a family of",
            "is a term",
            "is a concept",
            "is an event",
            "is a holiday",
            "is a celebration",
            "is an organization",
            "is a school",
            "is a university",
            "is a college",
            "is a hospital",
            "census-designated place",
            "unincorporated community",
            "populated place",
            "geographic",
            "coordinates"
        ]

        // Reject if content matches non-person patterns
        if nonPersonIndicators.contains(where: { combinedText.contains($0) }) {
            return false
        }

        // Person indicators: biography patterns common in Wikipedia person articles
        let personIndicators = [
            // Life events
            "was born", "born on", "born in", "(born ", "date of birth",
            "died on", "died in", "date of death", "(died ",
            // Biography structure
            "biography", "early life", "personal life", "later life",
            "career", "education",
            // Descriptions of people
            "was a ", "was an ", "is a ", "is an ",
            // Life year patterns (e.g. "(1940–2020)")
            "graduated from", "attended", "married", "children",
            // Titles and roles
            "politician", "scientist", "artist", "author", "writer",
            "musician", "composer", "actor", "actress", "director",
            "philosopher", "mathematician", "physicist", "chemist",
            "engineer", "architect", "physician", "surgeon", "nurse",
            "general", "admiral", "colonel", "soldier", "military",
            "king", "queen", "emperor", "empress", "prince", "princess",
            "president", "prime minister", "governor", "senator", "mayor",
            "journalist", "explorer", "inventor", "entrepreneur",
            "businessman", "businesswoman", "industrialist",
            "athlete", "player", "coach", "boxer", "wrestler",
            "painter", "sculptor", "photographer",
            "theologian", "priest", "bishop", "pope", "rabbi", "imam",
            "activist", "reformer", "revolutionary",
            "professor", "researcher", "historian", "economist",
            "lawyer", "judge", "chief justice",
            "philanthropist", "humanitarian",
            "singer", "rapper", "guitarist", "drummer",
            "ceo of", "founder of", "co-founder",
            // Awards/honors (strong person signal)
            "nobel", "pulitzer", "grammy", "oscar", "emmy", "award"
        ]

        return personIndicators.contains { combinedText.contains($0) }
    }

    private func summarizeCandidateContent(_ content: String) -> String {
        let cleaned = content
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.count <= 220 { return cleaned }
        let cutoff = cleaned.index(cleaned.startIndex, offsetBy: 220)
        return String(cleaned[..<cutoff]).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
    }

    /// Extract a lifespan string like "1452 – 1519" from content.
    /// Returns a normalized, display-ready string with proper en-dashes.
    private func extractLifespan(from content: String) -> String? {
        // Ordered patterns: most specific first
        let patterns: [(pattern: String, format: LifespanFormat)] = [
            // (1452–1519) or (1452-1519)
            ("\\(\\s*(\\d{3,4})\\s*[–\\-—]\\s*(\\d{3,4})\\s*\\)", .range),
            // (1980–present)
            ("\\(\\s*(\\d{3,4})\\s*[–\\-—]\\s*present\\s*\\)", .birthToPresent),
            // born 1452 ... died 1519
            ("born\\s+(\\d{3,4}).*?died\\s+(\\d{3,4})", .range),
            // (born 1980)
            ("\\(born\\s+(\\d{3,4})\\)", .birthOnly),
            // 100 BCE–44 BCE
            ("\\b(\\d{3,4})\\s*(BCE?|CE|BC|AD)\\s*[–\\-—]\\s*(\\d{3,4})\\s*(BCE?|CE|BC|AD)?\\b", .eraRange)
        ]

        for (pattern, format) in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }
            let range = NSRange(content.startIndex..., in: content)
            guard let match = regex.firstMatch(in: content, range: range) else { continue }

            switch format {
            case .range:
                if let r1 = Range(match.range(at: 1), in: content),
                   let r2 = Range(match.range(at: 2), in: content) {
                    return "\(content[r1]) \u{2013} \(content[r2])"
                }
            case .birthToPresent:
                if let r1 = Range(match.range(at: 1), in: content) {
                    return "\(content[r1]) \u{2013} present"
                }
            case .birthOnly:
                if let r1 = Range(match.range(at: 1), in: content) {
                    return "b. \(content[r1])"
                }
            case .eraRange:
                if let r1 = Range(match.range(at: 1), in: content),
                   let r2 = Range(match.range(at: 2), in: content),
                   let r3 = Range(match.range(at: 3), in: content) {
                    let era1 = String(content[r2]).uppercased()
                    let era2Str: String
                    if match.range(at: 4).location != NSNotFound,
                       let r4 = Range(match.range(at: 4), in: content) {
                        era2Str = " \(String(content[r4]).uppercased())"
                    } else {
                        era2Str = ""
                    }
                    return "\(content[r1]) \(era1) \u{2013} \(content[r3])\(era2Str)"
                }
            }
        }

        return nil
    }

    private enum LifespanFormat {
        case range
        case birthToPresent
        case birthOnly
        case eraRange
    }

    /// Extract the first meaningful sentence that describes a person.
    private func extractPersonDescription(from content: String, name: String) -> String {
        let cleaned = content
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Split into sentences
        let sentenceEnders = CharacterSet(charactersIn: ".!?")
        var sentences: [String] = []
        var current = ""
        for char in cleaned {
            current.append(char)
            if sentenceEnders.contains(Unicode.Scalar(String(char))!) {
                let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    sentences.append(trimmed)
                }
                current = ""
            }
        }
        if !current.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sentences.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        let nameParts = name.lowercased().split(separator: " ")
        let lastName = nameParts.last.map(String.init) ?? name.lowercased()

        // Find the first sentence mentioning the person that reads like a description
        // (contains a verb-like indicator: "was", "is", "served", etc.)
        let descriptionIndicators = ["was ", "is ", "were ", "served ", "became ", "founded ", "known ", "regarded "]
        for sentence in sentences {
            let lower = sentence.lowercased()
            let mentionsPerson = lower.contains(name.lowercased()) || lower.contains(lastName)
            let hasDescriptor = descriptionIndicators.contains { lower.contains($0) }
            if mentionsPerson && hasDescriptor && sentence.count >= 20 {
                // Trim to one sentence, max ~200 chars
                if sentence.count <= 200 {
                    return sentence
                }
                let cutoff = sentence.index(sentence.startIndex, offsetBy: 200)
                return String(sentence[..<cutoff]).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
            }
        }

        // Fallback: first sentence that mentions the person
        for sentence in sentences {
            let lower = sentence.lowercased()
            if (lower.contains(name.lowercased()) || lower.contains(lastName)) && sentence.count >= 15 {
                if sentence.count <= 200 {
                    return sentence
                }
                let cutoff = sentence.index(sentence.startIndex, offsetBy: 200)
                return String(sentence[..<cutoff]).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
            }
        }

        // Last resort: truncated content
        return summarizeCandidateContent(content)
    }

    private func candidateRelevanceScore(name: String, query: String, sourceScore: Double) -> Double {
        let normalizedName = name.lowercased()
        let normalizedQuery = query.lowercased()
        var score = sourceScore

        if normalizedName == normalizedQuery { score += 2.0 }
        if normalizedName.hasPrefix(normalizedQuery) { score += 1.2 }
        if normalizedName.contains(normalizedQuery) { score += 0.7 }

        return score
    }

    private func deduplicateCandidatesByName(_ candidates: [PersonCandidate]) -> [PersonCandidate] {
        var candidatesByName: [String: PersonCandidate] = [:]

        for candidate in candidates {
            let normalizedName = normalizeCandidateName(candidate.name)
            guard !normalizedName.isEmpty else { continue }

            guard let existingCandidate = candidatesByName[normalizedName] else {
                candidatesByName[normalizedName] = candidate
                continue
            }

            if shouldPrefer(candidate, over: existingCandidate) {
                candidatesByName[normalizedName] = candidate
            }
        }

        return Array(candidatesByName.values)
    }

    private func shouldPrefer(_ candidate: PersonCandidate, over existingCandidate: PersonCandidate) -> Bool {
        if candidate.relevanceScore != existingCandidate.relevanceScore {
            return candidate.relevanceScore > existingCandidate.relevanceScore
        }

        let candidateHasYears = !(candidate.years?.isEmpty ?? true)
        let existingHasYears = !(existingCandidate.years?.isEmpty ?? true)
        if candidateHasYears != existingHasYears {
            return candidateHasYears
        }

        if candidate.summary.count != existingCandidate.summary.count {
            return candidate.summary.count > existingCandidate.summary.count
        }

        return candidate.name.localizedCaseInsensitiveCompare(existingCandidate.name) == .orderedAscending
    }

    private func normalizeCandidateName(_ name: String) -> String {
        name
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
    
    /// Perform a Tavily search request
    private func performSearch(query: String, depth: String, maxResults: Int, includeDomains: [String]? = nil) async throws -> [TavilySearchResult] {
        guard let url = URL(string: "\(APIConfig.tavilyBaseURL)/search") else {
            throw TavilyError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [
            "api_key": APIConfig.tavilyAPIKey,
            "query": query,
            "search_depth": depth,
            "include_answer": false,
            "include_raw_content": false,
            "max_results": maxResults
        ]

        if let includeDomains, !includeDomains.isEmpty {
            body["include_domains"] = includeDomains
        }
        
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
