//
//  ViewModels.swift
//  Snap Macros
//

import SwiftUI
import Combine
import UIKit
import Foundation

/*
private enum StoreKey {
    static let todayMeals = "SM.today.meals.v1"
    static let todayTotals = "SM.today.totals.v1"
    static let lastDay = "SM.last.day.v1"
    static let history = "SM.history.v1"
    static let goals = "SM.goals.v1"
}
*/

private enum StoreKey {
    static let todayMeals = "SM.today.meals.v1"
    static let todayTotals = "SM.today.totals.v1"
    static let lastDay    = "SM.last.day.v1"
    static let history    = "SM.history.v1"
    static let goals      = "SM.goals.v1"
    static let usageCount = "SM.usage.count.v1"
}

private func saveCodable<T: Codable>(_ value: T, key: String) {
    do {
        let data = try JSONEncoder().encode(value)
        UserDefaults.standard.set(data, forKey: key)
    } catch {
        print("Save failed for \(key): \(error)")
    }
}

private func loadCodable<T: Codable>(_ type: T.Type, key: String) -> T? {
    guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
    do {
        return try JSONDecoder().decode(T.self, from: data)
    } catch {
        print("Load failed for \(key): \(error)")
        return nil
    }
}

private func startOfDay(_ date: Date) -> Date {
    Calendar.current.startOfDay(for: date)
}

// MARK: - Goals

@MainActor
final class GoalsViewModel: ObservableObject {
    @Published var goals: (calories: Int, protein: Int, carbs: Int, fats: Int) = (2000, 150, 200, 70) {
        didSet { persist() }
    }

    init() {
        if let g = loadCodable([Int].self, key: StoreKey.goals), g.count == 4 {
            goals = (g[0], g[1], g[2], g[3])
        } else {
            persist()
        }
    }

    private func persist() {
        let array = [goals.calories, goals.protein, goals.carbs, goals.fats]
        saveCodable(array, key: StoreKey.goals)
    }
}

// MARK: - Today

@MainActor
final class TodayViewModel: ObservableObject {
    @Published private(set) var todayMeals: [MealEstimate] = []   // keep images while it's "today"
    @Published private(set) var calories = 0
    @Published private(set) var protein = 0
    @Published private(set) var carbs = 0
    @Published private(set) var fats = 0
    @Published private(set) var aiPhotosUsed = 0

    init() {
        // Load persisted "today"
        if let meals = loadCodable([MealEstimate].self, key: StoreKey.todayMeals) {
            self.todayMeals = meals
        }
        if let totals = loadCodable([Int].self, key: StoreKey.todayTotals), totals.count == 4 {
            (calories, protein, carbs, fats) = (totals[0], totals[1], totals[2], totals[3])
        } else {
            persistTotals()
        }
        aiPhotosUsed = loadCodable(Int.self, key: StoreKey.usageCount) ?? 0
        rolloverIfNeeded()
    }
    
    func canSnapAI(limit: Int = 10) -> Bool { aiPhotosUsed < limit }

    func recordAIUsage() {
        aiPhotosUsed += 1
        saveCodable(aiPhotosUsed, key: StoreKey.usageCount)
        saveCodable(startOfDay(Date()), key: StoreKey.lastDay)
    }

    func add(estimate: MealEstimate) {
        todayMeals.insert(estimate, at: 0)
        calories += estimate.calories
        protein += estimate.protein
        carbs += estimate.carbs
        fats += estimate.fats
        persistToday()
    }

    // MARK: - Persistence

    private func persistToday() {
        saveCodable(todayMeals, key: StoreKey.todayMeals)
        persistTotals()
        saveCodable(aiPhotosUsed, key: StoreKey.usageCount)
        saveCodable(startOfDay(Date()), key: StoreKey.lastDay)
    }

    private func persistTotals() {
        saveCodable([calories, protein, carbs, fats], key: StoreKey.todayTotals)
    }

    // MARK: - Daily rollover (on first launch of new day)

    func rolloverIfNeeded() {
        let today = startOfDay(Date())
        let last = (loadCodable(Date.self, key: StoreKey.lastDay)) ?? today
        guard last != today else { return }

        // 1) Create numeric summary for yesterday
        let summary = DailySummary(
            date: last,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fats: fats
        )

        // 2) Append to history
        var history = loadCodable([DailySummary].self, key: StoreKey.history) ?? []
        history.insert(summary, at: 0)
        saveCodable(history, key: StoreKey.history)

        // 3) Reset today's state (drop photos)
        todayMeals = []
        calories = 0; protein = 0; carbs = 0; fats = 0
        aiPhotosUsed = 0

        // 4) Persist empty today + new lastDay
        persistToday()
    }
}

// MARK: - History

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published private(set) var days: [DailySummary] = []

    init() {
        load()
    }

    func load() {
        days = loadCodable([DailySummary].self, key: StoreKey.history) ?? []
        // Optional: sort newest first
        days.sort { $0.date > $1.date }
    }

    // Optional: clear all history
    func clear() {
        days = []
        saveCodable(days, key: StoreKey.history)
    }
}

final class CameraViewModel: ObservableObject {
    @Published var capturedImage: UIImage? = nil
}

@MainActor
final class AnalysisViewModel: ObservableObject {
    @Published var lastEstimate: MealEstimate?
    @Published var isAnalyzing = false
    @Published var errorMessage: String?

    private let client = OpenAIClient() // hardcoded key lives inside

    func analyze(image: UIImage) async {
        isAnalyzing = true
        errorMessage = nil
        defer { isAnalyzing = false }

        do {
            let estimate = try await client.analyzeMeal(from: image)
            self.lastEstimate = estimate
        } catch {
            // Map to friendly text
            if let e = error as? OpenAIClientError {
                switch e {
                case .missingKey:
                    errorMessage = "Missing API key. Add your key to OpenAIClient.swift."
                default:
                    errorMessage = "We couldn’t analyze your photo. Please check your connection and try again later."
                }
            } else {
                errorMessage = "We couldn’t analyze your photo. Please try again later."
            }
            self.lastEstimate = nil
        }
    }

    func clear() {
        lastEstimate = nil
        errorMessage = nil
    }
}
