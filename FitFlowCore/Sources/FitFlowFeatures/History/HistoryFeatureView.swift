#if os(iOS)
import ComposableArchitecture
import FitFlowDomain
import SwiftUI

@available(iOS 17.0, *)
public struct HistoryFeatureView: View {
    @SwiftUI.Bindable var store: StoreOf<HistoryFeature>
    @State private var selectedWorkout: Workout?

    public init(store: StoreOf<HistoryFeature>) {
        self.store = store
    }

    public var body: some View {
        WithPerceptionTracking {
            ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Всё, что ты записал")
                        .font(.subheadline)
                        .foregroundStyle(FitFlowPalette.secondaryText)
                    Text("История")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .tracking(-1.2)
                        .foregroundStyle(FitFlowPalette.primaryText)
                }
                if store.isLoading && store.workouts.isEmpty {
                    ProgressView().tint(FitFlowPalette.teal).frame(maxWidth: .infinity).padding(.top, 50)
                } else if let error = store.errorMessage, store.workouts.isEmpty {
                    EmptyStateView(title: "Не удалось открыть историю", message: error, symbol: "wifi.exclamationmark")
                    Button("Повторить") { store.send(.retryTapped) }
                        .buttonStyle(.borderedProminent)
                        .tint(FitFlowPalette.teal)
                } else if store.workouts.isEmpty {
                    EmptyStateView(
                        title: "Здесь появятся тренировки",
                        message: "Сохрани первое занятие — и мы будем хранить его историю прямо на устройстве.",
                        symbol: "book.closed"
                    )
                } else {
                    ForEach(groupedMonths, id: \.key) { month, workouts in
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeading(month, detail: "\(workouts.count) тренировок")
                            ForEach(workouts) { workout in
                                Button { selectedWorkout = workout } label: {
                                    historyRow(workout)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        store.send(.deleteRequested(workout))
                                    } label: {
                                        Label("Удалить тренировку", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .background(FitFlowPalette.canvas)
        .task { store.send(.task) }
        .refreshable { store.send(.retryTapped) }
        .confirmationDialog(
            "Удалить тренировку?",
            isPresented: Binding(
                get: { store.workoutToDelete != nil },
                set: { if !$0 { store.send(.deleteCancelled) } }
            ),
            presenting: store.workoutToDelete
        ) { workout in
            Button("Удалить «\(workout.title)»", role: .destructive) { store.send(.deleteConfirmed) }
            Button("Отмена", role: .cancel) { store.send(.deleteCancelled) }
        } message: { _ in
            Text("Запись будет удалена с этого устройства.")
        }
        .sheet(item: $selectedWorkout) { workout in
            WorkoutDetailSheet(workout: workout)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        }
    }

    private var groupedMonths: [(key: String, value: [Workout])] {
        let grouped = Dictionary(grouping: store.workouts) {
            $0.startedAt.formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "ru_RU")))
        }
        return grouped.keys.sorted { keyA, keyB in
            (grouped[keyA]?.first?.startedAt ?? .distantPast) > (grouped[keyB]?.first?.startedAt ?? .distantPast)
        }.compactMap { key in grouped[key].map { (key: key, value: $0) } }
    }

    private func historyRow(_ workout: Workout) -> some View {
        HStack(spacing: 13) {
            VStack(spacing: 2) {
                Text(workout.startedAt.formatted(.dateTime.day()))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Text(workout.startedAt.formatted(.dateTime.month(.abbreviated).locale(Locale(identifier: "ru_RU"))))
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(FitFlowPalette.teal)
            .frame(width: 44, height: 48)
            .background(FitFlowPalette.softMint, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            VStack(alignment: .leading, spacing: 5) {
                Text(workout.title).font(.subheadline.weight(.bold)).foregroundStyle(FitFlowPalette.primaryText)
                Text("\(workout.exercises.count) упражнений · \(duration(for: workout))")
                    .font(.caption)
                    .foregroundStyle(FitFlowPalette.secondaryText)
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 3) {
                Text(workout.volume.formatted(.number.precision(.fractionLength(0))))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(FitFlowPalette.primaryText)
                Text("кг × повторы").font(.system(size: 9)).foregroundStyle(FitFlowPalette.secondaryText)
            }
        }
        .padding(13)
        .background(FitFlowPalette.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(FitFlowPalette.border, lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func duration(for workout: Workout) -> String {
        guard let completedAt = workout.completedAt else { return "не завершена" }
        let minutes = max(1, Int(completedAt.timeIntervalSince(workout.startedAt) / 60))
        return "\(minutes) мин"
    }
}
@available(iOS 17.0, *)
private struct WorkoutDetailSheet: View {
    let workout: Workout
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Дата", value: workout.startedAt.formatted(date: .long, time: .shortened))
                    LabeledContent("Подходы", value: "\(workout.completedSetCount)")
                    LabeledContent("Объём", value: "\(workout.volume.formatted(.number.precision(.fractionLength(0)))) кг × повторы")
                }
                ForEach(workout.exercises.sorted { $0.order < $1.order }) { exercise in
                    Section(exercise.exercise.name) {
                        ForEach(exercise.sets.sorted { $0.order < $1.order }) { set in
                            HStack {
                                Text("Подход \(set.order + 1)")
                                Spacer()
                                Text("\(set.weightText) кг × \(set.repetitions.map(String.init) ?? "—")")
                                    .foregroundStyle(FitFlowPalette.secondaryText)
                                if set.isCompleted { Image(systemName: "checkmark.circle.fill").foregroundStyle(FitFlowPalette.teal) }
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(FitFlowPalette.canvas)
            .navigationTitle(workout.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }
}

private extension WorkoutSet {
    var weightText: String {
        weight?.formatted(.number.precision(.fractionLength(0...1))) ?? "—"
    }
}
#endif
