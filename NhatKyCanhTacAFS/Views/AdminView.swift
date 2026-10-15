import SwiftUI

// MARK: - Trang quản trị (tài khoản AFS / 2026)
struct AdminView: View {
    @EnvironmentObject private var app: AppState

    private var allAreas: [[Area]] { app.allUsers.map { app.areas(for: $0.username) } }
    private var totalAreas: Int { allAreas.reduce(0) { $0 + $1.count } }
    private var totalCrops: Int { allAreas.reduce(0) { acc, list in acc + list.reduce(0) { $0 + $1.crops.count } } }
    private var totalLogs: Int {
        allAreas.reduce(0) { acc, list in
            acc + list.reduce(0) { $0 + $1.crops.reduce(0) { $0 + $1.logs.count } }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.screenGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        hero
                        statsCard

                        HStack {
                            AFSSectionTitle(icon: "person.2.fill", title: "Tài khoản",
                                            subtitle: "\(app.allUsers.count) tài khoản trên thiết bị")
                            Spacer()
                        }

                        ForEach(app.allUsers, id: \.username) { user in
                            NavigationLink {
                                AdminUserView(user: user)
                            } label: {
                                AdminUserCard(user: user)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Quản trị")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Quản trị hệ thống")
                        .font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                }
            }
        }
    }

    private var hero: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(.white.opacity(0.2)).frame(width: 52, height: 52)
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 22)).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Quản trị viên").font(.system(size: 13)).foregroundColor(.white.opacity(0.9))
                Text(app.currentUser?.fullName ?? "AFS")
                    .font(.system(size: 18, weight: .bold)).foregroundColor(.white)
            }
            Spacer()
            Image("Logo")
                .resizable().scaledToFit().frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.radius, style: .continuous)
                .fill(AppTheme.heroGradient)
                .shadow(color: AppTheme.primary.opacity(0.3), radius: 12, y: 6)
        )
    }

    private var statsCard: some View {
        AFSCard {
            HStack(spacing: 0) {
                stat("\(app.allUsers.count)", "Tài khoản")
                divider
                stat("\(totalAreas)", "Khu vực")
                divider
                stat("\(totalCrops)", "Vụ")
                divider
                stat("\(totalLogs)", "Nhật ký")
            }
        }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 20, weight: .heavy)).foregroundColor(AppTheme.primary)
            Text(label).font(.system(size: 11)).foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle().fill(AppTheme.line).frame(width: 1, height: 34)
    }
}

struct AdminUserCard: View {
    @EnvironmentObject private var app: AppState
    let user: AppUser

    private var areas: [Area] { app.areas(for: user.username) }
    private var cropCount: Int { areas.reduce(0) { $0 + $1.crops.count } }
    private var logCount: Int { areas.reduce(0) { acc, a in acc + a.crops.reduce(0) { $0 + $1.logs.count } } }

    var body: some View {
        AFSCard(padding: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(AppTheme.heroGradient).frame(width: 46, height: 46)
                    Image(systemName: user.isAdmin ? "shield.lefthalf.filled" : "person.fill")
                        .font(.system(size: 19)).foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(user.fullName).font(.system(size: 16, weight: .bold)).foregroundColor(AppTheme.textPrimary)
                        if user.isAdmin {
                            Text("ADMIN")
                                .font(.system(size: 9, weight: .heavy)).foregroundColor(.white)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Capsule().fill(AppTheme.gold))
                        }
                    }
                    Text("@\(user.username)").font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
                    HStack(spacing: 10) {
                        Label("\(areas.count) khu vực", systemImage: "mappin.and.ellipse")
                        Label("\(cropCount) vụ", systemImage: "sprout")
                        Label("\(logCount) nhật ký", systemImage: "list.bullet.rectangle")
                    }
                    .font(.system(size: 11, weight: .medium)).foregroundColor(AppTheme.primary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.textSecondary.opacity(0.6))
            }
        }
    }
}

