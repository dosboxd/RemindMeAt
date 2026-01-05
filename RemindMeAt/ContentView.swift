import MapKit
import SwiftUI

struct ContentView: View {
    @StateObject private var locationService = LocationService()
    @StateObject private var notifyService = NotifyService(notificationCenter: .current())

    @State private var position: MapCameraPosition = .userLocation(fallback: .rect(.world))
    @State private var previousPosition: MapCameraPosition = .userLocation(fallback: .rect(.world))
    @State private var isPresentedListView: Bool = true

    @State private var showingAll: Bool = false
    @AppStorage("satelliteEnabled", store: .standard) private var satelliteEnabled: Bool = false

    @State private var listDetent = Detent.medium.presentationDetent
    @State private var detailsDetent = Detent.medium.presentationDetent
    @State private var isPresentedDetailsView: Bool = false
    @State private var isPresentedAlert: Bool = false
    @State var selection: NotificationArea? {
        didSet {
            isPresentedDetailsView = selection != nil
        }
    }
    @State private var alertedNotification: NotificationEntity? {
        didSet {
            isPresentedAlert = alertedNotification != nil
        }
    }

    var body: some View {
        MapReader { proxy in
            ZStack {
                Map(position: $position) {
                    UserAnnotation()
                    if let selection = Binding($selection) {
                        Marker(coordinate: selection.center.wrappedValue) {}
                        MapCircle(center: selection.center.wrappedValue, radius: selection.radius.wrappedValue)
                            .foregroundStyle(Color.blue.opacity(0.2))
                            .stroke(.white, lineWidth: 2)
                    }
                    ForEach(notifyService.pendingNotifications) { notification in
                        mapCircle(name: notification.title, center: notification.center, radius: notification.radius)
                    }
                }
                .contentMargins(.bottom, 100)
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
            .onChange(of: showingAll) { _, newValue in
                if newValue {
                    position = .automatic
                    previousPosition = position
                    listDetent = Detent.small.presentationDetent
                    selection = nil
                }
            }
            .onChange(of: notifyService.alertedNotification, { oldValue, newValue in
                self.alertedNotification = newValue
            })
            .task {
                locationService.requestAuthorization()
                await notifyService.requestAuthorization()
                notifyService.loadPendingNotifications()
            }
            .sheet(isPresented: $isPresentedListView) {
                NavigationStack {
                    listBottomSheet
                        .navigationTitle("Notifications")
                        .toolbarTitleDisplayMode(.inlineLarge)
                        .sheet(
                            isPresented: $isPresentedDetailsView,
                            onDismiss: {
                                withAnimation {
                                    position = previousPosition
                                    selection = nil
                                }
                            }
                        ) {
                            if let selection {
                                CreateNotificationView(
                                    dummy: Binding(
                                        get: {
                                            selection
                                        }, set: {
                                            self.selection = $0
                                        }
                                    )
                                )
                                .presentationDragIndicator(.visible)
                                .presentationBackgroundInteraction(.enabled)
                                .presentationDetents([Detent.medium.presentationDetent], selection: $detailsDetent)
                                .environmentObject(notifyService)
                            }
                        }
                }
            }
            .alert("You asked me to notify you about", isPresented: $isPresentedAlert, actions: {
                Button("Keep") {}
                Button("Complete or remove") {
                    print("Procedding to complete or remove")
                    if let id = alertedNotification?.id {
                        notifyService.pendingNotifications.removeAll(where: { $0.id == id })
                        notifyService.removePendingNotification(by: id)
                    }

                    alertedNotification = nil
                    isPresentedAlert = false
                }
            }, message: {
                if let alertedNotification {
                    Text(alertedNotification.title)
                }
            })
        }
    }

    var listBottomSheet: some View {
        List {
            if notifyService.pendingNotifications.isEmpty {
                Text("Tap on map to add a reminder")
            } else {
                ForEach(notifyService.pendingNotifications) { notification in
                    Text(notification.title)
                }
                .onDelete { index in
                    var copy = notifyService.pendingNotifications
                    copy.remove(atOffsets: index)
                    notifyService.replace(newPendingNotifications: copy)
                    notifyService.pendingNotifications.remove(atOffsets: index)
                }
            }
        }
        .listRowBackground(Color.clear)
        .contentMargins(.vertical, 8)
        .listStyle(.automatic)
        .background(.ultraThickMaterial)
        .presentationBackgroundInteraction(.enabled)
        .presentationDetents(Set(Detent.allCases.map(\.presentationDetent)), selection: $listDetent)
        .interactiveDismissDisabled()
    }

    func mapCircle(name: String, center: CLLocationCoordinate2D, radius: CLLocationDistance) -> some MapContent {
        Group {
            Marker(coordinate: center) {
                Text(name)
            }
            MapCircle(center: center, radius: radius)
                .foregroundStyle(Color.blue.opacity(0.2))
                .stroke(.white, lineWidth: 2)
        }
    }

    func locate(position: CGPoint, proxy: MapProxy, space: CoordinateSpaceProtocol) {
        guard let coordinate = proxy.convert(position, from: space) else { return }
        selection = NotificationArea(center: coordinate, radius: 50)
        withAnimation {
            self.position = .camera(
                MapCamera(MKMapCamera(lookingAtCenter: coordinate, fromDistance: 1000, pitch: 0, heading: 0))
            )
        }
        detailsDetent = Detent.medium.presentationDetent
    }

    var mapControls: some View {
        VStack {
            Button {
                position = .userLocation(fallback: .rect(.world))
                previousPosition = position
                showingAll = false
                selection = nil
            } label: {
                Rectangle()
                    .foregroundStyle(.background)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: position == .userLocation(fallback: .rect(.world)) ? "location.fill" : "location")
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
            Button {
                showingAll.toggle()
            } label: {
                Rectangle()
                    .foregroundStyle(.background)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: showingAll ? "map.fill" : "map")
                    )
            }
            .frame(width: 44, height: 44)
        }
    }
}

#Preview {
    ContentView()
}
