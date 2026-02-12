//
//  WikidataService.swift
//  life-encyclopedia
//
//  Service for fetching structured biographical data from Wikidata's free API.
//  No API key required.
//

import Foundation

// MARK: - Wikidata Result

struct WikidataPersonResult {
    let entityID: String
    let name: String
    let description: String?
    let structuredFacts: WikidataStructuredFacts
    let sources: [Source]
    let contextBlock: String

    static let empty = WikidataPersonResult(
        entityID: "",
        name: "",
        description: nil,
        structuredFacts: .empty,
        sources: [],
        contextBlock: ""
    )

    var isEmpty: Bool { entityID.isEmpty }
}

// MARK: - Structured Facts

struct WikidataStructuredFacts {
    let dateOfBirth: String?
    let dateOfDeath: String?
    let placeOfBirth: String?
    let placeOfDeath: String?
    let occupations: [String]
    let educatedAt: [String]
    let awards: [String]
    let notableWorks: [String]
    let spouses: [String]
    let children: [String]
    let positionsHeld: [String]
    let employers: [String]
    let politicalParty: String?
    let nationalities: [String]
    let nominatedFor: [String]

    static let empty = WikidataStructuredFacts(
        dateOfBirth: nil,
        dateOfDeath: nil,
        placeOfBirth: nil,
        placeOfDeath: nil,
        occupations: [],
        educatedAt: [],
        awards: [],
        notableWorks: [],
        spouses: [],
        children: [],
        positionsHeld: [],
        employers: [],
        politicalParty: nil,
        nationalities: [],
        nominatedFor: []
    )

    var isEmpty: Bool {
        dateOfBirth == nil && dateOfDeath == nil && occupations.isEmpty && awards.isEmpty && notableWorks.isEmpty
    }
}

// MARK: - Wikidata Service

@Observable
final class WikidataService {

    // MARK: - Constants

    /// Key Wikidata property IDs for biographical data
    private enum Property {
        static let dateOfBirth = "P569"
        static let dateOfDeath = "P570"
        static let placeOfBirth = "P19"
        static let placeOfDeath = "P20"
        static let occupation = "P106"
        static let educatedAt = "P69"
        static let award = "P166"
        static let notableWork = "P800"
        static let spouse = "P26"
        static let child = "P40"
        static let positionHeld = "P39"
        static let employer = "P108"
        static let politicalParty = "P102"
        static let nationality = "P27"
        static let nominatedFor = "P1411"
        static let instanceOf = "P31"
    }

    /// Q-IDs that represent "human" in Wikidata
    private let humanEntityIDs: Set<String> = ["Q5"]

    // MARK: - Errors

    enum WikidataError: LocalizedError {
        case networkError(Error)
        case invalidResponse
        case entityNotFound
        case notAPerson

        var errorDescription: String? {
            switch self {
            case .networkError(let error):
                return "Wikidata network error: \(error.localizedDescription)"
            case .invalidResponse:
                return "Invalid response from Wikidata"
            case .entityNotFound:
                return "Entity not found on Wikidata"
            case .notAPerson:
                return "Wikidata entity is not a person"
            }
        }
    }

    // MARK: - Public Methods

    /// Fetch structured biographical data for a person from Wikidata
    /// - Parameter name: The person's name to search for
    /// - Returns: WikidataPersonResult with structured facts and sources
    func fetchPerson(name: String) async throws -> WikidataPersonResult {
        // Step 1: Search for the entity ID
        let entityID = try await searchEntity(name: name)

        // Step 2: Fetch full entity data with labels
        let entityData = try await fetchEntityData(entityID: entityID)

        // Step 3: Verify this is a person (instance of Q5 = human)
        guard isHuman(entityData: entityData) else {
            throw WikidataError.notAPerson
        }

        // Step 4: Extract structured facts
        let facts = extractStructuredFacts(from: entityData)

        // Step 5: Build context block for Claude
        let contextBlock = buildContextBlock(name: name, facts: facts)

        // Step 6: Create Source objects
        let sources = buildSources(entityID: entityID, name: name, facts: facts)

        let description = extractDescription(from: entityData, language: "en")

        return WikidataPersonResult(
            entityID: entityID,
            name: name,
            description: description,
            structuredFacts: facts,
            sources: sources,
            contextBlock: contextBlock
        )
    }

    // MARK: - Step 1: Search for Entity

    private func searchEntity(name: String) async throws -> String {
        var components = URLComponents(string: APIConfig.wikidataBaseURL)
        components?.queryItems = [
            URLQueryItem(name: "action", value: "wbsearchentities"),
            URLQueryItem(name: "search", value: name),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "type", value: "item"),
            URLQueryItem(name: "limit", value: "5"),
            URLQueryItem(name: "format", value: "json")
        ]

