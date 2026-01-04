import MapKit

final class LocationService: NSObject, CLLocationManagerDelegate, ObservableObject {
    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 100
        locationManager.delegate = self
    }

    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    func requestAuthorization() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .restricted:
            print("restricted")
        case .denied:
            print("denied")
        case .authorizedAlways:
            print("authorizedAlways")
            locationManager.requestLocation()
        case .authorizedWhenInUse:
            print("authorizedWhenInUse")
            locationManager.requestLocation()
        case .authorized:
            print("authorized")
            locationManager.requestLocation()
        @unknown default:
            print("unknown default")
        }
    }

    func locationManager(_: CLLocationManager, didUpdateLocations _: [CLLocation]) {
        print("didUpdateLocations")
    }

    func locationManager(_: CLLocationManager, didFailWithError _: any Error) {
        print("didFailWithError")
    }
}

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
