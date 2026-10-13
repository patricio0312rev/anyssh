import Foundation

public enum ImagePasteDestination {
    public static let filePrefix = "paste-"
    public static let retentionDays = 6
    public static let directoryExpression = #""${XDG_CACHE_HOME:-$HOME/.cache}/anyssh/paste""#

    public static var prepareScript: String {
        "d=\(directoryExpression); umask 077; "
            + #"mkdir -p -- "$d" && chmod 700 "$d" && { "#
            + #"find "$d" -type f -name '\#(filePrefix)*' -mtime +\#(retentionDays) "#
            + #"-exec rm -f -- {} + 2>/dev/null; printf %s "$d"; }"#
    }

    public static func fileName(at date: Date, format: PastedImage.Format) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let parts = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second, .nanosecond],
            from: date
        )
        let stamp = String(
            format: "%04d%02d%02d-%02d%02d%02d-%03d",
            parts.year ?? 0,
            parts.month ?? 0,
            parts.day ?? 0,
            parts.hour ?? 0,
            parts.minute ?? 0,
            parts.second ?? 0,
            (parts.nanosecond ?? 0) / 1_000_000
        )
        return filePrefix + stamp + "." + format.fileExtension
    }
}
