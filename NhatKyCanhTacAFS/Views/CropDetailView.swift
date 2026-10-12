import SwiftUI

private enum CropSheet: Identifiable {
    case add
    case edit(WorkLog)
    case export
    case gallery([String])

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let log): return "edit-\(log.id)"
        case .export: return "export"
        case .gallery(let names): return "gallery-\(names.first ?? "")-\(names.count)"
        }
    }
}

struct CropDetailView: View {
    @EnvironmentObject private var app: AppState
    let areaID: UUID
    let cropID: UUID

    @State private var sheet: CropSheet?

    private var crop: Crop? {
        app.area(id: areaID)?.crops.first { $0.id == cropID }
    }

    var body: some View {
        ZStack {
            AppTheme.screenGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    if let crop {
                        cropHeader(crop)
                        section2(crop)
                        section3
                        exportButton
                    } else {
                        Text("Vụ canh tác không tồn tại.").foregroundColor(AppTheme.textSecondary)
                    }
                }
                .padding(16)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(crop?.cropType ?? "Vụ canh tác")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $sheet) { item in
            switch item {
            case .add:
                LogEntryView(areaID: areaID, cropID: cropID, existing: nil)
            case .edit(let log):
                LogEntryView(areaID: areaID, cropID: cropID, existing: log)
            case .export:
                QRExportView(areaName: app.area(id: areaID)?.name ?? "", crop: crop ?? emptyCrop)
            case .gallery(let names):
                ImageGalleryView(names: names)
            }
        }
    }

    private var emptyCrop: Crop {
        Crop(cropType: "", variety: "", areaM2: 0, seedCount: 0,
             sowDate: Date(), plantCount: 0, plantDate: Date())
    }

    // MARK: - Header
    private func cropHeader(_ crop: Crop) -> some View {
        AFSCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppTheme.accent.opacity(0.2))
                            .frame(width: 54, height: 54)
                        Image(CropCatalog.asset(for: crop.cropType))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(crop.cropType).font(.system(size: 18, weight: .bold)).foregroundColor(AppTheme.textPrimary)
                        Text("Giống: \(crop.variety)").font(.system(size: 13)).foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                }
                Divider().overlay(AppTheme.line)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    infoTile(icon: "arrow.up.left.and.arrow.down.right", title: "Diện tích", value: "\(Fmt.number(crop.areaM2)) m²")
                    infoTile(icon: "square.stack.3d.up.fill", title: "Số hạt gieo", value: "\(crop.seedCount) hạt · \(Fmt.day.string(from: crop.sowDate))")
                    infoTile(icon: "tree.fill", title: "Số cây trồng", value: "\(crop.plantCount) cây · \(Fmt.day.string(from: crop.plantDate))")
                    infoTile(icon: "list.bullet.rectangle", title: "Số nhật ký", value: "\(crop.logs.count) mục")
                }
            }
        }
    }

    private func infoTile(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 15)).foregroundColor(AppTheme.primary)
                .frame(width: 30, height: 30)
                .background(Circle().fill(AppTheme.primary.opacity(0.12)))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 11)).foregroundColor(AppTheme.textSecondary)
                Text(value).font(.system(size: 12, weight: .semibold)).foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1).minimumScaleFactor(0.8)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Mục 2: Bảng nhật ký
    private func section2(_ crop: Crop) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            AFSSectionTitle(icon: "tablecells", title: "Mục 2 · Bảng nhật ký",
                            subtitle: "Ngày trồng · Công việc · Ngày thực hiện · Ghi chú · Hình ảnh")

            if crop.logs.isEmpty {
                AFSCard {
                    HStack(spacing: 12) {
                        Image(systemName: "tray").foregroundColor(AppTheme.textSecondary)
                        Text("Chưa có nhật ký. Dùng Mục 3 bên dưới để thêm.")
                            .font(.system(size: 13)).foregroundColor(AppTheme.textSecondary)
                    }
                }
            } else {
                LogTable(logs: crop.logs.sorted { $0.performDate > $1.performDate },
                         onEdit: { log in sheet = .edit(log) },
                         onViewImages: { sheet = .gallery($0) })
            }
        }
    }

    private var section3: some View {
        VStack(alignment: .leading, spacing: 12) {
            AFSSectionTitle(icon: "square.and.pencil", title: "Mục 3 · Nhập nhật ký",
                            subtitle: "Chọn ngày trồng, công việc, ghi chú và chụp hình")
            Button {
                sheet = .add
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill").font(.system(size: 18))
                    Text("Thêm nhật ký công việc").font(.system(size: 15, weight: .semibold))
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(AppTheme.primary))
                .shadow(color: AppTheme.primary.opacity(0.28), radius: 8, y: 4)
            }
        }
    }

    private var exportButton: some View {
        Button {
            sheet = .export
        } label: {
            HStack {
                Image(systemName: "qrcode")
                Text("Kết thúc vụ · Xuất mã QR")
                Spacer()
                Text("Tạo mã QR").font(.system(size: 11)).opacity(0.85)
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(AppTheme.primaryDark)
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(AppTheme.accent.opacity(0.22)))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AppTheme.accent, lineWidth: 1))
        }
        .padding(.top, 4)
    }
}

