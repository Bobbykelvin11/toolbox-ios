import Combine
import Foundation
import SwiftUI
import UIKit
import WebKit

@MainActor
final class WebViewStore: ObservableObject {
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var isLoading = false
    @Published var estimatedProgress: Double = 0
    @Published var loadErrorMessage: String?
    @Published var safariItem: SafariItem?
    @Published var downloadedFile: DownloadedFileItem?
    @Published var downloadErrorMessage: String?

    weak var webView: WKWebView?
    private(set) var homeURL: URL

    init(homeURL: URL) {
        self.homeURL = homeURL
    }

    func loadHome() {
        loadErrorMessage = nil
        webView?.load(URLRequest(url: homeURL))
    }

    func updateHomeURL(_ newURL: URL) {
        guard newURL != homeURL else { return }
        homeURL = newURL
        loadHome()
    }

    func goBack() {
        webView?.goBack()
    }

    func goForward() {
        webView?.goForward()
    }

    func reload() {
        loadErrorMessage = nil
        if webView?.url == nil {
            loadHome()
        } else {
            webView?.reload()
        }
    }

    func openExternalURL(_ url: URL) {
        guard let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = url.host, !host.isEmpty
        else { return }
        safariItem = SafariItem(url: url)
    }

    func clearWebsiteData() {
        let dataStore = WKWebsiteDataStore.default()
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        dataStore.fetchDataRecords(ofTypes: types) { records in
            dataStore.removeData(ofTypes: types, for: records) {}
        }
    }
}

private final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?

    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}

struct WebViewRepresentable: UIViewRepresentable {
    let targetURL: URL
    @ObservedObject var store: WebViewStore