        guard let url = components?.url else {
            throw WikidataError.invalidResponse
        }

        let (data, response) = try await performRequest(url: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw WikidataError.invalidResponse
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let searchResults = json["search"] as? [[String: Any]],
              let firstResult = searchResults.first,
              let entityID = firstResult["id"] as? String else {
            throw WikidataError.entityNotFound
        }

        return entityID
    }

    // MARK: - Step 2: Fetch Entity Data

    private func fetchEntityData(entityID: String) async throws -> [String: Any] {
        // Fetch entity with labels resolved for linked items
        var components = URLComponents(string: APIConfig.wikidataBaseURL)
        components?.queryItems = [
            URLQueryItem(name: "action", value: "wbgetentities"),
            URLQueryItem(name: "ids", value: entityID),
            URLQueryItem(name: "languages", value: "en"),
            URLQueryItem(name: "props", value: "claims|descriptions|labels"),
            URLQueryItem(name: "format", value: "json")
        ]

        guard let url = components?.url else {
            throw WikidataError.invalidResponse
        }

        let (data, response) = try await performRequest(url: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw WikidataError.invalidResponse
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let entities = json["entities"] as? [String: Any],
              let entityData = entities[entityID] as? [String: Any] else {
            throw WikidataError.entityNotFound
        }

        return entityData
    }

    // MARK: - Step 3: Verify Human

    private func isHuman(entityData: [String: Any]) -> Bool {
        guard let claims = entityData["claims"] as? [String: Any],
              let instanceOfClaims = claims[Property.instanceOf] as? [[String: Any]] else {
            return false
        }

        for claim in instanceOfClaims {
            if let mainsnak = claim["mainsnak"] as? [String: Any],
               let datavalue = mainsnak["datavalue"] as? [String: Any],
               let value = datavalue["value"] as? [String: Any],
               let qid = value["id"] as? String,
               humanEntityIDs.contains(qid) {
                return true
            }
        }
        return false
    }

    // MARK: - Step 4: Extract Structured Facts

    private func extractStructuredFacts(from entityData: [String: Any]) -> WikidataStructuredFacts {
        guard let claims = entityData["claims"] as? [String: Any] else {
            return .empty
        }

        return WikidataStructuredFacts(
            dateOfBirth: extractTimeValue(from: claims, property: Property.dateOfBirth),
            dateOfDeath: extractTimeValue(from: claims, property: Property.dateOfDeath),
            placeOfBirth: extractEntityLabel(from: claims, property: Property.placeOfBirth),
            placeOfDeath: extractEntityLabel(from: claims, property: Property.placeOfDeath),
            occupations: extractAllEntityLabels(from: claims, property: Property.occupation),
            educatedAt: extractAllEntityLabels(from: claims, property: Property.educatedAt),
            awards: extractAllEntityLabels(from: claims, property: Property.award),
            notableWorks: extractAllEntityLabels(from: claims, property: Property.notableWork),
            spouses: extractAllEntityLabels(from: claims, property: Property.spouse),
            children: extractAllEntityLabels(from: claims, property: Property.child),
            positionsHeld: extractAllEntityLabels(from: claims, property: Property.positionHeld),
            employers: extractAllEntityLabels(from: claims, property: Property.employer),
            politicalParty: extractEntityLabel(from: claims, property: Property.politicalParty),
            nationalities: extractAllEntityLabels(from: claims, property: Property.nationality),
            nominatedFor: extractAllEntityLabels(from: claims, property: Property.nominatedFor)
        )
    }

    // MARK: - Claim Value Extractors

    /// Extract a time value (date) from a claim property
    private func extractTimeValue(from claims: [String: Any], property: String) -> String? {
        guard let propertyClaims = claims[property] as? [[String: Any]],
              let firstClaim = propertyClaims.first,
              let mainsnak = firstClaim["mainsnak"] as? [String: Any],
              let datavalue = mainsnak["datavalue"] as? [String: Any],
              let value = datavalue["value"] as? [String: Any],
              let time = value["time"] as? String,
              let precision = value["precision"] as? Int else {
            return nil
        }

        return formatWikidataTime(time, precision: precision)
    }

    /// Extract the label of a linked entity from a claim (first value only)
    private func extractEntityLabel(from claims: [String: Any], property: String) -> String? {
        guard let propertyClaims = claims[property] as? [[String: Any]],
              let firstClaim = propertyClaims.first else {
            return nil
        }
        return entityIDFromClaim(firstClaim)
    }

    /// Extract all linked entity labels from a multi-valued claim
    private func extractAllEntityLabels(from claims: [String: Any], property: String) -> [String] {
        guard let propertyClaims = claims[property] as? [[String: Any]] else { return [] }
        return propertyClaims.compactMap { entityIDFromClaim($0) }
    }

    /// Extract the entity Q-ID from a claim (we'll resolve labels in a batch afterward)
    private func entityIDFromClaim(_ claim: [String: Any]) -> String? {
        guard let mainsnak = claim["mainsnak"] as? [String: Any],
              let datavalue = mainsnak["datavalue"] as? [String: Any],
              let value = datavalue["value"] as? [String: Any],
              let qid = value["id"] as? String else {
            return nil
        }
        return qid
    }

    /// Format Wikidata time string into a human-readable date
    /// Wikidata time format: "+1964-03-29T00:00:00Z" with precision levels
    private func formatWikidataTime(_ time: String, precision: Int) -> String {
        // Remove leading + sign
        let cleaned = time.hasPrefix("+") ? String(time.dropFirst()) : time

        switch precision {
        case 11: // Day precision
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withFullDate]
            if let date = dateFormatter.date(from: String(cleaned.prefix(10))) {
                let displayFormatter = DateFormatter()
                displayFormatter.dateFormat = "MMMM d, yyyy"
                return displayFormatter.string(from: date)
            }
            return String(cleaned.prefix(10))
        case 10: // Month precision
            let parts = cleaned.split(separator: "-")
            if parts.count >= 2,
               let month = Int(parts[1]),
               let year = Int(parts[0]) {
                let monthNames = ["January", "February", "March", "April", "May", "June",
                                  "July", "August", "September", "October", "November", "December"]
                if month >= 1 && month <= 12 {
                    return "\(monthNames[month - 1]) \(year)"
                }
            }
            return String(cleaned.prefix(7))
        case 9: // Year precision
            let parts = cleaned.split(separator: "-")
            if let year = parts.first { return String(year) }
            return cleaned
        case 8: // Decade precision
            let parts = cleaned.split(separator: "-")
            if let year = parts.first, let yearInt = Int(year) {
                return "\(yearInt / 10 * 10)s"
            }
            return cleaned
        case 7: // Century precision
            let parts = cleaned.split(separator: "-")
            if let year = parts.first, let yearInt = Int(year) {
                return "\(yearInt / 100 + 1)th century"
            }
            return cleaned
        default:
            return String(cleaned.prefix(10))
        }
    }

