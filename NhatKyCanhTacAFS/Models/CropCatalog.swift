import Foundation

// MARK: - Danh mục cây trồng + icon trái cây (bộ ảnh OpenMoji trong Assets.xcassets)
struct CropCatalogItem: Identifiable {
    let name: String
    let asset: String
    let varieties: [String]

    var id: String { name }
}

enum CropCatalog {

    static let fallbackAsset = "FruitSeedling"

    /// Danh mục đầy đủ các loại trái cây / rau củ dùng cho gợi ý và biểu tượng.
    static let items: [CropCatalogItem] = [
        // --- Trái cây ---
        .init(name: "Ổi", asset: "FruitGuava",
              varieties: ["Ổi Đài Loan", "Ổi Lê", "Ổi Nữ Hoàng", "Ổi Xá Lị"]),
        .init(name: "Xoài", asset: "FruitMango",
              varieties: ["Xoài Cát Chu", "Xoài Cát Hòa Lộc", "Xoài Đài Loan", "Xoài Tứ Quý"]),
        .init(name: "Bưởi", asset: "FruitPomelo",
              varieties: ["Bưởi Da Xanh", "Bưởi Năm Roi", "Bưởi Tân Triều", "Bưởi Diễn"]),
        .init(name: "Cam", asset: "FruitOrange",
              varieties: ["Cam Sành", "Cam Vinh", "Cam Xoàn", "Cam Cao Phong"]),
        .init(name: "Quýt", asset: "FruitPomelo",
              varieties: ["Quýt Đường", "Quýt Hồng"]),
        .init(name: "Chanh", asset: "FruitLemon",
              varieties: ["Chanh Dây", "Chanh Không Hạt", "Chanh Tứ Quý", "Chanh Đào"]),
        .init(name: "Thanh Long", asset: "FruitDragonFruit",
              varieties: ["Thanh Long Ruột Đỏ", "Thanh Long Ruột Trắng"]),
        .init(name: "Dưa Hấu", asset: "FruitWatermelon",
              varieties: ["Dưa Hấu Black Lady", "Dưa Hấu Hắc Mỹ Nhân"]),
        .init(name: "Dưa Lưới", asset: "FruitMelon",
              varieties: ["Dưa Lưới Nhật", "Dưa Lưới Hàn Quốc"]),
        .init(name: "Táo", asset: "FruitApple",
              varieties: ["Táo Gala", "Táo Fuji", "Táo Envy"]),
        .init(name: "Chuối", asset: "FruitBanana",
              varieties: ["Chuối Già", "Chuối Sứ", "Chuối Tiêu"]),
        .init(name: "Dứa", asset: "FruitPineapple",
              varieties: ["Dứa Cayenne", "Dứa Queen", "Dứa MD2"]),
        .init(name: "Đào", asset: "FruitPeach",
              varieties: ["Đào Pháp", "Đào Tiên"]),
        .init(name: "Mận", asset: "FruitPeach",
              varieties: ["Mận Hậu", "Mận Tam Hoa"]),
        .init(name: "Anh Đào", asset: "FruitCherry",
              varieties: ["Anh Đào Mỹ", "Anh Đào Đà Lạt"]),
        .init(name: "Dâu Tây", asset: "FruitStrawberry",
              varieties: ["Dâu Tây Đà Lạt", "Dâu Tây New Zealand"]),
        .init(name: "Chôm Chôm", asset: "FruitStrawberry",
              varieties: ["Chôm Chôm Java", "Chôm Chôm Nhãn"]),
        .init(name: "Kiwi", asset: "FruitKiwi",
              varieties: ["Kiwi Vàng", "Kiwi Xanh"]),
        .init(name: "Dừa Xiêm", asset: "FruitCoconut",
              varieties: ["Dừa Xiêm Xanh", "Dừa Xiêm Lửa"]),
        .init(name: "Bơ", asset: "FruitAvocado",
              varieties: ["Bơ Booth", "Bơ Hass", "Bơ 034"]),
        .init(name: "Nho", asset: "FruitGrape",
              varieties: ["Nho Ninh Thuận", "Nho Mẫu Đơn", "Nho Hạ Đen"]),
        .init(name: "Nhãn", asset: "FruitGrape",
              varieties: ["Nhãn Xuồng", "Nhãn Ido", "Nhãn Tiêu"]),
        .init(name: "Vải", asset: "FruitGrape",
              varieties: ["Vải Thiều", "Vải Lai"]),
        .init(name: "Việt Quất", asset: "FruitBlueberry",
              varieties: []),
        .init(name: "Ô Liu", asset: "FruitOlive",
              varieties: []),
        .init(name: "Mít", asset: "FruitPineapple",
              varieties: ["Mít Thái", "Mít Nghệ"]),
        .init(name: "Sầu Riêng", asset: "FruitPineapple",
              varieties: ["Sầu Riêng Ri6", "Sầu Riêng Monthong"]),
        .init(name: "Mãng Cầu", asset: "FruitPineapple",
              varieties: ["Mãng Cầu Xiêm", "Mãng Cầu Ta"]),
        .init(name: "Đu Đủ", asset: "FruitMango",
              varieties: ["Đu Đủ Vàng", "Đu Đủ Ruột Đỏ"]),
        .init(name: "Lê", asset: "FruitGuava",
              varieties: ["Lê Hàn Quốc", "Lê Đài Loan"]),
        // --- Rau củ ---
        .init(name: "Cà Chua", asset: "FruitTomato",
              varieties: ["Cà Chua Cherry", "Cà Chua Bi", "Cà Chua Beef"]),
        .init(name: "Ớt", asset: "FruitChili",
              varieties: ["Ớt Chỉ Thiên", "Ớt Hiểm", "Ớt Sừng"]),
        .init(name: "Ớt Chuông", asset: "FruitBellPepper",
              varieties: ["Ớt Chuông Đỏ", "Ớt Chuông Xanh", "Ớt Chuông Vàng"]),
        .init(name: "Dưa Leo", asset: "FruitCucumber",
              varieties: ["Dưa Leo Baby", "Dưa Leo Quả Dài"]),
        .init(name: "Khổ Qua", asset: "FruitCucumber",
              varieties: ["Khổ Qua Xanh", "Khổ Qua Trắng"]),
        .init(name: "Cà Tím", asset: "FruitEggplant",
              varieties: ["Cà Tím Dài", "Cà Tím Tròn"]),
        .init(name: "Bí Đỏ", asset: "FruitPumpkin",
              varieties: ["Bí Đỏ Nhật", "Bí Đỏ Đài Loan"]),
        .init(name: "Ngô", asset: "FruitCorn",
              varieties: ["Ngô Ngọt", "Ngô Nếp", "Ngô Tím"]),
        .init(name: "Khoai Tây", asset: "FruitPotato",
              varieties: ["Khoai Tây Đà Lạt", "Khoai Tây Atlantic"]),
        .init(name: "Khoai Lang", asset: "FruitSweetPotato",
              varieties: ["Khoai Lang Mật", "Khoai Lang Tím"]),
        .init(name: "Cà Rốt", asset: "FruitCarrot",
              varieties: ["Cà Rốt Đà Lạt"]),
        .init(name: "Tỏi", asset: "FruitGarlic",
              varieties: ["Tỏi Lý Sơn", "Tỏi Phan Rang"]),
        .init(name: "Hành", asset: "FruitOnion",
              varieties: ["Hành Tím", "Hành Trắng"]),
        .init(name: "Súp Lơ", asset: "FruitBroccoli",
              varieties: ["Súp Lơ Xanh", "Súp Lơ Trắng"]),
        .init(name: "Rau Ăn Lá", asset: "FruitLeafyGreen",
              varieties: ["Cải Ngọt", "Cải Bó Xôi", "Xà Lách"]),
        .init(name: "Nấm", asset: "FruitMushroom",
              varieties: ["Nấm Rơm", "Nấm Bào Ngư", "Nấm Linh Chi"]),
        .init(name: "Hạt Dẻ", asset: "FruitChestnut",
              varieties: []),
        .init(name: "Lạc", asset: "FruitPeanut",
              varieties: ["Lạc Đỏ", "Lạc Sen"]),
        .init(name: "Lúa", asset: "FruitRice",
              varieties: ["Lúa Jasmine", "Lúa IR50404", "Lúa Nếp"]),
        .init(name: "Cà Phê", asset: "FruitCoffee",
              varieties: ["Cà Phê Robusta", "Cà Phê Arabica"]),
    ]

