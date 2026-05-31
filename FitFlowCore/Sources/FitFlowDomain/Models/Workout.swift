import Foundation

public enum MeasurementUnit: String, Codable, CaseIterable, Sendable {
    case kilograms
    case pounds

    public var symbol: String {
        switch self {
        case .kilograms: "кг"
        case .pounds: "lb"
        }
    }
}

public enum ExerciseCategory: String, Codable, CaseIterable, Sendable, Identifiable {
    case chest
    case back
    case legs
    case shoulders
    case arms
    case core
    case other

    public var id: Self { self }

    public var title: String {
        switch self {
        case .chest: "Грудь"
        case .back: "Спина"
        case .legs: "Ноги"
        case .shoulders: "Плечи"
        case .arms: "Руки"
        case .core: "Корпус"
        case .other: "Другое"
        }
    }
}

public struct Exercise: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var category: ExerciseCategory
    public var isCustom: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        category: ExerciseCategory,
        isCustom: Bool = false
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.isCustom = isCustom
    }
}

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
