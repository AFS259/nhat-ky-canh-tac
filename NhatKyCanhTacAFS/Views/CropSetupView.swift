import SwiftUI

struct CropSetupView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss

    let areaID: UUID

    @State private var step = 0
    @State private var cropType = ""
    @State private var variety = ""
    @State private var areaText = ""
    @State private var seedText = ""
    @State private var sowDate = Date()
    @State private var plantCountText = ""
    @State private var plantDate = Date()

    private let totalSteps = 5

    private var suggestedVarieties: [String] {
        CropCatalog.varieties(for: cropType)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.screenGradient.ignoresSafeArea()

                VStack(spacing: 0) {
                    progressHeader
                    ScrollView {
                        VStack(spacing: 18) {
                            stepContent
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    bottomBar
                }
            }
            .navigationTitle("Thêm cây trồng")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") { dismiss() }.foregroundColor(.white)
                }
            }
        }
    }

    // MARK: - Progress
    private var progressHeader: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                ForEach(0..<totalSteps, id: \.self) { i in
                    Capsule()
                        .fill(i <= step ? AppTheme.primary : AppTheme.primary.opacity(0.18))
                        .frame(height: 5)
                }
            }
            HStack {
                Text("Bước \(step + 1)/\(totalSteps)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.primary)
                Spacer()
                Text(stepTitle)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 4)
    }

    private var stepTitle: String {
        ["Loại cây", "Giống", "Diện tích", "Gieo hạt", "Trồng cây"][step]
    }

    // MARK: - Step content
    @ViewBuilder private var stepContent: some View {
        switch step {
        case 0: cropTypeStep
        case 1: varietyStep
        case 2: areaStep
        case 3: seedStep
        case 4: plantStep
        default: EmptyView()
        }
    }

    private var cropTypeStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepHeader(icon: "camera.macro", title: "Bạn trồng loại cây gì?",
                       subtitle: "Chọn nhanh hoặc tự nhập tên loại cây.")
            AFSTextField(placeholder: "VD: Ổi", text: $cropType)

            if !cropType.trimmingCharacters(in: .whitespaces).isEmpty {
                HStack(spacing: 10) {
                    Image(CropCatalog.asset(for: cropType))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                    Text("Biểu tượng nhận diện · \(cropType)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.primaryDark)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(AppTheme.accent.opacity(0.18)))
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                ForEach(CropCatalog.items) { item in
                    Button {
                        cropType = item.name
                        variety = ""
                    } label: {
                        HStack(spacing: 6) {
                            Image(item.asset)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                            Text(item.name).font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(cropType == item.name ? .white : AppTheme.primaryDark)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .fill(cropType == item.name ? AppTheme.primary : AppTheme.accent.opacity(0.16))
                        )
                    }
                }
            }
        }
    }

    private var varietyStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepHeader(icon: "arrow.triangle.branch", title: "Chọn giống \(cropType)",
                       subtitle: "Giống quyết định năng suất và kỹ thuật chăm sóc.")
            AFSTextField(placeholder: "VD: Ổi Đài Loan", text: $variety)

            if !suggestedVarieties.isEmpty {
                Text("Gợi ý giống")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)
                VStack(spacing: 10) {
                    ForEach(suggestedVarieties, id: \.self) { v in
                        Button { variety = v } label: {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(variety == v ? AppTheme.primary : AppTheme.textSecondary.opacity(0.4))
                                Text(v).font(.system(size: 14, weight: .medium)).foregroundColor(AppTheme.textPrimary)
                                Spacer()
                            }
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(variety == v ? AppTheme.accent.opacity(0.16) : .white))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(variety == v ? AppTheme.primary : AppTheme.line, lineWidth: 1))
                        }
                    }
                }
            }
        }
    }

    private var areaStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepHeader(icon: "arrow.up.left.and.arrow.down.right", title: "Nhập diện tích",
                       subtitle: "Diện tích khu vực canh tác (mét vuông).")
            AFSTextField(placeholder: "VD: 500", text: $areaText, keyboard: .decimalPad)
            if let v = Double(areaText.replacingOccurrences(of: ",", with: ".")) {
                infoChip(icon: "checkmark.circle.fill", text: "≈ \(Fmt.number(v)) m²")
            }
        }
    }

    private var seedStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepHeader(icon: "leaf.arrow.circlepath", title: "Số hạt gieo",
                       subtitle: "Nhập số hạt và chọn ngày gieo.")
            AFSLabeledField(title: "Số hạt gieo", icon: "number") {
                AFSTextField(placeholder: "VD: 1200", text: $seedText, keyboard: .numberPad)
            }
            AFSLabeledField(title: "Ngày gieo", icon: "calendar") {
                DatePicker("", selection: $sowDate, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "vi_VN"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(hex: 0xF6FBF1)))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(AppTheme.line, lineWidth: 1))
            }
        }
    }

    private var plantStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepHeader(icon: "tree.fill", title: "Số cây trồng",
                       subtitle: "Nhập số cây và chọn ngày trồng.")
            AFSLabeledField(title: "Số cây trồng", icon: "number") {
                AFSTextField(placeholder: "VD: 300", text: $plantCountText, keyboard: .numberPad)
            }
            AFSLabeledField(title: "Ngày trồng", icon: "calendar") {
                DatePicker("", selection: $plantDate, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "vi_VN"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(hex: 0xF6FBF1)))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(AppTheme.line, lineWidth: 1))
            }
            summaryCard
        }
    }

    private var summaryCard: some View {
        AFSCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tóm tắt vụ").font(.system(size: 14, weight: .bold)).foregroundColor(AppTheme.textPrimary)
                summaryRow("Loại cây", cropType)
                summaryRow("Giống", variety)
                summaryRow("Diện tích", "\(areaText) m²")
                summaryRow("Hạt gieo", "\(seedText) · \(Fmt.day.string(from: sowDate))")
                summaryRow("Cây trồng", "\(plantCountText) · \(Fmt.day.string(from: plantDate))")
            }
        }
    }

    private func summaryRow(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
            Spacer()
            Text(v.isEmpty ? "—" : v).font(.system(size: 12, weight: .semibold)).foregroundColor(AppTheme.textPrimary)
        }
    }

    // MARK: - Shared pieces
    private func stepHeader(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            AFSIconBadge(icon: icon)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 18, weight: .bold)).foregroundColor(AppTheme.textPrimary)
                Text(subtitle).font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(.bottom, 2)
    }

    private func infoChip(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundColor(AppTheme.primary)
            Text(text).font(.system(size: 13, weight: .semibold)).foregroundColor(AppTheme.primaryDark)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Capsule().fill(AppTheme.accent.opacity(0.18)))
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            if step > 0 {
                Button {
                    withAnimation { step -= 1 }
                } label: {
                    Label("Quay lại", systemImage: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(AppTheme.primary.opacity(0.1)))
                }
            }
            Button {
                if step < totalSteps - 1 {
                    withAnimation { step += 1 }
                } else {
                    save()
                }
            } label: {
                Text(step < totalSteps - 1 ? "Tiếp tục" : "LƯU VỤ")
            }
            .buttonStyle(AFSPrimaryButtonStyle())
            .disabled(!canContinue)
            .opacity(canContinue ? 1 : 0.5)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.white.shadow(.drop(color: AppTheme.cardShadow, radius: 8, y: -2)))
    }

    private var canContinue: Bool {
        switch step {
        case 0: return !cropType.trimmingCharacters(in: .whitespaces).isEmpty
        case 1: return !variety.trimmingCharacters(in: .whitespaces).isEmpty
        case 2: return Double(areaText.replacingOccurrences(of: ",", with: ".")) != nil
        case 3: return Int(seedText) != nil
        case 4: return Int(plantCountText) != nil
        default: return false
        }
    }

    private func save() {
        let crop = Crop(
            cropType: cropType.trimmingCharacters(in: .whitespaces),
            variety: variety.trimmingCharacters(in: .whitespaces),
            areaM2: Double(areaText.replacingOccurrences(of: ",", with: ".")) ?? 0,
            seedCount: Int(seedText) ?? 0,
            sowDate: sowDate,
            plantCount: Int(plantCountText) ?? 0,
            plantDate: plantDate
        )
        app.updateArea(id: areaID) { $0.crops.append(crop) }
        dismiss()
    }
}
