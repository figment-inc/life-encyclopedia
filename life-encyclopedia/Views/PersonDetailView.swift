//
//  PersonDetailView.swift
//  life-encyclopedia
//
//  Paginated view showing historical events for a person with swipe navigation
//

import SwiftUI

struct PersonDetailView: View {
    let person: Person
    var showSaveButton: Bool = false
    var onSave: (() async -> Void)?
    var onDismiss: (() -> Void)?
    var onViewTracked: (() -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @State private var isSaving = false
    @State private var hasTrackedView = false
    @State private var currentEventIndex: Int = 0
    
    private let supabaseService = SupabaseService()
    
    var body: some View {
        // No NavigationStack wrapper - caller is responsible for navigation context
        // HomeView pushes via NavigationLink, CreateView embeds directly in its NavigationStack
        mainContent
            .toolbar {
                if showSaveButton {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            onDismiss?()
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if showSaveButton {
                    bottomActions
                }
            }
            .task {
                // Track view count when viewing an existing person (not when previewing before save)
                if !showSaveButton && !hasTrackedView {
                    hasTrackedView = true
                    await trackView()
                }
            }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            // Events Section
            if person.events.isEmpty {
                emptyEventsView
            } else {
                eventsPagerSection
            }
        }
        .background(Color.surfacePrimary)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // Custom back button - plain chevron only, no background
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.textPrimary)
                }
            }
            
            // Name and lifespan stacked vertically in center
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(person.name)
                        .font(.system(size: 17, weight: .semibold, design: .serif))
                        .foregroundStyle(.textPrimary)
                        .lineLimit(1)
                    
                    if let lifeSpan = person.lifeSpan {
                        Text(lifeSpan)
                            .font(.caption)
                            .foregroundStyle(.textTertiary)
                    }
                }
            }
        }
    }
    
    // MARK: - View Tracking
    
    private func trackView() async {
        do {
            try await supabaseService.incrementViewCount(id: person.id)
            onViewTracked?()
        } catch {
            // Silently fail - view tracking is not critical
            print("Failed to track view: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Events Pager Section
    
    private var eventsPagerSection: some View {
        VStack(spacing: 0) {
            // Paginated TabView
            TabView(selection: $currentEventIndex) {
                ForEach(Array(person.events.enumerated()), id: \.element.id) { index, event in
                    EventPageView(event: event)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Bottom Navigation - centered with < N of M > format
            BottomNavigationBar(
                currentIndex: $currentEventIndex,
                totalCount: person.events.count
            )
        }
    }
    
    // MARK: - Empty Events View
    
    private var emptyEventsView: some View {
        VStack(spacing: Spacing.md) {
            Spacer()
            
            Image(systemName: "text.book.closed")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.quaternary)
            
            Text("No events recorded")
                .font(.bodyMedium)
                .foregroundStyle(.tertiary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Bottom Actions
    
    private var bottomActions: some View {
        VStack(spacing: 0) {
            Divider()
            
            Button(action: {
                Task {
                    isSaving = true
                    await onSave?()
                    isSaving = false
                }
            }) {
                HStack(spacing: Spacing.xs) {
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Save to Library")
                            .fontWeight(.medium)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSaving)
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.md)
        }
        .background(.ultraThinMaterial)
    }
}

// MARK: - Event Page View (Full-page event display)

struct EventPageView: View {
    let event: HistoricalEvent
    
    var body: some View {
        VStack(spacing: 0) {
            // Scrollable content area
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    // Year display - prominent
                    if let year = event.year {
                        Text("\(year)")
                            .font(.system(size: 48, weight: .light, design: .serif))
                            .foregroundStyle(.textTertiary)
                    } else {
                        Text(event.date)
                            .font(.system(size: 24, weight: .light, design: .serif))
                            .foregroundStyle(.textTertiary)
                    }
                    
                    // Title
                    Text(event.title)
                        .font(.system(size: 24, weight: .medium, design: .serif))
                        .foregroundStyle(.textPrimary)
                        .padding(.top, Spacing.xs)
                    
                    // Description as narrative
                    Text(event.description)
                        .font(.bodyLargeSerif)
                        .foregroundStyle(.textSecondary)
                        .lineSpacing(6)
                        .padding(.top, Spacing.sm)
                    
                    Spacer(minLength: Spacing.xl)
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.top, Spacing.md)
            }
            
            // Fixed footnotes section at bottom
            FootnotesSection(event: event)
        }
        .background(Color.surfacePrimary)
    }
}

// MARK: - Footnotes Section

struct FootnotesSection: View {
    let event: HistoricalEvent
    @State private var isSectionRevealed = false
    
    private let springAnimation: Animation = .spring(response: 0.35, dampingFraction: 0.85)
    
    private var visibleSources: [Source] {
        if !isSectionRevealed { return [] }
        return event.sources
    }
    
    private var sourceCountLabel: String {
        let count = event.sources.count
        return "\(count) Source\(count == 1 ? "" : "s")"
    }
    
    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    var body: some View {
        if !event.sources.isEmpty || event.hasCitation {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Subtle top border
                Rectangle()
                    .fill(Color.textTertiary.opacity(0.15))
                    .frame(height: 0.5)
                
                // Disclosure header row -- tappable to reveal/hide sources
                Button {
                    triggerHaptic()
                    withAnimation(springAnimation) {
                        isSectionRevealed.toggle()
                    }
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Text("Sources")
                            .font(.system(size: 11, weight: .medium))
                            .textCase(.uppercase)
                            .tracking(0.8)
                        
                        Text(sourceCountLabel)
                            .font(.system(size: 11, weight: .regular))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .rotationEffect(.degrees(isSectionRevealed ? 180 : 0))
                    }
                    .foregroundStyle(.textTertiary)
                    .padding(.vertical, Spacing.xs)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isSectionRevealed ? "Collapse sources" : "Expand sources")
                .accessibilityHint("\(sourceCountLabel) available")
                
                // Source list -- revealed on tap
                if isSectionRevealed {
                    if !event.sources.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            ForEach(Array(visibleSources.enumerated()), id: \.element.id) { index, source in
                                SourceFootnote(source: source, number: index + 1)
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                                        removal: .opacity
                                    ))
                                    .animation(
                                        springAnimation.delay(Double(index) * 0.05),
                                        value: visibleSources.count
                                    )
                            }
                        }
                    } else if let citation = event.citation, !citation.isEmpty {
                        LegacyCitationFootnote(citation: citation)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.lg)
            .background(Color.surfacePrimary)
        }
    }
}

