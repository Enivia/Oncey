#if os(iOS)
import PhotosUI
import SwiftData
import SwiftUI
import UIKit

enum MomentCreationMode {
    case newAlbum
    case newMoment(album: Album)

    var album: Album? {
        switch self {
        case .newAlbum:
            return nil

        case .newMoment(let album):
            return album
        }
    }

    var latestMoment: Moment? {
        album?.moments.max { lhs, rhs in
            if lhs.createdAt == rhs.createdAt {
                return lhs.updatedAt < rhs.updatedAt
            }

            return lhs.createdAt < rhs.createdAt
        }
    }

    var isCreatingAlbum: Bool {
        if case .newAlbum = self {
            return true
        }

        return false
    }

    var isCreatingFirstMoment: Bool {
        guard case .newMoment(let album) = self else {
            return false
        }

        return album.moments.isEmpty
    }

    var showsAlbumConfigurationStep: Bool {
        isCreatingAlbum || isCreatingFirstMoment
    }

    var showsAlbumNameField: Bool {
        isCreatingAlbum
    }
}

enum MomentCreationStep: Hashable {
    case capture
    case configuration
    case note
    case success
}

enum MomentCreationCapturePreviewKind: Equatable {
    case live
    case cameraPreview
    case photoLibraryCrop
}

enum MomentCreationCaptureLeadingAction: Equatable {
    case close
    case backToCapture
}

struct MomentCreationCaptureChromeState: Equatable {
    let leadingAction: MomentCreationCaptureLeadingAction
    let showsFlash: Bool
    let showsAspectButton: Bool
    let showsConfirmButton: Bool
    let showsMaskSlider: Bool
    let showsCaptureControls: Bool
}

enum MomentCreationCaptureChromeResolver {
    static func resolve(
        previewKind: MomentCreationCapturePreviewKind,
        allowsAspectSelection: Bool,
        showsOverlaySlider: Bool
    ) -> MomentCreationCaptureChromeState {
        switch previewKind {
        case .live:
            return MomentCreationCaptureChromeState(
                leadingAction: .close,
                showsFlash: true,
                showsAspectButton: allowsAspectSelection,
                showsConfirmButton: false,
                showsMaskSlider: showsOverlaySlider,
                showsCaptureControls: true
            )
        case .cameraPreview:
            return MomentCreationCaptureChromeState(
                leadingAction: .backToCapture,
                showsFlash: false,
                showsAspectButton: false,
                showsConfirmButton: true,
                showsMaskSlider: false,
                showsCaptureControls: false
            )
        case .photoLibraryCrop:
            return MomentCreationCaptureChromeState(
                leadingAction: .backToCapture,
                showsFlash: false,
                showsAspectButton: allowsAspectSelection,
                showsConfirmButton: true,
                showsMaskSlider: false,
                showsCaptureControls: false
            )
        }
    }
}

struct MomentCreationCameraCaptureState: Equatable {
    private(set) var lockedAspect: CameraCaptureAspect?

    var isCaptureInProgress: Bool {
        lockedAspect != nil
    }

    mutating func beginCapture(selectedAspect: CameraCaptureAspect) -> CameraCaptureAspect? {
        guard lockedAspect == nil else {
            return nil
        }

        lockedAspect = selectedAspect
        return selectedAspect
    }

    mutating func finishCapture() {
        lockedAspect = nil
    }
}

struct MomentCreationCaptureInteractivityState: Equatable {
    let allowsFlashToggle: Bool
    let allowsAspectToggle: Bool
    let allowsPhotoPicker: Bool
    let allowsShutter: Bool
    let allowsCameraToggle: Bool
}

enum MomentCreationCaptureInteractivityResolver {
    static func resolve(
        chrome: MomentCreationCaptureChromeState,
        isCaptureInProgress: Bool,
        isCameraAuthorized: Bool,
        isSessionConfigured: Bool,
        isFlashAvailable: Bool
    ) -> MomentCreationCaptureInteractivityState {
        let captureControlsAvailable = chrome.showsCaptureControls && !isCaptureInProgress
        let liveCameraReady = isCameraAuthorized && isSessionConfigured

        return MomentCreationCaptureInteractivityState(
            allowsFlashToggle: chrome.showsFlash && !isCaptureInProgress && isFlashAvailable,
            allowsAspectToggle: chrome.showsAspectButton && !isCaptureInProgress,
            allowsPhotoPicker: captureControlsAvailable,
            allowsShutter: captureControlsAvailable && liveCameraReady,
            allowsCameraToggle: captureControlsAvailable && isCameraAuthorized
        )
    }
}

private enum ReminderDecision {
    case untouched
    case skip
    case set
}

private struct ReminderSelection {
    let value: Int
    let unit: AlbumReminderUnit
}

private enum MomentCreationNavigationDirection {
    case forward
    case backward
}

private enum MomentCreationCaptureSource {
    case camera
    case photoLibrary
}

private struct MomentCreationCaptureDraft {
    let id = UUID()
    let image: UIImage
    let source: MomentCreationCaptureSource
}

private enum MomentCreationPreviewCropMode {
    case none
    case adjustable
    case fixed(CameraCaptureAspect)
}

private struct MomentCreationPendingShareInput: Identifiable, Hashable {
    let id = UUID()
    let moment: Moment

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

private struct MomentCreationCaptureLayout: Equatable {
    let stageSize: CGSize
    let referenceRect: CGRect
    let frameRect: CGRect
    let previewSize: CGSize
    let cropSize: CGSize
}

struct CreationView: View {
    private static let imageProcessingQueue = DispatchQueue(
        label: "Oncey.Creation.image-processing",
        qos: .userInitiated
    )

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focusedField: MomentCreationFocusField?
    @Namespace private var creationAnimation
    @StateObject private var camera = CameraSessionController()

    let mode: MomentCreationMode
    let onComplete: (Album) -> Void
    let reminderClient: AlbumReminderClient

