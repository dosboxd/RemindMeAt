import SwiftUI

enum NotificationType: String, CaseIterable, Identifiable {
    var id: RawValue { rawValue }

case arriving
    case leaving
}

struct CreateNotificationView: View {
    @Environment(\.dismiss) var dismiss

    @EnvironmentObject var notifyService: NotifyService
    @EnvironmentObject var locationService: LocationService

    @Binding var notification: NotificationEntity

    @State private var shouldSelectOnEntryOrOnExitBehavior = false
    @FocusState private var reminderFieldIsFocused: Bool
    @State private var selectedNotificationType: NotificationType = .arriving

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $notification.title) // suggestion
                    .focused($reminderFieldIsFocused)
                    .onSubmit {
                        saveAndRemind(notification)
                    }
                    .padding(8)
                VStack(alignment: .leading) {
                    Text("Radius: \(Int(notification.radius)) meters")
                    HStack {
                        Text("5 m.")
                        Slider(value: $notification.radius, in: 5 ... 100, step: 1)
                        Text("100 m.")
                    }
                }
                Picker("Notify on", selection: $selectedNotificationType) {
                    ForEach(NotificationType.allCases) { theme in
                        Text(theme.rawValue.capitalized).tag(theme)
                    }
                }
                .pickerStyle(.palette)
                .labelsHidden()
            }
            .selectionDisabled()
            .listStyle(.automatic)
            .contentMargins(.vertical, 0)
            .backgroundStyle(.ultraThickMaterial)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .title) {
                    Text("New Reminder")
                        .fontWeight(.bold)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", systemImage: "checkmark") {
                        print("saving")
                        dismiss()
                    }
                }
            }
            .task(id: notification.center) {
                do {
                    notification.title =
                        try await locationService.lookUpPlacemark(location: notification.center).first
                            ?? ""
                } catch {
                    print("Could not get a name for location with error: \(error)")
                }
            }
        }
    }

    func saveAndRemind(_ notification: NotificationEntity) {
        print("saveAndRemind")
        guard notification.notifyOnEntry || notification.notifyOnExit else {
            shouldSelectOnEntryOrOnExitBehavior = true
            return
        }
        notifyService.notify(
            near: notification.center, about: notification.title,
            onEntry: notification.notifyOnEntry,
            onExit: notification.notifyOnExit, radius: notification.radius
        )
        notifyService.loadPendingNotifications()
        dismiss()
    }
}

#Preview {
    @Previewable @State var notification = NotificationEntity(
        id: "", title: "", center: .init(), notifyOnEntry: true, notifyOnExit: false, radius: 100
    )
    CreateNotificationView(notification: $notification)
        .environmentObject(NotifyService(notificationCenter: .current()))
        .environmentObject(LocationService())
}