// MARK: - Source Footnote (Editorial style)

struct SourceFootnote: View {
    let source: Source
    let number: Int
    @Environment(\.openURL) private var openURL
    
    private var openableURLString: String {
        source.deepLinkURL ?? source.url
    }
    
    private var factCheckQuote: String? {
        CitationDeepLinkBuilder.bestQuote(
            relevantQuote: source.relevantQuote,
            contentSnippet: source.contentSnippet
        )
    }
    
    /// Metadata string: domain + publish date joined by centered dot
    private var metadataText: String {
        var parts: [String] = []
        if let domain = source.domain {
            parts.append(domain)
        }
        if let publisher = source.publisher, !publisher.isEmpty {
            parts.append(publisher)
        } else if let publishDate = source.publishDate, !publishDate.isEmpty {
            parts.append(publishDate)
        }
        return parts.joined(separator: "  \u{00B7}  ")
    }
    
    var body: some View {
        Button {
            if let url = URL(string: openableURLString) {
                openURL(url)
            }
        } label: {
            HStack(alignment: .top, spacing: Spacing.sm) {
                // Source type icon with superscript number
                ZStack(alignment: .topTrailing) {
                    Image(systemName: source.sourceType.iconName)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.textTertiary)
                        .frame(width: 24, height: 24, alignment: .center)
                    
                    // Superscript number
                    Text("\(number)")
                        .font(.system(size: 8, weight: .semibold, design: .serif))
                        .foregroundStyle(.textTertiary)
                        .offset(x: 6, y: -2)
                }
                .frame(width: 28)
                
                // Content column
                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    Text(source.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Metadata line: domain · publish date
                    if !metadataText.isEmpty {
                        Text(metadataText)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(.textTertiary)
                    }
                    
                    // Blockquote-styled excerpt
                    if let factCheckQuote {
                        HStack(alignment: .top, spacing: Spacing.xs) {
                            // Left accent bar
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.textTertiary.opacity(0.3))
                                .frame(width: 2)
                            
                            Text(factCheckQuote)
                                .font(.system(size: 12, weight: .regular, design: .serif))
                                .italic()
                                .foregroundStyle(.textSecondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.top, 2)
                    }
                }
                
                Spacer(minLength: 0)
                
                // External link indicator
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.textTertiary.opacity(0.5))
                    .padding(.top, 4)
            }
            .padding(.vertical, Spacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(SourceButtonStyle())
        .accessibilityLabel("Source \(number): \(source.title)")
        .accessibilityHint("Double tap to open in browser")
    }
}

