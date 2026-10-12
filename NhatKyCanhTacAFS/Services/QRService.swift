import Foundation
import CryptoKit
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

struct QRRow: Codable, Hashable, Identifiable {
    var id: String { plantDate + work + performDate + note }
    let plantDate: String
    let work: String
    let performDate: String
    let note: String
}

struct QRPayload: Codable {
    let areaName: String
    let crop: String
    let issuedAt: Date
    let expiresAt: Date
    let rows: [QRRow]
}

enum QRService {

    /// Khóa bí mật dùng để mã hóa QR thành key (đổi khi phát hành chính thức).
    private static let secret = "AFS-AUTO-FUSION-SYSTEM-2026-SECRET"
    private static let prefix = "AFS1:"
    static let validDays = 10

    private static var symmetricKey: SymmetricKey {
        let digest = SHA256.hash(data: Data(secret.utf8))
        return SymmetricKey(data: Data(digest))
    }

    private static let df: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yyyy"
        f.locale = Locale(identifier: "vi_VN")
        return f
    }()

    // MARK: - Mã hóa
    static func makeToken(areaName: String, crop: Crop) throws -> (token: String, payload: QRPayload) {
        let now = Date()
        let payload = QRPayload(
            areaName: areaName,
            crop: crop.title,
            issuedAt: now,
            expiresAt: Calendar.current.date(byAdding: .day, value: validDays, to: now) ?? now,
            rows: crop.logs
                .sorted { $0.performDate < $1.performDate }
                .map { QRRow(plantDate: df.string(from: $0.plantDate),
                             work: $0.work.rawValue,
                             performDate: df.string(from: $0.performDate),
                             note: $0.note) }
        )
        let data = try JSONEncoder().encode(payload)
        let sealed = try AES.GCM.seal(data, using: symmetricKey)
        guard let combined = sealed.combined else { throw QRServiceError.encryptFailed }
        return (prefix + combined.base64EncodedString(), payload)
    }

    // MARK: - Giải mã (kiểm tra hạn 10 ngày)
    static func decode(token: String) -> Result<QRPayload, QRServiceError> {
        guard token.hasPrefix(prefix) else { return .failure(.invalidFormat) }
        let base64 = String(token.dropFirst(prefix.count))
        guard let data = Data(base64Encoded: base64) else { return .failure(.invalidFormat) }
        do {
            let box = try AES.GCM.SealedBox(combined: data)
            let opened = try AES.GCM.open(box, using: symmetricKey)
            let payload = try JSONDecoder().decode(QRPayload.self, from: opened)
            if Date() > payload.expiresAt { return .failure(.expired(payload.expiresAt)) }
            return .success(payload)
        } catch {
            return .failure(.decryptFailed)
        }
    }

    // MARK: - Sinh ảnh QR
    static func image(from string: String, size: CGFloat = 260) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scale = size / output.extent.width
        let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let context = CIContext()
        guard let cg = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cg)
    }

    static func format(_ date: Date) -> String { df.string(from: date) }
}

enum QRServiceError: Error, LocalizedError {
    case encryptFailed
    case invalidFormat
    case decryptFailed
    case expired(Date)

    var errorDescription: String? {
        switch self {
        case .encryptFailed: return "Không tạo được mã QR."
        case .invalidFormat: return "Mã QR không đúng định dạng AFS."
        case .decryptFailed: return "Mã QR không hợp lệ hoặc đã bị chỉnh sửa."
        case .expired(let date): return "Mã QR đã hết hạn từ \(QRService.format(date)). Hạn dùng tối đa 10 ngày."
        }
    }
}
