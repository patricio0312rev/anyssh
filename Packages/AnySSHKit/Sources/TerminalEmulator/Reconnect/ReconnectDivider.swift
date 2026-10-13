import Foundation

public enum ReconnectDivider {
    public static func bytes(at date: Date) -> [UInt8] {
        Array("\r\n\(dim)\(label(at: date))\(plain)\r\n".utf8)
    }

    public static func label(at date: Date) -> String {
        "-- reconnected \(date.formatted(date: .omitted, time: .shortened)) --"
    }

    private static let dim = "\u{1B}[2m"
    private static let plain = "\u{1B}[0m"
}
