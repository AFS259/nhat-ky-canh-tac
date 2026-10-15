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
    @State private var work: String = WorkCatalog.builtins.first?.name ?? ""
    @State private var performer: String = ""
    @State private var performDate = Date()
    @State private var note = ""
    @State private var images: [String] = []
    @State private var showCamera = false
    @State private var workSheet = false
    @State private var performerSheet = false
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
            .sheet(isPresented: $performerSheet) {
                PerformerPickerView(selected: performer) { picked in
                    performer = picked
                }
            }
            .sheet(item: $viewer) { item in
                ImageGalleryView(names: item.names, startIndex: item.index)
            }
        }
    }

    private func prefill() {
        guard let existing else {
            if work.isEmpty { work = app.workItems.first?.name ?? "" }
            return
        }
        plantDate = existing.plantDate
        work = existing.work
        performer = existing.performer
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
                AFSLabeledField(title: "Người thực hiện", icon: "person.fill") {
                    performerButton
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
                Image(app.workAsset(for: work))
                    .resizable().scaledToFit().frame(width: 22, height: 22)
                Text(work.isEmpty ? "Chọn công việc" : work)
                    .font(.system(size: 15, weight: .medium)).foregroundColor(AppTheme.textPrimary)
                Spacer()
                Image(systemName: "chevron.up.chevron.down").font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(hex: 0xF6FBF1)))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(AppTheme.line, lineWidth: 1))
        }
    }

    private var performerButton: some View {
        Button {
            performerSheet = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "person.fill").foregroundColor(AppTheme.primary)
                Text(performer.isEmpty ? "Chọn người thực hiện" : performer)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(performer.isEmpty ? AppTheme.textSecondary : AppTheme.textPrimary)
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
                log.performer = performer
                log.performDate = performDate
                log.note = note
                log.images = images
                area.crops[ci].logs[li] = log
            } else {
                let log = WorkLog(plantDate: plantDate, work: work, performer: performer,
                                  performDate: performDate, note: note, images: images)
                area.crops[ci].logs.append(log)
            }
        }
        dismiss()
    }
}

// MARK: - Listbox chọn công việc (thêm/xoá được)
struct WorkPickerView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss
    let selected: String
    let onSelect: (String) -> Void

    @State private var newName = ""
    @State private var newAsset = WorkCatalog.defaultAsset

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.screenGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        addCard

                        VStack(spacing: 10) {
                            ForEach(app.workItems) { type in
                                row(type)
                            }
                        }
                    }
                    .padding(18)
                }
                .scrollDismissesKeyboard(.interactively)
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

    private var addCard: some View {
        AFSCard {
            VStack(alignment: .leading, spacing: 12) {
                AFSSectionTitle(icon: "plus.circle.fill", title: "Thêm công việc mới",
                                subtitle: "Đặt tên và chọn biểu tượng canh tác.")
                AFSTextField(placeholder: "VD: Bón vôi, Cắt cỏ...", text: $newName)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 52), spacing: 10)], spacing: 10) {
                    ForEach(WorkCatalog.iconAssets, id: \.self) { asset in
                        Button {
                            newAsset = asset
                        } label: {
                            Image(asset)
                                .resizable().scaledToFit()
                                .frame(width: 30, height: 30)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(newAsset == asset ? AppTheme.primary.opacity(0.2) : AppTheme.accent.opacity(0.12)))
                                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(newAsset == asset ? AppTheme.primary : .clear, lineWidth: 1.5))
                        }
                    }
                }

                if let err = app.lastError, !err.isEmpty {
                    Text(err).font(.system(size: 12)).foregroundColor(AppTheme.danger)
                }

                Button {
                    if app.addWork(name: newName, asset: newAsset) {
                        newName = ""
                        newAsset = WorkCatalog.defaultAsset
                    }
                } label: {
                    Label("THÊM VÀO DANH SÁCH", systemImage: "plus")
                }
                .buttonStyle(AFSPrimaryButtonStyle())
                .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(newName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
            }
        }
    }

    private func row(_ type: WorkItem) -> some View {
        HStack(spacing: 12) {
            Button {
                onSelect(type.name)
                dismiss()
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(AppTheme.accent.opacity(0.18)).frame(width: 40, height: 40)
                        Image(type.asset).resizable().scaledToFit().frame(width: 26, height: 26)
                    }
                    Text(type.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    if type.name == selected {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(AppTheme.primary)
                    }
                }
            }
            if !type.builtin {
                Button {
                    app.deleteWork(id: type.id)
                } label: {
                    Image(systemName: "trash.fill").foregroundColor(AppTheme.danger)
                        .frame(width: 34, height: 34)
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(type.name == selected ? AppTheme.accent.opacity(0.16) : .white))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(type.name == selected ? AppTheme.primary : AppTheme.line, lineWidth: 1))
    }
}

// MARK: - Listbox chọn người thực hiện (thêm/xoá được)
struct PerformerPickerView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss
    let selected: String
    let onSelect: (String) -> Void

    @State private var newName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.screenGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        addCard
                        VStack(spacing: 10) {
                            if app.performers.isEmpty {
                                AFSCard {
                                    HStack(spacing: 10) {
                                        Image(systemName: "person.crop.circle.badge.questionmark")
                                            .foregroundColor(AppTheme.textSecondary)
                                        Text("Chưa có người thực hiện. Thêm ở trên.")
                                            .font(.system(size: 13)).foregroundColor(AppTheme.textSecondary)
                                    }
                                }
                            } else {
                                ForEach(app.performers, id: \.self) { person in
                                    row(person)
                                }
                            }
                        }
                    }
                    .padding(18)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Người thực hiện")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") { dismiss() }.foregroundColor(.white)
                }
            }
        }
    }

    private var addCard: some View {
        AFSCard {
            VStack(alignment: .leading, spacing: 12) {
                AFSSectionTitle(icon: "person.badge.plus", title: "Thêm người thực hiện",
                                subtitle: "Nhập tên rồi bấm thêm.")
                AFSTextField(placeholder: "VD: Nguyễn Văn A", text: $newName)
                if let err = app.lastError, !err.isEmpty {
                    Text(err).font(.system(size: 12)).foregroundColor(AppTheme.danger)
                }
                Button {
                    if app.addPerformer(newName) { newName = "" }
                } label: {
                    Label("THÊM VÀO DANH SÁCH", systemImage: "plus")
                }
                .buttonStyle(AFSPrimaryButtonStyle())
                .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(newName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
            }
        }
    }

    private func row(_ person: String) -> some View {
        HStack(spacing: 12) {
            Button {
                onSelect(person)
                dismiss()
            } label: {
                HStack(spacing: 12) {
                    AFSIconBadge(icon: "person.fill", color: person == selected ? AppTheme.primary : AppTheme.textSecondary)
                    Text(person).font(.system(size: 15, weight: .semibold)).foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    if person == selected {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(AppTheme.primary)
                    }
                }
            }
            Button {
                app.removePerformer(person)
            } label: {
                Image(systemName: "trash.fill").foregroundColor(AppTheme.danger)
                    .frame(width: 34, height: 34)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(person == selected ? AppTheme.accent.opacity(0.16) : .white))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(person == selected ? AppTheme.primary : AppTheme.line, lineWidth: 1))
    }
}
