//
//  CitationDeepLinkBuilder.swift
//  life-encyclopedia
//
//  Builds best-effort deep links for source fact-checking.
//

import Foundation

enum CitationDeepLinkBuilder {
    static func resolvedURLString(
        baseURL: String,
        relevantQuote: String?,
        deepLinkHint: String?
    ) -> String {
        guard let base = URL(string: baseURL), base.scheme != nil else {
            return baseURL
        }
        
        if let resolvedFromHint = resolveHint(base: base, hint: deepLinkHint) {
            return resolvedFromHint
        }
        
        if let textFragmentURL = buildTextFragmentURL(base: base, quote: relevantQuote) {
            return textFragmentURL
        }
        
        return baseURL
    }
    
    static func bestQuote(relevantQuote: String?, contentSnippet: String?) -> String? {
        let candidate = (relevantQuote?.isEmpty == false ? relevantQuote : contentSnippet)?
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let candidate, !candidate.isEmpty else { return nil }
        
        if candidate.count <= 200 { return candidate }
        let end = candidate.index(candidate.startIndex, offsetBy: 200)
        return String(candidate[..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private static func resolveHint(base: URL, hint: String?) -> String? {
        guard let rawHint = hint?.trimmingCharacters(in: .whitespacesAndNewlines), !rawHint.isEmpty else {
            return nil
        }
        
        if let absoluteHint = URL(string: rawHint), absoluteHint.scheme != nil {
            return absoluteHint.absoluteString
        }
        
        if rawHint.hasPrefix("#") {
            var components = URLComponents(url: base, resolvingAgainstBaseURL: false)
            components?.fragment = String(rawHint.dropFirst())
            return components?.url?.absoluteString
        }
        
        if isWikipediaURL(base) {
            let slug = rawHint
                .replacingOccurrences(of: " ", with: "_")
                .replacingOccurrences(of: "#", with: "")
            var components = URLComponents(url: base, resolvingAgainstBaseURL: false)
            components?.fragment = slug
            if let wikiURL = components?.url?.absoluteString {
                return wikiURL
            }
        }
        
        if let relativeHint = URL(string: rawHint, relativeTo: base)?.absoluteURL {
            return relativeHint.absoluteString
        }
        
        return nil
    }
    
    private static func buildTextFragmentURL(base: URL, quote: String?) -> String? {
        guard let quote = bestQuote(relevantQuote: quote, contentSnippet: nil), !quote.isEmpty else {
            return nil
        }
        
        var components = URLComponents(url: base, resolvingAgainstBaseURL: false)
        guard components?.fragment?.isEmpty != false else {
            return nil
        }
        
        let encodedQuote = quote
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?
            .replacingOccurrences(of: "&", with: "%26")
        guard let encodedQuote else { return nil }
        
        components?.fragment = ":~:text=\(encodedQuote)"
        return components?.url?.absoluteString
    }
    
    private static func isWikipediaURL(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return host.contains("wikipedia.org")
    }
}
