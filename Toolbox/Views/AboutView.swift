import SwiftUI

struct AboutView: View {
    @State private var safariItem: SafariItem?

    private var appVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    private var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.bobbymedia.toolbox"
    }

    var body: some View {
        List {
            Section("Toolbox for iOS") {
                LabeledContent("Version", value: appVersion)
                LabeledContent("Bundle ID", value: bundleIdentifier)
                LabeledContent("Minimum iOS", value: "16.0")
                Text("Toolbox brings together five open-source tools in a single iOS app, wrapping web-ready apps in WKWebView with file upload/download support and providing info cards and iOS alternatives for desktop-only or Android TV-only projects.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Credited Projects & Licenses") {
                projectRow(
                    name: "Stirling-PDF",
                    author: "Stirling-Tools/Stirling-PDF",
                    license: "MIT License (proprietary/SaaS modules under separate license terms)",
                    summary: "Full-featured PDF editing and manipulation web app.",
                    links: [
                        ("Hosted Web App", ToolDefaults.stirlingPDFURL),
                        ("GitHub Repository", ToolDefaults.stirlingRepoURL),
                    ]
                )

                projectRow(
                    name: "OpenCut",
                    author: "OpenCut-app/OpenCut",
                    license: "MIT License",
                    summary: "Open-source browser-based video editor.",
                    links: [
                        ("OpenCut Web App", ToolDefaults.openCutHomeURL),
                        ("GitHub Repository", ToolDefaults.openCutRepoURL),
                    ]
                )

                projectRow(
                    name: "n8n",
                    author: "n8n-io/n8n",
                    license: "Sustainable Use License (Fair-code) / n8n Enterprise License",
                    summary: "Self-hosted and cloud workflow automation platform.",
                    links: [
                        ("n8n.io", ToolDefaults.n8nHomeURL),
                        ("Self-Hosting Docs", ToolDefaults.n8nDocsURL),
                        ("GitHub Repository", ToolDefaults.n8nRepoURL),
                    ]
                )

                projectRow(
                    name: "SmartTube",
                    author: "yuliskov/SmartTube",
                    license: "MIT License",
                    summary: "Android TV / Fire TV client (info card only; not built for iOS).",
                    links: [
                        ("GitHub Repository", ToolDefaults.smartTubeRepoURL),
                    ]
                )

                projectRow(
                    name: "Yattee (iOS Alternative)",
                    author: "yattee/yattee",
                    license: "GNU Affero General Public License v3.0 (AGPL-3.0)",
                    summary: "Privacy-oriented open-source video player for iOS, tvOS, and macOS.",
                    links: [
                        ("App Store", ToolDefaults.yatteeAppStoreURL),
                        ("GitHub Repository", ToolDefaults.yatteeRepoURL),
                    ]
                )

                projectRow(
                    name: "Wan2GP (WanGP)",
                    author: "deepbeepmeep/Wan2GP",
                    license: "WanGP Community License 2.0",
                    summary: "Local AI video/image generator for desktop NVIDIA/AMD GPUs (info card only).",
                    links: [
                        ("GitHub Repository", ToolDefaults.wan2gpRepoURL),
                    ]
                )
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $safariItem) { item in
            SafariView(url: item.url)
                .ignoresSafeArea()
        }
    }

    private func projectRow(
        name: String,
        author: String,
        license: String,
        summary: String,
        links: [(String, String)]
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(name)
                .font(.headline)
            Text(author)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
            Text("License: \(license)")
                .font(.caption.weight(.medium))
                .foregroundStyle(Color("AccentColor"))
            Text(summary)
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                ForEach(links, id: \.0) { label, urlStr in
                    Button(label) {
                        openLink(urlStr)
                    }
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.bordered)
                }
            }
            .padding(.top, 2)
        }
        .padding(.vertical, 4)
    }

    private func openLink(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        if url.host?.contains("apps.apple.com") == true {
            UIApplication.shared.open(url)
        } else {
            safariItem = SafariItem(url: url)
        }
    }
}
