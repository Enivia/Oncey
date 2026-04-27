import Foundation

enum MomentCreationFlowScenario: Equatable {
    case newAlbum
    case firstMomentInAlbum
    case laterMomentInAlbum
}

enum MomentCreationWorkflowStep: Hashable {
    case albumName
    case note
    case reminder
    case complete
}

enum MomentCreationScreenStep: Hashable {
    case capture
    case workflow(MomentCreationWorkflowStep)
}

enum MomentCreationFocusField: Hashable {
    case albumName
    case note
}

enum MomentCreationWorkflowLeadingAction: Equatable {
    case close
    case back
}

struct MomentCreationWorkflowChromeState: Equatable {
    let leadingAction: MomentCreationWorkflowLeadingAction
    let showsShare: Bool
}

enum MomentCreationFlowScenarioResolver {
    static func resolve(for mode: MomentCreationMode) -> MomentCreationFlowScenario {
        if mode.isCreatingAlbum {
            return .newAlbum
        }

        if mode.isCreatingFirstMoment {
            return .firstMomentInAlbum
        }

        return .laterMomentInAlbum
    }
}

enum MomentCreationWorkflowResolver {
    static func steps(for mode: MomentCreationMode) -> [MomentCreationWorkflowStep] {
        steps(for: MomentCreationFlowScenarioResolver.resolve(for: mode))
    }

    static func steps(for scenario: MomentCreationFlowScenario) -> [MomentCreationWorkflowStep] {
        switch scenario {
        case .newAlbum:
            return [.albumName, .note, .reminder, .complete]
        case .firstMomentInAlbum:
            return [.note, .reminder, .complete]
        case .laterMomentInAlbum:
            return [.note, .complete]
        }
    }

    static func initialStep(for mode: MomentCreationMode) -> MomentCreationWorkflowStep {
        steps(for: mode).first ?? .note
    }

    static func progressIndex(for step: MomentCreationWorkflowStep, in mode: MomentCreationMode) -> Int? {
        steps(for: mode).firstIndex(of: step)
    }

    static func previousStep(
        before step: MomentCreationWorkflowStep,
        in mode: MomentCreationMode
    ) -> MomentCreationWorkflowStep? {
        let steps = steps(for: mode)

        guard let currentIndex = steps.firstIndex(of: step), currentIndex > 0 else {
            return nil
        }

        return steps[currentIndex - 1]
    }
}

enum MomentCreationWorkflowChromeResolver {
    static func resolve(for step: MomentCreationWorkflowStep) -> MomentCreationWorkflowChromeState {
        switch step {
        case .albumName:
            return MomentCreationWorkflowChromeState(leadingAction: .close, showsShare: false)
        case .note, .reminder:
            return MomentCreationWorkflowChromeState(leadingAction: .back, showsShare: false)
        case .complete:
            return MomentCreationWorkflowChromeState(leadingAction: .close, showsShare: true)
        }
    }
}

enum MomentCreationScreenStepResolver {
    static func stepAfterCapture(for mode: MomentCreationMode) -> MomentCreationScreenStep {
        .workflow(MomentCreationWorkflowResolver.initialStep(for: mode))
    }

    static func previousStep(from step: MomentCreationScreenStep, in mode: MomentCreationMode) -> MomentCreationScreenStep? {
        switch step {
        case .capture:
            return nil
        case .workflow(let workflowStep):
            if let previousWorkflowStep = MomentCreationWorkflowResolver.previousStep(before: workflowStep, in: mode) {
                return .workflow(previousWorkflowStep)
            }

            return .capture
        }
    }
}