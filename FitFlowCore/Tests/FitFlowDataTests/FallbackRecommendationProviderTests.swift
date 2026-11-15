import FitFlowData
import FitFlowDomain
import Testing

struct FallbackRecommendationProviderTests {
  @Test
  func usesLocalPolicyWhenRemoteProviderFails() async throws {
    let provider = FallbackRecommendationProvider(remote: UnavailableRecommendationProvider())

    let recommendation = try await provider.recommendation(for: [])

    #expect(recommendation.title == "Продолжай записывать")
    #expect(recommendation.source == .localFallback)
  }
}

private struct UnavailableRecommendationProvider: RecommendationProvider {
  func recommendation(for workouts: [Workout]) async throws -> Recommendation {
    throw TestFailure.unavailable
  }

  private enum TestFailure: Error {
    case unavailable
  }
}
