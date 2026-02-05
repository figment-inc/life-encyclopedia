//
//  FilterBar.swift
//  life-encyclopedia
//
//  Simplified unified filter bar with three pillars: Era, Domain, Region
//  Plus overflow menu for Impact Level, Sort, and Advanced filters
//

import SwiftUI

struct FilterBar: View {
    @Bindable var filterState: FilterState
    
    @State private var showEraMenu = false
    @State private var showDomainMenu = false
    @State private var showRegionMenu = false
    @State private var showMoreMenu = false
    @State private var showAdvancedSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Primary filter row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xs) {
                    // Era picker
                    FilterDropdown(
                        label: eraLabel,
                        icon: "calendar",
                        isActive: !filterState.selectedEras.isEmpty
                    ) {
                        showEraMenu = true
                    }
                    .popover(isPresented: $showEraMenu) {
                        EraPickerView(selected: $filterState.selectedEras)
                            .presentationCompactAdaptation(.popover)
                    }
                    
                    // Domain picker
                    FilterDropdown(
                        label: domainLabel,
                        icon: "square.grid.2x2",
                        isActive: !filterState.selectedDomains.isEmpty
                    ) {
                        showDomainMenu = true
                    }
                    .popover(isPresented: $showDomainMenu) {
                        DomainPickerView(selected: $filterState.selectedDomains)
                            .presentationCompactAdaptation(.popover)
                    }
                    
                    // Region picker
                    FilterDropdown(
                        label: regionLabel,
                        icon: "globe",
                        isActive: !filterState.selectedRegions.isEmpty
                    ) {
                        showRegionMenu = true
                    }
                    .popover(isPresented: $showRegionMenu) {
                        RegionPickerView(selected: $filterState.selectedRegions)
                            .presentationCompactAdaptation(.popover)
                    }
                    
                    // More options (overflow)
                    MoreOptionsButton(
                        hasActiveFilters: filterState.selectedImpactLevel != nil || filterState.hasAdvancedFilters,
                        sortBy: filterState.sortBy
                    ) {
                        showMoreMenu = true
                    }
                    .popover(isPresented: $showMoreMenu) {
                        MoreOptionsMenu(
                            filterState: filterState,
                            onAdvancedTap: {
                                showMoreMenu = false
                                showAdvancedSheet = true
                            }
                        )
                        .presentationCompactAdaptation(.popover)
                    }
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.vertical, Spacing.xs)
            }
            
            // Active filter pills (if any)
            if filterState.hasActiveFilters {
                activeFilterPills
            }
        }
        .background(Color.surfacePrimary)
        .sheet(isPresented: $showAdvancedSheet) {
            AdvancedFiltersSheet(filterState: filterState)
                .presentationDetents([.medium])
        }
    }
    
    // MARK: - Computed Labels
    
    private var eraLabel: String {
        if filterState.selectedEras.isEmpty {
            return "Era"
        }
        if filterState.selectedEras.count == 1, let era = filterState.selectedEras.first {
            return era.displayName
        }
        return "Era (\(filterState.selectedEras.count))"
    }
    
    private var domainLabel: String {
        if filterState.selectedDomains.isEmpty {
            return "Domain"
        }
        if filterState.selectedDomains.count == 1, let domain = filterState.selectedDomains.first {
            return domain.displayName
        }
        return "Domain (\(filterState.selectedDomains.count))"
    }
    
    private var regionLabel: String {
        if filterState.selectedRegions.isEmpty {
            return "Region"
        }
        if filterState.selectedRegions.count == 1, let region = filterState.selectedRegions.first {
            return region.displayName
        }
        return "Region (\(filterState.selectedRegions.count))"
    }
    
    // MARK: - Active Filter Pills
    
    private var activeFilterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(filterState.activeFilterPills) { pill in
                    RemovableFilterPill(pill: pill) {
                        withAnimation(.spring(duration: 0.25)) {
                            filterState.removeFilter(pillId: pill.id)
                        }
                    }
                }
                
                Button {
                    withAnimation(.spring(duration: 0.25)) {
                        filterState.reset()
                    }
                } label: {
                    Text("Clear all")
                        .font(.caption)
                        .foregroundStyle(.textTertiary)
                }
                .buttonStyle(.plain)
                .padding(.leading, Spacing.xxs)
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.xs)
        }
    }
}

