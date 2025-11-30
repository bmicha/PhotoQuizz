import SwiftUI

// MARK: - SettingsView (T049, T050, T051, T052, T053, T056)

/// Settings screen for customizing game options
struct SettingsView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(SettingsService.self) private var settingsService

    // MARK: - Focus State

    @FocusState private var focusedSetting: SettingOption?

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.02)
                .ignoresSafeArea()

            VStack(spacing: 50) {
                // Header
                Text("Game Settings")
                    .font(.system(size: 56, weight: .bold))
                    .padding(.top, 40)

                // Settings list
                VStack(spacing: 30) {
                    // Reveal Speed (T050)
                    SettingRow(
                        title: "Reveal Speed",
                        subtitle: "How fast tiles reveal",
                        icon: "timer"
                    ) {
                        SettingPicker(
                            selection: Binding(
                                get: { settingsService.settings.revealSpeed },
                                set: { settingsService.setRevealSpeed($0) }
                            ),
                            options: RevealSpeed.allCases
                        ) { speed in
                            speed.displayName
                        }
                    }
                    .focused($focusedSetting, equals: .revealSpeed)

                    // Timer Duration (T051)
                    SettingRow(
                        title: "Timer Duration",
                        subtitle: "Time to guess each photo",
                        icon: "clock"
                    ) {
                        TimerDurationPicker(
                            value: Binding(
                                get: { settingsService.settings.timerDuration },
                                set: { settingsService.setTimerDuration($0) }
                            )
                        )
                    }
                    .focused($focusedSetting, equals: .timerDuration)

                    // Session Length (T052)
                    SettingRow(
                        title: "Photos Per Session",
                        subtitle: "Number of photos to play",
                        icon: "photo.stack"
                    ) {
                        SettingPicker(
                            selection: Binding(
                                get: { settingsService.settings.sessionLength },
                                set: { settingsService.setSessionLength($0) }
                            ),
                            options: SessionLength.allCases
                        ) { length in
                            length.displayName
                        }
                    }
                    .focused($focusedSetting, equals: .sessionLength)
                }
                .padding(.horizontal, 100)

                Spacer()

                // Reset button
                Button("Reset to Defaults") {
                    settingsService.resetToDefaults()
                }
                .buttonStyle(SecondarySettingButtonStyle())
                .focused($focusedSetting, equals: .reset)

                Spacer()
            }
            .padding(60)
        }
        .navigationTitle("Settings")
        .onAppear {
            focusedSetting = .revealSpeed
        }
    }
}

// MARK: - Setting Option Enum

private enum SettingOption: Hashable {
    case revealSpeed
    case timerDuration
    case sessionLength
    case reset
}

// MARK: - SettingRow

private struct SettingRow<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    @ViewBuilder let content: () -> Content

    @Environment(\.isFocused) private var isFocused

    var body: some View {
        HStack(spacing: 30) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(.blue)
                .frame(width: 60)

            // Labels
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 36, weight: .semibold))

                Text(subtitle)
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Control
            content()
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isFocused ? Color.blue.opacity(0.15) : Color.secondary.opacity(0.08))
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.spring(duration: 0.3), value: isFocused)
    }
}

// MARK: - SettingPicker

private struct SettingPicker<T: Hashable>: View {
    @Binding var selection: T
    let options: [T]
    let label: (T) -> String

    var body: some View {
        HStack(spacing: 20) {
            // Previous button
            Button {
                selectPrevious()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .semibold))
            }
            .buttonStyle(PickerArrowStyle())

            // Current value
            Text(label(selection))
                .font(.system(size: 28, weight: .medium))
                .frame(minWidth: 150)

            // Next button
            Button {
                selectNext()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 24, weight: .semibold))
            }
            .buttonStyle(PickerArrowStyle())
        }
    }

    private func selectPrevious() {
        guard let currentIndex = options.firstIndex(of: selection),
              currentIndex > 0 else { return }
        selection = options[currentIndex - 1]
    }

    private func selectNext() {
        guard let currentIndex = options.firstIndex(of: selection),
              currentIndex < options.count - 1 else { return }
        selection = options[currentIndex + 1]
    }
}

// MARK: - TimerDurationPicker

private struct TimerDurationPicker: View {
    @Binding var value: Int

    private let step = 5
    private let minValue = 10
    private let maxValue = 120

    var body: some View {
        HStack(spacing: 20) {
            // Decrease button
            Button {
                if value > minValue {
                    value = max(minValue, value - step)
                }
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 24, weight: .semibold))
            }
            .buttonStyle(PickerArrowStyle())
            .disabled(value <= minValue)

            // Current value
            Text("\(value) seconds")
                .font(.system(size: 28, weight: .medium))
                .frame(minWidth: 150)

            // Increase button
            Button {
                if value < maxValue {
                    value = min(maxValue, value + step)
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
            }
            .buttonStyle(PickerArrowStyle())
            .disabled(value >= maxValue)
        }
    }
}

// MARK: - Button Styles

private struct PickerArrowStyle: ButtonStyle {
    @Environment(\.isFocused) private var isFocused
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isEnabled ? (isFocused ? .white : .blue) : .gray)
            .frame(width: 50, height: 50)
            .background(
                Circle()
                    .fill(isFocused ? Color.blue : Color.blue.opacity(0.1))
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
    }
}

private struct SecondarySettingButtonStyle: ButtonStyle {
    @Environment(\.isFocused) private var isFocused

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 28))
            .padding(.horizontal, 40)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isFocused ? Color.red.opacity(0.8) : Color.gray.opacity(0.2))
            )
            .foregroundColor(isFocused ? .white : .red)
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .animation(.spring(duration: 0.3), value: isFocused)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(SettingsService())
}
