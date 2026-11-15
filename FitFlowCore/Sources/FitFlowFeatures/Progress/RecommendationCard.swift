import FitFlowDomain
import SwiftUI

#if os(iOS)
  import UIKit
#endif

@available(iOS 17.0, *)
struct RecommendationCard: View {
  @Environment(\.openURL) private var openURL
  @State private var isConnectionHelpPresented = false

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
        if recommendation.source == .localFallback {
          Button {
            isConnectionHelpPresented = true
          } label: {
            Label("Python-сервер не подключён · Подробнее", systemImage: "wifi.exclamationmark")
              .font(.caption.weight(.semibold))
              .foregroundStyle(FitFlowPalette.lime)
              .fixedSize(horizontal: false, vertical: true)
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("recommendation.localFallbackHelp")
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
      .background(
        FitFlowPalette.brandInk, in: RoundedRectangle(cornerRadius: 22, style: .continuous)
      )
      .alert("Python-сервер недоступен", isPresented: $isConnectionHelpPresented) {
        Button("Открыть настройки iPhone", action: openAppSettings)
        Button("Понятно", role: .cancel) {}
      } message: {
        Text(
          "FitFlow продолжит показывать подсказки на устройстве, но прогноз Python недоступен. "
            + "Проверь, что сервер запущен. Если доступ к локальной сети запрещён, включи его в "
            + "Настройки → Конфиденциальность и безопасность → Локальная сеть → FitFlow. "
            + "На iPhone укажи IP-адрес Mac вместо 127.0.0.1."
        )
      }
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
      .background(
        FitFlowPalette.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
  }

  private func openAppSettings() {
    #if os(iOS)
      guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
      openURL(settingsURL)
    #endif
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
