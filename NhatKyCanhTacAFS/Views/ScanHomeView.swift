import SwiftUI

struct ScanHomeView: View {
    @State private var scanning = false
    @State private var result: QRPayload?
    @State private var failure: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.screenGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        hero
                        scanButton
                        steps
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Quét QR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Quét mã QR nhật ký").font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                }
            }
            .fullScreenCover(isPresented: $scanning) {
                QRScannerView { outcome in
                    scanning = false
                    switch outcome {
                    case .success(let payload): result = payload
                    case .failure(let err): failure = err.errorDescription
                    }
                }
            }
            .sheet(item: $result) { payload in
                QRResultView(payload: payload)
            }
            .alert("Không đọc được mã", isPresented: Binding(get: { failure != nil }, set: { if !$0 { failure = nil } })) {
                Button("Đóng", role: .cancel) {}
            } message: {
                Text(failure ?? "")
            }
        }
    }

    private var scanButton: some View {
        Button {
            scanning = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "qrcode.viewfinder").font(.system(size: 19))
                Text("MỞ CAMERA QUÉT MÃ").font(.system(size: 15, weight: .bold))
            }
        }
        .buttonStyle(AFSPrimaryButtonStyle())
    }

    private var hero: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppTheme.heroGradient)
                    .frame(height: 150)
                VStack(spacing: 8) {
                    Image(systemName: "qrcode.viewfinder").font(.system(size: 44)).foregroundColor(.white)
                    Text("Quét mã QR để xem nhật ký vụ mùa")
                        .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                }
            }
        }
    }

    private var steps: some View {
        AFSCard {
            VStack(alignment: .leading, spacing: 14) {
                AFSSectionTitle(icon: "info.circle", title: "Hướng dẫn", subtitle: nil)
                stepRow(1, "Đưa mã QR của vụ mùa vào giữa khung hình.")
                stepRow(2, "Hệ thống giải mã key bảo mật AES-256.")
                stepRow(3, "Kiểm tra hạn: mã có hiệu lực theo thời gian.")
                stepRow(4, "Hiển thị toàn bộ bảng nhật ký (Mục 2).")
            }
        }
    }

    private func stepRow(_ index: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(index)")
                .font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(AppTheme.primary))
            Text(text).font(.system(size: 13)).foregroundColor(AppTheme.textPrimary)
            Spacer(minLength: 0)
        }
    }
}

extension QRPayload: Identifiable {
    var id: String { areaName + crop + issuedAt.description }
}

// MARK: - Camera quét
struct QRScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var scanner = QRScannerController()
    @State private var handled = false
    let onResult: (Result<QRPayload, QRServiceError>) -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if scanner.authorized {
                CameraPreview(session: scanner.session).ignoresSafeArea()
                scanFrame
                closeButton
            } else {
                denied
            }
        }
        .onAppear { scanner.start() }
        .onDisappear { scanner.stop() }
        .onChange(of: scanner.scannedCode) { code in
            guard let code, !handled else { return }
            handled = true
            let outcome = QRService.decode(token: code)
            onResult(outcome)
            if case .failure = outcome {
                // cho phép quét lại
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    handled = false
                    scanner.resume()
                }
            } else {
                dismiss()
            }
        }
    }

    private var scanFrame: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height) * 0.68
            VStack {
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(AppTheme.accent, lineWidth: 4)
                        .frame(width: side, height: side)
                    corner(side: side)
                    Text("Căn mã QR vào khung")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Capsule().fill(.black.opacity(0.4)))
                        .offset(y: side / 2 + 30)
                }
                Spacer().frame(height: geo.size.height * 0.16)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func corner(side: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .trim(from: 0, to: 0.2)
            .stroke(AppTheme.accent, style: StrokeStyle(lineWidth: 7, lineCap: .round))
            .frame(width: side, height: side)
    }

    private var closeButton: some View {
        VStack {
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(.black.opacity(0.4)))
                }
            }
            .padding(16)
            Spacer()
        }
    }

    private var denied: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.metering.unknown").font(.system(size: 44)).foregroundColor(.white)
            Text("Chưa được cấp quyền Camera").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
            Button { dismiss() } label: {
                Text("Đóng").foregroundColor(.white).padding(.horizontal, 26).padding(.vertical, 12)
                    .background(Capsule().fill(AppTheme.primary))
            }
        }
    }
}
