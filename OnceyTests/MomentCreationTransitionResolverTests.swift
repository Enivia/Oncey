import Testing
@testable import Oncey

@MainActor
struct MomentCreationTransitionResolverTests {

    @Test func captureRoutesFollowWorkflowEntryPointForEachMode() {
        let newAlbumPlan = TransitionResolver.resolveAfterCapture(for: .newAlbum)
        let firstMomentPlan = TransitionResolver.resolveAfterCapture(
            for: .newMoment(album: Album(name: "First"))
        )
        let laterMomentPlan = TransitionResolver.resolveAfterCapture(
            for: .newMoment(album: makeAlbumWithMoment())
        )

        #expect(newAlbumPlan.route == .captureToAlbumName)
        #expect(newAlbumPlan.kind == .staged)
        #expect(newAlbumPlan.containerTransition == .none)
        #expect(firstMomentPlan.route == .captureToNote)
        #expect(firstMomentPlan.kind == .staged)
        #expect(firstMomentPlan.containerTransition == .none)
        #expect(laterMomentPlan.route == .captureToNote)
        #expect(laterMomentPlan.kind == .staged)
        #expect(laterMomentPlan.containerTransition == .none)
    }

    @Test func captureEntryStagesWaitForHeroTransitionBeforeShowingFieldAndButton() {
        let albumNamePlan = TransitionResolver.resolve(
            from: .capture,
            to: .workflow(.albumName),
            direction: .forward
        )
        let notePlan = TransitionResolver.resolve(
            from: .capture,
            to: .workflow(.note),
            direction: .forward
        )

        #expect(albumNamePlan.stages == [
            .init(
                anchor: .routeStart,
                startMilliseconds: 0,
                durationMilliseconds: 500,
                events: [
                    .init(element: .background, action: .transition)
                ]
            ),
            .init(
                anchor: .routeStart,
                startMilliseconds: 500,
                durationMilliseconds: 300,
                events: [
                    .init(element: .heroImage, action: .enter)
                ]
            ),
            .init(
                anchor: .routeStart,
                startMilliseconds: 600,
                durationMilliseconds: 300,
                events: [
                    .init(element: .albumNameField, action: .enter)
                ]
            ),
            .init(
                anchor: .routeStart,
                startMilliseconds: 700,
                durationMilliseconds: 300,
                events: [
                    .init(element: .primaryButton, action: .enter)
                ]
            )
        ])

        #expect(notePlan.stages == [
            .init(
                anchor: .routeStart,
                startMilliseconds: 0,
                durationMilliseconds: 500,
                events: [
                    .init(element: .background, action: .transition)
                ]
            ),
            .init(
                anchor: .routeStart,
                startMilliseconds: 500,
                durationMilliseconds: 300,
                events: [
                    .init(element: .heroImage, action: .enter)
                ]
            ),
            .init(
                anchor: .routeStart,
                startMilliseconds: 600,
                durationMilliseconds: 300,
                events: [
                    .init(element: .noteCard, action: .enter)
                ]
            ),
            .init(
                anchor: .routeStart,
                startMilliseconds: 700,
                durationMilliseconds: 300,
                events: [
                    .init(element: .primaryButton, action: .enter)
                ]
            )
        ])
    }

    @Test func captureEntryStartsWithHiddenHeroAndControls() {
        let albumNamePhases = TransitionStateResolver.initialPhases(
            for: .workflow(.albumName),
            route: .captureToAlbumName
        )
        let notePhases = TransitionStateResolver.initialPhases(
            for: .workflow(.note),
            route: .captureToNote
        )

        #expect(albumNamePhases[.heroImage] == .hiddenBelow)
        #expect(albumNamePhases[.albumNameField] == .hiddenBelow)
        #expect(albumNamePhases[.primaryButton] == .hiddenBelow)

        #expect(notePhases[.heroImage] == .hiddenBelow)
        #expect(notePhases[.noteCard] == .hiddenBelow)
        #expect(notePhases[.primaryButton] == .hiddenBelow)
    }

    @Test func captureEntryFocusWaitsUntilWholeEntranceFinishes() {
        let albumNamePlan = TransitionResolver.resolve(
            from: .capture,
            to: .workflow(.albumName),
            direction: .forward
        )
        let notePlan = TransitionResolver.resolve(
            from: .capture,
            to: .workflow(.note),
            direction: .forward
        )

        #expect(
            TransitionStateResolver.focusDelayMilliseconds(
                for: .workflow(.albumName),
                plan: albumNamePlan
            ) == 1050
        )
        #expect(
            TransitionStateResolver.focusDelayMilliseconds(
                for: .workflow(.note),
                plan: notePlan
            ) == 1050
        )
    }

    @Test func albumNameToNoteFocusWaitsUntilWholeTransitionFinishes() {
        let plan = TransitionResolver.resolve(
            from: .workflow(.albumName),
            to: .workflow(.note),
            direction: .forward
        )

        #expect(
            TransitionStateResolver.focusDelayMilliseconds(
                for: .workflow(.note),
                plan: plan
            ) == 1450
        )
    }

    @Test func albumNameToNoteUsesSequentialExitAndEntryStages() {
        let plan = TransitionResolver.resolve(
            from: .workflow(.albumName),
            to: .workflow(.note),
            direction: .forward
        )

        #expect(plan.route == .albumNameToNote)
        #expect(plan.kind == .staged)
        #expect(plan.stages == [
            .init(
                anchor: .routeStart,
                startMilliseconds: 0,
                durationMilliseconds: 300,
                events: [
                    .init(element: .albumNameField, action: .exit)
                ]
            ),
            .init(
                anchor: .routeStart,
                startMilliseconds: 400,
                durationMilliseconds: 300,
                events: [
                    .init(element: .primaryButton, action: .exit)
                ]
            ),
            .init(
                anchor: .routeStart,
                startMilliseconds: 700,
                durationMilliseconds: 300,
                events: [
                    .init(element: .noteCard, action: .enter)
                ]
            ),
            .init(
                anchor: .routeStart,
                startMilliseconds: 1100,
                durationMilliseconds: 300,
                events: [
                    .init(element: .primaryButton, action: .enter)
                ]
            )
        ])
    }

    @Test func noteToReminderUsesExitStagesBeforeReminderContentAppears() {
        let plan = TransitionResolver.resolve(
            from: .workflow(.note),
            to: .workflow(.reminder),
            direction: .forward
        )

        #expect(plan.route == .noteToReminder)
        #expect(plan.kind == .staged)
        #expect(plan.stages.prefix(3) == [
            .init(
                anchor: .routeStart,
                startMilliseconds: 0,
                durationMilliseconds: 300,
                events: [
                    .init(element: .heroImage, action: .exit)
                ]
            ),
            .init(
                anchor: .routeStart,
                startMilliseconds: 400,
                durationMilliseconds: 300,
                events: [
                    .init(element: .noteCard, action: .exit)
                ]
            ),
            .init(
                anchor: .routeStart,
                startMilliseconds: 800,
                durationMilliseconds: 300,
                events: [
                    .init(element: .primaryButton, action: .exit)
                ]
            )
        ])
    }

    @Test func completeRoutesStayAsForwardPushWithStagedContent() {
        let notePlan = TransitionResolver.resolve(
            from: .workflow(.note),
            to: .workflow(.complete),
            direction: .forward
        )
        let reminderPlan = TransitionResolver.resolve(
            from: .workflow(.reminder),
            to: .workflow(.complete),
            direction: .forward
        )

        let expectedStages: [MomentCreationTransitionStage] = [
            .init(
                anchor: .containerCompletion,
                startMilliseconds: 0,
                durationMilliseconds: 300,
                events: [
                    .init(element: .completeCard, action: .enter)
                ]
            ),
            .init(
                anchor: .containerCompletion,
                startMilliseconds: 400,
                durationMilliseconds: 300,
                events: [
                    .init(element: .completeTimeline, action: .enter)
                ]
            )
        ]

        #expect(notePlan.route == .noteToComplete)
        #expect(notePlan.kind == .push)
        #expect(notePlan.containerTransition == .pushFromTrailing)
        #expect(notePlan.stages == expectedStages)

        #expect(reminderPlan.route == .reminderToComplete)
        #expect(reminderPlan.kind == .push)
        #expect(reminderPlan.containerTransition == .pushFromTrailing)
        #expect(reminderPlan.stages == expectedStages)
    }

    @Test func backwardAndUnknownRoutesUseFallbackPlan() {
        let backwardPlan = TransitionResolver.resolve(
            from: .workflow(.reminder),
            to: .workflow(.note),
            direction: .backward
        )
        let unknownForwardPlan = TransitionResolver.resolve(
            from: .workflow(.albumName),
            to: .workflow(.complete),
            direction: .forward
        )

        #expect(backwardPlan.kind == .fallback)
        #expect(backwardPlan.route == .fallback(
            from: .workflow(.reminder),
            to: .workflow(.note),
            direction: .backward
        ))
        #expect(backwardPlan.stages.isEmpty)

        #expect(unknownForwardPlan.kind == .fallback)
        #expect(unknownForwardPlan.route == .fallback(
            from: .workflow(.albumName),
            to: .workflow(.complete),
            direction: .forward
        ))
        #expect(unknownForwardPlan.stages.isEmpty)
    }

    @Test func reminderStagesUseFiftyMillisecondStagger() {
        let plan = TransitionResolver.resolve(
            from: .workflow(.note),
            to: .workflow(.reminder),
            direction: .forward
        )

        #expect(Array(plan.stages.suffix(5)) == [
            .init(
                anchor: .routeStart,
                startMilliseconds: 1100,
                durationMilliseconds: 300,
                events: [
                    .init(element: .reminderTitle, action: .enter)
                ]
            ),
            .init(
                anchor: .routeStart,
                startMilliseconds: 1150,
                durationMilliseconds: 300,
                events: [
                    .init(element: .reminderPicker, action: .enter)
                ]
            ),
            .init(
                anchor: .routeStart,
                startMilliseconds: 1200,
                durationMilliseconds: 300,
                events: [
                    .init(element: .reminderDescription, action: .enter)
                ]
            ),
            .init(
                anchor: .routeStart,
                startMilliseconds: 1250,
                durationMilliseconds: 300,
                events: [
                    .init(element: .reminderPrimaryButton, action: .enter)
                ]
            ),
            .init(
                anchor: .routeStart,
                startMilliseconds: 1300,
                durationMilliseconds: 300,
                events: [
                    .init(element: .reminderSecondaryButton, action: .enter)
                ]
            )
        ])
    }

    private func makeAlbumWithMoment() -> Album {
        let album = Album(name: "Existing Album")
        _ = Moment(album: album, photo: "/tmp/existing.jpg", note: "Existing note")
        return album
    }
}
