import SwiftUI
import UIKit

struct QRExportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var app: AppState
    let areaID: UUID
    let areaName: String
    let crop: Crop

    @AppStorage("qrValidDays") private var storedDays: Int = QRService.defaultValidDays

    @State private var daysText: String = ""
    @State private var token: String = ""
    @State private var payload: QRPayload?
    @State private var errorText: String?
    @State private var locked = false
    @FocusState private var daysFocused: Bool

    private let dayOptions = [7, 10, 30, 60, 90]
    private let minDays = 1
    private let maxDays = 365

    private var validDays: Int {
        let parsed = Int(daysText) ?? storedDays
        return min(max(parsed, minDays), maxDays)
    }

    private var expiryPreview: Date {
        Calendar.current.date(byAdding: .day, value: validDays, to: Date()) ?? Date()
    }

    private var currentStep: Int {
        locked ? 2 : 1
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.screenGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        header

                        if locked, let payload {
                            lockedSection(payload)
                        } else {
                            stepBar
                            durationCard
                            expiryCard
                            if let errorText {
                                errorCard(errorText)
                            }
                            generateButton
                        }
                    }
                    .padding(20)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Kết thúc vụ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(locked ? "Đóng" : "Hủy") { dismiss() }.foregroundColor(.white)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Xong") { daysFocused = false }
                }
            }
            .onAppear {
                if daysText.isEmpty { daysText = "\(storedDays)" }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(AppTheme.heroGradient).frame(width: 60, height: 60)
                Image(systemName: locked ? "checkmark.seal.fill" : "leaf.circle.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(.white)
            }
            Text(locked ? "Đã xuất mã QR" : "Kết thúc vụ · Xuất mã QR")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
            Text("\(areaName) · \(crop.title)")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textSecondary)
        }
    }

    // MARK: - Step bar

    private var stepBar: some View {
        HStack(spacing: 8) {
            stepPill(index: 1, title: "Thời hạn", active: currentStep == 1)
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(AppTheme.textSecondary.opacity(0.5))
            stepPill(index: 2, title: "Mã QR", active: currentStep == 2)
        }
    }

    private func stepPill(index: Int, title: String, active: Bool) -> some View {
        HStack(spacing: 6) {
            Text("\(index)")
                .font(.system(size: 11, weight: .heavy))
                .foregroundColor(active ? .white : AppTheme.primary)
                .frame(width: 19, height: 19)
                .background(Circle().fill(active ? AppTheme.primary : AppTheme.primary.opacity(0.12)))
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(active ? AppTheme.primaryDark : AppTheme.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(active ? AppTheme.accent.opacity(0.2) : Color.white.opacity(0.7)))
    }

    // MARK: - Step 1: Duration

    private var durationCard: some View {
        AFSCard(padding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                AFSSectionTitle(icon: "hourglass", title: "Bước 1 · Số ngày hiệu lực",
                                subtitle: "Mã QR còn hiệu lực kể từ khi tạo.")

                HStack(spacing: 18) {
                    stepperButton("minus") { adjust(-1) }

                    VStack(spacing: 2) {
                        Text("\(validDays)")
                            .font(.system(size: 46, weight: .heavy))
                            .foregroundColor(AppTheme.primaryDark)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        Text("ngày")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .frame(width: 130)

                    stepperButton("plus") { adjust(1) }
                }
                .frame(maxWidth: .infinity)

                AFSLabeledField(title: "Hoặc nhập số ngày chính xác", icon: "number") {
                    AFSTextField(placeholder: "VD: 10", text: $daysText, keyboard: .numberPad)
                        .focused($daysFocused)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Chọn nhanh")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)
                    HStack(spacing: 8) {
                        ForEach(dayOptions, id: \.self) { d in
                            Button {
                                daysText = "\(d)"
                            } label: {
                                Text("\(d)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(validDays == d ? .white : AppTheme.primaryDark)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(validDays == d ? AppTheme.primary : AppTheme.accent.opacity(0.16))
                                    )
                            }
                        }
                    }
                }

                Text("Giới hạn từ \(minDays) đến \(maxDays) ngày.")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }

    private var expiryCard: some View {
        AFSCard {
            VStack(alignment: .leading, spacing: 12) {
                AFSSectionTitle(icon: "calendar.badge.clock", title: "Dự kiến hiệu lực", subtitle: nil)
                row(icon: "calendar", title: "Ngày xuất", value: Fmt.dayTime.string(from: Date()))
                Divider().overlay(AppTheme.line)
                row(icon: "hourglass.bottomhalf.filled", title: "Hết hạn",
                    value: Fmt.day.string(from: expiryPreview), highlight: true)
            }
        }
    }

    private var generateButton: some View {
        VStack(spacing: 10) {
            Button {
                daysFocused = false
                generate()
            } label: {
                Label("XUẤT QR", systemImage: "qrcode")
            }
            .buttonStyle(AFSPrimaryButtonStyle())
            Text("Sau khi xuất, mã QR sẽ được khóa và không thể chỉnh lại.")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Step 2: Locked result

    private func lockedSection(_ payload: QRPayload) -> some View {
        VStack(spacing: 18) {
            HStack(spacing: 10) {
                Image(systemName: "lock.fill").foregroundColor(.white)
                Text("Mã QR đã xuất và khóa — không thể chỉnh sửa lại.")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Spacer(minLength: 0)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(AppTheme.primary))
            .shadow(color: AppTheme.primary.opacity(0.25), radius: 8, y: 4)

            qrCard
            infoCard(payload)

            Button {
                dismiss()
            } label: {
                Text("ĐÓNG")
            }
            .buttonStyle(AFSPrimaryButtonStyle())
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
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill")
                    Text("\(crop.logs.count) dòng dữ liệu · AES-256")
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppTheme.primary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func infoCard(_ payload: QRPayload) -> some View {
        AFSCard {
            VStack(alignment: .leading, spacing: 12) {
                row(icon: "calendar.badge.clock", title: "Ngày xuất",
                    value: Fmt.dayTime.string(from: payload.issuedAt))
                Divider().overlay(AppTheme.line)
                row(icon: "hourglass.bottomhalf.filled", title: "Hết hạn",
                    value: Fmt.day.string(from: payload.expiresAt), highlight: true)
                Divider().overlay(AppTheme.line)
                HStack(spacing: 8) {
                    Image(systemName: "link").foregroundColor(AppTheme.primary)
                    Text("Mã QR đã được lưu lên Google Sheet (sheet \"Mã QR\") theo khu vực & mùa vụ để tra cứu lại.")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                }
                Divider().overlay(AppTheme.line)
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill").foregroundColor(AppTheme.gold)
                    Text("Mã QR có hiệu lực \(validDays) ngày kể từ khi xuất. Quá hạn sẽ không quét được.")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
    }

    // MARK: - Helpers

    private func row(icon: String, title: String, value: String, highlight: Bool = false) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(highlight ? AppTheme.warning : AppTheme.primary)
                .frame(width: 22)
            Text(title).font(.system(size: 13)).foregroundColor(AppTheme.textSecondary)
            Spacer()
            Text(value).font(.system(size: 13, weight: .bold))
                .foregroundColor(highlight ? AppTheme.warning : AppTheme.textPrimary)
        }
    }

    private func stepperButton(_ system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppTheme.primary)
                .frame(width: 54, height: 54)
                .background(Circle().fill(AppTheme.accent.opacity(0.18)))
                .overlay(Circle().stroke(AppTheme.accent.opacity(0.45), lineWidth: 1))
        }
        .disabled(system == "minus" && validDays <= minDays)
        .disabled(system == "plus" && validDays >= maxDays)
    }

    private func errorCard(_ text: String) -> some View {
        AFSCard {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(AppTheme.danger)
                Text(text).font(.system(size: 13)).foregroundColor(AppTheme.textPrimary)
            }
        }
    }

    private func adjust(_ delta: Int) {
        daysText = "\(min(max(validDays + delta, minDays), maxDays))"
    }

    private func generate() {
        let days = validDays
        do {
            let result = try QRService.makeToken(areaName: areaName, crop: crop, validDays: days)
            storedDays = days
            daysText = "\(days)"
            token = result.token
            payload = result.payload
            errorText = nil
            withAnimation { locked = true }

            // Lưu mã QR lên Google Sheet dạng link, gắn theo khu vực + mùa vụ.
            let qrImage = QRService.image(from: result.token, size: 512)
            let area = app.areas.first(where: { $0.id == areaID })
            GoogleSheetService.syncQR(areaID: areaID, areaName: areaName,
                                       areaAddress: area?.address ?? "",
                                       areaLatitude: area?.latitude,
                                       areaLongitude: area?.longitude,
                                       crop: crop,
                                       validDays: days,
                                       issuedAt: result.payload.issuedAt,
                                       expiresAt: result.payload.expiresAt,
                                       token: result.token, qrImage: qrImage,
                                       username: app.currentUser?.username ?? "") {
                app.resyncArea(id: areaID)
            }
        } catch {
            errorText = "Không tạo được mã QR: \(error.localizedDescription)"
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    QRExportView(areaID: UUID(), areaName: "Vườn ổi sau nhà", crop: Crop.empty)
        .environmentObject(AppState())
}
