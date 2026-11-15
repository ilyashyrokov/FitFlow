import Foundation

public struct WorkoutPlan: Codable, Equatable, Identifiable, Sendable {
  public let id: UUID
  public var title: String
  public var estimatedMinutes: Int
  public var exercises: [Exercise]

  public init(id: UUID = UUID(), title: String, estimatedMinutes: Int, exercises: [Exercise]) {
    self.id = id
    self.title = title
    self.estimatedMinutes = estimatedMinutes
    self.exercises = exercises
  }

  public func makeWorkout(at date: Date = .now) -> Workout {
    Workout(
      title: title,
      startedAt: date,
      exercises: exercises.enumerated().map { index, exercise in
        WorkoutExercise(
          exercise: exercise,
          order: index,
          sets: (0..<3).map { setIndex in WorkoutSet(order: setIndex) }
        )
      }
    )
  }

  public static let samples: [WorkoutPlan] = [
    WorkoutPlan(
      title: "Верх тела",
      estimatedMinutes: 45,
      exercises: [
        Exercise(name: "Жим штанги лёжа", category: .chest),
        Exercise(name: "Тяга горизонтального блока", category: .back),
        Exercise(name: "Жим гантелей сидя", category: .shoulders),
        Exercise(name: "Сгибание рук", category: .arms),
      ]
    ),
    WorkoutPlan(
      title: "Низ тела",
      estimatedMinutes: 40,
      exercises: [
        Exercise(name: "Приседания", category: .legs),
        Exercise(name: "Румынская тяга", category: .legs),
        Exercise(name: "Выпады", category: .legs),
      ]
    ),
    WorkoutPlan(
      title: "Полное тело",
      estimatedMinutes: 40,
      exercises: [
        Exercise(name: "Приседания", category: .legs),
        Exercise(name: "Жим штанги лёжа", category: .chest),
        Exercise(name: "Тяга горизонтального блока", category: .back),
      ]
    ),
  ]
}
