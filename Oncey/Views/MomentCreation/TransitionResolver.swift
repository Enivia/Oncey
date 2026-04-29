import Foundation

enum MomentCreationTransitionDirection: Equatable {
    case forward
    case backward
}

enum MomentCreationTransitionKind: Equatable {
    case staged
    case push
    case fallback
}

enum MomentCreationTransitionRoute: Equatable {
    case captureToAlbumName
    case captureToNote
    case albumNameToNote
    case noteToReminder
    case noteToComplete
    case reminderToComplete
    case fallback(
        from: MomentCreationScreenStep,
        to: MomentCreationScreenStep,
        direction: MomentCreationTransitionDirection
    )
}

enum MomentCreationTransitionElement: Hashable {
    case background
    case heroImage
    case albumNameField
    case noteCard
    case primaryButton
    case reminderTitle
    case reminderPicker
    case reminderDescription
    case reminderPrimaryButton
    case reminderSecondaryButton
    case completeCard
    case completeTimeline
}

enum MomentCreationTransitionAction: Equatable {
    case transition
    case enter
    case exit
}

enum MomentCreationTransitionStageAnchor: Equatable {
    case routeStart
    case containerCompletion
}

enum MomentCreationContainerTransition: Equatable {
    case none
    case pushFromTrailing
}

struct MomentCreationTransitionEvent: Equatable {
    let element: MomentCreationTransitionElement
    let action: MomentCreationTransitionAction
}

struct MomentCreationTransitionStage: Equatable {
    let anchor: MomentCreationTransitionStageAnchor
    let startMilliseconds: Int
    let durationMilliseconds: Int
    let events: [MomentCreationTransitionEvent]
}

struct MomentCreationTransitionPlan: Equatable {
    let route: MomentCreationTransitionRoute
    let kind: MomentCreationTransitionKind
    let containerTransition: MomentCreationContainerTransition
    let stages: [MomentCreationTransitionStage]
}

enum TransitionResolver {
    private static let captureFadeDuration = 500
    private static let stageGap = 100
    private static let contentDuration = 300
    private static let reminderStagger = 50

    static func resolveAfterCapture(for mode: MomentCreationMode) -> MomentCreationTransitionPlan {
        resolve(
            from: .capture,
            to: MomentCreationScreenStepResolver.stepAfterCapture(for: mode),
            direction: .forward
        )
    }

    static func resolve(
        from: MomentCreationScreenStep,
        to: MomentCreationScreenStep,
        direction: MomentCreationTransitionDirection
    ) -> MomentCreationTransitionPlan {
        guard direction == .forward else {
            return fallbackPlan(from: from, to: to, direction: direction)
        }

        switch (from, to) {
        case (.capture, .workflow(.albumName)):
            return captureEntryPlan(route: .captureToAlbumName, field: .albumNameField)
        case (.capture, .workflow(.note)):
            return captureEntryPlan(route: .captureToNote, field: .noteCard)
        case (.workflow(.albumName), .workflow(.note)):
            let buttonExitStart = contentDuration + stageGap
            let fieldEnterStart = buttonExitStart + contentDuration
            let buttonEnterStart = fieldEnterStart + contentDuration + stageGap

            return stagedPlan(
                route: .albumNameToNote,
                stages: [
                    stage(0, contentDuration, .init(element: .albumNameField, action: .exit)),
                    stage(buttonExitStart, contentDuration, .init(element: .primaryButton, action: .exit)),
                    stage(fieldEnterStart, contentDuration, .init(element: .noteCard, action: .enter)),
                    stage(buttonEnterStart, contentDuration, .init(element: .primaryButton, action: .enter))
                ]
            )
        case (.workflow(.note), .workflow(.reminder)):
            let noteExitStart = contentDuration + stageGap
            let buttonExitStart = noteExitStart + contentDuration + stageGap
            let reminderStart = buttonExitStart + contentDuration

            return stagedPlan(
                route: .noteToReminder,
                stages: [
                    stage(0, contentDuration, .init(element: .heroImage, action: .exit)),
                    stage(noteExitStart, contentDuration, .init(element: .noteCard, action: .exit)),
                    stage(buttonExitStart, contentDuration, .init(element: .primaryButton, action: .exit)),
                    stage(reminderStart, contentDuration, .init(element: .reminderTitle, action: .enter)),
                    stage(reminderStart + reminderStagger, contentDuration, .init(element: .reminderPicker, action: .enter)),
                    stage(reminderStart + (reminderStagger * 2), contentDuration, .init(element: .reminderDescription, action: .enter)),
                    stage(reminderStart + (reminderStagger * 3), contentDuration, .init(element: .reminderPrimaryButton, action: .enter)),
                    stage(reminderStart + (reminderStagger * 4), contentDuration, .init(element: .reminderSecondaryButton, action: .enter))
                ]
            )
        case (.workflow(.note), .workflow(.complete)):
            return completePushPlan(route: .noteToComplete)
        case (.workflow(.reminder), .workflow(.complete)):
            return completePushPlan(route: .reminderToComplete)
        default:
            return fallbackPlan(from: from, to: to, direction: direction)
        }
    }

