//
//  HomeView.swift
//  life-encyclopedia
//
//  Main view showing library of generated historical profiles with filtering
//

import SwiftUI

struct HomeView: View {
    @State private var allPeople: [Person] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showCreateSheet = false
    
    // Filter state
    @State private var filterState = FilterState()
    
    private let supabaseService = SupabaseService()
    
    /// Filtered and sorted people based on current filter state
    private var filteredPeople: [Person] {
        filterState.apply(to: allPeople)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Unified filter bar (always visible when there are people)
                if !allPeople.isEmpty {
                    FilterBar(filterState: filterState)
                }
                
                // Main content
                Group {
                    if isLoading && allPeople.isEmpty {
                        loadingView
                    } else if allPeople.isEmpty {
                        emptyStateView
                    } else if filteredPeople.isEmpty {
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
            .refreshable {
                await loadPeople()
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
            .sheet(isPresented: $showCreateSheet) {
                CreateView()
            }
            .navigationDestination(for: Person.self) { person in
                PersonDetailView(
                    person: person,
                    onViewTracked: {
                        Task {
                            await loadPeople()
                        }
                    }
                )
            }
        }
        .task {
            await loadPeople()
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
                
                Text("Try adjusting your filters\nto see more results.")
                    .font(.bodyMedium)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                withAnimation(.spring(duration: 0.25)) {
                    filterState.reset()
                }
            } label: {
                Text("Clear Filters")
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
                // Results count header
                if filterState.hasActiveFilters {
                    HStack {
                        Text("\(filteredPeople.count) of \(allPeople.count) people")
                            .font(.caption)
                            .foregroundStyle(.textTertiary)
                        
                        Spacer()
                        
                        if filterState.hasCustomSort {
                            Text("Sorted by \(filterState.sortBy.displayName.lowercased())")
                                .font(.caption)
                                .foregroundStyle(.textTertiary)
                        }
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                }
                
                ForEach(filteredPeople) { person in
                    NavigationLink(value: person) {
                        PersonCard(person: person)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.xxl)
        }
        .background(Color.surfacePrimary)
    }
    
    // MARK: - Methods
    
    private func loadPeople() async {
        isLoading = true
        errorMessage = nil
        
        do {
            allPeople = try await supabaseService.fetchPeople()
        } catch is CancellationError {
            // Silently ignore - task was cancelled intentionally by SwiftUI
        } catch let urlError as URLError where urlError.code == .cancelled {
            // Silently ignore URLSession cancellation
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

// MARK: - Person Card (Editorial Style)

struct PersonCard: View {
    let person: Person
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header with name and domain badge
            HStack(alignment: .top) {
                Text(person.name)
                    .font(.system(size: 22, weight: .regular, design: .serif))
                    .foregroundStyle(.textPrimary)
                
                Spacer()
                
                // Domain badge if available
                if let domain = person.filterMetadata.primaryDomain {
                    Image(systemName: domain.iconName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.textTertiary)
                        .padding(6)
                        .background(Color.surfaceSecondary)
                        .clipShape(Circle())
                }
            }
            
            // Lifespan and region
            HStack(spacing: Spacing.sm) {
                if let lifeSpan = person.lifeSpan {
                    Text(lifeSpan)
                        .font(.caption)
                        .foregroundStyle(.textTertiary)
                        .tracking(0.5)
                }
                
                if let region = person.filterMetadata.culturalRegion {
                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.textTertiary)
                    
                    Text(region.displayName)
                        .font(.caption)
                        .foregroundStyle(.textTertiary)
                }
            }
            
            // Summary as body text
            Text(person.summary)
                .font(.bodyMediumSerif)
                .foregroundStyle(.textSecondary)
                .lineLimit(3)
                .lineSpacing(4)
                .padding(.top, Spacing.xxs)
            
            // Tags row if metadata exists
            if person.filterMetadata.primaryDomain != nil || person.filterMetadata.archetype != nil {
                HStack(spacing: Spacing.xs) {
                    if let domain = person.filterMetadata.primaryDomain {
                        PersonTagView(text: domain.displayName, icon: domain.iconName)
                    }
                    
                    if let archetype = person.filterMetadata.archetype {
                        PersonTagView(text: archetype.displayName, icon: archetype.iconName)
                    }
                    
                    Spacer()
                }
                .padding(.top, Spacing.xs)
            }
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
