//
//  ResearchPipeline.swift
//  life-encyclopedia
//
//  5-stage research pipeline for comprehensive person research with fact verification
//

import Foundation

// MARK: - Pipeline Stage

enum PipelineStage: String, CaseIterable {
    case discovery = "Discovery"
    case sourceCollection = "Source Collection"
    case eventGeneration = "Event Generation"
    case factVerification = "Fact Verification"
    case enrichment = "Enrichment"
    
    var description: String {
        switch self {
        case .discovery: return "Searching for biographical information..."
        case .sourceCollection: return "Collecting authoritative sources..."
        case .eventGeneration: return "Generating historical events..."
        case .factVerification: return "Verifying dates and facts..."
        case .enrichment: return "Enhancing citations..."
        }
    }
    
    var iconName: String {
        switch self {
        case .discovery: return "magnifyingglass"
        case .sourceCollection: return "doc.text.magnifyingglass"
        case .eventGeneration: return "sparkles"
        case .factVerification: return "checkmark.seal"
        case .enrichment: return "link.badge.plus"
        }
    }
}

// MARK: - Pipeline Progress

struct PipelineProgress {
    let currentStage: PipelineStage
    let stageProgress: Double  // 0.0 to 1.0
    let message: String
    let sourcesCollected: Int
    let eventsGenerated: Int
    let eventsVerified: Int
    
    var overallProgress: Double {
        let stageIndex = PipelineStage.allCases.firstIndex(of: currentStage) ?? 0
        let stageWeight = 1.0 / Double(PipelineStage.allCases.count)
        return (Double(stageIndex) * stageWeight) + (stageProgress * stageWeight)
    }
}

// MARK: - Verified Person Result

struct VerifiedPerson {
    let person: Person
    let allSources: [Source]
    let researchSummary: ResearchSummary
    
    struct ResearchSummary {
        let totalEvents: Int
        let eventsWithSources: Int
        let totalSources: Int
        let authoritativeSources: Int
    }
}

// MARK: - Pipeline Errors

enum PipelineError: LocalizedError {
    case personNotFound
    case fictionalCharacter
    case noSourcesFound
    case eventGenerationFailed(Error)
    case verificationFailed(Error)
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .personNotFound:
            return "Could not find information about this person."
        case .fictionalCharacter:
            return "This appears to be a fictional character."
        case .noSourcesFound:
            return "No authoritative sources found for this person."
        case .eventGenerationFailed(let error):
            return "Failed to generate events: \(error.localizedDescription)"
        case .verificationFailed(let error):
            return "Failed to verify events: \(error.localizedDescription)"
        case .cancelled:
            return "Research was cancelled."
        }
    }
}

// MARK: - Research Pipeline

@MainActor
final class ResearchPipeline {
    
    // MARK: - Properties
    
    private let tavilyService: TavilyService
    private let claudeService: ClaudeService
    private let sourceFilter: SourceFilter
    private let filterEnrichmentService: FilterEnrichmentService
    
    private var isCancelled = false
    private var progressHandler: ((PipelineProgress) -> Void)?
    
    // MARK: - Configuration
    
    struct Configuration {
        let maxSourcesPerEvent: Int
        let minConfidenceThreshold: Double
        let verifyAllEvents: Bool
        let enrichLowConfidenceOnly: Bool
        
        static let `default` = Configuration(
            maxSourcesPerEvent: 5,
            minConfidenceThreshold: 0.5,
            verifyAllEvents: true,
            enrichLowConfidenceOnly: true
        )
        
        static let thorough = Configuration(
            maxSourcesPerEvent: 8,
            minConfidenceThreshold: 0.7,
            verifyAllEvents: true,
            enrichLowConfidenceOnly: false
        )
        
        static let quick = Configuration(
            maxSourcesPerEvent: 3,
            minConfidenceThreshold: 0.3,
            verifyAllEvents: false,
            enrichLowConfidenceOnly: true
        )
    }
    
    // MARK: - Initialization
    
    init(
        tavilyService: TavilyService,
        claudeService: ClaudeService,
        sourceFilter: SourceFilter,
        filterEnrichmentService: FilterEnrichmentService
    ) {
        self.tavilyService = tavilyService
        self.claudeService = claudeService
        self.sourceFilter = sourceFilter
        self.filterEnrichmentService = filterEnrichmentService
    }
    
    init() {
        self.tavilyService = TavilyService()
        self.claudeService = ClaudeService()
        self.sourceFilter = SourceFilter()
        self.filterEnrichmentService = FilterEnrichmentService()
    }
    
    // MARK: - Public Methods
    
    /// Set progress handler for UI updates
    func setProgressHandler(_ handler: @escaping (PipelineProgress) -> Void) {
        self.progressHandler = handler
    }
    
    /// Cancel the current research operation
    func cancel() {
        isCancelled = true
    }
    
