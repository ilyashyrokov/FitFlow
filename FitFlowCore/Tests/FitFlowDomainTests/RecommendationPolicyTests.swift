import FitFlowDomain
import Foundation
import Testing

struct RecommendationPolicyTests {
    private let policy = RecommendationPolicy()
    private let exerciseID = UUID()

    @Test
    func insufficientHistoryAsksForMoreRecords() {
        let result = policy.recommendation(from: [workout(daysAgo: 0, reps: [8, 8])])

        #expect(result.title == "Продолжай записывать")
        #expect(result.basedOnWorkoutCount == 1)
        #expect(result.exerciseID == nil)
    }

    @Test
    func stableHistoryRecommendsKeepingTheLoad() {
        let result = policy.recommendation(from: [
            workout(daysAgo: 0, reps: [8, 8], weight: 40),
            workout(daysAgo: 7, reps: [8, 8], weight: 40),
        ])

        #expect(result.title == "Сохрани текущий вес")
        #expect(result.basedOnWorkoutCount == 2)
        #expect(result.exerciseID == exerciseID)
    }

    @Test
    func progressWithHigherLoadAndStableRepsIsDescribedWithoutAnOrder() {
        let result = policy.recommendation(from: [
            workout(daysAgo: 0, reps: [8, 8], weight: 42.5),
            workout(daysAgo: 7, reps: [8, 8], weight: 40),
        ])

        #expect(result.title == "Нагрузка постепенно растёт")
        #expect(result.confidence == .moderate)
        #expect(result.message.contains("Продолжай ориентироваться на самочувствие"))
    }

    @Test
    func fewerRepsRecommendsRepeatingLoad() {
        let result = policy.recommendation(from: [
            workout(daysAgo: 0, reps: [6, 7], weight: 40),
            workout(daysAgo: 7, reps: [8, 8], weight: 40),
        ])

        #expect(result.title == "Оставь вес прежним")
        #expect(result.message.contains("посмотреть по ощущениям"))
    }

    @Test
    func incompleteSetsDoNotCreateFalseProgress() {
        let result = policy.recommendation(from: [
            workout(daysAgo: 0, reps: [8, 8], weight: 40, completed: false),
            workout(daysAgo: 7, reps: [8, 8], weight: 40),
        ])

        #expect(result.title == "Повтори комфортную нагрузку")
    }

    private func workout(
        daysAgo: Int,
        reps: [Int],
        weight: Double = 40,
        completed: Bool = true
    ) -> Workout {
        let sets = reps.enumerated().map { index, count in
            WorkoutSet(order: index, weight: weight, repetitions: count, isCompleted: completed)
        }
        let exercise = Exercise(id: exerciseID, name: "Жим штанги лёжа", category: .chest)
        return Workout(
            title: "Верх тела",
            startedAt: Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now)!,
            completedAt: .now,
            status: .completed,
            exercises: [WorkoutExercise(exercise: exercise, order: 0, sets: sets)]
        )
    }
}