    @State private var currentStep: MomentCreationScreenStep = .capture
    @State private var albumName: String
    @State private var note = ""
    @State private var selectedAspect: CameraCaptureAspect
    @State private var selectedPhotoOrientation: MomentPhotoOrientation
    @State private var captureDraft: MomentCreationCaptureDraft?
    @State private var cachedCaptureLayout: MomentCreationCaptureLayout?
    @State private var cameraCaptureState = MomentCreationCameraCaptureState()
    @State private var preparedImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var captureCropOffset: CGSize = .zero
    @State private var committedCaptureCropOffset: CGSize = .zero
    @State private var captureCropZoomScale: CGFloat = 1
    @State private var committedCaptureCropZoomScale: CGFloat = 1
    @State private var navigationDirection: MomentCreationNavigationDirection = .forward
    @State private var isCaptureFlashVisible = false
    @State private var overlayOpacity = 0.3
    @State private var reminderValue: Int
    @State private var reminderUnit: AlbumReminderUnit
    @State private var reminderDecision: ReminderDecision = .untouched
    @State private var reminderAuthorizationGranted: Bool?
    @State private var isSaving = false
    @State private var createdAlbum: Album?
    @State private var createdMoment: Moment?
    @State private var pendingShareInput: MomentCreationPendingShareInput?
    @State private var previousMoment: Moment?
    @State private var reminderScheduleOutcome: AlbumReminderScheduleOutcome?
    @State private var errorMessage: String?
    @State private var isPresentingError = false
    @State private var activeTransitionPlan: MomentCreationTransitionPlan?
    @State private var transitionSourceStep: MomentCreationScreenStep?
    @State private var transitionDestinationStep: MomentCreationScreenStep?
    @State private var transitionElementPhases: [MomentCreationScreenStep: MomentCreationTransitionElementPhases] = [:]
    @State private var transitionBackgroundOpacity = 0.0
    @State private var transitionSourceOpacity = 1.0
    @State private var transitionTask: Task<Void, Never>?
    @State private var focusTask: Task<Void, Never>?

    init(
        mode: MomentCreationMode,
        onComplete: @escaping (Album) -> Void = { _ in },
        reminderClient: AlbumReminderClient = AlbumReminderClient.live()
    ) {
        self.mode = mode
        self.onComplete = onComplete
        self.reminderClient = reminderClient

        let selection = Self.initialReminderSelection(for: mode)
        _albumName = State(initialValue: mode.album?.name ?? "")
        _selectedAspect = State(initialValue: Self.initialAspect(for: mode))
        _selectedPhotoOrientation = State(initialValue: Self.initialOrientation(for: mode))
        _reminderValue = State(initialValue: selection.value)
        _reminderUnit = State(initialValue: selection.unit)
    }

    var body: some View {
        alertConfiguredContent
    }

