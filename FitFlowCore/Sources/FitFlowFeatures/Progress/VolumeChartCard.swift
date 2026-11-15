import Charts
import SwiftUI

@available(iOS 17.0, *)
struct VolumeChartCard: View {
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
    .overlay(
      RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(
        FitFlowPalette.border, lineWidth: 1))
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
