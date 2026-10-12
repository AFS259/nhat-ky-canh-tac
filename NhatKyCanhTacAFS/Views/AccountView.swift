import SwiftUI
import PhotosUI

struct AccountView: View {
    @EnvironmentObject private var app: AppState
    @State private var showLogoutConfirm = false
    @State private var showEdit = false
    @State private var pickerItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.screenGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        profileCard
                        statsCard
                        if app.isAdmin { adminCard }
                        aboutCard
                        logoutButton
                    }
                    .padding(16)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Tài khoản")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Tài khoản").font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                }
            }
            .confirmationDialog("Đăng xuất khỏi AFS?", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
                Button("Đăng xuất", role: .destructive) { app.logout() }
                Button("Hủy", role: .cancel) {}
            }
            .sheet(isPresented: $showEdit) {
                EditProfileView()
            }
            .onChange(of: pickerItem) { item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        handleAvatar(data)
                    }
                    pickerItem = nil
                }
            }
        }
    }

    private func handleAvatar(_ data: Data) {
        guard let image = UIImage(data: data) else { return }
        let side: CGFloat = 512
        let maxSide = max(image.size.width, image.size.height)
        let scale = maxSide > side ? side / maxSide : 1
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        if let jpeg = resized.jpegData(compressionQuality: 0.85) {
            _ = app.setAvatar(imageData: jpeg)
        }
    }

    private var profileCard: some View {
        AFSCard(padding: 20) {
            HStack(spacing: 16) {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    avatarView
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    Text(app.currentUser?.fullName ?? "Kỹ thuật viên")
                        .font(.system(size: 18, weight: .bold)).foregroundColor(AppTheme.textPrimary)
                    Text("@\(app.currentUser?.username ?? "")")
                        .font(.system(size: 13)).foregroundColor(AppTheme.textSecondary)
                    Text("AUTO FUNSION SYSTEM")
                        .font(.system(size: 11, weight: .semibold)).foregroundColor(AppTheme.accent)
                        .padding(.top, 2)
                }
                Spacer()
                Button {
                    showEdit = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.primary)
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(AppTheme.primary.opacity(0.12)))
                }
            }
        }
    }

    private var avatarView: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let image = app.avatarImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Circle().fill(AppTheme.heroGradient)
                    Image(systemName: "person.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 68, height: 68)
            .clipShape(Circle())

            Image(systemName: "camera.fill")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(AppTheme.primary))
                .overlay(Circle().stroke(.white, lineWidth: 2))
        }
    }

    private var statsCard: some View {
        AFSCard {
            HStack(spacing: 0) {
                stat("\(app.areas.count)", "Khu vực")
                divider
                stat("\(app.areas.reduce(0) { $0 + $1.crops.count })", "Vụ canh tác")
                divider
                stat("\(app.areas.reduce(0) { $0 + $1.crops.reduce(0) { $0 + $1.logs.count } })", "Nhật ký")
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

    private var adminCard: some View {
        NavigationLink {
            AdminView()
        } label: {
            AFSCard {
                HStack(spacing: 14) {
                    AFSIconBadge(icon: "shield.lefthalf.filled", color: AppTheme.gold)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Trang quản trị")
                            .font(.system(size: 16, weight: .bold)).foregroundColor(AppTheme.textPrimary)
                        Text("Xem tất cả tài khoản và vụ mùa canh tác")
                            .font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary.opacity(0.6))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var aboutCard: some View {
        AFSCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Spacer()
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 76, height: 76)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    Spacer()
                }
                AFSSectionTitle(icon: "info.circle", title: "Thông tin ứng dụng", subtitle: nil)
                aboutRow("Ứng dụng", "Nhật Ký Canh Tác")
                aboutRow("Chủ sở hữu", "AUTO FUNSION SYSTEM")
                aboutRow("Phiên bản", "1.1 (2026)")
                aboutRow("Bảo mật QR", "AES-256")
                aboutRow("Thời hạn QR", "Tùy chỉnh khi xuất")
            }
        }
    }

    private func aboutRow(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).font(.system(size: 13)).foregroundColor(AppTheme.textSecondary)
            Spacer()
            Text(v).font(.system(size: 13, weight: .semibold)).foregroundColor(AppTheme.textPrimary)
        }
    }

    private var logoutButton: some View {
        Button {
            showLogoutConfirm = true
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("ĐĂNG XUẤT").font(.system(size: 15, weight: .bold))
            }
        }
        .buttonStyle(AFSPrimaryButtonStyle(color: AppTheme.danger))
    }
}
