import SwiftUI

@main
struct ToolboxApp: App {
    @StateObject private var settings = ToolSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
        }
    }
}
