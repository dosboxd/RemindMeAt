import SwiftUI

struct CreateNotificationView: View {

    @Environment(\.dismiss) var dismiss

    @EnvironmentObject var notifyService: NotifyService
    @EnvironmentObject var locationService: LocationService

    @Binding var notification: NotificationEntity

    @State private var shouldSelectOnEntryOrOnExitBehavior = false
    @FocusState private var reminderFieldIsFocused: Bool

    var body: some View {
        Form {
            Section("Details") {
                    HStack {
                        Text("Name: ")
                        TextField("Reminder name", text: $notification.title)
                            .focused($reminderFieldIsFocused)
                            .onSubmit {
                                saveAndRemind(notification)
                            }
                            .padding(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.secondary, lineWidth: 1)
                            )
                    }
                    VStack(alignment: .leading) {
                        Text("Radius: \(Int(notification.radius)) meters")
                        HStack {
                            Text("5 m.")
                            Slider(value: $notification.radius, in: 5...100, step: 1)
                            Text("100 m.")
                        }
                    }
            }
            Section("Notify on") {
                Toggle(isOn: $notification.notifyOnEntry) {
                    Text("On Entry")
                }
                Toggle(isOn: $notification.notifyOnExit) {
                    Text("On Exit")
                }
            }
            Button("Save and remind") {
                saveAndRemind(notification)
            }
            Button(role: .destructive) {
                dismiss.callAsFunction()
            } label: {
                Text("Cancel")
            }
            .listRowSeparator(.hidden)
        }
        .selectionDisabled()
        .listStyle(.automatic)
        .backgroundStyle(.ultraThickMaterial)
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

    func saveAndRemind(_ notification: NotificationEntity) {
        print("saveAndRemind")
        guard notification.notifyOnEntry || notification.notifyOnExit else {
            shouldSelectOnEntryOrOnExitBehavior = true
            return
        }
        notifyService.notify(
            near: notification.center, about: notification.title,
            onEntry: notification.notifyOnEntry,
            onExit: notification.notifyOnExit, radius: notification.radius)
        notifyService.loadPendingNotifications()
        dismiss()
    }
}

#Preview {
    @Previewable @State var notification = NotificationEntity(
        id: "", title: "", center: .init(), notifyOnEntry: true, notifyOnExit: false, radius: 100)
        CreateNotificationView(notification: $notification)
            .environmentObject(NotifyService(notificationCenter: .current()))
            .environmentObject(LocationService())
}