struct AdminUserView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss
    let user: AppUser

    @State private var showDelete = false
    @State private var didDelete = false

    private var areas: [Area] { app.areas(for: user.username).sorted { $0.createdAt > $1.createdAt } }
    private var cropCount: Int { areas.reduce(0) { $0 + $1.crops.count } }
    private var logCount: Int { areas.reduce(0) { acc, a in acc + a.crops.reduce(0) { $0 + $1.logs.count } } }

    var body: some View {
        ZStack {
            AppTheme.screenGradient.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    AFSCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                AFSIconBadge(icon: user.isAdmin ? "shield.lefthalf.filled" : "person.fill")
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(user.fullName).font(.system(size: 17, weight: .bold)).foregroundColor(AppTheme.textPrimary)
                                    Text("@\(user.username)").font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
                                }
                                Spacer()
                            }
                            Divider().overlay(AppTheme.line)
                            HStack(spacing: 18) {
                                stat("\(areas.count)", "Khu vực")
                                stat("\(cropCount)", "Vụ canh tác")
                                stat("\(logCount)", "Nhật ký")
                            }
                        }
                    }

                    if areas.isEmpty {
                        AFSCard {
                            HStack(spacing: 12) {
                                Image(systemName: "tray").foregroundColor(AppTheme.textSecondary)
                                Text("Tài khoản này chưa có khu vực canh tác.")
                                    .font(.system(size: 13)).foregroundColor(AppTheme.textSecondary)
                            }
                        }
                    } else {
                        ForEach(areas) { area in
                            NavigationLink {
                                AdminAreaView(area: area, ownerName: user.fullName)
                            } label: {
                                AdminAreaCard(area: area)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if !user.isAdmin {
                        deleteButton
                    }
                }
                .padding(16)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle(user.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showDelete, onDismiss: {
            if didDelete { dismiss() }
        }) {
            AdminDeleteUserSheet(user: user) { didDelete = true }
                .environmentObject(app)
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            showDelete = true
        } label: {
            HStack {
                Image(systemName: "trash.fill")
                Text("XOÁ TÀI KHOẢN").font(.system(size: 15, weight: .bold))
            }
        }
        .buttonStyle(AFSPrimaryButtonStyle(color: AppTheme.danger))
        .padding(.top, 4)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.system(size: 16, weight: .bold)).foregroundColor(AppTheme.primary)
            Text(label).font(.system(size: 11)).foregroundColor(AppTheme.textSecondary)
        }
    }
}

struct AdminAreaCard: View {
    let area: Area

    var body: some View {
        AFSCard(padding: 16) {
            HStack(spacing: 14) {
                AFSIconBadge(icon: "leaf.fill")
                VStack(alignment: .leading, spacing: 5) {
                    Text(area.name).font(.system(size: 16, weight: .bold)).foregroundColor(AppTheme.textPrimary)
                    if !area.address.isEmpty {
                        Text(area.address).font(.system(size: 12)).foregroundColor(AppTheme.textSecondary).lineLimit(1)
                    }
                    HStack(spacing: 10) {
                        Label("\(area.crops.count) vụ", systemImage: "sprout")
                        Label(Fmt.day.string(from: area.createdAt), systemImage: "calendar")
                    }
                    .font(.system(size: 11, weight: .medium)).foregroundColor(AppTheme.primary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.textSecondary.opacity(0.6))
            }
        }
    }
}

struct AdminAreaView: View {
    let area: Area
    let ownerName: String

    private var logCount: Int { area.crops.reduce(0) { $0 + $1.logs.count } }

    var body: some View {
        ZStack {
            AppTheme.screenGradient.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    AFSCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                AFSIconBadge(icon: "mappin.and.ellipse")
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(area.name).font(.system(size: 17, weight: .bold)).foregroundColor(AppTheme.textPrimary)
                                    Text("Chủ sở hữu: \(ownerName)").font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
                                }
                                Spacer()
                            }
                            Divider().overlay(AppTheme.line)
                            HStack(spacing: 18) {
                                stat("\(area.crops.count)", "Vụ canh tác")
                                stat("\(logCount)", "Nhật ký")
                                stat(Fmt.day.string(from: area.createdAt), "Ngày tạo")
                            }
                        }
                    }

                    if area.crops.isEmpty {
                        AFSCard {
                            HStack(spacing: 12) {
                                Image(systemName: "tray").foregroundColor(AppTheme.textSecondary)
                                Text("Khu vực chưa có vụ canh tác.")
                                    .font(.system(size: 13)).foregroundColor(AppTheme.textSecondary)
                            }
                        }
                    } else {
                        ForEach(area.crops.sorted { $0.createdAt > $1.createdAt }) { crop in
                            NavigationLink {
                                AdminCropView(crop: crop, areaName: area.name)
                            } label: {
                                AdminCropCard(crop: crop)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle(area.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.system(size: 16, weight: .bold)).foregroundColor(AppTheme.primary)
            Text(label).font(.system(size: 11)).foregroundColor(AppTheme.textSecondary)
        }
    }
}

struct AdminCropCard: View {
    let crop: Crop

    var body: some View {
        AFSCard(padding: 16) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppTheme.accent.opacity(0.18))
                        .frame(width: 46, height: 46)
                    Image(CropCatalog.asset(for: crop.cropType))
                        .resizable().scaledToFit().frame(width: 30, height: 30)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(crop.cropType).font(.system(size: 16, weight: .bold)).foregroundColor(AppTheme.textPrimary)
                    Text("Giống: \(crop.variety)").font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
                    Text("\(crop.logs.count) nhật ký · \(Fmt.number(crop.areaM2)) m²")
                        .font(.system(size: 11, weight: .medium)).foregroundColor(AppTheme.primary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.textSecondary.opacity(0.6))
            }
        }
    }
}

