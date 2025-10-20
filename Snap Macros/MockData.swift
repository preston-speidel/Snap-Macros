//
//  MockData.swift
//  Snap Macros
//

import SwiftUI


enum MockData {
    static let sampleGoals = MacroGoals(calories: 2400, protein: 180, carbs: 250, fats: 80)

    static let sampleItems: [DetectedItem] = [
        .init(name: "Grilled chicken", grams: 180, calories: 300, protein: 54, carbs: 0, fats: 6),
        .init(name: "Rice", grams: 200, calories: 260, protein: 5, carbs: 56, fats: 1),
        .init(name: "Broccoli", grams: 120, calories: 40, protein: 3, carbs: 8, fats: 0)
    ]

    static let sampleEstimate = MealEstimate(
        title: "Chicken rice bowl",
        calories: 600,
        protein: 62,
        carbs: 64,
        fats: 7,
        items: sampleItems,
        imageData: nil,
        timestamp: Date()
    )

    static let sampleHistory: [DayTotals] = {
        let cal = Calendar.current
        return (1...7).compactMap { i in
            guard let d = cal.date(byAdding: .day, value: -i, to: Date()) else { return nil }
            return DayTotals(date: d, calories: 2200 + i*10, protein: 160 + i, carbs: 240 + i*5, fats: 70 + i)
        }
    }()
}
