# FitFlow iOS

Нативное приложение для iPhone на SwiftUI, iOS 17+. Запись тренировок работает локально через SwiftData. Рекомендация может приходить из FastAPI, а если адрес API не настроен — рассчитывается локальными объяснимыми правилами. Python API дополнительно строит экспериментальный прогноз силы на следующее занятие линейной регрессией, если есть история минимум из пяти тренировок упражнения.

## Открыть

Для запуска приложения открой `FitFlow.xcodeproj` в Xcode 16+, выбери схему `FitFlow` и iPhone Simulator, затем нажми **Run** (`⌘R`). При первом открытии Xcode разреши макросы зависимостей TCA: в Issue navigator (`⌘5`) выбери предупреждения `Macro ... must be enabled` и нажми **Enable Macros**. Это одноразовое подтверждение Xcode для исполняемых макросов; пока они выключены, последующие ошибки `RootFeature does not conform to Reducer` — каскадные.

В группе `Sources` виден только `FitFlowApp.swift`, потому что это тонкая точка запуска. Остальной Swift-код — отдельный локальный пакет `FitFlowCore`. В Xcode его можно раскрыть внизу Project navigator в секции **Package Dependencies**. Чтобы смотреть код и тесты отдельными модулями, открой `FitFlowCore/Package.swift` как Swift package.

## Архитектура

- `FitFlowCore/Sources/FitFlowDomain` — модели, контракты репозиториев, расчёт объёма и правила рекомендаций.
- `FitFlowCore/Sources/FitFlowData` — SwiftData-репозиторий и HTTP-клиент FastAPI.
- `FitFlowCore/Sources/FitFlowFeatures` — TCA reducers, состояния и SwiftUI-экраны.
- `Sources/FitFlowApp.swift` — composition root: подключает SwiftData и зависимости.

## Библиотеки и инструменты

- [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) — feature state, эффекты, DI и `TestStore`.
- [SwiftLint build plugin](https://github.com/SimplyDanny/SwiftLintPlugins) — единые правила Swift в сборке SwiftPM.
- SwiftUI, SwiftData, Swift Charts, URLSession и Swift Testing — системные фреймворки Apple.

Версии сторонних пакетов закреплены в `FitFlowCore/Package.swift`.

## Тесты

```sh
swift test --package-path FitFlowCore
```

Покрыты правила рекомендаций, сохранение/обновление/удаление SwiftData-записей, выбор вкладок, валидация подходов, автосохранение черновика, завершение тренировки и offline-fallback.

## Как пользоваться

1. На экране «Сегодня» начни тренировку с одного из планов или продолжи незавершённую.
2. Введи вес и повторы каждого подхода, отметь выполненные. Черновик сохраняется сам.
3. Заверши тренировку; она появится в «Истории», а сводка и рекомендации — в «Прогрессе».
4. Сервер рекомендаций необязателен: без его адреса Swift-приложение использует локальную политику.

## Подключить FastAPI

В Debug-схеме адрес Python API уже настроен на `http://127.0.0.1:8000/`: запусти сервер по шагам из `RecommendationService/README.md`, затем запускай приложение в Simulator. Без запущенного сервера приложение автоматически использует локальные рекомендации; ML-карточка появится после пяти занятий по одному упражнению. Для физического iPhone укажи адрес Mac в локальной сети вместо `127.0.0.1`. Клиент отправляет только дату занятия и название упражнения с весом и повторами завершённых подходов. Свободные заметки пользователя не отправляются.
