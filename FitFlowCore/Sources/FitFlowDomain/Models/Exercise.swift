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