// MARK: - Source Button Style (scale + opacity press state)

struct SourceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Legacy Citation Footnote

struct LegacyCitationFootnote: View {
    let citation: String
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            // Icon matching new style
            Image(systemName: "doc.text")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.textTertiary)
                .frame(width: 28)
            
            // Citation text
            Text(citation)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.leading)
            
            Spacer(minLength: 0)
        }
        .padding(.vertical, Spacing.xs)
    }
}

// MARK: - Bottom Navigation Bar

struct BottomNavigationBar: View {
    @Binding var currentIndex: Int
    let totalCount: Int
    
    private var canGoBack: Bool { currentIndex > 0 }
    private var canGoForward: Bool { currentIndex < totalCount - 1 }
    
    var body: some View {
        HStack(spacing: Spacing.lg) {
            // Left chevron button
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentIndex -= 1
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(canGoBack ? .textPrimary : .textTertiary.opacity(0.3))
                    .frame(width: 44, height: 44)
            }
            .disabled(!canGoBack)
            .accessibilityLabel("Previous event")
            .accessibilityHint(canGoBack ? "Double tap to navigate" : "No more events in this direction")
            
            // Current position indicator
            Text("\(currentIndex + 1) of \(totalCount)")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.textSecondary)
                .monospacedDigit()
            
            // Right chevron button
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentIndex += 1
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(canGoForward ? .textPrimary : .textTertiary.opacity(0.3))
                    .frame(width: 44, height: 44)
            }
            .disabled(!canGoForward)
            .accessibilityLabel("Next event")
            .accessibilityHint(canGoForward ? "Double tap to navigate" : "No more events in this direction")
        }
        .padding(.vertical, Spacing.sm)
        .padding(.bottom, Spacing.md)
        .frame(maxWidth: .infinity)
        .background(Color.surfacePrimary)
    }
}

// MARK: - Event Card (Editorial Style)

struct EventCard: View {
    let event: HistoricalEvent
    @State private var showingSources = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Year display - large and muted
            if let year = event.year {
                Text("\(year)")
                    .font(.yearDisplay)
                    .foregroundStyle(.textTertiary)
            } else {
                Text(event.date)
                    .font(.labelLarge)
                    .foregroundStyle(.textTertiary)
            }
            
            // Title
            Text(event.title)
                .font(.headlineSmall)
                .foregroundStyle(.textPrimary)
            
            // Description as narrative
            Text(event.description)
                .font(.bodyMediumSerif)
                .foregroundStyle(.textSecondary)
                .lineSpacing(5)
            
