//
//  Spacing.swift
//  life-encyclopedia
//
//  Design System: Spacing and Layout Constants
//

import SwiftUI

// MARK: - Spacing Constants

enum Spacing {
    /// 4pt - Tight spacing
    static let xxs: CGFloat = 4
    
    /// 8pt - Small spacing
    static let xs: CGFloat = 8
    
    /// 12pt - Compact spacing
    static let sm: CGFloat = 12
    
    /// 16pt - Default spacing
    static let md: CGFloat = 16
    
    /// 24pt - Large spacing
    static let lg: CGFloat = 24
    
    /// 32pt - Extra large spacing
    static let xl: CGFloat = 32
    
    /// 48pt - Major section breaks
    static let xxl: CGFloat = 48
    
    /// Screen horizontal margins
    static let screenHorizontal: CGFloat = 16
    
    /// Vertical rhythm for sections
    static let sectionSpacing: CGFloat = 32
    
    /// Card internal padding
    static let cardPadding: CGFloat = 20
}

// MARK: - Corner Radius Constants

enum CornerRadius {
    /// 8pt - Small
    static let sm: CGFloat = 8
    
    /// 12pt - Medium
    static let md: CGFloat = 12
    
    /// 16pt - Large
    static let lg: CGFloat = 16
    
    /// 20pt - Extra large
    static let xl: CGFloat = 20
}

// MARK: - View Extensions

extension View {
    /// Apply standard card styling
    func cardStyle() -> some View {
        self.padding(Spacing.md)
            .background(Color.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }
    
    /// Apply editorial card styling with more padding
    func editorialCardStyle() -> some View {
        self.padding(Spacing.cardPadding)
            .background(Color.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
    }
}
