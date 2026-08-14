import Foundation
import Testing

@Suite struct UsageDescriptionTests {
    private struct Requirement {
        let key: String
        let framework: String
        let evidence: [String]
    }

    private static let requirements = [
        Requirement(
            key: "NSFaceIDUsageDescription",
            framework: "LocalAuthentication",
            evidence: ["LAContext", "evaluateAccessControl", "biometryCurrentSet"]
        ),
        Requirement(
            key: "NSMicrophoneUsageDescription",
            framework: "AVFoundation",
            evidence: ["AVAudioEngine", "AVAudioSession"]
        ),
        Requirement(
            key: "NSSpeechRecognitionUsageDescription",
            framework: "Speech",
            evidence: ["SFSpeechRecognizer"]
        ),
    ]

    @Test func everyProtectedResourceTheAppReachesIsDeclared() throws {
        let plist = try infoPlist()
        let sources = try sourceText()

        for requirement in Self.requirements {
            let used = requirement.evidence.contains { sources.contains($0) }
            guard used else { continue }
            let message =
                "\(requirement.framework) is used but Config/Info.plist has no "
                + "\(requirement.key). The system terminates the app the first time that API "
                + "is reached."
            #expect(plist.contains(requirement.key), Comment(rawValue: message))
        }
    }

    @Test func everyDescriptionSaysWhatItIsFor() throws {
        let plist = try infoPlist()

        for requirement in Self.requirements {
            guard let value = value(of: requirement.key, in: plist) else { continue }
            #expect(value.split(separator: " ").count >= 6, "\(requirement.key) is too terse")
        }
    }

    private func value(of key: String, in plist: String) -> String? {
        guard let keyRange = plist.range(of: "<key>\(key)</key>"),
            let open = plist.range(of: "<string>", range: keyRange.upperBound..<plist.endIndex),
            let close = plist.range(of: "</string>", range: open.upperBound..<plist.endIndex)
        else { return nil }
        return String(plist[open.upperBound..<close.lowerBound])
    }

    private func repositoryRoot() -> URL {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { url.deleteLastPathComponent() }
        return url
    }

    private func infoPlist() throws -> String {
        try String(contentsOf: repositoryRoot().appending(path: "Config/Info.plist"), encoding: .utf8)
    }

    private func sourceText() throws -> String {
        let root = repositoryRoot()
        var combined = ""
        for directory in ["AnySSH", "Packages/AnySSHKit/Sources"] {
            let base = root.appending(path: directory)
            guard let files = FileManager.default.enumerator(atPath: base.path) else { continue }
            for case let name as String in files where name.hasSuffix(".swift") {
                guard !name.contains("AnySSHMocks") else { continue }
                combined += (try? String(contentsOf: base.appending(path: name), encoding: .utf8)) ?? ""
            }
        }
        return combined
    }
}
