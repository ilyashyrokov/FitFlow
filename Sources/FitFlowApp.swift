import ComposableArchitecture
import FitFlowData
import FitFlowDomain
import FitFlowFeatures
import Foundation
import SwiftData
import SwiftUI

@main
@MainActor
struct FitFlowApp: App {
    var body: some Scene {
        WindowGroup {
            AppBootstrapView()
        }
    }
}

@MainActor
private final class AppRuntime {
    let modelContainer: ModelContainer
    let repository: SwiftDataWorkoutRepository
    let store: StoreOf<RootFeature>

    init() throws {
        let schema = Schema([
            WorkoutRecord.self,
            WorkoutExerciseRecord.self,
            WorkoutSetRecord.self,
        ])
        let container = try ModelContainer(for: schema)
        let repository = SwiftDataWorkoutRepository(modelContainer: container)
        let recommendationProvider = Self.makeRecommendationProvider()

        self.modelContainer = container
        self.repository = repository
        self.store = withDependencies {
            $0.workoutRepository = repository
            $0.recommendationProvider = recommendationProvider
        } operation: {
            Store(initialState: RootFeature.State()) {
                RootFeature()
            }
        }
    }

    private static func makeRecommendationProvider() -> any RecommendationProvider {
        let baseURL = Bundle.main.object(forInfoDictionaryKey: "RecommendationAPIBaseURL") as? String
        guard let baseURL,
              !baseURL.isEmpty,
              let url = URL(string: baseURL),
              url.scheme != nil
        else {
            return RuleBasedRecommendationProvider()
        }
        return FallbackRecommendationProvider(remote: RecommendationAPIClient(baseURL: url))
    }
}

@MainActor
private struct AppBootstrapView: View {
    private enum Phase {
        case loading
        case ready(AppRuntime)
        case failed(String)
    }

    @State private var phase: Phase = .loading

    var body: some View {
        Group {
            switch phase {
            case .loading:
                ProgressView("Подготовка локального хранилища…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(FitFlowPalette.canvas)
            case let .ready(runtime):
                RootView(store: runtime.store)
                    .modelContainer(runtime.modelContainer)
            case let .failed(message):
                DatabaseRecoveryView(message: message, onRetry: start)
            }
        }
        .task {
            if case .loading = phase {
                start()
            }
        }
    }

    private func start() {
        phase = .loading
        do {
            phase = .ready(try AppRuntime())
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }
}

@available(iOS 17.0, *)
private struct DatabaseRecoveryView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Не удалось открыть данные", systemImage: "externaldrive.badge.exclamationmark")
        } description: {
            Text("Твои данные не были удалены. Попробуй открыть локальное хранилище ещё раз.")
        } actions: {
            Button("Повторить", action: onRetry)
                .buttonStyle(.borderedProminent)
            DisclosureGroup("Технические подробности") {
                Text(message)
                    .font(.caption)
                    .textSelection(.enabled)
            }
        }
        .padding()
        .background(FitFlowPalette.canvas)
    }
}
