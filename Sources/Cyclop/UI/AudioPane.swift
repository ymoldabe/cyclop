import SwiftUI

struct AudioPane: View {
    @ObservedObject var audio: AudioOutputStore

    var body: some View {
        if audio.devices.isEmpty {
            Text(localized("No output devices"))
                .font(.system(size: 12))
                .foregroundStyle(Theme.tertiary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 6) {
                    ForEach(audio.devices) { device in
                        DeviceRow(device: device, isCurrent: audio.current == device.id) {
                            audio.select(device)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct DeviceRow: View {
    let device: AudioOutputStore.Device
    let isCurrent: Bool
    let action: () -> Void

    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: device.symbol)
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 20)
                Text(device.name)
                    .font(.system(size: 12.5, weight: .medium))
                    .lineLimit(1)
                Spacer(minLength: 0)
                if let battery = device.battery {
                    Text("\(battery)%")
                        .font(.system(size: 11).monospacedDigit())
                        .foregroundStyle(Theme.secondary)
                }
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .semibold))
                    .opacity(isCurrent ? 1 : 0)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isCurrent ? Theme.surfaceHover : (hovered ? Theme.surface : Color.clear))
            )
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
    }
}
