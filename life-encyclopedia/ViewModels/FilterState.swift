//
//  FilterState.swift
//  life-encyclopedia
//
//  Simplified observable state for filtering historical figures
//  Uses progressive disclosure: primary filters visible, advanced hidden
//

import Foundation
import SwiftUI

@Observable
final class FilterState {
    
    // MARK: - Search
    
    /// Draft search text while the user types.
    var searchText: String = ""
    
    /// Applied search text used for querying and filtering.
    var committedSearchText: String = ""
    
    // MARK: - Primary Filters (Always Visible)
    
    /// Selected eras (simplified time periods)
    var selectedEras: Set<Era> = []
    
    /// Selected domains (what they're known for)
    var selectedDomains: Set<Domain> = []
    
    /// Selected cultural regions (where they're from)
    var selectedRegions: Set<CulturalRegion> = []
    
    /// Optional impact level filter
    var selectedImpactLevel: ImpactLevel? = nil
    
    // MARK: - Sorting
    
    /// Current sort option
    var sortBy: SortOption = .createdAt
    
    /// Sort direction
    var sortDirection: SortDirection = .descending
    
    // MARK: - Advanced Filters (Hidden by Default)
    
    /// Advanced/power-user filters
    var advancedFilters = AdvancedFilters()
    
    // MARK: - Computed Properties
    
    /// Total number of active primary filters
    var activeFilterCount: Int {
        (normalizedSearchText.isEmpty ? 0 : 1) +
        selectedEras.count +
        selectedDomains.count +
        selectedRegions.count +
        (selectedImpactLevel != nil ? 1 : 0) +
        advancedFilters.activeCount
    }
    
    /// Whether any filters are active
    var hasActiveFilters: Bool {
        activeFilterCount > 0
    }
    
    /// Whether sorting is customized from default
    var hasCustomSort: Bool {
        sortBy != .createdAt || sortDirection != .descending
    }
    
    /// Whether advanced filters are in use
    var hasAdvancedFilters: Bool {
        !advancedFilters.isEmpty
    }
    
    // MARK: - Active Filter Pills
    
    /// Get all active filters as displayable pills
    var activeFilterPills: [FilterPill] {
        var pills: [FilterPill] = []
        
        if !normalizedSearchText.isEmpty {
            pills.append(FilterPill(
                id: "search",
                label: "\"\(normalizedSearchText)\"",
                icon: "magnifyingglass",
                category: .coreIdentity
            ))
        }
        
        // Era filters
        for era in selectedEras {
            pills.append(FilterPill(
                id: "era-\(era.rawValue)",
                label: era.displayName,
                icon: era.iconName,
                category: .coreIdentity
            ))
        }
        
        // Domain filters
        for domain in selectedDomains {
            pills.append(FilterPill(
                id: "domain-\(domain.rawValue)",
                label: domain.displayName,
                icon: domain.iconName,
                category: .domain
            ))
        }
        
        // Region filters
        for region in selectedRegions {
            pills.append(FilterPill(
                id: "region-\(region.rawValue)",
                label: region.displayName,
                icon: region.iconName,
                category: .coreIdentity
            ))
        }
        
        // Impact level
        if let impact = selectedImpactLevel {
            pills.append(FilterPill(
                id: "impact-\(impact.rawValue)",
                label: impact.displayName,
                icon: impact.iconName,
                category: .scale
            ))
        }
        
        // Advanced filters
        for archetype in advancedFilters.archetypes {
            pills.append(FilterPill(
                id: "archetype-\(archetype.rawValue)",
                label: archetype.displayName,
                icon: archetype.iconName,
                category: .narrative
            ))
        }
        
        for valence in advancedFilters.moralValences {
            pills.append(FilterPill(
                id: "valence-\(valence.rawValue)",
                label: valence.displayName,
                icon: "scale.3d",
                category: .narrative
            ))
        }
        
        for arc in advancedFilters.lifeArcs {
            pills.append(FilterPill(
                id: "arc-\(arc.rawValue)",
                label: arc.displayName,
                icon: "chart.line.uptrend.xyaxis",
                category: .narrative
            ))
        }
        
        for mode in advancedFilters.influenceModes {
            pills.append(FilterPill(
                id: "influence-\(mode.rawValue)",
                label: mode.displayName,
                icon: "bolt",
                category: .influence
            ))
        }
        
        return pills
    }
    
