import FitFlowDomain
import Foundation
import SwiftData

@ModelActor
@available(iOS 17.0, *)
public actor SwiftDataWorkoutRepository: WorkoutRepository {
    public func fetchWorkouts() async throws -> [Workout] {
        let descriptor = FetchDescriptor<WorkoutRecord>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { $0.domainModel() }
    }

    public func save(_ workout: Workout) async throws {
        let id = workout.id
        let descriptor = FetchDescriptor<WorkoutRecord>(
            predicate: #Predicate { $0.id == id }
        )
        if let existing = try modelContext.fetch(descriptor).first {
            modelContext.delete(existing)
        }
        modelContext.insert(WorkoutRecord(workout: workout))
        try modelContext.save()
    }

    public func delete(id: UUID) async throws {
        let descriptor = FetchDescriptor<WorkoutRecord>(
            predicate: #Predicate { $0.id == id }
        )
        if let existing = try modelContext.fetch(descriptor).first {
            modelContext.delete(existing)
            try modelContext.save()
        }
    }

    public func deleteAll() async throws {
        try modelContext.delete(model: WorkoutRecord.self)
        try modelContext.save()
    }
}
