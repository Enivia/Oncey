import Testing
@testable import Oncey

@MainActor
struct MomentCreationCaptureChromeTests {

    @Test func cameraCaptureStateLocksAspectUntilCaptureFinishes() {
        var state = MomentCreationCameraCaptureState()

        let lockedAspect = state.beginCapture(selectedAspect: .threeByFour)
        let secondAttempt = state.beginCapture(selectedAspect: .square)

        #expect(lockedAspect == .threeByFour)
        #expect(secondAttempt == nil)
        #expect(state.isCaptureInProgress)

        state.finishCapture()

        let restartedAspect = state.beginCapture(selectedAspect: .square)

        #expect(restartedAspect == .square)
        #expect(state.isCaptureInProgress)
    }

    @Test func liveCaptureForAlbumCreationShowsCloseFlashAspectAndControls() {
        let chrome = MomentCreationCaptureChromeResolver.resolve(
            previewKind: .live,
            allowsAspectSelection: true,
            showsOverlaySlider: false
        )

        #expect(chrome.leadingAction == .close)
        #expect(chrome.showsFlash)
        #expect(chrome.showsAspectButton)
        #expect(!chrome.showsConfirmButton)
        #expect(!chrome.showsMaskSlider)
        #expect(chrome.showsCaptureControls)
    }

    @Test func captureInteractivityLocksLiveControlsWhileCaptureIsInFlight() {
        let chrome = MomentCreationCaptureChromeResolver.resolve(
            previewKind: .live,
            allowsAspectSelection: true,
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
        #expect(!lockedInteractivity.allowsAspectToggle)
        #expect(!lockedInteractivity.allowsPhotoPicker)
        #expect(!lockedInteractivity.allowsShutter)
        #expect(!lockedInteractivity.allowsCameraToggle)

        #expect(restoredInteractivity.allowsFlashToggle)
        #expect(restoredInteractivity.allowsAspectToggle)
        #expect(restoredInteractivity.allowsPhotoPicker)
        #expect(restoredInteractivity.allowsShutter)
        #expect(restoredInteractivity.allowsCameraToggle)
    }

    @Test func liveCaptureForLaterMomentShowsMaskWithoutAspectButton() {
        let chrome = MomentCreationCaptureChromeResolver.resolve(
            previewKind: .live,
            allowsAspectSelection: false,
            showsOverlaySlider: true
        )

        #expect(chrome.leadingAction == .close)
        #expect(chrome.showsFlash)
        #expect(!chrome.showsAspectButton)
        #expect(!chrome.showsConfirmButton)
        #expect(chrome.showsMaskSlider)
        #expect(chrome.showsCaptureControls)
    }

    @Test func cameraPreviewShowsBackAndConfirmOnly() {
        let chrome = MomentCreationCaptureChromeResolver.resolve(
            previewKind: .cameraPreview,
            allowsAspectSelection: true,
            showsOverlaySlider: true
        )

        #expect(chrome.leadingAction == .backToCapture)
        #expect(!chrome.showsFlash)
        #expect(!chrome.showsAspectButton)
        #expect(chrome.showsConfirmButton)
        #expect(!chrome.showsMaskSlider)
        #expect(!chrome.showsCaptureControls)
    }

    @Test func photoLibraryCropKeepsAspectButtonOnlyWhenSelectionIsAllowed() {
        let adjustableChrome = MomentCreationCaptureChromeResolver.resolve(
            previewKind: .photoLibraryCrop,
            allowsAspectSelection: true,
            showsOverlaySlider: true
        )
        let fixedChrome = MomentCreationCaptureChromeResolver.resolve(
            previewKind: .photoLibraryCrop,
            allowsAspectSelection: false,
            showsOverlaySlider: true
        )

        #expect(adjustableChrome.leadingAction == .backToCapture)
        #expect(adjustableChrome.showsAspectButton)
        #expect(adjustableChrome.showsConfirmButton)
        #expect(!fixedChrome.showsAspectButton)
        #expect(fixedChrome.showsConfirmButton)
        #expect(!fixedChrome.showsMaskSlider)
    }

    @Test func locationRefreshPolicyOnlyRequestsOnceWhenEnteringNote() {
        #expect(MomentCreationLocationRefreshPolicy.shouldRefreshLocation(for: .note, hasAutoRequestedLocation: false))
        #expect(!MomentCreationLocationRefreshPolicy.shouldRefreshLocation(for: .reminder, hasAutoRequestedLocation: false))
        #expect(!MomentCreationLocationRefreshPolicy.shouldRefreshLocation(for: .note, hasAutoRequestedLocation: true))
    }
}