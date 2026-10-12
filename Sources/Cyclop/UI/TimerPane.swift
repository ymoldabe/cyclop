import SwiftUI

struct TimerPane: View {
    @ObservedObject var timer: FocusTimer

    var body: some View {
        HStack(spacing: 18) {
            VStack(spacing: 10) {
                Text(timer.phase.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.secondary)
                TimerCountdown(timer: timer, size: 40)
                HStack(spacing: 10) {
                    Button {
                        timer.toggle()
                    } label: {
                        Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                    }
                    .buttonStyle(NotchButtonStyle(size: 34, prominent: true))

                    Button {
                        timer.reset()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .buttonStyle(NotchButtonStyle(size: 30))
                    .disabled(!timer.isActive)
                    .opacity(timer.isActive ? 1 : 0.35)
                }
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 8) {
                ForEach(FocusTimer.Phase.allCases) { phase in
                    PhaseButton(phase: phase, isCurrent: timer.phase == phase && timer.isActive) {
                        timer.start(phase)
                    }
                }
            }
            .frame(width: 190)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(Theme.contentAnimation, value: timer.state)
    }
}

struct TimerCountdown: View {
    @ObservedObject var timer: FocusTimer
    var size: CGFloat

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            Text(formatTime(timer.remaining(at: context.date)))
                .font(.system(size: size, weight: .medium).monospacedDigit())
                .foregroundStyle(timer.isRunning || !timer.isActive ? Color.white : Theme.secondary)
        }
    }
}

private struct PhaseButton: View {
    let phase: FocusTimer.Phase
    let isCurrent: Bool
    let action: () -> Void

    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: phase.symbol)
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 18)
                Text(phase.title)
                    .font(.system(size: 12, weight: .medium))
                Spacer(minLength: 0)
                Text(localized("%d min", Int(phase.duration / 60)))
                    .font(.system(size: 11).monospacedDigit())
                    .foregroundStyle(Theme.tertiary)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isCurrent ? Theme.surfaceHover : (hovered ? Theme.surface : Theme.surface.opacity(0.5)))
            )
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
    }
}
