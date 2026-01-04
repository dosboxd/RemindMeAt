import CoreLocation
import SwiftUI

struct CreateNotificationView: View {
    @EnvironmentObject var notifyService: NotifyService
    @Binding var dummy: NotificationArea

    @Environment(\.dismiss) private var dismiss
    @FocusState private var textFieldIsFocused: Bool

    @State private var title: String = ""
    @State private var notificationOnType: NotificationOnType = .arriving

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                    .focused($textFieldIsFocused)
                    .onSubmit(saveAndRemind)
                    .padding(8)
                HStack {
                    Slider(value: $dummy.radius, in: 5 ... 100, step: 1)
                    Text("\(Int(dummy.radius)) m.")
                }
                Picker("Notify on", selection: $notificationOnType) {
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
                textFieldIsFocused = true
            }
        }
    }

    func saveAndRemind() {
        notifyService.notify(
            near: dummy.center,
            about: title,
            notificationOnType: notificationOnType,
            radius: dummy.radius
        )
        notifyService.loadPendingNotifications()
        dismiss()
    }
}

 #Preview {
     CreateNotificationView(dummy: .constant(NotificationArea(center: CLLocationCoordinate2D(), radius: .zero)))
        .environmentObject(NotifyService(notificationCenter: .current()))
 }
