#if os(iOS)
  import FitFlowDomain
  import SwiftUI

  @available(iOS 17.0, *)
  struct ExerciseCatalogSheet: View {
    let onSelect: (Exercise) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory?

    private let exercises = [
      Exercise(name: "Жим штанги лёжа", category: .chest),
      Exercise(name: "Жим гантелей на наклонной", category: .chest),
      Exercise(name: "Отжимания", category: .chest),
      Exercise(name: "Тяга горизонтального блока", category: .back),
      Exercise(name: "Тяга верхнего блока", category: .back),
      Exercise(name: "Приседания", category: .legs),
      Exercise(name: "Румынская тяга", category: .legs),
      Exercise(name: "Жим гантелей сидя", category: .shoulders),
      Exercise(name: "Подъём гантелей в стороны", category: .shoulders),
      Exercise(name: "Сгибание рук", category: .arms),
      Exercise(name: "Разгибание рук на блоке", category: .arms),
      Exercise(name: "Планка", category: .core),
    ]

    private var filteredExercises: [Exercise] {
      exercises.filter { exercise in
        (selectedCategory == nil || exercise.category == selectedCategory)
          && (searchText.isEmpty || exercise.name.localizedCaseInsensitiveContains(searchText))
      }
    }

    var body: some View {
      NavigationStack {
        List(filteredExercises) { exercise in
          Button {
            onSelect(exercise)
            dismiss()
          } label: {
            HStack {
              VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name).foregroundStyle(FitFlowPalette.primaryText)
                Text(exercise.category.title).font(.caption).foregroundStyle(
                  FitFlowPalette.secondaryText)
              }
              Spacer()
              Image(systemName: "plus.circle.fill").foregroundStyle(FitFlowPalette.teal)
            }
            .padding(.vertical, 3)
          }
          .listRowBackground(FitFlowPalette.surface)
        }
        .scrollContentBackground(.hidden)
        .background(FitFlowPalette.canvas)
        .navigationTitle("Упражнения")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .searchable(text: $searchText, prompt: "Найти упражнение")
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            Button("Готово") { dismiss() }
          }
        }
        .safeAreaInset(edge: .bottom) {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
              categoryChip(nil, title: "Все")
              ForEach(ExerciseCategory.allCases) { category in
                categoryChip(category, title: category.title)
              }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
          }
          .background(.ultraThinMaterial)
        }
      }
    }

    private func categoryChip(_ category: ExerciseCategory?, title: String) -> some View {
      let isSelected = selectedCategory == category
      return Button(title) { selectedCategory = category }
        .font(.caption.weight(.semibold))
        .foregroundStyle(isSelected ? FitFlowPalette.brandInk : FitFlowPalette.primaryText)
        .padding(.horizontal, 12)
        .frame(minHeight: 38)
        .background(isSelected ? FitFlowPalette.lime : FitFlowPalette.surface, in: Capsule())
        .overlay(Capsule().stroke(FitFlowPalette.border, lineWidth: isSelected ? 0 : 1))
    }
  }
#endif
