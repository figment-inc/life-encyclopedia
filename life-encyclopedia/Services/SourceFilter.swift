//
//  SourceFilter.swift
//  life-encyclopedia
//
//  Service for filtering and scoring source reliability
//

import Foundation

// MARK: - Source Filter

struct SourceFilter {
    
    // MARK: - Authoritative Domains
    
    /// Domains considered highly authoritative for biographical/historical information
    static let authoritativeDomains: [String: (type: SourceType, score: Double)] = [
        // Encyclopedias (highest tier)
        "wikipedia.org": (.wikipedia, 0.85),
        "britannica.com": (.encyclopedia, 0.95),
        "encyclopedia.com": (.encyclopedia, 0.85),
        
        // Major News Outlets
        "nytimes.com": (.news, 0.90),
        "bbc.com": (.news, 0.90),
        "bbc.co.uk": (.news, 0.90),
        "theguardian.com": (.news, 0.85),
        "washingtonpost.com": (.news, 0.85),
        "reuters.com": (.news, 0.90),
        "apnews.com": (.news, 0.90),
        "npr.org": (.news, 0.85),
        "pbs.org": (.news, 0.85),
        "economist.com": (.news, 0.85),
        "time.com": (.news, 0.80),
        "theatlantic.com": (.news, 0.80),
        
        // Biography Sites
        "biography.com": (.biography, 0.80),
        "notablebiographies.com": (.biography, 0.70),
        "famousscientists.org": (.biography, 0.75),
        
        // Historical Archives
        "history.com": (.archive, 0.80),
        "archives.gov": (.official, 0.95),
        "loc.gov": (.official, 0.95),
        "nationalarchives.gov.uk": (.official, 0.95),
        
        // Academic/Educational
        "jstor.org": (.academic, 0.90),
        "scholar.google.com": (.academic, 0.85),
        "academia.edu": (.academic, 0.75),
        "researchgate.net": (.academic, 0.75),
        "pubmed.ncbi.nlm.nih.gov": (.academic, 0.90),
        
        // Official Government
        "whitehouse.gov": (.official, 0.95),
        "congress.gov": (.official, 0.95),
        "usa.gov": (.official, 0.90),
        "gov.uk": (.official, 0.90),
        
        // Nobel and Major Organizations
        "nobelprize.org": (.official, 0.95),
        "pulitzer.org": (.official, 0.95),
        "imdb.com": (.archive, 0.70),
        "grammy.com": (.official, 0.85),
        "oscars.org": (.official, 0.90),
    ]
    
    /// Domain suffixes that indicate authoritative sources
    static let authoritativeSuffixes: [(suffix: String, type: SourceType, score: Double)] = [
        (".edu", .academic, 0.85),
        (".gov", .official, 0.90),
        (".mil", .official, 0.85),
        (".ac.uk", .academic, 0.85),
        (".gov.uk", .official, 0.90),
    ]
    
    /// Domains to exclude (low reliability or inappropriate)
    static let excludedDomains: Set<String> = [
        "facebook.com",
        "twitter.com",
        "x.com",
        "instagram.com",
        "tiktok.com",
        "reddit.com",
        "pinterest.com",
        "tumblr.com",
        "quora.com",
        "answers.com",
        "wikihow.com",
        "ehow.com",
        "about.com",
        "buzzfeed.com",
        "dailymail.co.uk",
        "thesun.co.uk",
    ]
    
    // MARK: - Public Methods
    
    /// Filter results to only include authoritative sources
    /// - Parameter results: Array of Tavily search results
    /// - Returns: Filtered array containing only authoritative sources
    func filterAuthoritativeSources(_ results: [TavilySearchResult]) -> [TavilySearchResult] {
        results.filter { result in
            guard let domain = extractDomain(from: result.url) else { return false }
            
            // Exclude blacklisted domains
            if Self.excludedDomains.contains(domain) { return false }
            
            // Check if domain is in authoritative list
            if Self.authoritativeDomains[domain] != nil { return true }
            
            // Check for authoritative suffixes
            for (suffix, _, _) in Self.authoritativeSuffixes {
                if domain.hasSuffix(suffix) { return true }
            }
            
            return false
        }
    }
    
    /// Score the reliability of a search result
    /// - Parameter result: A Tavily search result
    /// - Returns: Reliability score from 0.0 to 1.0
    func scoreSourceReliability(_ result: TavilySearchResult) -> Double {
        guard let domain = extractDomain(from: result.url) else { return 0.3 }
        
        // Check exact domain match first
        if let domainInfo = Self.authoritativeDomains[domain] {
            return adjustScoreByContent(domainInfo.score, content: result.content)
        }
        
        // Check suffixes
        for (suffix, _, baseScore) in Self.authoritativeSuffixes {
            if domain.hasSuffix(suffix) {
                return adjustScoreByContent(baseScore, content: result.content)
            }
        }
        
        // Default score for non-authoritative sources
        return adjustScoreByContent(0.4, content: result.content)
    }
    