    private var alertConfiguredContent: some View {
        lifecycleConfiguredContent
        .alert("Something went wrong", isPresented: $isPresentingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }

    private var lifecycleConfiguredContent: some View {
        navigationConfiguredContent
            .onAppear {
                handleCurrentStepChange(currentStep)
            }
            .onDisappear {
                transitionTask?.cancel()
                focusTask?.cancel()
                camera.deactivate()
            }
            .onChange(of: currentStep) { _, newValue in
                handleCurrentStepChange(newValue)
            }
            .onChange(of: selectedPhotoItem) { _, newValue in
                guard let newValue else {
                    return
                }

                Task {
                    await loadSelectedImage(from: newValue)
                }
            }
            .onChange(of: isShowingCapturePreview) { _, _ in
                updateCameraLifecycle(for: currentStep)
            }
            .onChange(of: selectedAspect) { _, _ in
                preparedImage = nil

                if isShowingInteractiveCaptureCrop {
                    resetCaptureCropTransform()
                }
            }
            .onChange(of: selectedPhotoOrientation) { _, _ in
                preparedImage = nil

                if isShowingInteractiveCaptureCrop {
                    resetCaptureCropTransform()
                }
            }
            .onChange(of: camera.errorMessage) { _, newValue in
                guard let newValue else {
                    return
                }

                present(newValue)
            }
    }

    private var navigationConfiguredContent: some View {
        contentRoot
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar { toolbarContent }
            .toolbarBackground(isCaptureStep ? .hidden : .visible, for: .navigationBar)
            .toolbarColorScheme(isCaptureStep ? .dark : .light, for: .navigationBar)
            .navigationDestination(item: $pendingShareInput) { input in
                MomentShareView(moment: input.moment)
            }
    }

    private var contentRoot: some View {
        ZStack {
            backgroundView
            contentStack
        }
    }

    private var contentStack: some View {
        VStack(spacing: AppTheme.Spacing.s6) {
            stepContent
        }
        .padding(.bottom, isCaptureStep ? 0 : AppTheme.Spacing.s6)
    }

    private var backgroundView: AnyView {
        if isCaptureEntryTransitionActive {
            return AnyView(
                ZStack {
                    Color.black.ignoresSafeArea()
                    AppPageBackground().opacity(transitionBackgroundOpacity)
                }
            )
        }

        if isCaptureStep {
            return AnyView(Color.black.ignoresSafeArea())
        }

        return AnyView(AppPageBackground())
    }

    private var stepContent: AnyView {
        let content: AnyView

        if let sourceStep = transitionSourceStep,
           let destinationStep = transitionDestinationStep,
           activeTransitionPlan?.kind == .staged {
            content = AnyView(stagedTransitionContent(from: sourceStep, to: destinationStep))
        } else {
            content = AnyView(singleStepContent(for: currentStep).transition(stepTransition))
        }

        return AnyView(
            ZStack {
                content
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .allowsHitTesting(activeTransitionPlan == nil)
        )
    }

    private func workflowStepContent(
        _ step: MomentCreationWorkflowStep,
        screenStep: MomentCreationScreenStep
    ) -> AnyView {
        let elementPhases = phases(for: screenStep)

        switch step {
        case .albumName:
            return AnyView(
                AlbumNameStepView(
                    focus: $focusedField,
                    elementPhases: elementPhases,
                    reduceMotion: reduceMotion,
                    albumName: $albumName
                )
            )
        case .note:
            return AnyView(
                NoteStepView(
                    namespace: creationAnimation,
                    focus: $focusedField,
                    elementPhases: elementPhases,
                    reduceMotion: reduceMotion,
                    note: $note
                )
            )
        case .reminder:
            return AnyView(
                ReminderStepView(
                    elementPhases: elementPhases,
                    reduceMotion: reduceMotion,
                    reminderValue: $reminderValue,
                    reminderUnit: $reminderUnit,
                    reminderDateText: configurationReminderText,
                    onSkip: {
                        Task {
                            await completeCreation(using: .skip)
                        }
                    },
                    onDeal: {
                        Task {
                            await completeCreation(using: .set)
                        }
                    }
                )
            )
        case .complete:
            guard let createdMoment else {
                return AnyView(ProgressView())
            }

            return AnyView(
                CompleteStepView(
                    moment: createdMoment,
                    namespace: creationAnimation,
                    elementPhases: elementPhases,
                    reduceMotion: reduceMotion,
                )
            )
        }
    }

    private func singleStepContent(for step: MomentCreationScreenStep) -> AnyView {
        switch step {
        case .capture:
            return AnyView(captureStep)
        case .workflow(let workflowStep):
            return workflowStepContent(workflowStep, screenStep: step)
        }
    }

    private func stagedTransitionContent(
        from sourceStep: MomentCreationScreenStep,
        to destinationStep: MomentCreationScreenStep
    ) -> some View {
        ZStack {
            singleStepContent(for: sourceStep)
                .opacity(sourceOpacity(for: sourceStep))

            singleStepContent(for: destinationStep)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if isCaptureStep {
            ToolbarItem(placement: .topBarLeading) {
                if captureChrome.leadingAction == .backToCapture {
                    Button {
                        resetCaptureDraft()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .accessibilityLabel("Back")
                } else {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Close")
                }
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                if captureChrome.showsFlash {
                    Button {
                        guard camera.isFlashAvailable else {
                            return
                        }

                        camera.isFlashEnabled.toggle()
                    } label: {
                        Image(systemName: camera.isFlashEnabled ? "bolt.fill" : "bolt.slash.fill")
                    }
                    .disabled(!captureInteractivity.allowsFlashToggle)
                    .accessibilityLabel(camera.isFlashEnabled ? "Flash On" : "Flash Off")
                }

                if captureChrome.showsAspectButton {
                    Button {
                        preparedImage = nil
                        selectedAspect = selectedAspect.next
                    } label: {
                        Text(selectedAspect.label)
                    }
                    .disabled(!captureInteractivity.allowsAspectToggle)
                }

                if showsPhotoOrientationButton {
                    Button {
                        selectedPhotoOrientation = selectedPhotoOrientation.toggled
                    } label: {
                        Image(systemName: "rotate.right")
                    }
                    .accessibilityLabel("Toggle orientation")
                }

                if captureChrome.showsConfirmButton {
                    Button {
                        goForwardFromCapture(using: activeCaptureLayout)
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .accessibilityLabel("Next")
                }
            }
        } else if let currentWorkflowStep, let workflowChrome {
            ToolbarItem(placement: .principal) {
                progressBar
                    .frame(width: 72)
                    .accessibilityLabel("Progress")
            }

            ToolbarItem(placement: .topBarLeading) {
                switch workflowChrome.leadingAction {
                case .back:
                    Button {
                        stepBack()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .accessibilityLabel("Back")
                case .close:
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(currentWorkflowStep == .complete ? "Close" : "Cancel")
                }
            }

            if currentWorkflowStep == .albumName || currentWorkflowStep == .note {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        goForwardFromWorkflowToolbar()
                    } label: {
                        Image(systemName: "chevron.forward")
                    }
                    .disabled(isWorkflowToolbarConfirmationDisabled)
                    .accessibilityLabel("Next")
                }
            } else if workflowChrome.showsShare, createdMoment != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        guard let createdMoment else {
                            return
                        }

                        pendingShareInput = MomentCreationPendingShareInput(moment: createdMoment)
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Share")
                }
                
                ToolbarSpacer(.fixed, placement: .topBarTrailing)

                ToolbarItem(placement: .topBarTrailing) {
                    Button (action: closeAndRouteToMoments) {
                        Image(systemName: "photo.stack")
                    }
                    .accessibilityLabel("Moments")
                }
            }
        }
    }

    private var progressBar: some View {
        Group {
            if let currentWorkflowStep {
                ProgressDots(steps: workflowSteps, currentStep: currentWorkflowStep)
            }
        }
    }

    private var captureStep: some View {
        GeometryReader { proxy in
            let layout = captureLayout(in: proxy)

            VStack(spacing: 0) {
                captureStage(layout: layout)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .onAppear {
                cachedCaptureLayout = layout
            }
            .onChange(of: layout) { _, newValue in
                cachedCaptureLayout = newValue
            }
        }
    }

    private func captureStage(layout: MomentCreationCaptureLayout) -> some View {
        ZStack(alignment: .topLeading) {
            captureStageBackgroundColor

            captureFrameContent(layout: layout)
                .frame(width: layout.frameRect.width, height: layout.frameRect.height)
                .offset(x: layout.frameRect.minX, y: layout.frameRect.minY)

            Rectangle()
                .fill(.white)
                .frame(width: layout.frameRect.width, height: layout.frameRect.height)
                .offset(x: layout.frameRect.minX, y: layout.frameRect.minY)
                .opacity(isCaptureFlashVisible ? 0.85 : 0)
                .allowsHitTesting(false)

            if captureChrome.showsMaskSlider {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    overlaySliderSection
                        .padding(.horizontal, AppTheme.Spacing.s2)
                        .padding(.bottom, AppTheme.Spacing.s2)
                }
                .frame(width: layout.referenceRect.width, height: layout.referenceRect.height)
                .offset(x: layout.referenceRect.minX, y: layout.referenceRect.minY)
            }

            if captureChrome.showsCaptureControls {
                VStack(spacing: 0) {
                     Spacer(minLength: 0)

                    captureBottomBar
                        .padding(.horizontal, AppTheme.Spacing.s5)
                        .padding(.bottom, AppTheme.Spacing.s2)
                }
                .frame(width: layout.stageSize.width, height: layout.stageSize.height)
            }
        }
        .frame(width: layout.stageSize.width, height: layout.stageSize.height)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func captureFrameContent(layout: MomentCreationCaptureLayout) -> some View {
        if let captureDraft {
            capturePreviewImageStage(captureDraft, layout: layout)
        } else if camera.authorizationState == .authorized, camera.isSessionConfigured {
            CameraPreviewView(session: camera.session)
                .frame(width: layout.frameRect.width, height: layout.frameRect.height)
                .overlay {
                    Rectangle()
                        .stroke(.white.opacity(0.18), lineWidth: 1)
                }
                .overlay {
                    if let latestMomentPhotoPath, latestMomentPhotoPath.isEmpty == false {
                        LocalPhotoView(path: latestMomentPhotoPath, contentMode: .fit)
                            .frame(width: layout.frameRect.width, height: layout.frameRect.height)
                            .opacity(overlayOpacity)
                    }
                }
        } else {
            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(width: layout.frameRect.width, height: layout.frameRect.height)
                .overlay {
                    permissionStateView
                        .padding(AppTheme.Spacing.s6)
                }
        }
    }

    @ViewBuilder
    private func capturePreviewImageStage(
        _ captureDraft: MomentCreationCaptureDraft,
        layout: MomentCreationCaptureLayout
    ) -> some View {
        if isShowingInteractiveCaptureCrop {
            let canvas = CropCanvas(
                image: captureDraft.image,
                containerSize: layout.frameRect.size,
                previewSize: layout.previewSize,
                cropSize: layout.cropSize,
                zoomScale: $captureCropZoomScale,
                committedZoomScale: $committedCaptureCropZoomScale,
                offset: $captureCropOffset,
                committedOffset: $committedCaptureCropOffset
            )

            if reduceMotion {
                canvas
            } else if captureHeroMatchedGeometryEnabled {
                canvas
                    .matchedGeometryEffect(id: "creation-hero-image", in: creationAnimation)
            } else {
                canvas
            }
        } else {
            let image = Image(uiImage: captureDraft.image)
                .resizable()
                .scaledToFill()
                .frame(width: layout.frameRect.width, height: layout.frameRect.height)
                .clipped()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if reduceMotion {
                image
            } else if captureHeroMatchedGeometryEnabled {
                image
                    .matchedGeometryEffect(id: "creation-hero-image", in: creationAnimation)
            } else {
                image
            }
        }
    }

    private var overlaySliderSection: some View {
        HStack(spacing: AppTheme.Spacing.s5) {
            Text("Mask")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.88))

            Slider(value: $overlayOpacity, in: 0 ... 0.7)
                .tint(.white)
        }
    }

    private var captureBottomBar: some View {
        HStack {
            PhotosPicker(
                selection: $selectedPhotoItem,
                matching: .images,
                preferredItemEncoding: .current
            ) {
                Image(systemName: "photo.on.rectangle").font(.system(size: 20, weight: .medium))
            }
            .disabled(!captureInteractivity.allowsPhotoPicker)
            .tint(AppTheme.Colors.accent)
            .accessibilityLabel("Album")

            Spacer(minLength: AppTheme.Spacing.s7)

            Button {
                capturePhoto()
            } label: {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 80, height: 80)

                    Circle()
                        .stroke(.white.opacity(0.4), lineWidth: 2)
                        .frame(width: 68, height: 68)

                    Circle()
                        .fill(.white)
                        .frame(width: 60, height: 60)
                }
            }
            .buttonStyle(.plain)
            .disabled(!captureInteractivity.allowsShutter)
            .opacity(captureInteractivity.allowsShutter ? 1 : 0.55)

            Spacer(minLength: AppTheme.Spacing.s7)

            Button {
                camera.toggleCamera()
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .disabled(!captureInteractivity.allowsCameraToggle)
            .opacity(captureInteractivity.allowsCameraToggle ? 1 : 0.55)
        }
    }

