#if os(iOS)
import PhotosUI
import SwiftUI
import UIKit

struct CameraView: View {
    let template: ExtractPhotoTemplate?
    let onImagePicked: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var camera = CameraSessionController()
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isPhotoPickerPresented = false
    @State private var selectedAspect: CameraCaptureAspect = .threeByFour
    @State private var showsMaskOutline = true
    @State private var errorMessage: String?
    @State private var isPresentingError = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: AppTheme.Spacing.s4) {
                    topBar
                        .padding(.horizontal, AppTheme.Spacing.s6)
                    previewArea()
                    bottomBar
                        .padding(.horizontal, AppTheme.Spacing.s6)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, topInset(for: proxy))
                .padding(.bottom, bottomInset(for: proxy))
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .photosPicker(
            isPresented: $isPhotoPickerPresented,
            selection: $selectedPhotoItem,
            matching: .images,
            preferredItemEncoding: .current
        )
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else {
                return
            }

            Task {
                await loadSelectedImage(from: newItem)
            }
        }
        .onAppear {
            camera.activate()
        }
        .onDisappear {
            camera.deactivate()
        }
        .onChange(of: camera.errorMessage) { _, newValue in
            guard let newValue else {
                return
            }

            present(newValue)
        }
        .alert("Couldn't continue", isPresented: $isPresentingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }

    private var topBar: some View {
        HStack {
            buttonCircle {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .semibold))
            }

            Spacer(minLength: AppTheme.Spacing.s4)

            HStack(spacing: AppTheme.Spacing.s3) {
                buttonCircle {
                    guard camera.isFlashAvailable else {
                        return
                    }

                    camera.isFlashEnabled.toggle()
                } label: {
                    Image(systemName: camera.isFlashEnabled ? "bolt.fill" : "bolt.slash.fill")
                        .font(.system(size: 16, weight: .semibold))
                }
                .disabled(!camera.isFlashAvailable)
                .opacity(camera.isFlashAvailable ? 1 : 0.45)

                buttonCircle {
                    showsMaskOutline.toggle()
                } label: {
                    Image(systemName: showsMaskOutline ? "square.stack.3d.up.fill" : "square.stack.3d.up")
                        .font(.system(size: 16, weight: .semibold))
                }
                .disabled(!canToggleMaskOutline)
                .opacity(canToggleMaskOutline ? 1 : 0.45)
                .accessibilityLabel(showsMaskOutline ? "Hide mask outline" : "Show mask outline")

                Button {
                    selectedAspect = selectedAspect.next
                } label: {
                    Text(selectedAspect.label)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppTheme.Spacing.s4)
                        .frame(height: 40)
                        .background(.white.opacity(0.15), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .foregroundStyle(.white)
    }

    private func previewArea() -> some View {
        GeometryReader { previewProxy in
            let previewSize = previewFrameSize(in: previewProxy.size)

            ZStack {
                if camera.authorizationState == .authorized, camera.isSessionConfigured {
                    CameraPreviewView(session: camera.session)
                        .frame(width: previewSize.width, height: previewSize.height)
                        .overlay {
                            Rectangle()
                                .stroke(.white.opacity(0.18), lineWidth: 1)
                        }
                        .overlay(alignment: .center) {
                            templateMaskOverlay(in: previewSize)
                        }
                } else {
                    Rectangle()
                        .fill(.white.opacity(0.08))
                        .frame(width: previewSize.width, height: previewSize.height)
                        .overlay {
                            permissionStateView
                                .padding(AppTheme.Spacing.s6)
                        }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func templateMaskOverlay(in previewSize: CGSize) -> some View {
        Group {
            if showsMaskOutline,
               let template,
               let outlineImage = template.outlineImage,
               let layout = CameraGeometry.maskLayout(for: template.photoSize, in: previewSize) {
                OutlineMaskImageView(image: outlineImage, opacity: 0.9, expansion: 1.4)
                    .rotationEffect(.degrees(layout.rotationDegrees))
                    .frame(width: layout.frame.width, height: layout.frame.height)
                    .position(x: layout.frame.midX, y: layout.frame.midY)
                .allowsHitTesting(false)
                .frame(width: previewSize.width, height: previewSize.height)
            } else {
                EmptyView()
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

            if showsSettingsButton {
                Button("Open Settings") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else {
                        return
                    }

                    UIApplication.shared.open(url)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.Colors.accent)
                .foregroundStyle(.black)
            }
        }
    }

    private var bottomBar: some View {
        HStack {
            Button {
                isPhotoPickerPresented = true
            } label: {
                Image(systemName: "photo.on.rectangle")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 76, height: 76)
            }
            .buttonStyle(.plain)

            Spacer(minLength: AppTheme.Spacing.s7)

            Button {
                camera.capturePhoto { result in
                    switch result {
                    case .success(let image):
                        let croppedImage = CameraImageCropper.croppedImage(image, aspect: selectedAspect)
                        onImagePicked(croppedImage)
                        dismiss()
                    case .failure(let error):
                        present(error.localizedDescription)
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 86, height: 86)

                    Circle()
                        .stroke(.white.opacity(0.4), lineWidth: 2)
                        .frame(width: 76, height: 76)

                    Circle()
                        .fill(.white)
                        .frame(width: 64, height: 64)
                }
            }
            .buttonStyle(.plain)
            .disabled(camera.authorizationState != .authorized || !camera.isSessionConfigured)
            .opacity(camera.authorizationState == .authorized && camera.isSessionConfigured ? 1 : 0.55)

            Spacer(minLength: AppTheme.Spacing.s7)

            Button {
                camera.toggleCamera()
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 76, height: 76)
            }
            .buttonStyle(.plain)
            .disabled(camera.authorizationState != .authorized)
            .opacity(camera.authorizationState == .authorized ? 1 : 0.55)
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

    private var showsSettingsButton: Bool {
        camera.authorizationState == .denied
    }

    private var canToggleMaskOutline: Bool {
        template?.outlineImage != nil
    }

    private func previewFrameSize(in containerSize: CGSize) -> CGSize {
        let availableSize = CGSize(
            width: max(containerSize.width, 1),
            height: max(containerSize.height, 1)
        )
        let sourceSize = CGSize(width: selectedAspect.aspectRatio * 1_000, height: 1_000)
        return CameraGeometry.fittedSize(for: sourceSize, in: availableSize)
    }

    private func topInset(for proxy: GeometryProxy) -> CGFloat {
        proxy.safeAreaInsets.top + AppTheme.Spacing.s2
    }

    private func bottomInset(for proxy: GeometryProxy) -> CGFloat {
        max(proxy.safeAreaInsets.bottom, AppTheme.Spacing.s8)
    }

    private func buttonCircle(action: @escaping () -> Void, label: @escaping () -> some View) -> some View {
        Button(action: action) {
            label()
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(.white.opacity(0.15), in: Circle())
        }
        .buttonStyle(.plain)
    }

    private func loadSelectedImage(from item: PhotosPickerItem) async {
        do {
            let image = try await PhotosPickerImageLoader.loadImage(from: item)
            onImagePicked(image)
            dismiss()
        } catch {
            present(error.localizedDescription)
        }

        selectedPhotoItem = nil
    }

    private func present(_ message: String) {
        errorMessage = message
        isPresentingError = true
    }
}

#Preview {
    CameraView(template: nil) { _ in }
}
#endif
