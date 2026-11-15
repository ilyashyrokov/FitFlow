import Foundation

public enum RecommendationSource: String, Codable, Sendable {
  case onDevice
  case localFallback
  case pythonService
}

public struct Recommendation: Codable, Equatable, Identifiable, Sendable {
  public let id: UUID
  public var createdAt: Date
  public var title: String
  public var message: String
  public var reason: String
  public var basedOnWorkoutCount: Int
  public var exerciseID: UUID?
  public var confidence: Confidence
  public var forecast: TrainingForecast?
  public var source: RecommendationSource

  public enum Confidence: String, Codable, Sendable {
    case low
    case moderate
  }

  public init(
    id: UUID = UUID(),
    createdAt: Date = .now,
    title: String,
    message: String,
    reason: String,
    basedOnWorkoutCount: Int,
    exerciseID: UUID? = nil,
    confidence: Confidence = .low,
    forecast: TrainingForecast? = nil,
    source: RecommendationSource = .onDevice
  ) {
    self.id = id
    self.createdAt = createdAt
    self.title = title
    self.message = message
    self.reason = reason
    self.basedOnWorkoutCount = basedOnWorkoutCount
    self.exerciseID = exerciseID
    self.confidence = confidence
    self.forecast = forecast
    self.source = source
  }
}

public struct RecommendationPolicy: Sendable {
  public init() {}

  public func recommendation(from workouts: [Workout]) -> Recommendation {
    let completed =
      workouts
      .filter { $0.status == .completed }
      .sorted { $0.startedAt > $1.startedAt }
    guard let pair = latestMatchingExercise(in: completed) else {
      return insufficientHistory(count: completed.count)
    }
    return compare(pair.latest, with: pair.previous)
  }

  private func latestMatchingExercise(in workouts: [Workout]) -> (
    latest: WorkoutExercise, previous: WorkoutExercise
  )? {
    guard let latest = workouts.first?.exercises.first,
      let previous = workouts.dropFirst()
        .flatMap(\.exercises)
        .first(where: { $0.exercise.name == latest.exercise.name })
    else { return nil }
    return (latest, previous)
  }

  private func insufficientHistory(count: Int) -> Recommendation {
    Recommendation(
      title: "Продолжай записывать",
      message: "Добавь ещё пару тренировок — тогда появится первая подсказка по твоим данным.",
      reason: "Пока недостаточно записей для сравнения.",
      basedOnWorkoutCount: count
    )
  }

  private func compare(
    _ latest: WorkoutExercise,
    with previous: WorkoutExercise
  ) -> Recommendation {
    let latestSets = latest.sets.filter(\.isCompleted)
    let previousSets = previous.sets.filter(\.isCompleted)
    guard !latestSets.isEmpty, !previousSets.isEmpty else {
      return Recommendation(
        title: "Повтори комфортную нагрузку",
        message:
          "В прошлой записи не хватает завершённых подходов. Выбери вес по самочувствию и продолжай дневник.",
        reason: "Сравнение основано на завершённых подходах.",
        basedOnWorkoutCount: 2,
        exerciseID: latest.exercise.id
      )
    }

    let latestReps = latestSets.compactMap(\.repetitions).reduce(0, +)
    let previousReps = previousSets.compactMap(\.repetitions).reduce(0, +)
    if latestReps < previousReps { return holdLoad(for: latest.exercise) }
    if latestSets.compactMap(\.weight).max() ?? 0 > previousSets.compactMap(\.weight).max() ?? 0 {
      return growingLoad(for: latest.exercise)
    }
    return stableLoad(for: latest.exercise)
  }

  private func holdLoad(for exercise: Exercise) -> Recommendation {
    Recommendation(
      title: "Оставь вес прежним",
      message:
        "В прошлой тренировке повторов было меньше. Можно сохранить текущую нагрузку и посмотреть по ощущениям.",
      reason: "Сравнены завершённые подходы упражнения «\(exercise.name)».",
      basedOnWorkoutCount: 2,
      exerciseID: exercise.id
    )
  }

  private func growingLoad(for exercise: Exercise) -> Recommendation {
    Recommendation(
      title: "Нагрузка постепенно растёт",
      message:
        "В последней записи вес выше, а повторения сохранились. Продолжай ориентироваться на самочувствие.",
      reason: "Сравнены две последние записи упражнения «\(exercise.name)».",
      basedOnWorkoutCount: 2,
      exerciseID: exercise.id,
      confidence: .moderate
    )
  }

  private func stableLoad(for exercise: Exercise) -> Recommendation {
    Recommendation(
      title: "Сохрани текущий вес",
      message: "Последние записи выглядят стабильными. Повтори нагрузку, если она комфортна.",
      reason: "Основано на двух последних записях упражнения «\(exercise.name)».",
      basedOnWorkoutCount: 2,
      exerciseID: exercise.id,
      confidence: .moderate
    )
  }
}