    private var showsPhotoOrientationButton: Bool {
        capturePreviewKind == .photoLibraryCrop && previewCropAspect != .square
    }

    private var isCaptureStep: Bool {
        if case .capture = currentStep {
            return true
        }

        return false
    }

    private var currentWorkflowStep: MomentCreationWorkflowStep? {
        if case .workflow(let step) = currentStep {
            return step
        }

        return nil
    }

    private var workflowSteps: [MomentCreationWorkflowStep] {
        MomentCreationWorkflowResolver.steps(for: mode)
    }

    private var workflowChrome: MomentCreationWorkflowChromeState? {
        currentWorkflowStep.map { MomentCreationWorkflowChromeResolver.resolve(for: $0) }
    }

    private var isCaptureEntryTransitionActive: Bool {
        transitionSourceStep == .capture && activeTransitionPlan?.kind == .staged
    }

    private var captureStageBackgroundColor: Color {
        isCaptureEntryTransitionActive ? .clear : .black
    }

    private var workflowImage: UIImage? {
        preparedImage ?? captureDraft?.image
    }

    private var captureHeroMatchedGeometryEnabled: Bool {
        switch activeTransitionPlan?.route {
        case .captureToAlbumName, .captureToNote:
            return false
        default:
            return true
        }
    }

    private func advanceFromAlbumName() {
        let trimmedAlbumName = albumName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedAlbumName.isEmpty == false else {
            focusedField = .albumName
            return
        }

        navigate(to: .workflow(.note), direction: .forward)
    }

    private func advanceFromNote() async {
        if mode.showsAlbumConfigurationStep {
            navigate(to: .workflow(.reminder), direction: .forward)
        } else {
            await completeCreation()
        }
    }

    private var isWorkflowToolbarConfirmationDisabled: Bool {
        guard currentWorkflowStep == .albumName else {
            return false
        }

        return albumName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func goForwardFromWorkflowToolbar() {
        switch currentWorkflowStep {
        case .albumName:
            advanceFromAlbumName()
        case .note:
            Task {
                await advanceFromNote()
            }
        case .reminder, .complete, .none:
            break
        }
    }

    private func handleCurrentStepChange(_ step: MomentCreationScreenStep) {
        updateCameraLifecycle(for: step)

        if activeTransitionPlan?.kind == .staged {
            focusedField = nil
            return
        }

        if case .workflow(let workflowStep) = step {
            scheduleFocus(for: workflowStep)
        } else {
            focusedField = nil
        }
    }

    private func scheduleFocus(for workflowStep: MomentCreationWorkflowStep) {
        focusedField = nil
        focusTask?.cancel()

        let targetField = TransitionStateResolver.focusField(for: .workflow(workflowStep))

        guard let targetField else {
            return
        }

        focusTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(220))

            if currentWorkflowStep == workflowStep, activeTransitionPlan == nil {
                focusedField = targetField
            }
        }
    }

