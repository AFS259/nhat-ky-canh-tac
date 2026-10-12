import SwiftUI

struct AccountView: View {
    @EnvironmentObject private var app: AppState
    @State private var showLogoutConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.screenGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        profileCard
                        statsCard
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
        }
    }

    private var profileCard: some View {
        AFSCard(padding: 20) {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(AppTheme.heroGradient).frame(width: 68, height: 68)
                    Image(systemName: "person.fill").font(.system(size: 28)).foregroundColor(.white)
                }
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
            }
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

    private var aboutCard: some View {
        AFSCard {
            VStack(alignment: .leading, spacing: 12) {
                AFSSectionTitle(icon: "info.circle", title: "Thông tin ứng dụng", subtitle: nil)
                aboutRow("Ứng dụng", "Nhật Ký Canh Tác AFS")
                aboutRow("Chủ sở hữu", "AUTO FUNSION SYSTEM")
                aboutRow("Phiên bản", "1.0 (2026)")
                aboutRow("Bảo mật QR", "AES-256 · Hạn 10 ngày")
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
