import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            AreaListView()
                .tabItem { Label("Vườn", systemImage: "tree.fill") }

            ScanHomeView()
                .tabItem { Label("Quét QR", systemImage: "qrcode.viewfinder") }

            AccountView()
                .tabItem { Label("Tài khoản", systemImage: "person.crop.circle.fill") }
        }
        .tint(AppTheme.primary)
    }
}