    private var permissionStateView: some View {
        VStack(spacing: AppTheme.Spacing.s4) {
            Image(systemName: permissionIconName)
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(.white.opacity(0.92))

            Text(permissionTitle)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)

            Text(permissionMessage)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.72))
        }
    }

    private var permissionIconName: String {
        switch camera.authorizationState {
        case .denied, .restricted:
            return "camera.fill.badge.ellipsis"
        case .unavailable:
            return "camera.metering.unknown"
        case .authorized, .unknown:
            return "camera"
        }
    }

    private var permissionTitle: String {
        switch camera.authorizationState {
        case .denied:
            return "Camera access is off"
        case .restricted:
            return "Camera access is restricted"
        case .unavailable:
            return "Camera unavailable"
        case .authorized:
            return "Starting camera"
        case .unknown:
            return "Requesting camera access"
        }
    }

    private var permissionMessage: String {
        switch camera.authorizationState {
        case .denied:
            return "Enable camera access in Settings to take a new photo, or use Album below to choose one."
        case .restricted:
            return "This device currently restricts camera access. You can still choose an image from Album below."
        case .unavailable:
            return "This environment doesn't provide a usable camera. You can still choose an image from Album below."
        case .authorized:
            return "Preparing the capture session."
        case .unknown:
            return "Waiting for camera permission."
        }
    }

    private var stepTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        }

        let insertionEdge: Edge = navigationDirection == .forward ? .trailing : .leading
        let removalEdge: Edge = navigationDirection == .forward ? .leading : .trailing

        return .asymmetric(
            insertion: .move(edge: insertionEdge).combined(with: .opacity),
            removal: .move(edge: removalEdge).combined(with: .opacity)
        )
    }

    private var isShowingCapturePreview: Bool {
        captureDraft != nil
    }

    private var capturePreviewKind: MomentCreationCapturePreviewKind {
        guard let captureDraft else {
            return .live
        }

        if captureDraft.source == .photoLibrary, isShowingInteractiveCaptureCrop {
            return .photoLibraryCrop
        }

        return .cameraPreview
    }

    private var captureChrome: MomentCreationCaptureChromeState {
        MomentCreationCaptureChromeResolver.resolve(
            previewKind: capturePreviewKind,
            allowsAspectSelection: allowsAspectSelection,
            showsOverlaySlider: showsOverlaySlider
        )
    }

    private var previewCropMode: MomentCreationPreviewCropMode {
        guard let captureDraft else {
            return .none
        }

        return capturePreviewCropMode(for: captureDraft.source)
    }

    private var previewCropAspect: CameraCaptureAspect {
        switch previewCropMode {
        case .none, .adjustable:
            return selectedAspect
        case .fixed(let aspect):
            return aspect
        }
    }

    private var isShowingInteractiveCaptureCrop: Bool {
        switch previewCropMode {
        case .none:
            return false
        case .adjustable, .fixed:
            return true
        }
    }

    private var activeCaptureLayout: MomentCreationCaptureLayout {
        cachedCaptureLayout ?? captureLayout(forStageWidth: AppTheme.Layout.screenWidth)
    }

    private var isCapturingPhoto: Bool {
        cameraCaptureState.isCaptureInProgress
    }

    private var captureInteractivity: MomentCreationCaptureInteractivityState {
        MomentCreationCaptureInteractivityResolver.resolve(
            chrome: captureChrome,
            isCaptureInProgress: isCapturingPhoto,
            isCameraAuthorized: camera.authorizationState == .authorized,
            isSessionConfigured: camera.isSessionConfigured,
            isFlashAvailable: camera.isFlashAvailable
        )
    }

    private var latestMomentPhotoPath: String? {
        mode.latestMoment?.photo
    }

    private var latestMoment: Moment? {
        previousMoment ?? mode.latestMoment
    }

    private var showsOverlaySlider: Bool {
        latestMomentPhotoPath != nil && mode.isCreatingAlbum == false
    }

    private var allowsAspectSelection: Bool {
        switch mode {
        case .newAlbum:
            return true
        case .newMoment(let album):
            return album.moments.isEmpty && album.ratio == nil
        }
    }

    private var configurationReminderText: String {
        guard let date = AlbumReminderService.reminderDate(from: .now, value: reminderValue, unit: reminderUnit) else {
            return "another time"
        }

        return AppDateFormatters.momentTimestamp.string(from: date)
    }

    private func updateCameraLifecycle(for step: MomentCreationScreenStep) {
        if step == .capture, captureDraft == nil {
            camera.activate()
        } else {
            camera.deactivate()
        }
    }

    private func capturePhoto() {
        guard let captureAspect = cameraCaptureState.beginCapture(selectedAspect: selectedAspect) else {
            return
        }

        triggerCaptureFlash()

        camera.capturePhoto { result in
            switch result {
            case .success(let image):
                cameraCaptureState.finishCapture()
                let draft = setCaptureDraft(image, source: .camera)
                prepareCameraImage(image, aspect: captureAspect, matching: draft.id)
            case .failure(let error):
                cameraCaptureState.finishCapture()
                present(error.localizedDescription)
            }
        }
    }

    private func goForwardFromCapture(using layout: MomentCreationCaptureLayout) {
        guard captureDraft != nil else {
            present("A photo is required before continuing.")
            return
        }

        preparedImage = exportPreparedImage(using: layout)
        navigate(to: MomentCreationScreenStepResolver.stepAfterCapture(for: mode), direction: .forward)
    }

    private func stepBack() {
        guard let previousStep = MomentCreationScreenStepResolver.previousStep(from: currentStep, in: mode) else {
            return
        }

        navigate(to: previousStep, direction: .backward)
    }

    private func completeCreation() async {
        await completeCreation(using: reminderDecision)
    }

    private func completeCreation(using decision: ReminderDecision) async {
        guard !isSaving else {
            return
        }

        guard let preparedImage else {
            present("A photo is required before continuing.")
            return
        }

        if mode.showsAlbumNameField {
            let trimmedAlbumName = albumName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedAlbumName.isEmpty else {
                focusedField = .albumName
                return
            }
        }

        reminderDecision = decision
        isSaving = true

        do {
            let now = Date.now
            let photoPath = try await storeMomentImage(preparedImage)
            let previousMoment = mode.latestMoment
            let album = try prepareAlbumForSave(at: now)
            let moment = Moment(
                album: album,
                photo: photoPath,
                photoOrientation: .inferred(from: preparedImage.size),
                note: note,
                createdAt: now,
                updatedAt: now
            )

            if album.modelContext == nil {
                modelContext.insert(album)
            }

            if moment.modelContext == nil {
                modelContext.insert(moment)
            }
            try modelContext.save()

            let scheduleOutcome = try await finalizeReminderIfNeeded(for: album)
            if scheduleOutcome != nil {
                try modelContext.save()
            }

            self.previousMoment = previousMoment
            createdAlbum = album
            createdMoment = moment
            reminderScheduleOutcome = scheduleOutcome
            navigate(to: .workflow(.complete), direction: .forward)
        } catch {
            present(error.localizedDescription)
        }

        isSaving = false
    }

    private func prepareAlbumForSave(at now: Date) throws -> Album {
        switch mode {
        case .newAlbum:
            let album = Album(
                name: albumName.trimmingCharacters(in: .whitespacesAndNewlines),
                ratio: selectedAspect,
                createdAt: now,
                updatedAt: now
            )

            if reminderDecision == .set {
                try AlbumReminderService.storeReminder(
                    on: album,
                    value: reminderValue,
                    unit: reminderUnit,
                    baseDate: now
                )
            }

            return album
        case .newMoment(let album):
            if album.ratio == nil {
                album.ratio = selectedAspect
            }
            album.updatedAt = now

            if mode.showsAlbumConfigurationStep {
                switch reminderDecision {
                case .set:
                    try AlbumReminderService.storeReminder(
                        on: album,
                        value: reminderValue,
                        unit: reminderUnit,
                        baseDate: now
                    )
                case .skip:
                    album.remindValue = nil
                    album.remindUnit = nil
                    album.remindAt = nil
                case .untouched:
                    break
                }
            }

            return album
        }
    }

    private func finalizeReminderIfNeeded(for album: Album) async throws -> AlbumReminderScheduleOutcome? {
        guard mode.showsAlbumConfigurationStep else {
            return nil
        }

        switch reminderDecision {
        case .set:
            if let reminderAuthorizationGranted {
                return try await AlbumReminderService.scheduleStoredReminder(
                    for: album,
                    authorizationGranted: reminderAuthorizationGranted,
                    client: reminderClient
                )
            }

            return try await AlbumReminderService.scheduleStoredReminder(for: album, client: reminderClient)
        case .skip:
            AlbumReminderService.removeScheduledReminder(for: album, client: reminderClient)
            return nil
        case .untouched:
            return nil
        }
    }

    private func closeAndRouteToMoments() {
        guard let album = createdAlbum ?? mode.album else {
            dismiss()
            return
        }

        onComplete(album)
        dismiss()
    }

    private func captureLayout(in proxy: GeometryProxy) -> MomentCreationCaptureLayout {
        captureLayout(forStageWidth: proxy.size.width)
    }

    private func captureLayout(forStageWidth stageWidth: CGFloat) -> MomentCreationCaptureLayout {
        let stageLayout = CameraGeometry.captureStageLayout(
            stageWidth: stageWidth,
            aspect: currentCaptureDisplayAspect,
            orientation: currentCaptureDisplayOrientation,
            bottomInset: AppTheme.Spacing.s2
        )
        let previewSize = if let captureDraft, captureDraft.source == .photoLibrary {
            imagePreviewSize(for: captureDraft.image, in: stageLayout.frameRect.size)
        } else {
            stageLayout.frameRect.size
        }
        let cropSize = isShowingInteractiveCaptureCrop
            ? stageLayout.frameRect.size
            : .zero

        return MomentCreationCaptureLayout(
            stageSize: stageLayout.stageRect.size,
            referenceRect: stageLayout.referenceRect,
            frameRect: stageLayout.frameRect,
            previewSize: previewSize,
            cropSize: cropSize
        )
    }

    private func imagePreviewSize(for image: UIImage, in containerSize: CGSize) -> CGSize {
        CameraGeometry.fittedSize(for: image.size, in: containerSize)
    }

    private func capturePreviewCropMode(for source: MomentCreationCaptureSource) -> MomentCreationPreviewCropMode {
        if source == .camera {
            return .none
        }

        if allowsAspectSelection {
            return .adjustable
        }

        if source == .photoLibrary, let fixedAspect = mode.album?.ratio {
            return .fixed(fixedAspect)
        }

        return .none
    }

    private func exportPreparedImage(using layout: MomentCreationCaptureLayout) -> UIImage {
        guard let captureDraft else {
            return preparedImage ?? UIImage()
        }

        if captureDraft.source == .camera {
            return preparedImage ?? CameraImageCropper.croppedImage(captureDraft.image, aspect: selectedAspect)
        }

        switch previewCropMode {
        case .adjustable, .fixed:
            return CameraImageCropper.croppedImage(
                captureDraft.image,
                previewSize: layout.previewSize,
                cropSize: layout.cropSize,
                zoomScale: captureCropZoomScale,
                offset: captureCropOffset
            )
        case .none:
            return captureDraft.image
        }
    }

    @discardableResult
    private func setCaptureDraft(_ image: UIImage, source: MomentCreationCaptureSource) -> MomentCreationCaptureDraft {
        let draft = MomentCreationCaptureDraft(image: image, source: source)
        captureDraft = draft
        selectedPhotoOrientation = source == .photoLibrary
            ? MomentPhotoOrientation.inferred(from: image.size)
            : .portrait
        preparedImage = nil
        resetCaptureCropTransform()
        return draft
    }

    private func resetCaptureDraft() {
        captureDraft = nil
        selectedPhotoOrientation = Self.initialOrientation(for: mode)
        preparedImage = nil
        isCaptureFlashVisible = false
        cameraCaptureState.finishCapture()
        resetCaptureCropTransform()
    }

    private func resetCaptureCropTransform() {
        captureCropOffset = .zero
        committedCaptureCropOffset = .zero
        captureCropZoomScale = 1
        committedCaptureCropZoomScale = 1
    }

    private func prepareCameraImage(
        _ image: UIImage,
        aspect: CameraCaptureAspect,
        matching draftID: UUID
    ) {
        Self.imageProcessingQueue.async {
            let preparedImage = CameraImageCropper.croppedImage(image, aspect: aspect)

            Task { @MainActor in
                guard captureDraft?.id == draftID else {
                    return
                }

                self.preparedImage = preparedImage
            }
        }
    }

    private func storeMomentImage(_ image: UIImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            Self.imageProcessingQueue.async {
                do {
                    let path = try AppImageStore.store(image)
                    continuation.resume(returning: path)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func navigate(to step: MomentCreationScreenStep, direction: MomentCreationNavigationDirection) {
        navigationDirection = direction

        transitionTask?.cancel()
        focusTask?.cancel()

        let sourceStep = currentStep
        let transitionDirection: MomentCreationTransitionDirection = direction == .forward ? .forward : .backward
        let plan = TransitionResolver.resolve(
            from: sourceStep,
            to: step,
            direction: transitionDirection
        )

        switch plan.kind {
        case .staged:
            startStagedTransition(from: sourceStep, to: step, plan: plan)
        case .push:
            resetTransientTransitionState()
            transitionElementPhases[step] = TransitionStateResolver.initialPhases(
                for: step,
                route: plan.route
            )
            focusedField = nil

            withAnimation(containerStepAnimation) {
                currentStep = step
            }

            schedulePlanStages(
                from: sourceStep,
                to: step,
                plan: plan,
                clearsStagedTransition: false
            )
        case .fallback:
            resetTransientTransitionState()
            transitionElementPhases[step] = TransitionStateResolver.settledPhases(for: step)

            withAnimation(containerStepAnimation) {
                currentStep = step
            }
        }
    }

    private var containerStepAnimation: Animation {
        .easeInOut(duration: 0.3)
    }

    private func phases(
        for step: MomentCreationScreenStep
    ) -> MomentCreationTransitionElementPhases {
        transitionElementPhases[step] ?? TransitionStateResolver.settledPhases(for: step)
    }

    private func startStagedTransition(
        from sourceStep: MomentCreationScreenStep,
        to destinationStep: MomentCreationScreenStep,
        plan: MomentCreationTransitionPlan
    ) {
        activeTransitionPlan = plan
        transitionSourceStep = sourceStep
        transitionDestinationStep = destinationStep
        transitionBackgroundOpacity = sourceStep == .capture ? 0 : 1
        transitionSourceOpacity = 1
        transitionElementPhases[sourceStep] = TransitionStateResolver.settledPhases(for: sourceStep)

        var destinationPhases = TransitionStateResolver.initialPhases(
            for: destinationStep,
            route: plan.route
        )
        transitionElementPhases[destinationStep] = destinationPhases
        focusedField = nil

        switch plan.route {
        case .captureToAlbumName, .captureToNote:
            break
        case .albumNameToNote, .noteToReminder, .noteToComplete, .reminderToComplete, .fallback:
            currentStep = destinationStep
        }

        schedulePlanStages(
            from: sourceStep,
            to: destinationStep,
            plan: plan,
            clearsStagedTransition: true
        )
    }

    private func schedulePlanStages(
        from sourceStep: MomentCreationScreenStep,
        to destinationStep: MomentCreationScreenStep,
        plan: MomentCreationTransitionPlan,
        clearsStagedTransition: Bool
    ) {
        let currentStepSwitchTime = currentStepSwitchTime(for: plan)
        let stagedEvents = plan.stages
            .map { stage in
                (
                    start: absoluteStart(for: stage, plan: plan),
                    stage: stage
                )
            }
            .sorted { $0.start < $1.start }

        scheduleFocusIfNeeded(for: destinationStep, plan: plan)

        transitionTask = Task { @MainActor in
            var elapsed = 0
            var hasSwitchedCurrentStep = currentStepSwitchTime == nil

            for item in stagedEvents {
                if let currentStepSwitchTime,
                   hasSwitchedCurrentStep == false,
                   currentStepSwitchTime <= item.start {
                    let switchDelay = max(currentStepSwitchTime - elapsed, 0)
                    if switchDelay > 0 {
                        try? await Task.sleep(for: .milliseconds(switchDelay))
                    }

                    guard Task.isCancelled == false else {
                        return
                    }

                    currentStep = destinationStep
                    elapsed = currentStepSwitchTime
                    hasSwitchedCurrentStep = true
                }

                let delay = max(item.start - elapsed, 0)
                if delay > 0 {
                    try? await Task.sleep(for: .milliseconds(delay))
                }

                guard Task.isCancelled == false else {
                    return
                }

                apply(item.stage, from: sourceStep, to: destinationStep, route: plan.route)
                elapsed = item.start
            }

            if let currentStepSwitchTime,
               hasSwitchedCurrentStep == false {
                let switchDelay = max(currentStepSwitchTime - elapsed, 0)
                if switchDelay > 0 {
                    try? await Task.sleep(for: .milliseconds(switchDelay))
                }

                guard Task.isCancelled == false else {
                    return
                }

                currentStep = destinationStep
                elapsed = currentStepSwitchTime
            }

            let totalDuration = max(
                stagedEvents.map { $0.start + $0.stage.durationMilliseconds }.max() ?? 0,
                plan.containerTransition == .pushFromTrailing ? 300 : 0
            )
            let remaining = max(totalDuration - elapsed, 0)

            if remaining > 0 {
                try? await Task.sleep(for: .milliseconds(remaining))
            }

            guard Task.isCancelled == false else {
                return
            }

            finalizeTransition(
                from: sourceStep,
                to: destinationStep,
                clearsStagedTransition: clearsStagedTransition
            )
        }
    }

    private func absoluteStart(
        for stage: MomentCreationTransitionStage,
        plan: MomentCreationTransitionPlan
    ) -> Int {
        let anchorOffset = switch stage.anchor {
        case .routeStart:
            0
        case .containerCompletion:
            plan.containerTransition == .pushFromTrailing ? 300 : 0
        }

        return anchorOffset + stage.startMilliseconds
    }

    private func scheduleFocusIfNeeded(
        for step: MomentCreationScreenStep,
        plan: MomentCreationTransitionPlan
    ) {
        focusTask?.cancel()

        guard let targetField = TransitionStateResolver.focusField(for: step),
              let delay = TransitionStateResolver.focusDelayMilliseconds(
                  for: step,
                  plan: plan
              ) else {
            return
        }

        focusTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(delay))

            if currentStep == step, activeTransitionPlan != nil {
                try? await Task.sleep(for: .milliseconds(60))
            }

            if currentStep == step, activeTransitionPlan == nil {
                focusedField = targetField
            }
        }
    }

    private func apply(
        _ stage: MomentCreationTransitionStage,
        from sourceStep: MomentCreationScreenStep,
        to destinationStep: MomentCreationScreenStep,
        route: MomentCreationTransitionRoute
    ) {
        withAnimation(.easeInOut(duration: Double(stage.durationMilliseconds) / 1000)) {
            for event in stage.events {
                switch event.action {
                case .transition:
                    if event.element == .background {
                        transitionBackgroundOpacity = 1

                        if sourceStep == .capture {
                            transitionSourceOpacity = 0
                        }
                    }
                case .enter:
                    var phases = transitionElementPhases[destinationStep]
                        ?? TransitionStateResolver.initialPhases(
                            for: destinationStep,
                            route: route
                        )
                    phases[event.element] = .visible
                    transitionElementPhases[destinationStep] = phases
                case .exit:
                    var phases = transitionElementPhases[sourceStep]
                        ?? TransitionStateResolver.settledPhases(for: sourceStep)
                    phases[event.element] = .hiddenAbove
                    transitionElementPhases[sourceStep] = phases
                }
            }
        }
    }

    private func finalizeTransition(
        from sourceStep: MomentCreationScreenStep,
        to destinationStep: MomentCreationScreenStep,
        clearsStagedTransition: Bool
    ) {
        transitionElementPhases[destinationStep] = TransitionStateResolver.settledPhases(for: destinationStep)
        transitionElementPhases[sourceStep] = nil
        transitionTask = nil
        transitionSourceOpacity = 1

        if clearsStagedTransition {
            activeTransitionPlan = nil
            transitionSourceStep = nil
            transitionDestinationStep = nil
            transitionBackgroundOpacity = destinationStep == .capture ? 0 : 1
        }
    }

    private func resetTransientTransitionState() {
        activeTransitionPlan = nil
        transitionSourceStep = nil
        transitionDestinationStep = nil
        transitionBackgroundOpacity = currentStep == .capture ? 0 : 1
        transitionSourceOpacity = 1
        transitionTask = nil
    }

    private func sourceOpacity(for step: MomentCreationScreenStep) -> Double {
        step == transitionSourceStep ? transitionSourceOpacity : 1
    }

    private func currentStepSwitchTime(for plan: MomentCreationTransitionPlan) -> Int? {
        switch plan.route {
        case .captureToAlbumName, .captureToNote:
            guard let fadeStage = plan.stages.first(where: { stage in
                stage.events.contains { event in
                    event.element == .background && event.action == .transition
                }
            }) else {
                return nil
            }

            return absoluteStart(for: fadeStage, plan: plan) + fadeStage.durationMilliseconds
        case .albumNameToNote, .noteToReminder, .noteToComplete, .reminderToComplete, .fallback:
            return nil
        }
    }

    private func triggerCaptureFlash() {
        withAnimation(.easeOut(duration: 0.06)) {
            isCaptureFlashVisible = true
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(140))

            withAnimation(.easeOut(duration: 0.16)) {
                isCaptureFlashVisible = false
            }
        }
    }

    private func present(_ message: String) {
        errorMessage = message
        isPresentingError = true
    }

    private func loadSelectedImage(from item: PhotosPickerItem) async {
        do {
            let image = try await PhotosPickerImageLoader.loadImage(from: item)
            setCaptureDraft(image, source: .photoLibrary)
        } catch {
            present(error.localizedDescription)
        }

        selectedPhotoItem = nil
    }

    private var currentCaptureDisplayAspect: CameraCaptureAspect {
        switch captureDraft?.source {
        case .photoLibrary:
            return previewCropAspect
        case .camera, .none:
            return selectedAspect
        }
    }

    private var currentCaptureDisplayOrientation: MomentPhotoOrientation {
        switch captureDraft?.source {
        case .photoLibrary:
            return selectedPhotoOrientation
        case .camera, .none:
            return .portrait
        }
    }

    private static func initialReminderSelection(for mode: MomentCreationMode) -> ReminderSelection {
        if let album = mode.album,
           let remindValue = album.remindValue,
           let remindUnit = album.remindUnit {
            return ReminderSelection(value: remindValue, unit: remindUnit)
        }

        return ReminderSelection(value: 1, unit: .month)
    }

    private static func initialAspect(for mode: MomentCreationMode) -> CameraCaptureAspect {
        guard let album = mode.album else {
            return .threeByFour
        }

        let latestMomentPhotoSize = mode.latestMoment.flatMap { moment in
            ImageResourceService.imageSize(from: moment.photo)
        }

        return MomentPhotoLayoutResolver.initialAspect(
            albumRatio: album.ratio,
            templatePhotoSize: album.templatePhotoSize,
            latestMomentPhotoSize: latestMomentPhotoSize
        )
    }

    private static func initialOrientation(for mode: MomentCreationMode) -> MomentPhotoOrientation {
        guard let album = mode.album else {
            return .portrait
        }

        let latestMomentPhotoSize = mode.latestMoment.flatMap { moment in
            ImageResourceService.imageSize(from: moment.photo)
        }

        return MomentPhotoLayoutResolver.initialOrientation(
            templatePhotoSize: album.templatePhotoSize,
            latestMomentPhotoOrientation: mode.latestMoment?.photoOrientation,
            latestMomentPhotoSize: latestMomentPhotoSize
        )
    }
}

