import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        TabView {
            AreaListView()
                .tabItem { Label("Vườn", systemImage: "tree.fill") }

            ScanHomeView()
                .tabItem { Label("Quét QR", systemImage: "qrcode.viewfinder") }

            if app.isAdmin {
                AdminView()
                    .tabItem { Label("Quản trị", systemImage: "shield.lefthalf.filled") }
            }

            AccountView()
                .tabItem { Label("Tài khoản", systemImage: "person.crop.circle.fill") }
        }
        .tint(AppTheme.primary)
    }
}
