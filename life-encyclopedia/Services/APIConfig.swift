//
//  APIConfig.swift
//  life-encyclopedia
//
//  API configuration and keys
//  Set these values via environment variables or a local Config.xcconfig file
//

import Foundation

enum APIConfig {
    // MARK: - Anthropic (Claude)
    static let anthropicAPIKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] ?? ""
    static let anthropicBaseURL = "https://api.anthropic.com/v1"
    
    // MARK: - Tavily
    static let tavilyAPIKey = ProcessInfo.processInfo.environment["TAVILY_API_KEY"] ?? ""
    static let tavilyBaseURL = "https://api.tavily.com"
    
    // MARK: - Google Knowledge Graph
    static let googleAPIKey = ProcessInfo.processInfo.environment["GOOGLE_API_KEY"] ?? ""
    static let knowledgeGraphBaseURL = "https://kgsearch.googleapis.com/v1"
    
    // MARK: - Wikidata (no key needed)
    static let wikidataBaseURL = "https://www.wikidata.org/w/api.php"
    
    // MARK: - Supabase
    static let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? ""
    static let supabaseAnonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""
    
    // MARK: - Debug Logging
    
    #if DEBUG
    static func logConfiguration() {
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
