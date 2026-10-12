import SwiftUI

struct QRExportView: View {
    @Environment(\.dismiss) private var dismiss
    let areaName: String
    let crop: Crop

    @State private var token: String = ""
    @State private var payload: QRPayload?
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.screenGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        header

                        if let errorText {
                            errorCard(errorText)
                        } else {
                            qrCard
                            infoCard
                        }

                        Button {
                            dismiss()
                        } label: {
                            Text("ĐÓNG")
                        }
                        .buttonStyle(AFSPrimaryButtonStyle())
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Xuất QR kết thúc vụ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") { dismiss() }.foregroundColor(.white)
                }
            }
            .onAppear(perform: generate)
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(AppTheme.heroGradient).frame(width: 60, height: 60)
                Image(systemName: "qrcode").font(.system(size: 26, weight: .semibold)).foregroundColor(.white)
            }
            Text("Mã QR nhật ký vụ mùa")
                .font(.system(size: 17, weight: .bold)).foregroundColor(AppTheme.textPrimary)
            Text("\(areaName) · \(crop.title)")
                .font(.system(size: 13)).foregroundColor(AppTheme.textSecondary)
        }
    }

    private var qrCard: some View {
        AFSCard(padding: 20) {
            VStack(spacing: 14) {
                if let image = QRService.image(from: token, size: 260) {
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 260, height: 260)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 16).fill(.white))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.line, lineWidth: 1))
                }
                Text("Đã mã hóa toàn bộ Mục 2 thành key bảo mật")
                    .font(.system(size: 12, weight: .medium)).foregroundColor(AppTheme.textSecondary)
                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill")
                    Text("\(crop.logs.count) dòng dữ liệu · AES-256")
                }
                .font(.system(size: 11, weight: .semibold)).foregroundColor(AppTheme.primary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var infoCard: some View {
        AFSCard {
            VStack(alignment: .leading, spacing: 12) {
                row(icon: "calendar.badge.clock", title: "Ngày xuất",
                    value: payload.map { Fmt.dayTime.string(from: $0.issuedAt) } ?? "—")
                Divider().overlay(AppTheme.line)
                row(icon: "hourglass.bottomhalf.filled", title: "Hết hạn",
                    value: payload.map { Fmt.day.string(from: $0.expiresAt) } ?? "—", highlight: true)
                Divider().overlay(AppTheme.line)
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill").foregroundColor(AppTheme.gold)
                    Text("Mã QR có hạn tối đa \(QRService.validDays) ngày kể từ khi xuất. Quá hạn sẽ không quét được.")
                        .font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
                }
            }
        }
    }

    private func row(icon: String, title: String, value: String, highlight: Bool = false) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(highlight ? AppTheme.warning : AppTheme.primary).frame(width: 22)
            Text(title).font(.system(size: 13)).foregroundColor(AppTheme.textSecondary)
            Spacer()
            Text(value).font(.system(size: 13, weight: .bold))
                .foregroundColor(highlight ? AppTheme.warning : AppTheme.textPrimary)
        }
    }

    private func errorCard(_ text: String) -> some View {
        AFSCard {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(AppTheme.danger)
                Text(text).font(.system(size: 13)).foregroundColor(AppTheme.textPrimary)
            }
        }
    }

    private func generate() {
        do {
            let result = try QRService.makeToken(areaName: areaName, crop: crop)
            token = result.token
            payload = result.payload
        } catch {
            errorText = "Không tạo được mã QR: \(error.localizedDescription)"
        }
    }
}
