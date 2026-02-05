//
//  SourceListView.swift
//  life-encyclopedia
//
//  Simplified source display components
//

import SwiftUI

// MARK: - Source List View (Simplified)

struct SourceListView: View {
    let sources: [Source]
    let title: String
    @State private var isExpanded: Bool
    
    init(sources: [Source], title: String = "Sources", expanded: Bool = false) {
        self.sources = sources
        self.title = title
        self._isExpanded = State(initialValue: expanded)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Collapsed: just show count
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                    Text("\(sources.count) source\(sources.count == 1 ? "" : "s")")
                        .font(.caption)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                }
                .foregroundStyle(.textTertiary)
            }
            .buttonStyle(.plain)
            
            // Expanded: simple list
            if isExpanded {
                VStack(spacing: Spacing.xs) {
                    ForEach(sources) { source in
                        SourceRowSimple(source: source)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Simple Source Row

struct SourceRowSimple: View {
    let source: Source
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: source.sourceType.iconName)
                .font(.caption)
                .foregroundStyle(.textTertiary)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(source.title)
                    .font(.caption)
                    .foregroundStyle(.textPrimary)
                    .lineLimit(1)
                
                if let domain = source.domain {
                    Text(domain)
                        .font(.caption)
                        .foregroundStyle(.textTertiary)
                }
            }
            
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if let url = URL(string: source.url) {
                UIApplication.shared.open(url)
            }
        }
    }
}

// MARK: - Source Row (Legacy - kept for compatibility)

struct SourceRow: View {
    let source: Source
    let compact: Bool
    
    init(source: Source, compact: Bool = false) {
        self.source = source
        self.compact = compact
    }
    
    var body: some View {
        SourceRowSimple(source: source)
    }
}

// MARK: - Preview

#Preview("Source List - Simplified") {
    let sampleSources = [
        Source(
            title: "Albert Einstein - Wikipedia",
            url: "https://en.wikipedia.org/wiki/Albert_Einstein",
            sourceType: .wikipedia,
            publisher: "Wikipedia",
            reliabilityScore: 0.85
        ),
        Source(
            title: "Einstein Biography - Britannica",
            url: "https://www.britannica.com/biography/Albert-Einstein",
            sourceType: .encyclopedia,
            publisher: "Encyclopædia Britannica",
            reliabilityScore: 0.95
        ),
        Source(
            title: "The Nobel Prize in Physics 1921",
            url: "https://www.nobelprize.org/prizes/physics/1921/einstein/facts/",
            sourceType: .official,
            publisher: "Nobel Prize",
            reliabilityScore: 0.98
        )
    ]
    
    VStack(spacing: 20) {
        SourceListView(sources: sampleSources, expanded: false)
            .padding()
            .background(Color.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        
        SourceListView(sources: sampleSources, expanded: true)
            .padding()
            .background(Color.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .padding()
}
