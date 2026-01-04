enum NotificationOnType: String, CaseIterable, Identifiable {
    var id: RawValue { rawValue }

    case arriving
    case leaving
}
