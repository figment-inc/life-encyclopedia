//
//  CreateView.swift
//  life-encyclopedia
//
//  Create tab for searching and generating person history
//

import SwiftUI

struct CreateView: View {
    // MARK: - Callback
    
    var onPersonCreated: ((Person) -> Void)?
    
    // MARK: - State
    
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var isGenerating = false
    @State private var verification: PersonVerification?
    @State private var generatedPerson: Person?
    @State private var verifiedResult: VerifiedPerson?
    @State private var errorMessage: String?
    @State private var pipelineProgress: PipelineProgress?
    @State private var useAdvancedPipeline = true
    @State private var showingOptions = false
    
    // MARK: - Existing Entry State

    @State private var selectedExistingPerson: Person?
    @State private var discoveryCandidates: [PersonCandidate] = []
    @State private var existingMatches: [Person] = []
    @State private var isLoadingCandidateLists = false
    @State private var candidateSearchTask: Task<Void, Never>?
    @State private var visibleDiscoveryCount = 5
    
    // MARK: - Services
    
    private let tavilyService = TavilyService()
    private let claudeService = ClaudeService()
    private let supabaseService = SupabaseService()
    private let researchPipeline = ResearchPipeline()
    
    // MARK: - Computed
    
    private var isLoading: Bool {
        isSearching || isGenerating
    }

    private let discoveryPageSize = 5

    private var visibleDiscoveryCandidates: [PersonCandidate] {
        Array(discoveryCandidates.prefix(visibleDiscoveryCount))
    }

    private var hasMoreDiscoveryResults: Bool {
        visibleDiscoveryCount < discoveryCandidates.count
    }

    private var shouldHideSearchHeader: Bool {
        !isSearching && (!discoveryCandidates.isEmpty || !existingMatches.isEmpty)
    }
    
    private var currentStep: CreateStep {
        if verification?.isVerified == true {
            return .verified
        } else {
            return .search
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                switch currentStep {
                case .search:
                    searchView
                case .verified:
                    verifiedView
                }
            }
            .navigationTitle("Create")
            .navigationBarTitleDisplayMode(.large)
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage {
                    Text(errorMessage)
                }
            }
            .sheet(item: $selectedExistingPerson) { person in
                NavigationStack {
                    PersonDetailView(
                        person: person,
                        showSaveButton: false,
                        onSave: nil,
                        onDismiss: { selectedExistingPerson = nil }
                    )
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") {
                                selectedExistingPerson = nil
                                handleReset()
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Search View
    
    private var searchView: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                if !shouldHideSearchHeader {
                    searchHeaderView
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Search input
                VStack(spacing: Spacing.md) {
                    TextField("Enter name", text: $searchText)
                        .font(.system(size: 20, weight: .regular, design: .serif))
                        .multilineTextAlignment(.center)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .onSubmit {
                            Task { await handleSearch() }
                        }
                        .padding(.vertical, Spacing.md)
                        .padding(.horizontal, Spacing.lg)
                        .background(Color.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))

                    if isLoadingCandidateLists && !isSearching && currentStep == .search {
                        HStack(spacing: Spacing.xs) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Searching discovery and existing entries...")
                                .font(.caption)
                                .foregroundStyle(.textSecondary)
                        }
                    }

                    if !discoveryCandidates.isEmpty && !isSearching && currentStep == .search {
                        discoveryCandidatesList
                    }

                    if !existingMatches.isEmpty && !isSearching && currentStep == .search {
                        existingMatchesList
                    }

                    Button(action: {
                        Task { await handleSearch() }
                    }) {
                        Group {
                            if isSearching {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Search")
                                    .fontWeight(.medium)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xxl)
            .animation(.easeInOut(duration: 0.28), value: shouldHideSearchHeader)
        }
    }

    private var searchHeaderView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "person.text.rectangle")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.quaternary)