    /// Main research pipeline entry point
    /// - Parameters:
    ///   - name: Person's name to research
    ///   - config: Pipeline configuration
    /// - Returns: VerifiedPerson with all sources and verification summary
    func researchPerson(name: String, config: Configuration) async throws -> VerifiedPerson {
        isCancelled = false
        
        // Stage 1: Discovery
        reportProgress(stage: .discovery, progress: 0.0, message: "Starting discovery...", sources: 0, events: 0, verified: 0)
        let discovery = try await performDiscovery(name: name)
        
        try checkCancelled()
        
        // Stage 2: Source Collection
        reportProgress(stage: .sourceCollection, progress: 0.0, message: "Filtering sources...", sources: discovery.sources.count, events: 0, verified: 0)
        let collectedSources = try await collectSources(from: discovery, config: config)
        
        try checkCancelled()
        
        // Stage 3: Event Generation
        reportProgress(stage: .eventGeneration, progress: 0.0, message: "Generating events...", sources: collectedSources.count, events: 0, verified: 0)
        let generatedPerson = try await generateEvents(name: name, sources: collectedSources)
        
        try checkCancelled()
        
        // Stage 4: Fact Verification
        reportProgress(stage: .factVerification, progress: 0.0, message: "Verifying facts...", sources: collectedSources.count, events: generatedPerson.events.count, verified: 0)
        let verifiedEvents = try await verifyEvents(events: generatedPerson.events, personName: name, config: config)
        
        try checkCancelled()
        
        // Stage 5: Enrichment
        reportProgress(stage: .enrichment, progress: 0.0, message: "Enriching citations...", sources: collectedSources.count, events: verifiedEvents.count, verified: 0)
        let enrichedEvents = try await enrichCitations(events: verifiedEvents, personName: name, config: config)
        
        // Build initial person for filter enrichment
        var finalPerson = Person(
            name: generatedPerson.name,
            birthDate: generatedPerson.birthDate,
            deathDate: generatedPerson.deathDate,
            summary: generatedPerson.summary,
            events: enrichedEvents
        )
        
        // Enrich with filter metadata using AI
        reportProgress(stage: .enrichment, progress: 0.8, message: "Classifying for filters...", sources: collectedSources.count, events: enrichedEvents.count, verified: 0)
        
        do {
            // Build additional context from sources for better classification
            let sourceContext = collectedSources.prefix(5).compactMap { $0.contentSnippet }.joined(separator: "\n")
            let filterMetadata = try await filterEnrichmentService.enrichPerson(finalPerson, additionalContext: sourceContext)
            finalPerson = finalPerson.withFilterMetadata(filterMetadata)
        } catch {
            // Filter enrichment is optional - log but don't fail the pipeline
            #if DEBUG
            print("Filter enrichment failed: \(error.localizedDescription)")
            #endif
        }
        
        let summary = buildResearchSummary(events: enrichedEvents, sources: collectedSources)
        
        reportProgress(stage: .enrichment, progress: 1.0, message: "Research complete!", sources: collectedSources.count, events: enrichedEvents.count, verified: summary.eventsWithSources)
        
        return VerifiedPerson(
            person: finalPerson,
            allSources: collectedSources,
            researchSummary: summary
        )
    }
    
    // MARK: - Stage 1: Discovery
    
    private func performDiscovery(name: String) async throws -> PersonDiscovery {
        reportProgress(stage: .discovery, progress: 0.3, message: "Searching biographical sources...", sources: 0, events: 0, verified: 0)
        
        let discovery = try await tavilyService.discoverPerson(name: name)
        
        if !discovery.isVerified {
            if discovery.isFictional {
                throw PipelineError.fictionalCharacter
            }
            throw PipelineError.personNotFound
        }
        
        reportProgress(stage: .discovery, progress: 1.0, message: "Found \(discovery.sources.count) sources", sources: discovery.sources.count, events: 0, verified: 0)
        
        return discovery
    }
    
    // MARK: - Stage 2: Source Collection
    
    private func collectSources(from discovery: PersonDiscovery, config: Configuration) async throws -> [Source] {
        var allSources = discovery.sources
        
        reportProgress(stage: .sourceCollection, progress: 0.3, message: "Deduplicating sources...", sources: allSources.count, events: 0, verified: 0)
        
        // Deduplicate
        allSources = sourceFilter.deduplicateSources(allSources)
        
        reportProgress(stage: .sourceCollection, progress: 0.6, message: "Scoring reliability...", sources: allSources.count, events: 0, verified: 0)
        
        // Sort by reliability and take top sources
        let topSources = sourceFilter.topSources(allSources, limit: 15)
        
        if topSources.isEmpty {
            throw PipelineError.noSourcesFound
        }
        
        reportProgress(stage: .sourceCollection, progress: 1.0, message: "Collected \(topSources.count) authoritative sources", sources: topSources.count, events: 0, verified: 0)
        
        return prepareCitationSources(topSources)
    }
    
