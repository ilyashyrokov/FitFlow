#if os(iOS)
  import FitFlowDomain
  import SwiftUI

  @available(iOS 17.0, *)
  struct ExerciseEditorCard: View {
    let item: WorkoutExercise
    let unit: MeasurementUnit
    let onWeightChange: (UUID, String) -> Void
    let onRepetitionsChange: (UUID, String) -> Void
    let onCompletionChange: (UUID, Bool) -> Void
    let onAddSet: () -> Void
    let onRemove: () -> Void

    var body: some View {
      VStack(alignment: .leading, spacing: 12) {
        HStack(alignment: .top) {
          VStack(alignment: .leading, spacing: 4) {
            Text(item.exercise.name)
              .font(.system(.headline, design: .rounded).weight(.bold))
              .foregroundStyle(FitFlowPalette.primaryText)
            Text(item.exercise.category.title)
              .font(.caption)
              .foregroundStyle(FitFlowPalette.secondaryText)
          }
          Spacer()
          Menu {
            Button("Удалить упражнение", role: .destructive, action: onRemove)
          } label: {
            Image(systemName: "ellipsis")
              .font(.system(size: 17, weight: .semibold))
              .foregroundStyle(FitFlowPalette.secondaryText)
              .frame(width: 44, height: 44)
              .contentShape(Rectangle())
          }
          .accessibilityLabel("Действия для упражнения \(item.exercise.name)")
        }
        Text("Прошлый раз  ·  смотришь на свои записи")
          .font(.caption)
          .foregroundStyle(FitFlowPalette.secondaryText)
        HStack(spacing: 8) {
          Text("№").frame(width: 25)
          Text(unit.symbol).frame(maxWidth: .infinity)
          Text("Повторы").frame(maxWidth: .infinity)
          Text("Готово").frame(width: 44)
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(FitFlowPalette.secondaryText)
        ForEach(item.sets.sorted { $0.order < $1.order }) { set in
          HStack(spacing: 8) {
            Text("\(set.order + 1)")
              .font(.caption.weight(.medium))
              .foregroundStyle(FitFlowPalette.secondaryText)
              .frame(width: 25)
            SetValueField(
              value: set.weight.map {
                let displayed = unit == .pounds ? $0 * 2.20462 : $0
                return displayed.formatted(.number.precision(.fractionLength(0...1)))
              } ?? "",
              placeholder: "—",
              label: "Вес, \(unit.symbol)",
              isDecimal: true,
              onChange: { onWeightChange(set.id, $0) }
            )
            SetValueField(
              value: set.repetitions.map(String.init) ?? "",
              placeholder: "—",
              label: "Число повторений",
              isDecimal: false,
              onChange: { onRepetitionsChange(set.id, $0) }
            )
            Button {
              onCompletionChange(set.id, !set.isCompleted)
            } label: {
              Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(
                  set.isCompleted ? FitFlowPalette.teal : FitFlowPalette.secondaryText
                )
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
              set.isCompleted
                ? "Подход \(set.order + 1) выполнен"
                : "Отметить подход \(set.order + 1) выполненным"
            )
            .accessibilityAddTraits(set.isCompleted ? .isSelected : [])
          }
        }
        Button(action: onAddSet) {
          Label("Добавить подход", systemImage: "plus")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(FitFlowPalette.teal)
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
      }
      .padding(15)
      .background(
        FitFlowPalette.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(
          FitFlowPalette.border, lineWidth: 1))
    }
  }
#endif
