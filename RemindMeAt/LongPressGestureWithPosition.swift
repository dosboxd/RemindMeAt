import SwiftUI

struct LongPressGestureWithPosition: UIGestureRecognizerRepresentable {
    private let longPressAt: (_ position: CGPoint) -> Void

    init(longPressAt: @escaping (_ position: CGPoint) -> Void) {
        self.longPressAt = longPressAt
    }

    func makeUIGestureRecognizer(context: Context) -> UILongPressGestureRecognizer {
        UILongPressGestureRecognizer()
    }

    func handleUIGestureRecognizerAction(_ gesture: UILongPressGestureRecognizer, context: Context) {
        guard  gesture.state == .began else { return }
        longPressAt(gesture.location(in: gesture.view))
    }
}
