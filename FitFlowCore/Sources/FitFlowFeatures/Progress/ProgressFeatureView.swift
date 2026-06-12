import Charts
import ComposableArchitecture
import FitFlowDomain
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

@available(iOS 17.0, *)
private struct ProgressHeader: View {
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
private struct ProgressContent: View {
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
                message: "После нескольких тренировок здесь появятся объём, регулярность и первая объяснимая подсказка.",
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

@available(iOS 17.0, *)
private struct VolumeChartCard: View {
    let weeklyVolumes: [ProgressFeature.WeeklyVolume]

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            ViewThatFits(in: .horizontal) {
                HStack {
                    chartTitle
                    Spacer()
                    chartUnit
                }
                VStack(alignment: .leading, spacing: 4) {
                    chartTitle
                    chartUnit
                }
            }
            if weeklyVolumes.isEmpty {
                Text("Добавь завершённые подходы, чтобы увидеть динамику.")
                    .font(.subheadline)
                    .foregroundStyle(FitFlowPalette.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                Chart(weeklyVolumes) { item in
                    BarMark(
                        x: .value("Неделя", item.week, unit: .weekOfYear),
                        y: .value("Объём", item.volume)
                    )
                    .foregroundStyle(FitFlowPalette.teal.gradient)
                    .cornerRadius(6)
                }
                .chartYAxis(.hidden)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                            .foregroundStyle(FitFlowPalette.secondaryText)
                    }
                }
                .frame(minHeight: 150)
                .accessibilityLabel("Объём завершённых тренировок по неделям")
            }
        }
        .padding(16)
        .background(FitFlowPalette.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(FitFlowPalette.border, lineWidth: 1))
    }

    private var chartTitle: some View {
        Text("Записанный объём")
            .font(.system(.headline, design: .rounded).weight(.bold))
            .foregroundStyle(FitFlowPalette.primaryText)
    }

    private var chartUnit: some View {
        Text("кг × повторы")
            .font(.caption)
            .foregroundStyle(FitFlowPalette.secondaryText)
    }
}

@available(iOS 17.0, *)
private struct RecommendationCard: View {
    let recommendation: Recommendation?
    let error: String?
    let isRefreshing: Bool
    let onRefresh: () -> Void

    var body: some View {
        if let recommendation {
            VStack(alignment: .leading, spacing: 10) {
                Label("ПО ДАННЫМ ТВОИХ ЗАПИСЕЙ", systemImage: "sparkle")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(FitFlowPalette.lime)
                Text(recommendation.title)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                Text(recommendation.message)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.82))
                if let forecast = recommendation.forecast {
                    forecastCard(forecast)
                }
                Label(
                    "\(recommendation.reason) Подсказка необязательна и не заменяет совет тренера или врача.",
                    systemImage: "info.circle"
                )
                .font(.caption)
                .foregroundStyle(.white.opacity(0.68))
                refreshButton
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FitFlowPalette.brandInk, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        } else if let error {
            VStack(alignment: .leading, spacing: 10) {
                Text("Подсказка пока недоступна")
                    .font(.headline)
                    .foregroundStyle(FitFlowPalette.primaryText)
                Text("Записи сохранены на устройстве. Проверь подключение и попробуй ещё раз.")
                    .font(.subheadline)
                    .foregroundStyle(FitFlowPalette.secondaryText)
                Text(error)
                    .font(.caption)
                    .foregroundStyle(FitFlowPalette.secondaryText)
                Button("Повторить", action: onRefresh)
                    .buttonStyle(.borderedProminent)
                    .tint(FitFlowPalette.teal)
            }
            .padding(16)
            .background(FitFlowPalette.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var refreshButton: some View {
        Button(action: onRefresh) {
            HStack(spacing: 8) {
                if isRefreshing { ProgressView().tint(FitFlowPalette.brandInk) }
                Text("Обновить подсказку")
            }
            .font(.subheadline.weight(.bold))
            .foregroundStyle(FitFlowPalette.brandInk)
            .frame(minHeight: 44)
            .padding(.horizontal, 13)
            .background(FitFlowPalette.lime, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isRefreshing)
    }

    private func forecastCard(_ forecast: TrainingForecast) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label("ЭКСПЕРИМЕНТАЛЬНЫЙ ML-ПРОГНОЗ", systemImage: "chart.line.uptrend.xyaxis")
                .font(.caption2.weight(.bold))
                .tracking(0.3)
                .foregroundStyle(FitFlowPalette.lime)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                let estimate = forecast.estimatedOneRepMax
                    .formatted(.number.precision(.fractionLength(1)))
                Text("≈ \(estimate) \(forecast.unit)")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                let change = forecast.changePercent.formatted(.number.precision(.fractionLength(1)))
                Text("\(forecast.changePercent >= 0 ? "+" : "")\(change)%")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(FitFlowPalette.lime)
            }
            Text(
                "Оценка на следующее занятие по \(forecast.sessionsUsed) записям. "
                    + "Это ориентир, не рекомендация по весу."
            )
                .font(.caption)
                .foregroundStyle(.white.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
    }
}
