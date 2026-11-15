import ComposableArchitecture
import FitFlowDomain
import Foundation

@Reducer
public struct TodayFeature {
  @ObservableState
  public struct State: Equatable {
    public var workouts: [Workout] = []
    public var isLoading = false
    public var errorMessage: String?
    public var loadRequestID: UUID?

    public init() {}

    public var latestWorkout: Workout? {
      workouts.first(where: { $0.status == .completed })
    }
  }

  public enum Action: Equatable {
    case task
    case workoutsLoaded([Workout])
    case loadWorkoutsResponse(id: UUID, workouts: [Workout])
    case loadFailed(String)
    case loadFailedResponse(id: UUID, message: String)
    case retryTapped
  }

  private enum CancelID {
    case load
  }

  @Dependency(\.workoutRepository) var repository
  @Dependency(\.uuid) var uuid

  public init() {}

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .task, .retryTapped:
        let id = uuid()
        state.loadRequestID = id
        state.isLoading = true
        state.errorMessage = nil
        let repository = self.repository
        return .run { send in
          do {
            await send(
              .loadWorkoutsResponse(id: id, workouts: try await repository.fetchWorkouts()))
          } catch {
            await send(.loadFailedResponse(id: id, message: error.localizedDescription))
          }
        }
        .cancellable(id: CancelID.load, cancelInFlight: true)

      case .workoutsLoaded(let workouts):
        state.workouts = workouts.sorted { $0.startedAt > $1.startedAt }
        state.isLoading = false
        return .none

      case .loadWorkoutsResponse(let id, let workouts):
        guard id == state.loadRequestID else { return .none }
        state.workouts = workouts.sorted { $0.startedAt > $1.startedAt }
        state.isLoading = false
        return .none

      case .loadFailed(let message):
        state.isLoading = false
        state.errorMessage = message
        return .none

      case .loadFailedResponse(let id, let message):
        guard id == state.loadRequestID else { return .none }
        state.isLoading = false
        state.errorMessage = message
        return .none
      }
    }
  }
}
