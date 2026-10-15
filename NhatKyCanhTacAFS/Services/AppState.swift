import Foundation
import CryptoKit
import Combine
import UIKit

struct AppData: Codable {
    var users: [AppUser] = []
    var areasByUser: [String: [Area]] = [:]
    var currentUsername: String?
    var customWorksByUser: [String: [WorkItem]] = [:]
    var performersByUser: [String: [String]] = [:]

    init(users: [AppUser] = [], areasByUser: [String: [Area]] = [:], currentUsername: String? = nil,
         customWorksByUser: [String: [WorkItem]] = [:], performersByUser: [String: [String]] = [:]) {
        self.users = users
        self.areasByUser = areasByUser
        self.currentUsername = currentUsername
        self.customWorksByUser = customWorksByUser
        self.performersByUser = performersByUser
    }

    enum CodingKeys: String, CodingKey {
        case users, areasByUser, currentUsername, customWorksByUser, performersByUser
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        users = try c.decodeIfPresent([AppUser].self, forKey: .users) ?? []
        areasByUser = try c.decodeIfPresent([String: [Area]].self, forKey: .areasByUser) ?? [:]
        currentUsername = try c.decodeIfPresent(String.self, forKey: .currentUsername)
        customWorksByUser = try c.decodeIfPresent([String: [WorkItem]].self, forKey: .customWorksByUser) ?? [:]
        performersByUser = try c.decodeIfPresent([String: [String]].self, forKey: .performersByUser) ?? [:]
    }
}

final class AppState: ObservableObject {

    @Published private(set) var users: [AppUser] = []
    @Published var currentUser: AppUser?
    @Published private var areasByUser: [String: [Area]] = [:]
    @Published private var customWorksByUser: [String: [WorkItem]] = [:]
    @Published private var performersByUser: [String: [String]] = [:]
    @Published var lastError: String?
    @Published private(set) var avatarImage: UIImage?

