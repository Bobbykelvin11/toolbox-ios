import SwiftUI
import WebKit

struct SettingsView: View {
    @EnvironmentObject private var settings: ToolSettings

    @State private var stirlingDraft: String = ""
    @State private var openCutDraft: String = ""
    @State private var n8nDraft: String = ""
    @State private var statusMessage: String?
    @State private var showClearCacheAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(ToolDefaults.stirlingPDFURL, text: $stirlingDraft)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Button("Reset to Hosted Default") {
                        settings.resetStirlingURL()
                        stirlingDraft = settings.stirlingPDFURL
                        statusMessage = "Stirling-PDF URL reset to default."
                    }
                    .font(.subheadline)
                } header: {
                    Text("Stirling-PDF")
                } footer: {
                    Text("Default: \(ToolDefaults.stirlingPDFURL). Replace with your self-hosted Stirling-PDF server URL if you run your own.")
                }

                Section {
                    TextField(ToolDefaults.openCutURL, text: $openCutDraft)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Button("Reset to Hosted Default") {
                        settings.resetOpenCutURL()
                        openCutDraft = settings.openCutURL
                        statusMessage = "OpenCut URL reset to default."
                    }
                    .font(.subheadline)
                } header: {
                    Text("OpenCut")
                } footer: {
                    Text("Default: \(ToolDefaults.openCutURL). You can also point this to a self-hosted OpenCut instance.")
                }

                Section {
                    TextField("https://n8n.example.com (optional)", text: $n8nDraft)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    if !n8nDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button("Clear n8n URL", role: .destructive) {
                            settings.clearN8nURL()
                            n8nDraft = ""
                            statusMessage = "n8n URL cleared."
                        }
                        .font(.subheadline)
                    }
                } header: {
                    Text("n8n Instance")
                } footer: {
                    Text("Leave empty to see the n8n setup guide, or enter your n8n Cloud / self-hosted URL.")
                }

                Section {
                    Button {
                        applyURLs()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Save URLs", systemImage: "checkmark.circle.fill")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }

                    if let statusMessage {
                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Storage & Privacy") {
                    Button(role: .destructive) {
                        showClearCacheAlert = true
                    } label: {
                        Label("Clear Web Cache & Cookies", systemImage: "trash")
                    }
                }

                Section("App Info") {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About Toolbox & Licenses", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                stirlingDraft = settings.stirlingPDFURL
                openCutDraft = settings.openCutURL
                n8nDraft = settings.n8nURL
            }
            .alert("Clear Web Data?", isPresented: $showClearCacheAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    clearAllWebData()
                }
            } message: {
                Text("This clears cookies, cached pages, and local web storage across Stirling-PDF, OpenCut, and n8n.")
            }
        }
    }

    private func applyURLs() {
        let sTrim = stirlingDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if sTrim.isEmpty {
            settings.resetStirlingURL()
            stirlingDraft = settings.stirlingPDFURL
        } else if let sURL = ToolSettings.normalizedURL(from: sTrim) {
            settings.stirlingPDFURL = sURL.absoluteString
            stirlingDraft = sURL.absoluteString
        } else {
            statusMessage = "Invalid Stirling-PDF URL. Keep http:// or https://."
            return
        }

        let oTrim = openCutDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if oTrim.isEmpty {
            settings.resetOpenCutURL()
            openCutDraft = settings.openCutURL
        } else if let oURL = ToolSettings.normalizedURL(from: oTrim) {
            settings.openCutURL = oURL.absoluteString
            openCutDraft = oURL.absoluteString
        } else {
            statusMessage = "Invalid OpenCut URL. Keep http:// or https://."
            return
        }

        let nTrim = n8nDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if nTrim.isEmpty {
            settings.clearN8nURL()
            n8nDraft = ""
        } else if let nURL = ToolSettings.normalizedURL(from: nTrim) {
            settings.n8nURL = nURL.absoluteString
            n8nDraft = nURL.absoluteString
        } else {
            statusMessage = "Invalid n8n URL. Keep http:// or https://."
            return
        }

        statusMessage = "Saved custom URLs."
    }

    private func clearAllWebData() {
        let dataStore = WKWebsiteDataStore.default()
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        dataStore.fetchDataRecords(ofTypes: types) { records in
            dataStore.removeData(ofTypes: types, for: records) {
                Task { @MainActor in
                    statusMessage = "Cleared web cache and cookies."
                }
            }
        }
    }
}
