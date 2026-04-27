import Testing
@testable import Oncey

@MainActor
struct MomentCreationWorkflowResolverTests {

    @Test func newAlbumUsesAlbumNameNoteReminderCompleteWorkflow() {
        let mode = MomentCreationMode.newAlbum

        #expect(MomentCreationFlowScenarioResolver.resolve(for: mode) == .newAlbum)
        #expect(MomentCreationWorkflowResolver.steps(for: mode) == [.albumName, .note, .reminder, .complete])
    }

    @Test func firstMomentUsesNoteReminderCompleteWorkflow() {
        let album = Album(name: "First Moment Album")
        let mode = MomentCreationMode.newMoment(album: album)

        #expect(MomentCreationFlowScenarioResolver.resolve(for: mode) == .firstMomentInAlbum)
        #expect(MomentCreationWorkflowResolver.steps(for: mode) == [.note, .reminder, .complete])
    }

    @Test func laterMomentUsesNoteCompleteWorkflow() {
        let album = makeAlbumWithMoment()
        let mode = MomentCreationMode.newMoment(album: album)

        #expect(MomentCreationFlowScenarioResolver.resolve(for: mode) == .laterMomentInAlbum)
        #expect(MomentCreationWorkflowResolver.steps(for: mode) == [.note, .complete])
    }

    @Test func progressIndexStartsAtZeroForWorkflowSteps() {
        let mode = MomentCreationMode.newAlbum

        #expect(MomentCreationWorkflowResolver.progressIndex(for: .albumName, in: mode) == 0)
        #expect(MomentCreationWorkflowResolver.progressIndex(for: .note, in: mode) == 1)
        #expect(MomentCreationWorkflowResolver.progressIndex(for: .reminder, in: mode) == 2)
        #expect(MomentCreationWorkflowResolver.progressIndex(for: .complete, in: mode) == 3)
    }

    @Test func previousStepResolvesWorkflowBackPathPerScenario() {
        let newAlbum = MomentCreationMode.newAlbum
        let firstMoment = MomentCreationMode.newMoment(album: Album(name: "First"))
        let laterMoment = MomentCreationMode.newMoment(album: makeAlbumWithMoment())

        #expect(MomentCreationWorkflowResolver.previousStep(before: .albumName, in: newAlbum) == nil)
        #expect(MomentCreationWorkflowResolver.previousStep(before: .note, in: newAlbum) == .albumName)
        #expect(MomentCreationWorkflowResolver.previousStep(before: .reminder, in: newAlbum) == .note)
        #expect(MomentCreationWorkflowResolver.previousStep(before: .complete, in: newAlbum) == .reminder)

        #expect(MomentCreationWorkflowResolver.previousStep(before: .note, in: firstMoment) == nil)
        #expect(MomentCreationWorkflowResolver.previousStep(before: .reminder, in: firstMoment) == .note)
        #expect(MomentCreationWorkflowResolver.previousStep(before: .complete, in: firstMoment) == .reminder)

        #expect(MomentCreationWorkflowResolver.previousStep(before: .note, in: laterMoment) == nil)
        #expect(MomentCreationWorkflowResolver.previousStep(before: .complete, in: laterMoment) == .note)
    }

    @Test func initialWorkflowStepMatchesScenarioEntryPoint() {
        #expect(MomentCreationWorkflowResolver.initialStep(for: .newAlbum) == .albumName)
        #expect(MomentCreationWorkflowResolver.initialStep(for: .newMoment(album: Album(name: "First"))) == .note)
        #expect(MomentCreationWorkflowResolver.initialStep(for: .newMoment(album: makeAlbumWithMoment())) == .note)
    }

    @Test func workflowChromeMatchesPerStepNavigationRules() {
        let albumName = MomentCreationWorkflowChromeResolver.resolve(for: .albumName)
        let note = MomentCreationWorkflowChromeResolver.resolve(for: .note)
        let reminder = MomentCreationWorkflowChromeResolver.resolve(for: .reminder)
        let complete = MomentCreationWorkflowChromeResolver.resolve(for: .complete)

        #expect(albumName.leadingAction == .close)
        #expect(!albumName.showsShare)

        #expect(note.leadingAction == .back)
        #expect(!note.showsShare)

        #expect(reminder.leadingAction == .back)
        #expect(!reminder.showsShare)

        #expect(complete.leadingAction == .close)
        #expect(complete.showsShare)
    }

    @Test func screenStepResolverBridgesCaptureAndWorkflowSteps() {
        let newAlbum = MomentCreationMode.newAlbum
        let firstMoment = MomentCreationMode.newMoment(album: Album(name: "First"))
        let laterMoment = MomentCreationMode.newMoment(album: makeAlbumWithMoment())

        #expect(MomentCreationScreenStepResolver.stepAfterCapture(for: newAlbum) == .workflow(.albumName))
        #expect(MomentCreationScreenStepResolver.stepAfterCapture(for: firstMoment) == .workflow(.note))
        #expect(MomentCreationScreenStepResolver.stepAfterCapture(for: laterMoment) == .workflow(.note))

        #expect(MomentCreationScreenStepResolver.previousStep(from: .workflow(.albumName), in: newAlbum) == .capture)
        #expect(MomentCreationScreenStepResolver.previousStep(from: .workflow(.note), in: firstMoment) == .capture)
        #expect(MomentCreationScreenStepResolver.previousStep(from: .workflow(.complete), in: laterMoment) == .workflow(.note))
    }

    private func makeAlbumWithMoment() -> Album {
        let album = Album(name: "Existing Album")
        _ = Moment(album: album, photo: "/tmp/existing.jpg", note: "Existing note")
        return album
    }
}