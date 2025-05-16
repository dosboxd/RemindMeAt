import MapKit
import SwiftUI
import UserNotifications

struct ContentView: View {

    @StateObject private var locationService = LocationService()
    @StateObject private var notifyService = NotifyService(notificationCenter: .current())

    @State private var position: MapCameraPosition = .automatic
    @State private var listDetent = PresentationDetent.fraction(0.33)
    @State private var detailsDetent = PresentationDetent.fraction(0.33)

    @State var selection: NotificationEntity?
    @State var isPresentedCreateView: Bool = false

    var body: some View {
        MapReader { proxy in
            Map(position: $position) {
                UserAnnotation()
                if let selection = Binding($selection) {
                    Marker(coordinate: selection.center.wrappedValue) { Text(selection.title.wrappedValue) }
                    MapCircle(center: selection.center.wrappedValue, radius: selection.radius.wrappedValue)
                        .foregroundStyle(Color.blue.opacity(0.2))
                        .stroke(.white, lineWidth: 2)
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
                    isPresentedCreateView = true
                    selection = NotificationEntity(title: "", center: coordinate, notifyOnEntry: true, notifyOnExit: false, radius: 50)
                    let mkMapCamera = MKMapCamera(lookingAtCenter: coordinate, fromDistance: 1000, pitch: 0, heading: 0)
                    let mapCamera = MapCamera(mkMapCamera)
                    self.position = .camera(mapCamera)
                    listDetent = .fraction(0.33)
                }
            }
            .task {
                locationService.requestAuthorization()
                await notifyService.requestAuthorization()
                notifyService.loadPendingNotifications()
            }
            .sheet(isPresented: $notifyService.areThereAnyPendingNotificationsLeft) {
                listBottomSheet
                    .sheet(isPresented: $isPresentedCreateView, onDismiss: {
                        position = .automatic
                    }) {
                        if let selection = selection {
                            CreateNotificationView(
                                isPresented: $isPresentedCreateView,
                                notification: Binding(
                                    get: { selection },
                                    set: { self.selection = $0 }
                                )
                            )
                            .presentationDragIndicator(.visible)
                            .presentationBackgroundInteraction(.enabled)
                            .presentationDetents([.large, .fraction(0.33)], selection: $detailsDetent)
                            .environmentObject(notifyService)
                            .environmentObject(locationService)
                        }
                    }
            }
        }
    }

    var listBottomSheet: some View {
        List {
            Section("Notifications") {
                ForEach(notifyService.pendingNotifications) { notification in
                    Text(notification.content.title)
                }
                .onDelete { index in
                    var copy = notifyService.pendingNotifications
                    copy.remove(atOffsets: index)
                    notifyService.replace(newPendingNotifications: copy)
                    notifyService.pendingNotifications.remove(atOffsets: index)
                }
                .listRowBackground(Color.clear)
            }
            .headerProminence(.increased)
        }
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
}

#Preview {
    ContentView()
}