    private var currentKey: String? { currentUser?.username }

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
        syncToSheet(area)
    }

    func updateArea(_ area: Area) {
        guard let key = currentUser?.username else { return }
        var list = areasByUser[key] ?? []
        if let i = list.firstIndex(where: { $0.id == area.id }) {
            list[i] = area
            areasByUser[key] = list
            save()
            syncToSheet(area)
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
        syncToSheet(copy)
    }

    func deleteArea(_ area: Area) {
        guard let key = currentUser?.username else { return }
        var list = areasByUser[key] ?? []
        list.removeAll { $0.id == area.id }
        areasByUser[key] = list
        save()
        GoogleSheetService.deleteArea(area, username: key)
    }

    // MARK: - Quản trị: xoá tài khoản đã đăng ký
    /// Kiểm tra mật khẩu quản trị (mặc định "2026").
    func verifyAdminPassword(_ password: String) -> Bool {
        guard let admin = users.first(where: { $0.isAdmin }) else { return false }
        return admin.passwordHash == hash(password)
    }

    /// Xoá một tài khoản đã đăng ký cùng toàn bộ dữ liệu của tài khoản đó.
    /// Chỉ quản trị viên thực hiện được; không xoá được tài khoản quản trị.
    @discardableResult
    func deleteUser(_ user: AppUser) -> Bool {
        guard isAdmin else {
            lastError = "Chỉ quản trị viên mới được xoá tài khoản."
            return false
        }
        guard !user.isAdmin else {
            lastError = "Không thể xoá tài khoản quản trị."
            return false
        }
        guard let i = users.firstIndex(where: { $0.username == user.username }) else { return false }

        let userAreas = areasByUser[user.username] ?? []
        for area in userAreas {
            GoogleSheetService.deleteArea(area, username: user.username)
        }
        if let fn = user.avatarFileName, let url = avatarURL(fn) {
            try? FileManager.default.removeItem(at: url)
        }
        areasByUser[user.username] = nil
        customWorksByUser[user.username] = nil
        performersByUser[user.username] = nil
        users.remove(at: i)
        lastError = nil
        save()
        return true
    }

    // MARK: - Google Sheet sync (mỗi khu vực một sheet)
    private func syncToSheet(_ area: Area) {
        guard let username = currentUser?.username else { return }
        GoogleSheetService.syncArea(area, username: username)
    }

    /// Re-sync một khu vực lên Google Sheet (dùng sau khi cập nhật phụ (vd. QR link)).
    func resyncArea(id: UUID) {
        guard let key = currentUser?.username else { return }
        let list = areasByUser[key] ?? []
        guard let area = list.first(where: { $0.id == id }) else { return }
        syncToSheet(area)
    }

    // MARK: - Danh sách công việc (thêm/xoá, lưu theo tài khoản trên máy)
    /// Công việc mặc định + công việc tự thêm của tài khoản hiện tại.
    var workItems: [WorkItem] {
        guard let key = currentKey else { return WorkCatalog.builtins }
        return WorkCatalog.builtins + (customWorksByUser[key] ?? [])
    }

    /// Trả về tên asset icon cho một công việc (theo tên).
    func workAsset(for name: String) -> String {
        let key = WorkCatalog.normalize(name)
        if let custom = (currentKey.flatMap { customWorksByUser[$0] } ?? [])
            .first(where: { WorkCatalog.normalize($0.name) == key }) {
            return custom.asset
        }
        return WorkCatalog.asset(forName: name) ?? WorkCatalog.defaultAsset
    }

    @discardableResult
    func addWork(name: String, asset: String) -> Bool {
        guard let key = currentKey else { return false }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { lastError = "Tên công việc không được để trống."; return false }
        guard !workItems.contains(where: { WorkCatalog.normalize($0.name) == WorkCatalog.normalize(trimmed) }) else {
            lastError = "Công việc đã tồn tại trong danh sách."; return false
        }
        var list = customWorksByUser[key] ?? []
        list.append(WorkItem(name: trimmed, asset: asset))
        customWorksByUser[key] = list
        lastError = nil
        save()
        return true
    }

    func deleteWork(id: String) {
        guard let key = currentKey else { return }
        var list = customWorksByUser[key] ?? []
        list.removeAll { $0.id == id }
        customWorksByUser[key] = list
        save()
    }

    /// Các công việc tự thêm (có thể xoá).
    var customWorks: [WorkItem] {
        guard let key = currentKey else { return [] }
        return customWorksByUser[key] ?? []
    }

    // MARK: - Danh sách người thực hiện (thêm/xoá, lưu theo tài khoản trên máy)
    var performers: [String] {
        guard let key = currentKey else { return [] }
        return performersByUser[key] ?? []
    }

    @discardableResult
    func addPerformer(_ name: String) -> Bool {
        guard let key = currentKey else { return false }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { lastError = "Tên người thực hiện không được để trống."; return false }
        var list = performersByUser[key] ?? []
        guard !list.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) else {
            lastError = "Người thực hiện đã tồn tại."; return false
        }
        list.append(trimmed)
        performersByUser[key] = list
        lastError = nil
        save()
        return true
    }

    func removePerformer(_ name: String) {
        guard let key = currentKey else { return }
        var list = performersByUser[key] ?? []
        list.removeAll { $0.caseInsensitiveCompare(name) == .orderedSame }
        performersByUser[key] = list
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
        loadAvatar()
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
            loadAvatar()
            save()
            return true
        }
        lastError = "Sai tên đăng nhập hoặc mật khẩu."
        return false
    }

    func logout() {
        currentUser = nil
        avatarImage = nil
        save()
    }

    // MARK: - Cập nhật tài khoản
    /// Cập nhật họ tên, tên đăng nhập và (tuỳ chọn) đổi mật khẩu. Trả về false nếu có lỗi.
    @discardableResult
    func updateAccount(newUsername: String, fullName: String,
                       currentPassword: String?, newPassword: String?) -> Bool {
        guard var user = currentUser else { return false }
        let name = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let uname = newUsername.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !name.isEmpty else { lastError = "Họ và tên không được để trống."; return false }
        guard !uname.isEmpty else { lastError = "Tên đăng nhập không được để trống."; return false }
        let taken = users.contains {
            $0.username.caseInsensitiveCompare(uname) == .orderedSame && $0.username != user.username
        }
        guard !taken else { lastError = "Tên đăng nhập đã tồn tại."; return false }

        var newHash = user.passwordHash
        if let newPassword, !newPassword.isEmpty {
            guard newPassword.count >= 4 else { lastError = "Mật khẩu mới phải từ 4 ký tự."; return false }
            guard let currentPassword, hash(currentPassword) == user.passwordHash else {
                lastError = "Mật khẩu hiện tại không đúng."; return false
            }
            newHash = hash(newPassword)
        }

        let oldName = user.username
        user.username = uname
        user.fullName = name
        user.passwordHash = newHash

        if oldName != uname {
            areasByUser[uname] = areasByUser[oldName] ?? []
            areasByUser[oldName] = nil
            customWorksByUser[uname] = customWorksByUser[oldName] ?? []
            customWorksByUser[oldName] = nil
            performersByUser[uname] = performersByUser[oldName] ?? []
            performersByUser[oldName] = nil
        }
        if let i = users.firstIndex(where: { $0.username == oldName }) {
            users[i] = user
        }
        currentUser = user
        lastError = nil
        loadAvatar()
        save()
        return true
    }

    // MARK: - Ảnh đại diện
    private func avatarURL(_ filename: String) -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent(filename)
    }

    @discardableResult
    func setAvatar(imageData: Data) -> Bool {
        guard var user = currentUser, let url = avatarURL("avatar_\(user.username).jpg") else { return false }
        do {
            try imageData.write(to: url, options: .atomic)
            user.avatarFileName = url.lastPathComponent
            if let i = users.firstIndex(where: { $0.username == user.username }) {
                users[i] = user
            }
            currentUser = user
            loadAvatar()
            save()
            return true
        } catch {
            lastError = "Không lưu được ảnh đại diện."
            return false
        }
    }

    func loadAvatar() {
        guard let name = currentUser?.avatarFileName,
              let url = avatarURL(name),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            avatarImage = nil
            return
        }
        avatarImage = image
    }

    // MARK: - Persistence
    private func load() {
        if let data = try? Data(contentsOf: dataURL),
           let decoded = try? JSONDecoder().decode(AppData.self, from: data) {
            users = decoded.users
            areasByUser = decoded.areasByUser
            customWorksByUser = decoded.customWorksByUser
            performersByUser = decoded.performersByUser
            if let name = decoded.currentUsername {
                currentUser = users.first { $0.username == name }
            }
        }
        ensureAdminExists()
        loadAvatar()
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
        let payload = AppData(users: users, areasByUser: areasByUser, currentUsername: currentUser?.username,
                              customWorksByUser: customWorksByUser, performersByUser: performersByUser)
        if let data = try? JSONEncoder().encode(payload) {
            try? data.write(to: dataURL, options: .atomic)
        }
    }
}
