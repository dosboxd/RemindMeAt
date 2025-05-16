import CoreLocation

struct NotificationEntity: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var center: CLLocationCoordinate2D
    var notifyOnEntry: Bool
    var notifyOnExit: Bool
    var radius: CGFloat

    static func == (lhs: NotificationEntity, rhs: NotificationEntity) -> Bool {
        lhs.title == rhs.title && lhs.center.latitude == rhs.center.latitude
            && lhs.center.longitude == rhs.center.longitude
            && lhs.notifyOnEntry == rhs.notifyOnEntry && lhs.notifyOnExit == rhs.notifyOnExit
            && lhs.radius == rhs.radius
    }
}
