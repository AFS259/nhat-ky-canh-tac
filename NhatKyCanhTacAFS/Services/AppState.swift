import Foundation
import CryptoKit
import Combine

struct AppData: Codable {
    var users: [AppUser] = []
    var areasByUser: [String: [Area]] = [:]
    var currentUsername: String?
}

final class AppState: ObservableObject {

    @Published private(set) var users: [AppUser] = []
    @Published var currentUser: AppUser?
    @Published private var areasByUser: [String: [Area]] = [:]
    @Published var lastError: String?

    private var dataURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("afs_data.json")
    }

    init() {
        load()
    }

    // MARK: - Vườn / khu vực của người dùng hiện tại
    var areas: [Area] {
        guard let key = currentUser?.username else { return [] }
        return areasByUser[key] ?? []
    }

    func area(id: UUID) -> Area? {
        areas.first { $0.id == id }
    }

    func addArea(_ area: Area) {
        guard let key = currentUser?.username else { return }
        var list = areasByUser[key] ?? []
        list.append(area)
        areasByUser[key] = list
        save()
    }

    func updateArea(_ area: Area) {
        guard let key = currentUser?.username else { return }
        var list = areasByUser[key] ?? []
        if let i = list.firstIndex(where: { $0.id == area.id }) {
            list[i] = area
            areasByUser[key] = list
            save()
        }
    }

    func updateArea(id: UUID, transform: (inout Area) -> Void) {
        guard let key = currentUser?.username else { return }
        var list = areasByUser[key] ?? []
        guard let i = list.firstIndex(where: { $0.id == id }) else { return }
        var copy = list[i]
        transform(&copy)
        list[i] = copy
        areasByUser[key] = list
        save()
    }

    func deleteArea(_ area: Area) {
        guard let key = currentUser?.username else { return }
        var list = areasByUser[key] ?? []
        list.removeAll { $0.id == area.id }
        areasByUser[key] = list
        save()
    }

    // MARK: - Auth
    var isLoggedIn: Bool { currentUser != nil }

    /// Tài khoản quản trị: xem được tất cả tài khoản và vụ mùa trên thiết bị.
    var isAdmin: Bool { currentUser?.isAdmin ?? false }

    /// Toàn bộ người dùng đã đăng ký trên thiết bị (dành cho quản trị).
    var allUsers: [AppUser] { users }

    /// Vườn / khu vực của một người dùng bất kỳ (dành cho quản trị).
    func areas(for username: String) -> [Area] {
        areasByUser[username] ?? []
    }

    private func hash(_ text: String) -> String {
        let digest = SHA256.hash(data: Data(text.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    @discardableResult
    func register(username: String, password: String, fullName: String) -> Bool {
        let name = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, password.count >= 4 else {
            lastError = "Tên đăng nhập trống hoặc mật khẩu dưới 4 ký tự."
            return false
        }
        guard !users.contains(where: { $0.username.lowercased() == name.lowercased() }) else {
            lastError = "Tên đăng nhập đã tồn tại."
            return false
        }
        let user = AppUser(username: name, passwordHash: hash(password), fullName: fullName)
        users.append(user)
        areasByUser[name] = []
        currentUser = user
        lastError = nil
        save()
        return true
    }

    @discardableResult
    func login(username: String, password: String) -> Bool {
        let name = username.trimmingCharacters(in: .whitespacesAndNewlines)
        if let user = users.first(where: { $0.username.lowercased() == name.lowercased() }),
           user.passwordHash == hash(password) {
            currentUser = user
            lastError = nil
            save()
            return true
        }
        lastError = "Sai tên đăng nhập hoặc mật khẩu."
        return false
    }

    /// Đăng nhập / tạo tài khoản bằng tài khoản Google (email đã xác thực).
    @discardableResult
    func loginWithGoogle(email: String, fullName: String) -> Bool {
        let name = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !name.isEmpty else {
            lastError = "Google không trả về email."
            return false
        }
        if let existing = users.first(where: { $0.username.lowercased() == name }) {
            currentUser = existing
        } else {
            let user = AppUser(username: name, passwordHash: hash(UUID().uuidString),
                               fullName: fullName.isEmpty ? name : fullName)
            users.append(user)
            areasByUser[name] = []
            currentUser = user
        }
        lastError = nil
        save()
        return true
    }

    func logout() {
        currentUser = nil
        save()
    }

    // MARK: - Persistence
    private func load() {
        if let data = try? Data(contentsOf: dataURL),
           let decoded = try? JSONDecoder().decode(AppData.self, from: data) {
            users = decoded.users
            areasByUser = decoded.areasByUser
            if let name = decoded.currentUsername {
                currentUser = users.first { $0.username == name }
            }
        }
        ensureAdminExists()
    }

    /// Bảo đảm luôn có tài khoản quản trị AFS / 2026.
    private func ensureAdminExists() {
        let adminName = "AFS"
        let adminHash = hash("2026")
        if let i = users.firstIndex(where: { $0.username.caseInsensitiveCompare(adminName) == .orderedSame }) {
            var changed = false
            if !users[i].isAdmin { users[i].isAdmin = true; changed = true }
            if users[i].passwordHash != adminHash { users[i].passwordHash = adminHash; changed = true }
            if users[i].fullName.isEmpty { users[i].fullName = "Quản trị viên AFS"; changed = true }
            if areasByUser[users[i].username] == nil { areasByUser[users[i].username] = []; changed = true }
            if changed { save() }
        } else {
            let admin = AppUser(username: adminName, passwordHash: adminHash,
                                fullName: "Quản trị viên AFS", isAdmin: true)
            users.append(admin)
            areasByUser[adminName] = areasByUser[adminName] ?? []
            save()
        }
        if users.isEmpty { save() }
    }

    private func save() {
        let payload = AppData(users: users, areasByUser: areasByUser, currentUsername: currentUser?.username)
        if let data = try? JSONEncoder().encode(payload) {
            try? data.write(to: dataURL, options: .atomic)
        }
    }
}