    private static func captureEntryPlan(
        route: MomentCreationTransitionRoute,
        field: MomentCreationTransitionElement
    ) -> MomentCreationTransitionPlan {
        let heroEnterStart = captureFadeDuration
        let fieldEnterStart = heroEnterStart + stageGap
        let buttonEnterStart = fieldEnterStart + stageGap

        return stagedPlan(
            route: route,
            stages: [
                stage(
                    0,
                    captureFadeDuration,
                    .init(element: .background, action: .transition)
                ),
                stage(heroEnterStart, contentDuration, .init(element: .heroImage, action: .enter)),
                stage(fieldEnterStart, contentDuration, .init(element: field, action: .enter)),
                stage(buttonEnterStart, contentDuration, .init(element: .primaryButton, action: .enter))
            ]
        )
    }

    private static func completePushPlan(route: MomentCreationTransitionRoute) -> MomentCreationTransitionPlan {
        let timelineEnterStart = contentDuration + stageGap

        return MomentCreationTransitionPlan(
            route: route,
            kind: .push,
            containerTransition: .pushFromTrailing,
            stages: [
                stage(
                    0,
                    contentDuration,
                    anchor: .containerCompletion,
                    .init(element: .completeCard, action: .enter)
                ),
                stage(
                    timelineEnterStart,
                    contentDuration,
                    anchor: .containerCompletion,
                    .init(element: .completeTimeline, action: .enter)
                )
            ]
        )
    }

    private static func stagedPlan(
        route: MomentCreationTransitionRoute,
        stages: [MomentCreationTransitionStage]
    ) -> MomentCreationTransitionPlan {
        MomentCreationTransitionPlan(
            route: route,
            kind: .staged,
            containerTransition: .none,
            stages: stages
        )
    }

    private static func fallbackPlan(
        from: MomentCreationScreenStep,
        to: MomentCreationScreenStep,
        direction: MomentCreationTransitionDirection
    ) -> MomentCreationTransitionPlan {
        MomentCreationTransitionPlan(
            route: .fallback(from: from, to: to, direction: direction),
            kind: .fallback,
            containerTransition: .none,
            stages: []
        )
    }

    private static func stage(
        _ startMilliseconds: Int,
        _ durationMilliseconds: Int,
        anchor: MomentCreationTransitionStageAnchor = .routeStart,
        _ events: MomentCreationTransitionEvent...
    ) -> MomentCreationTransitionStage {
        MomentCreationTransitionStage(
            anchor: anchor,
            startMilliseconds: startMilliseconds,
            durationMilliseconds: durationMilliseconds,
            events: events
        )
    }
}
