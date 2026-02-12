//
//  Source.swift
//  life-encyclopedia
//
//  Data models for sources and citations
//

import Foundation

// MARK: - Source Type

enum SourceType: String, Codable, CaseIterable {
    case wikipedia
    case news
    case academic
    case biography
    case official
    case archive
    case encyclopedia
    case wikidata
    case knowledgeGraph
    case unknown
    
    var displayName: String {
        switch self {
        case .wikipedia: return "Wikipedia"
        case .news: return "News"
        case .academic: return "Academic"
        case .biography: return "Biography"
        case .official: return "Official"
        case .archive: return "Archive"
        case .encyclopedia: return "Encyclopedia"
        case .wikidata: return "Wikidata"
        case .knowledgeGraph: return "Knowledge Graph"
        case .unknown: return "Other"
        }
    }
    
    var iconName: String {
        switch self {
        case .wikipedia: return "globe"
        case .news: return "newspaper"
        case .academic: return "graduationcap"
        case .biography: return "person.text.rectangle"
        case .official: return "building.columns"
        case .archive: return "archivebox"
        case .encyclopedia: return "books.vertical"
        case .wikidata: return "list.bullet.rectangle"
        case .knowledgeGraph: return "brain"
        case .unknown: return "link"
        }
    }
    
    /// Base reliability score for this source type (can be modified by domain)
    var baseReliabilityScore: Double {
        switch self {
        case .official: return 0.95
        case .wikidata: return 0.90
        case .academic: return 0.90
        case .knowledgeGraph: return 0.88
        case .encyclopedia: return 0.85
        case .wikipedia: return 0.80
        case .biography: return 0.75
        case .archive: return 0.75
        case .news: return 0.70
        case .unknown: return 0.50
        }
    }
}

// MARK: - Source

struct Source: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let title: String
    let url: String
    let sourceType: SourceType
    let publisher: String?
    let author: String?
    let publishDate: String?
    let accessDate: Date
    let reliabilityScore: Double
    let contentSnippet: String?
    let relevantQuote: String?
    let deepLinkURL: String?
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case url
        case sourceType
        case publisher
        case author
        case publishDate
        case accessDate
        case reliabilityScore
        case contentSnippet
        case relevantQuote
        case deepLinkURL
    }
    
    private enum LegacyCodingKeys: String, CodingKey {
        case relevantQuote = "relevant_quote"
        case deepLinkURL = "deep_link_url"
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        url: String,
        sourceType: SourceType = .unknown,
        publisher: String? = nil,
        author: String? = nil,
        publishDate: String? = nil,
        accessDate: Date = Date(),
        reliabilityScore: Double = 0.5,
        contentSnippet: String? = nil,
        relevantQuote: String? = nil,
        deepLinkURL: String? = nil
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.sourceType = sourceType
        self.publisher = publisher
        self.author = author
        self.publishDate = publishDate
        self.accessDate = accessDate
        self.reliabilityScore = min(1.0, max(0.0, reliabilityScore))
        self.contentSnippet = contentSnippet
        self.relevantQuote = relevantQuote
        self.deepLinkURL = deepLinkURL
    }
    
    // MARK: - Custom Decoder (handles legacy data without all fields)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let legacyContainer = try decoder.container(keyedBy: LegacyCodingKeys.self)
        
        // Required fields with defaults
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Unknown Source"
        self.url = try container.decodeIfPresent(String.self, forKey: .url) ?? ""
        
        // Optional and defaultable fields
        self.sourceType = try container.decodeIfPresent(SourceType.self, forKey: .sourceType) ?? .unknown
        self.publisher = try container.decodeIfPresent(String.self, forKey: .publisher)
        self.author = try container.decodeIfPresent(String.self, forKey: .author)
        self.publishDate = try container.decodeIfPresent(String.self, forKey: .publishDate)
        self.accessDate = try container.decodeIfPresent(Date.self, forKey: .accessDate) ?? Date()
        let rawScore = try container.decodeIfPresent(Double.self, forKey: .reliabilityScore) ?? 0.5
        self.reliabilityScore = min(1.0, max(0.0, rawScore))
        self.contentSnippet = try container.decodeIfPresent(String.self, forKey: .contentSnippet)
        self.relevantQuote = try container.decodeIfPresent(String.self, forKey: .relevantQuote)
            ?? legacyContainer.decodeIfPresent(String.self, forKey: .relevantQuote)
        self.deepLinkURL = try container.decodeIfPresent(String.self, forKey: .deepLinkURL)
            ?? legacyContainer.decodeIfPresent(String.self, forKey: .deepLinkURL)
    }
    
    /// Create a Source from a TavilySearchResult
    static func fromTavilyResult(_ result: TavilySearchResult, reliabilityScore: Double = 0.5, sourceType: SourceType = .unknown) -> Source {
        Source(
            title: result.title,
            url: result.url,
            sourceType: sourceType,
            reliabilityScore: reliabilityScore,
            contentSnippet: result.content,
            relevantQuote: result.content
        )
    }
    
    /// Extract the domain from the URL
    var domain: String? {
        guard let urlObj = URL(string: url),
              let host = urlObj.host else {
            return nil
        }
        return host.replacingOccurrences(of: "www.", with: "")
    }
    
    /// Reliability tier for UI display
    var reliabilityTier: ReliabilityTier {
        switch reliabilityScore {
        case 0.85...1.0: return .high
        case 0.65..<0.85: return .medium
        default: return .low
        }
    }
}

