//
//  SupabaseService.swift
//  life-encyclopedia
//
//  Service for CRUD operations with Supabase
//

import Foundation

@Observable
final class SupabaseService {
    
    // MARK: - Errors
    
    enum SupabaseError: LocalizedError {
        case invalidURL
        case invalidResponse
        case invalidConfiguration(String)
        case requestFailed(statusCode: Int, message: String)
        case decodingFailed(String)
        case networkError(Error)
        case notConfigured
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid Supabase URL"
            case .invalidResponse:
                return "Invalid response from database"
            case .invalidConfiguration(let message):
                return message
            case .requestFailed(_, let message):
                return message
            case .decodingFailed(let detail):
                return "Failed to decode database response: \(detail)"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .notConfigured:
                return "Supabase is not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY to real values."
            }
        }
    }
    
    // MARK: - Properties
    
    private let placeholderTokens = [
        "YOUR_SUPABASE_URL",
        "YOUR_SUPABASE_ANON_KEY",
        "your_supabase_url_here",
        "your_supabase_anon_key_here",
        "your-supabase-url",
        "your-supabase-anon-key"
    ]
    
    private var trimmedSupabaseURL: String {
        APIConfig.supabaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var baseSupabaseURL: String {
        trimmedSupabaseURL.hasSuffix("/") ? String(trimmedSupabaseURL.dropLast()) : trimmedSupabaseURL
    }
    
    private var trimmedSupabaseAnonKey: String {
        APIConfig.supabaseAnonKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var isConfigured: Bool {
        configurationError == nil
    }
    
    private var configurationError: SupabaseError? {
        if trimmedSupabaseURL.isEmpty || trimmedSupabaseAnonKey.isEmpty {
            return .notConfigured
        }
        
        if containsPlaceholder(trimmedSupabaseURL) || containsPlaceholder(trimmedSupabaseAnonKey) {
            return .notConfigured
        }
        
        guard let components = URLComponents(string: baseSupabaseURL),
              let scheme = components.scheme?.lowercased(),
              let host = components.host,
              !host.isEmpty else {
            return .invalidURL
        }
        
        if scheme != "https" {
            return .invalidConfiguration("Supabase URL must start with https://")
        }
        
        return nil
    }
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    // MARK: - Name Matching

    /// Normalize a person name for deterministic equality checks.
    /// Rules: trim, collapse whitespace, lowercase.
    func normalizePersonName(_ name: String) -> String {
        let tokens = name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }

        return tokens.joined(separator: " ").lowercased()
    }
    
    // MARK: - Private Helpers
    
    private struct SupabaseAPIErrorPayload: Decodable {
        let message: String?
        let error: String?
        let errorDescription: String?
        
        enum CodingKeys: String, CodingKey {
            case message
            case error
            case errorDescription = "error_description"
        }
    }
    
    private func containsPlaceholder(_ value: String) -> Bool {
        let lowercasedValue = value.lowercased()
        return placeholderTokens.contains { token in
            lowercasedValue.contains(token.lowercased())
        }
    }
    
    private func requireConfiguration() throws {
        guard isConfigured else {
            throw configurationError ?? .notConfigured
        }
    }
    
    private func makeURL(pathAndQuery: String) throws -> URL {
        try requireConfiguration()
        
        guard let url = URL(string: "\(baseSupabaseURL)\(pathAndQuery)") else {
            throw SupabaseError.invalidURL
        }
        
        return url
    }
    
    private func applyCommonHeaders(to request: inout URLRequest) {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(trimmedSupabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(trimmedSupabaseAnonKey)", forHTTPHeaderField: "Authorization")
    }
    
    private func extractAPIErrorMessage(from data: Data) -> String? {
        let payload = try? decoder.decode(SupabaseAPIErrorPayload.self, from: data)
        return payload?.message ?? payload?.errorDescription ?? payload?.error
    }
    
    private func rethrowCancellationIfNeeded(_ error: Error) throws {
        if error is CancellationError {
            throw error
        }
        
        if let urlError = error as? URLError, urlError.code == .cancelled {
            throw urlError
        }
    }
    
    private func normalizeSearchText(_ value: String) -> String {
        let allowedCharacters = CharacterSet.alphanumerics.union(.whitespaces)
        let filteredScalars = value.unicodeScalars.map { scalar -> String in
            allowedCharacters.contains(scalar) ? String(scalar) : " "
        }
        let normalized = filteredScalars.joined()
            .lowercased()
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
        return normalized
    }
    
    private func tokenizeSearchText(_ value: String) -> [String] {
        normalizeSearchText(value)
            .split(separator: " ")
            .map(String.init)
    }
    
    private func suggestionRelevanceScore(for person: Person, query: String) -> Int {
        let normalizedQuery = normalizeSearchText(query)
        guard !normalizedQuery.isEmpty else { return 0 }
        
        let normalizedName = normalizeSearchText(person.name)
        let nameTokens = tokenizeSearchText(person.name)
        let queryTokens = tokenizeSearchText(query)
        
        if normalizedName == normalizedQuery {
            return 500
        }
        
        if let firstNameToken = nameTokens.first {
            if firstNameToken == normalizedQuery {
                return 450
            }
            
            if firstNameToken.hasPrefix(normalizedQuery) {
                return 400
            }
        }
        
        if normalizedName.hasPrefix(normalizedQuery) {
            return 350
        }
        
        if nameTokens.contains(where: { token in
            queryTokens.contains(where: { queryToken in token.hasPrefix(queryToken) })
        }) {
            return 300
        }
        
        if normalizedName.contains(normalizedQuery) {
            return 200
        }
        
        return 0
    }
    
    private func validateResponse(
        _ response: URLResponse,
        data: Data,
        expectedStatusCodes: Set<Int>
    ) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        guard expectedStatusCodes.contains(httpResponse.statusCode) else {
            let apiMessage = extractAPIErrorMessage(from: data) ?? "Supabase request failed."
            
            switch httpResponse.statusCode {
            case 401:
                throw SupabaseError.requestFailed(
                    statusCode: 401,
                    message: "Supabase rejected the anon key (401). Check SUPABASE_ANON_KEY for the same project as SUPABASE_URL."
                )
            case 403:
                throw SupabaseError.requestFailed(
                    statusCode: 403,
                    message: "Supabase request forbidden (403). Verify RLS policies allow this operation on the people table."
                )
            case 404:
                throw SupabaseError.requestFailed(
                    statusCode: 404,
                    message: "Supabase endpoint not found (404). Confirm SUPABASE_URL points to the correct project."
                )
            default:
                throw SupabaseError.requestFailed(
                    statusCode: httpResponse.statusCode,
                    message: "Supabase error (\(httpResponse.statusCode)): \(apiMessage)"
                )
            }
        }
    }
    
    private func parseTotalCount(from response: URLResponse) -> Int? {
        guard let httpResponse = response as? HTTPURLResponse else { return nil }
        guard let contentRange = httpResponse.value(forHTTPHeaderField: "Content-Range") else { return nil }
        
        let pieces = contentRange.split(separator: "/")
        guard pieces.count == 2 else { return nil }
        
        let totalPart = String(pieces[1])
        guard totalPart != "*" else { return nil }
        return Int(totalPart)
    }
    
    private func makePeopleQueryItems(from query: PeopleQuery) -> [URLQueryItem] {
        var queryItems: [URLQueryItem] = []
        
        if !query.searchText.isEmpty {
            queryItems.append(URLQueryItem(name: "name", value: "ilike.*\(query.searchText)*"))
        }
        
        if !query.selectedRegions.isEmpty {
            let values = query.selectedRegions.map(\.rawValue).sorted().joined(separator: ",")
            queryItems.append(URLQueryItem(name: "filter_metadata->>culturalRegion", value: "in.(\(values))"))
        }
        
        if !query.advancedFilters.archetypes.isEmpty {
            let values = query.advancedFilters.archetypes.map(\.rawValue).sorted().joined(separator: ",")
            queryItems.append(URLQueryItem(name: "filter_metadata->>archetype", value: "in.(\(values))"))
        }
        
        if !query.advancedFilters.moralValences.isEmpty {
            let values = query.advancedFilters.moralValences.map(\.rawValue).sorted().joined(separator: ",")
            queryItems.append(URLQueryItem(name: "filter_metadata->>moralValence", value: "in.(\(values))"))
        }
        
        if !query.advancedFilters.lifeArcs.isEmpty {
            let values = query.advancedFilters.lifeArcs.map(\.rawValue).sorted().joined(separator: ",")
            queryItems.append(URLQueryItem(name: "filter_metadata->>lifeArc", value: "in.(\(values))"))
        }
        
        if !query.selectedDomains.isEmpty {
            let primaryValues = query.selectedDomains.map(\.rawValue).sorted().joined(separator: ",")
            var domainTerms = ["filter_metadata->>primaryDomain.in.(\(primaryValues))"]
            for domain in query.selectedDomains.sorted(by: { $0.rawValue < $1.rawValue }) {
                domainTerms.append("filter_metadata->secondaryDomains.cs.[\"\(domain.rawValue)\"]")
            }
            queryItems.append(URLQueryItem(name: "or", value: "(\(domainTerms.joined(separator: ",")))"))
        }
        
        if !query.selectedEras.isEmpty {
            let includesLiving = query.selectedEras.contains(.living)
            let historicalPeriods: [HistoricalPeriod] = query.selectedEras
                .filter { $0 != .living }
                .flatMap(Self.historicalPeriods(for:))
            let periodValues = Set(historicalPeriods).map(\.rawValue).sorted().joined(separator: ",")
            
            if includesLiving && query.selectedEras.count == 1 {
                queryItems.append(URLQueryItem(name: "death_date", value: "is.null"))
            } else if !periodValues.isEmpty {
                queryItems.append(URLQueryItem(name: "filter_metadata->>historicalPeriod", value: "in.(\(periodValues))"))
            }
        }
        
        let sortColumn: String
        switch query.sortBy {
        case .name:
            sortColumn = "name"
        case .birthYear:
            sortColumn = "filter_metadata->>birthYear"
        case .deathYear:
            sortColumn = "filter_metadata->>deathYear"
        case .recognitionLevel:
            sortColumn = "filter_metadata->>recognitionLevel"
        case .domainCount:
            sortColumn = "view_count"
        case .createdAt:
            sortColumn = "created_at"
        }
        
        let direction = query.sortDirection == .ascending ? "asc" : "desc"
        queryItems.append(URLQueryItem(name: "order", value: "\(sortColumn).\(direction).nullslast"))
        
        queryItems.append(URLQueryItem(name: "limit", value: String(query.pageSize)))
        queryItems.append(URLQueryItem(name: "offset", value: String((query.page - 1) * query.pageSize)))
        
        return queryItems
    }
    
    private static func historicalPeriods(for era: Era) -> [HistoricalPeriod] {
        switch era {
        case .ancient:
            return [.ancientWorld]
        case .medieval:
            return [.medieval]
        case .earlyModern:
            return [.renaissance, .enlightenment]
        case .modern:
            return [.industrial, .modernEra]
        case .contemporary:
            return [.coldWar, .digitalAge]
        case .living:
            return []
        }
    }
    
    // MARK: - Public Methods
    
    /// Search for existing people by name (case-insensitive partial match)
    /// - Parameter query: The name to search for
    /// - Returns: Array of matching Person objects
    func searchPeople(byName query: String) async throws -> [Person] {
        try requireConfiguration()
        
        // Encode the query for URL, using ilike for case-insensitive partial matching
        let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
        guard !trimmedQuery.isEmpty else { return [] }
        
        // URL encode the query
        guard let encodedQuery = trimmedQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return []
        }
        
        let url = try makeURL(
            pathAndQuery: "/rest/v1/people?name=ilike.*\(encodedQuery)*&order=created_at.desc"
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyCommonHeaders(to: &request)
        
        var responseData = Data()
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            responseData = data
            try validateResponse(response, data: data, expectedStatusCodes: [200])
            
            let supabasePeople = try decoder.decode([SupabasePerson].self, from: data)
            return supabasePeople.map { $0.toPerson() }
            
        } catch let error as SupabaseError {
            throw error
        } catch let decodingError as DecodingError {
            #if DEBUG
            print("[SupabaseService] Decoding error in searchPeople: \(decodingError)")
            print("[SupabaseService] Raw response: \(String(data: responseData, encoding: .utf8) ?? "nil")")
            #endif
            throw SupabaseError.decodingFailed(decodingError.localizedDescription)
        } catch let error {
            try rethrowCancellationIfNeeded(error)
            throw SupabaseError.networkError(error)
        }
    }

    /// Find the first existing person whose normalized name exactly matches the query.
    /// Candidate retrieval still uses partial matching for broad server-side lookup.
    func findExistingPerson(matchingName query: String) async throws -> Person? {
        let normalizedQuery = normalizePersonName(query)
        guard !normalizedQuery.isEmpty else { return nil }

        let candidates = try await searchPeople(byName: query)
        return candidates.first { candidate in
            normalizePersonName(candidate.name) == normalizedQuery
        }
    }
    
    /// Search for existing people by name and return relevance-ranked suggestions.
    /// - Parameters:
    ///   - query: The partial name to search for.
    ///   - limit: The max number of ranked suggestions to return.
    /// - Returns: Array of matching Person objects sorted by relevance.
    func searchPeopleForNameSuggestions(query: String, limit: Int = 12) async throws -> [Person] {
        try requireConfiguration()
        
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return [] }
        
        let safeLimit = max(1, min(limit, 20))
        
        guard let encodedQuery = trimmedQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return []
        }
        
        let url = try makeURL(
            pathAndQuery: "/rest/v1/people?name=ilike.*\(encodedQuery)*&limit=\(safeLimit)&order=created_at.desc"
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyCommonHeaders(to: &request)
        
        var responseData = Data()
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            responseData = data
            try validateResponse(response, data: data, expectedStatusCodes: [200])
            
            let supabasePeople = try decoder.decode([SupabasePerson].self, from: data)
            let rankedPeople = supabasePeople
                .map { $0.toPerson() }
                .sorted { left, right in
                    let leftScore = suggestionRelevanceScore(for: left, query: trimmedQuery)
                    let rightScore = suggestionRelevanceScore(for: right, query: trimmedQuery)
                    
                    if leftScore != rightScore { return leftScore > rightScore }
                    if left.viewCount != right.viewCount { return left.viewCount > right.viewCount }
                    if left.createdAt != right.createdAt { return left.createdAt > right.createdAt }
                    return left.name.localizedCaseInsensitiveCompare(right.name) == .orderedAscending
                }
            
            return Array(rankedPeople.prefix(safeLimit))
            
        } catch let error as SupabaseError {
            throw error
        } catch let decodingError as DecodingError {
            #if DEBUG
            print("[SupabaseService] Decoding error in searchPeopleForNameSuggestions: \(decodingError)")
            print("[SupabaseService] Raw response: \(String(data: responseData, encoding: .utf8) ?? "nil")")
            #endif
            throw SupabaseError.decodingFailed(decodingError.localizedDescription)
        } catch let error {
            try rethrowCancellationIfNeeded(error)
            throw SupabaseError.networkError(error)
        }
    }
    
    /// Fetch all people from the database
    /// - Returns: Array of Person objects sorted by creation date (newest first)
    func fetchPeople() async throws -> [Person] {
        let page = try await fetchPeople(query: PeopleQuery())
        return page.people
    }
    
    /// Unified people query endpoint for search, filters, sort, and pagination.
    func fetchPeople(query: PeopleQuery) async throws -> PeoplePage {
        try requireConfiguration()
        
        guard var components = URLComponents(string: "\(baseSupabaseURL)/rest/v1/people") else {
            throw SupabaseError.invalidURL
        }
        
        components.queryItems = makePeopleQueryItems(from: query)
        
        guard let url = components.url else {
            throw SupabaseError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyCommonHeaders(to: &request)
        request.setValue("count=exact", forHTTPHeaderField: "Prefer")
        
        var responseData = Data()
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            responseData = data
            try validateResponse(response, data: data, expectedStatusCodes: [200])
            
            let supabasePeople = try decoder.decode([SupabasePerson].self, from: data)
            let people = supabasePeople.map { $0.toPerson() }
            let totalCount = parseTotalCount(from: response)
            let hasMore: Bool
            if let totalCount {
                let consumed = ((query.page - 1) * query.pageSize) + people.count
                hasMore = consumed < totalCount
            } else {
                hasMore = people.count == query.pageSize
            }
            
            return PeoplePage(
                people: people,
                page: query.page,
                pageSize: query.pageSize,
                totalCount: totalCount,
                hasMore: hasMore
            )
            
        } catch let error as SupabaseError {
            throw error
        } catch let decodingError as DecodingError {
            #if DEBUG
            print("[SupabaseService] Decoding error in fetchPeople: \(decodingError)")
            print("[SupabaseService] Raw response: \(String(data: responseData, encoding: .utf8) ?? "nil")")
            #endif
            throw SupabaseError.decodingFailed(decodingError.localizedDescription)
        } catch let error {
            try rethrowCancellationIfNeeded(error)
            throw SupabaseError.networkError(error)
        }
    }
    
    /// Fetch people with server-side filtering by domain
    /// - Parameter domain: The domain to filter by
    /// - Returns: Array of Person objects with matching primary domain
    func fetchPeople(byDomain domain: Domain) async throws -> [Person] {
        try requireConfiguration()
        
        // Use JSONB filtering: filter_metadata->>'primaryDomain' = 'science'
        let domainFilter = "filter_metadata->>primaryDomain=eq.\(domain.rawValue)"
        let url = try makeURL(pathAndQuery: "/rest/v1/people?\(domainFilter)&order=created_at.desc")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyCommonHeaders(to: &request)
        
        var responseData = Data()
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            responseData = data
            try validateResponse(response, data: data, expectedStatusCodes: [200])
            
            let supabasePeople = try decoder.decode([SupabasePerson].self, from: data)
            return supabasePeople.map { $0.toPerson() }
            
        } catch let error as SupabaseError {
            throw error
        } catch let decodingError as DecodingError {
            #if DEBUG
            print("[SupabaseService] Decoding error in fetchPeople(byDomain:): \(decodingError)")
            print("[SupabaseService] Raw response: \(String(data: responseData, encoding: .utf8) ?? "nil")")
            #endif
            throw SupabaseError.decodingFailed(decodingError.localizedDescription)
        } catch let error {
            try rethrowCancellationIfNeeded(error)
            throw SupabaseError.networkError(error)
        }
    }
    
    /// Update a person's filter metadata
    /// - Parameters:
    ///   - id: The person's ID
    ///   - metadata: The new filter metadata
    func updateFilterMetadata(id: UUID, metadata: FilterMetadata) async throws {
        try requireConfiguration()
        let url = try makeURL(pathAndQuery: "/rest/v1/people?id=eq.\(id.uuidString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        applyCommonHeaders(to: &request)
        
        // Encode just the filter_metadata field
        struct MetadataUpdate: Codable {
            let filterMetadata: FilterMetadata
            
            enum CodingKeys: String, CodingKey {
                case filterMetadata = "filter_metadata"
            }
        }
        
        let updateData = MetadataUpdate(filterMetadata: metadata)
        request.httpBody = try encoder.encode(updateData)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            try validateResponse(response, data: data, expectedStatusCodes: [200, 204])
        } catch let error as SupabaseError {
            throw error
        } catch let error {
            try rethrowCancellationIfNeeded(error)
            throw SupabaseError.networkError(error)
        }
    }
    
    /// Save a new person to the database
    func savePerson(_ person: Person) async throws -> Person {
        try requireConfiguration()
        let url = try makeURL(pathAndQuery: "/rest/v1/people")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyCommonHeaders(to: &request)
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        
        let insertData = PersonInsert(from: person)
        request.httpBody = try encoder.encode(insertData)
        
        var responseData = Data()
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            responseData = data
            try validateResponse(response, data: data, expectedStatusCodes: [201])
            
            let savedPeople = try decoder.decode([SupabasePerson].self, from: data)
            guard let savedPerson = savedPeople.first else {
                throw SupabaseError.invalidResponse
            }
            
            return savedPerson.toPerson()
            
        } catch let error as SupabaseError {
            throw error
        } catch let decodingError as DecodingError {
            #if DEBUG
            print("[SupabaseService] Decoding error in savePerson: \(decodingError)")
            print("[SupabaseService] Raw response: \(String(data: responseData, encoding: .utf8) ?? "nil")")
            #endif
            throw SupabaseError.decodingFailed(decodingError.localizedDescription)
        } catch let error {
            try rethrowCancellationIfNeeded(error)
            throw SupabaseError.networkError(error)
        }
    }
    
    /// Delete a person from the database
    func deletePerson(id: UUID) async throws {
        try requireConfiguration()
        let url = try makeURL(pathAndQuery: "/rest/v1/people?id=eq.\(id.uuidString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        applyCommonHeaders(to: &request)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            try validateResponse(response, data: data, expectedStatusCodes: [200, 204])
        } catch let error as SupabaseError {
            throw error
        } catch let error {
            try rethrowCancellationIfNeeded(error)
            throw SupabaseError.networkError(error)
        }
    }
    
    /// Increment the view count for a person
    /// Called when a user views a person's detail page
    func incrementViewCount(id: UUID) async throws {
        try requireConfiguration()
        
        // Use Supabase RPC to atomically increment view_count
        // First, we need to fetch current value, then update
        let url = try makeURL(pathAndQuery: "/rest/v1/people?id=eq.\(id.uuidString)")
        
        // First fetch the current view count
        var getRequest = URLRequest(url: url)
        getRequest.httpMethod = "GET"
        applyCommonHeaders(to: &getRequest)
        
        var responseData = Data()
        do {
            let (getData, getResponse) = try await URLSession.shared.data(for: getRequest)
            responseData = getData
            try validateResponse(getResponse, data: getData, expectedStatusCodes: [200])
            
            let people = try decoder.decode([SupabasePerson].self, from: getData)
            guard let person = people.first else {
                throw SupabaseError.invalidResponse
            }
            
            let newViewCount = (person.viewCount ?? 0) + 1
            
            // Now update with incremented count
            var patchRequest = URLRequest(url: url)
            patchRequest.httpMethod = "PATCH"
            applyCommonHeaders(to: &patchRequest)
            
            let updateData: [String: Any] = [
                "view_count": newViewCount,
                "last_viewed_at": ISO8601DateFormatter().string(from: Date())
            ]
            patchRequest.httpBody = try JSONSerialization.data(withJSONObject: updateData)
            
            let (patchData, patchResponse) = try await URLSession.shared.data(for: patchRequest)
            try validateResponse(patchResponse, data: patchData, expectedStatusCodes: [200, 204])
            
        } catch let error as SupabaseError {
            throw error
        } catch let decodingError as DecodingError {
            #if DEBUG
            print("[SupabaseService] Decoding error in incrementViewCount: \(decodingError)")
            print("[SupabaseService] Raw response: \(String(data: responseData, encoding: .utf8) ?? "nil")")
            #endif
            throw SupabaseError.decodingFailed(decodingError.localizedDescription)
        } catch let error {
            try rethrowCancellationIfNeeded(error)
            throw SupabaseError.networkError(error)
        }
    }
}