// MARK: - Filter Dropdown Button

struct FilterDropdown: View {
    let label: String
    let icon: String
    let isActive: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(label)
                    .font(.labelMedium)
                    .lineLimit(1)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
            .background(isActive ? Color.accentColor.opacity(0.1) : Color.surfaceSecondary)
            .foregroundStyle(isActive ? Color.accentColor : Color.textPrimary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label) filter")
        .accessibilityHint("Double tap to open filter options")
    }
}

// MARK: - More Options Button

struct MoreOptionsButton: View {
    let hasActiveFilters: Bool
    let sortBy: SortOption
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .medium))
                
                if hasActiveFilters {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(hasActiveFilters ? Color.accentColor.opacity(0.1) : Color.surfaceSecondary)
            .foregroundStyle(hasActiveFilters ? Color.accentColor : Color.textPrimary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("More filter options")
    }
}

// MARK: - Era Picker View

struct EraPickerView: View {
    @Binding var selected: Set<Era>
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(Era.allCases) { era in
                    Button {
                        toggleSelection(era)
                    } label: {
                        HStack {
                            Image(systemName: era.iconName)
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(era.displayName)
                                    .foregroundStyle(.textPrimary)
                                Text(era.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.textTertiary)
                            }
                            
                            Spacer()
                            
                            if selected.contains(era) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Era")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
                if !selected.isEmpty {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Clear") {
                            selected = []
                        }
                    }
                }
            }
        }
        .frame(minWidth: 300, minHeight: 400)
    }
    
    private func toggleSelection(_ era: Era) {
        if selected.contains(era) {
            selected.remove(era)
        } else {
            selected.insert(era)
        }
    }
}

// MARK: - Domain Picker View

struct DomainPickerView: View {
    @Binding var selected: Set<Domain>
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(Domain.allCases) { domain in
                    Button {
                        toggleSelection(domain)
                    } label: {
                        HStack {
                            Image(systemName: domain.iconName)
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 24)
                            
                            Text(domain.displayName)
                                .foregroundStyle(.textPrimary)
                            
                            Spacer()
                            
                            if selected.contains(domain) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Domain")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
                if !selected.isEmpty {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Clear") {
                            selected = []
                        }
                    }
                }
            }
        }
        .frame(minWidth: 300, minHeight: 400)
    }
    
    private func toggleSelection(_ domain: Domain) {
        if selected.contains(domain) {
            selected.remove(domain)
        } else {
            selected.insert(domain)
        }
    }
}

// MARK: - Region Picker View

struct RegionPickerView: View {
    @Binding var selected: Set<CulturalRegion>
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(CulturalRegion.allCases) { region in
                    Button {
                        toggleSelection(region)
                    } label: {
                        HStack {
                            Image(systemName: region.iconName)
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 24)
                            
                            Text(region.displayName)
                                .foregroundStyle(.textPrimary)
                            
                            Spacer()
                            
                            if selected.contains(region) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Region")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
                if !selected.isEmpty {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Clear") {
                            selected = []
                        }
                    }
                }
            }
        }
        .frame(minWidth: 300, minHeight: 450)
    }
    
    private func toggleSelection(_ region: CulturalRegion) {
        if selected.contains(region) {
            selected.remove(region)
        } else {
            selected.insert(region)
        }
    }
}

// MARK: - More Options Menu

