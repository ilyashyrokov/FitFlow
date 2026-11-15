import ComposableArchitecture
import SwiftUI

@available(iOS 17.0, *)
public struct ProgressFeatureView: View {
  @SwiftUI.Bindable var store: StoreOf<ProgressFeature>

  public init(store: StoreOf<ProgressFeature>) {
    self.store = store
  }

  public var body: some View {
    WithPerceptionTracking {
      ScrollView {
        VStack(alignment: .leading, spacing: 18) {
          ProgressHeader()
          ProgressContent(
            isLoading: store.isLoading,
            completedWorkoutsAreEmpty: store.completedWorkouts.isEmpty,
            weeklyWorkoutCount: store.weeklyWorkoutCount,
            totalVolume: store.totalVolume,
            weeklyVolumes: store.weeklyVolumes,
            recommendation: store.recommendation,
            recommendationError: store.recommendationError,
            isRefreshingRecommendation: store.isRefreshingRecommendation,
            onRefreshRecommendation: { store.send(.refreshRecommendationTapped) }
          )
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 24)
      }
      .background(FitFlowPalette.canvas)
      .task { store.send(.task) }
      .refreshable { store.send(.retryTapped) }
    }
  }
}
