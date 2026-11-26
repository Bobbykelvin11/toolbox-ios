import SwiftUI

struct InfoCardsView: View {
    @State private var safariItem: SafariItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    smartTubeCard
                    wan2gpCard
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Desktop & TV Tools")
            .sheet(item: $safariItem) { item in
                SafariView(url: item.url)
                    .ignoresSafeArea()
            }
        }
    }

    private var smartTubeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "tv.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.red.gradient, in: RoundedRectangle(cornerRadius: 13))

                VStack(alignment: .leading, spacing: 3) {
                    Text("SmartTube")
                        .font(.title3.bold())
                    Text("Android TV Only • Not Available on iOS")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                }
            }

            Text("SmartTube (yuliskov/SmartTube) is an Android APK built specifically for Android TV, Google TV, and Fire TV devices. Because Android apps and TV Leanback UIs cannot run on iPhone, it is not bundled here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Open-Source iOS Alternative: Yattee")
                    .font(.subheadline.weight(.semibold))
                Text("Yattee is an open-source (AGPL-3.0), privacy-focused video player for iOS, iPadOS, tvOS, and macOS with SponsorBlock and self-hosted Invidious / Piped / Yattee Server support.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

            VStack(spacing: 8) {
                linkButton(
                    title: "Get Yattee on App Store",
                    systemImage: "arrow.down.app",
                    urlString: ToolDefaults.yatteeAppStoreURL,
                    prominent: true
                )
                linkButton(
                    title: "Yattee on GitHub (yattee/yattee)",
                    systemImage: "chevron.left.forwardslash.chevron.right",
                    urlString: ToolDefaults.yatteeRepoURL
                )
                linkButton(
                    title: "SmartTube on GitHub (yuliskov/SmartTube)",
                    systemImage: "tv",
                    urlString: ToolDefaults.smartTubeRepoURL
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var wan2gpCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "cpu.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.indigo.gradient, in: RoundedRectangle(cornerRadius: 13))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Wan2GP (WanGP)")
                        .font(.title3.bold())
                    Text("Desktop GPU Required • Cannot Run on iPhone")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.indigo)
                }
            }

            Text("Wan2GP (deepbeepmeep/Wan2GP) runs large open-source AI video, image, and audio generation models (Wan 2.1/2.2, LTX Video, Hunyuan Video, Flux, Qwen Image). Even with its low-VRAM optimizations, it requires a desktop NVIDIA GPU (GTX 10XX / RTX 20XX+ with 4–8+ GB VRAM) or supported desktop AMD RDNA GPU with PyTorch.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("iPhone hardware does not support desktop CUDA/PyTorch video generation models locally. To use Wan2GP on a computer or cloud GPU, install it from the GitHub repository below.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

            linkButton(
                title: "Wan2GP on GitHub (deepbeepmeep/Wan2GP)",
                systemImage: "chevron.left.forwardslash.chevron.right",
                urlString: ToolDefaults.wan2gpRepoURL,
                prominent: true
            )
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func linkButton(
        title: String,
        systemImage: String,
        urlString: String,
        prominent: Bool = false
    ) -> some View {
        if prominent {
            Button {
                openURL(urlString)
            } label: {
                Label(title, systemImage: systemImage)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        } else {
            Button {
                openURL(urlString)
            } label: {
                HStack {
                    Label(title, systemImage: systemImage)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)
        }
    }

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        if url.host?.contains("apps.apple.com") == true {
            UIApplication.shared.open(url)
        } else {
            safariItem = SafariItem(url: url)
        }
    }
}