struct MoreOptionsMenu: View {
    @Bindable var filterState: FilterState
    var onAdvancedTap: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                // Impact Level Section
                Section("Impact Level") {
                    ForEach(ImpactLevel.allCases) { level in
                        Button {
                            if filterState.selectedImpactLevel == level {
                                filterState.selectedImpactLevel = nil
                            } else {
                                filterState.selectedImpactLevel = level
                            }
                        } label: {
                            HStack {
                                Image(systemName: level.iconName)
                                    .foregroundStyle(Color.accentColor)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(level.displayName)
                                        .foregroundStyle(.textPrimary)
                                    Text(level.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.textTertiary)
                                }
                                
                                Spacer()
                                
                                if filterState.selectedImpactLevel == level {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Sort Section
                Section("Sort By") {
                    ForEach(SortOption.allCases) { option in
                        Button {
                            if filterState.sortBy == option {
                                filterState.sortDirection = filterState.sortDirection == .ascending ? .descending : .ascending
                            } else {
                                filterState.sortBy = option
                            }
                        } label: {
                            HStack {
                                Image(systemName: option.iconName)
                                    .foregroundStyle(Color.accentColor)
                                    .frame(width: 24)
                                
                                Text(option.displayName)
                                    .foregroundStyle(.textPrimary)
                                
                                Spacer()
                                
                                if filterState.sortBy == option {
                                    Image(systemName: filterState.sortDirection.iconName)
                                        .foregroundStyle(Color.accentColor)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Advanced Filters Section
                Section {
                    Button {
                        onAdvancedTap()
                    } label: {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 24)
                            
                            Text("Advanced Filters")
                                .foregroundStyle(.textPrimary)
                            
                            Spacer()
                            
                            if filterState.hasAdvancedFilters {
                                Text("\(filterState.advancedFilters.activeCount)")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor)
                                    .clipShape(Capsule())
                            }
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.textTertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("More Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .frame(minWidth: 320, minHeight: 500)
    }
}

// MARK: - Advanced Filters Sheet

struct AdvancedFiltersSheet: View {
    @Bindable var filterState: FilterState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Archetype
                    ChipGroup(
                        title: "Character Archetype",
                        options: Array(Archetype.allCases),
                        selected: $filterState.advancedFilters.archetypes,
                        labelProvider: { $0.displayName },
                        iconProvider: { $0.iconName }
                    )
                    
                    // Moral Valence
                    ChipGroup(
                        title: "Moral Perception",
                        options: Array(MoralValence.allCases),
                        selected: $filterState.advancedFilters.moralValences,
                        labelProvider: { $0.displayName },
                        iconProvider: nil
                    )
                    
                    // Life Arc
                    ChipGroup(
                        title: "Life Trajectory",
                        options: Array(LifeArc.allCases),
                        selected: $filterState.advancedFilters.lifeArcs,
                        labelProvider: { $0.displayName },
                        iconProvider: nil
                    )
                    
                    // Influence Mode
                    ChipGroup(
                        title: "Influence Mode",
                        options: Array(InfluenceMode.allCases),
                        selected: $filterState.advancedFilters.influenceModes,
                        labelProvider: { $0.displayName },
                        iconProvider: nil
                    )
                }
                .padding(Spacing.md)
            }
            .navigationTitle("Advanced Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if filterState.hasAdvancedFilters {
                        Button("Clear") {
                            withAnimation(.spring(duration: 0.25)) {
                                filterState.advancedFilters.reset()
                            }
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Filter Bar") {
    struct PreviewWrapper: View {
        @State private var filterState = FilterState()
        
        var body: some View {
            VStack {
                FilterBar(filterState: filterState)
                
                Spacer()
                
                // Test buttons
                VStack(spacing: 10) {
                    Button("Add Science Filter") {
                        filterState.selectedDomains.insert(.science)
                    }
                    Button("Add Modern Era") {
                        filterState.selectedEras.insert(.modern)
                    }
                    Button("Add Western Europe") {
                        filterState.selectedRegions.insert(.westernEurope)
                    }
                    Button("Reset") {
                        filterState.reset()
                    }
                }
                .padding()
            }
        }
    }
    
    return PreviewWrapper()
}
