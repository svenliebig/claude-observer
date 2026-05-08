import Cocoa

// MARK: - Constants

let kStateDir = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".claude-observer/sessions")

let kCrabNames = [
    "Pinchy", "Snippy", "Clawdia", "Scuttles", "Sheldon",
    "Bubbles", "Sandy", "Hermie", "Captain Claw", "Rusty",
    "Coral", "Neptune", "Barnacle", "Tidbit", "Shelly",
    "Crusty", "Wobbles", "Chomper", "Skipper", "Pebbles",
    "Biscuit", "Snapper", "Gizmo", "Pepper", "Ziggy",
    "Pickle", "Noodle", "Sprocket", "Tango", "Mango",
    "Fiddler", "Coconut", "Cheddar", "Waffles", "Bongo"
]

private func abbreviatePath(_ path: String) -> String {
    let home = FileManager.default.homeDirectoryForCurrentUser.path
    if path.hasPrefix(home) {
        return "~" + path.dropFirst(home.count)
    }
    return path
}

// MARK: - Session Model

struct CrabSession: Codable {
    let id: String
    let name: String
    var cwd: String
    var status: String
    var pid: Int?
    let startedAt: String
    var lastActivity: String
    var notificationType: String?
    var tmuxPane: String?

    enum CodingKeys: String, CodingKey {
        case id, name, cwd, status, pid
        case startedAt = "started_at"
        case lastActivity = "last_activity"
        case notificationType = "notification_type"
        case tmuxPane = "tmux_pane"
    }
}

// MARK: - Crab Renderer

enum CrabState {
    case working, idle, needsInput, error, none
}

class CrabRenderer {

    static func createImage(size: CGFloat = 18, frame: Int = 0, state: CrabState = .working) -> NSImage {
        let img = NSImage(size: NSSize(width: size, height: size))
        img.lockFocus()
        if let ctx = NSGraphicsContext.current?.cgContext {
            drawCrab(ctx: ctx, w: size, h: size, frame: frame, state: state)
        }
        img.unlockFocus()
        return img
    }

