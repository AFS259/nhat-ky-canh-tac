import Foundation

/// Đồng bộ dữ liệu (khu vực → vụ → nhật ký, kèm ảnh minh chứng) lên Google Sheet
/// qua Apps Script Web App. Mỗi khu vực (Area) được ghi thành một sheet riêng.
enum GoogleSheetService {

    /// URL Web App của Google Apps Script (kết thúc bằng /exec).
    static let webAppURL = URL(string: "https://script.google.com/macros/s/AKfycbwiJc-NZ1NRL4sQh2VIG1wjbMECKYURVPJPPQgkacs1EQaXCWyApNj_k4CN4o747Qc4mQ/exec")!

    // MARK: - DTO

    private struct SyncRequest: Encodable {
        let action = "syncArea"
        let username: String
        let area: AreaPayload
    }

    private struct DeleteRequest: Encodable {
        let action = "deleteArea"
        let username: String
        let key: String
        let areaName: String
    }

    private struct AreaPayload: Encodable {
        let key: String
        let name: String
        let address: String
        let note: String
        let createdAt: String
        let crops: [CropPayload]
    }

    private struct CropPayload: Encodable {
        let cropType: String
        let variety: String
        let areaM2: String
        let seedCount: Int
        let sowDate: String
        let plantCount: Int
        let plantDate: String
        let logs: [LogPayload]
    }

    private struct LogPayload: Encodable {
        let plantDate: String
        let work: String
        let performDate: String
        let note: String
        let images: [String]
    }

    // MARK: - API

    /// Ghi (ghi đè) toàn bộ một khu vực lên sheet tương ứng.
    static func syncArea(_ area: Area, username: String) {
        post(SyncRequest(username: username, area: mapArea(area)))
    }

    /// Xoá sheet của khu vực khi khu vực bị xoá trong app.
    static func deleteArea(_ area: Area, username: String) {
        post(DeleteRequest(username: username, key: area.id.uuidString, areaName: area.name))
    }

    // MARK: - Mapping

    private static func mapArea(_ area: Area) -> AreaPayload {
        AreaPayload(
            key: area.id.uuidString,
            name: area.name,
            address: area.address,
            note: area.note,
            createdAt: Fmt.day.string(from: area.createdAt),
            crops: area.crops.map { crop in
                CropPayload(
                    cropType: crop.cropType,
                    variety: crop.variety,
                    areaM2: Fmt.number(crop.areaM2),
                    seedCount: crop.seedCount,
                    sowDate: Fmt.day.string(from: crop.sowDate),
                    plantCount: crop.plantCount,
                    plantDate: Fmt.day.string(from: crop.plantDate),
                    logs: crop.logs
                        .sorted { $0.performDate < $1.performDate }
                        .map { log in
                            LogPayload(
                                plantDate: Fmt.day.string(from: log.plantDate),
                                work: log.work.rawValue,
                                performDate: Fmt.day.string(from: log.performDate),
                                note: log.note,
                                images: log.images.compactMap {
                                    ImageStore.jpegData(for: $0).map { $0.base64EncodedString() }
                                }
                            )
                        }
                )
            }
        )
    }

    // MARK: - Networking

    private static func post<T: Encodable>(_ body: T) {
        guard let data = try? JSONEncoder().encode(body) else { return }
        var request = URLRequest(url: webAppURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.httpBody = data
        URLSession.shared.dataTask(with: request) { _, _, _ in }.resume()
    }
}
