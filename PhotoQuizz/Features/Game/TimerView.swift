import SwiftUI

// MARK: - TimerView (T027)

/// Circular countdown timer display
struct TimerView: View {

    // MARK: - Properties

    let remaining: Int
    let total: Int

    // MARK: - Computed Properties

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(remaining) / Double(total)
    }

    private var isUrgent: Bool {
        remaining <= 5
    }

    private var timerColor: Color {
        if remaining <= 5 {
            return .red
        } else if remaining <= 10 {
            return .orange
        } else {
            return .blue
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 12)

            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    timerColor,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: remaining)

            // Timer text
            VStack(spacing: 8) {
                Text("\(remaining)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(timerColor)
                    .contentTransition(.numericText())

                Text("seconds")
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 200, height: 200)
        .scaleEffect(isUrgent ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isUrgent)
    }
}

// MARK: - Compact Timer View

/// Smaller inline timer for secondary display
struct CompactTimerView: View {

    let remaining: Int

    private var timerColor: Color {
        if remaining <= 5 {
            return .red
        } else if remaining <= 10 {
            return .orange
        } else {
            return .blue
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "timer")
                .font(.system(size: 24))

            Text("\(remaining)s")
                .font(.system(size: 32, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(timerColor)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(timerColor.opacity(0.15))
        )
    }
}

// MARK: - Preview

#Preview("Timer View") {
    VStack(spacing: 40) {
        TimerView(remaining: 25, total: 30)
        TimerView(remaining: 8, total: 30)
        TimerView(remaining: 3, total: 30)
    }
}

#Preview("Compact Timer") {
    VStack(spacing: 20) {
        CompactTimerView(remaining: 25)
        CompactTimerView(remaining: 8)
        CompactTimerView(remaining: 3)
    }
}
