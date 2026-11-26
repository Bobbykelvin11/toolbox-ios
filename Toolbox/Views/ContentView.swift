import SwiftUI

enum ToolboxTab: Hashable {
    case pdf
    case video
    case automate
    case more
    case settings
}

struct ContentView: View {
    @EnvironmentObject private var settings: ToolSettings
    @State private var selectedTab: ToolboxTab = .pdf

    var body: some View {
        TabView(selection: $selectedTab) {
            WebToolTabView(title: "Stirling-PDF", targetURL: settings.effectiveStirlingURL)
                .tabItem {
                    Label("PDF", systemImage: "doc.richtext")
                }
                .tag(ToolboxTab.pdf)

            WebToolTabView(title: "OpenCut", targetURL: settings.effectiveOpenCutURL)
                .tabItem {
                    Label("OpenCut", systemImage: "film")
                }
                .tag(ToolboxTab.video)

            N8nTabView(selectedTab: $selectedTab)
                .tabItem {
                    Label("n8n", systemImage: "point.3.connected.trianglepath.dotted")
                }
                .tag(ToolboxTab.automate)

            InfoCardsView()
                .tabItem {
                    Label("More", systemImage: "square.grid.2x2")
                }
                .tag(ToolboxTab.more)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(ToolboxTab.settings)
        }
    }
}
