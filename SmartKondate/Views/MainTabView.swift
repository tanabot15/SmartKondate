//
//  ContentView.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab: Tab = .dashboard
    
    enum Tab {
        case dashboard
        case patterns
        case menus
        case stock
        case settings
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardPlaceholderView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "square.grid.2x2.fill")
            }
            .tag(Tab.dashboard)
            
            NavigationStack {
                PatternListPlaceholderView()
            }
            .tabItem {
                Label("Patterns", systemImage: "calendar.day.timeline.left")
            }
            .tag(Tab.patterns)
            
            NavigationStack {
                MenuListPlaceholderView()
            }
            .tabItem {
                Label("Menus", systemImage: "fork.knife")
            }
            .tag(Tab.menus)
            
            NavigationStack {
                StockListPlaceholderView()
            }
            .tabItem {
                Label("Stock", systemImage: "checklist")
            }
            .tag(Tab.stock)
            
            NavigationStack {
                SettingsPlaceholderView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(Tab.settings)
        }
    }
}

// MARK: - Temporary Placeholders
// 今後のフェーズで各 View ファイルを作成した際に順次差し替えます

private struct DashboardPlaceholderView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Dashboard", systemImage: "square.grid.2x2.fill")
        } description: {
            Text("Today's menu and quick adjustments will appear here.")
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Dashboard")
    }
}

private struct PatternListPlaceholderView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Patterns", systemImage: "calendar.day.timeline.left")
        } description: {
            Text("Manage your weekly meal patterns here.")
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Patterns")
    }
}

private struct MenuListPlaceholderView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Menus", systemImage: "fork.knife")
        } description: {
            Text("Your recipe database will be managed here.")
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Menus")
    }
}

private struct StockListPlaceholderView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Stock Checklist", systemImage: "checklist")
        } description: {
            Text("Check items to buy regular pantry supplies.")
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Stock")
    }
}

private struct SettingsPlaceholderView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Settings", systemImage: "gearshape.fill")
        } description: {
            Text("CloudKit sharing and options will be configured here.")
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [
            Ingredient.self,
            Menu.self,
            PatternDay.self,
            KondatePattern.self,
            StockItem.self
        ], inMemory: true)
}