    var querySignature: String {
        let parts: [String] = [
            "q:\(normalizedSearchText.lowercased())",
            "eras:\(selectedEras.map(\.rawValue).sorted().joined(separator: ","))",
            "domains:\(selectedDomains.map(\.rawValue).sorted().joined(separator: ","))",
            "regions:\(selectedRegions.map(\.rawValue).sorted().joined(separator: ","))",
            "impact:\(selectedImpactLevel?.rawValue ?? "-")",
            "archetypes:\(advancedFilters.archetypes.map(\.rawValue).sorted().joined(separator: ","))",
            "valences:\(advancedFilters.moralValences.map(\.rawValue).sorted().joined(separator: ","))",
            "arcs:\(advancedFilters.lifeArcs.map(\.rawValue).sorted().joined(separator: ","))",
            "influence:\(advancedFilters.influenceModes.map(\.rawValue).sorted().joined(separator: ","))",
            "sort:\(sortBy.rawValue):\(sortDirection.rawValue)"
        ]
        return parts.joined(separator: "|")
    }
    
    var normalizedSearchText: String {
        committedSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var normalizedDraftSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Methods
    
    /// Reset all filters to defaults
    func reset() {
        searchText = ""
        committedSearchText = ""
        selectedEras = []
        selectedDomains = []
        selectedRegions = []
        selectedImpactLevel = nil
        advancedFilters.reset()
        sortBy = .createdAt
        sortDirection = .descending
    }
    
    /// Reset only primary filters (keep advanced)
    func resetPrimary() {
        selectedEras = []
        selectedDomains = []
        selectedRegions = []
        selectedImpactLevel = nil
    }
    
    /// Remove a specific filter by pill ID
    func removeFilter(pillId: String) {
        if pillId == "search" {
            clearSearch()
            return
        }
        
        let parts = pillId.split(separator: "-", maxSplits: 1)
        guard parts.count == 2 else { return }
        
        let type = String(parts[0])
        let rawValue = String(parts[1])
        
        switch type {
        case "era":
            if let era = Era(rawValue: rawValue) {
                selectedEras.remove(era)
            }
            
        case "domain":
            if let domain = Domain(rawValue: rawValue) {
                selectedDomains.remove(domain)
            }
            
        case "region":
            if let region = CulturalRegion(rawValue: rawValue) {
                selectedRegions.remove(region)
            }
            
        case "impact":
            if ImpactLevel(rawValue: rawValue) != nil {
                selectedImpactLevel = nil
            }
            
        case "archetype":
            if let archetype = Archetype(rawValue: rawValue) {
                advancedFilters.archetypes.remove(archetype)
            }
            
        case "valence":
            if let valence = MoralValence(rawValue: rawValue) {
                advancedFilters.moralValences.remove(valence)
            }
            
        case "arc":
            if let arc = LifeArc(rawValue: rawValue) {
                advancedFilters.lifeArcs.remove(arc)
            }
            
        case "influence":
            if let mode = InfluenceMode(rawValue: rawValue) {
                advancedFilters.influenceModes.remove(mode)
            }
            
        default:
            break
        }
    }
    
    /// Check if a person matches the current filters
    func matches(_ person: Person) -> Bool {
        let metadata = person.filterMetadata
        
        // Era filter
        if !selectedEras.isEmpty {
            let matchesEra = metadata.era.map { selectedEras.contains($0) } ?? false
            let matchesLiving = selectedEras.contains(.living) && person.isLiving
            
            if !matchesEra && !matchesLiving {
                return false
            }
        }
        
        // Domain filter (includes secondary domains by default)
        if !selectedDomains.isEmpty {
            let matchesPrimary = metadata.primaryDomain.map { selectedDomains.contains($0) } ?? false
            let matchesSecondary = metadata.secondaryDomains.contains(where: { selectedDomains.contains($0) })
            
            if !matchesPrimary && !matchesSecondary {
                return false
            }
        }
        
        // Region filter
        if !selectedRegions.isEmpty {
            guard let region = metadata.culturalRegion,
                  selectedRegions.contains(region) else {
                return false
            }
        }
        
        // Impact level filter
        if let requiredImpact = selectedImpactLevel {
            if metadata.impactLevel.sortValue < requiredImpact.sortValue {
                return false
            }
        }
        
        // Advanced filters
        if !advancedFilters.isEmpty {
            // Archetype filter
            if !advancedFilters.archetypes.isEmpty {
                guard let archetype = metadata.archetype,
                      advancedFilters.archetypes.contains(archetype) else {
                    return false
                }
            }
            
            // Moral valence filter
            if !advancedFilters.moralValences.isEmpty {
                guard let valence = metadata.moralValence,
                      advancedFilters.moralValences.contains(valence) else {
                    return false
                }
            }
            
            // Life arc filter
            if !advancedFilters.lifeArcs.isEmpty {
                guard let arc = metadata.lifeArc,
                      advancedFilters.lifeArcs.contains(arc) else {
                    return false
                }
            }
            
            // Influence mode filter
            if !advancedFilters.influenceModes.isEmpty {
                let hasMatchingInfluence = advancedFilters.influenceModes.contains { mode in
                    metadata.influenceScore(for: mode) >= 1
                }
                if !hasMatchingInfluence {
                    return false
                }
            }
        }
        
        return true
    }
    
    /// Sort an array of people based on current sort settings
    func sorted(_ people: [Person]) -> [Person] {
        people.sorted { a, b in
            let comparison: Bool
            
            switch sortBy {
            case .birthYear:
                let aYear = a.filterMetadata.birthYear ?? 0
                let bYear = b.filterMetadata.birthYear ?? 0
                comparison = aYear < bYear
                
            case .deathYear:
                let aYear = a.filterMetadata.deathYear ?? Int.max
                let bYear = b.filterMetadata.deathYear ?? Int.max
                comparison = aYear < bYear
                
            case .name:
                comparison = a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
                
            case .createdAt:
                comparison = a.createdAt < b.createdAt
                
            case .recognitionLevel:
                let aLevel = a.filterMetadata.recognitionLevel?.sortValue ?? 0
                let bLevel = b.filterMetadata.recognitionLevel?.sortValue ?? 0
                comparison = aLevel < bLevel
                
            case .domainCount:
                let aCount = a.filterMetadata.allDomains.count
                let bCount = b.filterMetadata.allDomains.count
                comparison = aCount < bCount
            }
            
            return sortDirection == .ascending ? comparison : !comparison
        }
    }
    
    /// Filter and sort an array of people
    func apply(to people: [Person]) -> [Person] {
        let filtered = people.filter { person in
            if !normalizedSearchText.isEmpty &&
                !person.name.localizedCaseInsensitiveContains(normalizedSearchText) {
                return false
            }
            return matches(person)
        }
        return sorted(filtered)
    }
    
    /// Build a unified server query from current UI state.
    func makePeopleQuery(page: Int, pageSize: Int) -> PeopleQuery {
        PeopleQuery(
            searchText: normalizedSearchText,
            selectedEras: selectedEras,
            selectedDomains: selectedDomains,
            selectedRegions: selectedRegions,
            selectedImpactLevel: selectedImpactLevel,
            advancedFilters: advancedFilters,
            sortBy: sortBy,
            sortDirection: sortDirection,
            page: max(1, page),
            pageSize: max(1, pageSize)
        )
    }
    
    /// Apply refinements that are currently easier to compute on-device.
    /// This keeps server querying broad while preserving richer local behavior.
    func applyClientRefinements(to people: [Person], includeSearchFallback: Bool = false) -> [Person] {
        let filtered = people.filter { person in
            if includeSearchFallback && !normalizedSearchText.isEmpty &&
                !person.name.localizedCaseInsensitiveContains(normalizedSearchText) {
                return false
            }
            return matches(person)
        }
        
        return sorted(filtered)
    }
    
    /// Apply the currently typed search text to active querying/filtering state.
    func commitSearch() {
        committedSearchText = normalizedDraftSearchText
    }
    
    /// Clear draft and committed search text.
    func clearSearch() {
        searchText = ""
        committedSearchText = ""
    }
}

// MARK: - Filter Pill

struct FilterPill: Identifiable, Equatable {
    let id: String
    let label: String
    let icon: String
    let category: FilterCategory
    var isExclusion: Bool = false
}

enum FilterCategory {
    case coreIdentity
    case domain
    case influence
    case scale
    case narrative
    
    var displayName: String {
        switch self {
        case .coreIdentity: return "Era & Geography"
        case .domain: return "Domain"
        case .influence: return "Influence"
        case .scale: return "Scale"
        case .narrative: return "Narrative"
        }
    }
}

// MARK: - Recognition Level Sort Extension

extension RecognitionLevel {
    var sortValue: Int {
        switch self {
        case .obscure: return 0
        case .fieldFamous: return 1
        case .publiclyFamous: return 2
        case .canonical: return 3
        }
    }
}
