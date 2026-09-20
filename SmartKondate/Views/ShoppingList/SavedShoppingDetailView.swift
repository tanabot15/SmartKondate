//
//  SavedShoppingDetailView.swift
//  SmartKondate
//

import SwiftUI
import SwiftData

struct SavedShoppingDetailView: View {
    @Bindable var shoppingList: SavedShoppingList

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allStockItems: [StockItem]

    @State private var showCopiedToast = false
    @State private var showCompleteAlert = false

    // Group saved items by category
    private var groupedItemsByCategory: [(category: String, items: [SavedIngredientItem])] {
        let grouped = Dictionary(grouping: shoppingList.items, by: { $0.categoryRawValue })
        return grouped.map { (category: $0.key, items: $0.value) }
            .sorted { $0.category < $1.category }
    }

    // Exportable plain text content
    private var formattedTextForSharing: String {
        var text = "【\(shoppingList.title)】\n\n"
        for group in groupedItemsByCategory {
            text += "■ \(group.category)\n"
            for item in group.items {
                let checkMark = item.isChecked ? "[x]" : "[ ]"
                let qtyStr = item.quantity.truncatingRemainder(dividingBy: 1) == 0
                    ? String(format: "%.0f", item.quantity)
                    : String(format: "%.1f", item.quantity)
                let unitStr = item.unit.isEmpty ? "" : " \(item.unit)"
                text += "\(checkMark) \(item.name): \(qtyStr)\(unitStr)\n"
            }
            text += "\n"
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ZStack {
            List {
                ForEach(groupedItemsByCategory, id: \.category) { group in
                    Section(header: Text(group.category)) {
                        ForEach(group.items) { item in
                            DiffIngredientRow(
                                ingredientName: item.name,
                                quantity: item.quantity,
                                unit: item.unit,
                                menuDetails: item.menuDetails,
                                isModifiedMeal: false,
                                isChecked: item.isChecked,
                                onToggle: { item.isChecked.toggle() },
                                onQuantityChange: { item.quantity = $0 }
                            )
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            
            if showCopiedToast {
                toastView(message: "Copied to clipboard", icon: "checkmark.circle.fill", color: .green)
            }
        }
        .navigationTitle(shoppingList.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: formattedTextForSharing) {
                    Image(systemName: "square.and.arrow.up")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(action: copyToClipboard) {
                    Image(systemName: "doc.on.doc")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button { showCompleteAlert = true } label: {
                    Image(systemName: "checkmark.circle.fill")
                }
            }
        }
        .alert("Complete Shopping?", isPresented: $showCompleteAlert) {
            Button("Complete & Clear Stock Out", role: .destructive) {
                completeShopping(clearStockOut: true)
            }
            Button("Complete Only") {
                completeShopping(clearStockOut: false)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Would you like to reset all out-of-stock items in your Stock Checklist as restocked?")
        }
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = formattedTextForSharing
        withAnimation { showCopiedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { showCopiedToast = false }
        }
    }

    private func completeShopping(clearStockOut: Bool) {
        if clearStockOut {
            for stockItem in allStockItems {
                stockItem.isOut = false
            }
        }
        modelContext.delete(shoppingList)
        dismiss()
    }

    private func toastView(message: String, icon: String, color: Color) -> some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundStyle(color)
                Text(message).font(.subheadline).fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(radius: 4)
            .padding(.bottom, 20)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

#Preview("Detail View") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: SavedShoppingList.self, SavedIngredientItem.self, StockItem.self,
        configurations: config
    )
    let context = container.mainContext

    let list = SavedShoppingList(title: "今週の食材買い出し")
    
    let items = [
        SavedIngredientItem(name: "鶏もも肉", quantity: 2, unit: "枚", categoryRawValue: "肉・魚", menuDetails: "チキン南蛮", isChecked: false),
        SavedIngredientItem(name: "サーモン", quantity: 2, unit: "切れ", categoryRawValue: "肉・魚", menuDetails: "鮭の塩焼き", isChecked: true),
        SavedIngredientItem(name: "玉ねぎ", quantity: 3, unit: "個", categoryRawValue: "野菜・果物", menuDetails: "カレー", isChecked: false),
        SavedIngredientItem(name: "みそ", quantity: 1, unit: "パック", categoryRawValue: "調味料・穀物", menuDetails: "", isChecked: false)
    ]
    
    list.items = items
    context.insert(list)

    let stockItem = StockItem(name: "玉ねぎ", isOut: true)
    context.insert(stockItem)

    return NavigationStack {
        SavedShoppingDetailView(shoppingList: list)
    }
    .modelContainer(container)
}
