import Foundation

public enum AppTab: String, CaseIterable, Equatable, Identifiable {
    case today
    case history
    case progress

    public var id: Self { self }

    public var title: LocalizedStringResource {
        switch self {
        case .today: "Сегодня"
        case .history: "История"
        case .progress: "Прогресс"
        }
    }

    public var symbol: String {
        switch self {
        case .today: "house"
        case .history: "clock.arrow.circlepath"
        case .progress: "chart.xyaxis.line"
        }
    }
}
