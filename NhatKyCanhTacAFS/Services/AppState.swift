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
        if users.isEmpty {
            let demo = AppUser(username: "afs", passwordHash: hash("1234"), fullName: "Kỹ thuật viên AFS")
            users = [demo]
            areasByUser["afs"] = []
            save()
        }
    }

    private func save() {
        let payload = AppData(users: users, areasByUser: areasByUser, currentUsername: currentUser?.username)
        if let data = try? JSONEncoder().encode(payload) {
            try? data.write(to: dataURL, options: .atomic)
        }
    }
}
