import Combine
import Foundation
import SwiftUI

enum ToolDefaults {
    static let stirlingPDFURL = "https://stirling.com/app/"
    static let stirlingRepoURL = "https://github.com/Stirling-Tools/Stirling-PDF"
    static let openCutURL = "https://opencut.app/projects"
    static let openCutHomeURL = "https://opencut.app"
    static let openCutRepoURL = "https://github.com/OpenCut-app/OpenCut"
    static let n8nHomeURL = "https://n8n.io"
    static let n8nDocsURL = "https://docs.n8n.io/hosting/"
    static let n8nRepoURL = "https://github.com/n8n-io/n8n"
    static let smartTubeRepoURL = "https://github.com/yuliskov/SmartTube"
    static let yatteeRepoURL = "https://github.com/yattee/yattee"
    static let yatteeAppStoreURL = "https://apps.apple.com/us/app/yattee/id1595136629"
    static let wan2gpRepoURL = "https://github.com/deepbeepmeep/Wan2GP"
}

@MainActor
final class ToolSettings: ObservableObject {
    @AppStorage("stirlingPDFURL") var stirlingPDFURL: String = ToolDefaults.stirlingPDFURL
    @AppStorage("openCutURL") var openCutURL: String = ToolDefaults.openCutURL
    @AppStorage("n8nURL") var n8nURL: String = ""

    var effectiveStirlingURL: URL {
        Self.normalizedURL(from: stirlingPDFURL) ?? URL(string: ToolDefaults.stirlingPDFURL)!
    }

    var effectiveOpenCutURL: URL {
        Self.normalizedURL(from: openCutURL) ?? URL(string: ToolDefaults.openCutURL)!
    }

    var effectiveN8nURL: URL? {
        Self.normalizedURL(from: n8nURL)
    }

    func resetStirlingURL() {
        stirlingPDFURL = ToolDefaults.stirlingPDFURL
    }

    func resetOpenCutURL() {
        openCutURL = ToolDefaults.openCutURL
    }

    func clearN8nURL() {
        n8nURL = ""
    }

    static func normalizedURL(from raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let candidateString: String
        if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
            candidateString = trimmed
        } else {
            let lower = trimmed.lowercased()
            let isLocal = lower.hasPrefix("localhost")
                || lower.hasPrefix("127.")
                || lower.hasPrefix("192.168.")
                || lower.hasPrefix("10.")
                || lower.contains(".local")
                || lower.contains(":")
            candidateString = (isLocal ? "http://" : "https://") + trimmed
        }

        guard let url = URL(string: candidateString),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = url.host,
              !host.isEmpty
        else {
            return nil
        }
        return url
    }
}
