//
//  HomeView.swift
//  life-encyclopedia
//
//  Main view showing library of generated historical profiles with filtering
//

import SwiftUI

struct HomeView: View {
    @State private var loadedPeople: [Person] = []
    @State private var isInitialLoading = false
    @State private var isLoadingMore = false
    @State private var hasMorePages = false
    @State private var currentPage = 1
    @State private var totalCount: Int?
    
    @State private var deletingPersonID: UUID?
    @State private var errorMessage: String?
    @State private var showCreateSheet = false
    @State private var personPendingDeletion: Person?
    @State private var debouncedReloadTask: Task<Void, Never>?
    
    @State private var filterState = FilterState()
    
    private let supabaseService = SupabaseService()
    private let pageSize = 30
    
    private var visiblePeople: [Person] {
        filterState.applyClientRefinements(to: loadedPeople)
    }
    
    private var isLibraryEmpty: Bool {
        (totalCount ?? 0) == 0 &&
        filterState.normalizedSearchText.isEmpty &&
        !filterState.hasActiveFilters
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !isLibraryEmpty || !loadedPeople.isEmpty {
                    FilterBar(
                        filterState: filterState,
                        resultCount: visiblePeople.count,
                        totalCount: totalCount,
                        isLoading: isInitialLoading || isLoadingMore
                    )
                }
                
                Group {
                    if isInitialLoading && loadedPeople.isEmpty {
                        loadingView
                    } else if isLibraryEmpty {
                        emptyStateView
                    } else if visiblePeople.isEmpty {
                        noResultsView
                    } else {
                        peopleListView
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                    .accessibilityLabel("Create new profile")
                }
            }
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage {
                    Text(errorMessage)
                }
            }
            .confirmationDialog(
                personPendingDeletion.map { "Delete \($0.name)?" } ?? "Delete profile?",
                isPresented: Binding(
                    get: { personPendingDeletion != nil },
                    set: { isPresented in
                        if !isPresented {
                            personPendingDeletion = nil
                        }
                    }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    guard let person = personPendingDeletion else { return }
                    personPendingDeletion = nil
                    Task {
                        await deletePerson(person)
                    }
                }
                Button("Cancel", role: .cancel) {
                    personPendingDeletion = nil
                }
            } message: {
                Text("This will permanently remove this profile from your library.")
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateView()
            }
            .onChange(of: filterState.querySignature) { _, _ in
                scheduleDebouncedReload()
            }
            .navigationDestination(for: Person.self) { person in
                PersonDetailView(
                    person: person,
                    onViewTracked: {
                        Task {
                            await reloadFirstPage()
                        }
                    }
                )
            }
        }
        .task {
            await reloadFirstPage()
        }
        .onDisappear {
            debouncedReloadTask?.cancel()
        }
    }
    
    // MARK: - Views
    
    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            Image(systemName: "books.vertical")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.quaternary)
            
            VStack(spacing: Spacing.sm) {
                Text("Your library is empty")
                    .font(.headlineSmall)
                    .foregroundStyle(.secondary)
                
                Text("Create your first historical profile\nusing the + button above.")
                    .font(.bodyMedium)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            Spacer()
        }
        .padding(Spacing.xl)
    }
    
    private var noResultsView: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.quaternary)
            
            VStack(spacing: Spacing.sm) {
                Text("No matches found")
                    .font(.headlineSmall)
                    .foregroundStyle(.secondary)
                
                Text("Try changing your search or filter choices\nto discover more people.")
                    .font(.bodyMedium)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                withAnimation(.spring(duration: 0.25)) {
                    filterState.reset()
                }
            } label: {
                Text("Clear Search & Filters")
                    .font(.labelLarge)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            
            Spacer()
            Spacer()
        }
        .padding(Spacing.xl)
    }
    
    private var peopleListView: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                ForEach(visiblePeople) { person in
                    NavigationLink(value: person) {
                        PersonCard(person: person)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            personPendingDeletion = person
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .disabled(deletingPersonID == person.id)
                    }
                    .onAppear {
                        if person.id == visiblePeople.last?.id {
                            Task {
                                await loadNextPageIfNeeded()
                            }
                        }
                    }
                }
                
                if isLoadingMore {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                } else if hasMorePages {
                    Button("Load more") {
                        Task {
                            await loadNextPageIfNeeded()
                        }
                    }
                    .buttonStyle(.plain)
                    .font(.bodySmall)
                    .foregroundStyle(.textTertiary)
                    .padding(.vertical, Spacing.md)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.xxl)
        }
        .refreshable {
            await reloadFirstPage()
        }
        .background(Color.surfacePrimary)
    }
    
    // MARK: - Methods
    
    private func scheduleDebouncedReload() {
        debouncedReloadTask?.cancel()
        debouncedReloadTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            if Task.isCancelled { return }
            await reloadFirstPage()
        }
    }
    
    @MainActor
    private func reloadFirstPage() async {
        isInitialLoading = true
        errorMessage = nil
        defer { isInitialLoading = false }
        
        let requestSignature = filterState.querySignature
        let query = filterState.makePeopleQuery(page: 1, pageSize: pageSize)
        
        do {
            let page = try await supabaseService.fetchPeople(query: query)
            
            if requestSignature != filterState.querySignature {
                return
            }
            
            loadedPeople = page.people
            totalCount = page.totalCount ?? page.people.count
            hasMorePages = page.hasMore
            currentPage = page.page
        } catch let supabaseError as SupabaseService.SupabaseError {
            errorMessage = supabaseError.errorDescription
        } catch is CancellationError {
        } catch let urlError as URLError where urlError.code == .cancelled {
        } catch {
            errorMessage = "Unable to load people right now. Please verify your Supabase URL and anon key."
        }
    }
    
    @MainActor
    private func loadNextPageIfNeeded() async {
        if isLoadingMore || isInitialLoading || !hasMorePages {
            return
        }
        
        let requestSignature = filterState.querySignature
        let nextPage = currentPage + 1
        let query = filterState.makePeopleQuery(page: nextPage, pageSize: pageSize)
        
        isLoadingMore = true
        defer { isLoadingMore = false }
        
        do {
            let page = try await supabaseService.fetchPeople(query: query)
            
            if requestSignature != filterState.querySignature {
                return
            }
            
            let existingIDs = Set(loadedPeople.map(\.id))
            let uniquePeople = page.people.filter { !existingIDs.contains($0.id) }
            loadedPeople.append(contentsOf: uniquePeople)
            totalCount = page.totalCount ?? totalCount
            hasMorePages = page.hasMore
            currentPage = page.page
        } catch let supabaseError as SupabaseService.SupabaseError {
            errorMessage = supabaseError.errorDescription
        } catch is CancellationError {
        } catch let urlError as URLError where urlError.code == .cancelled {
        } catch {
            errorMessage = "Unable to load more results right now. Please try again."
        }
    }
    
    @MainActor
    private func removeDeletedPerson(_ person: Person) {
        loadedPeople.removeAll { $0.id == person.id }
        if let totalCount {
            self.totalCount = max(0, totalCount - 1)
        } else {
            totalCount = loadedPeople.count
        }
    }
    
    @MainActor
    private func deletePerson(_ person: Person) async {
        guard deletingPersonID == nil else { return }
        
        deletingPersonID = person.id
        defer { deletingPersonID = nil }
        
        do {
            try await supabaseService.deletePerson(id: person.id)
            withAnimation(.spring(duration: 0.22)) {
                removeDeletedPerson(person)
            }
        } catch let supabaseError as SupabaseService.SupabaseError {
            errorMessage = supabaseError.errorDescription
        } catch is CancellationError {
        } catch let urlError as URLError where urlError.code == .cancelled {
        } catch {
            errorMessage = "Unable to delete this profile right now. Please try again."
        }
    }
}

