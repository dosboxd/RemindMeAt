import MapKit
import SwiftUI
import UserNotifications

struct ContentView: View {
    @StateObject private var locationService = LocationService()
    @StateObject private var notifyService = NotifyService(notificationCenter: .current())

    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var isPresentedListView: Bool = true

    @AppStorage("satelliteEnabled", store: .standard) private var satelliteEnabled: Bool = false

    @State private var listDetent = PresentationDetent.fraction(0.33)
    @State private var detailsDetent = PresentationDetent.fraction(0.33)

    @State var selection: NotificationEntity?

    var body: some View {
        MapReader { proxy in
            ZStack {
                Map(position: $position) {
                    UserAnnotation()
                    if let selection = Binding($selection) {
                        Marker(coordinate: selection.center.wrappedValue) { Text(selection.title.wrappedValue) }
                        MapCircle(center: selection.center.wrappedValue, radius: selection.radius.wrappedValue)
                            .foregroundStyle(Color.blue.opacity(0.2))
                            .stroke(.white, lineWidth: 2)
                    }
                    ForEach(notifyService.pendingNotifications) { notification in
                        mapCircle(name: notification.title, center: notification.center, radius: notification.radius)
                    }
                }
                .mapStyle(satelliteEnabled ? .hybrid : .standard)
                VStack {
                    HStack {
                        Spacer()
                        mapControls
                    }
                    .padding(5)

                    Spacer()
                }
            }
            .mapControls {
                MapScaleView()
            }
            .gesture(
                LongPressGestureWithPosition { position in
                    locate(position: position, proxy: proxy, space: .global)
                }
            )
            .onTapGesture { position in
                locate(position: position, proxy: proxy, space: .local)
            }
            .task {
                locationService.requestAuthorization()
                await notifyService.requestAuthorization()
                notifyService.loadPendingNotifications()
            }
            .sheet(isPresented: $isPresentedListView) {
                listBottomSheet
                    .sheet(
                        item: $selection,
                        onDismiss: { withAnimation { self.position = .automatic } }
                    ) { selection in
                        CreateNotificationView(
                            notification: Binding(
                                get: { selection },
                                set: { self.selection = $0 }
                            )
                        )
                        .presentationDragIndicator(.visible)
                        .presentationBackgroundInteraction(.enabled)
                        .presentationDetents(
                            [.large, .fraction(0.33)], selection: $detailsDetent
                        )
                        .environmentObject(notifyService)
                        .environmentObject(locationService)
                    }
            }
        }
    }

    var listBottomSheet: some View {
        List {
            Section("Notifications") {
                if notifyService.pendingNotifications.isEmpty {
                    Text("Tap on map to add a reminder")
                } else {
                    ForEach(notifyService.pendingNotifications) { notification in
                        Button(notification.title) {
                            selection = notification
                            withAnimation { position = .item(MKMapItem(placemark: MKPlacemark(coordinate: notification.center))) }
                        }
                    }
                    .onDelete { index in
                        var copy = notifyService.pendingNotifications
                        copy.remove(atOffsets: index)
                        notifyService.replace(newPendingNotifications: copy)
                        notifyService.pendingNotifications.remove(atOffsets: index)
                    }
                }
            }
            .headerProminence(.increased)
        }
        .listRowBackground(Color.clear)
        .listStyle(.plain)
        .background(.ultraThickMaterial)
        .presentationBackgroundInteraction(.enabled)
        .presentationDetents([.large, .fraction(0.33), .fraction(0.15)], selection: $listDetent)
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

    func locate(position: CGPoint, proxy: MapProxy, space: CoordinateSpaceProtocol) {
        guard let coordinate = proxy.convert(position, from: space) else { return }
        selection = NotificationEntity(id: "", title: "", center: coordinate, notifyOnEntry: true, notifyOnExit: false, radius: 50)
        withAnimation { self.position = .camera(MapCamera(MKMapCamera(lookingAtCenter: coordinate, fromDistance: 1000, pitch: 0, heading: 0))) }
        listDetent = .fraction(0.33)
    }

    var mapControls: some View {
        VStack {
            Button {
                position = .userLocation(fallback: .automatic)
            } label: {
                Rectangle()
                    .foregroundStyle(.background)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: position == .userLocation(fallback: .automatic) ? "location.fill" : "location")
                    )
            }
            .frame(width: 44, height: 44)
            Button {
                withAnimation {
                    satelliteEnabled.toggle()
                }
            } label: {
                Rectangle()
                    .foregroundStyle(.background)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: satelliteEnabled ? "globe.americas.fill" : "globe.americas")
                    )
            }
            .frame(width: 44, height: 44)
        }
    }
}

#Preview {
    ContentView()
}
