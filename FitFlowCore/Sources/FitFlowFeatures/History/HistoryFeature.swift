import ComposableArchitecture
import FitFlowDomain
import Foundation

@Reducer
public struct HistoryFeature {
    @ObservableState
    public struct State: Equatable {
        public var workouts: [Workout] = []
        public var isLoading = false
        public var errorMessage: String?
        public var workoutToDelete: Workout?

        public init() {}
    }

    public enum Action: Equatable {
        case task
        case workoutsLoaded([Workout])
        case loadFailed(String)
        case deleteRequested(Workout)
        case deleteConfirmed
        case deleteCancelled
        case workoutDeleted(UUID)
        case retryTapped
    }

    @Dependency(\.workoutRepository) var repository

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task, .retryTapped:
                state.isLoading = true
                state.errorMessage = nil
                let repository = self.repository
                return .run { send in
                    do {
                        await send(.workoutsLoaded(try await repository.fetchWorkouts()))
                    } catch {
                        await send(.loadFailed(error.localizedDescription))
                    }
                }

            case let .workoutsLoaded(workouts):
                state.workouts = workouts.filter { $0.status == .completed }
                    .sorted { $0.startedAt > $1.startedAt }
                state.isLoading = false
                return .none

            case let .loadFailed(message):
                state.isLoading = false
                state.errorMessage = message
                return .none

            case let .deleteRequested(workout):
                state.workoutToDelete = workout
                return .none

            case .deleteConfirmed:
                guard let workout = state.workoutToDelete else { return .none }
                state.workoutToDelete = nil
                let repository = self.repository
                return .run { send in
                    do {
                        try await repository.delete(id: workout.id)
                        await send(.workoutDeleted(workout.id))
                    } catch {
                        await send(.loadFailed(error.localizedDescription))
                    }
                }

            case .deleteCancelled:
                state.workoutToDelete = nil
                return .none

            case let .workoutDeleted(id):
                state.workouts.removeAll { $0.id == id }
                return .none
            }
        }
    }
}
