import CoreLocation

struct NotificationEntity: Identifiable {
    let id = UUID()
    var title: String
    var center: CLLocationCoordinate2D
    var notifyOnEntry: Bool
    var notifyOnExit: Bool
    var radius: CGFloat
}
