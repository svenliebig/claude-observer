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

    enum CodingKeys: String, CodingKey {
        case id, name, cwd, status, pid
        case startedAt = "started_at"
        case lastActivity = "last_activity"
        case notificationType = "notification_type"
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
        let body: CGColor
        let shell: CGColor

        switch state {
        case .working:
            body = color(1.0, 0.42, 0.21)
            shell = color(0.88, 0.35, 0.15)
        case .idle:
            body = color(0.55, 0.55, 0.55, 0.75)
            shell = color(0.45, 0.45, 0.45, 0.75)
        case .needsInput:
            body = color(1.0, 0.25, 0.25)
            shell = color(0.88, 0.18, 0.18)
        case .error:
            body = color(0.8, 0.1, 0.4)
            shell = color(0.65, 0.08, 0.3)
        case .none:
            body = color(0.55, 0.55, 0.55, 0.35)
            shell = color(0.45, 0.45, 0.45, 0.35)
        }

        // Animation
        let bounce: CGFloat = (state == .needsInput && frame % 2 == 1) ? 1.2 : 0
        let legWiggle: CGFloat = (frame % 2 == 0) ? 0.8 : -0.8
        let clawWave: CGFloat = (frame % 2 == 0) ? 0.0 : 1.0

        // --- Legs (3 pairs, behind body) ---
        ctx.setStrokeColor(body)
        ctx.setLineWidth(max(1, w * 0.055))
        ctx.setLineCap(.round)

        for i in 0..<3 {
            let fi = CGFloat(i)
            let legY = h * 0.22 + fi * h * 0.065 + bounce
            let spread = w * (0.04 + fi * 0.025)
            let wig = (i % 2 == 0) ? legWiggle : -legWiggle

            // Left
            ctx.move(to: CGPoint(x: w * 0.27, y: legY))
            ctx.addLine(to: CGPoint(x: w * 0.08 - spread + wig, y: legY - h * 0.07))
            // Right
            ctx.move(to: CGPoint(x: w * 0.73, y: legY))
            ctx.addLine(to: CGPoint(x: w * 0.92 + spread - wig, y: legY - h * 0.07))
        }
        ctx.strokePath()

        // --- Claws ---
        ctx.setFillColor(body)

        // Left claw
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

        // Right claw (mirrored)
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

        // Shell highlight
        ctx.setFillColor(shell)
        let sw = bw * 0.68
        let sh = bh * 0.55
        ctx.fillEllipse(in: CGRect(x: (w - sw) / 2, y: by + bh * 0.18, width: sw, height: sh))

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

        ctx.setFillColor(CGColor.white)
        ctx.fillEllipse(in: CGRect(x: elx - er, y: stalkTop - er, width: er * 2, height: er * 2))
        ctx.fillEllipse(in: CGRect(x: erx - er, y: stalkTop - er, width: er * 2, height: er * 2))

        // Pupils
        let pr = er * 0.45
        let plook: CGFloat = (frame % 4 < 2) ? 0.2 : -0.2 // eyes look around
        ctx.setFillColor(color(0.15, 0.1, 0.1).copy(alpha: 0.95)!)
        ctx.fillEllipse(in: CGRect(x: elx - pr + plook, y: stalkTop - pr, width: pr * 2, height: pr * 2))
        ctx.fillEllipse(in: CGRect(x: erx - pr + plook, y: stalkTop - pr, width: pr * 2, height: pr * 2))

        // --- Mouth ---
        ctx.setStrokeColor(shell)
        ctx.setLineWidth(max(0.5, w * 0.028))
        ctx.setLineCap(.round)

        let mouthY = h * 0.33 + bounce
        if state == .needsInput {
            // Open mouth (surprised)
            ctx.fillEllipse(in: CGRect(x: w * 0.46, y: mouthY - w * 0.03, width: w * 0.08, height: w * 0.06))
        } else {
            // Smile
            ctx.addArc(
                center: CGPoint(x: w * 0.5, y: mouthY),
                radius: w * 0.055,
                startAngle: .pi * 1.15,
                endAngle: .pi * 1.85,
                clockwise: false
            )
            ctx.strokePath()
        }

        // --- "Zzz" for idle ---
        if state == .idle {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: max(5, w * 0.28), weight: .bold),
                .foregroundColor: NSColor(red: 0.4, green: 0.4, blue: 0.8, alpha: 0.8)
            ]
            let zStr = NSAttributedString(string: "z", attributes: attrs)
            zStr.draw(at: NSPoint(x: w * 0.7, y: h * 0.68))
        }

        // --- "!" for needs input ---
        if state == .needsInput && frame % 2 == 0 {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: max(6, w * 0.35), weight: .heavy),
                .foregroundColor: NSColor(red: 1, green: 0.9, blue: 0, alpha: 1)
            ]
            let eStr = NSAttributedString(string: "!", attributes: attrs)
            eStr.draw(at: NSPoint(x: w * 0.72, y: h * 0.6))
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
        let icon: String
        let label: String

        switch session.status {
        case "working":         icon = ""; label = "working"
        case "needs_input":     icon = ""; label = "needs input"
        case "needs_permission": icon = ""; label = "needs permission"
        case "idle":            icon = ""; label = "idle"
        case "error":           icon = ""; label = "error"
        default:                icon = ""; label = session.status
        }
        _ = icon // status shown via crab image

        let dirName = (session.cwd as NSString).lastPathComponent
        let crabState = stateFor(session.status)

        let item = NSMenuItem(title: "\(session.name)  \u{2014}  \(dirName)", action: nil, keyEquivalent: "")
        item.isEnabled = false
        item.image = CrabRenderer.createImage(size: 16, frame: animFrame, state: crabState)

        // Styled title with status
        let main = NSMutableAttributedString(
            string: "\(session.name)",
            attributes: [.font: NSFont.systemFont(ofSize: 13, weight: .medium)]
        )
        main.append(NSAttributedString(
            string: "  \(dirName)  ",
            attributes: [
                .font: NSFont.systemFont(ofSize: 12),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
        ))
        let badgeColor: NSColor
        switch crabState {
        case .working:    badgeColor = NSColor.systemGreen
        case .needsInput: badgeColor = NSColor.systemRed
        case .error:      badgeColor = NSColor.systemPink
        case .idle:       badgeColor = NSColor.systemGray
        case .none:       badgeColor = NSColor.systemGray
        }
        main.append(NSAttributedString(
            string: label,
            attributes: [
                .font: NSFont.systemFont(ofSize: 10, weight: .medium),
                .foregroundColor: badgeColor
            ]
        ))
        item.attributedTitle = main
        menu.addItem(item)

        // Detail row: full path
        let detail = NSMenuItem(title: session.cwd, action: nil, keyEquivalent: "")
        detail.isEnabled = false
        detail.attributedTitle = NSAttributedString(
            string: "    \(session.cwd)",
            attributes: [
                .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .regular),
                .foregroundColor: NSColor.tertiaryLabelColor
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