    /// Từ khóa (đã bỏ dấu, "đ" → "d") → tên asset icon.
    /// Dùng để khi gõ tên trái là tự chọn được biểu tượng phù hợp.
    private static let aliases: [String: String] = [
        // Trái cây
        "oi": "FruitGuava", "le": "FruitGuava",
        "xoai": "FruitMango", "du du": "FruitMango", "sap": "FruitMango",
        "buoi": "FruitPomelo", "quyt": "FruitPomelo", "cam": "FruitOrange",
        "cam sanh": "FruitOrange", "cam vinh": "FruitOrange",
        "chanh": "FruitLemon", "chanh day": "FruitLemon", "chanh dao": "FruitLemon",
        "thanh long": "FruitDragonFruit",
        "dua hau": "FruitWatermelon",
        "dua luoi": "FruitMelon", "dua gang": "FruitMelon",
        "tao": "FruitApple", "tao xanh": "FruitGreenApple",
        "chuoi": "FruitBanana",
        "dua": "FruitPineapple", "thom": "FruitPineapple", "khom": "FruitPineapple",
        "mit": "FruitPineapple", "sau rieng": "FruitPineapple", "mang cau": "FruitPineapple",
        "dao": "FruitPeach", "man": "FruitPeach", "mo": "FruitPeach", "khe": "FruitPeach",
        "anh dao": "FruitCherry", "so ri": "FruitCherry",
        "dau tay": "FruitStrawberry", "chom chom": "FruitStrawberry",
        "kiwi": "FruitKiwi",
        "dua xiem": "FruitCoconut", "dua kho": "FruitCoconut",
        "bo": "FruitAvocado",
        "nho": "FruitGrape", "nhan": "FruitGrape", "vai": "FruitGrape",
        "viet quat": "FruitBlueberry",
        "o liu": "FruitOlive", "oliu": "FruitOlive",
        "luu": "FruitApple", "hong": "FruitOrange",
        // Rau củ
        "ca chua": "FruitTomato",
        "ot": "FruitChili", "ot hiem": "FruitChili", "ot chi thien": "FruitChili",
        "ot chuong": "FruitBellPepper", "ot ngot": "FruitBellPepper",
        "dua leo": "FruitCucumber", "kho qua": "FruitCucumber", "muop dang": "FruitCucumber",
        "ca tim": "FruitEggplant",
        "bi do": "FruitPumpkin", "bi ngo": "FruitPumpkin", "bi": "FruitPumpkin",
        "ngo": "FruitCorn", "bap": "FruitCorn",
        "khoai tay": "FruitPotato", "khoai lang": "FruitSweetPotato", "khoai": "FruitPotato",
        "ca rot": "FruitCarrot",
        "toi": "FruitGarlic",
        "hanh": "FruitOnion", "hanh tim": "FruitOnion", "hanh la": "FruitHerb",
        "sup lo": "FruitBroccoli", "cai": "FruitBroccoli", "cai ngot": "FruitBroccoli",
        "cai bo xoi": "FruitLeafyGreen", "xa lach": "FruitLeafyGreen",
        "rau": "FruitLeafyGreen", "rau an la": "FruitLeafyGreen",
        "rau thom": "FruitHerb", "hung": "FruitHerb",
        "nam": "FruitMushroom",
        "hat de": "FruitChestnut",
        "lac": "FruitPeanut", "dau phong": "FruitPeanut", "dau": "FruitPeanut",
        "lua": "FruitRice", "lua mi": "FruitRice",
        "ca phe": "FruitCoffee", "coffee": "FruitCoffee",
    ]

