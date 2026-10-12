import SwiftUI

struct QRExportView: View {
    @Environment(\.dismiss) private var dismiss
    let areaName: String
    let crop: Crop

    @AppStorage("qrValidDays") private var storedDays: Int = QRService.defaultValidDays

    @State private var daysText: String = ""
    @State private var token: String = ""
    @State private var payload: QRPayload?
    @State private var errorText: String?
    @State private var showResult = false
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

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.screenGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        stepBar
                        header

                        if showResult, let payload {
                            resultSection(payload)
                        } else {
                            setupSection
                        }
                    }
                    .padding(20)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle(showResult ? "Mã QR vụ mùa" : "Xuất QR kết thúc vụ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") { dismiss() }.foregroundColor(.white)
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

    // MARK: - Step bar

    private var stepBar: some View {
        HStack(spacing: 10) {
            stepPill(index: 1, title: "Nhập thời hạn", active: !showResult)
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(AppTheme.textSecondary.opacity(0.5))
            stepPill(index: 2, title: "Mã QR", active: showResult)
        }
    }

    private func stepPill(index: Int, title: String, active: Bool) -> some View {
        HStack(spacing: 7) {
            Text("\(index)")
                .font(.system(size: 12, weight: .heavy))
                .foregroundColor(active ? .white : AppTheme.primary)
                .frame(width: 20, height: 20)
                .background(Circle().fill(active ? AppTheme.primary : AppTheme.primary.opacity(0.12)))
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(active ? AppTheme.primaryDark : AppTheme.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Capsule().fill(active ? AppTheme.accent.opacity(0.2) : Color.white.opacity(0.7)))
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(AppTheme.heroGradient).frame(width: 60, height: 60)
                Image(systemName: showResult ? "qrcode" : "hourglass")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(.white)
            }
            Text(showResult ? "Mã QR nhật ký vụ mùa" : "Chọn thời hạn cho mã QR")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
            Text("\(areaName) · \(crop.title)")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textSecondary)
        }
    }

    // MARK: - Step 1: setup

    private var setupSection: some View {
        VStack(spacing: 18) {
            durationCard
            expiryCard
            if let errorText {
                errorCard(errorText)
            }
            Button {
                daysFocused = false
                generate()
            } label: {
                Label("TẠO MÃ QR", systemImage: "qrcode")
            }
            .buttonStyle(AFSPrimaryButtonStyle())

            Text("Số ngày vừa nhập sẽ được ghi nhớ cho lần xuất kế tiếp.")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var durationCard: some View {
        AFSCard(padding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                AFSSectionTitle(icon: "hourglass", title: "Số ngày hiệu lực",
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

    // MARK: - Step 2: result

    private func resultSection(_ payload: QRPayload) -> some View {
        VStack(spacing: 18) {
            qrCard
            infoCard(payload)
            Button {
                dismiss()
            } label: {
                Text("ĐÓNG")
            }
            .buttonStyle(AFSPrimaryButtonStyle())

            Button {
                withAnimation { reset() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Tạo mã mới")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.primary)
            }
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

    private func reset() {
        showResult = false
        token = ""
        payload = nil
        errorText = nil
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
            withAnimation { showResult = true }
        } catch {
            errorText = "Không tạo được mã QR: \(error.localizedDescription)"
        }
    }
}

#Preview {
    QRExportView(areaName: "Vườn ổi sau nhà", crop: Crop.empty)
}
