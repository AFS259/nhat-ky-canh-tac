import SwiftUI

struct QRResultView: View {
    @Environment(\.dismiss) private var dismiss
    let payload: QRPayload

    private let colPlant: CGFloat = 96
    private let colWork: CGFloat = 150
    private let colPerform: CGFloat = 110
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

    private var headerRow: some View {
        HStack(spacing: 0) {
            headCell("Ngày trồng", colPlant)
            headCell("Công việc", colWork)
            headCell("Ngày thực hiện", colPerform)
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
            cell(r.note.isEmpty ? "—" : r.note, colNote)
            HStack(spacing: 6) {
                Image(systemName: "photo.badge.exclamationmark").font(.system(size: 12))
                Text("Không kèm").font(.system(size: 10))
            }
            .foregroundColor(AppTheme.textSecondary)
            .frame(width: colImage, alignment: .leading)
            .padding(.horizontal, 10).padding(.vertical, 12)
        }
        .background(zebra ? Color(hex: 0xF6FBF1) : .white)
        .overlay(alignment: .bottom) { Divider().overlay(AppTheme.line) }
    }

    private func cell(_ text: String, _ width: CGFloat, semibold: Bool = false) -> some View {
        Text(text)
            .font(.system(size: 12, weight: semibold ? .semibold : .regular))
            .foregroundColor(AppTheme.textPrimary)
            .frame(width: width, alignment: .leading)
            .padding(.horizontal, 10).padding(.vertical, 12)
    }
}
