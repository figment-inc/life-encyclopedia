//
//  Colors.swift
//  life-encyclopedia
//
//  Design System: Color Palette
//

import SwiftUI

// MARK: - Semantic Colors

extension Color {
    
    // MARK: Surface Colors
    
    /// Primary surface (adapts to dark mode)
    static let surfacePrimary = Color(.systemBackground)
    
    /// Secondary surface (adapts to dark mode)
    static let surfaceSecondary = Color(.secondarySystemBackground)
    
    /// Grouped background (adapts to dark mode)
    static let surfaceGrouped = Color(.systemGroupedBackground)
    
    /// Card surface (adapts to dark mode)
    static let surfaceCard = Color(.secondarySystemGroupedBackground)
    
    // MARK: Text Colors
    
    /// Primary text color (adapts to dark mode)
    static let textPrimary = Color(.label)
    
    /// Secondary text color (adapts to dark mode)
    static let textSecondary = Color(.secondaryLabel)
    
    /// Tertiary text color (adapts to dark mode)
    static let textTertiary = Color(.tertiaryLabel)
    
    /// Disabled text color
    static let textDisabled = Color(.quaternaryLabel)
    
    // MARK: Trust Level Colors
    
    /// High trust - Green
    static let trustHigh = Color.success
    
    /// Medium trust - Yellow/Amber
    static let trustMedium = Color.warning
    
    /// Low trust - Red
    static let trustLow = Color.danger
}

// MARK: - ShapeStyle Extensions for .foregroundStyle() usage

extension ShapeStyle where Self == Color {
    
    // Text Colors
    static var textPrimary: Color { .textPrimary }
    static var textSecondary: Color { .textSecondary }
    static var textTertiary: Color { .textTertiary }
    static var textDisabled: Color { .textDisabled }
    
    // Surface Colors
    static var surfacePrimary: Color { .surfacePrimary }
    static var surfaceSecondary: Color { .surfaceSecondary }
    static var surfaceGrouped: Color { .surfaceGrouped }
    static var surfaceCard: Color { .surfaceCard }
    
    // Trust Level Colors
    static var trustHigh: Color { .trustHigh }
    static var trustMedium: Color { .trustMedium }
    static var trustLow: Color { .trustLow }
}

// MARK: - Hex Color Initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
