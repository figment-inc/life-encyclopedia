//
//  CreateView.swift
//  life-encyclopedia
//
//  Create tab for searching and generating person history
//

import SwiftUI

struct CreateView: View {
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
    
    @State private var existingMatches: [Person] = []
    @State private var showExistingMatchesSheet = false
    @State private var selectedExistingPerson: Person?
    @State private var pendingVerification: PersonVerification?
    
    // MARK: - Services
    
    private let tavilyService = TavilyService()
    private let claudeService = ClaudeService()
    private let supabaseService = SupabaseService()
    private let researchPipeline = ResearchPipeline()
    
    // MARK: - Computed
    
    private var isLoading: Bool {
        isSearching || isGenerating
    }
    
    private var currentStep: CreateStep {
        if generatedPerson != nil {
            return .result
        } else if verification?.isVerified == true {
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
                case .result:
                    resultView
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
            .sheet(isPresented: $showExistingMatchesSheet) {
                existingMatchesSheet
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
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: Spacing.xl) {
                // Icon and title
                VStack(spacing: Spacing.md) {
                    Image(systemName: "person.text.rectangle")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(.quaternary)
                    
                    Text("Research a historical figure")
                        .font(.bodyMedium)
                        .foregroundStyle(.secondary)
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
                    .disabled(searchText.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                }
                .padding(.horizontal, Spacing.xl)
            }
            
            Spacer()
            Spacer()
        }
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
    
    // MARK: - Result View
    
    private var resultView: some View {
        Group {
            if let person = generatedPerson {
                PersonDetailView(
                    person: person,
                    showSaveButton: true,
                    onSave: handleSave,
                    onDismiss: handleReset
                )
            }
        }
    }
    
    // MARK: - Existing Matches Sheet
    
    private var existingMatchesSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header explanation
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "person.fill.checkmark")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(.brandPrimary)
                    
                    Text("Entry Already Exists")
                        .font(.system(size: 20, weight: .semibold, design: .serif))
                    
                    Text("We found an existing entry that matches your search. Would you like to view it?")
                        .font(.bodySmall)
                        .foregroundStyle(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.md)
                
                // List of existing matches
                List {
                    ForEach(existingMatches) { person in
                        Button(action: {
                            showExistingMatchesSheet = false
                            selectedExistingPerson = person
                        }) {
                            HStack(spacing: Spacing.md) {
                                VStack(alignment: .leading, spacing: Spacing.xxs) {
                                    Text(person.name)
                                        .font(.bodyMedium)
                                        .foregroundStyle(.textPrimary)
                                    
                                    if let birthYear = person.filterMetadata.birthYear, let deathYear = person.filterMetadata.deathYear {
                                        Text("\(birthYear) – \(deathYear)")
                                            .font(.caption)
                                            .foregroundStyle(.textTertiary)
                                    } else if let birthYear = person.filterMetadata.birthYear {
                                        Text("Born \(birthYear)")
                                            .font(.caption)
                                            .foregroundStyle(.textTertiary)
                                    }
                                    
                                    Text("\(person.events.count) events")
                                        .font(.caption)
                                        .foregroundStyle(.textTertiary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.textTertiary)
                            }
                            .padding(.vertical, Spacing.xs)
                        }
                        .listRowBackground(Color.surfaceCard)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                
                // Create new anyway button
                VStack(spacing: Spacing.sm) {
                    Divider()
                    
                    Button(action: handleContinueWithCreation) {
                        Text("Create New Entry Anyway")
                            .font(.bodySmall)
                            .foregroundStyle(.textTertiary)
                    }
                    .padding(.vertical, Spacing.md)
                }
            }
            .background(Color.surfacePrimary)
            .navigationTitle("Existing Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        showExistingMatchesSheet = false
                        pendingVerification = nil
                        handleReset()
                    }
                }
            }
        }
    }
    
    // MARK: - Methods
    
    private func handleSearch() async {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmedSearch.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        
        do {
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
            
            // Person is verified - now check if they already exist in our database
            let existingPeople = try await supabaseService.searchPeople(byName: trimmedSearch)
            
            if !existingPeople.isEmpty {
                // Found existing entries - show the sheet to let user decide
                existingMatches = existingPeople
                pendingVerification = result
                showExistingMatchesSheet = true
            } else {
                // No existing entries - proceed with normal flow
                verification = result
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSearching = false
    }
    
    private func handleContinueWithCreation() {
        // User chose to create a new entry despite existing matches
        showExistingMatchesSheet = false
        if let pending = pendingVerification {
            verification = pending
            pendingVerification = nil
        }
        existingMatches = []
    }
    
    private func handleGenerate() async {
        guard let verification, verification.isVerified else { return }
        
        isGenerating = true
        errorMessage = nil
        pipelineProgress = nil
        
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
                verifiedResult = result
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
        
        isGenerating = false
        pipelineProgress = nil
    }
    
    private func handleSave() async {
        guard let person = generatedPerson else { return }
        
        do {
            _ = try await supabaseService.savePerson(person)
            handleReset()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func handleReset() {
        searchText = ""
        verification = nil
        generatedPerson = nil
        verifiedResult = nil
        errorMessage = nil
        existingMatches = []
        pendingVerification = nil
        selectedExistingPerson = nil
    }
}

// MARK: - Create Step

enum CreateStep {
    case search
    case verified
    case result
}

#Preview {
    CreateView()
}