    /// Classify the source type based on URL
    /// - Parameter url: The URL string
    /// - Returns: The source type
    func classifySourceType(_ url: String) -> SourceType {
        guard let domain = extractDomain(from: url) else { return .unknown }
        
        // Check exact domain match
        if let domainInfo = Self.authoritativeDomains[domain] {
            return domainInfo.type
        }
        
        // Check suffixes
        for (suffix, type, _) in Self.authoritativeSuffixes {
            if domain.hasSuffix(suffix) {
                return type
            }
        }
        
        return .unknown
    }
    
    /// Convert Tavily results to Source objects with scoring
    /// - Parameter results: Array of Tavily search results
    /// - Returns: Array of Source objects sorted by reliability
    func convertToSources(_ results: [TavilySearchResult]) -> [Source] {
        results.map { result in
            let score = scoreSourceReliability(result)
            let type = classifySourceType(result.url)
            return Source.fromTavilyResult(result, reliabilityScore: score, sourceType: type)
        }
        .sorted { $0.reliabilityScore > $1.reliabilityScore }
    }
    
    /// Deduplicate sources by URL
    /// - Parameter sources: Array of sources that may contain duplicates
    /// - Returns: Deduplicated array
    func deduplicateSources(_ sources: [Source]) -> [Source] {
        var seenURLs = Set<String>()
        var uniqueSources: [Source] = []
        
        for source in sources {
            let normalizedURL = normalizeURL(source.url)
            if !seenURLs.contains(normalizedURL) {
                seenURLs.insert(normalizedURL)
                uniqueSources.append(source)
            }
        }
        
        return uniqueSources
    }
    
    /// Check if a URL is from an authoritative domain
    /// - Parameter url: The URL to check
    /// - Returns: True if authoritative
    func isAuthoritative(_ url: String) -> Bool {
        guard let domain = extractDomain(from: url) else { return false }
        
        if Self.excludedDomains.contains(domain) { return false }
        if Self.authoritativeDomains[domain] != nil { return true }
        
        for (suffix, _, _) in Self.authoritativeSuffixes {
            if domain.hasSuffix(suffix) { return true }
        }
        
        return false
    }
    
    // MARK: - Private Helpers
    
    /// Extract the domain from a URL
    private func extractDomain(from urlString: String) -> String? {
        guard let url = URL(string: urlString),
              let host = url.host else {
            return nil
        }
        return host.replacingOccurrences(of: "www.", with: "").lowercased()
    }
    
    /// Normalize a URL for deduplication
    private func normalizeURL(_ urlString: String) -> String {
        var normalized = urlString.lowercased()
        
        // Remove protocol
        normalized = normalized.replacingOccurrences(of: "https://", with: "")
        normalized = normalized.replacingOccurrences(of: "http://", with: "")
        
        // Remove www
        normalized = normalized.replacingOccurrences(of: "www.", with: "")
        
        // Remove trailing slash
        if normalized.hasSuffix("/") {
            normalized = String(normalized.dropLast())
        }
        
        // Remove common tracking parameters
        if let questionIndex = normalized.firstIndex(of: "?") {
            normalized = String(normalized[..<questionIndex])
        }
        
        return normalized
    }
    
    /// Adjust reliability score based on content quality
    private func adjustScoreByContent(_ baseScore: Double, content: String) -> Double {
        var score = baseScore
        let lowercaseContent = content.lowercased()
        
        // Boost for detailed content
        if content.count > 500 {
            score += 0.02
        }
        
        // Boost for biographical indicators
        let biographicalTerms = ["born", "died", "life", "career", "biography", "educated", "married"]
        let matches = biographicalTerms.filter { lowercaseContent.contains($0) }.count
        score += Double(matches) * 0.01
        
        // Penalize for uncertainty indicators
        let uncertaintyTerms = ["allegedly", "rumored", "unconfirmed", "disputed"]
        let uncertaintyMatches = uncertaintyTerms.filter { lowercaseContent.contains($0) }.count
        score -= Double(uncertaintyMatches) * 0.02
        
        return min(1.0, max(0.0, score))
    }
}

// MARK: - Source Filter Extensions

extension SourceFilter {
    
    /// Get top N sources sorted by reliability
    /// - Parameters:
    ///   - sources: Array of sources
    ///   - limit: Maximum number to return
    /// - Returns: Top sources by reliability
    func topSources(_ sources: [Source], limit: Int) -> [Source] {
        Array(sources.sorted { $0.reliabilityScore > $1.reliabilityScore }.prefix(limit))
    }
    
    /// Aggregate sources by type
    /// - Parameter sources: Array of sources
    /// - Returns: Dictionary grouped by source type
    func groupByType(_ sources: [Source]) -> [SourceType: [Source]] {
        Dictionary(grouping: sources, by: { $0.sourceType })
    }
    
    /// Calculate average reliability score
    /// - Parameter sources: Array of sources
    /// - Returns: Average reliability score
    func averageReliability(_ sources: [Source]) -> Double {
        guard !sources.isEmpty else { return 0.0 }
        let total = sources.reduce(0.0) { $0 + $1.reliabilityScore }
        return total / Double(sources.count)
    }
}
