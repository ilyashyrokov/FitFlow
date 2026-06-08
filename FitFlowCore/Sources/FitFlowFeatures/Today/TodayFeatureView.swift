import ComposableArchitecture
import FitFlowDomain
import SwiftUI

@available(iOS 17.0, *)
public struct TodayFeatureView: View {
    @SwiftUI.Bindable var store: StoreOf<TodayFeature>
    let onStartWorkout: (WorkoutPlan) -> Void
    let onResumeWorkout: (Workout) -> Void

    public init(
        store: StoreOf<TodayFeature>,
        onStartWorkout: @escaping (WorkoutPlan) -> Void,
        onResumeWorkout: @escaping (Workout) -> Void
    ) {
        self.store = store
        self.onStartWorkout = onStartWorkout
        self.onResumeWorkout = onResumeWorkout
    }

    public var body: some View {
        WithPerceptionTracking {
            ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                title
                startCard
                plans
                lastWorkout
                recommendationHint
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(FitFlowPalette.canvas)
        .task { store.send(.task) }
        .refreshable { store.send(.retryTapped) }
        }
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "ru_RU"))))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(FitFlowPalette.secondaryText)
            Text("Хороший день\nдля движения")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .tracking(-1.3)
                .foregroundStyle(FitFlowPalette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
    }

    private var startCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("ТВОЙ РИТМ", systemImage: "circle.fill")
                .font(.caption.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(FitFlowPalette.lime)
            Text("Продолжим\nс того места?")
                .font(.system(size: 27, weight: .bold, design: .rounded))
                .tracking(-0.8)
                .foregroundStyle(.white)
            Text("Прошлые веса уже под рукой. Выбери план и сосредоточься на тренировке.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
            startWorkoutButton
                .padding(.top, 2)
        }
        .padding(21)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 26, style: .continuous).fill(FitFlowPalette.brandInk)
                Circle().stroke(.white.opacity(0.12), lineWidth: 1).frame(width: 190).offset(x: 70, y: 45)
                Circle().stroke(.white.opacity(0.08), lineWidth: 1).frame(width: 230).offset(x: 90, y: 25)
            }
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
    }

    private var startWorkoutButton: some View {
        let activeWorkout = store.workouts.first(where: { $0.status == .inProgress })
        return PrimaryActionButton(
            title: activeWorkout == nil ? "Начать тренировку" : "Продолжить тренировку"
        ) {
            if let activeWorkout {
                    onResumeWorkout(activeWorkout)
            } else {
                onStartWorkout(WorkoutPlan.samples[0])
            }
        }
    }

    private var plans: some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionHeading("Выбери план", detail: "или начни с пустого")
            ForEach(WorkoutPlan.samples) { plan in
                PlanCard(plan: plan) { onStartWorkout(plan) }
            }
            Button {
                onStartWorkout(WorkoutPlan(title: "Своя тренировка", estimatedMinutes: 0, exercises: []))
            } label: {
                Label("Начать пустую тренировку", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(FitFlowPalette.teal)
                    .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var lastWorkout: some View {
        if let workout = store.latestWorkout {
            VStack(alignment: .leading, spacing: 11) {
                SectionHeading("Последняя тренировка", detail: workout.startedAt.formatted(.dateTime.day().month(.abbreviated)))
                HStack(spacing: 13) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(FitFlowPalette.teal)
                        .frame(width: 40, height: 40)
                        .overlay(Circle().stroke(FitFlowPalette.teal.opacity(0.35), lineWidth: 1))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.title).font(.subheadline.weight(.bold)).foregroundStyle(FitFlowPalette.primaryText)
                        Text("\(workout.exercises.count) упражнений · \(workout.completedSetCount) подходов")
                            .font(.caption)
                            .foregroundStyle(FitFlowPalette.secondaryText)
                    }
                    Spacer()
                    VolumeSparkline(workouts: Array(store.workouts.prefix(5)))
                }
                .padding(14)
                .background(FitFlowPalette.softMint.opacity(0.7), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        } else if store.isLoading {
            ProgressView().tint(FitFlowPalette.teal).frame(maxWidth: .infinity).padding(.vertical, 12)
        } else if let error = store.errorMessage {
            ErrorInlineView(message: error) { store.send(.retryTapped) }
        }
    }

    @ViewBuilder
    private var recommendationHint: some View {
        if !store.workouts.isEmpty {
            HStack(alignment: .top, spacing: 11) {
                RoundedRectangle(cornerRadius: 2).fill(FitFlowPalette.orange).frame(width: 3)
                VStack(alignment: .leading, spacing: 5) {
                    Text("МАЛЕНЬКАЯ ПОДСКАЗКА")
                        .font(.caption2.weight(.bold))
                        .tracking(0.6)
                        .foregroundStyle(FitFlowPalette.orange)
                    Text("Открой прогресс, чтобы увидеть рекомендацию по своим последним записям.")
                        .font(.subheadline)
                        .foregroundStyle(FitFlowPalette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(14)
            .background(
                FitFlowPalette.softPeach.opacity(0.55),
                in: UnevenRoundedRectangle(
                    topLeadingRadius: 4,
                    bottomLeadingRadius: 4,
                    bottomTrailingRadius: 15,
                    topTrailingRadius: 15
                )
            )
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

@available(iOS 17.0, *)
private struct VolumeSparkline: View {
    let workouts: [Workout]

    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(Array(workouts.reversed().enumerated()), id: \.offset) { index, workout in
                Capsule()
                    .fill(index == workouts.count - 1 ? FitFlowPalette.teal : FitFlowPalette.teal.opacity(0.45))
                    .frame(width: 4, height: max(9, min(28, CGFloat(workout.volume / 900))))
            }
        }
        .frame(height: 30, alignment: .bottom)
        .accessibilityLabel("График объёма последних тренировок")
    }
}

@available(iOS 17.0, *)
private struct ErrorInlineView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        HStack {
            Text(message).font(.subheadline).foregroundStyle(FitFlowPalette.secondaryText)
            Spacer()
            Button("Повторить", action: retry).font(.subheadline.weight(.semibold))
        }
        .padding(15)
        .background(FitFlowPalette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
