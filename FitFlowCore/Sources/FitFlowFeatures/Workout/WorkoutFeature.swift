import ComposableArchitecture
import FitFlowDomain
import Foundation

@Reducer
public struct WorkoutFeature {
    @ObservableState
    public struct State: Equatable {
        public var workout: Workout
        public var isSaving = false
        public var isFinished = false
        public var errorMessage: String?

        public init(workout: Workout) {
            self.workout = workout
        }
    }

    public enum Action: Equatable {
        case task
        case weightChanged(exerciseID: UUID, setID: UUID, text: String)
        case repetitionsChanged(exerciseID: UUID, setID: UUID, text: String)
        case setCompleted(exerciseID: UUID, setID: UUID, isCompleted: Bool)
        case addSet(exerciseID: UUID)
        case addExercise(Exercise)
        case removeExercise(UUID)
        case notesChanged(String)
        case finishTapped
        case dismissTapped
        case draftSaved
        case finishSucceeded
        case saveFailed(String)
        case dismissError
    }

    private enum CancelID {
        case draftSave
    }

    @Dependency(\.workoutRepository) var repository
    @Dependency(\.date.now) var now

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return saveDraft(state.workout)

            case let .weightChanged(exerciseID, setID, text):
                let normalized = text.replacingOccurrences(of: ",", with: ".")
                guard !normalized.isEmpty else {
                    updateSet(state: &state, exerciseID: exerciseID, setID: setID) { $0.weight = nil }
                    return saveDraft(state.workout)
                }
                guard let value = Double(normalized), value >= 0 else { return .none }
                updateSet(state: &state, exerciseID: exerciseID, setID: setID) { $0.weight = value }
                return saveDraft(state.workout)

            case let .repetitionsChanged(exerciseID, setID, text):
                guard !text.isEmpty else {
                    updateSet(state: &state, exerciseID: exerciseID, setID: setID) { $0.repetitions = nil }
                    return saveDraft(state.workout)
                }
                guard let value = Int(text), value > 0 else { return .none }
                updateSet(state: &state, exerciseID: exerciseID, setID: setID) { $0.repetitions = value }
                return saveDraft(state.workout)

            case let .setCompleted(exerciseID, setID, isCompleted):
                updateSet(state: &state, exerciseID: exerciseID, setID: setID) {
                    $0.isCompleted = isCompleted
                }
                return saveDraft(state.workout)

            case let .addSet(exerciseID):
                guard let index = state.workout.exercises.firstIndex(where: { $0.id == exerciseID }) else {
                    return .none
                }
                let order = state.workout.exercises[index].sets.count
                state.workout.exercises[index].sets.append(WorkoutSet(order: order))
                return saveDraft(state.workout)

            case let .addExercise(exercise):
                let order = state.workout.exercises.count
                let item = WorkoutExercise(
                    exercise: exercise,
                    order: order,
                    sets: (0..<3).map { WorkoutSet(order: $0) }
                )
                state.workout.exercises.append(item)
                return saveDraft(state.workout)

            case let .removeExercise(id):
                state.workout.exercises.removeAll { $0.id == id }
                for index in state.workout.exercises.indices {
                    state.workout.exercises[index].order = index
                }
                return saveDraft(state.workout)

            case let .notesChanged(notes):
                state.workout.notes = notes.isEmpty ? nil : notes
                return saveDraft(state.workout)

            case .finishTapped:
                guard !state.workout.exercises.isEmpty else {
                    state.errorMessage = "Добавь хотя бы одно упражнение, чтобы завершить тренировку."
                    return .none
                }
                guard state.workout.completedSetCount > 0 else {
                    state.errorMessage = "Отметь выполненный подход перед завершением."
                    return .none
                }
                state.isSaving = true
                state.workout.completedAt = now
                state.workout.status = .completed
                let repository = self.repository
                let workout = state.workout
                return .concatenate(
                    .cancel(id: CancelID.draftSave),
                    .run { send in
                        do {
                            try await repository.save(workout)
                            await send(.finishSucceeded)
                        } catch {
                            await send(.saveFailed(error.localizedDescription))
                        }
                    }
                )

            case .draftSaved:
                state.isSaving = false
                return .none

            case .finishSucceeded:
                state.isSaving = false
                state.isFinished = true
                return .none

            case let .saveFailed(message):
                state.isSaving = false
                state.errorMessage = "Не удалось сохранить тренировку. \\(message)"
                return .none

            case .dismissError:
                state.errorMessage = nil
                return .none

            case .dismissTapped:
                return .none
            }
        }
    }

    private func saveDraft(_ workout: Workout) -> Effect<Action> {
        let repository = self.repository
        return .run { send in
            do {
                try await repository.save(workout)
                await send(.draftSaved)
            } catch {
                await send(.saveFailed(error.localizedDescription))
            }
        }
        .cancellable(id: CancelID.draftSave, cancelInFlight: true)
    }

    private func updateSet(
        state: inout State,
        exerciseID: UUID,
        setID: UUID,
        update: (inout WorkoutSet) -> Void
    ) {
        guard let exerciseIndex = state.workout.exercises.firstIndex(where: { $0.id == exerciseID }),
              let setIndex = state.workout.exercises[exerciseIndex].sets.firstIndex(where: { $0.id == setID })
        else { return }
        update(&state.workout.exercises[exerciseIndex].sets[setIndex])
    }
}
