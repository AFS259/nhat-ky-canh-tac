import Foundation
import AuthenticationServices
import CryptoKit
import UIKit

struct GoogleProfile {
    let email: String
    let name: String
}

enum GoogleAuthError: LocalizedError {
    case notConfigured
    case cancelled
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Chưa cấu hình Google Client ID. Vui lòng nhập Client ID iOS trong GoogleAuth.clientID."
        case .cancelled:
            return "Bạn đã hủy đăng nhập Google."
        case .failed(let msg):
            return "Đăng nhập Google thất bại: \(msg)"
        }
    }
}

/// Đăng nhập Google thật bằng OAuth 2.0 + PKCE (không cần SDK).
/// Điền `clientID` bằng "iOS Client ID" tạo trong Google Cloud Console
/// (đã bật OAuth consent screen + đăng ký bundle id iOS) để kích hoạt.
enum GoogleAuth {

    /// TODO: dán iOS Client ID, dạng "1234567890-xxxxxxxx.apps.googleusercontent.com".
    static let clientID = ""

    static var isConfigured: Bool {
        !clientID.trimmingCharacters(in: .whitespaces).isEmpty
    }

    @MainActor
    static func signIn() async throws -> GoogleProfile {
        guard isConfigured else { throw GoogleAuthError.notConfigured }

        let verifier = randomURLSafe(length: 64)
        let challenge = sha256Base64URL(verifier)
        let scheme = reversedClientScheme(clientID)
        let redirect = "\(scheme):/oauth2redirect"

        var comps = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        comps.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirect),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "openid email profile"),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "prompt", value: "select_account"),
        ]

        let callback = try await present(url: comps.url!, scheme: scheme)
        guard let code = URLComponents(url: callback, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "code" })?.value else {
            throw GoogleAuthError.failed("Không nhận được mã uỷ quyền.")
        }

        let idToken = try await exchange(code: code, verifier: verifier, redirect: redirect)
        return try parseIDToken(idToken)
    }

    // MARK: - OAuth plumbing

    @MainActor
    private static func present(url: URL, scheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<URL, Error>) in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: scheme) { callback, error in
                Holder.session = nil
                if let error = error {
                    cont.resume(throwing: GoogleAuthError.failed(error.localizedDescription))
                } else if let callback {
                    cont.resume(returning: callback)
                } else {
                    cont.resume(throwing: GoogleAuthError.cancelled)
                }
            }
            session.presentationContextProvider = Holder.provider
            session.prefersEphemeralWebBrowserSession = false
            Holder.session = session
            if !session.start() {
                Holder.session = nil
                cont.resume(throwing: GoogleAuthError.failed("Không mở được trang đăng nhập."))
            }
        }
    }

    private static func exchange(code: String, verifier: String, redirect: String) async throws -> String {
        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let fields = [
            ("code", code),
            ("client_id", clientID),
            ("code_verifier", verifier),
            ("grant_type", "authorization_code"),
            ("redirect_uri", redirect),
        ]
        request.httpBody = fields
            .map { "\($0.0)=\(urlEncode($0.1))" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: request)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let idToken = json["id_token"] as? String else {
            throw GoogleAuthError.failed("Không lấy được token từ Google.")
        }
        return idToken
    }

    private static func parseIDToken(_ token: String) throws -> GoogleProfile {
        let parts = token.split(separator: ".")
        guard parts.count >= 2 else { throw GoogleAuthError.failed("Token không hợp lệ.") }
        var payload = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while payload.count % 4 != 0 { payload += "=" }
        guard let data = Data(base64Encoded: payload),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw GoogleAuthError.failed("Không đọc được thông tin tài khoản.")
        }
        let email = json["email"] as? String ?? ""
        let name = json["name"] as? String ?? email
        guard !email.isEmpty else { throw GoogleAuthError.failed("Google không trả về email.") }
        return GoogleProfile(email: email, name: name)
    }

    // MARK: - Helpers

    private static func reversedClientScheme(_ clientID: String) -> String {
        // com.googleusercontent.apps.<id> thu được khi đảo client id
        clientID.split(separator: ".").reversed().joined(separator: ".")
    }

    private static func randomURLSafe(length: Int) -> String {
        let key = SymmetricKey(size: .bits256)
        let data = key.withUnsafeBytes { Data($0) }
        return data.base64URLEncoded()
    }

    private static func sha256Base64URL(_ text: String) -> String {
        let digest = SHA256.hash(data: Data(text.utf8))
        return Data(digest).base64URLEncoded()
    }

    private static func urlEncode(_ value: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }

    private final class Provider: NSObject, ASWebAuthenticationPresentationContextProviding {
        func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow } ?? ASPresentationAnchor()
        }
    }

    private enum Holder {
        static var session: ASWebAuthenticationSession?
        static let provider = Provider()
    }
}

private extension Data {
    func base64URLEncoded() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
