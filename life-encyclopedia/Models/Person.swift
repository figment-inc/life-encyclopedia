//
//  Person.swift
//  life-encyclopedia
//
//  Data models for people and their historical events
//

import Foundation

// MARK: - Filter Metadata

/// Comprehensive metadata for filtering and categorizing historical figures
struct FilterMetadata: Codable, Equatable {
    // Core Identity
    var birthYear: Int?
    var deathYear: Int?
    var birthplace: Birthplace?
    var nationality: [String]
    var culturalRegion: CulturalRegion?
    var century: Int?
    var historicalPeriod: HistoricalPeriod?
    
    // Domain of Impact
    var primaryDomain: Domain?
    var secondaryDomains: [Domain]
    var subRole: String?
    
    // Type of Influence (scored 0-5)
    var influenceModes: [String: Int]
    
    // Scale & Reach
    var geographicReach: GeographicReach?
    var influenceLongevity: InfluenceLongevity?
    var recognitionLevel: RecognitionLevel?
    
    // Narrative
    var archetype: Archetype?
    var moralValence: MoralValence?
    var lifeArc: LifeArc?
    
    init(
        birthYear: Int? = nil,
        deathYear: Int? = nil,
        birthplace: Birthplace? = nil,
        nationality: [String] = [],
        culturalRegion: CulturalRegion? = nil,
        century: Int? = nil,
        historicalPeriod: HistoricalPeriod? = nil,
        primaryDomain: Domain? = nil,
        secondaryDomains: [Domain] = [],
        subRole: String? = nil,
        influenceModes: [String: Int] = [:],
        geographicReach: GeographicReach? = nil,
        influenceLongevity: InfluenceLongevity? = nil,
        recognitionLevel: RecognitionLevel? = nil,
        archetype: Archetype? = nil,
        moralValence: MoralValence? = nil,
        lifeArc: LifeArc? = nil
    ) {
        self.birthYear = birthYear
        self.deathYear = deathYear
        self.birthplace = birthplace
        self.nationality = nationality
        self.culturalRegion = culturalRegion
        self.century = century
        self.historicalPeriod = historicalPeriod
        self.primaryDomain = primaryDomain
        self.secondaryDomains = secondaryDomains
        self.subRole = subRole
        self.influenceModes = influenceModes
        self.geographicReach = geographicReach
        self.influenceLongevity = influenceLongevity
        self.recognitionLevel = recognitionLevel
        self.archetype = archetype
        self.moralValence = moralValence
        self.lifeArc = lifeArc
    }
    
    /// Empty metadata for new/unprocessed people
    static let empty = FilterMetadata()
    
    /// Check if the person is still living
    var isLiving: Bool {
        deathYear == nil
    }
    
    /// All domains (primary + secondary)
    var allDomains: [Domain] {
        var domains: [Domain] = []
        if let primary = primaryDomain {
            domains.append(primary)
        }
        domains.append(contentsOf: secondaryDomains)
        return domains
    }
    
    /// Get influence score for a specific mode
    func influenceScore(for mode: InfluenceMode) -> Int {
        influenceModes[mode.rawValue] ?? 0
    }
    
    /// Check if person matches a domain (including secondary if specified)
    func matchesDomain(_ domain: Domain, includeSecondary: Bool = true) -> Bool {
        if primaryDomain == domain { return true }
        if includeSecondary && secondaryDomains.contains(domain) { return true }
        return false
    }
    
    // MARK: - Simplified Filter Helpers
    
    /// Computed era from birth year or historical period
    var era: Era? {
        if isLiving { return .living }
        if let year = birthYear {
            return Era.from(birthYear: year)
        }
        if let period = historicalPeriod {
            return Era.from(period)
        }
        return nil
    }
    
    /// Computed impact level from reach, recognition, and longevity
    var impactLevel: ImpactLevel {
        ImpactLevel.from(
            reach: geographicReach,
            recognition: recognitionLevel,
            longevity: influenceLongevity
        )
    }
}

