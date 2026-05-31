import Foundation

public struct TrainingForecast: Codable, Equatable, Sendable {
    public var estimatedOneRepMax: Double
    public var changePercent: Double
    public var sessionsUsed: Int
    public var unit: String

    public init(
        estimatedOneRepMax: Double,
        changePercent: Double,
        sessionsUsed: Int,
        unit: String
    ) {
        self.estimatedOneRepMax = estimatedOneRepMax
        self.changePercent = changePercent
        self.sessionsUsed = sessionsUsed
        self.unit = unit
    }
}
