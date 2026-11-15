import FitFlowDomain

public struct FallbackRecommendationProvider: RecommendationProvider {
  private let remote: any RecommendationProvider
  private let local: any RecommendationProvider

  public init(
    remote: any RecommendationProvider,
    local: any RecommendationProvider = RuleBasedRecommendationProvider()
  ) {
    self.remote = remote
    self.local = local
  }

  public func recommendation(for workouts: [Workout]) async throws -> Recommendation {
    do {
      return try await remote.recommendation(for: workouts)
    } catch {
      var recommendation = try await local.recommendation(for: workouts)
      recommendation.source = .localFallback
      return recommendation
    }
  }
}
