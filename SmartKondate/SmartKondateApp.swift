//
//  SmartKondateApp.swift
//  SmartKondate
//

import SwiftUI
import SwiftData

@main
struct SmartKondateApp: App {
    @AppStorage("userColorScheme") private var userColorScheme: String = "system"

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Ingredient.self,
            Menu.self,
            PatternDay.self,
            KondatePattern.self,
            StockItem.self,
            SavedShoppingList.self,
            SavedIngredientItem.self,
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("Failed to initialize ModelContainer. Attempting to recreate database: \(error)")
            
            let url = modelConfiguration.url
            let fileManager = FileManager.default
            let urlPath = url.path
            
            try? fileManager.removeItem(at: url)
            try? fileManager.removeItem(atPath: "\(urlPath)-shm")
            try? fileManager.removeItem(atPath: "\(urlPath)-wal")
            
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not reset ModelContainer: \(error)")
            }
        }
    }()

    private var selectedColorScheme: ColorScheme? {
        switch userColorScheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(selectedColorScheme)
        }
        .modelContainer(sharedModelContainer)
    }
}