    // MARK: - Step 5: Build Context Block

    /// Build a text context block from structured facts for Claude consumption
    private func buildContextBlock(name: String, facts: WikidataStructuredFacts) -> String {
        var lines: [String] = []
        lines.append("STRUCTURED BIOGRAPHICAL FACTS (from Wikidata):")
        lines.append("Subject: \(name)")

        if let dob = facts.dateOfBirth { lines.append("Date of Birth: \(dob)") }
        if let dod = facts.dateOfDeath { lines.append("Date of Death: \(dod)") }
        if let pob = facts.placeOfBirth { lines.append("Place of Birth: \(pob)") }
        if let pod = facts.placeOfDeath { lines.append("Place of Death: \(pod)") }
        if !facts.nationalities.isEmpty { lines.append("Nationality: \(facts.nationalities.joined(separator: ", "))") }
        if !facts.occupations.isEmpty { lines.append("Occupations: \(facts.occupations.joined(separator: ", "))") }
        if !facts.educatedAt.isEmpty { lines.append("Education: \(facts.educatedAt.joined(separator: ", "))") }
        if !facts.employers.isEmpty { lines.append("Employers: \(facts.employers.joined(separator: ", "))") }
        if !facts.positionsHeld.isEmpty { lines.append("Positions Held: \(facts.positionsHeld.joined(separator: ", "))") }
        if let party = facts.politicalParty { lines.append("Political Party: \(party)") }
        if !facts.awards.isEmpty { lines.append("Awards: \(facts.awards.joined(separator: ", "))") }
        if !facts.notableWorks.isEmpty { lines.append("Notable Works: \(facts.notableWorks.joined(separator: ", "))") }
        if !facts.nominatedFor.isEmpty { lines.append("Nominated For: \(facts.nominatedFor.joined(separator: ", "))") }
        if !facts.spouses.isEmpty { lines.append("Spouses: \(facts.spouses.joined(separator: ", "))") }
        if !facts.children.isEmpty { lines.append("Children: \(facts.children.joined(separator: ", "))") }

        return lines.joined(separator: "\n")
    }

    // MARK: - Step 6: Build Sources

    /// Create Source objects from Wikidata results
    private func buildSources(entityID: String, name: String, facts: WikidataStructuredFacts) -> [Source] {
        guard !facts.isEmpty else { return [] }

        let wikidataURL = "https://www.wikidata.org/wiki/\(entityID)"
        let snippet = buildContextBlock(name: name, facts: facts)

        return [
            Source(
                title: "\(name) - Wikidata",
                url: wikidataURL,
                sourceType: .wikidata,
                publisher: "Wikidata",
                reliabilityScore: 0.90,
                contentSnippet: snippet,
                relevantQuote: nil,
                deepLinkURL: wikidataURL
            )
        ]
    }

