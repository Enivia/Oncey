#if os(iOS)
import AVFoundation
import Combine
import UIKit

final class CameraSessionController: NSObject, ObservableObject {
    enum AuthorizationState: Equatable {
        case unknown
        case authorized
        case denied
        case restricted
        case unavailable
    }

    enum CameraError: LocalizedError {
        case deviceUnavailable
        case configurationFailed
        case captureFailed
        case processingFailed

        var errorDescription: String? {
            switch self {
            case .deviceUnavailable:
                return "Camera is unavailable on this device."
            case .configurationFailed:
                return "Couldn't configure the camera session."
            case .captureFailed:
                return "Couldn't capture the photo."
            case .processingFailed:
                return "Couldn't process the captured photo."
            }
        }
    }

    @Published private(set) var authorizationState: AuthorizationState = .unknown
    @Published private(set) var isSessionConfigured = false
    @Published private(set) var isRunning = false
    @Published private(set) var currentPosition: AVCaptureDevice.Position = .back
    @Published private(set) var previewRotationAngle: CGFloat = CameraPreviewRotationResolver.resolve(captureRotationAngle: 90)
    @Published private(set) var videoRotationAngle: CGFloat = 90
    @Published private(set) var errorMessage: String?
    @Published var isFlashEnabled = false

    let session = AVCaptureSession()

    var isFlashAvailable: Bool {
        guard let device = videoInput?.device else {
            return false
        }

        return device.hasFlash
    }

    private let sessionQueue = DispatchQueue(label: "Oncey.CameraSessionController")
    private let photoOutput = AVCapturePhotoOutput()
    private var videoInput: AVCaptureDeviceInput?
    private var captureCompletion: ((Result<UIImage, Error>) -> Void)?
    private var isConfigured = false
    private var captureVideoRotationAngle: CGFloat = 90
    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
    private var captureRotationObservation: NSKeyValueObservation?

    func activate() {
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .video)

        switch currentStatus {
        case .authorized:
            authorizationState = .authorized
            configureAndStartIfNeeded()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor [weak self] in
                    guard let self else {
                        return
                    }

                    self.authorizationState = granted ? .authorized : .denied
                    if granted {
                        self.configureAndStartIfNeeded()
                    }
                }
            }
        case .denied:
            authorizationState = .denied
        case .restricted:
            authorizationState = .restricted
        @unknown default:
            authorizationState = .restricted
        }
    }

    func deactivate() {
        sessionQueue.async { [session] in
            guard session.isRunning else {
                return
            }

            session.stopRunning()
            Task { @MainActor in
                self.isRunning = false
            }
        }
    }

    func toggleCamera() {
        let nextPosition: AVCaptureDevice.Position = currentPosition == .back ? .front : .back
        reconfigureCameraInput(position: nextPosition)
    }

    func capturePhoto(completion: @escaping (Result<UIImage, Error>) -> Void) {
        guard authorizationState == .authorized else {
            completion(.failure(CameraError.deviceUnavailable))
            return
        }

        captureCompletion = completion

        sessionQueue.async {
            let settings = AVCapturePhotoSettings()

            if self.isFlashEnabled,
               self.photoOutput.supportedFlashModes.contains(.on) {
                settings.flashMode = .on
            } else {
                settings.flashMode = .off
            }

            self.applyCaptureRotationAngle(self.captureVideoRotationAngle)

            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    private func configureAndStartIfNeeded() {
        sessionQueue.async {
            if !self.isConfigured {
                do {
                    try self.configureSession(position: self.currentPosition)
                    self.isConfigured = true
                    Task { @MainActor in
                        self.isSessionConfigured = true
                        self.errorMessage = nil
                    }
                } catch {
                    self.isConfigured = false
                    Task { @MainActor in
                        self.authorizationState = .unavailable
                        self.errorMessage = error.localizedDescription
                    }
                    return
                }
            }

            guard !self.session.isRunning else {
                Task { @MainActor in
                    self.isRunning = true
                }
                return
            }

            self.session.startRunning()
            Task { @MainActor in
                self.isRunning = self.session.isRunning
            }
        }
    }

    private func configureSession(position: AVCaptureDevice.Position) throws {
        guard let device = makeDevice(for: position) else {
            throw CameraError.deviceUnavailable
        }

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        if session.canSetSessionPreset(.photo) {
            session.sessionPreset = .photo
        }

        if let existingInput = videoInput {
            session.removeInput(existingInput)
            videoInput = nil
        }

        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else {
            throw CameraError.configurationFailed
        }

        session.addInput(input)
        videoInput = input

        if !session.outputs.contains(photoOutput) {
            guard session.canAddOutput(photoOutput) else {
                throw CameraError.configurationFailed
            }

            session.addOutput(photoOutput)
        }

        updateRotationCoordinator(for: device)
        applyCaptureRotationAngle(captureVideoRotationAngle)

        Task { @MainActor in
            self.currentPosition = position
        }

        if !device.hasFlash {
            Task { @MainActor in
                self.isFlashEnabled = false
            }
        }
    }

    private func reconfigureCameraInput(position: AVCaptureDevice.Position) {
        sessionQueue.async {
            do {
                try self.configureSession(position: position)
                Task { @MainActor in
                    self.errorMessage = nil
                }
            } catch {
                Task { @MainActor in
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func makeDevice(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
            ?? AVCaptureDevice.default(for: .video)
    }

    private func updateRotationCoordinator(for device: AVCaptureDevice) {
        captureRotationObservation = nil
        rotationCoordinator = nil

        if #available(iOS 17.0, *) {
            let coordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: nil)
            rotationCoordinator = coordinator
            observeRotationUpdates(with: coordinator)
            return
        }

        updateVideoRotationAngle(90)
    }

    @available(iOS 17.0, *)
    private func observeRotationUpdates(with coordinator: AVCaptureDevice.RotationCoordinator) {
        captureRotationObservation = coordinator.observe(
            \.videoRotationAngleForHorizonLevelCapture,
            options: [.initial, .new]
        ) { [weak self] coordinator, _ in
            self?.updateVideoRotationAngle(coordinator.videoRotationAngleForHorizonLevelCapture)
        }
    }

    private func updateVideoRotationAngle(_ angle: CGFloat) {
        sessionQueue.async {
            self.applyCaptureRotationAngle(angle)

            Task { @MainActor in
                self.videoRotationAngle = angle
                self.previewRotationAngle = CameraPreviewRotationResolver.resolve(captureRotationAngle: angle)
            }
        }
    }

    private func applyCaptureRotationAngle(_ angle: CGFloat) {
        captureVideoRotationAngle = angle

        guard let connection = photoOutput.connection(with: .video),
              connection.isVideoRotationAngleSupported(angle) else {
            return
        }

        connection.videoRotationAngle = angle
    }

    private func finishCapture(with result: Result<UIImage, Error>) {
        let completion = captureCompletion
        captureCompletion = nil

        Task { @MainActor in
            if case .failure(let error) = result {
                self.errorMessage = error.localizedDescription
            }

            completion?(result)
        }
    }
}

extension CameraSessionController: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error {
            finishCapture(with: .failure(error))
            return
        }

        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            finishCapture(with: .failure(CameraError.processingFailed))
            return
        }

        finishCapture(with: .success(image))
    }
}
#endif