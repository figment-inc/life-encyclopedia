//
//  Typography.swift
//  life-encyclopedia
//
//  Design System: Typography Styles
//

import SwiftUI

// MARK: - Custom Font Extensions

extension Font {
    
    // MARK: Display (Hero Text)
    
    /// 34pt bold - For hero/display text
    static let displayLarge = Font.system(size: 34, weight: .bold)
    
    /// 28pt bold - Secondary display
    static let displayMedium = Font.system(size: 28, weight: .bold)
    
    // MARK: Headlines
    
    /// 28pt semibold
    static let headlineLarge = Font.system(size: 28, weight: .semibold)
    
    /// 24pt semibold
    static let headlineMedium = Font.system(size: 24, weight: .semibold)
    
    /// 20pt semibold
    static let headlineSmall = Font.system(size: 20, weight: .semibold)
    
    // MARK: Titles
    
    /// 22pt medium
    static let titleLarge = Font.system(size: 22, weight: .medium)
    
    /// 17pt medium
    static let titleMedium = Font.system(size: 17, weight: .medium)
    
    /// 15pt medium
    static let titleSmall = Font.system(size: 15, weight: .medium)
    
    // MARK: Body (Sans-serif - UI Text)
    
    /// 17pt regular - Primary UI text
    static let bodyLarge = Font.system(size: 17, weight: .regular)
    
    /// 15pt regular - Secondary UI text
    static let bodyMedium = Font.system(size: 15, weight: .regular)
    
    /// 13pt regular - Small UI text
    static let bodySmall = Font.system(size: 13, weight: .regular)
    
    // MARK: Body (Narrative Text - Serif)
    
    /// 17pt regular serif - Primary narrative text
    static let bodyLargeSerif = Font.system(size: 17, weight: .regular, design: .serif)
    
    /// 15pt regular serif
    static let bodyMediumSerif = Font.system(size: 15, weight: .regular, design: .serif)
    
    // MARK: Labels
    
    /// 14pt medium
    static let labelLarge = Font.system(size: 14, weight: .medium)
    
    /// 12pt medium
    static let labelMedium = Font.system(size: 12, weight: .medium)
    
    /// 11pt regular - For captions and citations
    static let caption = Font.system(size: 11, weight: .regular)
    
    // MARK: Year Display (Editorial)
    
    /// 32pt light - For large year displays
    static let yearDisplay = Font.system(size: 32, weight: .light, design: .serif)
}

// MARK: - View Modifiers

extension View {
    /// Apply narrative text styling with proper line spacing
    func narrativeStyle() -> some View {
        self
            .font(.bodyLargeSerif)
            .lineSpacing(8)
    }
}