// MARK: - Person Card (Editorial Style)

struct PersonCard: View {
    let person: Person
    
    private var activeYearsText: String {
        let eventYears = person.events.compactMap(\.year)
        if let firstActiveYear = eventYears.min(), let lastActiveYear = eventYears.max() {
            if firstActiveYear == lastActiveYear {
                return "\(firstActiveYear)"
            }
            return "\(firstActiveYear) - \(lastActiveYear)"
        }
        
        let birthYear = person.filterMetadata.birthYear ?? extractYear(from: person.birthDate)
        let deathYear = person.filterMetadata.deathYear ?? extractYear(from: person.deathDate)
        
        if let birthYear, let deathYear {
            return "\(birthYear) - \(deathYear)"
        }
        
        if let birthYear {
            return "\(birthYear) - Present"
        }
        
        if let deathYear {
            return deathYear.description
        }
        
        return "Active years unknown"
    }
    
    private func extractYear(from value: String?) -> Int? {
        guard let value else { return nil }
        
        let numericSegments = value.split { !$0.isNumber }
        for segment in numericSegments {
            guard segment.count == 4, let year = Int(segment), (1000...2999).contains(year) else {
                continue
            }
            return year
        }
        
        return nil
    }
    
    private var oneSentenceSummary: String {
        let trimmed = person.summary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Preset" }
        
        let sentenceBreaks = CharacterSet(charactersIn: ".!?")
        if let punctuationIndex = trimmed.rangeOfCharacter(from: sentenceBreaks)?.upperBound {
            return String(trimmed[..<punctuationIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return trimmed
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(person.name)
                .font(.system(size: 22, weight: .regular, design: .serif))
                .foregroundStyle(.textPrimary)
            
            Text(activeYearsText)
                .font(.caption)
                .foregroundStyle(.textTertiary)
                .tracking(0.5)
            
            Text(oneSentenceSummary)
                .font(.bodyMediumSerif)
                .foregroundStyle(.textSecondary)
                .lineLimit(2)
                .lineSpacing(4)
                .padding(.top, Spacing.xxs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.cardPadding)
        .background(Color.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .contentShape(Rectangle())
    }
}

// MARK: - Person Tag View

struct PersonTagView: View {
    let text: String
    let icon: String?
    
    init(text: String, icon: String? = nil) {
        self.text = text
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .medium))
            }
            
            Text(text)
                .font(.caption2)
        }
        .foregroundStyle(.textTertiary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.surfaceSecondary)
        .clipShape(Capsule())
    }
}

#Preview("Home - With People") {
    HomeView()
}

#Preview("Person Card") {
    PersonCard(person: Person(
        name: "Albert Einstein",
        birthDate: "1879",
        deathDate: "1955",
        summary: "German-born theoretical physicist who developed the theory of relativity, one of the two pillars of modern physics alongside quantum mechanics.",
        events: [],
        filterMetadata: FilterMetadata(
            birthYear: 1879,
            deathYear: 1955,
            culturalRegion: .westernEurope,
            primaryDomain: .science,
            archetype: .visionary
        )
    ))
    .padding()
}
