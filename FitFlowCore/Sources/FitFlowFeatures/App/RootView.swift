#if os(iOS)
import ComposableArchitecture
import FitFlowDomain
import SwiftUI

@available(iOS 17.0, *)
public struct RootView: View {
    @SwiftUI.Bindable var store: StoreOf<RootFeature>
    @State private var isSettingsPresented = false

    public init(store: StoreOf<RootFeature>) {
        self.store = store
    }

    public var body: some View {
        WithPerceptionTracking {
            NavigationStack {
            Group {
                switch store.selectedTab {
                case .today:
                    TodayFeatureView(
                        store: store.scope(state: \.today, action: \.today),
                        onStartWorkout: { store.send(.startWorkout($0)) },
                        onResumeWorkout: { store.send(.resumeWorkout($0)) }
                    )
                case .history:
                    HistoryFeatureView(store: store.scope(state: \.history, action: \.history))
                case .progress:
                    ProgressFeatureView(store: store.scope(state: \.progress, action: \.progress))
                }
            }
            .background(FitFlowPalette.canvas.ignoresSafeArea())
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(FitFlowPalette.lime)
                            .frame(width: 30, height: 30)
                            .background(FitFlowPalette.teal, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        Text("fitflow")
                            .font(.system(.headline, design: .rounded).weight(.heavy))
                            .tracking(-0.5)
                            .foregroundStyle(FitFlowPalette.primaryText)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("FitFlow")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { isSettingsPresented = true } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(FitFlowPalette.primaryText)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Настройки")
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                FloatingTabBar(selectedTab: store.selectedTab) { tab in
                    withAnimation(.snappy(duration: 0.22)) {
                        _ = store.send(.tabSelected(tab))
                    }
                }
            }
        }
        .tint(FitFlowPalette.teal)
        .sheet(item: $store.scope(state: \.workout, action: \.workout)) { workoutStore in
            ActiveWorkoutView(store: workoutStore)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView(store: store)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}
@available(iOS 17.0, *)
private struct FloatingTabBar: View {
    let selectedTab: AppTab
    let onSelect: (AppTab) -> Void
    @ScaledMetric(relativeTo: .body) private var selectedIconWidth = 34

    var body: some View {
        HStack(spacing: 6) {
            ForEach(AppTab.allCases) { tab in
                let isSelected = selectedTab == tab
                Button { onSelect(tab) } label: {
                    VStack(spacing: 5) {
                        Image(systemName: tab.symbol)
                            .font(.body.weight(isSelected ? .bold : .medium))
                            .frame(minWidth: selectedIconWidth, minHeight: 27)
                            .background {
                                if isSelected {
                                    Capsule().fill(FitFlowPalette.lime)
                                }
                            }
                        Text(tab.title)
                            .font(.caption2.weight(isSelected ? .bold : .medium))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundStyle(isSelected ? FitFlowPalette.brandInk : FitFlowPalette.primaryText.opacity(0.75))
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(tab.title))
                .accessibilityValue(isSelected ? Text("Выбрано") : Text("Не выбрано"))
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                .accessibilityIdentifier("tab.\(tab.rawValue)")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(FitFlowPalette.border.opacity(0.8), lineWidth: 1))
        .shadow(color: FitFlowPalette.brandInk.opacity(0.14), radius: 18, x: 0, y: 7)
        .padding(.horizontal, 22)
        .padding(.top, 7)
        .padding(.bottom, 5)
        .background(.clear)
    }
}

@available(iOS 17.0, *)
private struct SettingsView: View {
    @SwiftUI.Bindable var store: StoreOf<RootFeature>
    @Environment(\.dismiss) private var dismiss
    @AppStorage("fitflow.measurementUnit") private var unit = MeasurementUnit.kilograms.rawValue
    @State private var isDeleteConfirmationPresented = false

    init(store: StoreOf<RootFeature>) {
        self.store = store
    }

    var body: some View {
        WithPerceptionTracking {
            NavigationStack {
                Form {
                Section("Тренировки") {
                    Picker("Единицы веса", selection: $unit) {
                        Text("Килограммы").tag(MeasurementUnit.kilograms.rawValue)
                        Text("Фунты").tag(MeasurementUnit.pounds.rawValue)
                    }
                }
                Section("Рекомендации") {
                    Text(
                        "FitFlow сравнивает твои последние записи и показывает необязательную подсказку. " +
                            "Это не медицинская рекомендация и не замена тренеру."
                    )
                        .font(.subheadline)
                        .foregroundStyle(FitFlowPalette.secondaryText)
                }
                Section {
                    Button(role: .destructive) {
                        isDeleteConfirmationPresented = true
                    } label: {
                        if store.isDeleting {
                            ProgressView()
                        } else {
                            Text("Удалить все локальные данные")
                        }
                    }
                    .disabled(store.isDeleting)
                } footer: {
                    Text("Тренировки хранятся на этом устройстве. Для рекомендации на сервер отправляются только подходы и даты занятий.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(FitFlowPalette.canvas)
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                }
            }
            .confirmationDialog(
                "Удалить все данные?",
                isPresented: $isDeleteConfirmationPresented,
                titleVisibility: .visible
            ) {
                Button("Удалить", role: .destructive) {
                    store.send(.deleteAllTapped)
                }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Это действие нельзя отменить.")
            }
            .alert("Не удалось удалить данные", isPresented: Binding(
                get: { store.deleteError != nil },
                set: { if !$0 { store.send(.deleteErrorDismissed) } }
            )) {
                Button("Понятно", role: .cancel) { store.send(.deleteErrorDismissed) }
            } message: {
                Text(store.deleteError ?? "Попробуй ещё раз.")
            }
            .onChange(of: store.deleteCompleted) { _, completed in
                if completed {
                    dismiss()
                }
            }
            }
        }
    }
}
}
#endif