// MARK: - Bảng nhật ký (Mục 2)
struct LogTable: View {
    let logs: [WorkLog]
    let onEdit: (WorkLog) -> Void
    let onViewImages: ([String]) -> Void

    private let colPlant: CGFloat = 96
    private let colWork: CGFloat = 150
    private let colPerform: CGFloat = 110
    private let colNote: CGFloat = 200
    private let colImage: CGFloat = 118

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            VStack(spacing: 0) {
                headerRow
                ForEach(Array(logs.enumerated()), id: \.offset) { index, log in
                    row(log, zebra: index % 2 == 1)
                }
            }
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AppTheme.line, lineWidth: 1))
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.white))
        .shadow(color: AppTheme.cardShadow, radius: 10, y: 4)
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            headCell("Ngày trồng", width: colPlant)
            headCell("Công việc", width: colWork)
            headCell("Ngày thực hiện", width: colPerform)
            headCell("Ghi chú", width: colNote)
            headCell("Hình ảnh", width: colImage)
        }
        .background(AppTheme.primary)
    }

    private func headCell(_ text: String, width: CGFloat) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.white)
            .frame(width: width, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
    }

    private func row(_ log: WorkLog, zebra: Bool) -> some View {
        HStack(alignment: .top, spacing: 0) {
            bodyCell(Fmt.day.string(from: log.plantDate), width: colPlant)

            HStack(spacing: 6) {
                Image(systemName: log.work.icon).font(.system(size: 12)).foregroundColor(AppTheme.primary)
                Text(log.work.rawValue).font(.system(size: 12, weight: .semibold)).foregroundColor(AppTheme.textPrimary)
                    .lineLimit(2)
            }
            .frame(width: colWork, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 12)

            bodyCell(Fmt.day.string(from: log.performDate), width: colPerform)

            Text(log.note.isEmpty ? "—" : log.note)
                .font(.system(size: 12))
                .foregroundColor(log.note.isEmpty ? AppTheme.textSecondary : AppTheme.textPrimary)
                .lineLimit(3)
                .frame(width: colNote, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 12)

            imagesCell(log)

            if !log.isEditable {
                Image(systemName: "lock.fill")
                    .font(.system(size: 9))
                    .foregroundColor(AppTheme.warning)
                    .padding(.top, 14)
                    .padding(.trailing, 6)
            } else {
                Image(systemName: "pencil")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.primary)
                    .padding(.top, 14)
                    .padding(.trailing, 6)
            }
        }
        .background(zebra ? Color(hex: 0xF6FBF1) : .white)
        .contentShape(Rectangle())
        .onTapGesture {
            if log.isEditable { onEdit(log) }
        }
        .overlay(alignment: .bottom) { Divider().overlay(AppTheme.line) }
    }

    private func bodyCell(_ text: String, width: CGFloat) -> some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundColor(AppTheme.textPrimary)
            .frame(width: width, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
    }

    private func imagesCell(_ log: WorkLog) -> some View {
        HStack(spacing: 5) {
            if log.images.isEmpty {
                Image(systemName: "camera").foregroundColor(AppTheme.textSecondary.opacity(0.5))
            } else {
                ForEach(log.images.prefix(2), id: \.self) { name in
                    ThumbnailView(name: name)
                }
                if log.images.count > 2 {
                    Text("+\(log.images.count - 2)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.primary)
                }
            }
        }
        .frame(width: colImage, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            if !log.images.isEmpty { onViewImages(log.images) }
        }
    }
}

struct ThumbnailView: View {
    let name: String
    var size: CGFloat = 34

    var body: some View {
        if let img = ImageStore.load(name) {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(AppTheme.line)
                .frame(width: size, height: size)
                .overlay(Image(systemName: "photo").font(.system(size: 12)).foregroundColor(AppTheme.textSecondary))
        }
    }
}

// MARK: - Xem ảnh
struct ImageGalleryView: View {
    @Environment(\.dismiss) private var dismiss
    let names: [String]
    var startIndex: Int = 0
    @State private var index = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                if !names.isEmpty {
                    TabView(selection: $index) {
                        ForEach(Array(names.enumerated()), id: \.offset) { i, name in
                            Group {
                                if let img = ImageStore.load(name) {
                                    Image(uiImage: img).resizable().scaledToFit()
                                } else {
                                    Text("Không tải được ảnh").foregroundColor(.white)
                                }
                            }
                            .tag(i)
                        }
                    }
                    .tabViewStyle(.page)
                }
            }
            .navigationTitle("Hình ảnh \(names.isEmpty ? 0 : index + 1)/\(names.count)")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { index = min(max(startIndex, 0), max(names.count - 1, 0)) }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") { dismiss() }.foregroundColor(.white)
                }
            }
        }
    }
}
