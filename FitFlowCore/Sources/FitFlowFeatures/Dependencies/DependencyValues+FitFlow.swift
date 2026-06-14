import ComposableArchitecture
import FitFlowDomain

private enum WorkoutRepositoryKey: DependencyKey {
    static let liveValue: any WorkoutRepository = InMemoryWorkoutRepository()
    static let testValue: any WorkoutRepository = InMemoryWorkoutRepository()
}

private enum RecommendationProviderKey: DependencyKey {
    static let liveValue: any RecommendationProvider = RuleBasedRecommendationProvider()
    static let testValue: any RecommendationProvider = RuleBasedRecommendationProvider()
}

public extension DependencyValues {
    var workoutRepository: any WorkoutRepository {
        get { self[WorkoutRepositoryKey.self] }
        set { self[WorkoutRepositoryKey.self] = newValue }
    }

    var recommendationProvider: any RecommendationProvider {
        get { self[RecommendationProviderKey.self] }
        set { self[RecommendationProviderKey.self] = newValue }
    }
}
