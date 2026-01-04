import SwiftUI

enum Detent: CaseIterable {
    case large
    case medium
    case small

    var presentationDetent: PresentationDetent {
        switch self {
        case .large:
            .large
        case .medium:
            .height(300)
        case .small:
            .height(80)
        }
    }
}
