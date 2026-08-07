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
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Ingredient.self,
            Menu.self,
            PatternDay.self,
            KondatePattern.self,
            StockItem.self
        ])
        
        // 💡 Preview (Canvas) やシミュレータ環境では CloudKit 同期をオフにする
        #if DEBUG
        let cloudKitSetting: ModelConfiguration.CloudKitDatabase = .none
        #else
        let cloudKitSetting: ModelConfiguration.CloudKitDatabase = .automatic
        #endif

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: cloudKitSetting
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
