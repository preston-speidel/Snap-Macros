//
//  Models.swift
//  Snap Macros
//

import Foundation
import SwiftUI

//user set goals for a day
struct MacroGoals: Codable, Hashable {
    var calories: Int
    var protein: Int
    var carbs: Int
    var fats: Int
}

//per meal estimate returned by AI
struct MealEstimate: Identifiable, Hashable, Codable {
    let id: UUID = UUID()
    var title: String //"Chicken bowl"
    var calories: Int
    var protein: Int
    var carbs: Int
    var fats: Int
    var items: [DetectedItem] //breakdown
    var imageData: Data? //JPEG bytes for today's feed thumbnail
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

//numeric only daily totals for history (kept long term)
struct DayTotals: Identifiable, Hashable, Codable {
    let id = UUID()
    var date: Date
    var calories: Int
    var protein: Int
    var carbs: Int
    var fats: Int
}

struct DailySummary: Identifiable, Codable {
    let id = UUID()
    let date: Date        // start-of-day date
    let calories: Int
    let protein: Int
    let carbs: Int
    let fats: Int
}
