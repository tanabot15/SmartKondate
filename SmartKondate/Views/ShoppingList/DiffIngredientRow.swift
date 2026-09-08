//
//  DiffIngredientRow.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import SwiftUI

struct DiffIngredientRow: View {
    let ingredientName: String
    let amountText: String
    let menuDetails: String
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

                        if !amountText.isEmpty {
                            Text("(\(amountText))")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundStyle(isChecked ? .secondary : Color.accentColor)
                        }

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

                    if !menuDetails.isEmpty {
                        Text(menuDetails)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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
            amountText: "200g",
            menuDetails: "Pork Ginger (Standard)",
            isModifiedMeal: false,
            isChecked: false,
            onToggle: {}
        )
        
        DiffIngredientRow(
            ingredientName: "Salmon Fillet",
            amountText: "2 pcs",
            menuDetails: "Grilled Salmon (Custom)",
            isModifiedMeal: true,
            isChecked: false,
            onToggle: {}
        )
        
        DiffIngredientRow(
            ingredientName: "Onion",
            amountText: "1 pc",
            menuDetails: "Pork Ginger (Standard)",
            isModifiedMeal: false,
            isChecked: true,
            onToggle: {}
        )
    }
    .padding()
    .background(Color(.secondarySystemGroupedBackground))
}
