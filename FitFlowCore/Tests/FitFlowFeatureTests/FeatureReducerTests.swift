import ComposableArchitecture
import FitFlowDomain
import FitFlowFeatures
import Foundation
import Testing

@MainActor
struct FeatureReducerTests {
    @Test
    func rootTabSelectionUpdatesState() async {
        let store = TestStore(initialState: RootFeature.State()) {
            RootFeature()
        }

        await store.send(.tabSelected(.progress)) {
            $0.selectedTab = .progress
        }
        await store.send(.tabSelected(.history)) {
            $0.selectedTab = .history
        }
    }

    @Test
    func workoutRejectsInvalidValuesAndSavesValidDraftChanges() async throws {
        let workout = WorkoutPlan.samples[0].makeWorkout(at: Date(timeIntervalSince1970: 1_000))
        let firstExercise = workout.exercises[0]
        let firstSet = firstExercise.sets[0]
        let repository = InMemoryWorkoutRepository()
        let store = TestStore(initialState: WorkoutFeature.State(workout: workout)) {
            WorkoutFeature()
        } withDependencies: {
            $0.workoutRepository = repository
        }

        await store.send(.weightChanged(exerciseID: firstExercise.id, setID: firstSet.id, text: "-5"))
        await store.send(.repetitionsChanged(exerciseID: firstExercise.id, setID: firstSet.id, text: "0"))
        await store.send(.weightChanged(exerciseID: firstExercise.id, setID: firstSet.id, text: "40")) {
            $0.workout.exercises[0].sets[0].weight = 40
        }
        await store.receive(.draftSaved)
        await store.send(.setCompleted(exerciseID: firstExercise.id, setID: firstSet.id, isCompleted: true)) {
            $0.workout.exercises[0].sets[0].isCompleted = true
        }
        await store.receive(.draftSaved)
        #expect(try await repository.fetchWorkouts().first?.completedSetCount == 1)
    }

    @Test
    func finishingRequiresAtLeastOneCompletedSet() async {
        let workout = WorkoutPlan.samples[0].makeWorkout()
        let store = TestStore(initialState: WorkoutFeature.State(workout: workout)) {
            WorkoutFeature()
        }

        await store.send(.finishTapped) {
            $0.errorMessage = "Отметь выполненный подход перед завершением."
        }
        await store.send(.dismissError) {
            $0.errorMessage = nil
        }
    }

    @Test
    func completedWorkoutIsSavedAndMarkedFinished() async throws {
        var workout = WorkoutPlan.samples[0].makeWorkout(at: Date(timeIntervalSince1970: 1_000))
        workout.exercises[0].sets[0].weight = 40
        workout.exercises[0].sets[0].repetitions = 8
        workout.exercises[0].sets[0].isCompleted = true
        let repository = InMemoryWorkoutRepository()
        let store = TestStore(initialState: WorkoutFeature.State(workout: workout)) {
            WorkoutFeature()
        } withDependencies: {
            $0.workoutRepository = repository
            $0.date.now = Date(timeIntervalSince1970: 2_000)
        }

        await store.send(.finishTapped) {
            $0.isSaving = true
            $0.workout.status = .completed
            $0.workout.completedAt = Date(timeIntervalSince1970: 2_000)
        }
        await store.receive(.finishSucceeded) {
            $0.isSaving = false
            $0.isFinished = true
        }
        #expect(try await repository.fetchWorkouts().first?.status == .completed)
    }

    @Test
    func progressBuildsStableMetricsWhenWorkoutsLoad() async {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let recent = completedWorkout(startedAt: now.addingTimeInterval(-86_400), weight: 40, repetitions: 8)
        let older = completedWorkout(startedAt: now.addingTimeInterval(-10 * 86_400), weight: 30, repetitions: 10)
        var initialState = ProgressFeature.State()
        initialState.recommendation = Recommendation(
            title: "Тест",
            message: "Тест",
            reason: "Тест",
            basedOnWorkoutCount: 0
        )
        var expectedMetrics = ProgressFeature.State()
        expectedMetrics.workouts = [recent, older]
        expectedMetrics.updateMetrics(now: now)
        let store = TestStore(initialState: initialState) {
            ProgressFeature()
        } withDependencies: {
            $0.date.now = now
        }

        await store.send(.workoutsLoaded([recent, older])) {
            $0.workouts = [recent, older]
            $0.completedWorkouts = [recent, older]
            $0.weeklyWorkoutCount = 1
            $0.totalVolume = 620
            $0.weeklyVolumes = expectedMetrics.weeklyVolumes
            $0.isLoading = false
        }
    }

    @Test
    func progressSurfacesRecommendationFailureWithoutLosingWorkouts() async {
        let workout = completedWorkout(startedAt: .now, weight: 20, repetitions: 5)
        var initialState = ProgressFeature.State()
        initialState.workouts = [workout]
        let store = TestStore(initialState: initialState) {
            ProgressFeature()
        } withDependencies: {
            $0.recommendationProvider = FailingRecommendationProvider()
        }

        await store.send(.refreshRecommendationTapped) {
            $0.isRefreshingRecommendation = true
        }
        await store.receive(\.recommendationFailed) {
            $0.isRefreshingRecommendation = false
            $0.recommendationError = TestFailure.unavailable.localizedDescription
        }
        #expect(store.state.workouts == [workout])
    }

    @Test
    func todayRestoresAndSortsAnInProgressDraft() async {
        let oldDraft = Workout(title: "Старая", startedAt: Date(timeIntervalSince1970: 100))
        let newestDraft = Workout(title: "Новая", startedAt: Date(timeIntervalSince1970: 300))
        let store = TestStore(initialState: TodayFeature.State()) {
            TodayFeature()
        }

        await store.send(.workoutsLoaded([oldDraft, newestDraft])) {
            $0.workouts = [newestDraft, oldDraft]
            $0.isLoading = false
        }
        #expect(store.state.workouts.first?.id == newestDraft.id)
    }

    private func completedWorkout(startedAt: Date, weight: Double, repetitions: Int) -> Workout {
        var workout = WorkoutPlan.samples[0].makeWorkout(at: startedAt)
        workout.status = .completed
        workout.completedAt = startedAt.addingTimeInterval(1_800)
        workout.exercises[0].sets[0].weight = weight
        workout.exercises[0].sets[0].repetitions = repetitions
        workout.exercises[0].sets[0].isCompleted = true
        return workout
    }
}

private struct FailingRecommendationProvider: RecommendationProvider {
    func recommendation(for workouts: [Workout]) async throws -> Recommendation {
        throw TestFailure.unavailable
    }
}

private enum TestFailure: Error {
    case unavailable
}
