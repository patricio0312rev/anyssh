import AnySSHCore
import Foundation

public enum OSC52Inbound: Sendable {
    public enum Outcome: Equatable, Sendable {
        case wrote(String)
        case query
        case refused(ClipboardRefusal)
        case ignored
    }

    public static func handle(
        sequence bytes: ArraySlice<UInt8>,
        pasteboard: any ClipboardPasteboard,
        maxDecodedBytes: Int = OSC52Limits.maxDecodedBytes
    ) -> Outcome {
        guard let parsed = OSC52Sequence.parse(bytes) else { return .ignored }
        return handle(
            payload: parsed.payload,
            pasteboard: pasteboard,
            maxDecodedBytes: maxDecodedBytes
        )
    }

    public static func handle(
        payload: ArraySlice<UInt8>,
        pasteboard: any ClipboardPasteboard,
        maxDecodedBytes: Int = OSC52Limits.maxDecodedBytes
    ) -> Outcome {
        if payload.count == 1, payload.first == UInt8(ascii: "?") {
            return .query
        }
        guard !payload.isEmpty else { return .ignored }

        let maxEncoded = ((maxDecodedBytes + 2) / 3) * 4 + 4
        if payload.count > maxEncoded {
            return .refused(.tooLarge)
        }

        let base64 = Data(payload)
        guard let decoded = Data(base64Encoded: base64, options: .ignoreUnknownCharacters) else {
            return .ignored
        }
        return accept(decoded: decoded, pasteboard: pasteboard, maxDecodedBytes: maxDecodedBytes)
    }

    public static func handle(
        decodedText text: String,
        pasteboard: any ClipboardPasteboard,
        maxDecodedBytes: Int = OSC52Limits.maxDecodedBytes
    ) -> Outcome {
        accept(
            decoded: Data(text.utf8),
            pasteboard: pasteboard,
            maxDecodedBytes: maxDecodedBytes
        )
    }

    private static func accept(
        decoded: Data,
        pasteboard: any ClipboardPasteboard,
        maxDecodedBytes: Int
    ) -> Outcome {
        if decoded.count > maxDecodedBytes {
            return .refused(.tooLarge)
        }
        let text = String(decoding: decoded, as: UTF8.self)
        pasteboard.write(text)
        return .wrote(text)
    }
}
