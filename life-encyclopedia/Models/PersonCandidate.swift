//
//  PersonCandidate.swift
//  life-encyclopedia
//
//  Lightweight candidate model for create-time discovery.
//

import Foundation

struct PersonCandidate: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let years: String?
    let summary: String
    /// Clean, LLM-generated one-sentence description. Falls back to `summary` if unavailable.
    var description: String?
    let sourceTitle: String?
    let sourceURL: String?
    let relevanceScore: Double

    /// Display-ready description: prefers LLM-generated `description`, falls back to raw `summary`.
    var displayDescription: String {
        if let description, !description.isEmpty { return description }
        return summary
    }

    init(
        name: String,
        years: String? = nil,
        summary: String,
        description: String? = nil,
        sourceTitle: String? = nil,
        sourceURL: String? = nil,
        relevanceScore: Double = 0
    ) {
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.years = years
        self.summary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        self.description = description
        self.sourceTitle = sourceTitle
        self.sourceURL = sourceURL
        self.relevanceScore = relevanceScore
        self.id = Self.makeID(name: self.name, sourceURL: sourceURL)
    }

    static func makeID(name: String, sourceURL: String?) -> String {
        let normalizedName = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedURL = sourceURL?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return "\(normalizedName)|\(normalizedURL)"
    }
}
