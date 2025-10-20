//
//  GoalsView.swift
//  Snap Macros
//

import SwiftUI

struct GoalsView: View {
    @EnvironmentObject var goalsVM: GoalsViewModel

    var body: some View {
        Form {
            Section("Daily Goals") {
                Stepper(value: $goalsVM.goals.calories, in: 0...6000, step: 50) {
                    HStack { Text("Calories"); Spacer(); Text("\(goalsVM.goals.calories) kcal") }
                }
                Stepper(value: $goalsVM.goals.protein, in: 0...400) {
                    HStack { Text("Protein"); Spacer(); Text("\(goalsVM.goals.protein) g") }
                }
                Stepper(value: $goalsVM.goals.carbs, in: 0...600) {
                    HStack { Text("Carbs"); Spacer(); Text("\(goalsVM.goals.carbs) g") }
                }
                Stepper(value: $goalsVM.goals.fats, in: 0...250) {
                    HStack { Text("Fats"); Spacer(); Text("\(goalsVM.goals.fats) g") }
                }
            }
            .font(.body)
        }
        .navigationTitle("Goals")
    }
}
