//
//  FilterTypes.swift
//  life-encyclopedia
//
//  Filter system enums and types for categorizing historical figures
//

import Foundation

// MARK: - Domain of Impact

/// Primary domain a historical figure is known for
enum Domain: String, Codable, CaseIterable, Identifiable {
    case politics
    case science
    case business
    case arts
    case philosophy
    case military
    case religion
    case sports
    case entertainment
    case activism
    case technology
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .politics: return "Politics"
        case .science: return "Science"
        case .business: return "Business"
        case .arts: return "Arts"
        case .philosophy: return "Philosophy"
        case .military: return "Military"
        case .religion: return "Religion"
        case .sports: return "Sports"
        case .entertainment: return "Entertainment"
        case .activism: return "Activism"
        case .technology: return "Technology"
        }
    }
    
    var iconName: String {
        switch self {
        case .politics: return "building.columns"
        case .science: return "atom"
        case .business: return "chart.line.uptrend.xyaxis"
        case .arts: return "paintpalette"
        case .philosophy: return "brain.head.profile"
        case .military: return "shield"
        case .religion: return "sparkles"
        case .sports: return "figure.run"
        case .entertainment: return "film"
        case .activism: return "megaphone"
        case .technology: return "cpu"
        }
    }
}

// MARK: - Type of Influence

/// How a historical figure made their impact
enum InfluenceMode: String, Codable, CaseIterable, Identifiable {
    case intellectual
    case institutional
    case cultural
    case technological
    case political
    case military
    case symbolic
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .intellectual: return "Intellectual"
        case .institutional: return "Institutional"
        case .cultural: return "Cultural"
        case .technological: return "Technological"
        case .political: return "Political"
        case .military: return "Military"
        case .symbolic: return "Symbolic"
        }
    }
    
    var description: String {
        switch self {
        case .intellectual: return "Ideas, theories, writings"
        case .institutional: return "Built organizations, systems"
        case .cultural: return "Shaped taste, norms"
        case .technological: return "Invented or engineered"
        case .political: return "Laws, governance"
        case .military: return "Conflict, strategy"
        case .symbolic: return "Iconic, representative figure"
        }
    }
}

// MARK: - Scale & Reach

/// Geographic reach of influence
enum GeographicReach: String, Codable, CaseIterable, Identifiable {
    case local
    case national
    case regional
    case global
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .local: return "Local"
        case .national: return "National"
        case .regional: return "Regional"
        case .global: return "Global"
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .local: return 0
        case .national: return 1
        case .regional: return 2
        case .global: return 3
        }
    }
}

/// How long their influence lasted
enum InfluenceLongevity: String, Codable, CaseIterable, Identifiable {
    case shortLived
    case generational
    case multiCentury
    case ongoing
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .shortLived: return "Short-lived (<10 years)"
        case .generational: return "Generational"
        case .multiCentury: return "Multi-century"
        case .ongoing: return "Still ongoing"
        }
    }
}

/// Level of public recognition
enum RecognitionLevel: String, Codable, CaseIterable, Identifiable {
    case obscure
    case fieldFamous
    case publiclyFamous
    case canonical
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .obscure: return "Obscure"
        case .fieldFamous: return "Field-famous"
        case .publiclyFamous: return "Publicly famous"
        case .canonical: return "Canonical"
        }
    }
}

// MARK: - Narrative / Interpretive

/// Character archetype
enum Archetype: String, Codable, CaseIterable, Identifiable {
    case founder
    case reformer
    case rebel
    case tyrant
    case visionary
    case martyr
    case polymath
    case `operator`
    case tragicFigure
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .founder: return "Founder"
        case .reformer: return "Reformer"
        case .rebel: return "Rebel"
        case .tyrant: return "Tyrant"
        case .visionary: return "Visionary"
        case .martyr: return "Martyr"
        case .polymath: return "Polymath"
        case .operator: return "Operator"
        case .tragicFigure: return "Tragic Figure"
        }
    }
    
    var iconName: String {
        switch self {
        case .founder: return "hammer"
        case .reformer: return "arrow.triangle.2.circlepath"
        case .rebel: return "flame"
        case .tyrant: return "crown"
        case .visionary: return "eye"
        case .martyr: return "heart"
        case .polymath: return "star"
        case .operator: return "gearshape.2"
        case .tragicFigure: return "theatermasks"
        }
    }
}

/// Moral perception spectrum
enum MoralValence: String, Codable, CaseIterable, Identifiable {
    case widelyAdmired
    case contested
    case widelyCondemned
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .widelyAdmired: return "Widely Admired"
        case .contested: return "Contested"
        case .widelyCondemned: return "Widely Condemned"
        }
    }
}

