//
//  ConfidenceBadge.swift
//  life-encyclopedia
//
//  Badge components for event type and source display
//

import SwiftUI

// MARK: - Event Type Badge

struct EventTypeBadge: View {
    let eventType: EventType
    let showLabel: Bool
    
    init(type: EventType, showLabel: Bool = true) {
        self.eventType = type
        self.showLabel = showLabel
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: eventType.iconName)
                .font(.caption)
            
            if showLabel {
                Text(eventType.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .foregroundStyle(Color(eventType.color))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(eventType.color).opacity(0.12))
        )
    }
}

// MARK: - Source Type Icon

struct SourceTypeIcon: View {
    let sourceType: SourceType
    let size: CGFloat
    
    init(type: SourceType, size: CGFloat = 16) {
        self.sourceType = type
        self.size = size
    }
    
    var body: some View {
        Image(systemName: sourceType.iconName)
            .font(.system(size: size))
            .foregroundStyle(.secondary)
    }
}

// MARK: - Preview

#Preview("Event Type Badges") {
    VStack(spacing: 20) {
        Text("Event Types")
            .font(.headline)
        
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(EventType.allCases, id: \.self) { type in
                    EventTypeBadge(type: type)
                }
            }
        }
    }
    .padding()
}