// MARK: - Reliability Tier

enum ReliabilityTier: String, Codable {
    case high
    case medium
    case low
    
    var displayName: String {
        switch self {
        case .high: return "Highly Reliable"
        case .medium: return "Moderately Reliable"
        case .low: return "Less Reliable"
        }
    }
    
    var iconName: String {
        switch self {
        case .high: return "checkmark.shield.fill"
        case .medium: return "checkmark.shield"
        case .low: return "shield"
        }
    }
    
    var color: String {
        switch self {
        case .high: return "Success"
        case .medium: return "Info"
        case .low: return "Warning"
        }
    }
}

// MARK: - Event Type

enum EventType: String, Codable, CaseIterable {
    case birth
    case childhood
    case education
    case career
    case personal
    case achievement
    case death
    case historical
    
    var displayName: String {
        switch self {
        case .birth: return "Birth"
        case .childhood: return "Childhood"
        case .education: return "Education"
        case .career: return "Career"
        case .personal: return "Personal"
        case .achievement: return "Achievement"
        case .death: return "Death"
        case .historical: return "Historical"
        }
    }
    
    var iconName: String {
        switch self {
        case .birth: return "star.fill"
        case .childhood: return "figure.and.child.holdinghands"
        case .education: return "graduationcap"
        case .career: return "briefcase"
        case .personal: return "heart"
        case .achievement: return "trophy"
        case .death: return "leaf"
        case .historical: return "clock"
        }
    }
    
    var color: String {
        switch self {
        case .birth: return "Success"
        case .childhood: return "Info"
        case .education: return "BrandPrimary"
        case .career: return "BrandSecondary"
        case .personal: return "Danger"
        case .achievement: return "Warning"
        case .death: return "Info"
        case .historical: return "BrandPrimary"
        }
    }
}

// MARK: - Date Precision

enum DatePrecision: String, Codable, CaseIterable {
    case exact          // "March 14, 1879"
    case monthYear      // "March 1879"
    case yearOnly       // "1879"
    case approximate    // "circa 1879"
    case decade         // "1870s"
    case unknown
    
    var displayName: String {
        switch self {
        case .exact: return "Exact Date"
        case .monthYear: return "Month & Year"
        case .yearOnly: return "Year Only"
        case .approximate: return "Approximate"
        case .decade: return "Decade"
        case .unknown: return "Unknown"
        }
    }
    
    var iconName: String {
        switch self {
        case .exact: return "calendar"
        case .monthYear: return "calendar.badge.clock"
        case .yearOnly: return "calendar.badge.minus"
        case .approximate: return "questionmark.circle"
        case .decade: return "calendar.badge.exclamationmark"
        case .unknown: return "questionmark"
        }
    }
}

// MARK: - Supabase Source Model

struct SupabaseSource: Codable {
    let id: UUID
    let title: String
    let url: String
    let sourceType: String
    let publisher: String?
    let author: String?
    let publishDate: String?
    let accessDate: Date
    let reliabilityScore: Double
    let contentSnippet: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case url
        case sourceType = "source_type"
        case publisher
        case author
        case publishDate = "publish_date"
        case accessDate = "access_date"
        case reliabilityScore = "reliability_score"
        case contentSnippet = "content_snippet"
        case createdAt = "created_at"
    }
    
    func toSource() -> Source {
        Source(
            id: id,
            title: title,
            url: url,
            sourceType: SourceType(rawValue: sourceType) ?? .unknown,
            publisher: publisher,
            author: author,
            publishDate: publishDate,
            accessDate: accessDate,
            reliabilityScore: reliabilityScore,
            contentSnippet: contentSnippet
        )
    }
}

// MARK: - Source Insert Model (for Supabase)

struct SourceInsert: Codable {
    let title: String
    let url: String
    let sourceType: String
    let publisher: String?
    let author: String?
    let publishDate: String?
    let reliabilityScore: Double
    let contentSnippet: String?
    
    enum CodingKeys: String, CodingKey {
        case title
        case url
        case sourceType = "source_type"
        case publisher
        case author
        case publishDate = "publish_date"
        case reliabilityScore = "reliability_score"
        case contentSnippet = "content_snippet"
    }
    
    init(from source: Source) {
        self.title = source.title
        self.url = source.url
        self.sourceType = source.sourceType.rawValue
        self.publisher = source.publisher
        self.author = source.author
        self.publishDate = source.publishDate
        self.reliabilityScore = source.reliabilityScore
        self.contentSnippet = source.contentSnippet
    }
}
