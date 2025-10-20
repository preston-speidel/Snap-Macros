//
//  Rings.swift
//  Snap Macros
//

import SwiftUI

struct RingGrid: View {
    let goals: MacroGoals
    let totals: (Int, Int, Int, Int)

    var body: some View {
        let (cals, prot, carbs, fats) = totals
        VStack(alignment: .center, spacing: 10) {
            // Large Calories ring (size 200)
            CircularRingView(title: "Calories",
                             value: cals,
                             goal: max(goals.calories, 1),
                             color: .green,
                             size: 200)

            // Three rings in a row with vertical offsets like your NutritionView
            HStack(spacing: 30) {
                CircularRingView(title: "Carbs",
                                 value: carbs,
                                 goal: max(goals.carbs, 1),
                                 color: .green,
                                 size: 80)
                .padding(.bottom, 160)

                CircularRingView(title: "Protein",
                                 value: prot,
                                 goal: max(goals.protein, 1),
                                 color: .green,
                                 size: 140)

                CircularRingView(title: "Fats",
                                 value: fats,
                                 goal: max(goals.fats, 1),
                                 color: .green,
                                 size: 80)
                .padding(.bottom, 160)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct CircularRingView: View {
    var title: String
    var value: Int
    var goal: Int
    var color: Color
    var size: CGFloat

    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 20)

                Circle()
                    .trim(from: 0, to: CGFloat(min(max(Double(value) / Double(max(goal,1)), 0), 1)))
                    .stroke(color, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut, value: value)

                VStack {
                    Text(title)
                        .font(.system(size: size * 0.15, weight: .bold))
                        .foregroundStyle(.primary)
                    if title == "Calories" {
                        Text("\(value) / \(goal)")
                            .font(.system(size: size * 0.14))
                            .foregroundStyle(.primary)
                    }
                }
            }
            .frame(width: size, height: size)

            if title != "Calories" {
                Text("\(value)g / \(goal)g")
                    .font(.system(size: size * 0.14, weight: .bold))
                    .foregroundStyle(.primary)
                    .padding(.top, 5)
            }
        }
    }
}