    private static func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
        NSColor(red: r, green: g, blue: b, alpha: a).cgColor
    }

    private static func drawCrab(ctx: CGContext, w: CGFloat, h: CGFloat, frame: Int, state: CrabState) {
        // For idle/none, draw a faded crab lower in the image (no bounce)
        // For needsInput, draw shifted left to make room for badge
        let crabScale: CGFloat = (state == .needsInput || state == .error) ? 0.78 : 1.0
        let crabOffX: CGFloat = (state == .needsInput || state == .error) ? -w * 0.08 : 0
        let crabOffY: CGFloat = 0.0
        let alphaMultiplier: CGFloat = (state == .idle || state == .none) ? 0.4 : 1.0

        let body: CGColor
        let shell: CGColor

        switch state {
        case .working:
            body = color(1.0, 0.45, 0.15)
            shell = color(0.9, 0.35, 0.1)
        case .idle:
            body = color(0.52, 0.52, 0.58, 0.4)
            shell = color(0.42, 0.42, 0.48, 0.4)
        case .needsInput:
            body = color(1.0, 0.3, 0.2)
            shell = color(0.9, 0.2, 0.12)
        case .error:
            body = color(0.85, 0.15, 0.45)
            shell = color(0.7, 0.1, 0.35)
        case .none:
            body = color(0.52, 0.52, 0.58, 0.25)
            shell = color(0.42, 0.42, 0.48, 0.25)
        }

        _ = alphaMultiplier

        // Animation
        let bounce: CGFloat = (state == .needsInput && frame % 2 == 1) ? 1.5 : 0
        let legWiggle: CGFloat = (state == .working) ? ((frame % 2 == 0) ? 1.0 : -1.0) : 0
        let clawWave: CGFloat = (state == .working) ? ((frame % 2 == 0) ? 0.0 : 1.2) : 0

        // Apply scaling transform for needsInput (make crab smaller to fit badge)
        ctx.saveGState()
        if crabScale < 1.0 {
            ctx.translateBy(x: w * (1 - crabScale) / 2 + crabOffX, y: crabOffY)
            ctx.scaleBy(x: crabScale, y: crabScale)
        }

        // --- Legs (3 pairs, behind body) ---
        ctx.setStrokeColor(body)
        ctx.setLineWidth(max(1, w * 0.055))
        ctx.setLineCap(.round)

        for i in 0..<3 {
            let fi = CGFloat(i)
            let legY = h * 0.22 + fi * h * 0.065 + bounce
            let spread = w * (0.04 + fi * 0.025)
            let wig = (i % 2 == 0) ? legWiggle : -legWiggle

            ctx.move(to: CGPoint(x: w * 0.27, y: legY))
            ctx.addLine(to: CGPoint(x: w * 0.08 - spread + wig, y: legY - h * 0.07))
            ctx.move(to: CGPoint(x: w * 0.73, y: legY))
            ctx.addLine(to: CGPoint(x: w * 0.92 + spread - wig, y: legY - h * 0.07))
        }
        ctx.strokePath()

        // --- Claws ---
        ctx.setFillColor(body)

        let lcx = w * 0.1
        let lcy = h * 0.48 + bounce + clawWave
        let lcp = CGMutablePath()
        lcp.move(to: CGPoint(x: w * 0.24, y: h * 0.43 + bounce))
        lcp.addLine(to: CGPoint(x: lcx, y: lcy + h * 0.06))
        lcp.addLine(to: CGPoint(x: lcx - w * 0.06, y: lcy - h * 0.01))
        lcp.addLine(to: CGPoint(x: lcx - w * 0.01, y: lcy - h * 0.05))
        lcp.addLine(to: CGPoint(x: w * 0.22, y: h * 0.38 + bounce))
        lcp.closeSubpath()
        ctx.addPath(lcp)
        ctx.fillPath()

        let rcx = w * 0.9
        let rcy = h * 0.48 + bounce + clawWave
        let rcp = CGMutablePath()
        rcp.move(to: CGPoint(x: w * 0.76, y: h * 0.43 + bounce))
        rcp.addLine(to: CGPoint(x: rcx, y: rcy + h * 0.06))
        rcp.addLine(to: CGPoint(x: rcx + w * 0.06, y: rcy - h * 0.01))
        rcp.addLine(to: CGPoint(x: rcx + w * 0.01, y: rcy - h * 0.05))
        rcp.addLine(to: CGPoint(x: w * 0.78, y: h * 0.38 + bounce))
        rcp.closeSubpath()
        ctx.addPath(rcp)
        ctx.fillPath()

        // --- Body (main oval) ---
        ctx.setFillColor(body)
        let bw = w * 0.52
        let bh = h * 0.32
        let bx = (w - bw) / 2
        let by = h * 0.24 + bounce
        ctx.fillEllipse(in: CGRect(x: bx, y: by, width: bw, height: bh))

        ctx.setFillColor(shell)
        let sw2 = bw * 0.68
        let sh2 = bh * 0.55
        ctx.fillEllipse(in: CGRect(x: (w - sw2) / 2, y: by + bh * 0.18, width: sw2, height: sh2))

        // --- Eye stalks ---
        ctx.setStrokeColor(body)
        ctx.setLineWidth(max(1, w * 0.065))
        ctx.setLineCap(.round)

        let eyeLX = w * 0.34
        let eyeRX = w * 0.66
        let stalkBase = h * 0.55 + bounce
        let stalkTop = h * 0.72 + bounce

        ctx.move(to: CGPoint(x: eyeLX, y: stalkBase))
        ctx.addLine(to: CGPoint(x: eyeLX - w * 0.03, y: stalkTop))
        ctx.move(to: CGPoint(x: eyeRX, y: stalkBase))
        ctx.addLine(to: CGPoint(x: eyeRX + w * 0.03, y: stalkTop))
        ctx.strokePath()

        // --- Eyes ---
        let er = max(1.8, w * 0.09)
        let elx = eyeLX - w * 0.03
        let erx = eyeRX + w * 0.03

        if state == .idle || state == .none {
            // Closed eyes (half circles / lines)
            ctx.setStrokeColor(color(0.35, 0.35, 0.4, 0.6))
            ctx.setLineWidth(max(1, w * 0.05))
            ctx.addArc(center: CGPoint(x: elx, y: stalkTop), radius: er * 0.7,
                       startAngle: 0, endAngle: .pi, clockwise: false)
            ctx.strokePath()
            ctx.addArc(center: CGPoint(x: erx, y: stalkTop), radius: er * 0.7,
                       startAngle: 0, endAngle: .pi, clockwise: false)
            ctx.strokePath()
        } else {
            ctx.setFillColor(CGColor.white)
            ctx.fillEllipse(in: CGRect(x: elx - er, y: stalkTop - er, width: er * 2, height: er * 2))
            ctx.fillEllipse(in: CGRect(x: erx - er, y: stalkTop - er, width: er * 2, height: er * 2))

            let pr = er * 0.45
            let plook: CGFloat = (frame % 4 < 2) ? 0.3 : -0.3
            ctx.setFillColor(color(0.12, 0.08, 0.08))
            ctx.fillEllipse(in: CGRect(x: elx - pr + plook, y: stalkTop - pr, width: pr * 2, height: pr * 2))
            ctx.fillEllipse(in: CGRect(x: erx - pr + plook, y: stalkTop - pr, width: pr * 2, height: pr * 2))
        }

        // --- Mouth ---
        let mouthY = h * 0.33 + bounce
        if state == .needsInput || state == .error {
            // Open mouth (worried)
            ctx.setFillColor(color(0.3, 0.05, 0.05, 0.8))
            ctx.fillEllipse(in: CGRect(x: w * 0.45, y: mouthY - w * 0.035, width: w * 0.1, height: w * 0.07))
        } else if state == .idle || state == .none {
            // No mouth (sleeping)
            () // intentionally blank
        } else {
            ctx.setStrokeColor(shell)
            ctx.setLineWidth(max(0.5, w * 0.028))
            ctx.setLineCap(.round)
            ctx.addArc(
                center: CGPoint(x: w * 0.5, y: mouthY),
                radius: w * 0.055,
                startAngle: .pi * 1.15,
                endAngle: .pi * 1.85,
                clockwise: false
            )
            ctx.strokePath()
        }

        ctx.restoreGState()

        // --- Overlays (drawn AFTER restoring transform, in full image coords) ---

        // Working: animated activity sparkles
        if state == .working {
            let sparkleColor = color(1.0, 0.85, 0.3, 0.9)
            ctx.setFillColor(sparkleColor)
            let sparkleR: CGFloat = max(1, w * 0.04)
            let positions: [(CGFloat, CGFloat)] = [
                (0.82, 0.78), (0.88, 0.62), (0.78, 0.9)
            ]
            let activeIdx = frame % 3
            for (i, pos) in positions.enumerated() {
                let alpha: CGFloat = (i == activeIdx) ? 1.0 : 0.3
                ctx.setFillColor(color(1.0, 0.85, 0.3, alpha))
                ctx.fillEllipse(in: CGRect(
                    x: w * pos.0 - sparkleR, y: h * pos.1 - sparkleR,
                    width: sparkleR * 2, height: sparkleR * 2
                ))
            }
        }

        // Idle: "Zzz" text
        if state == .idle || state == .none {
            let zAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: max(6, w * 0.35), weight: .heavy),
                .foregroundColor: NSColor(red: 0.35, green: 0.35, blue: 0.7, alpha: 0.85)
            ]
            let z1 = NSAttributedString(string: "z", attributes: zAttrs)
            z1.draw(at: NSPoint(x: w * 0.65, y: h * 0.55))
            let z2Attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: max(4, w * 0.25), weight: .bold),
                .foregroundColor: NSColor(red: 0.35, green: 0.35, blue: 0.7, alpha: 0.6)
            ]
            let z2 = NSAttributedString(string: "z", attributes: z2Attrs)
            z2.draw(at: NSPoint(x: w * 0.78, y: h * 0.72))
        }

        // Needs input / error: red notification badge with "!"
        if state == .needsInput || state == .error {
            let badgeR = w * 0.22
            let badgeCX = w * 0.82
            let badgeCY = h * 0.78

            // Badge shadow
            ctx.setFillColor(color(0, 0, 0, 0.2))
            ctx.fillEllipse(in: CGRect(
                x: badgeCX - badgeR + 0.5, y: badgeCY - badgeR - 0.5,
                width: badgeR * 2, height: badgeR * 2
            ))

            // Badge circle
            let badgeFill = (state == .error) ? color(0.9, 0.15, 0.5) : color(1.0, 0.15, 0.15)
            ctx.setFillColor(badgeFill)
            ctx.fillEllipse(in: CGRect(
                x: badgeCX - badgeR, y: badgeCY - badgeR,
                width: badgeR * 2, height: badgeR * 2
            ))

            // White border
            ctx.setStrokeColor(CGColor.white)
            ctx.setLineWidth(max(0.8, w * 0.03))
            ctx.strokeEllipse(in: CGRect(
                x: badgeCX - badgeR, y: badgeCY - badgeR,
                width: badgeR * 2, height: badgeR * 2
            ))

            // "!" text in badge
            let bangAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: max(7, badgeR * 1.5), weight: .heavy),
                .foregroundColor: NSColor.white
            ]
            let bang = NSAttributedString(string: "!", attributes: bangAttrs)
            let bangSize = bang.size()
            bang.draw(at: NSPoint(
                x: badgeCX - bangSize.width / 2,
                y: badgeCY - bangSize.height / 2
            ))
        }
    }
}

