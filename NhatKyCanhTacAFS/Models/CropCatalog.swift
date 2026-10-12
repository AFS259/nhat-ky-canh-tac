import Foundation

// MARK: - Danh mục cây trồng + icon trái cây (ảnh tải từ URL)
struct CropCatalogItem: Identifiable {
    let name: String
    let asset: String
    let varieties: [String]

    var id: String { name }
}

enum CropCatalog {

    static let items: [CropCatalogItem] = [
        .init(name: "Ổi", asset: "FruitGuava",
              varieties: ["Ổi Đài Loan", "Ổi Lê", "Ổi Nữ Hoàng"]),
        .init(name: "Xoài", asset: "FruitMango",
              varieties: ["Xoài Cát Chu", "Xoài Cát Hòa Lộc", "Xoài Đài Loan"]),
        .init(name: "Bưởi", asset: "FruitPomelo",
              varieties: ["Bưởi Da Xanh", "Bưởi Năm Roi", "Bưởi Tân Triều"]),
        .init(name: "Cam", asset: "FruitOrange",
              varieties: ["Cam Sành", "Cam Vinh", "Cam Xoàn"]),
        .init(name: "Chanh", asset: "FruitLemon",
              varieties: ["Chanh Dây", "Chanh Không Hạt", "Chanh Tứ Quý"]),
        .init(name: "Thanh Long", asset: "FruitDragonFruit",
              varieties: ["Thanh Long Ruột Đỏ", "Thanh Long Ruột Trắng"]),
        .init(name: "Dưa Hấu", asset: "FruitWatermelon",
              varieties: ["Dưa Hấu Black Lady", "Dưa Hấu Hắc Mỹ Nhân"]),
        .init(name: "Cà Chua", asset: "FruitTomato",
              varieties: ["Cà Chua Cherry", "Cà Chua Bi", "Cà Chua Beef"]),
        .init(name: "Ớt", asset: "FruitChili",
              varieties: ["Ớt Chỉ Thiên", "Ớt Hiểm", "Ớt Sừng"]),
        .init(name: "Nho", asset: "FruitGrape",
              varieties: ["Nho Ninh Thuận", "Nho Mẫu Đơn"]),
    ]

    static let fallbackAsset = "FruitSeedling"

    /// Suy ra tên asset icon trái cây từ tên loại cây (bỏ dấu, không phân biệt hoa thường).
    static func asset(for cropType: String) -> String {
        let key = normalize(cropType)
        guard !key.isEmpty else { return fallbackAsset }

        if let exact = items.first(where: { normalize($0.name) == key }) {
            return exact.asset
        }
        // so khớp mềm: "chanh dây" khớp "chanh", "xoài cát" khớp "xoài"...
        if let soft = items.first(where: {
            let n = normalize($0.name)
            return key.contains(n) || n.contains(key)
        }) {
            return soft.asset
        }
        // từ khóa phụ trợ
        let extra: [(String, String)] = [
            ("dua hau", "FruitWatermelon"),
            ("ca chua", "FruitTomato"),
            ("ot", "FruitChili"),
            ("nho", "FruitGrape"),
            ("thanh long", "FruitDragonFruit"),
        ]
        for (kw, asset) in extra where key.contains(kw) {
            return asset
        }
        return fallbackAsset
    }

    static func varieties(for cropType: String) -> [String] {
        let key = normalize(cropType)
        return items.first { normalize($0.name) == key }?.varieties ?? []
    }

    private static func normalize(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive],
                     locale: Locale(identifier: "vi_VN"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
