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
    let resultCount: Int
    let totalCount: Int?
    let isLoading: Bool
    @Binding var isSearchVisible: Bool
    @Binding var isFilterVisible: Bool
    
    @FocusState private var isSearchFieldFocused: Bool
    @State private var showEraMenu = false
    @State private var showDomainMenu = false
    @State private var showRegionMenu = false
    @State private var showRefineSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            if isSearchVisible {
                searchBarRow
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity.combined(with: .move(edge: .top))
                        )
                    )
            }
            
            if isFilterVisible {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xs) {
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
                        
                        Button {
                            showRefineSheet = true
                        } label: {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 14, weight: .medium))
                                
                                Text(refineLabel)
                                    .font(.labelMedium)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.xs)
                            .background(refineIsActive ? Color.accentColor.opacity(0.12) : Color.surfaceSecondary)
                            .foregroundStyle(refineIsActive ? Color.accentColor : Color.textPrimary)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.vertical, Spacing.xs)
                }
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity.combined(with: .move(edge: .top))
                    )
                )
            }
            
            if filterState.hasActiveFilters {
                activeFilterPills
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity
                        )
                    )
            }
            
            resultsRow
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.bottom, Spacing.xs)
        }
        .clipped()
        .background(Color.surfacePrimary)
        .overlay(alignment: .bottom) {
            Divider()
                .opacity(0.45)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.82, blendDuration: 0), value: isSearchVisible)
        .animation(.spring(response: 0.35, dampingFraction: 0.82, blendDuration: 0), value: isFilterVisible)
        .animation(.spring(response: 0.3, dampingFraction: 0.85, blendDuration: 0), value: filterState.hasActiveFilters)
        .sheet(isPresented: $showRefineSheet) {
            RefineFiltersSheet(filterState: filterState)
                .presentationDetents([.medium, .large])
        }
        .onChange(of: isSearchVisible) { _, isVisible in
            if isVisible {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isSearchFieldFocused = true
                }
            } else {
                isSearchFieldFocused = false
            }
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
    
    private var refineIsActive: Bool {
        filterState.selectedImpactLevel != nil || filterState.hasAdvancedFilters || filterState.hasCustomSort
    }
    
    private var refineLabel: String {
        if !refineIsActive {
            return "Refine"
        }
        
        let secondaryCount = (filterState.selectedImpactLevel != nil ? 1 : 0) +
            filterState.advancedFilters.activeCount +
            (filterState.hasCustomSort ? 1 : 0)
        return "Refine (\(secondaryCount))"
    }
    
    private var searchBarRow: some View {
        HStack(spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.textTertiary)
                
                TextField("Search by name", text: $filterState.searchText)
                    .focused($isSearchFieldFocused)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .font(.bodyMedium)
                    .onSubmit {
                        filterState.commitSearch()
                    }
                
                if !filterState.normalizedDraftSearchText.isEmpty {
                    Button {
                        filterState.clearSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            
            Button {
                filterState.commitSearch()
            } label: {
                Text("Search")
                    .font(.labelMedium)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Search")
        }
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.top, Spacing.xs)
        .padding(.bottom, Spacing.xxs)
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
    
    @ViewBuilder
    private var resultsRow: some View {
        HStack {
            if isLoading {
                Text("Loading results...")
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
            } else if let totalCount {
                Text("\(resultCount) of \(totalCount) shown")
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
            } else {
                Text("\(resultCount) results")
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
            }
            
            Spacer()
            
            if filterState.hasCustomSort {
                Text("Sorted by \(filterState.sortBy.displayName)")
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
            }
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

// MARK: - Refine Sheet

struct RefineFiltersSheet: View {
    @Bindable var filterState: FilterState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Impact Level")
                            .font(.titleSmall)
                            .foregroundStyle(.textPrimary)
                        
                        FlowLayout(spacing: 10) {
                            ForEach(ImpactLevel.allCases) { level in
                                FilterChip(
                                    label: level.displayName,
                                    icon: level.iconName,
                                    isSelected: filterState.selectedImpactLevel == level
                                ) {
                                    if filterState.selectedImpactLevel == level {
                                        filterState.selectedImpactLevel = nil
                                    } else {
                                        filterState.selectedImpactLevel = level
                                    }
                                }
                            }
                        }
                    }
                    .padding(Spacing.md)
                    .background(Color.surfaceSecondary.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                    
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Sort")
                            .font(.titleSmall)
                            .foregroundStyle(.textPrimary)
                        
                        VStack(spacing: Spacing.xs) {
                            ForEach(SortOption.allCases) { option in
                                Button {
                                    if filterState.sortBy == option {
                                        filterState.sortDirection = filterState.sortDirection == .ascending ? .descending : .ascending
                                    } else {
                                        filterState.sortBy = option
                                    }
                                } label: {
                                    HStack(spacing: Spacing.sm) {
                                        Image(systemName: option.iconName)
                                            .foregroundStyle(Color.accentColor)
                                        
                                        Text(option.displayName)
                                            .foregroundStyle(.textPrimary)
                                        
                                        Spacer()
                                        
                                        if filterState.sortBy == option {
                                            Image(systemName: filterState.sortDirection.iconName)
                                                .foregroundStyle(Color.accentColor)
                                        }
                                    }
                                    .font(.bodyMedium)
                                    .padding(.horizontal, Spacing.md)
                                    .padding(.vertical, Spacing.sm)
                                    .background(Color.surfaceSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    ChipGroup(
                        title: "Character Archetype",
                        options: Array(Archetype.allCases),
                        selected: $filterState.advancedFilters.archetypes,
                        labelProvider: { $0.displayName },
                        iconProvider: { $0.iconName }
                    )
                    
                    ChipGroup(
                        title: "Moral Perception",
                        options: Array(MoralValence.allCases),
                        selected: $filterState.advancedFilters.moralValences,
                        labelProvider: { $0.displayName },
                        iconProvider: nil
                    )
                    
                    ChipGroup(
                        title: "Life Trajectory",
                        options: Array(LifeArc.allCases),
                        selected: $filterState.advancedFilters.lifeArcs,
                        labelProvider: { $0.displayName },
                        iconProvider: nil
                    )
                    
                    ChipGroup(
                        title: "Influence Mode",
                        options: Array(InfluenceMode.allCases),
                        selected: $filterState.advancedFilters.influenceModes,
                        labelProvider: { $0.displayName },
                        iconProvider: nil
                    )
                }
            }
            .padding(Spacing.md)
            .navigationTitle("Refine Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if filterState.hasActiveFilters {
                        Button("Clear All") {
                            withAnimation(.spring(duration: 0.25)) {
                                filterState.reset()
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
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

// MARK: - Previews

#Preview("Filter Bar") {
    struct PreviewWrapper: View {
        @State private var filterState = FilterState()
        @State private var isSearchVisible = true
        @State private var isFilterVisible = true
        
        var body: some View {
            VStack {
                FilterBar(
                    filterState: filterState,
                    resultCount: 16,
                    totalCount: 80,
                    isLoading: false,
                    isSearchVisible: $isSearchVisible,
                    isFilterVisible: $isFilterVisible
                )
                
                Spacer()
                
                // Test buttons
                VStack(spacing: 10) {
                    Button("Toggle Search") {
                        isSearchVisible.toggle()
                    }
                    Button("Toggle Filters") {
                        isFilterVisible.toggle()
                    }
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
