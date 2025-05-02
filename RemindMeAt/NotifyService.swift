import MapKit

final class NotifyService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {

    @Published var pendingNotifications: [UNNotificationRequest] = []
    @Published var isThereAnyPendingNotificationsLeft: Bool = false
    private let notificationCenter: UNUserNotificationCenter

    init(notificationCenter: UNUserNotificationCenter) {
        self.notificationCenter = notificationCenter
        super.init()

        self.notificationCenter.delegate = self
        Task { @MainActor in
            let data = await notificationCenter.pendingNotificationRequests()
            pendingNotifications = data
            isThereAnyPendingNotificationsLeft = !data.isEmpty
        }
    }

    func replace(newPendingNotifications: [UNNotificationRequest]) {
        let set1 = Set(newPendingNotifications)
        let set2 = Set(pendingNotifications)
        let diff = set1.symmetricDifference(set2)
        let identifiers = Array(diff).map { $0.identifier }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
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
