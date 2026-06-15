import FitFlowData
import FitFlowDomain
import Foundation
import SwiftData
import Testing

struct SwiftDataWorkoutRepositoryTests {
    @Test
    func saveFetchUpdateAndDeleteRoundTrip() async throws {
        let container = try makeContainer()
        let repository = SwiftDataWorkoutRepository(modelContainer: container)
        let original = sampleWorkout()

        try await repository.save(original)
        #expect(try await repository.fetchWorkouts() == [original])

        var updated = original
        updated.notes = "Хорошее самочувствие"
        try await repository.save(updated)
        #expect(try await repository.fetchWorkouts() == [updated])

        try await repository.delete(id: updated.id)
        #expect(try await repository.fetchWorkouts().isEmpty)
    }

    @Test
    func deleteAllRemovesEveryWorkout() async throws {
        let container = try makeContainer()
        let repository = SwiftDataWorkoutRepository(modelContainer: container)
        try await repository.save(sampleWorkout())
        try await repository.save(sampleWorkout(title: "Низ тела"))

        try await repository.deleteAll()

        #expect(try await repository.fetchWorkouts().isEmpty)
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([WorkoutRecord.self, WorkoutExerciseRecord.self, WorkoutSetRecord.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private func sampleWorkout(title: String = "Верх тела") -> Workout {
        let exercise = Exercise(name: "Жим штанги лёжа", category: .chest)
        return Workout(
            title: title,
            startedAt: .now,
            exercises: [
                WorkoutExercise(
                    exercise: exercise,
                    order: 0,
                    sets: [WorkoutSet(order: 0, weight: 40, repetitions: 8, isCompleted: true)]
                ),
            ]
        )
    }
}