/// Life trajectory pattern
enum LifeArc: String, Codable, CaseIterable, Identifiable {
    case steadyAscent
    case lateBlocker
    case riseAndFall
    case posthumousRecognition
    case unfulfilledPotential
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .steadyAscent: return "Steady Ascent"
        case .lateBlocker: return "Late Bloomer"
        case .riseAndFall: return "Rise and Fall"
        case .posthumousRecognition: return "Posthumous Recognition"
        case .unfulfilledPotential: return "Unfulfilled Potential"
        }
    }
}

// MARK: - Core Identity

/// Historical period/era
enum HistoricalPeriod: String, Codable, CaseIterable, Identifiable {
    case ancientWorld
    case medieval
    case renaissance
    case enlightenment
    case industrial
    case modernEra
    case coldWar
    case digitalAge
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .ancientWorld: return "Ancient World"
        case .medieval: return "Medieval"
        case .renaissance: return "Renaissance"
        case .enlightenment: return "Enlightenment"
        case .industrial: return "Industrial Era"
        case .modernEra: return "Modern Era"
        case .coldWar: return "Cold War"
        case .digitalAge: return "Digital Age"
        }
    }
    
    var yearRange: ClosedRange<Int> {
        switch self {
        case .ancientWorld: return -3000...500
        case .medieval: return 500...1400
        case .renaissance: return 1400...1600
        case .enlightenment: return 1600...1800
        case .industrial: return 1800...1914
        case .modernEra: return 1914...1945
        case .coldWar: return 1945...1991
        case .digitalAge: return 1991...2100
        }
    }
}

/// Cultural/geographic region
enum CulturalRegion: String, Codable, CaseIterable, Identifiable {
    case westernEurope
    case easternEurope
    case northAmerica
    case latinAmerica
    case eastAsia
    case southAsia
    case southeastAsia
    case middleEast
    case northAfrica
    case subSaharanAfrica
    case oceania
    case centralAsia
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .westernEurope: return "Western Europe"
        case .easternEurope: return "Eastern Europe"
        case .northAmerica: return "North America"
        case .latinAmerica: return "Latin America"
        case .eastAsia: return "East Asia"
        case .southAsia: return "South Asia"
        case .southeastAsia: return "Southeast Asia"
        case .middleEast: return "Middle East"
        case .northAfrica: return "North Africa"
        case .subSaharanAfrica: return "Sub-Saharan Africa"
        case .oceania: return "Oceania"
        case .centralAsia: return "Central Asia"
        }
    }
    
    var iconName: String {
        switch self {
        case .westernEurope, .easternEurope: return "globe.europe.africa"
        case .northAmerica, .latinAmerica: return "globe.americas"
        case .eastAsia, .southAsia, .southeastAsia, .centralAsia: return "globe.asia.australia"
        case .middleEast, .northAfrica, .subSaharanAfrica: return "globe.europe.africa"
        case .oceania: return "globe.asia.australia"
        }
    }
}

// MARK: - Birthplace

/// Structured location information
struct Birthplace: Codable, Equatable, Hashable {
    var city: String?
    var country: String?
    var continent: String?
    
    var displayName: String {
        [city, country].compactMap { $0 }.joined(separator: ", ")
    }
}

// MARK: - Simplified Era (Primary Filter)

/// Simplified era enum that combines historical periods with year ranges
/// Used as the primary time-based filter in the simplified filter UX
enum Era: String, Codable, CaseIterable, Identifiable {
    case ancient        // Before 500 CE
    case medieval       // 500-1500
    case earlyModern    // 1500-1800
    case modern         // 1800-1950
    case contemporary   // 1950-present
    case living         // Still alive (special filter)
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .ancient: return "Ancient"
        case .medieval: return "Medieval"
        case .earlyModern: return "Early Modern"
        case .modern: return "Modern"
        case .contemporary: return "Contemporary"
        case .living: return "Living"
        }
    }
    
    var subtitle: String {
        switch self {
        case .ancient: return "Before 500 CE"
        case .medieval: return "500–1500"
        case .earlyModern: return "1500–1800"
        case .modern: return "1800–1950"
        case .contemporary: return "1950–present"
        case .living: return "Still alive"
        }
    }
    
    var iconName: String {
        switch self {
        case .ancient: return "building.columns"
        case .medieval: return "shield"
        case .earlyModern: return "scroll"
        case .modern: return "gear"
        case .contemporary: return "airplane"
        case .living: return "heart.fill"
        }
    }
    
    var yearRange: ClosedRange<Int>? {
        switch self {
        case .ancient: return -3000...500
        case .medieval: return 500...1500
        case .earlyModern: return 1500...1800
        case .modern: return 1800...1950
        case .contemporary: return 1950...2100
        case .living: return nil // Special case - check isLiving instead
        }
    }
    
    /// Convert from legacy HistoricalPeriod
    static func from(_ period: HistoricalPeriod) -> Era {
        switch period {
        case .ancientWorld: return .ancient
        case .medieval: return .medieval
        case .renaissance, .enlightenment: return .earlyModern
        case .industrial, .modernEra: return .modern
        case .coldWar, .digitalAge: return .contemporary
        }
    }
    
    /// Get era from a birth year
    static func from(birthYear: Int) -> Era {
        switch birthYear {
        case ..<500: return .ancient
        case 500..<1500: return .medieval
        case 1500..<1800: return .earlyModern
        case 1800..<1950: return .modern
        default: return .contemporary
        }
    }
}

