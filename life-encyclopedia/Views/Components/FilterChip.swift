//
//  FilterChip.swift
//  life-encyclopedia
//
//  Reusable filter chip component for quick filter selection
//

import SwiftUI

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    let icon: String?
    let isSelected: Bool
    let isExclusion: Bool
    var action: () -> Void
    var onLongPress: (() -> Void)?
    
    init(
        label: String,
        icon: String? = nil,
        isSelected: Bool = false,
        isExclusion: Bool = false,
        action: @escaping () -> Void,
        onLongPress: (() -> Void)? = nil
    ) {
        self.label = label
        self.icon = icon
        self.isSelected = isSelected
        self.isExclusion = isExclusion
        self.action = action
        self.onLongPress = onLongPress
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xxs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                }
                
                Text(label)
                    .font(.labelMedium)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contentShape(Capsule())
        .accessibilityLabel("\(label), \(isSelected ? "selected" : "not selected")")
        .accessibilityHint(onLongPress != nil ? "Double tap to toggle, long press to exclude" : "Double tap to toggle")
        .sensoryFeedback(.selection, trigger: isSelected)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    onLongPress?()
                }
        )
    }
    
    private var backgroundColor: Color {
        if isExclusion {
            return Color.danger.opacity(0.15)
        }
        if isSelected {
            return Color.accentColor.opacity(0.15)
        }
        return Color.surfaceSecondary
    }
    
    private var foregroundColor: Color {
        if isExclusion {
            return Color.danger
        }
        if isSelected {
            return Color.accentColor
        }
        return Color.textSecondary
    }
    
    private var borderColor: Color {
        if isExclusion {
            return Color.danger.opacity(0.3)
        }
        if isSelected {
            return Color.accentColor.opacity(0.3)
        }
        return Color.textTertiary.opacity(0.3)
    }
}

// MARK: - Styled Toggle Row

struct StyledToggleRow: View {
    let title: String
    let subtitle: String?
    let icon: String
    @Binding var isOn: Bool
    
    init(
        title: String,
        subtitle: String? = nil,
        icon: String,
        isOn: Binding<Bool>
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self._isOn = isOn
    }
    
    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.bodyMedium)
                        .foregroundStyle(.textPrimary)
                    
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.textTertiary)
                    }
                }
            }
        }
        .tint(.accentColor)
        .padding(Spacing.md)
        .background(Color.surfaceSecondary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
        .accessibilityLabel("\(title), \(isOn ? "enabled" : "disabled")")
        .accessibilityHint("Double tap to toggle")
    }
}

// MARK: - Removable Filter Pill

struct RemovableFilterPill: View {
    let pill: FilterPill
    var onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: pill.icon)
                .font(.system(size: 10, weight: .medium))
            
            Text(pill.label)
                .font(.caption)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(pill.isExclusion ? Color.danger : Color.accentColor)
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, Spacing.xs)
        .padding(.trailing, Spacing.xxs)
        .padding(.vertical, Spacing.xxs)
        .background(pill.isExclusion ? Color.danger.opacity(0.1) : Color.accentColor.opacity(0.1))
        .foregroundStyle(pill.isExclusion ? Color.danger : Color.accentColor)
        .clipShape(Capsule())
        .contentShape(Capsule())
        .accessibilityLabel("\(pill.label) filter")
        .accessibilityHint("Double tap to remove")
    }
}

// MARK: - Quick Filter Button

struct QuickFilterButton: View {
    let label: String
    let icon: String
    let count: Int
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(label)
                    .font(.labelMedium)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                }
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
            .background(count > 0 ? Color.accentColor.opacity(0.1) : Color.surfaceSecondary)
            .foregroundStyle(count > 0 ? Color.accentColor : Color.textPrimary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Multi-Select Chip Group

struct ChipGroup<T: Hashable & Identifiable>: View where T: RawRepresentable, T.RawValue == String {
    let title: String
    let options: [T]
    @Binding var selected: Set<T>
    var excluded: Binding<Set<T>>?
    var labelProvider: (T) -> String
    var iconProvider: ((T) -> String)?
    
    init(
        title: String,
        options: [T],
        selected: Binding<Set<T>>,
        excluded: Binding<Set<T>>? = nil,
        labelProvider: @escaping (T) -> String,
        iconProvider: ((T) -> String)? = nil
    ) {
        self.title = title
        self.options = options
        self._selected = selected
        self.excluded = excluded
        self.labelProvider = labelProvider
        self.iconProvider = iconProvider
    }
    
    private var activeCount: Int {
        let selectedCount = selected.count
        let excludedCount = excluded?.wrappedValue.count ?? 0
        return selectedCount + excludedCount
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Text(title)
                    .font(.titleSmall)
                    .foregroundStyle(.textPrimary)
                
                if activeCount > 0 {
                    Text("\(activeCount)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                }
                
                Spacer()
            }
            
            FlowLayout(spacing: 10) {
                ForEach(options) { option in
                    let isSelected = selected.contains(option)
                    let isExcluded = excluded?.wrappedValue.contains(option) ?? false
                    
                    FilterChip(
                        label: labelProvider(option),
                        icon: iconProvider?(option),
                        isSelected: isSelected,
                        isExclusion: isExcluded,
                        action: {
                            toggleSelection(option)
                        },
                        onLongPress: excluded != nil ? {
                            toggleExclusion(option)
                        } : nil
                    )
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.surfaceSecondary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
    }
    
    private func toggleSelection(_ option: T) {
        // If currently excluded, remove from exclusion first
        if excluded?.wrappedValue.contains(option) == true {
            excluded?.wrappedValue.remove(option)
        }
        
        if selected.contains(option) {
            selected.remove(option)
        } else {
            selected.insert(option)
        }
    }
    
    private func toggleExclusion(_ option: T) {
        guard var excludedSet = excluded?.wrappedValue else { return }
        
        // If currently selected, remove from selection first
        if selected.contains(option) {
            selected.remove(option)
        }
        
        if excludedSet.contains(option) {
            excludedSet.remove(option)
        } else {
            excludedSet.insert(option)
        }
        
        excluded?.wrappedValue = excludedSet
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(
                    x: bounds.minX + result.positions[index].x,
                    y: bounds.minY + result.positions[index].y
                ),
                proposal: .unspecified
            )
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x - spacing)
            }
            
            self.size.height = y + rowHeight
        }
    }
}

// MARK: - Previews

#Preview("Filter Chips") {
    VStack(spacing: 20) {
        HStack {
            FilterChip(label: "Science", icon: "atom", isSelected: false) {}
            FilterChip(label: "Politics", icon: "building.columns", isSelected: true) {}
            FilterChip(label: "Arts", icon: "paintpalette", isSelected: false, isExclusion: true) {}
        }
        
        RemovableFilterPill(
            pill: FilterPill(id: "test", label: "Science", icon: "atom", category: .domain)
        ) {}
        
        QuickFilterButton(label: "Domain", icon: "square.grid.2x2", count: 2) {}
    }
    .padding()
}

#Preview("Styled Toggle Row") {
    struct PreviewWrapper: View {
        @State private var isOn = false
        @State private var isOnWithSubtitle = true
        
        var body: some View {
            VStack(spacing: Spacing.md) {
                StyledToggleRow(
                    title: "Living Only",
                    icon: "heart.fill",
                    isOn: $isOn
                )
                
                StyledToggleRow(
                    title: "Include Secondary Domains",
                    subtitle: "Match people where this is their secondary domain",
                    icon: "square.grid.2x2",
                    isOn: $isOnWithSubtitle
                )
            }
            .padding()
        }
    }
    
    return PreviewWrapper()
}
