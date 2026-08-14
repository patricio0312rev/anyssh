import AnySSHCore
import CSSH
import Darwin
import Foundation

final class KeyboardInteractiveExchange: @unchecked Sendable {
    let channel: PromptChannel

    private let session: OpaquePointer
    private let username: String

    init(session: OpaquePointer, username: String, roundBudget: Duration) {
        self.session = session
        self.username = username
        channel = PromptChannel(roundBudget: roundBudget)
    }

    func start() {
        let thread = Thread { [self] in
            let length = UInt32(username.utf8.count)
            let code = username.withCString {
                libssh2_userauth_keyboard_interactive_ex(session, $0, length, Self.respond)
            }
            channel.complete(code)
        }
        thread.name = "anyssh.keyboard-interactive"
        thread.stackSize = 512 * 1024
        thread.start()
    }

    private static let respond:
        @convention(c) (
            UnsafePointer<CChar>?, Int32, UnsafePointer<CChar>?, Int32, Int32,
            UnsafePointer<LIBSSH2_USERAUTH_KBDINT_PROMPT>?,
            UnsafeMutablePointer<LIBSSH2_USERAUTH_KBDINT_RESPONSE>?,
            UnsafeMutablePointer<UnsafeMutableRawPointer?>?
        ) -> Void = {
            name, nameLength, instruction, instructionLength, count, prompts, responses, abstract in
            guard let context = abstract?.pointee else { return }
            let exchange = Unmanaged<KeyboardInteractiveExchange>
                .fromOpaque(context)
                .takeUnretainedValue()

            let round = AuthPromptRound(
                method: .keyboardInteractive,
                name: text(name, nameLength),
                instruction: text(instruction, instructionLength),
                prompts: (0..<Int(max(0, count))).compactMap { index in
                    guard let prompt = prompts?[index] else { return nil }
                    return AuthPrompt(
                        text: text(prompt.text, prompt.length),
                        isEchoed: prompt.echo != 0
                    )
                }
            )

            let answers = exchange.channel.present(round)
            for (index, answer) in answers.enumerated() where index < Int(count) {
                var bytes = Array(answer.utf8)
                guard let buffer = malloc(bytes.count + 1) else { continue }
                buffer.copyMemory(from: &bytes, byteCount: bytes.count)
                buffer.storeBytes(of: 0, toByteOffset: bytes.count, as: UInt8.self)
                responses?[index].text = buffer.assumingMemoryBound(to: CChar.self)
                responses?[index].length = UInt32(bytes.count)
            }
        }

    private static func text(_ pointer: UnsafePointer<CChar>?, _ length: Int32) -> String {
        guard let pointer, length > 0 else { return "" }
        return pointer.withMemoryRebound(to: UInt8.self, capacity: Int(length)) {
            String(decoding: UnsafeBufferPointer(start: $0, count: Int(length)), as: UTF8.self)
        }
    }

    private static func text(_ pointer: UnsafeMutablePointer<UInt8>?, _ length: Int) -> String {
        guard let pointer, length > 0 else { return "" }
        return String(decoding: UnsafeBufferPointer(start: pointer, count: length), as: UTF8.self)
    }
}
