#if os(iOS)
  import ComposableArchitecture
  import FitFlowDomain
  import SwiftUI

  @available(iOS 17.0, *)
  public struct ActiveWorkoutView: View {
    @SwiftUI.Bindable var store: StoreOf<WorkoutFeature>
    @State private var isAddingExercise = false
    @State private var showDiscardConfirmation = false
    @AppStorage("fitflow.measurementUnit") private var unitRawValue = MeasurementUnit.kilograms
      .rawValue

    public init(store: StoreOf<WorkoutFeature>) {
      self.store = store
    }

    public var body: some View {
      WithPerceptionTracking {
        NavigationStack {
          Group {
            if store.isFinished {
              WorkoutSummaryView(workout: store.workout) { store.send(.notesChanged($0)) }
            } else {
              ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                  workoutMeta
                  ForEach(store.workout.exercises.sorted { $0.order < $1.order }) { exercise in
                    ExerciseEditorCard(
                      item: exercise,
                      unit: selectedUnit,
                      onWeightChange: { id, text in
                        store.send(
                          .weightChanged(
                            exerciseID: exercise.id,
                            setID: id,
                            text: storedWeight(from: text)
                          )
                        )
                      },
                      onRepetitionsChange: { id, text in
                        store.send(
                          .repetitionsChanged(exerciseID: exercise.id, setID: id, text: text))
                      },
                      onCompletionChange: { id, done in
                        store.send(
                          .setCompleted(exerciseID: exercise.id, setID: id, isCompleted: done))
                      },
                      onAddSet: { store.send(.addSet(exerciseID: exercise.id)) },
                      onRemove: { store.send(.removeExercise(exercise.id)) }
                    )
                  }
                  Button {
                    isAddingExercise = true
                  } label: {
                    Label("Добавить упражнение", systemImage: "plus")
                      .font(.subheadline.weight(.bold))
                      .foregroundStyle(FitFlowPalette.teal)
                      .frame(maxWidth: .infinity, minHeight: 50)
                      .background(
                        FitFlowPalette.surface,
                        in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                      )
                      .overlay(
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                          .strokeBorder(
                            FitFlowPalette.teal.opacity(0.5),
                            style: StrokeStyle(lineWidth: 1, dash: [5, 4])
                          )
                      )
                  }
                  .buttonStyle(.plain)
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 26)
              }
            }
          }
          .background(FitFlowPalette.canvas)
          .task { store.send(.task) }
          .navigationTitle(store.isFinished ? "Тренировка завершена" : store.workout.title)
          .navigationBarTitleDisplayMode(.inline)
          .toolbarBackground(.hidden, for: .navigationBar)
          .toolbar {
            ToolbarItem(placement: .topBarLeading) {
              Button(store.isFinished ? "Готово" : "Закрыть") {
                if store.isFinished {
                  store.send(.dismissTapped)
                } else {
                  showDiscardConfirmation = true
                }
              }
              .foregroundStyle(FitFlowPalette.teal)
            }
            ToolbarItem(placement: .topBarTrailing) {
              if !store.isFinished {
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                  Label(elapsedTime, systemImage: "timer")
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(FitFlowPalette.teal)
                    .accessibilityLabel("Длительность тренировки \(elapsedTime)")
                }
              }
            }
          }
          .safeAreaInset(edge: .bottom, spacing: 0) {
            finishBar
          }
          .sheet(isPresented: $isAddingExercise) {
            ExerciseCatalogSheet { exercise in
              store.send(.addExercise(exercise))
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
          }
          .confirmationDialog(
            "Сохранить незавершённую тренировку?", isPresented: $showDiscardConfirmation
          ) {
            Button("Сохранить черновик и закрыть") { store.send(.dismissTapped) }
            Button("Продолжить тренировку", role: .cancel) { showDiscardConfirmation = false }
          } message: {
            Text("Черновик сохраняется автоматически и будет доступен позже.")
          }
          .alert(
            "Не удалось сохранить",
            isPresented: Binding(
              get: { store.errorMessage != nil },
              set: { if !$0 { store.send(.dismissError) } }
            )
          ) {
            Button("Понятно", role: .cancel) { store.send(.dismissError) }
          } message: {
            Text(store.errorMessage ?? "Попробуй ещё раз.")
          }
        }
      }
    }

    private var workoutMeta: some View {
      HStack {
        Label("Сохраняется на этом iPhone", systemImage: "iphone.and.arrow.forward")
          .font(.caption)
          .foregroundStyle(FitFlowPalette.secondaryText)
        Spacer()
        Text("\(store.workout.completedSetCount) / \(store.workout.setCount) подходов")
          .font(.caption.weight(.semibold))
          .foregroundStyle(FitFlowPalette.teal)
      }
      .padding(.vertical, 2)
    }

    private var finishBar: some View {
      VStack(spacing: 0) {
        if store.isFinished {
          Button("На главный экран") { store.send(.dismissTapped) }
            .font(.subheadline.weight(.bold))
            .foregroundStyle(FitFlowPalette.brandInk)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(FitFlowPalette.lime, in: Capsule())
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 8)
        } else {
          PrimaryActionButton(
            title: store.isSaving ? "Сохраняем…" : "Завершить тренировку",
            symbol: "checkmark"
          ) {
            store.send(.finishTapped)
          }
          .disabled(store.isSaving)
          .opacity(store.isSaving ? 0.7 : 1)
          .padding(.horizontal, 18)
          .padding(.top, 12)
          .padding(.bottom, 8)
        }
      }
      .background(.ultraThinMaterial)
    }

    private var elapsedTime: String {
      let seconds = max(0, Int(Date.now.timeIntervalSince(store.workout.startedAt)))
      return "\(seconds / 60):\(String(format: "%02d", seconds % 60))"
    }

    private var selectedUnit: MeasurementUnit {
      MeasurementUnit(rawValue: unitRawValue) ?? .kilograms
    }

    private func storedWeight(from text: String) -> String {
      guard selectedUnit == .pounds,
        let displayed = Double(text.replacingOccurrences(of: ",", with: "."))
      else {
        return text
      }
      return String(displayed / 2.20462)
    }
  }
#endif
