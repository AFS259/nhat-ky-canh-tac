import SwiftUI
import AVFoundation

struct CameraCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var camera = CameraController()
    @State private var preview: UIImage?
    let onCaptured: (UIImage) -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if !camera.authorized {
                permissionDenied
            } else if let preview {
                reviewOverlay(preview)
            } else {
                CameraPreview(session: camera.session)
                    .ignoresSafeArea()
                portraitGuide
                topBar
                shutter
            }
        }
        .onAppear { camera.start() }
        .onDisappear { camera.stop() }
        .onChange(of: camera.captured) { newValue in
            if let newValue { preview = newValue }
        }
        .statusBarHidden(false)
    }

    // MARK: - Khung hướng dẫn dựng đứng
    private var portraitGuide: some View {
        GeometryReader { geo in
            let width = geo.size.width * 0.8
            let height = min(geo.size.height * 0.62, width * 4 / 3)

            VStack {
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [10, 6]))
                        .foregroundColor(.white.opacity(0.55))
                        .frame(width: width, height: height)

                    VStack(spacing: 10) {
                        Image(systemName: "iphone.gen3")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                        Text("GIỮ ĐIỆN THOẠI THẲNG ĐỨNG")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .tracking(1)
                        Text("Đưa chủ thể vào giữa khung hình")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .padding(14)
                    .background(Capsule().fill(.black.opacity(0.35)))
                }
                .frame(maxWidth: .infinity)
                Spacer().frame(height: 150)
            }
        }
        .allowsHitTesting(false)
    }

    private var topBar: some View {
        VStack {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(.black.opacity(0.35)))
                }
                Spacer()
                Text("Chụp ảnh nhật ký")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Color.clear.frame(width: 40, height: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            Spacer()
        }
    }

    private var shutter: some View {
        VStack {
            Spacer()
            Button {
                camera.capture()
            } label: {
                ZStack {
                    Circle().strokeBorder(.white, lineWidth: 4).frame(width: 76, height: 76)
                    Circle().fill(.white).frame(width: 60, height: 60)
                }
            }
            .padding(.bottom, 34)
        }
    }

    private func reviewOverlay(_ image: UIImage) -> some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button {
                        preview = nil
                        camera.captured = nil
                    } label: {
                        Label("Chụp lại", systemImage: "arrow.counterclockwise")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(Capsule().fill(.black.opacity(0.45)))
                    }
                    Spacer()
                }
                .padding(16)

                Spacer()

                HStack(spacing: 14) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Hủy")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 15)
                            .background(RoundedRectangle(cornerRadius: 14).fill(.white.opacity(0.22)))
                    }
                    Button {
                        onCaptured(image)
                        dismiss()
                    } label: {
                        Label("Dùng ảnh", systemImage: "checkmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 15)
                            .background(RoundedRectangle(cornerRadius: 14).fill(AppTheme.primary))
                    }
                }
                .padding(20)
                .background(.black.opacity(0.35))
            }
        }
    }

    private var permissionDenied: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.metering.unknown")
                .font(.system(size: 46))
                .foregroundColor(.white)
            Text("Chưa được cấp quyền Camera")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
            Text("Vào Cài đặt > Nhật Ký Canh Tác > Camera để bật quyền.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.8))
            Button {
                dismiss()
            } label: {
                Text("Đóng")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 30).padding(.vertical, 13)
                    .background(Capsule().fill(AppTheme.primary))
            }
        }
        .padding(30)
    }
}

// MARK: - Preview layer
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewContainerView {
        let view = PreviewContainerView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewContainerView, context: Context) {}
}

final class PreviewContainerView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
