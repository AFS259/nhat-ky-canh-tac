import SwiftUI

private struct ViewerItem: Identifiable {
    let id = UUID()
    let names: [String]
    let index: Int
}

struct LogEntryView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss

    let areaID: UUID
    let cropID: UUID
    let existing: WorkLog?

    @State private var plantDate = Date()
    @State private var work: WorkType = .phanBonLa
    @State private var performDate = Date()
    @State private var note = ""
    @State private var images: [String] = []
    @State private var showCamera = false
    @State private var workSheet = false
    @State private var viewer: ViewerItem?

    private var locked: Bool {
        guard let existing else { return false }
        return !existing.isEditable
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.screenGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        if locked, let existing {
                            lockedBanner(existing)
                        }
                        formCard
                        imagesCard
                    }
                    .padding(18)
                    .padding(.bottom, 40)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle(existing == nil ? "Thêm nhật ký" : "Sửa nhật ký")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") { dismiss() }.foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Lưu") { save() }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .disabled(locked)
                }
            }
            .onAppear(perform: prefill)
            .fullScreenCover(isPresented: $showCamera) {
                CameraCaptureView { image in
                    if let name = ImageStore.save(image) { images.append(name) }
                }
            }
            .sheet(isPresented: $workSheet) {
                WorkPickerView(selected: work) { picked in
                    work = picked
                }
            }
            .sheet(item: $viewer) { item in
                ImageGalleryView(names: item.names, startIndex: item.index)
            }
        }
    }

    private func prefill() {
        guard let existing else { return }
        plantDate = existing.plantDate
        work = existing.work
        performDate = existing.performDate
        note = existing.note
        images = existing.images
    }

    private func lockedBanner(_ log: WorkLog) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill").foregroundColor(AppTheme.warning)
            VStack(alignment: .leading, spacing: 2) {
                Text("Đã khóa chỉnh sửa").font(.system(size: 13, weight: .bold)).foregroundColor(AppTheme.textPrimary)
                Text("Sau 1 ngày, thông tin đã nhập không thể chỉnh sửa (\(log.lockRemainingText)).")
                    .font(.system(size: 11)).foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(AppTheme.warning.opacity(0.12)))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(AppTheme.warning.opacity(0.4), lineWidth: 1))
    }

    private var formCard: some View {
        AFSCard {
            VStack(spacing: 16) {
                AFSLabeledField(title: "Ngày trồng", icon: "calendar.badge.plus") {
                    dateField($plantDate)
                }
                AFSLabeledField(title: "Công việc", icon: "list.bullet.rectangle.portrait") {
                    workButton
                }
                AFSLabeledField(title: "Ngày thực hiện", icon: "calendar") {
                    dateField($performDate)
                }
                AFSLabeledField(title: "Ghi chú", icon: "note.text") {
                    TextField("Nhập ghi chú công việc...", text: $note, axis: .vertical)
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.textPrimary)
                        .lineLimit(2...5)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(hex: 0xF6FBF1)))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(AppTheme.line, lineWidth: 1))
                }
            }
        }
        .disabled(locked)
        .opacity(locked ? 0.7 : 1)
    }

    private func dateField(_ binding: Binding<Date>) -> some View {
        DatePicker("", selection: binding, displayedComponents: .date)
            .datePickerStyle(.compact)
            .labelsHidden()
            .environment(\.locale, Locale(identifier: "vi_VN"))
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(hex: 0xF6FBF1)))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(AppTheme.line, lineWidth: 1))
    }

    private var workButton: some View {
        Button {
            workSheet = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: work.icon).foregroundColor(AppTheme.primary)
                Text(work.rawValue).font(.system(size: 15, weight: .medium)).foregroundColor(AppTheme.textPrimary)
                Spacer()
                Image(systemName: "chevron.up.chevron.down").font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(hex: 0xF6FBF1)))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(AppTheme.line, lineWidth: 1))
        }
    }

    private var imagesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            AFSSectionTitle(icon: "camera.fill", title: "Hình ảnh", subtitle: "Chụp ảnh minh chứng (điện thoại dựng đứng)")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    Button {
                        showCamera = true
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "camera.fill").font(.system(size: 22))
                            Text("Chụp").font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(AppTheme.primary)
                        .frame(width: 84, height: 84)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(AppTheme.primary.opacity(0.1)))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                            .foregroundColor(AppTheme.primary.opacity(0.5)))
                    }
                    .disabled(locked)

                    ForEach(images, id: \.self) { name in
                        ZStack(alignment: .topTrailing) {
                            if let img = ImageStore.load(name) {
                                Image(uiImage: img)
                                    .resizable().scaledToFill()
                                    .frame(width: 84, height: 84)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .onTapGesture { viewer = ViewerItem(names: images, index: images.firstIndex(of: name) ?? 0) }
                            }
                            if !locked {
                                Button {
                                    ImageStore.delete(name)
                                    images.removeAll { $0 == name }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Circle().fill(AppTheme.danger))
                                }
                                .padding(4)
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }

            HStack(spacing: 6) {
                Image(systemName: "iphone.gen3").font(.system(size: 11))
                Text("Quy định: giữ điện thoại thẳng đứng, để chủ thể trong khung xanh.")
                    .font(.system(size: 11))
            }
            .foregroundColor(AppTheme.textSecondary)
        }
    }

    private func save() {
        guard !locked else { return }
        app.updateArea(id: areaID) { area in
            guard let ci = area.crops.firstIndex(where: { $0.id == cropID }) else { return }
            if let existing,
               let li = area.crops[ci].logs.firstIndex(where: { $0.id == existing.id }) {
                var log = existing
                log.plantDate = plantDate
                log.work = work
                log.performDate = performDate
                log.note = note
                log.images = images
                area.crops[ci].logs[li] = log
            } else {
                let log = WorkLog(plantDate: plantDate, work: work, performDate: performDate, note: note, images: images)
                area.crops[ci].logs.append(log)
            }
        }
        dismiss()
    }
}

// MARK: - Listbox chọn công việc
struct WorkPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let selected: WorkType
    let onSelect: (WorkType) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.screenGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(WorkType.allCases) { type in
                            Button {
                                onSelect(type)
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    AFSIconBadge(icon: type.icon, color: type == selected ? AppTheme.primary : AppTheme.textSecondary)
                                    Text(type.rawValue)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(AppTheme.textPrimary)
                                    Spacer()
                                    if type == selected {
                                        Image(systemName: "checkmark.circle.fill").foregroundColor(AppTheme.primary)
                                    }
                                }
                                .padding(14)
                                .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(type == selected ? AppTheme.accent.opacity(0.16) : .white))
                                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(type == selected ? AppTheme.primary : AppTheme.line, lineWidth: 1))
                            }
                        }
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Chọn công việc")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") { dismiss() }.foregroundColor(.white)
                }
            }
        }
    }
}
