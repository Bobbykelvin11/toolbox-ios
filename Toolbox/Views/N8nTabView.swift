import SwiftUI

struct N8nTabView: View {
    @EnvironmentObject private var settings: ToolSettings
    @Binding var selectedTab: ToolboxTab

    @State private var draftURL: String = ""
    @State private var validationMessage: String?
    @State private var safariItem: SafariItem?

    var body: some View {
        Group {
            if let configuredURL = settings.effectiveN8nURL {
                WebToolTabView(title: "n8n", targetURL: configuredURL)
            } else {
                setupExplainerView
            }
        }
        .onAppear {
            if draftURL.isEmpty {
                draftURL = settings.n8nURL
            }
        }
    }

    private var setupExplainerView: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 12) {
                            Image(systemName: "point.3.connected.trianglepath.dotted")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 52, height: 52)
                                .background(Color.orange.gradient, in: RoundedRectangle(cornerRadius: 14))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("n8n Automation")
                                    .font(.title3.bold())
                                Text("Requires a Server Instance")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Text("n8n is a workflow automation backend that runs on a server (Docker, VPS, home lab, or n8n Cloud) rather than locally on an iPhone. Once you have an instance running, enter its URL below or in Settings to open the full editor right here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Connect Your n8n URL")
                            .font(.headline)

                        TextField("https://n8n.example.com or http://192.168.1.50:5678", text: $draftURL)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        if let validationMessage {
                            Text(validationMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }

                        HStack(spacing: 10) {
                            Button {
                                connectDraftURL()
                            } label: {
                                Label("Connect", systemImage: "arrow.right.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)

                            Button {
                                selectedTab = .settings
                            } label: {
                                Label("Settings", systemImage: "gearshape")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Learn & Self-Host")
                            .font(.headline)

                        Button {
                            if let url = URL(string: ToolDefaults.n8nHomeURL) {
                                safariItem = SafariItem(url: url)
                            }
                        } label: {
                            HStack {
                                Label("n8n Official Website (n8n.io)", systemImage: "globe")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }

                        Divider()

                        Button {
                            if let url = URL(string: ToolDefaults.n8nDocsURL) {
                                safariItem = SafariItem(url: url)
                            }
                        } label: {
                            HStack {
                                Label("Self-Hosting Docs (Docker & Server)", systemImage: "server.rack")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("n8n")
            .sheet(item: $safariItem) { item in
                SafariView(url: item.url)
                    .ignoresSafeArea()
            }
        }
    }

    private func connectDraftURL() {
        let trimmed = draftURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let normalized = ToolSettings.normalizedURL(from: trimmed) else {
            validationMessage = "Enter a valid http:// or https:// host URL."
            return
        }
        validationMessage = nil
        settings.n8nURL = normalized.absoluteString
    }
}