private enum MomentCreationPreviewSupport {
    static let reminderClient = AlbumReminderClient(
        requestAuthorization: { false },
        addRequest: { _ in },
        removeRequests: { _ in }
    )

    static func makeContainer() -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: Album.self, Moment.self, configurations: configuration)
    }

    static func makeAlbumWithMoment(in container: ModelContainer) -> Album {
        let album = Album(name: "Sunday Walk", ratio: .threeByFour)
        container.mainContext.insert(album)
        container.mainContext.insert(Moment(
            album: album,
            photo: "",
            note: "Soft light, still water, and a quiet walk.",
            createdAt: Date(timeIntervalSince1970: 1_713_628_800),
            updatedAt: Date(timeIntervalSince1970: 1_713_628_800)
        ))
        return album
    }
}

#Preview("New Album") {
    let container = MomentCreationPreviewSupport.makeContainer()

    return NavigationStack {
        CreationView(
            mode: .newAlbum,
            reminderClient: MomentCreationPreviewSupport.reminderClient
        )
    }
    .modelContainer(container)
}

#Preview("New Moment") {
    let container = MomentCreationPreviewSupport.makeContainer()
    let album = MomentCreationPreviewSupport.makeAlbumWithMoment(in: container)

    return NavigationStack {
        CreationView(
            mode: .newMoment(album: album),
            reminderClient: MomentCreationPreviewSupport.reminderClient
        )
    }
    .modelContainer(container)
}
#endif
