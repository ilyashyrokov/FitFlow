import ComposableArchitecture
import FitFlowDomain

@Reducer
public struct RootFeature {
    @ObservableState
    public struct State: Equatable {
        public var selectedTab: AppTab = .today
        public var today = TodayFeature.State()
        public var history = HistoryFeature.State()
        public var progress = ProgressFeature.State()
        @Presents public var workout: WorkoutFeature.State?
        public var isDeleting = false
        public var deleteError: String?
        public var deleteCompleted = false

        public init() {}
    }

    public enum Action: Equatable {
        case tabSelected(AppTab)
        case startWorkout(WorkoutPlan)
        case resumeWorkout(Workout)
        case today(TodayFeature.Action)
        case history(HistoryFeature.Action)
        case progress(ProgressFeature.Action)
        case workout(PresentationAction<WorkoutFeature.Action>)
        case dismissWorkout
        case deleteAllTapped
        case deleteAllSucceeded
        case deleteAllFailed(String)
        case deleteErrorDismissed
    }

    @Dependency(\.workoutRepository) var repository

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.today, action: \.today) { TodayFeature() }
        Scope(state: \.history, action: \.history) { HistoryFeature() }
        Scope(state: \.progress, action: \.progress) { ProgressFeature() }
        Reduce { state, action in
            switch action {
            case let .tabSelected(tab):
                state.selectedTab = tab
                return .none
            case let .startWorkout(plan):
                state.workout = WorkoutFeature.State(workout: plan.makeWorkout())
                return .none
            case .workout(.presented(.finishSucceeded)):
                return .merge(
                    .send(.today(.task)),
                    .send(.history(.task)),
                    .send(.progress(.task))
                )
            case .workout(.presented(.dismissTapped)):
                state.workout = nil
                return .none
            case let .resumeWorkout(workout):
                state.workout = WorkoutFeature.State(workout: workout)
                return .none
            case .dismissWorkout:
                state.workout = nil
                return .none
            case .deleteAllTapped:
                state.isDeleting = true
                state.deleteError = nil
                state.deleteCompleted = false
                let repository = self.repository
                return .run { send in
                    do {
                        try await repository.deleteAll()
                        await send(.deleteAllSucceeded)
                    } catch {
                        await send(.deleteAllFailed(error.localizedDescription))
                    }
                }
            case .deleteAllSucceeded:
                state.isDeleting = false
                state.deleteCompleted = true
                state.today = TodayFeature.State()
                state.history = HistoryFeature.State()
                state.progress = ProgressFeature.State()
                state.workout = nil
                return .none
            case let .deleteAllFailed(message):
                state.isDeleting = false
                state.deleteError = message
                return .none
            case .deleteErrorDismissed:
                state.deleteError = nil
                return .none
            case .workout, .today, .history, .progress:
                return .none
            }
        }
        .ifLet(\.$workout, action: \.workout) { WorkoutFeature() }
    }
}
