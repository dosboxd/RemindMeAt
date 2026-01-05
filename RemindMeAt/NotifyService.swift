import CoreLocation
import MapKit

@MainActor
final class NotifyService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var pendingNotifications: [NotificationEntity] = []
    @Published var alertedNotification: NotificationEntity?
    private let notificationCenter: UNUserNotificationCenter

    init(notificationCenter: UNUserNotificationCenter) {
        self.notificationCenter = notificationCenter
        super.init()
        self.notificationCenter.delegate = self
    }

    func loadPendingNotifications() {
        Task { @MainActor in
            self.pendingNotifications = await notificationCenter.pendingNotificationRequests()
                .compactMap { request in
                    guard let trigger = request.trigger as? UNLocationNotificationTrigger,
                          let region = trigger.region as? CLCircularRegion
                    else { return nil }

                    return NotificationEntity(
                        id: request.id,
                        title: request.content.title,
                        center: region.center,
                        notificationOnType: region.notifyOnEntry ? .arriving : .leaving,
                        radius: region.radius
                    )
                }
        }
    }

    func replace(newPendingNotifications: [NotificationEntity]) {
        let set1 = Set(newPendingNotifications)
        let set2 = Set(pendingNotifications)
        let diff = set1.symmetricDifference(set2)
        let identifiers = Array(diff).map { $0.id }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func removePendingNotification(by id: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
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

    func notify(
        near targetLocation: CLLocationCoordinate2D,
        about text: String,
        notificationOnType: NotificationOnType,
        radius: Double
    ) {
        print("Adding notification \(text)")
        let content = UNMutableNotificationContent()
        content.title = text
        content.sound = UNNotificationSound.default

        let region = CLCircularRegion(center: targetLocation, radius: radius, identifier: UUID().uuidString)
        let trigger = UNLocationNotificationTrigger(region: region, repeats: true)

        switch notificationOnType {
        case .arriving:
            region.notifyOnEntry = true
        case .leaving:
            region.notifyOnExit = true
        }

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        notificationCenter.add(request)
    }

    func userNotificationCenter(_: UNUserNotificationCenter, didReceive notification: UNNotificationResponse) async {
        print("Received Notification")
        alertedNotification = pendingNotifications.first(where: { $0.id == notification.notification.request.id })
    }

    func userNotificationCenter(
        _: UNUserNotificationCenter, willPresent _: UNNotification
    ) async -> UNNotificationPresentationOptions {
        print("Attempt to present notification")
        return [.banner, .sound, .badge, .list]
    }
}

extension UNNotificationRequest: @retroactive Identifiable {
    public var id: String { identifier }
}
