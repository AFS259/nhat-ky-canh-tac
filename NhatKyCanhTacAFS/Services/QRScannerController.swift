import AVFoundation
import Combine

final class QRScannerController: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {

    @Published var scannedCode: String?
    @Published var authorized = true

    let session = AVCaptureSession()
    private let output = AVCaptureMetadataOutput()
    private var configured = false
    private let queue = DispatchQueue(label: "afs.scanner.session")

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

    func resume() {
        scannedCode = nil
        queue.async {
            if !self.session.isRunning { self.session.startRunning() }
        }
    }

    private func requestPermission(_ completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: completion(true)
        case .notDetermined: AVCaptureDevice.requestAccess(for: .video) { completion($0) }
        default: completion(false)
        }
    }

    private func configureIfNeeded() {
        guard !configured else { return }
        configured = true
        session.beginConfiguration()
        if let device = AVCaptureDevice.default(for: .video),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
        }
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.qr]
        }
        session.commitConfiguration()
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard scannedCode == nil,
              let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              object.type == .qr,
              let value = object.stringValue else { return }
        scannedCode = value
        queue.async {
            if self.session.isRunning { self.session.stopRunning() }
        }
    }
}
