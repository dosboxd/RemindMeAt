import SwiftUI

struct CreateNotificationView: View {

    @EnvironmentObject var notifyService: NotifyService

    @Binding var isPresented: Bool
    @Binding var notification: NotificationEntity

    @State private var shouldSelectOnEntryOrOnExitBehavior = false
    @FocusState private var reminderFieldIsFocused: Bool

    var body: some View {
        VStack {
            Text("Details")
            HStack {
                Slider(value: $notification.radius)
                Text("\(Int(notification.radius * 100)) m.")
            }
            .padding(.bottom, 16)
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
            Toggle(isOn: $notification.notifyOnEntry) {
                Text("On Entry")
            }
            Toggle(isOn: $notification.notifyOnExit) {
                Text("On Exit")
            }
            Button("Save and remind") {
                saveAndRemind(notification)
            }
        }
        .background(Color.white)
        .padding(16)
    }

    func saveAndRemind(_ notification: NotificationEntity) {
        guard notification.notifyOnEntry || notification.notifyOnExit else {
            shouldSelectOnEntryOrOnExitBehavior = true
            return
        }
        notifyService.notify(
            near: notification.center, about: notification.title, onEntry: notification.notifyOnEntry,
            onExit: notification.notifyOnExit, radius: notification.radius)
        notifyService.loadPendingNotifications()
        isPresented = false
    }
}

#Preview {
    @Previewable @State var notification = NotificationEntity(title: "", center: .init(), notifyOnEntry: true, notifyOnExit: false, radius: 100)
    CreateNotificationView(isPresented: .constant(true), notification: $notification)
}
