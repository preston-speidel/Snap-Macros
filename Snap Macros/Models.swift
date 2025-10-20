//
//  Models.swift
//  Snap Macros
//

import Foundation
import SwiftUI

/// User-set goals for a day
struct MacroGoals: Codable, Hashable {
    var calories: Int
    var protein: Int // grams
    var carbs: Int   // grams
    var fats: Int    // grams
}

/// Per-meal estimate returned by AI (fake for milestone)
struct MealEstimate: Identifiable, Hashable, Codable {
    let id: UUID = UUID()
    var title: String           // e.g., "Chicken bowl"
    var calories: Int
    var protein: Int
    var carbs: Int
    var fats: Int
    var items: [DetectedItem]   // breakdown
    var imageData: Data?        // JPEG bytes for today's feed thumbnail
    var timestamp: Date
}

struct DetectedItem: Identifiable, Hashable, Codable {
    let id = UUID()
    var name: String
    var grams: Int
    var calories: Int
    var protein: Int
    var carbs: Int
    var fats: Int
}

/// Numeric-only daily totals for history (kept long term)
struct DayTotals: Identifiable, Hashable, Codable {
    let id = UUID()
    var date: Date
    var calories: Int
    var protein: Int
    var carbs: Int
    var fats: Int
}