    // MARK: - Label Resolution

    /// Resolve Q-IDs to human-readable labels in batch
    /// Called after extracting all Q-IDs to minimize API calls
    func resolveLabels(for facts: WikidataStructuredFacts) async throws -> WikidataStructuredFacts {
        // Collect all Q-IDs that need resolution
        var qids: Set<String> = []
        let allStringArrays = [
            facts.occupations, facts.educatedAt, facts.awards,
            facts.notableWorks, facts.spouses, facts.children,
            facts.positionsHeld, facts.employers, facts.nationalities,
            facts.nominatedFor
        ]
        for array in allStringArrays {
            for item in array where item.hasPrefix("Q") {
                qids.insert(item)
            }
        }
        if let pob = facts.placeOfBirth, pob.hasPrefix("Q") { qids.insert(pob) }
        if let pod = facts.placeOfDeath, pod.hasPrefix("Q") { qids.insert(pod) }
        if let party = facts.politicalParty, party.hasPrefix("Q") { qids.insert(party) }

        if qids.isEmpty { return facts }

        // Batch resolve labels (Wikidata allows up to 50 IDs per request)
        let labelMap = try await batchResolveLabels(qids: Array(qids))

        let resolve: (String) -> String = { qid in
            labelMap[qid] ?? qid
        }
        let resolveArray: ([String]) -> [String] = { array in
            array.map { resolve($0) }
        }

        return WikidataStructuredFacts(
            dateOfBirth: facts.dateOfBirth,
            dateOfDeath: facts.dateOfDeath,
            placeOfBirth: facts.placeOfBirth.map(resolve),
            placeOfDeath: facts.placeOfDeath.map(resolve),
            occupations: resolveArray(facts.occupations),
            educatedAt: resolveArray(facts.educatedAt),
            awards: resolveArray(facts.awards),
            notableWorks: resolveArray(facts.notableWorks),
            spouses: resolveArray(facts.spouses),
            children: resolveArray(facts.children),
            positionsHeld: resolveArray(facts.positionsHeld),
            employers: resolveArray(facts.employers),
            politicalParty: facts.politicalParty.map(resolve),
            nationalities: resolveArray(facts.nationalities),
            nominatedFor: resolveArray(facts.nominatedFor)
        )
    }

    /// Batch resolve Q-IDs to labels using wbgetentities
    private func batchResolveLabels(qids: [String]) async throws -> [String: String] {
        var labelMap: [String: String] = [:]

        // Process in batches of 50 (Wikidata API limit)
        let batchSize = 50
        for batchStart in stride(from: 0, to: qids.count, by: batchSize) {
            let endIndex = min(batchStart + batchSize, qids.count)
            let batch = Array(qids[batchStart..<endIndex])
            let idsString = batch.joined(separator: "|")

            var components = URLComponents(string: APIConfig.wikidataBaseURL)
            components?.queryItems = [
                URLQueryItem(name: "action", value: "wbgetentities"),
                URLQueryItem(name: "ids", value: idsString),
                URLQueryItem(name: "languages", value: "en"),
                URLQueryItem(name: "props", value: "labels"),
                URLQueryItem(name: "format", value: "json")
            ]

            guard let url = components?.url else { continue }

            do {
                let (data, _) = try await performRequest(url: url)
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let entities = json["entities"] as? [String: Any] {
                    for (qid, entityAny) in entities {
                        if let entity = entityAny as? [String: Any],
                           let labels = entity["labels"] as? [String: Any],
                           let enLabel = labels["en"] as? [String: Any],
                           let labelValue = enLabel["value"] as? String {
                            labelMap[qid] = labelValue
                        }
                    }
                }
            } catch {
                // Silently skip batch on error - labels are best-effort
                #if DEBUG
                print("WikidataService: Failed to resolve labels for batch: \(error.localizedDescription)")
                #endif
            }
        }

        return labelMap
    }

    // MARK: - Description Extraction

    private func extractDescription(from entityData: [String: Any], language: String) -> String? {
        guard let descriptions = entityData["descriptions"] as? [String: Any],
              let langDesc = descriptions[language] as? [String: Any],
              let value = langDesc["value"] as? String else {
            return nil
        }
        return value
    }

    // MARK: - Network Helper

    private func performRequest(url: URL) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: url)
        request.setValue("life-encyclopedia/1.0 (https://github.com/Figment/life-encyclopedia)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15

        do {
            return try await URLSession.shared.data(for: request)
        } catch {
            throw WikidataError.networkError(error)
        }
    }
}
