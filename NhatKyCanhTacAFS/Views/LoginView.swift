import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var app: AppState

    @State private var username = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var isRegister = false
    @State private var showPassword = false
    @FocusState private var focus: Field?

    private enum Field { case username, password, fullName }

    var body: some View {
        ZStack {
            AppTheme.screenGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    header
                    formCard
                    footer
                    Spacer(minLength: 10)
                }
                .padding(.horizontal, 22)
                .padding(.top, 30)
                .padding(.bottom, 30)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: 14) {
            Image("LoginLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 104, height: 104)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .shadow(color: AppTheme.primary.opacity(0.35), radius: 14, y: 8)
            VStack(spacing: 4) {
                Text("NHẬT KÝ CANH TÁC")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundColor(AppTheme.primaryDark)
                Text("Thuộc AUTO FUNSION SYSTEM")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }

    // MARK: - Form
    private var formCard: some View {
        AFSCard(padding: 20) {
            VStack(spacing: 16) {
                HStack(spacing: 0) {
                    segment(title: "Đăng nhập", active: !isRegister) { isRegister = false }
                    segment(title: "Đăng ký", active: isRegister) { isRegister = true }
                }
                .padding(4)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(hex: 0xEEF6E6)))

                if isRegister {
                    AFSLabeledField(title: "Họ và tên", icon: "person.text.rectangle") {
                        AFSTextField(placeholder: "Nguyễn Văn A", text: $fullName)
                            .focused($focus, equals: .fullName)
                    }
                }

                AFSLabeledField(title: "Tên đăng nhập", icon: "person.fill") {
                    AFSTextField(placeholder: "Nhập tên đăng nhập", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focus, equals: .username)
                }

                AFSLabeledField(title: "Mật khẩu", icon: "lock.fill") {
                    HStack(spacing: 8) {
                        if showPassword {
                            AFSTextField(placeholder: "Nhập mật khẩu", text: $password)
                                .focused($focus, equals: .password)
                        } else {
                            SecureField("Nhập mật khẩu", text: $password)
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.textPrimary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 13)
                                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(hex: 0xF6FBF1)))
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(AppTheme.line, lineWidth: 1))
                                .focused($focus, equals: .password)
                        }
                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .padding(.trailing, 4)
                    }
                }

                if let err = app.lastError {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(err).font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(AppTheme.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    focus = nil
                    submit()
                } label: {
                    Text(isRegister ? "TẠO TÀI KHOẢN" : "ĐĂNG NHẬP")
                }
                .buttonStyle(AFSPrimaryButtonStyle())
                .padding(.top, 4)
            }
        }
    }

    private func segment(title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(active ? .white : AppTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(active ? AppTheme.primary : .clear)
                )
        }
    }

    private var footer: some View {
        VStack(spacing: 6) {
            Text("© 2026 AUTO FUNSION SYSTEM")
                .font(.system(size: 11))
                .foregroundColor(AppTheme.textSecondary.opacity(0.8))
        }
    }

    private func submit() {
        if isRegister {
            _ = app.register(username: username, password: password, fullName: fullName.isEmpty ? username : fullName)
        } else {
            _ = app.login(username: username, password: password)
        }
    }
}

#Preview {
    LoginView().environmentObject(AppState())
}
