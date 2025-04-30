import MapKit
import SwiftUI

struct ContentView: View {

    @StateObject private var locationService = LocationService()
    @StateObject private var notifyService = NotifyService(notificationCenter: .current())

    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var tappedCoordinate: CLLocationCoordinate2D?

    var body: some View {
        MapReader { proxy in
            Map(initialPosition: position) {
                UserAnnotation()
                if let tappedCoordinate {
                    MapCircle(MKCircle(center: tappedCoordinate, radius: CLLocationDistance(100)))
                }
            }
            .mapControls {
                MapUserLocationButton()
            }
            .onTapGesture { position in
                if let coordinate = proxy.convert(position, from: .local) {
                    tappedCoordinate = coordinate
                    notifyService.notify(near: coordinate, onEntry: true, onExit: false)
                }
            }
            .task {
                locationService.requestAuthorization()
                await notifyService.requestAuthorization()
            }
        }
    }
}

#Preview {
    ContentView()
}
