#if os(iOS)
import ComposableArchitecture
import FitFlowDomain
import SwiftUI

@available(iOS 17.0, *)
public struct ActiveWorkoutView: View {
    @SwiftUI.Bindable var store: StoreOf<WorkoutFeature>
    @State private var isAddingExercise = false
    @State private var showDiscardConfirmation = false
    @AppStorage("fitflow.measurementUnit") private var unitRawValue = MeasurementUnit.kilograms.rawValue

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
                                        store.send(.repetitionsChanged(exerciseID: exercise.id, setID: id, text: text))
                                    },
                                    onCompletionChange: { id, done in
                                        store.send(.setCompleted(exerciseID: exercise.id, setID: id, isCompleted: done))
                                    },
                                    onAddSet: { store.send(.addSet(exerciseID: exercise.id)) },
                                    onRemove: { store.send(.removeExercise(exercise.id)) }
                                )
                            }
                            Button { isAddingExercise = true } label: {
                                Label("Добавить упражнение", systemImage: "plus")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(FitFlowPalette.teal)
                                    .frame(maxWidth: .infinity, minHeight: 50)
                                    .background(FitFlowPalette.surface, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
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
            .confirmationDialog("Сохранить незавершённую тренировку?", isPresented: $showDiscardConfirmation) {
                Button("Сохранить черновик и закрыть") { store.send(.dismissTapped) }
                Button("Продолжить тренировку", role: .cancel) { showDiscardConfirmation = false }
            } message: {
                Text("Черновик сохраняется автоматически и будет доступен позже.")
            }
            .alert("Не удалось сохранить", isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.send(.dismissError) } }
            )) {
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
        guard selectedUnit == .pounds, let displayed = Double(text.replacingOccurrences(of: ",", with: ".")) else {
            return text
        }
        return String(displayed / 2.20462)
    }
}
@available(iOS 17.0, *)
private struct ExerciseEditorCard: View {
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
                            .foregroundStyle(set.isCompleted ? FitFlowPalette.teal : FitFlowPalette.secondaryText)
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
        .background(FitFlowPalette.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(FitFlowPalette.border, lineWidth: 1))
    }
}

@available(iOS 17.0, *)
private struct SetValueField: View {
    let value: String
    let placeholder: String
    let label: String
    let isDecimal: Bool
    let onChange: (String) -> Void
    @State private var draft = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(placeholder, text: $draft)
            #if os(iOS)
            .keyboardType(isDecimal ? .decimalPad : .numberPad)
            #endif
            .multilineTextAlignment(.center)
            .font(.subheadline.weight(.bold).monospacedDigit())
            .foregroundStyle(FitFlowPalette.primaryText)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(FitFlowPalette.canvas, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .focused($isFocused)
            .onAppear { draft = value }
            .onChange(of: value) { _, newValue in
                if !isFocused { draft = newValue }
            }
            .onChange(of: draft) { _, newValue in onChange(newValue) }
            .accessibilityLabel(label)
    }
}

@available(iOS 17.0, *)
private struct ExerciseCatalogSheet: View {
    let onSelect: (Exercise) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory?

    private let exercises = [
        Exercise(name: "Жим штанги лёжа", category: .chest),
        Exercise(name: "Жим гантелей на наклонной", category: .chest),
        Exercise(name: "Отжимания", category: .chest),
        Exercise(name: "Тяга горизонтального блока", category: .back),
        Exercise(name: "Тяга верхнего блока", category: .back),
        Exercise(name: "Приседания", category: .legs),
        Exercise(name: "Румынская тяга", category: .legs),
        Exercise(name: "Жим гантелей сидя", category: .shoulders),
        Exercise(name: "Подъём гантелей в стороны", category: .shoulders),
        Exercise(name: "Сгибание рук", category: .arms),
        Exercise(name: "Разгибание рук на блоке", category: .arms),
        Exercise(name: "Планка", category: .core),
    ]

    private var filteredExercises: [Exercise] {
        exercises.filter { exercise in
            (selectedCategory == nil || exercise.category == selectedCategory)
                && (searchText.isEmpty || exercise.name.localizedCaseInsensitiveContains(searchText))
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredExercises) { exercise in
                Button {
                    onSelect(exercise)
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exercise.name).foregroundStyle(FitFlowPalette.primaryText)
                            Text(exercise.category.title).font(.caption).foregroundStyle(FitFlowPalette.secondaryText)
                        }
                        Spacer()
                        Image(systemName: "plus.circle.fill").foregroundStyle(FitFlowPalette.teal)
                    }
                    .padding(.vertical, 3)
                }
                .listRowBackground(FitFlowPalette.surface)
            }
            .scrollContentBackground(.hidden)
            .background(FitFlowPalette.canvas)
            .navigationTitle("Упражнения")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Найти упражнение")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        categoryChip(nil, title: "Все")
                        ForEach(ExerciseCategory.allCases) { category in
                            categoryChip(category, title: category.title)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .background(.ultraThinMaterial)
            }
        }
    }

    private func categoryChip(_ category: ExerciseCategory?, title: String) -> some View {
        let isSelected = selectedCategory == category
        return Button(title) { selectedCategory = category }
            .font(.caption.weight(.semibold))
            .foregroundStyle(isSelected ? FitFlowPalette.brandInk : FitFlowPalette.primaryText)
            .padding(.horizontal, 12)
            .frame(minHeight: 38)
            .background(isSelected ? FitFlowPalette.lime : FitFlowPalette.surface, in: Capsule())
            .overlay(Capsule().stroke(FitFlowPalette.border, lineWidth: isSelected ? 0 : 1))
    }
}

@available(iOS 17.0, *)
private struct WorkoutSummaryView: View {
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
                    MetricTile(value: workout.volume.formatted(.number.precision(.fractionLength(0))), title: "кг × повторы")
                }
                VStack(alignment: .leading, spacing: 9) {
                    Text("Как прошло занятие?")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(FitFlowPalette.primaryText)
                    TextField("Добавь заметку по самочувствию (по желанию)", text: Binding(
                        get: { workout.notes ?? "" },
                        set: onNotesChange
                    ), axis: .vertical)
                    .lineLimit(2...5)
                    .font(.subheadline)
                    .padding(13)
                    .background(FitFlowPalette.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(FitFlowPalette.border, lineWidth: 1))
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
