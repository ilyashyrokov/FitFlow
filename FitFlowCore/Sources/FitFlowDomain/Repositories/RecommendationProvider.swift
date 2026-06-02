import Foundation

public protocol RecommendationProvider: Sendable {
    func recommendation(for workouts: [Workout]) async throws -> Recommendation
}

public struct RuleBasedRecommendationProvider: RecommendationProvider {
    private let policy: RecommendationPolicy

    public init(policy: RecommendationPolicy = RecommendationPolicy()) {
        self.policy = policy
    }

    public func recommendation(for workouts: [Workout]) async throws -> Recommendation {
        policy.recommendation(from: workouts)
    }
}