            // Sources - collapsed by default
            if !event.sources.isEmpty {
                sourcesButton
            } else if event.hasCitation {
                citationView
            }
        }
        .padding(Spacing.cardPadding)
        .background(Color.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
    }
    
    // MARK: - Sources Button
    
    private var sourcesButton: some View {
        Button {
            showingSources = true
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "doc.on.doc")
                    .font(.caption)
                Text("\(event.sources.count) source\(event.sources.count == 1 ? "" : "s")")
                    .font(.caption)
            }
            .foregroundStyle(.textTertiary)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingSources) {
            SourcesSheet(sources: event.sources, eventTitle: event.title)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Citation View (Fallback)
    
    private var citationView: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "quote.opening")
                .font(.caption2)
            Text(event.citation ?? "")
                .font(.caption)
                .lineLimit(1)
        }
        .foregroundStyle(.textTertiary)
    }
}

// MARK: - Sources Sheet

struct SourcesSheet: View {
    let sources: [Source]
    let eventTitle: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: Spacing.sm) {
                    ForEach(sources) { source in
                        SourceRowSimple(source: source)
                    }
                }
                .padding(Spacing.screenHorizontal)
            }
            .background(Color.surfacePrimary)
            .navigationTitle("Sources")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Paginated Detail View") {
    let sampleSources = [
        Source(
            title: "Albert Einstein - Wikipedia",
            url: "https://en.wikipedia.org/wiki/Albert_Einstein",
            sourceType: .wikipedia,
            publisher: "Wikipedia",
            reliabilityScore: 0.85,
            contentSnippet: "Albert Einstein was a German-born theoretical physicist."
        ),
        Source(
            title: "Einstein Biography - Britannica",
            url: "https://www.britannica.com/biography/Albert-Einstein",
            sourceType: .encyclopedia,
            publisher: "Encyclopædia Britannica",
            reliabilityScore: 0.95
        ),
        Source(
            title: "Nobel Prize Biography",
            url: "https://www.nobelprize.org/prizes/physics/1921/einstein/biographical/",
            sourceType: .official,
            publisher: "Nobel Foundation",
            reliabilityScore: 0.98
        )
    ]
    
    let samplePerson = Person(
        name: "Albert Einstein",
        birthDate: "1879",
        deathDate: "1955",
        summary: "German-born theoretical physicist who developed the theory of relativity.",
        events: [
            HistoricalEvent(
                date: "March 14, 1879",
                title: "Birth in Ulm, Germany",
                description: "Albert Einstein was born in Ulm, in the Kingdom of Württemberg in the German Empire. His father, Hermann Einstein, was a salesman and engineer. His mother was Pauline Koch.",
                citation: "Isaacson, Walter. Einstein: His Life and Universe.",
                sourceURL: "https://en.wikipedia.org/wiki/Albert_Einstein",
                eventType: .birth,
                datePrecision: .exact,
                sources: sampleSources
            ),
            HistoricalEvent(
                date: "1905",
                title: "Annus Mirabilis Papers",
                description: "Einstein published four groundbreaking papers in the Annalen der Physik journal. These papers introduced special relativity, explained the photoelectric effect, presented Brownian motion theory, and introduced mass-energy equivalence (E=mc²).",
                citation: "Physics Today, 2005",
                sourceURL: nil,
                eventType: .achievement,
                datePrecision: .yearOnly,
                sources: [sampleSources[0]]
            ),
            HistoricalEvent(
                date: "November 25, 1915",
                title: "General Theory of Relativity",
                description: "Einstein presented his general theory of relativity to the Prussian Academy of Sciences. This revolutionary theory described gravity as a geometric property of space and time, fundamentally changing our understanding of the universe.",
                citation: "The Collected Papers of Albert Einstein",
                sourceURL: "https://einsteinpapers.press.princeton.edu",
                eventType: .achievement,
                datePrecision: .exact,
                sources: sampleSources
            ),
            HistoricalEvent(
                date: "1921",
                title: "Nobel Prize in Physics",
                description: "Einstein was awarded the Nobel Prize in Physics for his services to Theoretical Physics, and especially for his discovery of the law of the photoelectric effect.",
                eventType: .achievement,
                datePrecision: .yearOnly,
                sources: [sampleSources[2]]
            )
        ]
    )
    
    PersonDetailView(person: samplePerson)
}