struct AdminCropView: View {
    let crop: Crop
    let areaName: String
    @State private var gallery: [String]?

    var body: some View {
        ZStack {
            AppTheme.screenGradient.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    AFSCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(AppTheme.accent.opacity(0.2)).frame(width: 50, height: 50)
                                    Image(CropCatalog.asset(for: crop.cropType))
                                        .resizable().scaledToFit().frame(width: 34, height: 34)
                                }
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(crop.cropType).font(.system(size: 17, weight: .bold)).foregroundColor(AppTheme.textPrimary)
                                    Text("Giống: \(crop.variety)").font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
                                    Text(areaName).font(.system(size: 11)).foregroundColor(AppTheme.primary)
                                }
                                Spacer()
                            }
                            Divider().overlay(AppTheme.line)
                            HStack(spacing: 18) {
                                stat("\(Fmt.number(crop.areaM2)) m²", "Diện tích")
                                stat("\(crop.plantCount) cây", "Số cây")
                                stat("\(crop.logs.count)", "Nhật ký")
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        AFSSectionTitle(icon: "tablecells", title: "Mục 2 · Bảng nhật ký",
                                        subtitle: "Chế độ chỉ xem (quản trị)")
                        if crop.logs.isEmpty {
                            AFSCard {
                                HStack(spacing: 12) {
                                    Image(systemName: "tray").foregroundColor(AppTheme.textSecondary)
                                    Text("Vụ canh tác chưa có nhật ký.")
                                        .font(.system(size: 13)).foregroundColor(AppTheme.textSecondary)
                                }
                            }
                        } else {
                            LogTable(logs: crop.logs.sorted { $0.performDate > $1.performDate },
                                     onEdit: { _ in },
                                     onViewImages: { gallery = $0 })
                        }
                    }
                }
                .padding(16)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle(crop.cropType)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: Binding(get: { gallery.map { GalleryBox(names: $0) } },
                             set: { gallery = $0?.names })) { box in
            ImageGalleryView(names: box.names)
        }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.system(size: 16, weight: .bold)).foregroundColor(AppTheme.primary)
            Text(label).font(.system(size: 11)).foregroundColor(AppTheme.textSecondary)
        }
    }
}

private struct GalleryBox: Identifiable {
    let names: [String]
    var id: String { "\(names.count)-\(names.first ?? "")" }
}

// MARK: - Xác nhận xoá tài khoản (yêu cầu mật khẩu quản trị)
struct AdminDeleteUserSheet: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss
    let user: AppUser
    let onDeleted: () -> Void

    @State private var password = ""
    @State private var error: String?
    @FocusState private var focused: Bool

    private var areaCount: Int { app.areas(for: user.username).count }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.screenGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        warningCard
                        passwordField
                        if let error {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text(error).font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(AppTheme.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Button {
                            confirm()
                        } label: {
                            Text("XOÁ TÀI KHOẢN")
                        }
                        .buttonStyle(AFSPrimaryButtonStyle(color: AppTheme.danger))

                        Button("Huỷ") { dismiss() }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(16)
                    .padding(.bottom, 24)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Xác nhận xoá")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { focused = true }
        }
    }

    private var warningCard: some View {
        AFSCard(padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    AFSIconBadge(icon: "trash.fill", color: AppTheme.danger)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.fullName).font(.system(size: 16, weight: .bold)).foregroundColor(AppTheme.textPrimary)
                        Text("@\(user.username)").font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                }
                Divider().overlay(AppTheme.line)
                Text("Tài khoản này cùng \(areaCount) khu vực và toàn bộ nhật ký sẽ bị xoá vĩnh viễn trên thiết bị. Không thể hoàn tác.")
                    .font(.system(size: 13)).foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var passwordField: some View {
        AFSCard(padding: 18) {
            AFSLabeledField(title: "Nhập mật khẩu quản trị để tiếp tục", icon: "lock.fill") {
                SecureField("Mật khẩu", text: $password)
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 13)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(hex: 0xF6FBF1)))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(AppTheme.line, lineWidth: 1))
                    .focused($focused)
            }
        }
    }

    private func confirm() {
        guard app.verifyAdminPassword(password) else {
            error = "Mật khẩu quản trị không đúng."
            return
        }
        if app.deleteUser(user) {
            dismiss()
            onDeleted()
        } else {
            error = app.lastError ?? "Không xoá được tài khoản."
        }
    }
}
