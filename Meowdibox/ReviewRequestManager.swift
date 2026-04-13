import StoreKit
import UIKit

@MainActor
final class ReviewRequestManager {
    static let shared = ReviewRequestManager()

    private let defaults = UserDefaults.standard

    // Ajuste aqui o comportamento do pedido de avaliacao.
    // `minimumLaunchCount`: quantas aberturas do app antes de pedir.
    // `requestDelay`: espera em segundos apos o app ficar ativo.
    private let minimumLaunchCount = 4
    private let requestDelay: TimeInterval = 10

    private let launchCountKey = "review_request_launch_count"
    private let requestedVersionKey = "review_request_last_version"

    private init() {}

    func appDidBecomeActive() {
        let launchCount = defaults.integer(forKey: launchCountKey) + 1
        defaults.set(launchCount, forKey: launchCountKey)

        guard launchCount >= minimumLaunchCount else { return }
        guard defaults.string(forKey: requestedVersionKey) != currentVersion else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + requestDelay) {
            self.requestReviewIfPossible()
        }
    }

    private func requestReviewIfPossible() {
        guard let activeScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
        else {
            return
        }

        AppStore.requestReview(in: activeScene)
        defaults.set(currentVersion, forKey: requestedVersionKey)
    }

    private var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }
}
