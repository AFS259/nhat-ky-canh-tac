import SwiftUI

struct AreaDetailView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss
    let areaID: UUID

    @State private var showCropSetup = false
    @State private var showEditArea = false
    @State private var showDeleteSheet = false
    @State private var deletePassword = ""
    @State private var deleteError = false

    private var area: Area? { app.area(id: areaID) }

    var body: some View {
        ZStack {
            AppTheme.screenGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    if let area {
                        infoCard(area)

                        if area.crops.isEmpty {
                            emptyState
                        } else {
                            ForEach(area.crops.sorted { $0.createdAt > $1.createdAt }) { crop in
                                NavigationLink {
                                    CropDetailView(areaID: areaID, cropID: crop.id)
                                } label: {
                                    CropCard(crop: crop)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } else {
                        Text("Khu vực không tồn tại.").foregroundColor(AppTheme.textSecondary)
                    }
                }
                .padding(16)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle(area?.name ?? "Khu vực")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showCropSetup = true } label: {
                    Image(systemName: "plus.circle.fill").font(.system(size: 20)).foregroundColor(.white)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button { showEditArea = true } label: {
                        Label("Chỉnh sửa vườn", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        deletePassword = ""
                        deleteError = false
                        showDeleteSheet = true
                    } label: {
                        Label("Xoá vườn", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill").font(.system(size: 20)).foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $showCropSetup) {
            CropSetupView(areaID: areaID)
        }
        .sheet(isPresented: $showEditArea) {
            if let area { AddAreaView(editingArea: area) }
        }
        .sheet(isPresented: $showDeleteSheet) {
            deleteConfirmSheet
        }
    }

    private var deleteConfirmSheet: some View {
        NavigationStack {
            ZStack {
                AppTheme.screenGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        AFSIconBadge(icon: "trash.fill", color: AppTheme.danger)
                            .scaleEffect(1.3)
                            .padding(.top, 8)
                        Text("Xoá vườn")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        Text("Nhập mật khẩu để xác nhận xoá “\(area?.name ?? "")”. Toàn bộ vụ mùa và nhật ký trong vườn sẽ bị xoá vĩnh viễn.")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)

                        AFSCard {
                            AFSLabeledField(title: "Mật khẩu", icon: "lock.fill") {
                                SecureField("Nhập mật khẩu", text: $deletePassword)
                                    .font(.system(size: 15))
                                    .foregroundColor(AppTheme.textPrimary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(hex: 0xF6FBF1)))
                                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(deleteError ? AppTheme.danger : AppTheme.line, lineWidth: 1))
                            }
                        }

                        if deleteError {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text("Mật khẩu không đúng. Vui lòng thử lại.")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppTheme.danger)
                        }

                        Button { confirmDelete() } label: {
                            Text("XOÁ VƯỜN")
                        }
                        .buttonStyle(AFSPrimaryButtonStyle(color: AppTheme.danger))
                        .disabled(deletePassword.isEmpty)
                        .opacity(deletePassword.isEmpty ? 0.5 : 1)

                        Button("Hủy") { showDeleteSheet = false }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppTheme.primary)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Xác nhận xoá")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func confirmDelete() {
        guard deletePassword == "2026" else {
            deleteError = true
            return
        }
        if let area { app.deleteArea(area) }
        showDeleteSheet = false
        dismiss()
    }

    private func infoCard(_ area: Area) -> some View {
        AFSCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    AFSIconBadge(icon: "mappin.and.ellipse")
                    VStack(alignment: .leading, spacing: 2) {
                        Text(area.name).font(.system(size: 17, weight: .bold)).foregroundColor(AppTheme.textPrimary)
                        if !area.address.isEmpty {
                            Text(area.address).font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    Spacer()
                }
                if !area.note.isEmpty {
                    Text(area.note)
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textSecondary)
                }
                Divider().overlay(AppTheme.line)
                HStack(spacing: 18) {
                    stat("\(area.crops.count)", "Vụ canh tác")
                    stat("\(area.crops.reduce(0) { $0 + $1.logs.count })", "Nhật ký")
                    stat(Fmt.day.string(from: area.createdAt), "Ngày tạo")
                }
            }
        }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.system(size: 16, weight: .bold)).foregroundColor(AppTheme.primary)
            Text(label).font(.system(size: 11)).foregroundColor(AppTheme.textSecondary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 40)
            ZStack {
                Circle().fill(AppTheme.primary.opacity(0.10)).frame(width: 110, height: 110)
                Image(systemName: "camera.macro")
                    .font(.system(size: 44))
                    .foregroundColor(AppTheme.primary)
            }
            Text("Khu vực chưa có cây trồng")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
            Text("Nhấn dấu + để thêm vụ cây trồng: chọn loại cây, giống, diện tích, ngày gieo và ngày trồng.")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            Button {
                showCropSetup = true
            } label: {
                Label("Thêm cây trồng", systemImage: "plus")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 13)
                    .background(Capsule().fill(AppTheme.primary))
                    .shadow(color: AppTheme.primary.opacity(0.3), radius: 8, y: 4)
            }
            Spacer(minLength: 50)
        }
        .frame(maxWidth: .infinity)
    }
}

struct CropCard: View {
    let crop: Crop

    var body: some View {
        AFSCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(AppTheme.accent.opacity(0.18))
                            .frame(width: 46, height: 46)
                        Image(CropCatalog.asset(for: crop.cropType))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(crop.cropType)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        Text("Giống: \(crop.variety)")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary.opacity(0.6))
                }

                Divider().overlay(AppTheme.line)

                HStack(spacing: 0) {
                    miniStat(icon: "arrow.up.left.and.arrow.down.right", value: "\(Fmt.number(crop.areaM2)) m²", label: "Diện tích")
                    miniStat(icon: "leaf.arrow.circlepath", value: "\(crop.seedCount)", label: "Hạt gieo")
                    miniStat(icon: "tree.fill", value: "\(crop.plantCount)", label: "Cây trồng")
                    miniStat(icon: "square.stack.3d.up.fill", value: "\(crop.logs.count)", label: "Nhật ký")
                }
            }
        }
    }

    private func miniStat(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 13)).foregroundColor(AppTheme.primary)
            Text(value).font(.system(size: 13, weight: .bold)).foregroundColor(AppTheme.textPrimary)
            Text(label).font(.system(size: 10)).foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