            Text("Research a historical figure")
                .font(.bodyMedium)
                .foregroundStyle(.secondary)
        }
        .padding(.top, Spacing.xxl)
    }
    
    // MARK: - Verified View
    
    private var verifiedView: some View {
        VStack(spacing: 0) {
            if let verification {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        // Person card - editorial style
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            // Found indicator
                            HStack(spacing: Spacing.xs) {
                                Circle()
                                    .fill(Color.success)
                                    .frame(width: 8, height: 8)
                                Text("Found")
                                    .font(.caption)
                                    .foregroundStyle(.success)
                            }
                            
                            Text(verification.name)
                                .font(.system(size: 24, weight: .regular, design: .serif))
                                .foregroundStyle(.textPrimary)
                            
                            Text(verification.summary)
                                .font(.bodyMediumSerif)
                                .foregroundStyle(.textSecondary)
                                .lineSpacing(4)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Spacing.cardPadding)
                        .background(Color.surfaceCard)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                        
                        // Progress indicator (when generating)
                        if isGenerating {
                            generatingProgressView
                        }
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.top, Spacing.md)
                }
                
                // Bottom action area
                bottomActionArea
            }
        }
    }
    
    // MARK: - Generating Progress View (Simplified)
    
    private var generatingProgressView: some View {
        VStack(spacing: Spacing.md) {
            // Simple progress bar
            ProgressView(value: pipelineProgress?.overallProgress ?? 0)
                .tint(.brandPrimary)
            
            // Status message
            Text(pipelineProgress?.message ?? "Researching...")
                .font(.bodySmall)
                .foregroundStyle(.textSecondary)
        }
        .padding(Spacing.md)
        .background(Color.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }
    
    // MARK: - Bottom Action Area
    
    private var bottomActionArea: some View {
        VStack(spacing: 0) {
            Divider()
            
            VStack(spacing: Spacing.sm) {
                Button(action: {
                    Task { await handleGenerate() }
                }) {
                    Group {
                        if isGenerating {
                            HStack(spacing: Spacing.xs) {
                                ProgressView()
                                    .tint(.white)
                                Text("Researching...")
                            }
                        } else {
                            Text("Generate Timeline")
                                .fontWeight(.medium)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)
                
                HStack {
                    Button("Start Over") {
                        handleReset()
                    }
                    .font(.bodySmall)
                    .foregroundStyle(.textTertiary)
                    .disabled(isLoading)
                    
                    Spacer()
                    
                    // Options menu (advanced settings)
                    Menu {
                        Toggle(isOn: $useAdvancedPipeline) {
                            Label("Verify with sources", systemImage: "checkmark.seal")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundStyle(.textTertiary)
                    }
                    .disabled(isLoading)
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.md)
        }
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Discovery Candidates

    private var discoveryCandidatesList: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("DISCOVER PEOPLE")
                .font(.labelMedium)
                .foregroundStyle(.textTertiary)
                .kerning(1.2)
                .padding(.horizontal, Spacing.xxs)

            VStack(spacing: Spacing.xs) {
                ForEach(visibleDiscoveryCandidates) { candidate in
                    Button {
                        Task { await handleDiscoveryCandidateSelection(candidate) }
                    } label: {
                        HStack(alignment: .top, spacing: Spacing.sm) {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                // Row 1: Name (left) + Years (right)
                                HStack(alignment: .firstTextBaseline) {
                                    Text(candidate.name)
                                        .font(.system(size: 17, weight: .semibold, design: .serif))
                                        .foregroundStyle(.textPrimary)

                                    Spacer()

                                    if let years = candidate.years, !years.isEmpty {
                                        Text(years)
                                            .font(.system(size: 13, weight: .regular, design: .serif))
                                            .foregroundStyle(.textSecondary)
                                    }
                                }

                                // Row 2: Description
                                Text(candidateBodyText(for: candidate))
                                    .font(.bodyMediumSerif)
                                    .foregroundStyle(.textTertiary)
                                    .lineLimit(2)
                                    .lineSpacing(3)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            Image(systemName: "plus.circle")
                                .font(.system(size: 16, weight: .light))
                                .foregroundStyle(.textTertiary)
                                .padding(.top, 2)
                        }
                        .padding(.horizontal, Spacing.cardPadding)
                        .padding(.vertical, Spacing.md)
                    }
                    .buttonStyle(.plain)
                    .background(Color.surfaceCard)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                }
            }

            if hasMoreDiscoveryResults {
                Button("Show more") {
                    visibleDiscoveryCount = min(
                        visibleDiscoveryCount + discoveryPageSize,
                        discoveryCandidates.count
                    )
                }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .regular, design: .serif))
                .foregroundStyle(.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.top, Spacing.xxs)
            }
        }
    }

    // MARK: - Existing Matches

    private var existingMatchesList: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Already in Library")
                .font(.caption)
                .foregroundStyle(.textTertiary)
                .padding(.horizontal, Spacing.xs)

            VStack(spacing: 0) {
                ForEach(existingMatches) { person in
                    Button(action: {
                        handleExistingMatchSelection(person)
                    }) {
                        HStack(spacing: Spacing.sm) {
                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                Text(person.name)
                                    .font(.bodyMedium)
                                    .foregroundStyle(.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                if let birthYear = person.filterMetadata.birthYear, let deathYear = person.filterMetadata.deathYear {
                                    Text("\(birthYear) – \(deathYear)")
                                        .font(.caption)
                                        .foregroundStyle(.textTertiary)
                                } else if let birthYear = person.filterMetadata.birthYear {
                                    Text("Born \(birthYear)")
                                        .font(.caption)
                                        .foregroundStyle(.textTertiary)
                                }
                            }

                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundStyle(.textTertiary)
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                    }
                    .buttonStyle(.plain)

                    if person.id != existingMatches.last?.id {
                        Divider()
                            .padding(.leading, Spacing.md)
                    }
                }
            }
            .background(Color.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        }
    }

    // MARK: - Methods

    private func showExistingPerson(_ person: Person) {
        candidateSearchTask?.cancel()
        isLoadingCandidateLists = false
        withAnimation(.easeInOut(duration: 0.28)) {
            discoveryCandidates = []
            existingMatches = []
        }
        verification = nil
        generatedPerson = nil
        verifiedResult = nil
        pipelineProgress = nil
        errorMessage = nil
        selectedExistingPerson = person
    }

    private func handleSearch() async {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearch.isEmpty else { return }

        candidateSearchTask?.cancel()
        isLoadingCandidateLists = false
        isSearching = true
        errorMessage = nil

        do {
            async let discovered = tavilyService.searchPeopleCandidates(query: trimmedSearch, limit: 20)
            async let existing = supabaseService.searchPeopleForNameSuggestions(query: trimmedSearch, limit: 20)
            let (fetchedDiscovered, fetchedExisting) = try await (discovered, existing)
            let filteredDiscovered = removeExistingNames(from: fetchedDiscovered, existing: fetchedExisting)
            let hasSuggestions = !filteredDiscovered.isEmpty || !fetchedExisting.isEmpty

            withAnimation(.easeInOut(duration: 0.28)) {
                discoveryCandidates = filteredDiscovered
                existingMatches = fetchedExisting
                visibleDiscoveryCount = min(discoveryPageSize, filteredDiscovered.count)
            }

            if hasSuggestions {
                verification = nil
                generatedPerson = nil
                verifiedResult = nil
                pipelineProgress = nil
                isSearching = false

                // Enrich descriptions in background (non-blocking)
                if !filteredDiscovered.isEmpty {
                    Task { await enrichCandidateDescriptions(for: filteredDiscovered) }
                }
                return
            }

            // First verify the person exists externally
            let result = try await tavilyService.verifyPerson(name: trimmedSearch)

            if result.isFictional {
                errorMessage = "'\(trimmedSearch)' appears to be a fictional character. Please search for a real historical person."
                isSearching = false
                return
            }
            
            if !result.isVerified {
                errorMessage = "Could not find '\(trimmedSearch)'. Please check the spelling and try again."
                isSearching = false
                return
            }
            
            verification = result
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSearching = false
    }

    private func handleExistingMatchSelection(_ person: Person) {
        showExistingPerson(person)
    }

    private func handleDiscoveryCandidateSelection(_ candidate: PersonCandidate) async {
        candidateSearchTask?.cancel()
        isLoadingCandidateLists = false
        isSearching = true
        errorMessage = nil
        searchText = candidate.name

        do {
            let verificationResult = try await tavilyService.verifyPerson(name: candidate.name)

            if verificationResult.isFictional {
                errorMessage = "'\(candidate.name)' appears to be a fictional character. Please choose a real historical person."
                isSearching = false
                return
            }

            if verificationResult.isVerified {
                verification = verificationResult
            } else {
                verification = PersonVerification(
                    isVerified: true,
                    name: candidate.name,
                    summary: candidate.summary,
                    sources: []
                )
            }

            withAnimation(.easeInOut(duration: 0.28)) {
                discoveryCandidates = []
                existingMatches = []
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isSearching = false
    }

    private func handleGenerate() async {
        guard let verification, verification.isVerified else { return }
        
        isGenerating = true
        errorMessage = nil
        pipelineProgress = nil
        
        // Start database existence check early — runs in parallel with the pipeline
        // since it only needs the person name (available from verification)
        async let existingPersonCheck = supabaseService.findExistingPerson(matchingName: verification.name)
        
        var generatedPerson: Person?
        
        if useAdvancedPipeline {
            // Use the full research pipeline with fact verification
            do {
                await researchPipeline.setProgressHandler { progress in
                    Task { @MainActor in
                        self.pipelineProgress = progress
                    }
                }
                
                let result = try await researchPipeline.researchPerson(
                    name: verification.name,
                    config: .default
                )
                
                generatedPerson = result.person
            } catch {
                errorMessage = error.localizedDescription
            }
        } else {
            // Use basic generation without verification
            do {
                let context = verification.sources
                    .prefix(3)
                    .map { $0.content }
                    .joined(separator: "\n\n")
                
                let person = try await claudeService.generateHistoricalEvents(
                    name: verification.name,
                    context: context
                )
                
                generatedPerson = person
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        
        // Auto-save to Supabase and notify parent
        // The DB existence check was started at the top and has been running in parallel
        if let person = generatedPerson {
            do {
                if let existingPerson = try await existingPersonCheck {
                    onPersonCreated?(existingPerson)
                } else {
                    let savedPerson = try await supabaseService.savePerson(person)
                    onPersonCreated?(savedPerson)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        
        isGenerating = false
        pipelineProgress = nil
    }
    
    private func handleReset() {
        candidateSearchTask?.cancel()
        searchText = ""
        verification = nil
        generatedPerson = nil
        verifiedResult = nil
        errorMessage = nil
        selectedExistingPerson = nil
        withAnimation(.easeInOut(duration: 0.28)) {
            discoveryCandidates = []
            existingMatches = []
        }
        isLoadingCandidateLists = false
        visibleDiscoveryCount = discoveryPageSize
    }

    private func removeExistingNames(from candidates: [PersonCandidate], existing: [Person]) -> [PersonCandidate] {
        let existingNames = Set(existing.map { normalizeNameForComparison($0.name) })
        guard !existingNames.isEmpty else { return candidates }

        return candidates.filter { candidate in
            !existingNames.contains(normalizeNameForComparison(candidate.name))
        }
    }

    /// Enriches discovery candidates with LLM-generated one-sentence descriptions.
    /// Updates the candidates list in-place as descriptions arrive. Non-blocking; falls back gracefully.
    private func enrichCandidateDescriptions(for candidates: [PersonCandidate]) async {
        let input = candidates.map { (name: $0.name, rawSummary: $0.summary) }
        let descriptions = await claudeService.generateCandidateDescriptions(candidates: input)
        guard !descriptions.isEmpty else { return }

        // Update candidates in-place with enriched descriptions
        withAnimation(.easeInOut(duration: 0.2)) {
            for index in discoveryCandidates.indices {
                let normalizedName = discoveryCandidates[index].name
                    .lowercased()
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if let enrichedDescription = descriptions[normalizedName] {
                    discoveryCandidates[index].description = enrichedDescription
                }
            }
        }
    }

    private func normalizeNameForComparison(_ value: String) -> String {
        value
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    private func candidateBodyText(for candidate: PersonCandidate) -> String {
        // Prefer LLM-generated description when available
        if let description = candidate.description, !description.isEmpty {
            return description
        }
        let summarySentence = normalizedCandidateSummarySentence(candidate.summary)
        if !summarySentence.isEmpty { return summarySentence }
        return "No description available."
    }

    private func normalizedCandidateSummarySentence(_ summary: String) -> String {
        var cleanedSummary = summary
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Strip leftover Wikipedia artifacts (URL fragments, reference markers, bare URLs)
        let artifactPatterns: [(String, String)] = [
            ("[_#][A-Za-z0-9_#/]+\\)?", ""),           // URL fragments
            ("\\[(?:\\d+|[a-z])\\]", ""),                // [1], [a]
            ("https?://\\S+", ""),                       // bare URLs
            ("\\(\\)", ""),                               // empty parens
        ]
        for (pattern, replacement) in artifactPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                cleanedSummary = regex.stringByReplacingMatches(
                    in: cleanedSummary,
                    range: NSRange(cleanedSummary.startIndex..., in: cleanedSummary),
                    withTemplate: replacement
                )
            }
        }
        cleanedSummary = cleanedSummary
            .replacingOccurrences(of: "\\s{2,}", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanedSummary.isEmpty else { return "" }

        let endPunctuation = CharacterSet(charactersIn: ".!?")
        var sentence = ""
        for scalar in cleanedSummary.unicodeScalars {
            sentence.unicodeScalars.append(scalar)
            if endPunctuation.contains(scalar) { break }
        }

        let trimmedSentence = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
        let preferredSentence = trimmedSentence.isEmpty ? cleanedSummary : trimmedSentence
        if preferredSentence.count <= 160 { return preferredSentence }

        let cutoff = preferredSentence.index(preferredSentence.startIndex, offsetBy: 160)
        return String(preferredSentence[..<cutoff]).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
    }
}

// MARK: - Create Step

enum CreateStep {
    case search
    case verified
}

#Preview {
    CreateView()
}