    func makeCoordinator() -> Coordinator {
        Coordinator(store: store, initialURL: targetURL)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = true

        let contentController = WKUserContentController()
        let downloadScript = WKUserScript(
            source: Self.blobDownloadHookJS,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        contentController.addUserScript(downloadScript)
        contentController.add(
            WeakScriptMessageHandler(delegate: context.coordinator),
            name: Coordinator.downloadMessageName
        )
        config.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.alwaysBounceVertical = true

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(
            context.coordinator,
            action: #selector(Coordinator.handleRefresh(_:)),
            for: .valueChanged
        )
        webView.scrollView.refreshControl = refreshControl

        context.coordinator.observe(webView)
        store.webView = webView
        webView.load(URLRequest(url: targetURL))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if context.coordinator.currentBaseURL != targetURL {
            context.coordinator.currentBaseURL = targetURL
            Task { @MainActor in
                store.updateHomeURL(targetURL)
            }
        }
    }

    private static let blobDownloadHookJS = """
    (function() {
      if (window.__toolboxDownloadHooked) return;
      window.__toolboxDownloadHooked = true;

      function arrayBufferToBase64(buffer) {
        var bytes = new Uint8Array(buffer);
        var chunkSize = 0x8000;
        var parts = [];
        for (var i = 0; i < bytes.length; i += chunkSize) {
          parts.push(String.fromCharCode.apply(null, bytes.subarray(i, i + chunkSize)));
        }
        return btoa(parts.join(''));
      }

      function dispatchDownload(href, filename) {
        fetch(href)
          .then(function(res) { return res.arrayBuffer(); })
          .then(function(buf) {
            var b64 = arrayBufferToBase64(buf);
            window.webkit.messageHandlers.toolboxDownload.postMessage({
              filename: filename || 'download',
              base64: b64
            });
          })
          .catch(function() {});
      }

      var origClick = HTMLAnchorElement.prototype.click;
      HTMLAnchorElement.prototype.click = function() {
        var href = this.href || '';
        if (href.indexOf('blob:') === 0 || href.indexOf('data:') === 0) {
          dispatchDownload(href, this.getAttribute('download') || 'download');
          return;
        }
        return origClick.apply(this, arguments);
      };

      document.addEventListener('click', function(e) {
        var target = e.target;
        while (target && target.tagName !== 'A') {
          target = target.parentElement;
        }
        if (!target) return;
        var href = target.href || '';
        if (href.indexOf('blob:') === 0 || href.indexOf('data:') === 0) {
          e.preventDefault();
          dispatchDownload(href, target.getAttribute('download') || 'download');
        }
      }, true);
    })();
    """

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKDownloadDelegate, WKScriptMessageHandler {
        static let downloadMessageName = "toolboxDownload"

        private let store: WebViewStore
        var currentBaseURL: URL
        private var observations: [NSKeyValueObservation] = []
        private var downloadDestinations: [ObjectIdentifier: URL] = [:]

        init(store: WebViewStore, initialURL: URL) {
            self.store = store
            self.currentBaseURL = initialURL
        }

        deinit {
            observations.forEach { $0.invalidate() }
        }

        func observe(_ webView: WKWebView) {
            observations = [
                webView.observe(\.canGoBack, options: [.initial, .new]) { [weak self] wv, _ in
                    Task { @MainActor in
                        self?.store.canGoBack = wv.canGoBack
                    }
                },
                webView.observe(\.canGoForward, options: [.initial, .new]) { [weak self] wv, _ in
                    Task { @MainActor in
                        self?.store.canGoForward = wv.canGoForward
                    }
                },
                webView.observe(\.isLoading, options: [.initial, .new]) { [weak self] wv, _ in
                    Task { @MainActor in
                        self?.store.isLoading = wv.isLoading
                    }
                },
                webView.observe(\.estimatedProgress, options: [.initial, .new]) { [weak self] wv, _ in
                    Task { @MainActor in
                        self?.store.estimatedProgress = wv.estimatedProgress
                    }
                }
            ]
        }

        @objc func handleRefresh(_ sender: UIRefreshControl) {
            Task { @MainActor in
                store.reload()
            }
        }

        // MARK: - WKScriptMessageHandler (blob/data downloads)

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard message.name == Self.downloadMessageName,
                  let body = message.body as? [String: Any],
                  let base64 = body["base64"] as? String,
                  let data = Data(base64Encoded: base64)
            else { return }

            let rawName = (body["filename"] as? String) ?? "download"
            let safeName = sanitizedFilename(rawName)
            let dest = makeDownloadDestination(filename: safeName)

            do {
                try data.write(to: dest, options: .atomic)
                let byteCount = Int64(data.count)
                Task { @MainActor in
                    store.downloadedFile = DownloadedFileItem(
                        url: dest,
                        filename: safeName,
                        byteCount: byteCount
                    )
                }
            } catch {
                Task { @MainActor in
                    store.downloadErrorMessage = "Could not save download: \(error.localizedDescription)"
                }
            }
        }

        // MARK: - WKNavigationDelegate

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            Task { @MainActor in
                store.loadErrorMessage = nil
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.scrollView.refreshControl?.endRefreshing()
            Task { @MainActor in
                store.loadErrorMessage = nil
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            webView.scrollView.refreshControl?.endRefreshing()
            handleNavigationError(error)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            webView.scrollView.refreshControl?.endRefreshing()
            handleNavigationError(error)
        }

        private func handleNavigationError(_ error: Error) {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                return
            }
            if nsError.domain == "WebKitErrorDomain" && nsError.code == 102 {
                return
            }
            Task { @MainActor in
                store.loadErrorMessage = error.localizedDescription
            }
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            preferences: WKWebpagePreferences,
            decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void
        ) {
            if navigationAction.shouldPerformDownload {
                decisionHandler(.download, preferences)
                return
            }

            guard let url = navigationAction.request.url else {
                decisionHandler(.allow, preferences)
                return
            }

            let scheme = url.scheme?.lowercased() ?? ""
            if scheme == "http" || scheme == "https" || scheme == "about" || scheme == "blob" || scheme == "data" {
                decisionHandler(.allow, preferences)
                return
            }

            UIApplication.shared.open(url)
            decisionHandler(.cancel, preferences)
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationResponse: WKNavigationResponse,
            decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
        ) {
            if !navigationResponse.canShowMIMEType {
                decisionHandler(.download)
                return
            }

            if let httpResponse = navigationResponse.response as? HTTPURLResponse,
               let disposition = httpResponse.value(forHTTPHeaderField: "Content-Disposition")?.lowercased(),
               disposition.contains("attachment")
            {
                decisionHandler(.download)
                return
            }

            decisionHandler(.allow)
        }

        func webView(
            _ webView: WKWebView,
            navigationAction: WKNavigationAction,
            didBecome download: WKDownload
        ) {
            download.delegate = self
        }

        func webView(
            _ webView: WKWebView,
            navigationResponse: WKNavigationResponse,
            didBecome download: WKDownload
        ) {
            download.delegate = self
        }

        // MARK: - WKDownloadDelegate

        func download(
            _ download: WKDownload,
            decideDestinationUsing response: URLResponse,
            suggestedFilename: String,
            completionHandler: @escaping (URL?) -> Void
        ) {
            let safeName = sanitizedFilename(suggestedFilename.isEmpty ? (response.suggestedFilename ?? "download") : suggestedFilename)
            let dest = makeDownloadDestination(filename: safeName)
            downloadDestinations[ObjectIdentifier(download)] = dest
            completionHandler(dest)
        }

        func downloadDidFinish(_ download: WKDownload) {
            guard let dest = downloadDestinations.removeValue(forKey: ObjectIdentifier(download)) else {
                return
            }
            let attrs = try? FileManager.default.attributesOfItem(atPath: dest.path)
            let size = (attrs?[.size] as? NSNumber)?.int64Value ?? 0
            Task { @MainActor in
                store.downloadedFile = DownloadedFileItem(
                    url: dest,
                    filename: dest.lastPathComponent,
                    byteCount: size
                )
            }
        }

        func download(
            _ download: WKDownload,
            didFailWithError error: Error,
            resumeData: Data?
        ) {
            downloadDestinations.removeValue(forKey: ObjectIdentifier(download))
            Task { @MainActor in
                store.downloadErrorMessage = "Download failed: \(error.localizedDescription)"
            }
        }

        // MARK: - WKUIDelegate

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            guard let url = navigationAction.request.url else { return nil }
            let scheme = url.scheme?.lowercased() ?? ""
            if scheme == "http" || scheme == "https" {
                let targetHost = url.host?.lowercased() ?? ""
                let baseHost = currentBaseURL.host?.lowercased() ?? ""
                if !baseHost.isEmpty && (targetHost == baseHost || targetHost.hasSuffix("." + baseHost)) {
                    webView.load(URLRequest(url: url))
                } else {
                    Task { @MainActor in
                        store.openExternalURL(url)
                    }
                }
            } else {
                UIApplication.shared.open(url)
            }
            return nil
        }

