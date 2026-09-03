//
//  SmartKondateApp.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
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
            StockItem.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
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
