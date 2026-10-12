import Foundation

// MARK: - Công việc (mục 3 - listbox)
enum WorkType: String, Codable, CaseIterable, Identifiable {
    case phanBonLa = "Phân bón lá"
    case phanBonGoc = "Phân bón gốc"
    case phunThuocCay = "Phun thuốc cây"
    case thuocBVTV = "Thuốc BVTV"
    case quanDay = "Quấn dây"
    case tiaChoi = "Tỉa chồi"
    case thuPhan = "Thụ phấn"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .phanBonLa: return "leaf.fill"
        case .phanBonGoc: return "drop.fill"
        case .phunThuocCay: return "spray"
        case .thuocBVTV: return "shield.lefthalf.filled"
        case .quanDay: return "arrow.triangle.turn.up.right.diamond.fill"
        case .tiaChoi: return "scissors"
        case .thuPhan: return "camera.macro"
        }
    }
}

// MARK: - Nhật ký công việc (1 dòng của mục 2)
struct WorkLog: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var plantDate: Date          // cột 1 - ngày trồng
    var work: WorkType           // cột 2 - công việc
    var performDate: Date        // cột 3 - ngày thực hiện
    var note: String             // cột 4 - ghi chú
    var images: [String] = []    // cột 5 - hình ảnh (tên file trong Documents/Images)
    var createdAt: Date = Date()

    /// Sau 1 ngày (24h) không được chỉnh sửa thông tin đã nhập.
    var isEditable: Bool {
        Date().timeIntervalSince(createdAt) < 24 * 60 * 60
    }

    var lockRemainingText: String {
        let remain = 24 * 60 * 60 - Date().timeIntervalSince(createdAt)
        if remain <= 0 { return "Đã khóa" }
        let hours = Int(remain / 3600)
        let minutes = Int(remain.truncatingRemainder(dividingBy: 3600) / 60)
        return "Còn \(hours)h \(minutes)p để sửa"
    }
}

// MARK: - Vụ / Lô cây trồng
struct Crop: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var cropType: String         // loại cây
    var variety: String          // giống
    var areaM2: Double           // diện tích (m2)
    var seedCount: Int           // số hạt gieo
    var sowDate: Date            // ngày gieo
    var plantCount: Int          // số cây trồng
    var plantDate: Date          // ngày trồng
    var createdAt: Date = Date()
    var logs: [WorkLog] = []

    var title: String { "\(cropType) · \(variety)" }
}

// MARK: - Khu vực / Vườn
struct Area: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var address: String = ""
    var note: String = ""
    var createdAt: Date = Date()
    var crops: [Crop] = []
}

// MARK: - Người dùng
struct AppUser: Codable, Hashable {
    var username: String
    var passwordHash: String
    var fullName: String
    var isAdmin: Bool = false

    init(username: String, passwordHash: String, fullName: String, isAdmin: Bool = false) {
        self.username = username
        self.passwordHash = passwordHash
        self.fullName = fullName
        self.isAdmin = isAdmin
    }

    enum CodingKeys: String, CodingKey {
        case username, passwordHash, fullName, isAdmin
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        username = try c.decode(String.self, forKey: .username)
        passwordHash = try c.decode(String.self, forKey: .passwordHash)
        fullName = try c.decode(String.self, forKey: .fullName)
        isAdmin = try c.decodeIfPresent(Bool.self, forKey: .isAdmin) ?? false
    }
}
