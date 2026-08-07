//
//  DiffIngredientRow.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import SwiftUI

struct DiffIngredientRow: View {
    let ingredientName: String
    let amount: String
    let menuName: String
    let isModifiedMeal: Bool
    let isChecked: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isChecked ? Color.accentColor : Color.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(ingredientName)
                            .font(.body)
                            .fontWeight(isModifiedMeal ? .bold : .regular)
                            .foregroundStyle(isChecked ? .secondary : .primary)
                            .strikethrough(isChecked)

                        if isModifiedMeal {
                            Text("Changed")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.15))
                                .foregroundStyle(Color.accentColor)
                                .clipShape(Capsule())
                        }
                    }

                    Text("\(menuName)\(amount.isEmpty ? "" : " • \(amount)")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 16) {
        DiffIngredientRow(
            ingredientName: "Pork Slice",
            amount: "200g",
            menuName: "Pork Ginger (Standard)",
            isModifiedMeal: false,
            isChecked: false,
            onToggle: {}
        )
        
        DiffIngredientRow(
            ingredientName: "Salmon Fillet",
            amount: "2 pcs",
            menuName: "Grilled Salmon (Custom)",
            isModifiedMeal: true,
            isChecked: false,
            onToggle: {}
        )
        
        DiffIngredientRow(
            ingredientName: "Onion",
            amount: "1 pc",
            menuName: "Pork Ginger (Standard)",
            isModifiedMeal: false,
            isChecked: true,
            onToggle: {}
        )
    }
    .padding()
    .background(Color(.secondarySystemGroupedBackground))
}