// MARK: - FilterMetadata + Hashable

extension FilterMetadata: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(birthYear)
        hasher.combine(deathYear)
        hasher.combine(birthplace)
        hasher.combine(nationality)
        hasher.combine(culturalRegion)
        hasher.combine(century)
        hasher.combine(historicalPeriod)
        hasher.combine(primaryDomain)
        hasher.combine(secondaryDomains)
        hasher.combine(subRole)
        hasher.combine(geographicReach)
        hasher.combine(influenceLongevity)
        hasher.combine(recognitionLevel)
        hasher.combine(archetype)
        hasher.combine(moralValence)
        hasher.combine(lifeArc)
        // Hash the dictionary by sorting keys for consistent ordering
        for key in influenceModes.keys.sorted() {
            hasher.combine(key)
            hasher.combine(influenceModes[key])
        }
    }
}

// MARK: - Person

struct Person: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let name: String
    let birthDate: String?
    let deathDate: String?
    let summary: String
    let events: [HistoricalEvent]
    let createdAt: Date
    var filterMetadata: FilterMetadata
    let viewCount: Int
    let lastViewedAt: Date?
    
    init(
        id: UUID = UUID(),
        name: String,
        birthDate: String? = nil,
        deathDate: String? = nil,
        summary: String,
        events: [HistoricalEvent],
        createdAt: Date = Date(),
        filterMetadata: FilterMetadata = .empty,
        viewCount: Int = 0,
        lastViewedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.birthDate = birthDate
        self.deathDate = deathDate
        self.summary = summary
        self.events = events
        self.createdAt = createdAt
        self.filterMetadata = filterMetadata
        self.viewCount = viewCount
        self.lastViewedAt = lastViewedAt
    }
    
    /// Formatted life span string (e.g., "1879 - 1955")
    var lifeSpan: String? {
        guard let birth = birthDate else { return nil }
        if let death = deathDate {
            return "\(birth) - \(death)"
        }
        return "\(birth) - Present"
    }
    
    /// Check if the person is still living
    var isLiving: Bool {
        deathDate == nil || deathDate?.lowercased() == "present"
    }
    
    /// Create a copy with updated filter metadata
    func withFilterMetadata(_ metadata: FilterMetadata) -> Person {
        Person(
            id: id,
            name: name,
            birthDate: birthDate,
            deathDate: deathDate,
            summary: summary,
            events: events,
            createdAt: createdAt,
            filterMetadata: metadata,
            viewCount: viewCount,
            lastViewedAt: lastViewedAt
        )
    }
    
    /// Calculate trending score (views per day since creation)
    var trendingScore: Double {
        let daysSinceCreation = max(1, Date().timeIntervalSince(createdAt) / 86400)
        return Double(viewCount) / daysSinceCreation
    }
}

// MARK: - Historical Event

