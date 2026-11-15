import FitFlowDomain
import SwiftUI

@available(iOS 17.0, *)
struct ProgressHeader: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      Text("Твои записи")
        .font(.subheadline)
        .foregroundStyle(FitFlowPalette.secondaryText)
      Text("Прогресс")
        .font(.system(.largeTitle, design: .rounded).weight(.bold))
        .foregroundStyle(FitFlowPalette.primaryText)
    }
    .accessibilityElement(children: .combine)
  }
}

@available(iOS 17.0, *)
struct ProgressContent: View {
  let isLoading: Bool
  let completedWorkoutsAreEmpty: Bool
  let weeklyWorkoutCount: Int
  let totalVolume: Double
  let weeklyVolumes: [ProgressFeature.WeeklyVolume]
  let recommendation: Recommendation?
  let recommendationError: String?
  let isRefreshingRecommendation: Bool
  let onRefreshRecommendation: () -> Void

  var body: some View {
    if isLoading && completedWorkoutsAreEmpty {
      ProgressView()
        .tint(FitFlowPalette.teal)
        .frame(maxWidth: .infinity)
        .padding(.top, 50)
        .accessibilityLabel("Загрузка прогресса")
    } else if completedWorkoutsAreEmpty {
      EmptyStateView(
        title: "Сначала нужны записи",
        message:
          "После нескольких тренировок здесь появятся объём, регулярность и первая объяснимая подсказка.",
        symbol: "chart.xyaxis.line"
      )
    } else {
      ProgressDashboard(
        weeklyWorkoutCount: weeklyWorkoutCount,
        totalVolume: totalVolume,
        weeklyVolumes: weeklyVolumes,
        recommendation: recommendation,
        recommendationError: recommendationError,
        isRefreshingRecommendation: isRefreshingRecommendation,
        onRefreshRecommendation: onRefreshRecommendation
      )
    }
  }
}

@available(iOS 17.0, *)
private struct ProgressDashboard: View {
  let weeklyWorkoutCount: Int
  let totalVolume: Double
  let weeklyVolumes: [ProgressFeature.WeeklyVolume]
  let recommendation: Recommendation?
  let recommendationError: String?
  let isRefreshingRecommendation: Bool
  let onRefreshRecommendation: () -> Void

  var body: some View {
    Group {
      ViewThatFits(in: .horizontal) {
        HStack(spacing: 10) { metricTiles }
        VStack(spacing: 10) { metricTiles }
      }
      VolumeChartCard(weeklyVolumes: weeklyVolumes)
      RecommendationCard(
        recommendation: recommendation,
        error: recommendationError,
        isRefreshing: isRefreshingRecommendation,
        onRefresh: onRefreshRecommendation
      )
      Text("Объём — вспомогательная метрика. Он не оценивает качество тренировки.")
        .font(.caption)
        .foregroundStyle(FitFlowPalette.secondaryText)
        .padding(.horizontal, 2)
    }
  }

  @ViewBuilder
  private var metricTiles: some View {
    MetricTile(value: "\(weeklyWorkoutCount)", title: "тренировок за 7 дней")
    MetricTile(
      value: totalVolume.formatted(.number.precision(.fractionLength(0))),
      title: "объём записей, кг × повторы"
    )
  }
}
