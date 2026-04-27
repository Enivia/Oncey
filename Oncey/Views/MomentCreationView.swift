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

enum MomentCreationLocationRefreshPolicy {
    static func shouldRefreshLocation(for step: MomentCreationWorkflowStep, hasAutoRequestedLocation: Bool) -> Bool {
        step == .note && !hasAutoRequestedLocation
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

struct MomentCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
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
    @State private var locationService = CurrentLocationService()
    @State private var hasAutoRequestedLocation = false
    @State private var isSaving = false
    @State private var createdAlbum: Album?
    @State private var createdMoment: Moment?
    @State private var pendingShareInput: MomentCreationPendingShareInput?
    @State private var previousMoment: Moment?
    @State private var reminderScheduleOutcome: AlbumReminderScheduleOutcome?
    @State private var errorMessage: String?
    @State private var isPresentingError = false

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
            workflowProgressSection
            stepContent
        }
        .padding(.bottom, isCaptureStep ? 0 : AppTheme.Spacing.s6)
    }

    @ViewBuilder
    private var workflowProgressSection: some View {
        if currentWorkflowStep != nil {
            progressBar
                .padding(.horizontal, AppTheme.Spacing.s6)
                .padding(.top, AppTheme.Spacing.s2)
        }
    }

    private var backgroundView: AnyView {
        if isCaptureStep {
            return AnyView(Color.black.ignoresSafeArea())
        }

        return AnyView(AppPageBackground())
    }

    private var stepContent: AnyView {
        let content: AnyView

        switch currentStep {
        case .capture:
            content = AnyView(captureStep.transition(stepTransition))
        case .workflow(let currentWorkflowStep):
            content = workflowStepContent(currentWorkflowStep)
        }

        return AnyView(
            ZStack {
                content
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
        )
    }

    private func workflowStepContent(_ step: MomentCreationWorkflowStep) -> AnyView {
        guard let workflowImage else {
            return AnyView(ProgressView())
        }

        switch step {
        case .albumName:
            return AnyView(
                AlbumNameStepView(
                    image: workflowImage,
                    namespace: creationAnimation,
                    focus: $focusedField,
                    albumName: $albumName,
                    onNext: advanceFromAlbumName
                )
            )
        case .note:
            return AnyView(
                NoteStepView(
                    image: workflowImage,
                    namespace: creationAnimation,
                    focus: $focusedField,
                    note: $note,
                    onNext: {
                        Task {
                            await advanceFromNote()
                        }
                    }
                )
            )
        case .reminder:
            return AnyView(
                ReminderStepView(
                    image: workflowImage,
                    note: note,
                    namespace: creationAnimation,
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
                    reminderMessage: completionReminderMessage,
                    namespace: creationAnimation,
                    onTimeline: closeAndRouteToTimeline
                )
            )
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

            if workflowChrome.showsShare, createdMoment != nil {
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
            Color.black

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
            CropCanvas(
                image: captureDraft.image,
                containerSize: layout.frameRect.size,
                previewSize: layout.previewSize,
                cropSize: layout.cropSize,
                zoomScale: $captureCropZoomScale,
                committedZoomScale: $committedCaptureCropZoomScale,
                offset: $captureCropOffset,
                committedOffset: $committedCaptureCropOffset
            )
            .matchedGeometryEffect(id: "creation-hero-image", in: creationAnimation)
        } else {
            Image(uiImage: captureDraft.image)
                .resizable()
                .scaledToFill()
                .frame(width: layout.frameRect.width, height: layout.frameRect.height)
                .clipped()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .matchedGeometryEffect(id: "creation-hero-image", in: creationAnimation)
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

    private var workflowImage: UIImage? {
        preparedImage ?? captureDraft?.image
    }

    private var completionReminderMessage: String? {
        guard let createdAlbum, let remindAt = createdAlbum.remindAt else {
            return nil
        }

        return "Deal. I’ll remind you to come back on \(AppDateFormatters.momentTimestamp.string(from: remindAt))"
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

    private func handleCurrentStepChange(_ step: MomentCreationScreenStep) {
        updateCameraLifecycle(for: step)

        if case .workflow(let workflowStep) = step {
            requestLocationIfNeeded(for: workflowStep)
            scheduleFocus(for: workflowStep)
        } else {
            focusedField = nil
        }
    }

    private func scheduleFocus(for workflowStep: MomentCreationWorkflowStep) {
        focusedField = nil

        let targetField: MomentCreationFocusField?
        switch workflowStep {
        case .albumName:
            targetField = .albumName
        case .note:
            targetField = .note
        case .reminder, .complete:
            targetField = nil
        }

        guard let targetField else {
            return
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(220))

            if currentWorkflowStep == workflowStep {
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

        camera.capturePhoto { result in
            switch result {
            case .success(let image):
                let capturedImage = CameraImageCropper.croppedImage(image, aspect: captureAspect)
                cameraCaptureState.finishCapture()
                setCaptureDraft(capturedImage, source: .camera)
                triggerCaptureFlash()
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
            let photoPath = try AppImageStore.store(preparedImage)
            let previousMoment = mode.latestMoment
            let album = try prepareAlbumForSave(at: now)
            let moment = Moment(
                album: album,
                photo: photoPath,
                location: locationService.persistedValue,
                note: note,
                createdAt: now,
                updatedAt: now
            )

            if mode.isCreatingAlbum {
                modelContext.insert(album)
            }

            modelContext.insert(moment)
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

    private func closeAndRouteToTimeline() {
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

    private func setCaptureDraft(_ image: UIImage, source: MomentCreationCaptureSource) {
        captureDraft = MomentCreationCaptureDraft(image: image, source: source)
        preparedImage = nil
        resetCaptureCropTransform()
    }

    private func resetCaptureDraft() {
        captureDraft = nil
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

    private func navigate(to step: MomentCreationScreenStep, direction: MomentCreationNavigationDirection) {
        navigationDirection = direction

        withAnimation(.easeInOut(duration: 0.28)) {
            currentStep = step
        }
    }

    private func requestLocationIfNeeded(for step: MomentCreationWorkflowStep) {
        guard MomentCreationLocationRefreshPolicy.shouldRefreshLocation(
            for: step,
            hasAutoRequestedLocation: hasAutoRequestedLocation
        ) else {
            return
        }

        hasAutoRequestedLocation = true
        locationService.refresh()
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

        if let ratio = album.ratio {
            return ratio
        }

        if let templateAspectRatio = album.templatePhotoAspectRatio {
            return CameraCaptureAspect.closest(to: CGFloat(templateAspectRatio))
        }

        if let latestMoment = mode.latestMoment,
           let imageSize = ImageResourceService.imageSize(from: latestMoment.photo),
           imageSize.width > 0,
           imageSize.height > 0 {
            return CameraCaptureAspect.closest(to: imageSize.width / imageSize.height)
        }

        return .threeByFour
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
            location: "West Lake, Hangzhou",
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
        MomentCreationView(
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
        MomentCreationView(
            mode: .newMoment(album: album),
            reminderClient: MomentCreationPreviewSupport.reminderClient
        )
    }
    .modelContainer(container)
}
#endif
