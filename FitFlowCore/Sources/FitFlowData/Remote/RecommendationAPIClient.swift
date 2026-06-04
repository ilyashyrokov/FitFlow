import FitFlowDomain
import Foundation

public struct RecommendationAPIClient: RecommendationProvider {
    private let baseURL: URL
    private let session: URLSession

    public init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    public func recommendation(for workouts: [Workout]) async throws -> Recommendation {
        var request = URLRequest(url: baseURL.appending(path: "v1/recommendations"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(RecommendationRequest(workouts: workouts))

        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse,
              (200..<300).contains(response.statusCode)
        else {
            throw RecommendationAPIError.invalidResponse
        }
        return try JSONDecoder().decode(RecommendationResponse.self, from: data).domainModel()
    }
}

private struct RecommendationRequest: Encodable {
    let unit = "kg"
    let workouts: [WorkoutPayload]

    init(workouts: [Workout]) {
        self.workouts = workouts
            .filter { $0.status == .completed }
            .map(WorkoutPayload.init)
    }

    private enum CodingKeys: String, CodingKey {
        case unit
        case workouts
    }
}

private struct WorkoutPayload: Encodable {
    let date: String
    let exercises: [ExercisePayload]

    init(_ workout: Workout) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        date = formatter.string(from: workout.startedAt)
        exercises = workout.exercises.map(ExercisePayload.init)
    }
}

private struct ExercisePayload: Encodable {
    let name: String
    let sets: [SetPayload]

    init(_ exercise: WorkoutExercise) {
        name = exercise.exercise.name
        sets = exercise.sets.compactMap { set in
            guard set.isCompleted, set.weight != nil, set.repetitions != nil else { return nil }
            return SetPayload(set)
        }
    }
}

private struct SetPayload: Encodable {
    let weight: Double
    let repetitions: Int

    init(_ set: WorkoutSet) {
        weight = set.weight ?? 0
        repetitions = set.repetitions ?? 1
    }
}

private struct RecommendationResponse: Decodable {
    let title: String
    let message: String
    let reason: String
    let confidence: Recommendation.Confidence
    let basedOnWorkoutCount: Int?
    let exerciseID: UUID?
    let forecast: TrainingForecast?

    private enum CodingKeys: String, CodingKey {
        case title
        case message
        case reason
        case confidence
        case basedOnWorkoutCount
        case exerciseID = "exerciseId"
        case forecast
    }

    func domainModel() -> Recommendation {
        Recommendation(
            title: title,
            message: message,
            reason: reason,
            basedOnWorkoutCount: basedOnWorkoutCount ?? 0,
            exerciseID: exerciseID,
            confidence: confidence,
            forecast: forecast
        )
    }
}

public enum RecommendationAPIError: Error {
    case invalidResponse
}
