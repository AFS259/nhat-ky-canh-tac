import UIKit

enum ImageStore {

    static var directory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Images", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func url(for name: String) -> URL {
        directory.appendingPathComponent(name)
    }

    @discardableResult
    static func save(_ image: UIImage, quality: CGFloat = 0.85) -> String? {
        guard let data = image.jpegData(compressionQuality: quality) else { return nil }
        let name = "\(UUID().uuidString).jpg"
        do {
            try data.write(to: url(for: name), options: .atomic)
            return name
        } catch {
            return nil
        }
    }

    static func load(_ name: String) -> UIImage? {
        guard let data = try? Data(contentsOf: url(for: name)) else { return nil }
        return UIImage(data: data)
    }

    /// Đọc ảnh, co nhỏ về maxDimension (px, cạnh dài nhất) rồi nén JPEG để gửi lên Sheet.
    static func jpegData(for name: String, maxDimension: CGFloat = 480, quality: CGFloat = 0.6) -> Data? {
        guard let image = load(name) else { return nil }
        let longSide = max(image.size.width, image.size.height)
        guard longSide > 0 else { return nil }
        let scale = min(1, maxDimension / longSide)
        let newSize = CGSize(width: (image.size.width * scale).rounded(), height: (image.size.height * scale).rounded())
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resized?.jpegData(compressionQuality: quality)
    }

    static func delete(_ name: String) {
        try? FileManager.default.removeItem(at: url(for: name))
    }
}
