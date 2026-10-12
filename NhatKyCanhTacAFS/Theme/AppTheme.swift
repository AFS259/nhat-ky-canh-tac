import SwiftUI
import UIKit

enum AppTheme {

    // MARK: - Palette (xanh nông học, sáng & trực quan)
    static let primary = Color.afsGreen
    static let primaryDark = Color.afsGreenDark
    static let primaryLight = Color.afsGreenLight
    static let accent = Color.afsLime
    static let background = Color.afsBackground
    static let card = Color.afsCard
    static let textPrimary = Color.afsTextPrimary
    static let textSecondary = Color.afsTextSecondary
    static let line = Color.afsLine
    static let danger = Color(hex: 0xC62828)
    static let warning = Color(hex: 0xEF6C00)
    static let gold = Color(hex: 0xF9A825)

    static let screenGradient = LinearGradient(
        colors: [Color(hex: 0xEAF6DE), Color(hex: 0xF7FCF2)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let heroGradient = LinearGradient(
        colors: [Color(hex: 0x1B5E20), Color(hex: 0x43A047)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardShadow = Color.black.opacity(0.06)
    static let radius: CGFloat = 18

    static func configureAppearance() {
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = UIColor(primary)
        nav.titleTextAttributes = [.foregroundColor: UIColor.white]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().tintColor = .white

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = UIColor.white
        tab.stackedLayoutAppearance.selected.iconColor = UIColor(primary)
        tab.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(primary)]
        tab.stackedLayoutAppearance.normal.iconColor = UIColor(textSecondary)
        tab.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(textSecondary)]
        UITabBar.appearance().standardAppearance = tab
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tab
        }
    }
}

// MARK: - Reusable building blocks

struct AFSCard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.radius, style: .continuous)
                    .fill(AppTheme.card)
                    .shadow(color: AppTheme.cardShadow, radius: 10, x: 0, y: 4)
            )
    }
}

struct AFSSectionTitle: View {
    let icon: String
    let title: String
    var subtitle: String? = nil

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AppTheme.primary.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.primary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            Spacer()
        }
    }
}

struct AFSPrimaryButtonStyle: ButtonStyle {
    var color: Color = AppTheme.primary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(color)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}

struct AFSLabeledField<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.primary)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)
            }
            content
        }
    }
}

struct AFSTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboard)
            .font(.system(size: 15))
            .foregroundColor(AppTheme.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(hex: 0xF6FBF1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(AppTheme.line, lineWidth: 1)
            )
    }
}

struct AFSIconBadge: View {
    let icon: String
    var color: Color = AppTheme.primary

    var body: some View {
        ZStack {
            Circle().fill(color.opacity(0.14)).frame(width: 44, height: 44)
            Image(systemName: icon)
                .font(.system(size: 19, weight: .semibold))
                .foregroundColor(color)
        }
    }
}
