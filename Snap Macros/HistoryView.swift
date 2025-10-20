//
//  HistoryView.swift
//  Snap Macros
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var historyVM: HistoryViewModel

    var body: some View {
        List {
            ForEach(historyVM.pastDays) { day in
                VStack(alignment: .leading, spacing: 4) {
                    Text(day.date, style: .date).font(.headline)
                    Text("\(day.calories) kcal • P \(day.protein)g • C \(day.carbs)g • F \(day.fats)g")
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }
        }
        .navigationTitle("History")
    }
}
