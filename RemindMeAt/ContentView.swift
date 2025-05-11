import MapKit
import SwiftUI
import UserNotifications

struct ContentView: View {

    @StateObject private var locationService = LocationService()
    @StateObject private var notifyService = NotifyService(notificationCenter: .current())

    @State private var position: MapCameraPosition = .automatic
    @State private var tappedCoordinate: Location?
    @State private var isPresented: Bool = false
    @State private var onEntry: Bool = false
    @State private var onExit: Bool = false
    @State private var radius: Double = 0.5
    @State private var reminderName: String = ""
    @State private var mapItems = [MKMapItem]()
    @State private var shouldSelectOnEntryOrOnExitBehavior: Bool = false
    @FocusState private var reminderFieldIsFocused: Bool

    var body: some View {
        MapReader { proxy in
            Map(position: $position) {
                UserAnnotation()
                if let tappedCoordinate {
                    mapCircle(name: "RemindMeAt", center: tappedCoordinate.coordinate, radius: radius * 100)
                }
                ForEach(notifyService.pendingNotifications) { notification in
                    if let region = (notification.trigger as? UNLocationNotificationTrigger)?.region
                        as? CLCircularRegion
                    {
                        mapCircle(name: notification.content.title, center: region.center, radius: region.radius)
                    }
                }
            }
            .mapControls {
                MapUserLocationButton()
            }
            .onTapGesture { position in
                if let coordinate = proxy.convert(position, from: .local) {
                    tappedCoordinate = Location(coordinate: coordinate)

                    let mkMapCamera = MKMapCamera.init(
                        lookingAtCenter: coordinate, fromDistance: 1000, pitch: 0, heading: 0)
                    let mapCamera = MapCamera(mkMapCamera)
                    self.position = .camera(mapCamera)
                }
            }
            .task {
                locationService.requestAuthorization()
                await notifyService.requestAuthorization()
            }
            .sheet(isPresented: $isPresented, onDismiss: { tappedCoordinate = nil }) {
                creationBottomSheet
                    .alert(isPresented: $shouldSelectOnEntryOrOnExitBehavior) {
                        Alert(title: Text("Please select on entry or on exit behavior for the reminder"))
                    }
            }
            .sheet(isPresented: $notifyService.areThereAnyPendingNotificationsLeft) {
                listBottomSheet
            }
            .onChange(of: tappedCoordinate) { _, _ in isPresented = tappedCoordinate != nil }
        }
    }

    func saveAndRemind() {
        guard let coordinate = tappedCoordinate?.coordinate else { fatalError() }
        guard onEntry || onExit else {
            // show alert
            shouldSelectOnEntryOrOnExitBehavior = true
            return
        }
        notifyService.notify(
            near: coordinate, about: reminderName, onEntry: onEntry,
            onExit: onExit, radius: radius * 100)
        isPresented = false
        let regions = notifyService.pendingNotifications.compactMap {
            (($0.trigger as? UNLocationNotificationTrigger)?.region as? CLCircularRegion)
        }
        let rects = regions.map {
            MKMapRect(origin: MKMapPoint($0.center), size: MKMapSize(width: 0, height: 0))
        }
        let fittingRect = rects.reduce(MKMapRect.null) { $0.union($1) }
        position = MapCameraPosition.region(MKCoordinateRegion(fittingRect))
        tappedCoordinate = nil
    }

    var creationBottomSheet: some View {
        VStack {
            HStack {
                Slider(value: $radius)
                Text("\(Int(radius * 100)) m.")
            }
            .padding(.bottom, 16)
            TextField("Reminder name", text: $reminderName)
                .focused($reminderFieldIsFocused)
                .onSubmit(saveAndRemind)
                .padding(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.secondary, lineWidth: 1)
                )
            Toggle(isOn: $onEntry) {
                Text("On Entry")
            }
            Toggle(isOn: $onExit) {
                Text("On Exit")
            }
            Button("Save and remind", action: saveAndRemind)
        }
        .padding(.horizontal, 16)
        .presentationDetents([.height(256)])
    }

    var listBottomSheet: some View {
        List {
            ForEach(notifyService.pendingNotifications) { notification in
                Text(notification.content.title)
            }
            .onDelete { index in
                var copy = notifyService.pendingNotifications
                copy.remove(atOffsets: index)
                notifyService.replace(newPendingNotifications: copy)
                notifyService.pendingNotifications.remove(atOffsets: index)
            }
        }
        .presentationBackgroundInteraction(.enabled)
        .presentationDetents([.large, .medium, .fraction(0.15)])
        .interactiveDismissDisabled()
    }

    func mapCircle(name: String, center: CLLocationCoordinate2D, radius: CLLocationDistance) -> some MapContent {
        Group {
            Marker(coordinate: center) { Text(name) }
            MapCircle(center: center, radius: radius)
                .foregroundStyle(Color.blue.opacity(0.2))
                .stroke(.white, lineWidth: 2)
        }
    }
}

#Preview {
    ContentView()
}
