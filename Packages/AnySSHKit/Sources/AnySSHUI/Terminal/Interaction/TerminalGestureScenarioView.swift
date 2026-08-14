#if canImport(UIKit)
import SwiftUI
import TerminalEmulator
import UIKit

public struct TerminalGestureScenarioView: View {
    public init() {}

    public var body: some View {
        TerminalGestureScenarioRepresentable()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.surface.base)
    }
}

@MainActor
final class TerminalGestureScenarioController: UIViewController {
    private let canvas = TerminalGestureCanvasView()
    private var coordinator: TerminalInteractionCoordinator?
    private let switcher = UILabel()
    private var mouseLog: [UInt8] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Platform.surfaceBase
        layoutCanvas()
        layoutSwitcher()
        installCoordinator()
    }

    private func layoutCanvas() {
        canvas.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(canvas)
        NSLayoutConstraint.activate([
            canvas.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            canvas.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            canvas.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            canvas.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
        canvas.accessibilityIdentifier = UIIdentifier.Terminal.canvas
        canvas.isAccessibilityElement = true
        canvas.contentSize = CGSize(width: 400, height: 2400)
    }

    private func layoutSwitcher() {
        switcher.translatesAutoresizingMaskIntoConstraints = false
        switcher.isHidden = true
        switcher.text = "Sessions"
        switcher.textColor = Theme.Platform.textPrimary
        switcher.backgroundColor = Theme.Platform.surfaceRaised
        switcher.textAlignment = .center
        view.addSubview(switcher)
        NSLayoutConstraint.activate([
            switcher.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            switcher.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            switcher.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            switcher.heightAnchor.constraint(equalToConstant: 120),
        ])
    }

    private func installCoordinator() {
        let coordinator = TerminalInteractionCoordinator(
            scrollView: canvas,
            modeProvider: { [weak self] shiftHeld in
                TerminalGestureMode(
                    alternateScreen: self?.canvas.alternateScreen ?? false,
                    mouseReporting: self?.canvas.mouseReporting ?? false,
                    touchMode: self?.canvas.touchMode ?? false,
                    shiftHeld: shiftHeld
                )
            },
            selectionState: { [weak self] in self?.canvas.hasSelection ?? false },
            textProvider: { [weak self] in self?.canvas.selectedText ?? "" },
            selectionGeometry: { [weak self] in
                guard let self else { return (0, 0, .zero) }
                return (
                    self.canvas.selectionEnd.column,
                    self.canvas.selectionEnd.row,
                    self.canvas.selectionRect
                )
            },
            beginSelection: { [weak self] point in self?.canvas.beginSelection(at: point) },
            extendSelection: { [weak self] point in self?.canvas.extendSelection(to: point) },
            sessionSwitchHandler: { [weak self] in self?.openSwitcher() },
            mouseReportHandler: { [weak self] report in
                self?.mouseLog += report.sgrBytes
                self?.canvas.mouseBytes = self?.mouseLog ?? []
            },
            copyHandler: { text in SystemClipboardPasteboard().write(text) }
        )
        coordinator.install()
        self.coordinator = coordinator
    }

    private func openSwitcher() {
        switcher.isHidden = false
    }
}

struct TerminalGestureScenarioRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> TerminalGestureScenarioController {
        TerminalGestureScenarioController()
    }

    func updateUIViewController(_ controller: TerminalGestureScenarioController, context: Context) {}
}
#endif
