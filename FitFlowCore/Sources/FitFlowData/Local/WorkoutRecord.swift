import Foundation
import SwiftData
import FitFlowDomain

@Model
@available(iOS 17.0, *)
public final class WorkoutRecord {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var startedAt: Date
    public var completedAt: Date?
    public var statusRawValue: String
    public var notes: String?
    @Relationship(deleteRule: .cascade) public var exercises: [WorkoutExerciseRecord]

    public init(workout: Workout) {
        id = workout.id
        title = workout.title
        startedAt = workout.startedAt
        completedAt = workout.completedAt
        statusRawValue = workout.status.rawValue
        notes = workout.notes
        exercises = workout.exercises.map(WorkoutExerciseRecord.init)
    }

    public func domainModel() -> Workout {
        Workout(
            id: id,
            title: title,
            startedAt: startedAt,
            completedAt: completedAt,
            status: WorkoutStatus(rawValue: statusRawValue) ?? .inProgress,
            notes: notes,
            exercises: exercises.sorted { $0.order < $1.order }.map { $0.domainModel() }
        )
    }
}

@Model
@available(iOS 17.0, *)
public final class WorkoutExerciseRecord {
    @Attribute(.unique) public var id: UUID
    public var exerciseID: UUID
    public var name: String
    public var categoryRawValue: String
    public var isCustom: Bool
    public var order: Int
    @Relationship(deleteRule: .cascade) public var sets: [WorkoutSetRecord]

    public init(_ exercise: WorkoutExercise) {
        id = exercise.id
        exerciseID = exercise.exercise.id
        name = exercise.exercise.name
        categoryRawValue = exercise.exercise.category.rawValue
        isCustom = exercise.exercise.isCustom
        order = exercise.order
        sets = exercise.sets.map(WorkoutSetRecord.init)
    }

    public func domainModel() -> WorkoutExercise {
        let category = ExerciseCategory(rawValue: categoryRawValue) ?? .other
        return WorkoutExercise(
            id: id,
            exercise: Exercise(
                id: exerciseID,
                name: name,
                category: category,
                isCustom: isCustom
            ),
            order: order,
            sets: sets.sorted { $0.order < $1.order }.map { $0.domainModel() }
        )
    }
}

@Model
@available(iOS 17.0, *)
public final class WorkoutSetRecord {
    @Attribute(.unique) public var id: UUID
    public var order: Int
    public var weight: Double?
    public var repetitions: Int?
    public var isCompleted: Bool

    public init(_ set: WorkoutSet) {
        id = set.id
        order = set.order
        weight = set.weight
        repetitions = set.repetitions
        isCompleted = set.isCompleted
    }

    public func domainModel() -> WorkoutSet {
        WorkoutSet(
            id: id,
            order: order,
            weight: weight,
            repetitions: repetitions,
            isCompleted: isCompleted
        )
    }
}
