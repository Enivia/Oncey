import Testing
@testable import Oncey

@MainActor
struct MomentCreationCaptureChromeTests {

    @Test func cameraCaptureStateLocksUntilCaptureFinishes() {
        var state = MomentCreationCameraCaptureState()

        let startedCapture = state.beginCapture()
        let secondAttempt = state.beginCapture()

        #expect(startedCapture)
        #expect(!secondAttempt)
        #expect(state.isCaptureInProgress)

        state.finishCapture()

        let restartedCapture = state.beginCapture()

        #expect(restartedCapture)
        #expect(state.isCaptureInProgress)
    }

    @Test func liveCaptureForAlbumCreationShowsCloseFlashAndControls() {
        let chrome = MomentCreationCaptureChromeResolver.resolve(
            previewKind: .live,
            showsOverlaySlider: false
        )

        #expect(chrome.leadingAction == .close)
        #expect(chrome.showsFlash)
        #expect(!chrome.showsConfirmButton)
        #expect(!chrome.showsMaskSlider)
        #expect(chrome.showsCaptureControls)
    }

    @Test func captureInteractivityLocksLiveControlsWhileCaptureIsInFlight() {
        let chrome = MomentCreationCaptureChromeResolver.resolve(
            previewKind: .live,
            showsOverlaySlider: true
        )
        let lockedInteractivity = MomentCreationCaptureInteractivityResolver.resolve(
            chrome: chrome,
            isCaptureInProgress: true,
            isCameraAuthorized: true,
            isSessionConfigured: true,
            isFlashAvailable: true
        )
        let restoredInteractivity = MomentCreationCaptureInteractivityResolver.resolve(
            chrome: chrome,
            isCaptureInProgress: false,
            isCameraAuthorized: true,
            isSessionConfigured: true,
            isFlashAvailable: true
        )

        #expect(!lockedInteractivity.allowsFlashToggle)
        #expect(!lockedInteractivity.allowsPhotoPicker)
        #expect(!lockedInteractivity.allowsShutter)
        #expect(!lockedInteractivity.allowsCameraToggle)

        #expect(restoredInteractivity.allowsFlashToggle)
        #expect(restoredInteractivity.allowsPhotoPicker)
        #expect(restoredInteractivity.allowsShutter)
        #expect(restoredInteractivity.allowsCameraToggle)
    }

    @Test func liveCaptureForLaterMomentShowsMask() {
        let chrome = MomentCreationCaptureChromeResolver.resolve(
            previewKind: .live,
            showsOverlaySlider: true
        )

        #expect(chrome.leadingAction == .close)
        #expect(chrome.showsFlash)
        #expect(!chrome.showsConfirmButton)
        #expect(chrome.showsMaskSlider)
        #expect(chrome.showsCaptureControls)
    }

    @Test func cameraPreviewShowsBackAndConfirmOnly() {
        let chrome = MomentCreationCaptureChromeResolver.resolve(
            previewKind: .cameraPreview,
            showsOverlaySlider: true
        )

        #expect(chrome.leadingAction == .backToCapture)
        #expect(!chrome.showsFlash)
        #expect(chrome.showsConfirmButton)
        #expect(!chrome.showsMaskSlider)
        #expect(!chrome.showsCaptureControls)
    }

    @Test func photoLibraryCropShowsBackAndConfirmWithoutCaptureControls() {
        let chrome = MomentCreationCaptureChromeResolver.resolve(
            previewKind: .photoLibraryCrop,
            showsOverlaySlider: true
        )

        #expect(chrome.leadingAction == .backToCapture)
        #expect(!chrome.showsFlash)
        #expect(chrome.showsConfirmButton)
        #expect(!chrome.showsMaskSlider)
        #expect(!chrome.showsCaptureControls)
    }
}