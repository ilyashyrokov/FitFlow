import FitFlowDomain
import SwiftUI

@available(iOS 17.0, *)
public struct SectionHeading: View {
    let title: String
    var detail: String?

    public init(_ title: String, detail: String? = nil) {
        self.title = title
        self.detail = detail
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(FitFlowPalette.primaryText)
            Spacer(minLength: 12)
            if let detail {
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(FitFlowPalette.secondaryText)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

@available(iOS 17.0, *)
public struct PrimaryActionButton: View {
    let title: String
    var symbol: String = "arrow.up.right"
    let action: () -> Void

    public init(title: String, symbol: String = "arrow.up.right", action: @escaping () -> Void) {
        self.title = title
        self.symbol = symbol
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack {
                Text(title).font(.system(.body, design: .rounded).weight(.bold))
                Spacer()
                Image(systemName: symbol).font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(FitFlowPalette.brandInk)
            .padding(.horizontal, 18)
            .frame(minHeight: 54)
            .background(FitFlowPalette.lime, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

@available(iOS 17.0, *)
public struct PlanCard: View {
    let plan: WorkoutPlan
    let action: () -> Void

    public init(plan: WorkoutPlan, action: @escaping () -> Void) {
        self.plan = plan
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: planSymbol)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(FitFlowPalette.teal)
                    .frame(width: 48, height: 48)
                    .background(FitFlowPalette.softMint, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                VStack(alignment: .leading, spacing: 5) {
                    Text(plan.title)
                        .font(.system(.body, design: .rounded).weight(.bold))
                        .foregroundStyle(FitFlowPalette.primaryText)
                    Text("\(plan.exercises.count) упражнений · около \(plan.estimatedMinutes) мин")
                        .font(.subheadline)
                        .foregroundStyle(FitFlowPalette.secondaryText)
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(FitFlowPalette.secondaryText)
            }
            .padding(13)
            .background(FitFlowPalette.surface, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 19, style: .continuous).stroke(FitFlowPalette.border, lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Начать план «\(plan.title)»")
    }

    private var planSymbol: String {
        switch plan.title {
        case "Низ тела": "figure.strengthtraining.traditional"
        case "Полное тело": "figure.mixed.cardio"
        default: "dumbbell.fill"
        }
    }
}

@available(iOS 17.0, *)
public struct EmptyStateView: View {
    let title: String
    let message: String
    var symbol: String = "square.and.pencil"

    public init(title: String, message: String, symbol: String = "square.and.pencil") {
        self.title = title
        self.message = message
        self.symbol = symbol
    }

    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 25, weight: .medium))
                .foregroundStyle(FitFlowPalette.teal)
                .frame(width: 60, height: 60)
                .background(FitFlowPalette.softMint, in: Circle())
            Text(title)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(FitFlowPalette.primaryText)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(FitFlowPalette.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(FitFlowPalette.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

@available(iOS 17.0, *)
public struct MetricTile: View {
    let value: String
    let title: String

    public init(value: String, title: String) {
        self.value = value
        self.title = title
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(value)
                .font(.system(size: 29, weight: .bold, design: .rounded))
                .tracking(-1.1)
                .foregroundStyle(FitFlowPalette.primaryText)
                .contentTransition(.numericText())
            Text(title)
                .font(.subheadline)
                .foregroundStyle(FitFlowPalette.secondaryText)
        }
        .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
        .padding(.horizontal, 15)
        .background(FitFlowPalette.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(FitFlowPalette.border, lineWidth: 1))
    }
}