    // MARK: - Stage 3: Event Generation
    
    private func generateEvents(name: String, sources: [Source]) async throws -> Person {
        reportProgress(stage: .eventGeneration, progress: 0.2, message: "Preparing context...", sources: sources.count, events: 0, verified: 0)
        
        // Build context from sources
        let context = sources
            .prefix(10)
            .compactMap { $0.contentSnippet }
            .joined(separator: "\n\n---\n\n")
        
        // Add source metadata for Claude to reference
        let sourceMetadata = sources.prefix(10).map { source in
            "- \(source.title) [\(source.sourceType.displayName)] (\(source.url))"
        }.joined(separator: "\n")
        
        let fullContext = """
        AVAILABLE AUTHORITATIVE SOURCES:
        \(sourceMetadata)
        
        SOURCE CONTENT:
        \(context)
        """
        
        reportProgress(stage: .eventGeneration, progress: 0.4, message: "Generating events from \(sources.count) sources...", sources: sources.count, events: 0, verified: 0)
        
        do {
            let person = try await claudeService.generateHistoricalEvents(name: name, context: fullContext)
            let eventsWithCitationLinks = person.events.map { eventWithPreparedSources($0) }
            let personWithCitationLinks = Person(
                id: person.id,
                name: person.name,
                birthDate: person.birthDate,
                deathDate: person.deathDate,
                summary: person.summary,
                events: eventsWithCitationLinks,
                createdAt: person.createdAt,
                filterMetadata: person.filterMetadata,
                viewCount: person.viewCount,
                lastViewedAt: person.lastViewedAt
            )
            
            reportProgress(stage: .eventGeneration, progress: 1.0, message: "Generated \(person.events.count) events", sources: sources.count, events: person.events.count, verified: 0)
            
            return personWithCitationLinks
        } catch {
            throw PipelineError.eventGenerationFailed(error)
        }
    }
    
    // MARK: - Stage 4: Fact Verification
    
