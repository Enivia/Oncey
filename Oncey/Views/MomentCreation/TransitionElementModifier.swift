import SwiftUI

struct TransitionElementModifier: ViewModifier {
    let phase: MomentCreationTransitionElementPhase
    let reduceMotion: Bool
    let distance: CGFloat

    func body(content: Content) -> some View {
        content
            .opacity(phase == .visible ? 1 : 0)
            .offset(y: reduceMotion ? 0 : offsetY)
            .allowsHitTesting(phase == .visible)
            .accessibilityHidden(phase != .visible)
    }

    private var offsetY: CGFloat {
        switch phase {
        case .visible:
            0
        case .hiddenBelow:
            distance
        case .hiddenAbove:
            -distance
        }
    }
}

extension View {
    func momentCreationTransitionPhase(
        _ phase: MomentCreationTransitionElementPhase,
        reduceMotion: Bool,
        distance: CGFloat = 20
    ) -> some View {
        modifier(
            TransitionElementModifier(
                phase: phase,
                reduceMotion: reduceMotion,
                distance: distance
            )
        )
    }
}
