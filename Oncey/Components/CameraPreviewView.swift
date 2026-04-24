#if os(iOS)
import AVFoundation
import SwiftUI
import UIKit

final class CameraPreviewContainerView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewContainerView {
        let view = CameraPreviewContainerView()
        view.backgroundColor = .black
        view.previewLayer.videoGravity = .resizeAspectFill
        view.previewLayer.session = session
        applyPortraitRotation(to: view.previewLayer)
        return view
    }

    func updateUIView(_ uiView: CameraPreviewContainerView, context: Context) {
        uiView.previewLayer.session = session
        applyPortraitRotation(to: uiView.previewLayer)
    }

    private func applyPortraitRotation(to previewLayer: AVCaptureVideoPreviewLayer) {
        guard let connection = previewLayer.connection,
              connection.isVideoRotationAngleSupported(90) else {
            return
        }

        connection.videoRotationAngle = 90
    }
}
#endif