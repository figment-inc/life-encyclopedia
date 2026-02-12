//
//  PeopleQuery.swift
//  life-encyclopedia
//
//  Unified query contract for server-driven search and filtering.
//

import Foundation

struct PeopleQuery: Equatable {
    var searchText: String = ""
    var selectedEras: Set<Era> = []
    var selectedDomains: Set<Domain> = []
    var selectedRegions: Set<CulturalRegion> = []
    var selectedImpactLevel: ImpactLevel? = nil
    var advancedFilters = AdvancedFilters()
    var sortBy: SortOption = .createdAt
    var sortDirection: SortDirection = .descending
    var page: Int = 1
    var pageSize: Int = 30
}

struct PeoplePage {
    let people: [Person]
    let page: Int
    let pageSize: Int
    let totalCount: Int?
    let hasMore: Bool
}