        func webView(
            _ webView: WKWebView,
            runJavaScriptAlertPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping () -> Void
        ) {
            guard let presenter = topViewController(from: webView) else {
                completionHandler()
                return
            }
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                completionHandler()
            })
            presenter.present(alert, animated: true)
        }

        func webView(
            _ webView: WKWebView,
            runJavaScriptConfirmPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping (Bool) -> Void
        ) {
            guard let presenter = topViewController(from: webView) else {
                completionHandler(false)
                return
            }
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                completionHandler(false)
            })
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                completionHandler(true)
            })
            presenter.present(alert, animated: true)
        }

        func webView(
            _ webView: WKWebView,
            runJavaScriptTextInputPanelWithPrompt prompt: String,
            defaultText: String?,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping (String?) -> Void
        ) {
            guard let presenter = topViewController(from: webView) else {
                completionHandler(nil)
                return
            }
            let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
            alert.addTextField { field in
                field.text = defaultText
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                completionHandler(nil)
            })
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                completionHandler(alert.textFields?.first?.text)
            })
            presenter.present(alert, animated: true)
        }

        // MARK: - Helpers

        private func topViewController(from webView: WKWebView) -> UIViewController? {
            var current = webView.window?.rootViewController
            while let presented = current?.presentedViewController {
                current = presented
            }
            return current
        }

        private func sanitizedFilename(_ raw: String) -> String {
            let base = (raw as NSString).lastPathComponent.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleaned = base.replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: ":", with: "_")
            return cleaned.isEmpty ? "download.bin" : cleaned
        }

        private func makeDownloadDestination(filename: String) -> URL {
            let dir = FileManager.default.temporaryDirectory
                .appendingPathComponent("ToolboxDownloads", isDirectory: true)
                .appendingPathComponent(UUID().uuidString, isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            return dir.appendingPathComponent(filename)
        }
    }
}
