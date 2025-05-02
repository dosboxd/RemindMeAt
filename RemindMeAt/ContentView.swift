import MapKit
import SwiftUI

struct ContentView: View {

    @StateObject private var locationService = LocationService()
    @StateObject private var notifyService = NotifyService(notificationCenter: .current())

    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var tappedCoordinate: Location?
    @State private var isPresented: Bool = false
    @State private var radius: Double = 0.5

    var body: some View {
        MapReader { proxy in
            Map(position: $position) {
                UserAnnotation()
                if let tappedCoordinate {
                    Annotation.init("RemindMeAt", coordinate: tappedCoordinate.coordinate) {
                        Image(systemName: "mappin")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    MapCircle(MKCircle(center: tappedCoordinate.coordinate, radius: radius * 100))
                        .foregroundStyle(.blue.opacity(0.8))
                        .strokeStyle(style: StrokeStyle(lineWidth: 1, lineCap: .butt, lineJoin: .miter, miterLimit: 10, dash: [], dashPhase: 0))
                }
            }
           .mapControls {
                MapUserLocationButton()
            }
            .onTapGesture { position in
                if let coordinate = proxy.convert(position, from: .local) {
                    tappedCoordinate = Location(coordinate: coordinate)

                    let mkMapCamera = MKMapCamera.init(lookingAtCenter: coordinate, fromDistance: 1000, pitch: 0, heading: 0)
                    let mapCamera = MapCamera(mkMapCamera)
                    self.position = .camera(mapCamera)
                }
            }
            .task {
                locationService.requestAuthorization()
                await notifyService.requestAuthorization()
            }
            .sheet(
                isPresented: $isPresented, onDismiss: {
                    notifyService.notify(near: tappedCoordinate!.coordinate, onEntry: true, onExit: false, radius: radius * 100)
                },
                content: {
                    VStack {
                        Slider(value: $radius)
                        Text("Radius: \(Int(radius * 100)) meters.")
                    }
                    .padding(16)
                    .presentationDetents([.height(200)])
                }
            )
            .sheet(isPresented: $notifyService.isThereAnyPendingNotificationsLeft) {
                List {
                    ForEach($notifyService.pendingNotifications) { notification in
                        Text("\(notification)")
                    }
                    .onDelete { index in
                        var copy = notifyService.pendingNotifications
                        copy.remove(atOffsets: index)
                        notifyService.replace(newPendingNotifications: copy)
                    }
                }
            }
            .onChange(of: tappedCoordinate) { oldValue, newValue in
                // present a sheet
                print(tappedCoordinate)
                isPresented.toggle()
            }
        }
    }
}

#Preview {
    ContentView()
}

extension UNNotificationRequest: @retroactive Identifiable {
    public var id: String { identifier }
}
