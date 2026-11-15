#if os(iOS)
  import SwiftUI

  @available(iOS 17.0, *)
  struct SetValueField: View {
    let value: String
    let placeholder: String
    let label: String
    let isDecimal: Bool
    let onChange: (String) -> Void
    @State private var draft = ""
    @FocusState private var isFocused: Bool

    var body: some View {
      TextField(placeholder, text: $draft)
        #if os(iOS)
          .keyboardType(isDecimal ? .decimalPad : .numberPad)
        #endif
        .multilineTextAlignment(.center)
        .font(.subheadline.weight(.bold).monospacedDigit())
        .foregroundStyle(FitFlowPalette.primaryText)
        .frame(maxWidth: .infinity, minHeight: 44)
        .background(
          FitFlowPalette.canvas, in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
        .focused($isFocused)
        .onAppear { draft = value }
        .onChange(of: value) { _, newValue in
          if !isFocused { draft = newValue }
        }
        .onChange(of: draft) { _, newValue in onChange(newValue) }
        .accessibilityLabel(label)
    }
  }
#endif
