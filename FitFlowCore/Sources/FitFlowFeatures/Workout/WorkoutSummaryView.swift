#if os(iOS)
  import FitFlowDomain
  import SwiftUI

  @available(iOS 17.0, *)
  struct WorkoutSummaryView: View {
    let workout: Workout
    let onNotesChange: @MainActor @Sendable (String) -> Void

    var body: some View {
      ScrollView {
        VStack(spacing: 18) {
          Image(systemName: "checkmark")
            .font(.system(size: 26, weight: .bold))
            .foregroundStyle(FitFlowPalette.lime)
            .frame(width: 72, height: 72)
            .background(FitFlowPalette.brandInk, in: Circle())
            .padding(.top, 20)
          VStack(spacing: 6) {
            Text("Тренировка сохранена")
              .font(.system(.title2, design: .rounded).weight(.bold))
              .foregroundStyle(FitFlowPalette.primaryText)
            Text(workout.completedAt?.formatted(date: .complete, time: .shortened) ?? "Сегодня")
              .font(.subheadline)
              .foregroundStyle(FitFlowPalette.secondaryText)
          }
          HStack(spacing: 10) {
            MetricTile(value: "\(workout.exercises.count)", title: "упражнений")
            MetricTile(value: "\(workout.completedSetCount)", title: "подходов")
          }
          HStack(spacing: 10) {
            MetricTile(value: duration, title: "время")
            MetricTile(
              value: workout.volume.formatted(.number.precision(.fractionLength(0))),
              title: "кг × повторы")
          }
          VStack(alignment: .leading, spacing: 9) {
            Text("Как прошло занятие?")
              .font(.system(.headline, design: .rounded).weight(.bold))
              .foregroundStyle(FitFlowPalette.primaryText)
            TextField(
              "Добавь заметку по самочувствию (по желанию)",
              text: Binding(
                get: { workout.notes ?? "" },
                set: onNotesChange
              ), axis: .vertical
            )
            .lineLimit(2...5)
            .font(.subheadline)
            .padding(13)
            .background(
              FitFlowPalette.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
              RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(
                FitFlowPalette.border, lineWidth: 1)
            )
            .accessibilityLabel("Заметка о самочувствии")
          }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 22)
      }
      .background(FitFlowPalette.canvas)
    }

    private var duration: String {
      guard let completedAt = workout.completedAt else { return "—" }
      let minutes = max(1, Int(completedAt.timeIntervalSince(workout.startedAt) / 60))
      return "\(minutes) мин"
    }
  }
#endif
