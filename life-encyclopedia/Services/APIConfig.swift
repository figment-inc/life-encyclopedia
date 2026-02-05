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
    
    // MARK: - Supabase
    static let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? ""
    static let supabaseAnonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""
}
