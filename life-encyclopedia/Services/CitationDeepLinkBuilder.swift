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
        guard let raw = (relevantQuote?.isEmpty == false ? relevantQuote : contentSnippet),
              !raw.isEmpty else { return nil }
        
        let cleaned = cleanRawContent(raw)
        guard !cleaned.isEmpty else { return nil }
        
        // Post-clean validation: reject strings that are mostly non-alphanumeric
        let alphanumericCount = cleaned.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) }.count
        let ratio = Double(alphanumericCount) / Double(cleaned.count)
        guard cleaned.count >= 10, ratio >= 0.4 else { return nil }
        
        if cleaned.count <= 200 { return cleaned }
        let end = cleaned.index(cleaned.startIndex, offsetBy: 200)
        return String(cleaned[..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Content Cleaning
    
    /// Strips HTML, markdown syntax, repeated special characters, bare URLs,
    /// reference markers, and other web artifacts so the snippet reads as clean prose.
    static func cleanRawContent(_ text: String) -> String {
        var t = text
        
        // 1. Strip HTML tags
        t = t.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )
        
        // 2. Strip markdown-style links: [text](url) -> text
        t = t.replacingOccurrences(
            of: "\\[([^\\]]+)\\]\\([^)]*\\)",
            with: "$1",
            options: .regularExpression
        )
        
        // 3. Strip double-bracket wiki links: [[target|text]] -> text  or  [[text]] -> text
        t = t.replacingOccurrences(
            of: "\\[\\[(?:[^|\\]]*\\|)?([^\\]]+)\\]\\]",
            with: "$1",
            options: .regularExpression
        )
        
        // 4. Strip reference markers: [1], [2], [a], [citation needed], etc.
        t = t.replacingOccurrences(
            of: "\\[(?:\\d+|[a-z]|citation needed|clarification needed|unreliable source)\\]",
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        
        // 5. Strip markdown headings: lines starting with # through ######
        t = t.replacingOccurrences(
            of: "(?m)^#{1,6}\\s+",
            with: "",
            options: .regularExpression
        )
        
        // 6. Strip markdown bold/italic markers: ***text***, **text**, *text*
        t = t.replacingOccurrences(
            of: "\\*{1,3}([^*]+)\\*{1,3}",
            with: "$1",
            options: .regularExpression
        )
        
        // 7. Strip markdown underline bold/italic: ___text___, __text__, _text_
        t = t.replacingOccurrences(
            of: "_{1,3}([^_]+)_{1,3}",
            with: "$1",
            options: .regularExpression
        )
        
        // 8. Strip bare URLs
        t = t.replacingOccurrences(
            of: "https?://\\S+",
            with: "",
            options: .regularExpression
        )
        
        // 9. Strip URL fragments like _Kennedy#bodyContent) or (#section)
        t = t.replacingOccurrences(
            of: "[_#][A-Za-z0-9_#/]+\\)?",
            with: "",
            options: .regularExpression
        )
        
        // 10. Strip 3+ consecutive special characters (/, |, -, =, *, ~, _)
        t = t.replacingOccurrences(
            of: "[/|\\-=*~_]{3,}",
            with: " ",
            options: .regularExpression
        )
        
        // 11. Remove leftover empty brackets, parentheses, braces
        t = t.replacingOccurrences(of: "()", with: "")
        t = t.replacingOccurrences(of: "[]", with: "")
        t = t.replacingOccurrences(of: "{}", with: "")
        
        // 12. Remove common navigation/menu artifacts
        t = t.replacingOccurrences(
            of: "(?i)(?:skip to (?:content|main|navigation)|menu|breadcrumb|toggle navigation|search this site)",
            with: "",
            options: .regularExpression
        )
        
        // 13. Remove breadcrumb-like sequences: "Home > Section > Page"
        t = t.replacingOccurrences(
            of: "(?:[A-Za-z]+\\s*>\\s*){2,}[A-Za-z]+",
            with: "",
            options: .regularExpression
        )
        
        // 14. Collapse newlines into spaces, then collapse all whitespace
        t = t.replacingOccurrences(of: "\n", with: " ")
        t = t.replacingOccurrences(
            of: "\\s{2,}",
            with: " ",
            options: .regularExpression
        )
        
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
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
