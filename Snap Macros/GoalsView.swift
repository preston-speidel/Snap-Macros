//
//  GoalsView.swift
//  Snap Macros
//

import SwiftUI

struct GoalsView: View {
    @EnvironmentObject var goalsVM: GoalsViewModel

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Daily Goals")
                    .font(.title2)
                    .bold()
                    .padding(.top)

                HStack {
                    Text("Calories")
                    Spacer()
                    Text("\(goalsVM.goals.calories) kcal")
                }
                Stepper(value: $goalsVM.goals.calories, in: 0...6000, step: 50) {
                    EmptyView()
                }

                HStack {
                    Text("Protein")
                    Spacer()
                    Text("\(goalsVM.goals.protein) g")
                }
                Stepper(value: $goalsVM.goals.protein, in: 0...400) {
                    EmptyView()
                }

                HStack {
                    Text("Carbs")
                    Spacer()
                    Text("\(goalsVM.goals.carbs) g")
                }
                Stepper(value: $goalsVM.goals.carbs, in: 0...600) {
                    EmptyView()
                }

                HStack {
                    Text("Fats")
                    Spacer()
                    Text("\(goalsVM.goals.fats) g")
                }
                Stepper(value: $goalsVM.goals.fats, in: 0...250) {
                    EmptyView()
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Goals")
        }
    }
}
