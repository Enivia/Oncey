import Foundation

typealias MomentCreationTransitionElementPhases = [MomentCreationTransitionElement: MomentCreationTransitionElementPhase]

enum MomentCreationTransitionElementPhase: Equatable {
    case visible
    case hiddenBelow
    case hiddenAbove
}

enum TransitionStateResolver {
    private static let focusSettleDelayMilliseconds = 50

    static func settledPhases(for step: MomentCreationScreenStep) -> MomentCreationTransitionElementPhases {
        switch step {
        case .capture:
            return [:]
        case .workflow(.albumName):
            return phases(
                visible: [.heroImage, .albumNameField, .primaryButton]
            )
        case .workflow(.note):
            return phases(
                visible: [.heroImage, .noteCard, .primaryButton]
            )
        case .workflow(.reminder):
            return phases(
                visible: [
                    .reminderTitle,
                    .reminderPicker,
                    .reminderDescription,
                    .reminderPrimaryButton,
                    .reminderSecondaryButton
                ]
            )
        case .workflow(.complete):
            return phases(visible: [.completeCard, .completeTimeline])
        }
    }

    static func initialPhases(
        for step: MomentCreationScreenStep,
        route: MomentCreationTransitionRoute
    ) -> MomentCreationTransitionElementPhases {
        switch route {
        case .captureToAlbumName:
            return [
                .heroImage: .hiddenBelow,
                .albumNameField: .hiddenBelow,
                .primaryButton: .hiddenBelow
            ]
        case .captureToNote:
            return [
                .heroImage: .hiddenBelow,
                .noteCard: .hiddenBelow,
                .primaryButton: .hiddenBelow
            ]
        case .albumNameToNote:
            return [
                .heroImage: .visible,
                .noteCard: .hiddenBelow,
                .primaryButton: .hiddenBelow
            ]
        case .noteToReminder:
            return [
                .reminderTitle: .hiddenBelow,
                .reminderPicker: .hiddenBelow,
                .reminderDescription: .hiddenBelow,
                .reminderPrimaryButton: .hiddenBelow,
                .reminderSecondaryButton: .hiddenBelow
            ]
        case .noteToComplete, .reminderToComplete:
            return [
                .completeCard: .hiddenBelow,
                .completeTimeline: .hiddenBelow
            ]
        case .fallback:
            return settledPhases(for: step)
        }
    }

    static func focusDelayMilliseconds(
        for step: MomentCreationScreenStep,
        plan: MomentCreationTransitionPlan
    ) -> Int? {
        guard focusField(for: step) != nil,
              let triggerElement = focusTriggerElement(for: step),
              let stage = plan.stages.first(where: { stage in
                  stage.events.contains { event in
                      event.action == .enter && event.element == triggerElement
                  }
              }) else {
            return nil
        }

        let fieldEntranceCompletion = absoluteStart(for: stage, in: plan) + stage.durationMilliseconds
        let transitionCompletion = totalDurationMilliseconds(for: plan)

        return max(fieldEntranceCompletion, transitionCompletion) + focusSettleDelayMilliseconds
    }

    static func focusField(for step: MomentCreationScreenStep) -> MomentCreationFocusField? {
        switch step {
        case .capture, .workflow(.reminder), .workflow(.complete):
            return nil
        case .workflow(.albumName):
            return .albumName
        case .workflow(.note):
            return .note
        }
    }

    static func focusTriggerElement(for step: MomentCreationScreenStep) -> MomentCreationTransitionElement? {
        switch step {
        case .workflow(.albumName):
            return .albumNameField
        case .workflow(.note):
            return .noteCard
        case .capture, .workflow(.reminder), .workflow(.complete):
            return nil
        }
    }

    private static func phases(
        visible elements: [MomentCreationTransitionElement]
    ) -> MomentCreationTransitionElementPhases {
        Dictionary(uniqueKeysWithValues: elements.map { ($0, .visible) })
    }

    private static func totalDurationMilliseconds(
        for plan: MomentCreationTransitionPlan
    ) -> Int {
        max(plan.stages.map { absoluteStart(for: $0, in: plan) + $0.durationMilliseconds }.max() ?? 0, 0)
    }

    private static func absoluteStart(
        for stage: MomentCreationTransitionStage,
        in plan: MomentCreationTransitionPlan
    ) -> Int {
        let anchorOffset = switch stage.anchor {
        case .routeStart:
            0
        case .containerCompletion:
            plan.containerTransition == .pushFromTrailing ? 300 : 0
        }

        return anchorOffset + stage.startMilliseconds
    }
}
