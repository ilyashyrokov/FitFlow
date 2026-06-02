import Foundation

public protocol WorkoutRepository: Sendable {
    func fetchWorkouts() async throws -> [Workout]
    func save(_ workout: Workout) async throws
    func delete(id: UUID) async throws
    func deleteAll() async throws
}

public actor InMemoryWorkoutRepository: WorkoutRepository {
    private var storage: [UUID: Workout]

    public init(workouts: [Workout] = []) {
        storage = Dictionary(uniqueKeysWithValues: workouts.map { ($0.id, $0) })
    }

    public func fetchWorkouts() async throws -> [Workout] {
        storage.values.sorted { $0.startedAt > $1.startedAt }
    }

    public func save(_ workout: Workout) async throws {
        storage[workout.id] = workout
    }

    public func delete(id: UUID) async throws {
        storage[id] = nil
    }

    public func deleteAll() async throws {
        storage.removeAll()
    }
}
