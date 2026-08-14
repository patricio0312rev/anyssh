import AnySSHCore
import Foundation

enum MuxCommandSupport {
    static func section(
        label: String,
        in response: BatchResponse,
        batch: RemoteBatch
    ) throws -> CommandSection {
        guard let section = response.sections.first(where: { $0.label == label }) else {
            throw ErrorState.command(.responseUnreadable)
        }
        if let failure = section.failure(program: program(for: label, in: batch)) {
            throw mapFailure(failure)
        }
        return section
    }

    static func text(_ section: CommandSection) -> String {
        String(decoding: section.bytes, as: UTF8.self)
    }

    private static func program(for label: String, in batch: RemoteBatch) -> String {
        batch.commands.first(where: { $0.label == label })?.program ?? ""
    }

    private static func mapFailure(_ failure: CommandFailure) -> Error {
        switch failure {
        case .programMissing:
            ErrorState.mux(.absent)
        case .signalled:
            ErrorState.command(.signalled)
        case .exited:
            ErrorState.command(.failed)
        }
    }
}