#Preview("Event Page View") {
    let sampleSources = [
        Source(
            title: "Wikipedia Article",
            url: "https://en.wikipedia.org/wiki/Example",
            sourceType: .wikipedia,
            publisher: "Wikipedia",
            reliabilityScore: 0.80
        ),
        Source(
            title: "Academic Paper",
            url: "https://academic.example.com/paper",
            sourceType: .academic,
            author: "Dr. Jane Smith",
            reliabilityScore: 0.92
        )
    ]
    
    EventPageView(
        event: HistoricalEvent(
            date: "1905",
            title: "Annus Mirabilis Papers",
            description: "Einstein published four groundbreaking papers in the Annalen der Physik journal. These papers introduced special relativity, explained the photoelectric effect, presented Brownian motion theory, and introduced mass-energy equivalence (E=mc²). This year became known as Einstein's 'miracle year' and established him as one of the leading physicists of his generation.",
            sources: sampleSources
        )
    )
}

#Preview("Event with Legacy Citation") {
    EventPageView(
        event: HistoricalEvent(
            date: "1879",
            title: "Birth in Germany",
            description: "Born in the city of Ulm, in the Kingdom of Württemberg.",
            citation: "Isaacson, Walter. Einstein: His Life and Universe. Simon & Schuster, 2007."
        )
    )
}

#Preview("Source Footnotes") {
    VStack(alignment: .leading, spacing: Spacing.md) {
        Text("Sources")
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.textTertiary)
            .textCase(.uppercase)
            .tracking(0.8)
        
        SourceFootnote(
            source: Source(
                title: "Albert Einstein - Wikipedia",
                url: "https://en.wikipedia.org/wiki/Albert_Einstein",
                sourceType: .wikipedia,
                publisher: "Wikipedia",
                reliabilityScore: 0.85
            ),
            number: 1
        )
        SourceFootnote(
            source: Source(
                title: "Einstein Biography - Britannica",
                url: "https://www.britannica.com/biography/Albert-Einstein",
                sourceType: .encyclopedia,
                publisher: "Encyclopædia Britannica",
                reliabilityScore: 0.95
            ),
            number: 2
        )
        SourceFootnote(
            source: Source(
                title: "Nobel Prize Biography",
                url: "https://nobelprize.org/prizes/physics/1921/einstein",
                sourceType: .official,
                publisher: "Nobel Foundation",
                reliabilityScore: 0.98
            ),
            number: 3
        )
    }
    .padding(Spacing.screenHorizontal)
    .background(Color.surfacePrimary)
}

#Preview("Bottom Navigation") {
    @Previewable @State var currentIndex = 14
    
    VStack(spacing: 40) {
        Spacer()
        
        BottomNavigationBar(
            currentIndex: $currentIndex,
            totalCount: 16
        )
        .background(Color.surfacePrimary)
    }
}

#Preview("Empty Events") {
    PersonDetailView(person: Person(
        name: "Unknown Person",
        summary: "No information available about this person.",
        events: []
    ))
}

#Preview("Save Mode") {
    let samplePerson = Person(
        name: "Marie Curie",
        birthDate: "1867",
        deathDate: "1934",
        summary: "Polish and naturalized-French physicist and chemist who conducted pioneering research on radioactivity.",
        events: [
            HistoricalEvent(
                date: "November 7, 1867",
                title: "Birth in Warsaw",
                description: "Maria Sklodowska was born in Warsaw, in the Russian partition of Poland.",
                eventType: .birth,
                datePrecision: .exact
            ),
            HistoricalEvent(
                date: "1903",
                title: "Nobel Prize in Physics",
                description: "Awarded the Nobel Prize in Physics jointly with her husband Pierre Curie and Henri Becquerel.",
                eventType: .achievement,
                datePrecision: .yearOnly
            )
        ]
    )
    
    PersonDetailView(person: samplePerson, showSaveButton: true)
}
