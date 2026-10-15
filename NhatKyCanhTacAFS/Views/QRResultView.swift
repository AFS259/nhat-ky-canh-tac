import SwiftUI

struct QRResultView: View {
    @Environment(\.dismiss) private var dismiss
    let payload: QRPayload

    @State private var exportURL: URL?
    @State private var exportError: String?
    @State private var showShare = false

    private let colPlant: CGFloat = 96
    private let colWork: CGFloat = 150
    private let colPerform: CGFloat = 110
    private let colPerson: CGFloat = 130
    private let colNote: CGFloat = 200
    private let colImage: CGFloat = 110

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.screenGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        header
                        validBanner
                        table
                        exportButton
                    }
                    .padding(16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Kết quả quét QR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") { dismiss() }.foregroundColor(.white)
                }
            }
            .onAppear {
                // Chuẩn bị file export nhưng không tự mở share sheet
                prepareExportForCache()
            }
        }
    }

    private var header: some View {
        AFSCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    AFSIconBadge(icon: "checkmark.seal.fill")
                    VStack(alignment: .leading, spacing: 3) {
                        Text(payload.areaName).font(.system(size: 16, weight: .bold)).foregroundColor(AppTheme.textPrimary)
                        Text(payload.crop).font(.system(size: 13)).foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                }
                Divider().overlay(AppTheme.line)
                HStack(spacing: 18) {
                    stat("Ngày xuất", Fmt.day.string(from: payload.issuedAt))
                    stat("Hết hạn", Fmt.day.string(from: payload.expiresAt))
                    stat("Số dòng", "\(payload.rows.count)")
                }
            }
        }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 11)).foregroundColor(AppTheme.textSecondary)
            Text(value).font(.system(size: 13, weight: .bold)).foregroundColor(AppTheme.primary)
        }
    }

    private var validBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.shield.fill").foregroundColor(AppTheme.primaryLight)
            Text("Mã hợp lệ · Giải mã AES-256 thành công")
                .font(.system(size: 13, weight: .semibold)).foregroundColor(AppTheme.textPrimary)
            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(AppTheme.primary.opacity(0.12)))
    }

    private var table: some View {
        VStack(alignment: .leading, spacing: 10) {
            AFSSectionTitle(icon: "tablecells", title: "Mục 2 · Bảng nhật ký",
                            subtitle: "Hiển thị toàn bộ dữ liệu đã mã hóa trong QR")

            ScrollView(.horizontal, showsIndicators: true) {
                VStack(spacing: 0) {
                    headerRow
                    ForEach(Array(payload.rows.enumerated()), id: \.offset) { index, r in
                        row(r, zebra: index % 2 == 1)
                    }
                }
                .background(Color.white)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AppTheme.line, lineWidth: 1))
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.white))
            .shadow(color: AppTheme.cardShadow, radius: 10, y: 4)
        }
    }

    private var exportButton: some View {
        VStack(spacing: 10) {
            if let exportError {
                Text(exportError)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.danger)
                    .multilineTextAlignment(.center)
            }
            Button {
                prepareExport()
            } label: {
                Label("XUẤT DỮ LIỆU", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(AFSPrimaryButtonStyle())
        }
        .sheet(isPresented: $showShare, onDismiss: { showShare = false }) {
            if let exportURL {
                ShareSheet(items: [exportURL])
            }
        }
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            headCell("Ngày trồng", colPlant)
            headCell("Công việc", colWork)
            headCell("Ngày thực hiện", colPerform)
            headCell("Người thực hiện", colPerson)
            headCell("Ghi chú", colNote)
            headCell("Hình ảnh", colImage)
        }
        .background(AppTheme.primary)
    }

    private func headCell(_ text: String, _ width: CGFloat) -> some View {
        Text(text).font(.system(size: 12, weight: .bold)).foregroundColor(.white)
            .frame(width: width, alignment: .leading)
            .padding(.horizontal, 10).padding(.vertical, 12)
    }

    private func row(_ r: QRRow, zebra: Bool) -> some View {
        HStack(alignment: .top, spacing: 0) {
            cell(r.plantDate, colPlant)
            cell(r.work, colWork, semibold: true)
            cell(r.performDate, colPerform)
            cell(r.performer.isEmpty ? "—" : r.performer, colPerson)
            cell(r.note.isEmpty ? "—" : r.note, colNote)
            imageCell(r)
        }
        .background(zebra ? Color(hex: 0xF6FBF1) : .white)
        .overlay(alignment: .bottom) { Divider().overlay(AppTheme.line) }
    }

    @ViewBuilder
    private func imageCell(_ r: QRRow) -> some View {
        let thumbs = r.imageNames.compactMap { ImageStore.load($0) }
        if thumbs.isEmpty {
            cell("—", colImage)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(thumbs.enumerated()), id: \.offset) { _, img in
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                }
                .padding(.horizontal, 10).padding(.vertical, 12)
            }
            .frame(width: colImage, alignment: .leading)
        }
    }

    private func cell(_ text: String, _ width: CGFloat, semibold: Bool = false) -> some View {
        Text(text)
            .font(.system(size: 12, weight: semibold ? .semibold : .regular))
            .foregroundColor(AppTheme.textPrimary)
            .frame(width: width, alignment: .leading)
            .padding(.horizontal, 10).padding(.vertical, 12)
    }

    private var fileName: String {
        let base = "\(payload.areaName)_\(payload.crop)"
            .replacingOccurrences(of: " ", with: "_")
            .filter { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }
        return "NhatKyCanhTac_\(base.isEmpty ? "vu" : base).csv"
    }

    private func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }

    private func prepareExportForCache() {
        var lines: [String] = []
        lines.append("NHẬT KÝ CANH TÁC")
        lines.append("Khu vực,\(csvEscape(payload.areaName))")
        lines.append("Vụ,\(csvEscape(payload.crop))")
        lines.append("Ngày xuất,\(Fmt.dayTime.string(from: payload.issuedAt))")
        lines.append("Hết hạn,\(Fmt.day.string(from: payload.expiresAt))")
        lines.append("")
        lines.append("Ngày trồng,Công việc,Ngày thực hiện,Người thực hiện,Ghi chú,Hình ảnh")
        for r in payload.rows {
            lines.append([r.plantDate, r.work, r.performDate, r.performer, r.note,
                          r.imageNames.isEmpty ? "" : "\(r.imageNames.count) ảnh"]
                .map(csvEscape)
                .joined(separator: ","))
        }
        let csv = "\u{FEFF}" + lines.joined(separator: "\r\n")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            try csv.write(to: url, atomically: true, encoding: .utf8)
            exportError = nil
            exportURL = url
        } catch {
            exportError = "Không tạo được file dữ liệu: \(error.localizedDescription)"
        }
    }

    private func prepareExport() {
        prepareExportForCache()
        showShare = true
    }
}
