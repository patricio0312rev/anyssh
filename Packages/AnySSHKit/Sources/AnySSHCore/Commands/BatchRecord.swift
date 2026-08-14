enum BatchRecord: Hashable {
    case section(index: Int, length: Int, exitCode: Int32)
    case end(count: Int)

    static let headerLimit = 40

    static let sectionFormat = #"\n--%s--R%s:%s:%s\n"#

    static let endFormat = #"\n--%s--Z%s\n"#

    init?(header: String) {
        let fields = header.dropFirst().split(separator: ":", omittingEmptySubsequences: false)
        switch (header.first, fields.count) {
        case ("R", 3):
            guard let index = Self.number(fields[0], digits: 9),
                let length = Self.number(fields[1], digits: 12),
                let exitCode = Self.number(fields[2], digits: 3), exitCode <= 255
            else { return nil }
            self = .section(index: index, length: length, exitCode: Int32(exitCode))
        case ("Z", 1):
            guard let count = Self.number(fields[0], digits: 9) else { return nil }
            self = .end(count: count)
        default:
            return nil
        }
    }

    private static func number(_ field: Substring, digits: Int) -> Int? {
        guard (1...digits).contains(field.count) else { return nil }
        guard field.allSatisfy({ $0.isASCII && $0.isNumber }) else { return nil }
        return Int(field)
    }
}