    private func verifyEvents(events: [HistoricalEvent], personName: String, config: Configuration) async throws -> [HistoricalEvent] {
        var verifiedEvents: [HistoricalEvent] = []
        
        func normalized(_ value: String) -> String {
            value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
        
        // Determine which events to verify
        let eventsToVerify: [HistoricalEvent]
        if config.verifyAllEvents {
            eventsToVerify = events
        } else {
            // Only verify major events (birth, death, achievements)
            eventsToVerify = events.filter { event in
                let majorTypes: [EventType] = [.birth, .death, .achievement, .career]
                return majorTypes.contains(event.eventType)
            }
        }
        
        let totalToVerify = eventsToVerify.count
        var verified = 0
        
        // Batch verify events
        let eventTuples = eventsToVerify.map { ($0.title, $0.date) }
        
        do {
            let verifications = try await tavilyService.batchVerifyEvents(
                name: personName,
                events: eventTuples
            )
            
            var verificationsByEventID: [UUID: EventVerification] = [:]
            for (index, eventToVerify) in eventsToVerify.enumerated() {
                guard index < verifications.count else { continue }
                
                let verification = verifications[index]
                let isEventAligned = normalized(verification.event) == normalized(eventToVerify.title)
                let isDateAligned = normalized(verification.date) == normalized(eventToVerify.date)
                
                guard isEventAligned && isDateAligned else {
                    #if DEBUG
                    print("ResearchPipeline: Skipping mismatched verification for event '\(eventToVerify.title)'")
                    #endif
                    continue
                }
                
                verificationsByEventID[eventToVerify.id] = verification
            }
            
            // Map verifications back to events - add sources from verification
            for event in events {
                if let verification = verificationsByEventID[event.id] {
                    
                    // Create updated event with sources from verification
                    let verifiedEvent = HistoricalEvent(
                        id: event.id,
                        date: event.date,
                        title: event.title,
                        description: event.description,
                        citation: event.citation,
                        sourceURL: event.sourceURL,
                        eventType: event.eventType,
                        datePrecision: verification.datePrecision,
                        sources: prepareCitationSources(verification.matchingSources)
                    )
                    verifiedEvents.append(verifiedEvent)
                    verified += 1
                    
                    let progress = Double(verified) / Double(totalToVerify)
                    reportProgress(stage: .factVerification, progress: progress, message: "Verified \(verified)/\(totalToVerify) events", sources: 0, events: events.count, verified: verified)
                } else {
                    // Event wasn't verified, keep original
                    verifiedEvents.append(eventWithPreparedSources(event))
                }
            }
            
        } catch {
            // On verification failure, return events with unverified status
            verifiedEvents = events.map { eventWithPreparedSources($0) }
        }
        
        reportProgress(stage: .factVerification, progress: 1.0, message: "Verification complete", sources: 0, events: events.count, verified: verified)
        
        return verifiedEvents
    }
    
    // MARK: - Stage 5: Enrichment
    
    private func enrichCitations(events: [HistoricalEvent], personName: String, config: Configuration) async throws -> [HistoricalEvent] {
        var enrichedEvents: [HistoricalEvent] = []
        
        // Determine which events need enrichment (events with few sources)
        let eventsToEnrich: [HistoricalEvent]
        if config.enrichLowConfidenceOnly {
            eventsToEnrich = events.filter { $0.sources.count < 2 }
        } else {
            eventsToEnrich = events
        }
        
        let totalToEnrich = eventsToEnrich.count
        var enriched = 0
        
        for event in events {
            if eventsToEnrich.contains(where: { $0.id == event.id }) {
                // Try to find additional sources
                do {
                    let additionalSources = try await tavilyService.findAuthoritativeSources(
                        query: "\(personName) \(event.title) \(event.date)",
                        limit: config.maxSourcesPerEvent - event.sources.count
                    )
                    
                    // Merge sources
                    var allSources = event.sources
                    for source in additionalSources {
                        if !allSources.contains(where: { $0.url == source.url }) {
                            allSources.append(source)
                        }
                    }
                    
                    // Create enriched event with additional sources
                    let enrichedEvent = HistoricalEvent(
                        id: event.id,
                        date: event.date,
                        title: event.title,
                        description: event.description,
                        citation: event.citation,
                        sourceURL: event.sourceURL,
                        eventType: event.eventType,
                        datePrecision: event.datePrecision,
                        sources: prepareCitationSources(sourceFilter.topSources(allSources, limit: config.maxSourcesPerEvent))
                    )
                    enrichedEvents.append(enrichedEvent)
                    
                } catch {
                    // Keep original on error
                    enrichedEvents.append(eventWithPreparedSources(event))
                }
                
                enriched += 1
                let progress = Double(enriched) / Double(max(1, totalToEnrich))
                reportProgress(stage: .enrichment, progress: progress, message: "Enriched \(enriched)/\(totalToEnrich) events", sources: 0, events: events.count, verified: 0)
            } else {
                enrichedEvents.append(eventWithPreparedSources(event))
            }
        }
        
        return enrichedEvents
    }
    
    // MARK: - Helper Methods
    
    private func checkCancelled() throws {
        if isCancelled {
            throw PipelineError.cancelled
        }
    }
    
    private func reportProgress(stage: PipelineStage, progress: Double, message: String, sources: Int, events: Int, verified: Int) {
        let progressUpdate = PipelineProgress(
            currentStage: stage,
            stageProgress: progress,
            message: message,
            sourcesCollected: sources,
            eventsGenerated: events,
            eventsVerified: verified
        )
        progressHandler?(progressUpdate)
    }
    
    private func buildResearchSummary(events: [HistoricalEvent], sources: [Source]) -> VerifiedPerson.ResearchSummary {
        let eventsWithSources = events.filter { !$0.sources.isEmpty }.count
        
        let authoritativeCount = sources.filter { source in
            SourceFilter.authoritativeDomains[source.domain ?? ""] != nil
        }.count
        
        return VerifiedPerson.ResearchSummary(
            totalEvents: events.count,
            eventsWithSources: eventsWithSources,
            totalSources: sources.count,
            authoritativeSources: authoritativeCount
        )
    }
    
    private func eventWithPreparedSources(_ event: HistoricalEvent, sources overrideSources: [Source]? = nil) -> HistoricalEvent {
        let sources = prepareCitationSources(overrideSources ?? event.sources)
        return HistoricalEvent(
            id: event.id,
            date: event.date,
            title: event.title,
            description: event.description,
            citation: event.citation,
            sourceURL: event.sourceURL,
            eventType: event.eventType,
            datePrecision: event.datePrecision,
            sources: sources
        )
    }
    
    private func prepareCitationSources(_ sources: [Source]) -> [Source] {
        sources.map { source in
            let quote = CitationDeepLinkBuilder.bestQuote(
                relevantQuote: source.relevantQuote,
                contentSnippet: source.contentSnippet
            )
            let deepLinkURL = CitationDeepLinkBuilder.resolvedURLString(
                baseURL: source.url,
                relevantQuote: quote,
                deepLinkHint: source.deepLinkURL
            )
            
            return Source(
                id: source.id,
                title: source.title,
                url: source.url,
                sourceType: source.sourceType,
                publisher: source.publisher,
                author: source.author,
                publishDate: source.publishDate,
                accessDate: source.accessDate,
                reliabilityScore: source.reliabilityScore,
                contentSnippet: source.contentSnippet,
                relevantQuote: quote,
                deepLinkURL: deepLinkURL
            )
        }
    }
}
