import SwiftUI

// MARK: - PermissionRequestView (T019, T022)

/// View requesting photo library access with explanation
struct PermissionRequestView: View {

    // MARK: - Environment

    @Environment(PhotoLibraryService.self) private var photoLibraryService

    // MARK: - Properties

    let onAuthorized: () -> Void

    // MARK: - State

    @State private var isRequesting = false
    @FocusState private var isButtonFocused: Bool

    // MARK: - Body

    var body: some View {
        VStack(spacing: 60) {
            Spacer()

            // Icon
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 150))
                .foregroundStyle(.blue)
                .symbolEffect(.pulse, options: .repeating)

            // Title
            Text("Access Your Memories")
                .font(.system(size: 76, weight: .bold))

            // Description
            Text("PhotoQuizz needs access to your photo library to create personalized memory games from your travel photos.")
                .font(.system(size: 38))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 1200)

            Spacer()

            // Allow Access Button
            Button(action: requestAccess) {
                HStack(spacing: 16) {
                    if isRequesting {
                        ProgressView()
                            .tint(.white)
                    }
                    Text("Allow Access")
                        .font(.system(size: 38, weight: .semibold))
                }
                .frame(minWidth: 400, minHeight: 80)
            }
            .buttonStyle(FocusableButtonStyle())
            .focused($isButtonFocused)
            .disabled(isRequesting)

            Spacer()
        }
        .padding(80)
        .onAppear {
            isButtonFocused = true
        }
    }

    // MARK: - Actions

    private func requestAccess() {
        isRequesting = true

        Task {
            let status = await photoLibraryService.requestAuthorization()

            await MainActor.run {
                isRequesting = false

                if status == .authorized || status == .limited {
                    onAuthorized()
                }
            }
        }
    }
}

// MARK: - FocusableButtonStyle (T022)

/// Custom button style with focus effects for tvOS
struct FocusableButtonStyle: ButtonStyle {
    @Environment(\.isFocused) private var isFocused

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isFocused ? Color.blue : Color.blue.opacity(0.8))
            )
            .foregroundColor(.white)
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .shadow(color: isFocused ? .blue.opacity(0.5) : .clear, radius: 20)
            .animation(.spring(duration: 0.3), value: isFocused)
    }
}

// MARK: - Preview

#Preview {
    PermissionRequestView(onAuthorized: {})
        .environment(PhotoLibraryService())
}
