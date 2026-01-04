import SwiftUI

struct CreateNotificationView: View {
    @Environment(\.dismiss) var dismiss

    @EnvironmentObject var notifyService: NotifyService
    @State var notification: NotificationEntity = .init(id: "", title: "", center: .init(), notifyOnEntry: true, notifyOnExit: false, radius: .zero)
    @FocusState private var reminderFieldIsFocused: Bool
    @State private var selectedNotificationOnType: NotificationOnType = .arriving

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $notification.title)
                    .focused($reminderFieldIsFocused)
                    .onSubmit(saveAndRemind)
                    .padding(8)
                HStack {
                    Slider(value: $notification.radius, in: 5 ... 100, step: 1)
                    Text("\(Int(notification.radius)) m.")
                }
                Picker("Notify on", selection: $selectedNotificationOnType) {
                    ForEach(NotificationOnType.allCases) { theme in
                        Text(theme.rawValue.capitalized).tag(theme)
                    }
                }
                .pickerStyle(.palette)
                .labelsHidden()
            }
            .contentMargins(.vertical, 0)
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
                        saveAndRemind()
                    }
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                reminderFieldIsFocused = true
            }
        }
    }

    func saveAndRemind() {
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
    CreateNotificationView()
        .environmentObject(NotifyService(notificationCenter: .current()))
}
