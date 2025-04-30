import MapKit

final class NotifyService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {

    private let notificationCenter: UNUserNotificationCenter

    init(notificationCenter: UNUserNotificationCenter) {
        self.notificationCenter = notificationCenter
        super.init()

        self.notificationCenter.delegate = self
        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification, object: nil, queue: .main
        ) { _ in
            self.clearPendingNotifications()
        }
    }

    func requestAuthorization() async {
        do {
            let authorized = try await notificationCenter.requestAuthorization(options: [
                .badge, .sound, .alert,
            ])
            print("Notification are \(authorized ? "" : "not") authorized")
        } catch {
            print("Error requesting notification authorization: \(error)")
        }
    }

    func notify(near targetLocation: CLLocationCoordinate2D, onEntry: Bool, onExit: Bool, radius: Double = 100.0) {
        print("Adding notification")
        let content = UNMutableNotificationContent()
        content.title = "At home"
        content.subtitle = "Reminding you!"
        content.sound = UNNotificationSound.default

        let region = CLCircularRegion(
            center: targetLocation, radius: radius, identifier: UUID().uuidString)
        let trigger = UNLocationNotificationTrigger(region: region, repeats: false)
        region.notifyOnEntry = onEntry
        region.notifyOnExit = onExit

        let request = UNNotificationRequest(
            identifier: UUID().uuidString, content: content, trigger: trigger)

        notificationCenter.add(request)
    }

    func clearPendingNotifications() {
        print("clearPendingNotifications")
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse
    ) async {
        print("Received Notification")
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        print("Attempt to present notification")
        return [.banner, .sound, .badge, .list]
    }
}
