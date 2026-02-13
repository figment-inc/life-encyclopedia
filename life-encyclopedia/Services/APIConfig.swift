//
//  APIConfig.swift
//  life-encyclopedia
//
//  API configuration and keys
//  Keys are loaded from Configuration.plist (bundled in the app) with a
//  fallback to environment variables for local development in Xcode.
//

import Foundation

enum APIConfig {

    // MARK: - Bundled Configuration

    /// Loads values from the bundled Configuration.plist.
    /// Falls back to environment variables so Xcode-scheme-based
    /// development still works without touching the plist.
    private static let configDictionary: [String: Any] = {
        guard let url = Bundle.main.url(forResource: "Configuration", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else {
            return [:]
        }
        return dict
    }()

    /// Reads a value from Configuration.plist first, then falls back to
    /// environment variables, then returns an empty string.
    private static func value(for key: String) -> String {
        if let plistValue = configDictionary[key] as? String,
           !plistValue.isEmpty,
           !plistValue.hasPrefix("YOUR_") {
            return plistValue
        }
        return ProcessInfo.processInfo.environment[key] ?? ""
    }

    // MARK: - Anthropic (Claude)
    static let anthropicAPIKey = value(for: "ANTHROPIC_API_KEY")
    static let anthropicBaseURL = "https://api.anthropic.com/v1"

    // MARK: - Tavily
    static let tavilyAPIKey = value(for: "TAVILY_API_KEY")
    static let tavilyBaseURL = "https://api.tavily.com"

    // MARK: - Google Knowledge Graph
    static let googleAPIKey = value(for: "GOOGLE_API_KEY")
    static let knowledgeGraphBaseURL = "https://kgsearch.googleapis.com/v1"

    // MARK: - Wikidata (no key needed)
    static let wikidataBaseURL = "https://www.wikidata.org/w/api.php"

    // MARK: - Supabase
    static let supabaseURL = value(for: "SUPABASE_URL")
    static let supabaseAnonKey = value(for: "SUPABASE_ANON_KEY")

    // MARK: - Debug Logging

    #if DEBUG
    static func logConfiguration() {
        print("[APIConfig] Source: \(configDictionary.isEmpty ? "Environment Variables" : "Configuration.plist")")
        print("[APIConfig] SUPABASE_URL present: \(!supabaseURL.isEmpty)")
        print("[APIConfig] SUPABASE_ANON_KEY present: \(!supabaseAnonKey.isEmpty)")
        print("[APIConfig] SUPABASE_URL: \(supabaseURL.prefix(40))...")
        print("[APIConfig] SUPABASE_ANON_KEY prefix: \(supabaseAnonKey.prefix(20))...")
        print("[APIConfig] ANTHROPIC_API_KEY present: \(!anthropicAPIKey.isEmpty)")
        print("[APIConfig] TAVILY_API_KEY present: \(!tavilyAPIKey.isEmpty)")
        print("[APIConfig] GOOGLE_API_KEY present: \(!googleAPIKey.isEmpty)")
    }
    #endif
}