struct HistoricalEvent: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let date: String
    let title: String
    let description: String
    let citation: String?
    let sourceURL: String?
    
    // Event metadata
    let eventType: EventType
    let datePrecision: DatePrecision
    let sources: [Source]
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case id
        case date
        case title
        case description
        case citation
        case sourceURL
        case eventType
        case datePrecision
        case sources
    }
    
    init(
        id: UUID = UUID(),
        date: String,
        title: String,
        description: String,
        citation: String? = nil,
        sourceURL: String? = nil,
        eventType: EventType = .historical,
        datePrecision: DatePrecision = .unknown,
        sources: [Source] = []
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.description = description
        self.citation = citation
        self.sourceURL = sourceURL
        self.eventType = eventType
        self.datePrecision = datePrecision
        self.sources = sources
    }
    
    // MARK: - Custom Decoder (handles legacy data without enhanced fields)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.date = try container.decode(String.self, forKey: .date)
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decode(String.self, forKey: .description)
        
        // Optional fields
        self.citation = try container.decodeIfPresent(String.self, forKey: .citation)
        self.sourceURL = try container.decodeIfPresent(String.self, forKey: .sourceURL)
        
        // Enhanced fields with defaults (may not exist in legacy database records)
        self.eventType = try container.decodeIfPresent(EventType.self, forKey: .eventType) ?? .historical
        self.datePrecision = try container.decodeIfPresent(DatePrecision.self, forKey: .datePrecision) ?? .unknown
        self.sources = try container.decodeIfPresent([Source].self, forKey: .sources) ?? []
    }
    
    /// Extract the year from the date string
    /// Handles formats like "March 14, 1879", "1905", "Summer 1923", etc.
    var year: Int? {
        // Try to find a 4-digit year in the date string
        let pattern = "\\b(1[0-9]{3}|20[0-9]{2})\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                in: date,
                range: NSRange(date.startIndex..., in: date)
              ),
              let range = Range(match.range, in: date) else {
            return nil
        }
        return Int(date[range])
    }
    
    /// Check if the event has a valid citation
    var hasCitation: Bool {
        guard let citation else { return false }
        return !citation.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    /// Check if the event has multiple sources
    var hasMultipleSources: Bool {
        sources.count > 1
    }
    
    /// Get the primary source (highest reliability)
    var primarySource: Source? {
        sources.max(by: { $0.reliabilityScore < $1.reliabilityScore })
    }
}

// MARK: - Supabase Response Model

struct SupabasePerson: Codable {
    let id: UUID
    let name: String
    let birthDate: String?
    let deathDate: String?
    let summary: String
    let events: [HistoricalEvent]
    let createdAt: Date
    let filterMetadata: FilterMetadata?
    let viewCount: Int?
    let lastViewedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case birthDate = "birth_date"
        case deathDate = "death_date"
        case summary
        case events
        case createdAt = "created_at"
        case filterMetadata = "filter_metadata"
        case viewCount = "view_count"
        case lastViewedAt = "last_viewed_at"
    }
    
    func toPerson() -> Person {
        Person(
            id: id,
            name: name,
            birthDate: birthDate,
            deathDate: deathDate,
            summary: summary,
            events: events,
            createdAt: createdAt,
            filterMetadata: filterMetadata ?? .empty,
            viewCount: viewCount ?? 0,
            lastViewedAt: lastViewedAt
        )
    }
}

// MARK: - Person Insert Model (for Supabase)

struct PersonInsert: Codable {
    let name: String
    let birthDate: String?
    let deathDate: String?
    let summary: String
    let events: [HistoricalEvent]
    let filterMetadata: FilterMetadata
    
    enum CodingKeys: String, CodingKey {
        case name
        case birthDate = "birth_date"
        case deathDate = "death_date"
        case summary
        case events
        case filterMetadata = "filter_metadata"
    }
    
    init(from person: Person) {
        self.name = person.name
        self.birthDate = person.birthDate
        self.deathDate = person.deathDate
        self.summary = person.summary
        self.events = person.events
        self.filterMetadata = person.filterMetadata
    }
}

// MARK: - Tavily Search Result

struct TavilySearchResult: Codable {
    let title: String
    let url: String
    let content: String
    let score: Double
}

struct TavilyResponse: Codable {
    let query: String
    let results: [TavilySearchResult]
}

// MARK: - Person Verification Result

struct PersonVerification {
    let isVerified: Bool
    let name: String
    let summary: String
    let sources: [TavilySearchResult]
    let isFictional: Bool
    
    init(
        isVerified: Bool,
        name: String,
        summary: String,
        sources: [TavilySearchResult],
        isFictional: Bool = false
    ) {
        self.isVerified = isVerified
        self.name = name
        self.summary = summary
        self.sources = sources
        self.isFictional = isFictional
    }
    
    static let notFound = PersonVerification(
        isVerified: false,
        name: "",
        summary: "",
        sources: [],
        isFictional: false
    )
}
