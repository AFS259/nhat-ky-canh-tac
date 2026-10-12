import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var fullName = ""
    @State private var username = ""
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var errorText: String?
    @FocusState private var focus: Field?

    private enum Field { case fullName, username, current, new, confirm }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.screenGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        infoCard
                        accountCard
                        passwordCard
                        if let errorText {
                            errorCard(errorText)
                        }
                        Button {
                            focus = nil
                            save()
                        } label: {
                            Text("LƯU THAY ĐỔI")
                        }
                        .buttonStyle(AFSPrimaryButtonStyle())
                    }
                    .padding(20)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Chỉnh sửa tài khoản")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") { dismiss() }.foregroundColor(.white)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Xong") { focus = nil }
                }
            }
            .onAppear {
                fullName = app.currentUser?.fullName ?? ""
                username = app.currentUser?.username ?? ""
            }
        }
    }

    private var infoCard: some View {
        AFSCard {
            HStack(spacing: 12) {
                Image(systemName: "person.text.rectangle")
                    .font(.system(size: 22))
                    .foregroundColor(AppTheme.primary)
                    .frame(width: 46, height: 46)
                    .background(Circle().fill(AppTheme.primary.opacity(0.12)))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Thông tin tài khoản")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Đổi ảnh đại diện ở trang Tài khoản")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var accountCard: some View {
        AFSCard {
            VStack(alignment: .leading, spacing: 14) {
                AFSSectionTitle(icon: "person.fill", title: "Hồ sơ", subtitle: "Họ tên và tên đăng nhập")

                AFSLabeledField(title: "Họ và tên", icon: "person.text.rectangle") {
                    AFSTextField(placeholder: "Nguyễn Văn A", text: $fullName)
                        .focused($focus, equals: .fullName)
                }

                AFSLabeledField(title: "Tên đăng nhập", icon: "at") {
                    AFSTextField(placeholder: "Nhập tên đăng nhập", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focus, equals: .username)
                }
            }
        }
    }

    private var passwordCard: some View {
        AFSCard {
            VStack(alignment: .leading, spacing: 14) {
                AFSSectionTitle(icon: "lock.rotation", title: "Đổi mật khẩu",
                                subtitle: "Bỏ trống nếu không muốn đổi.")

                AFSLabeledField(title: "Mật khẩu hiện tại", icon: "lock.fill") {
                    secureField("Nhập mật khẩu hiện tại", text: $currentPassword, field: .current)
                }

                AFSLabeledField(title: "Mật khẩu mới", icon: "lock.open.fill") {
                    secureField("Nhập mật khẩu mới", text: $newPassword, field: .new)
                }

                AFSLabeledField(title: "Nhập lại mật khẩu mới", icon: "lock.open.fill") {
                    secureField("Nhập lại mật khẩu mới", text: $confirmPassword, field: .confirm)
                }

                Toggle(isOn: $showPassword) {
                    Text("Hiện mật khẩu")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .tint(AppTheme.primary)
            }
        }
    }

    @ViewBuilder
    private func secureField(_ placeholder: String, text: Binding<String>, field: Field) -> some View {
        HStack(spacing: 8) {
            Group {
                if showPassword {
                    TextField(placeholder, text: text)
                } else {
                    SecureField(placeholder, text: text)
                }
            }
            .font(.system(size: 15))
            .foregroundColor(AppTheme.textPrimary)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused($focus, equals: field)

            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                .foregroundColor(AppTheme.textSecondary)
                .font(.system(size: 14))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(hex: 0xF6FBF1)))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(AppTheme.line, lineWidth: 1))
    }

    private func errorCard(_ text: String) -> some View {
        AFSCard {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(AppTheme.danger)
                Text(text).font(.system(size: 13)).foregroundColor(AppTheme.textPrimary)
            }
        }
    }

    private func save() {
        errorText = nil
        let newFull = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let newUser = username.trimmingCharacters(in: .whitespacesAndNewlines)

        if newFull.isEmpty {
            errorText = "Họ và tên không được để trống."
            return
        }
        if newUser.isEmpty {
            errorText = "Tên đăng nhập không được để trống."
            return
        }

        var current: String? = nil
        var new: String? = nil
        if !newPassword.isEmpty {
            if newPassword != confirmPassword {
                errorText = "Mật khẩu nhập lại không khớp."
                return
            }
            if newPassword.count < 4 {
                errorText = "Mật khẩu mới phải từ 4 ký tự."
                return
            }
            current = currentPassword
            new = newPassword
        }

        if app.updateAccount(newUsername: newUser, fullName: newFull,
                             currentPassword: current, newPassword: new) {
            dismiss()
        } else {
            errorText = app.lastError ?? "Không cập nhật được tài khoản."
        }
    }
}

#Preview {
    EditProfileView().environmentObject(AppState())
}
