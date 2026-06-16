# FitFlow architecture decisions

Reviewed 13 November 2026 against the product brief and primary project documentation.

## Modules and dependency direction

The app target deploys to iOS 17. The shared Swift package declares iOS 16 so TCA's Observation backport can compile; SwiftUI screens are individually marked iOS 17 and are only used by the app target.

```text
FitFlowApp (composition root)
  ├── FitFlowFeatures ──> FitFlowDomain
  ├── FitFlowData ──────> FitFlowDomain
  └── FitFlowDomain
```

- `FitFlowDomain` owns the workout models, repository contracts, validation and deterministic recommendation policy. It imports no UI, persistence or networking framework.
- `FitFlowData` implements the domain contracts with SwiftData and `URLSession`.
- `FitFlowFeatures` owns TCA reducers and SwiftUI views. Effects receive domain protocols through TCA dependencies; views do not call SwiftData or HTTP directly.
- `FitFlowApp` is the composition root. It creates the SwiftData container, injects the live repository and selects the API provider with a local recommendation fallback.

This is one Xcode app plus a local Swift package with separate products, which keeps compile-time boundaries clear without introducing a project generator or a large number of tiny packages.

## Selected tools

### The Composable Architecture 1.26.2

Used for feature state, actions, effects, dependency injection and reducer tests. TCA's `TestStore` can assert every state transition and effect response. The package supports iOS 16 and later, so it fits the iOS 17 deployment target. It already includes Point-Free dependency support, so there is no duplicate direct `swift-dependencies` dependency.

Sources: [TCA README](https://github.com/pointfreeco/swift-composable-architecture), [Package.swift](https://github.com/pointfreeco/swift-composable-architecture/blob/main/Package.swift), [releases](https://github.com/pointfreeco/swift-composable-architecture/releases), [TCA testing guide](https://github.com/pointfreeco/swift-composable-architecture/blob/main/Sources/ComposableArchitecture/Documentation.docc/Articles/TestingTCA.md).

### SwiftLintPlugins 0.65.0

Applied as a SwiftPM build-tool plugin, with a checked-in `.swiftlint.yml`. It is development tooling only and does not enter the app runtime. The dedicated plugin repository distributes the binary plugin without building the whole SwiftLint source project.

Sources: [SwiftLint plugin setup](https://github.com/realm/SwiftLint#swift-package-manager), [plugin repository](https://github.com/SimplyDanny/SwiftLintPlugins), [plugin releases](https://github.com/SimplyDanny/SwiftLintPlugins/releases).

### Apple frameworks

SwiftUI, SwiftData, Swift Charts, `URLSession` and Swift Testing are native dependencies for the chosen platform. SwiftData provides the offline source of truth; recommendation requests include only workout dates, exercise names and completed-set values, as described in the brief.

Sources: [SwiftData](https://developer.apple.com/documentation/SwiftData), [ModelContext](https://developer.apple.com/documentation/swiftdata/modelcontext).

## Test boundaries

- Domain tests cover recommendation decisions and volume rules.
- Data tests use an in-memory SwiftData container for save, update, delete and delete-all behavior.
- Feature tests use TCA `TestStore` and injected in-memory repositories for tab selection, input validation, autosave and workout completion.

## Current limitation

The API client is ready for the described FastAPI response. The base URL is intentionally unset by default; until the service URL is configured in Build Settings, the app uses the local explainable recommendation policy. If a configured API is unreachable, it falls back to the same local policy, so the recommendation screen remains useful offline.