// MARK: - App Delegate

class ClaudeObserverDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private var sessions: [String: CrabSession] = [:]
    private var notifiedSessions: Set<String> = []
    private var animFrame = 0
    private var animTimer: Timer?
    private var pollTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Prevent duplicate instances
        if isDuplicate() {
            print("Claude Observer is already running.")
            NSApp.terminate(nil)
            return
        }

        // Ensure state directory
        try? FileManager.default.createDirectory(at: kStateDir, withIntermediateDirectories: true)

        // Status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.imagePosition = .imageLeft

        menu = NSMenu()
        statusItem.menu = menu

        // Initial load
        pollSessions()

        // Poll every 2s for session changes
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.pollSessions()
        }

        // Animation at 2fps
        animTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.animFrame += 1
            self.updateDisplay()
        }

        updateDisplay()
    }

    private func isDuplicate() -> Bool {
        let myPid = ProcessInfo.processInfo.processIdentifier
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        task.arguments = ["-x", "claude-observer"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice
        do {
            try task.run()
            task.waitUntilExit()
        } catch { return false }

        let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let pids = out.split(separator: "\n").compactMap { Int32($0) }
        return pids.contains(where: { $0 != myPid })
    }

    // MARK: - Session Polling

    private func pollSessions() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: kStateDir, includingPropertiesForKeys: nil) else { return }

        var updated: [String: CrabSession] = [:]
        let decoder = JSONDecoder()

        for file in files where file.pathExtension == "json" {
            guard let data = try? Data(contentsOf: file),
                  let session = try? decoder.decode(CrabSession.self, from: data) else { continue }

            // Stale session cleanup: PID dead + old
            if let pid = session.pid, kill(Int32(pid), 0) != 0 && errno == ESRCH {
                let fmt = ISO8601DateFormatter()
                if let lastDate = fmt.date(from: session.lastActivity),
                   Date().timeIntervalSince(lastDate) > 300 {
                    try? fm.removeItem(at: file)
                    continue
                }
            }

            updated[session.id] = session
        }

        // Notifications for new needs_input sessions
        for (id, session) in updated {
            let needsAttention = session.status == "needs_input" || session.status == "needs_permission"
            if needsAttention && !notifiedSessions.contains(id) {
                sendNotification(session: session)
                notifiedSessions.insert(id)
            }
            if session.status == "working" {
                notifiedSessions.remove(id)
            }
        }

        notifiedSessions = notifiedSessions.intersection(Set(updated.keys))
        sessions = updated
        updateDisplay()
    }

    // MARK: - Display

    private func updateDisplay() {
        let count = sessions.count
        let needsInput = sessions.values.contains { $0.status == "needs_input" || $0.status == "needs_permission" }
        let hasWorking = sessions.values.contains { $0.status == "working" }
        let hasError = sessions.values.contains { $0.status == "error" }

        let state: CrabState
        if hasError { state = .error }
        else if needsInput { state = .needsInput }
        else if hasWorking { state = .working }
        else if count > 0 { state = .idle }
        else { state = .none }

        statusItem.button?.image = CrabRenderer.createImage(size: 18, frame: animFrame, state: state)
        statusItem.button?.title = count > 0 ? " \(count)" : ""

        rebuildMenu()
    }

    private func rebuildMenu() {
        menu.removeAllItems()

        let title = NSMenuItem(title: "Claude Observer", action: nil, keyEquivalent: "")
        title.isEnabled = false
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .semibold)
        ]
        title.attributedTitle = NSAttributedString(string: "Claude Observer", attributes: titleAttrs)
        menu.addItem(title)
        menu.addItem(.separator())

        if sessions.isEmpty {
            let empty = NSMenuItem(title: "No active Claude sessions", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
        } else {
            let sorted = sessions.values.sorted { $0.startedAt < $1.startedAt }
            for session in sorted {
                addSessionItems(session)
            }
        }

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Claude Observer", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    private func addSessionItems(_ session: CrabSession) {
        let dot: String
        let label: String
        let dotColor: NSColor
        let labelColor: NSColor
        let labelWeight: NSFont.Weight

        // High-contrast explicit colors that work on translucent menu backgrounds
        switch session.status {
        case "working":
            dot = "\u{25CF}"; label = "WORKING"
            dotColor = NSColor(red: 0.1, green: 0.6, blue: 0.2, alpha: 1)
            labelColor = NSColor(red: 0.1, green: 0.55, blue: 0.15, alpha: 1)
            labelWeight = .bold
        case "needs_input":
            dot = "\u{25CF}"; label = "WAITING FOR INPUT"
            dotColor = NSColor(red: 0.85, green: 0.1, blue: 0.1, alpha: 1)
            labelColor = NSColor(red: 0.8, green: 0.05, blue: 0.05, alpha: 1)
            labelWeight = .heavy
        case "needs_permission":
            dot = "\u{25CF}"; label = "NEEDS PERMISSION"
            dotColor = NSColor(red: 0.85, green: 0.45, blue: 0.0, alpha: 1)
            labelColor = NSColor(red: 0.8, green: 0.4, blue: 0.0, alpha: 1)
            labelWeight = .bold
        case "idle":
            dot = "\u{25CB}"; label = "idle"
            dotColor = NSColor(red: 0.45, green: 0.45, blue: 0.5, alpha: 1)
            labelColor = NSColor(red: 0.45, green: 0.45, blue: 0.5, alpha: 1)
            labelWeight = .medium
        case "error":
            dot = "\u{25CF}"; label = "ERROR"
            dotColor = NSColor(red: 0.75, green: 0.1, blue: 0.35, alpha: 1)
            labelColor = NSColor(red: 0.7, green: 0.05, blue: 0.3, alpha: 1)
            labelWeight = .bold
        default:
            dot = "\u{25CB}"; label = session.status
            dotColor = NSColor(red: 0.45, green: 0.45, blue: 0.5, alpha: 1)
            labelColor = NSColor(red: 0.45, green: 0.45, blue: 0.5, alpha: 1)
            labelWeight = .medium
        }

        let dirName = (session.cwd as NSString).lastPathComponent
        let crabState = stateFor(session.status)

        let hasTmux = session.tmuxPane != nil && !session.tmuxPane!.isEmpty
        let item = NSMenuItem(
            title: "\(session.name) \(dirName)",
            action: hasTmux ? #selector(focusSession(_:)) : nil,
            keyEquivalent: ""
        )
        item.target = hasTmux ? self : nil
        item.isEnabled = hasTmux
        item.representedObject = session.tmuxPane
        item.image = CrabRenderer.createImage(size: 16, frame: animFrame, state: crabState)

        // Build attributed title: "● Name  dir  STATUS"
        let main = NSMutableAttributedString(
            string: "\(dot) ",
            attributes: [
                .font: NSFont.systemFont(ofSize: 14),
                .foregroundColor: dotColor
            ]
        )
        main.append(NSAttributedString(
            string: "\(session.name)",
            attributes: [
                .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
                .foregroundColor: NSColor.labelColor
            ]
        ))
        main.append(NSAttributedString(
            string: "  \(dirName)  ",
            attributes: [
                .font: NSFont.systemFont(ofSize: 12),
                .foregroundColor: NSColor(red: 0.35, green: 0.35, blue: 0.4, alpha: 1)
            ]
        ))
        main.append(NSAttributedString(
            string: label,
            attributes: [
                .font: NSFont.systemFont(ofSize: 11, weight: labelWeight),
                .foregroundColor: labelColor
            ]
        ))
        item.attributedTitle = main
        menu.addItem(item)

        // Detail row: path with ~ for home directory
        let displayPath = abbreviatePath(session.cwd)
        let detail = NSMenuItem(title: displayPath, action: nil, keyEquivalent: "")
        detail.isEnabled = false
        detail.attributedTitle = NSAttributedString(
            string: "      \(displayPath)",
            attributes: [
                .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .regular),
                .foregroundColor: NSColor(red: 0.4, green: 0.4, blue: 0.45, alpha: 1)
            ]
        )
        menu.addItem(detail)
    }

    private func stateFor(_ status: String) -> CrabState {
        switch status {
        case "working":                          return .working
        case "needs_input", "needs_permission":  return .needsInput
        case "error":                            return .error
        case "idle":                             return .idle
        default:                                 return .none
        }
    }

    // MARK: - Focus Session

    @objc private func focusSession(_ sender: NSMenuItem) {
        guard let paneId = sender.representedObject as? String, !paneId.isEmpty else { return }

        // Select the tmux window and pane
        let selectWindow = Process()
        selectWindow.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        selectWindow.arguments = ["tmux", "select-window", "-t", paneId]
        selectWindow.standardOutput = FileHandle.nullDevice
        selectWindow.standardError = FileHandle.nullDevice
        try? selectWindow.run()
        selectWindow.waitUntilExit()

        let selectPane = Process()
        selectPane.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        selectPane.arguments = ["tmux", "select-pane", "-t", paneId]
        selectPane.standardOutput = FileHandle.nullDevice
        selectPane.standardError = FileHandle.nullDevice
        try? selectPane.run()
        selectPane.waitUntilExit()

        // Bring Ghostty to front
        let activate = Process()
        activate.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        activate.arguments = ["-e", "tell application \"Ghostty\" to activate"]
        activate.standardOutput = FileHandle.nullDevice
        activate.standardError = FileHandle.nullDevice
        try? activate.run()
    }

    // MARK: - Notifications

    private func sendNotification(session: CrabSession) {
        let title = "\(session.name) needs your attention!"
        let body = (session.cwd as NSString).lastPathComponent

        let safeTitle = title
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let safeBody = body
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        let script = "display notification \"\(safeBody)\" with title \"\(safeTitle)\" sound name \"Ping\""
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        proc.arguments = ["-e", script]
        proc.standardOutput = FileHandle.nullDevice
        proc.standardError = FileHandle.nullDevice
        try? proc.run()
    }
}

// MARK: - Entry Point

let app = NSApplication.shared
app.setActivationPolicy(.accessory) // No dock icon

let delegate = ClaudeObserverDelegate()
app.delegate = delegate
app.run()