    /// Suy ra tên asset icon trái cây từ tên loại cây (bỏ dấu, không phân biệt hoa thường).
    static func asset(for cropType: String) -> String {
        let key = normalize(cropType)
        guard !key.isEmpty else { return fallbackAsset }

        // 1) khớp đúng tên trong danh mục
        if let exact = items.first(where: { normalize($0.name) == key }) {
            return exact.asset
        }
        // 2) khớp đúng từ khóa
        if let aliased = aliases[key] {
            return aliased
        }
        // 3) khớp mềm: ưu tiên từ khóa dài nhất xuất hiện trong câu
        for (kw, asset) in aliases.sorted(by: { $0.key.count > $1.key.count }) where key.contains(kw) {
            return asset
        }
        return fallbackAsset
    }

    static func varieties(for cropType: String) -> [String] {
        let key = normalize(cropType)
        return items.first { normalize($0.name) == key }?.varieties ?? []
    }

    /// Các mục khớp với từ khóa đang gõ (rỗng ⇒ trả về toàn bộ danh mục).
    static func matches(_ query: String) -> [CropCatalogItem] {
        let key = normalize(query)
        guard !key.isEmpty else { return items }
        return items.filter { item in
            let n = normalize(item.name)
            if n.contains(key) { return true }
            return item.varieties.contains { normalize($0).contains(key) }
        }
    }

    private static func normalize(_ text: String) -> String {
        var s = text.folding(options: [.diacriticInsensitive, .caseInsensitive],
                             locale: Locale(identifier: "vi_VN"))
            .lowercased()
        s = s.replacingOccurrences(of: "đ", with: "d")
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
