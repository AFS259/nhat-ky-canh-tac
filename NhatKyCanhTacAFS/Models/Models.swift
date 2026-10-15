import Foundation

// MARK: - Công việc (mục 3 - listbox, có thể thêm/xoá)
struct WorkItem: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var asset: String
    var builtin: Bool

    init(id: String = UUID().uuidString, name: String, asset: String, builtin: Bool = false) {
        self.id = id
        self.name = name
        self.asset = asset
        self.builtin = builtin
    }
}

enum WorkCatalog {

    /// Công việc mặc định (không xoá được).
    static let builtins: [WorkItem] = [
        .init(id: "work.water",       name: "Tưới nước",       asset: "WorkWater",            builtin: true),
        .init(id: "work.fertilizer",  name: "Bón phân",        asset: "WorkFertilizer",       builtin: true),
        .init(id: "work.leafFert",    name: "Phân bón lá",     asset: "WorkLeafFertilizer",   builtin: true),
        .init(id: "work.rootFert",    name: "Phân bón gốc",    asset: "WorkRootFertilizer",   builtin: true),
        .init(id: "work.spray",       name: "Phun thuốc cây",  asset: "WorkSpray",            builtin: true),
        .init(id: "work.pesticide",   name: "Thuốc BVTV",      asset: "WorkPesticide",        builtin: true),
        .init(id: "work.pest",        name: "Phòng sâu bệnh",  asset: "WorkBug",              builtin: true),
        .init(id: "work.disease",     name: "Phòng nấm bệnh",  asset: "WorkDisease",          builtin: true),
        .init(id: "work.bind",        name: "Quấn dây",        asset: "WorkBind",             builtin: true),
        .init(id: "work.prune",       name: "Tỉa chồi",        asset: "WorkPrune",            builtin: true),
        .init(id: "work.cutBranch",   name: "Tỉa cành",        asset: "WorkAxe",              builtin: true),
        .init(id: "work.pollinate",   name: "Thụ phấn",        asset: "WorkPollinate",        builtin: true),
        .init(id: "work.seed",        name: "Gieo hạt",        asset: "WorkSeed",             builtin: true),
        .init(id: "work.plant",       name: "Trồng cây",       asset: "WorkPlant",            builtin: true),
        .init(id: "work.plow",        name: "Cày đất",         asset: "WorkTractor",          builtin: true),
        .init(id: "work.dig",         name: "Xới đất",         asset: "WorkDig",              builtin: true),
        .init(id: "work.weed",        name: "Làm cỏ",          asset: "WorkBroom",            builtin: true),
        .init(id: "work.inspect",     name: "Kiểm tra vườn",   asset: "WorkSearch",           builtin: true),
        .init(id: "work.note",        name: "Ghi chép",        asset: "WorkNote",             builtin: true),
        .init(id: "work.harvest",     name: "Thu hoạch",       asset: "WorkHarvest",          builtin: true),
        .init(id: "work.cover",       name: "Bao trái",        asset: "WorkBox",              builtin: true),
        .init(id: "work.sell",        name: "Bán nông sản",    asset: "WorkSell",             builtin: true),
        .init(id: "work.transport",   name: "Vận chuyển",      asset: "WorkTruck",            builtin: true),
        .init(id: "work.repair",      name: "Sửa dụng cụ",     asset: "WorkHammer",           builtin: true),
    ]

    /// Toàn bộ icon công việc có sẵn để chọn khi tạo công việc mới.
    static let iconAssets: [String] = [
        "WorkWater", "WorkFertilizer", "WorkLeafFertilizer", "WorkRootFertilizer",
        "WorkSpray", "WorkPesticide", "WorkBug", "WorkDisease",
        "WorkBind", "WorkPrune", "WorkAxe", "WorkPollinate",
        "WorkSeed", "WorkPlant", "WorkTractor", "WorkDig",
        "WorkBroom", "WorkSearch", "WorkNote", "WorkHarvest",
        "WorkBox", "WorkSell", "WorkTruck", "WorkHammer",
        "WorkGear", "WorkSun", "WorkRain", "WorkFire",
        "WorkCalendar", "WorkBell",
    ]

    static let defaultAsset = "WorkNote"

    static func asset(forName name: String) -> String? {
        let key = normalize(name)
        return builtins.first { normalize($0.name) == key }?.asset
    }

    static func normalize(_ text: String) -> String {
        var s = text.folding(options: [.diacriticInsensitive, .caseInsensitive],
                             locale: Locale(identifier: "vi_VN")).lowercased()
        s = s.replacingOccurrences(of: "đ", with: "d")
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Nhật ký công việc (1 dòng của mục 2)
struct WorkLog: Identifiable, Codable, Hashable {
    var id: UUID
    var plantDate: Date          // cột 1 - ngày trồng
    var work: String             // cột 2 - công việc (tên)
    var performer: String        // cột 3 - người thực hiện
    var performDate: Date        // cột 4 - ngày thực hiện
    var note: String             // cột 5 - ghi chú
    var images: [String]         // cột 6 - hình ảnh (tên file trong Documents/Images)
    var createdAt: Date

    init(id: UUID = UUID(), plantDate: Date, work: String, performer: String = "",
         performDate: Date, note: String, images: [String] = [], createdAt: Date = Date()) {
        self.id = id
        self.plantDate = plantDate
        self.work = work
        self.performer = performer
        self.performDate = performDate
        self.note = note
        self.images = images
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id, plantDate, work, performer, performDate, note, images, createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        plantDate = try c.decode(Date.self, forKey: .plantDate)
        work = try c.decode(String.self, forKey: .work)
        performer = try c.decodeIfPresent(String.self, forKey: .performer) ?? ""
        performDate = try c.decode(Date.self, forKey: .performDate)
        note = try c.decode(String.self, forKey: .note)
        images = try c.decodeIfPresent([String].self, forKey: .images) ?? []
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }

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

    static let empty = Crop(cropType: "", variety: "", areaM2: 0, seedCount: 0,
                            sowDate: Date(), plantCount: 0, plantDate: Date())
}

// MARK: - Khu vực / Vườn
struct Area: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var address: String = ""
    var note: String = ""
    var latitude: Double? = nil
    var longitude: Double? = nil
    var createdAt: Date = Date()
    var crops: [Crop] = []

    var hasLocation: Bool { latitude != nil && longitude != nil }

    var mapsURL: URL? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return URL(string: "https://www.google.com/maps/search/?api=1&query=\(lat),\(lon)")
    }
}

// MARK: - Người dùng
struct AppUser: Codable, Hashable {
    var username: String
    var passwordHash: String
    var fullName: String
    var isAdmin: Bool = false
    var avatarFileName: String? = nil

    init(username: String, passwordHash: String, fullName: String, isAdmin: Bool = false, avatarFileName: String? = nil) {
        self.username = username
        self.passwordHash = passwordHash
        self.fullName = fullName
        self.isAdmin = isAdmin
        self.avatarFileName = avatarFileName
    }

    enum CodingKeys: String, CodingKey {
        case username, passwordHash, fullName, isAdmin, avatarFileName
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        username = try c.decode(String.self, forKey: .username)
        passwordHash = try c.decode(String.self, forKey: .passwordHash)
        fullName = try c.decode(String.self, forKey: .fullName)
        isAdmin = try c.decodeIfPresent(Bool.self, forKey: .isAdmin) ?? false
        avatarFileName = try c.decodeIfPresent(String.self, forKey: .avatarFileName)
    }
}
