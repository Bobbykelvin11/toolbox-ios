import SwiftUI

struct WebToolTabView: View {
    let title: String
    let targetURL: URL
    var emptyOverlayMessage: String? = nil

    @StateObject private var store: WebViewStore
    @State private var activeExportMode: ExportMode?

    private enum ExportMode: Identifiable {
        case files(URL)
        case share(URL)

        var id: String {
            switch self {
            case .files(let url): return "files:\(url.path)"
            case .share(let url): return "share:\(url.path)"
            }
        }
    }

    init(title: String, targetURL: URL, emptyOverlayMessage: String? = nil) {
        self.title = title
        self.targetURL = targetURL
        self.emptyOverlayMessage = emptyOverlayMessage
        _store = StateObject(wrappedValue: WebViewStore(homeURL: targetURL))
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                WebViewRepresentable(targetURL: targetURL, store: store)

                if store.isLoading {
                    ProgressView(value: max(store.estimatedProgress, 0.08))
                        .progressViewStyle(.linear)
                        .tint(Color("AccentColor"))
                }

                if let errorMessage = store.loadErrorMessage {
                    VStack(spacing: 14) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: 36))
                            .foregroundStyle(.secondary)
                        Text("Could Not Load \(title)")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Text(targetURL.absoluteString)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        HStack(spacing: 12) {
                            Button("Retry") {
                                store.reload()
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Home") {
                                store.loadHome()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                    .background(Color(.systemBackground).opacity(0.96))
                }
            }

            Divider()

            HStack(spacing: 0) {
                toolbarButton(systemName: "chevron.left", label: "Back", disabled: !store.canGoBack) {
                    store.goBack()
                }
                Spacer()
                toolbarButton(systemName: "chevron.right", label: "Forward", disabled: !store.canGoForward) {
                    store.goForward()
                }
                Spacer()
                toolbarButton(systemName: "house", label: "Home") {
                    store.loadHome()
                }
                Spacer()
                toolbarButton(systemName: "arrow.clockwise", label: "Reload") {
                    store.reload()
                }
                Spacer()
                toolbarButton(systemName: "safari", label: "Open in Safari") {
                    let current = store.webView?.url ?? targetURL
                    store.openExternalURL(current)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground))
        }
        .sheet(item: $store.safariItem) { item in
            SafariView(url: item.url)
                .ignoresSafeArea()
        }
        .sheet(item: $store.downloadedFile) { file in
            NavigationStack {
                VStack(spacing: 20) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color("AccentColor"))
                        .padding(.top, 12)

                    VStack(spacing: 6) {
                        Text("Download Ready")
                            .font(.title3.bold())
                        Text(file.filename)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        Text(ByteCountFormatter.string(fromByteCount: file.byteCount, countStyle: .file))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 12) {
                        Button {
                            activeExportMode = .files(file.url)
                        } label: {
                            Label("Save to Files", systemImage: "folder")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)

                        Button {
                            activeExportMode = .share(file.url)
                        } label: {
                            Label("Share / Open In...", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                    .padding(.top, 8)

                    Spacer()
                }
                .padding()
                .navigationTitle("Export File")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") {
                            store.downloadedFile = nil
                        }
                    }
                }
                .sheet(item: $activeExportMode) { mode in
                    switch mode {
                    case .files(let url):
                        DocumentExportPicker(fileURL: url) {
                            activeExportMode = nil
                            store.downloadedFile = nil
                        }
                    case .share(let url):
                        ShareSheetView(activityItems: [url])
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .alert(
            "Download Notice",
            isPresented: Binding(
                get: { store.downloadErrorMessage != nil },
                set: { if !$0 { store.downloadErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.downloadErrorMessage ?? "")
        }
    }

    private func toolbarButton(
        systemName: String,
        label: String,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .medium))
                .frame(width: 44, height: 32)
                .foregroundStyle(disabled ? Color.secondary.opacity(0.4) : Color.primary)
        }
        .disabled(disabled)
        .accessibilityLabel(label)
    }
}
