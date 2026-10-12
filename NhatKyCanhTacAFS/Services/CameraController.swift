import AVFoundation
import UIKit
import Combine

final class CameraController: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {

    @Published var captured: UIImage?
    @Published var authorized = true

    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var configured = false
    private let queue = DispatchQueue(label: "afs.camera.session")

    func start() {
        requestPermission { [weak self] granted in
            guard let self else { return }
            DispatchQueue.main.async { self.authorized = granted }
            guard granted else { return }
            self.configureIfNeeded()
            self.queue.async {
                if !self.session.isRunning { self.session.startRunning() }
            }
        }
    }

    func stop() {
        queue.async {
            if self.session.isRunning { self.session.stopRunning() }
        }
    }

    func capture() {
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }

    private func requestPermission(_ completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { completion($0) }
        default:
            completion(false)
        }
    }

    private func configureIfNeeded() {
        guard !configured else { return }
        configured = true

        session.beginConfiguration()
        if session.canSetSessionPreset(.photo) { session.sessionPreset = .photo }

        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
        }
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        session.commitConfiguration()
    }

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        DispatchQueue.main.async { self.captured = image }
    }
}
