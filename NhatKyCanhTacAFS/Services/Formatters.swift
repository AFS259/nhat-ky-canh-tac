import Foundation

enum Fmt {
    static let day: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yyyy"
        f.locale = Locale(identifier: "vi_VN")
        return f
    }()

    static let dayTime: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yyyy HH:mm"
        f.locale = Locale(identifier: "vi_VN")
        return f
    }()

    static func number(_ value: Double) -> String {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "vi_VN")
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
