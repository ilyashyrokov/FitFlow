import ComposableArchitecture
import FitFlowDomain
import Foundation

@Reducer
public struct ProgressFeature {
  @ObservableState
  public struct State: Equatable {
    public var workouts: [Workout] = []
    public var completedWorkouts: [Workout] = []
    public var weeklyVolumes: [WeeklyVolume] = []
    public var weeklyWorkoutCount = 0
    public var totalVolume: Double = 0
    public var recommendation: Recommendation?
    public var isLoading = false
    public var isRefreshingRecommendation = false
    public var errorMessage: String?
    public var recommendationError: String?
    public var loadRequestID: UUID?
    public var recommendationRequestID: UUID?

    public init() {}

    public mutating func updateMetrics(now: Date, calendar: Calendar = .current) {
      completedWorkouts = workouts.filter { $0.status == .completed }
      let start = calendar.date(byAdding: .day, value: -6, to: now) ?? .distantPast
      weeklyWorkoutCount = completedWorkouts.filter { $0.startedAt >= start }.count
      totalVolume = completedWorkouts.reduce(0) { $0 + $1.volume }

      let grouped = Dictionary(grouping: completedWorkouts) { workout in
        calendar.dateInterval(of: .weekOfYear, for: workout.startedAt)?.start ?? workout.startedAt
      }
      weeklyVolumes = grouped.map { week, workouts in
        WeeklyVolume(week: week, volume: workouts.reduce(0) { $0 + $1.volume })
      }
      .sorted { $0.week < $1.week }
    }
  }

  public struct WeeklyVolume: Equatable, Identifiable, Sendable {
    public let week: Date
    public let volume: Double

    public var id: Date { week }

    public init(week: Date, volume: Double) {
      self.week = week
      self.volume = volume
    }
  }

  public enum Action: Equatable {
    case task
    case workoutsLoaded([Workout])
    case loadWorkoutsResponse(id: UUID, workouts: [Workout])
    case loadFailed(String)
    case loadFailedResponse(id: UUID, message: String)
    case refreshRecommendationTapped
    case recommendationLoaded(Recommendation)
    case recommendationLoadedResponse(id: UUID, recommendation: Recommendation)
    case recommendationFailed(String)
    case recommendationFailedResponse(id: UUID, message: String)
    case retryTapped
  }

  private enum CancelID {
    case load
    case recommendation
  }

  @Dependency(\.workoutRepository) var repository
  @Dependency(\.recommendationProvider) var recommendationProvider
  @Dependency(\.date.now) var now
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
        state.workouts = workouts
        state.updateMetrics(now: now)
        state.isLoading = false
        return state.recommendation == nil ? .send(.refreshRecommendationTapped) : .none

      case .loadWorkoutsResponse(let id, let workouts):
        guard id == state.loadRequestID else { return .none }
        state.workouts = workouts
        state.updateMetrics(now: now)
        state.isLoading = false
        return .send(.refreshRecommendationTapped)

      case .loadFailed(let message):
        state.isLoading = false
        state.errorMessage = message
        return .none

      case .loadFailedResponse(let id, let message):
        guard id == state.loadRequestID else { return .none }
        state.isLoading = false
        state.errorMessage = message
        return .none

      case .refreshRecommendationTapped:
        let id = uuid()
        state.recommendationRequestID = id
        state.isRefreshingRecommendation = true
        state.recommendationError = nil
        let provider = self.recommendationProvider
        let workouts = state.workouts
        return .run { send in
          do {
            await send(
              .recommendationLoadedResponse(
                id: id,
                recommendation: try await provider.recommendation(for: workouts)
              ))
          } catch {
            await send(.recommendationFailedResponse(id: id, message: error.localizedDescription))
          }
        }
        .cancellable(id: CancelID.recommendation, cancelInFlight: true)

      case .recommendationLoaded(let recommendation):
        state.recommendation = recommendation
        state.isRefreshingRecommendation = false
        return .none

      case .recommendationLoadedResponse(let id, let recommendation):
        guard id == state.recommendationRequestID else { return .none }
        state.recommendation = recommendation
        state.isRefreshingRecommendation = false
        return .none

      case .recommendationFailed(let message):
        state.isRefreshingRecommendation = false
        state.recommendationError = message
        return .none

      case .recommendationFailedResponse(let id, let message):
        guard id == state.recommendationRequestID else { return .none }
        state.isRefreshingRecommendation = false
        state.recommendationError = message
        return .none
      }
    }
  }
}
