import SwiftUI

// MARK: - PermissionDeniedView (T020)

/// View explaining that photo access is required and how to enable it
struct PermissionDeniedView: View {

    // MARK: - Body

    var body: some View {
        VStack(spacing: 60) {
            Spacer()

            // Icon
            Image(systemName: "photo.badge.exclamationmark")
                .font(.system(size: 150))
                .foregroundStyle(.orange)

            // Title
            Text("Photo Access Required")
                .font(.system(size: 76, weight: .bold))

            // Description
            VStack(spacing: 24) {
                Text("PhotoQuizz needs access to your photos to work.")
                    .font(.system(size: 38))
                    .foregroundStyle(.secondary)

                Text("To enable access:")
                    .font(.system(size: 34, weight: .semibold))
                    .padding(.top, 20)

                VStack(alignment: .leading, spacing: 16) {
                    InstructionRow(number: 1, text: "Open Settings on your Apple TV")
                    InstructionRow(number: 2, text: "Go to Apps → PhotoQuizz")
                    InstructionRow(number: 3, text: "Enable Photos access")
                    InstructionRow(number: 4, text: "Return to PhotoQuizz")
                }
                .padding(.top, 10)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: 1200)

            Spacer()

            // Settings hint
            HStack(spacing: 12) {
                Image(systemName: "gear")
                    .font(.system(size: 32))
                Text("Settings → Apps → PhotoQuizz → Photos")
                    .font(.system(size: 32))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.1))
            )

            Spacer()
        }
        .padding(80)
    }
}

// MARK: - InstructionRow

/// A numbered instruction row
private struct InstructionRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 20) {
            // Number badge
            Text("\(number)")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Circle().fill(Color.blue))

            // Instruction text
            Text(text)
                .font(.system(size: 32))
                .foregroundStyle(.primary)

            Spacer()
        }
        .frame(maxWidth: 800)
    }
}

// MARK: - Preview

#Preview {
    PermissionDeniedView()
}
