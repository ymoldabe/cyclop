import AppKit

@MainActor
final class FocusTimer: ObservableObject {
    enum Phase: String, CaseIterable, Identifiable {
        case focus, shortBreak, longBreak
        var id: String { rawValue }

        var duration: TimeInterval {
            switch self {
            case .focus: return 25 * 60
            case .shortBreak: return 5 * 60
            case .longBreak: return 15 * 60
            }
        }

        var title: String {
            switch self {
            case .focus: return localized("Focus")
            case .shortBreak: return localized("Break")
            case .longBreak: return localized("Long Break")
            }
        }

        var symbol: String {
            switch self {
            case .focus: return "brain.head.profile"
            case .shortBreak: return "cup.and.saucer.fill"
            case .longBreak: return "figure.walk"
            }
        }
    }

    enum State: Equatable {
        case idle
        case running(endsAt: Date)
        case paused(remaining: TimeInterval)
    }

    @Published private(set) var phase: Phase = .focus
    @Published private(set) var state: State = .idle
    @Published private(set) var completedFocus = 0

    private var alarm: Timer?
    private var wakeObserver: Any?

    var isActive: Bool { state != .idle }
    var isRunning: Bool {
        if case .running = state { return true }
        return false
    }

    init() {
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.finishIfDue() }
        }
    }

    func remaining(at now: Date) -> TimeInterval {
        switch state {
        case .idle: return phase.duration
        case .running(let endsAt): return max(0, endsAt.timeIntervalSince(now))
        case .paused(let remaining): return remaining
        }
    }

    func start(_ phase: Phase) {
        self.phase = phase
        run(for: phase.duration)
    }

    func toggle() {
        switch state {
        case .idle:
            run(for: phase.duration)
        case .running(let endsAt):
            cancelAlarm()
            state = .paused(remaining: max(0, endsAt.timeIntervalSinceNow))
        case .paused(let remaining):
            run(for: remaining)
        }
    }

    func reset() {
        cancelAlarm()
        state = .idle
    }

    private func run(for seconds: TimeInterval) {
        cancelAlarm()
        let endsAt = Date().addingTimeInterval(seconds)
        state = .running(endsAt: endsAt)
        let timer = Timer(fire: endsAt, interval: 0, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.finishIfDue() }
        }
        timer.tolerance = 0.2
        RunLoop.main.add(timer, forMode: .common)
        alarm = timer
    }

    private func finishIfDue() {
        guard case .running(let endsAt) = state, endsAt <= Date().addingTimeInterval(0.5) else { return }
        cancelAlarm()
        state = .idle
        NSSound(named: "Glass")?.play()
        if phase == .focus {
            completedFocus += 1
            phase = completedFocus % 4 == 0 ? .longBreak : .shortBreak
        } else {
            phase = .focus
        }
    }

    private func cancelAlarm() {
        alarm?.invalidate()
        alarm = nil
    }
}
