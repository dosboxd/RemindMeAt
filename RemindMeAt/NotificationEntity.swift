import CoreLocation

struct NotificationEntity: Identifiable, Equatable, Hashable {
    var id: String
    var title: String
    var center: CLLocationCoordinate2D
    var notificationOnType: NotificationOnType
    var radius: CGFloat

    init(id: String, title: String, center: CLLocationCoordinate2D, notificationOnType: NotificationOnType, radius: CGFloat) {
        self.id = id
        self.title = title
        self.center = center
        self.notificationOnType = notificationOnType
        self.radius = radius
    }

    static func == (lhs: NotificationEntity, rhs: NotificationEntity) -> Bool {
        lhs.title == rhs.title && lhs.center.latitude == rhs.center.latitude
            && lhs.center.longitude == rhs.center.longitude
            && lhs.notificationOnType == rhs.notificationOnType
            && lhs.radius == rhs.radius
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