// MARK: - Impact Level (Simplified Scale)

/// Combined impact level that simplifies GeographicReach + Longevity + RecognitionLevel
/// into a single intuitive scale
enum ImpactLevel: String, Codable, CaseIterable, Identifiable {
    case emerging       // Local/obscure/short-lived
    case notable        // National/field-famous/generational
    case influential    // Regional/publicly famous/multi-century
    case legendary      // Global/canonical/ongoing
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .emerging: return "Emerging"
        case .notable: return "Notable"
        case .influential: return "Influential"
        case .legendary: return "Legendary"
        }
    }
    
    var subtitle: String {
        switch self {
        case .emerging: return "Local or niche influence"
        case .notable: return "Nationally recognized"
        case .influential: return "Widely known and impactful"
        case .legendary: return "Global, enduring legacy"
        }
    }
    
    var iconName: String {
        switch self {
        case .emerging: return "leaf"
        case .notable: return "star"
        case .influential: return "star.fill"
        case .legendary: return "crown"
        }
    }
    
    var sortValue: Int {
        switch self {
        case .emerging: return 0
        case .notable: return 1
        case .influential: return 2
        case .legendary: return 3
        }
    }
    
    /// Compute impact level from legacy filter values
    static func from(
        reach: GeographicReach?,
        recognition: RecognitionLevel?,
        longevity: InfluenceLongevity?
    ) -> ImpactLevel {
        // Calculate a score based on available data
        var score = 0
        var count = 0
        
        if let reach = reach {
            score += reach.sortOrder
            count += 1
        }
        
        if let recognition = recognition {
            switch recognition {
            case .obscure: score += 0
            case .fieldFamous: score += 1
            case .publiclyFamous: score += 2
            case .canonical: score += 3
            }
            count += 1
        }
        
        if let longevity = longevity {
            switch longevity {
            case .shortLived: score += 0
            case .generational: score += 1
            case .multiCentury: score += 2
            case .ongoing: score += 3
            }
            count += 1
        }
        
        guard count > 0 else { return .notable }
        
        let average = Double(score) / Double(count)
        
        switch average {
        case ..<1: return .emerging
        case 1..<2: return .notable
        case 2..<2.5: return .influential
        default: return .legendary
        }
    }
}

// MARK: - Advanced Filters Container

/// Container for advanced/power-user filters that are hidden by default
struct AdvancedFilters: Equatable {
    var archetypes: Set<Archetype> = []
    var moralValences: Set<MoralValence> = []
    var lifeArcs: Set<LifeArc> = []
    var influenceModes: Set<InfluenceMode> = []
    
    var isEmpty: Bool {
        archetypes.isEmpty && moralValences.isEmpty && lifeArcs.isEmpty && influenceModes.isEmpty
    }
    
    var activeCount: Int {
        archetypes.count + moralValences.count + lifeArcs.count + influenceModes.count
    }
    
    mutating func reset() {
        archetypes = []
        moralValences = []
        lifeArcs = []
        influenceModes = []
    }
}

// MARK: - Sorting Options

enum SortOption: String, Codable, CaseIterable, Identifiable {
    case birthYear
    case deathYear
    case name
    case createdAt
    case recognitionLevel
    case domainCount
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .birthYear: return "Birth Year"
        case .deathYear: return "Death Year"
        case .name: return "Name"
        case .createdAt: return "Recently Added"
        case .recognitionLevel: return "Recognition Level"
        case .domainCount: return "Multi-domain"
        }
    }
    
    var iconName: String {
        switch self {
        case .birthYear: return "calendar"
        case .deathYear: return "calendar.badge.clock"
        case .name: return "textformat.abc"
        case .createdAt: return "clock"
        case .recognitionLevel: return "star"
        case .domainCount: return "square.stack.3d.up"
        }
    }
}

enum SortDirection: String, Codable {
    case ascending
    case descending
    
    var displayName: String {
        switch self {
        case .ascending: return "Ascending"
        case .descending: return "Descending"
        }
    }
    
    var iconName: String {
        switch self {
        case .ascending: return "arrow.up"
        case .descending: return "arrow.down"
        }
    }
}
