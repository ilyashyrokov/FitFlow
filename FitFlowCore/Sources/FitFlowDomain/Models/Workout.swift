import Foundation

public struct WorkoutSet: Codable, Equatable, Identifiable, Sendable {
  public let id: UUID
  public var order: Int
  public var weight: Double?
  public var repetitions: Int?
  public var isCompleted: Bool

  public init(
    id: UUID = UUID(),
    order: Int,
    weight: Double? = nil,
    repetitions: Int? = nil,
    isCompleted: Bool = false
  ) {
    self.id = id
    self.order = order
    self.weight = weight
    self.repetitions = repetitions
    self.isCompleted = isCompleted
  }

  public var volume: Double {
    guard isCompleted, let weight, let repetitions else { return 0 }
    return weight * Double(repetitions)
  }
}

public struct WorkoutExercise: Codable, Equatable, Identifiable, Sendable {
  public let id: UUID
  public var exercise: Exercise
  public var order: Int
  public var sets: [WorkoutSet]

  public init(
    id: UUID = UUID(),
    exercise: Exercise,
    order: Int,
    sets: [WorkoutSet] = []
  ) {
    self.id = id
    self.exercise = exercise
    self.order = order
    self.sets = sets
  }
}

public enum WorkoutStatus: String, Codable, Sendable {
  case inProgress
  case completed
}

public struct Workout: Codable, Equatable, Identifiable, Sendable {
  public let id: UUID
  public var title: String
  public var startedAt: Date
  public var completedAt: Date?
  public var status: WorkoutStatus
  public var notes: String?
  public var exercises: [WorkoutExercise]

  public init(
    id: UUID = UUID(),
    title: String,
    startedAt: Date,
    completedAt: Date? = nil,
    status: WorkoutStatus = .inProgress,
    notes: String? = nil,
    exercises: [WorkoutExercise] = []
  ) {
    self.id = id
    self.title = title
    self.startedAt = startedAt
    self.completedAt = completedAt
    self.status = status
    self.notes = notes
    self.exercises = exercises
  }

  public var setCount: Int { exercises.reduce(0) { $0 + $1.sets.count } }
  public var completedSetCount: Int {
    exercises.reduce(0) { total, item in total + item.sets.filter(\.isCompleted).count }
  }
  public var volume: Double { exercises.flatMap(\.sets).reduce(0) { $0 + $1.volume } }
}
