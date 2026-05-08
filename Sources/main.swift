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

private func elapsedString(since isoString: String) -> String {
    let fmt = ISO8601DateFormatter()
    guard let date = fmt.date(from: isoString) else { return "" }
    let elapsed = Date().timeIntervalSince(date)
    if elapsed < 60 { return "\(Int(elapsed))s" }
    if elapsed < 3600 { return "\(Int(elapsed / 60))m" }
    return "\(Int(elapsed / 3600))h"
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

        let bounce: CGFloat = (state == .needsInput && frame % 2 == 1) ? 1.5 : 0
        let legWiggle: CGFloat = (state == .working) ? ((frame % 2 == 0) ? 1.0 : -1.0) : 0
        let clawWave: CGFloat = (state == .working) ? ((frame % 2 == 0) ? 0.0 : 1.2) : 0

        ctx.saveGState()
        if crabScale < 1.0 {
            ctx.translateBy(x: w * (1 - crabScale) / 2 + crabOffX, y: crabOffY)
            ctx.scaleBy(x: crabScale, y: crabScale)
        }

        // Legs
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

        // Claws
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

        // Body
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

        // Eye stalks
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

        // Eyes
        let er = max(1.8, w * 0.09)
        let elx = eyeLX - w * 0.03
        let erx = eyeRX + w * 0.03

        if state == .idle || state == .none {
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

        // Mouth
        let mouthY = h * 0.33 + bounce
        if state == .needsInput || state == .error {
            ctx.setFillColor(color(0.3, 0.05, 0.05, 0.8))
            ctx.fillEllipse(in: CGRect(x: w * 0.45, y: mouthY - w * 0.035, width: w * 0.1, height: w * 0.07))
        } else if state == .idle || state == .none {
            ()
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

        // Working sparkles
        if state == .working {
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

        // Idle zzz
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

        // Notification badge
        if state == .needsInput || state == .error {
            let badgeR = w * 0.22
            let badgeCX = w * 0.82
            let badgeCY = h * 0.78

            ctx.setFillColor(color(0, 0, 0, 0.2))
            ctx.fillEllipse(in: CGRect(
                x: badgeCX - badgeR + 0.5, y: badgeCY - badgeR - 0.5,
                width: badgeR * 2, height: badgeR * 2
            ))

            let badgeFill = (state == .error) ? color(0.9, 0.15, 0.5) : color(1.0, 0.15, 0.15)
            ctx.setFillColor(badgeFill)
            ctx.fillEllipse(in: CGRect(
                x: badgeCX - badgeR, y: badgeCY - badgeR,
                width: badgeR * 2, height: badgeR * 2
            ))

            ctx.setStrokeColor(CGColor.white)
            ctx.setLineWidth(max(0.8, w * 0.03))
            ctx.strokeEllipse(in: CGRect(
                x: badgeCX - badgeR, y: badgeCY - badgeR,
                width: badgeR * 2, height: badgeR * 2
            ))

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

// MARK: - Dynamic Island Panel

class IslandPanel: NSPanel {
    override var canBecomeKey: Bool { true }

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovableByWindowBackground = false
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        acceptsMouseMovedEvents = true
    }
}

// MARK: - Dynamic Island View

class IslandView: NSView {
    var sessions: [CrabSession] = []
    var animFrame: Int = 0
    var isExpanded = false
    var hoveredRowIndex: Int = -1
    var onToggle: (() -> Void)?
    var onSessionClick: ((CrabSession) -> Void)?

    static let compactHeight: CGFloat = 36
    static let sessionRowHeight: CGFloat = 52
    static let expandedWidth: CGFloat = 400
    static let compactWidthWithSessions: CGFloat = 240
    static let compactWidthEmpty: CGFloat = 160

    override var isFlipped: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    var sortedSessions: [CrabSession] {
        sessions.sorted { $0.startedAt < $1.startedAt }
    }

    // MARK: - Mouse Tracking

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach { removeTrackingArea($0) }
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways],
            owner: self
        ))
    }

    override func mouseExited(with event: NSEvent) {
        if hoveredRowIndex != -1 {
            hoveredRowIndex = -1
            needsDisplay = true
        }
    }

    override func mouseMoved(with event: NSEvent) {
        guard isExpanded else { return }
        let point = convert(event.locationInWindow, from: nil)
        let newIndex = rowIndex(at: point)
        if newIndex != hoveredRowIndex {
            hoveredRowIndex = newIndex
            needsDisplay = true
        }
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        if isExpanded {
            if point.y < Self.compactHeight {
                onToggle?()
                return
            }
            let index = rowIndex(at: point)
            let sorted = sortedSessions
            if index >= 0 && index < sorted.count {
                onSessionClick?(sorted[index])
            }
        } else {
            onToggle?()
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(
            title: "Quit Claude Observer",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }

    private func rowIndex(at point: NSPoint) -> Int {
        guard isExpanded else { return -1 }
        let rowsStartY = Self.compactHeight + 8
        let y = point.y - rowsStartY
        guard y >= 0 else { return -1 }
        let index = Int(y / Self.sessionRowHeight)
        return index < sessions.count ? index : -1
    }

    // MARK: - State Helpers

    func aggregateState() -> CrabState {
        let hasError = sessions.contains { $0.status == "error" }
        let needsInput = sessions.contains { $0.status == "needs_input" || $0.status == "needs_permission" }
        let hasWorking = sessions.contains { $0.status == "working" }

        if hasError { return .error }
        if needsInput { return .needsInput }
        if hasWorking { return .working }
        if !sessions.isEmpty { return .idle }
        return .none
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

    private func sessionStatusInfo(_ session: CrabSession) -> (dotColor: NSColor, label: String, labelColor: NSColor) {
        switch session.status {
        case "working":
            return (.systemGreen, "WORKING", .systemGreen)
        case "needs_input":
            return (.systemRed, "INPUT", .systemOrange)
        case "needs_permission":
            return (.systemOrange, "PERMISSION", .systemOrange)
        case "idle":
            return (NSColor(white: 0.5, alpha: 0.6), "idle", NSColor(white: 1, alpha: 0.4))
        case "error":
            return (.systemPink, "ERROR", .systemPink)
        default:
            return (NSColor(white: 0.5, alpha: 0.6), session.status, NSColor(white: 1, alpha: 0.4))
        }
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        drawCompactHeader()
        if isExpanded && !sessions.isEmpty {
            drawSeparator()
            let sorted = sortedSessions
            for (i, session) in sorted.enumerated() {
                let y = Self.compactHeight + 8 + CGFloat(i) * Self.sessionRowHeight
                drawSessionRow(session, at: y, index: i)
            }
        }
    }

    private func drawCompactHeader() {
        let state = aggregateState()
        let padding: CGFloat = 14
        var x: CGFloat = padding

        // Crab icon
        let crabSize: CGFloat = 24
        let crabY = (Self.compactHeight - crabSize) / 2
        let crabImage = CrabRenderer.createImage(size: crabSize, frame: animFrame, state: state)
        crabImage.draw(in: NSRect(x: x, y: crabY, width: crabSize, height: crabSize))
        x += crabSize + 10

        // Status dot
        let dotSize: CGFloat = 8
        let dotY = (Self.compactHeight - dotSize) / 2
        let dotColor: NSColor
        switch state {
        case .working:    dotColor = .systemGreen
        case .needsInput: dotColor = .systemOrange
        case .error:      dotColor = .systemPink
        case .idle:       dotColor = NSColor(white: 0.5, alpha: 0.6)
        case .none:       dotColor = NSColor(white: 0.4, alpha: 0.4)
        }
        dotColor.setFill()
        NSBezierPath(ovalIn: NSRect(x: x, y: dotY, width: dotSize, height: dotSize)).fill()
        x += dotSize + 8

        // Status text
        let statusText: String
        let statusTextColor: NSColor
        switch state {
        case .working:
            let workingCount = sessions.filter({ $0.status == "working" }).count
            statusText = workingCount == 1 ? "Working" : "\(workingCount) working"
            statusTextColor = NSColor(white: 1, alpha: 0.9)
        case .needsInput:
            statusText = "Input needed"
            statusTextColor = .systemOrange
        case .error:
            statusText = "Error"
            statusTextColor = .systemPink
        case .idle:
            let idleCount = sessions.filter({ $0.status == "idle" }).count
            statusText = idleCount == 1 ? "Idle" : "\(idleCount) idle"
            statusTextColor = NSColor(white: 1, alpha: 0.5)
        case .none:
            statusText = "No sessions"
            statusTextColor = NSColor(white: 1, alpha: 0.35)
        }

        let textAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: statusTextColor
        ]
        let textStr = NSAttributedString(string: statusText, attributes: textAttrs)
        let textY = (Self.compactHeight - textStr.size().height) / 2
        textStr.draw(at: NSPoint(x: x, y: textY))

        // Session count badge (right side)
        if sessions.count > 1 {
            let countAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .semibold),
                .foregroundColor: NSColor(white: 1, alpha: 0.45)
            ]
            let countStr = NSAttributedString(string: "\(sessions.count)", attributes: countAttrs)
            let countWidth = countStr.size().width
            countStr.draw(at: NSPoint(x: bounds.width - padding - countWidth, y: textY + 1))
        }
    }

    private func drawSeparator() {
        let y = Self.compactHeight + 3
        NSColor(white: 1, alpha: 0.1).setFill()
        NSBezierPath(rect: NSRect(x: 20, y: y, width: bounds.width - 40, height: 0.5)).fill()
    }

    private func drawSessionRow(_ session: CrabSession, at y: CGFloat, index: Int) {
        let padding: CGFloat = 14
        let crabState = stateFor(session.status)
        let hasTmux = session.tmuxPane != nil && !(session.tmuxPane?.isEmpty ?? true)

        // Hover highlight
        if hoveredRowIndex == index && hasTmux {
            let rowRect = NSRect(x: 6, y: y + 1, width: bounds.width - 12, height: Self.sessionRowHeight - 2)
            let hoverPath = NSBezierPath(roundedRect: rowRect, xRadius: 8, yRadius: 8)
            NSColor(white: 1, alpha: 0.07).setFill()
            hoverPath.fill()
        }

        let textX: CGFloat = padding + 16 + 6 + 7 + 8  // crab + gap + dot + gap
        var x: CGFloat = padding

        // Crab icon
        let crabImage = CrabRenderer.createImage(size: 16, frame: animFrame, state: crabState)
        crabImage.draw(in: NSRect(x: x, y: y + 10, width: 16, height: 16))
        x += 22

        // Status dot
        let dotSize: CGFloat = 7
        let info = sessionStatusInfo(session)
        info.dotColor.setFill()
        NSBezierPath(ovalIn: NSRect(x: x, y: y + 15, width: dotSize, height: dotSize)).fill()

        // Crab name
        let nameAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: NSColor(white: 1, alpha: 0.95)
        ]
        let nameStr = NSAttributedString(string: session.name, attributes: nameAttrs)
        nameStr.draw(at: NSPoint(x: textX, y: y + 8))
        let nameWidth = nameStr.size().width

        // Directory name
        let dirName = (session.cwd as NSString).lastPathComponent
        let dirAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: NSColor(white: 1, alpha: 0.35)
        ]
        let dirStr = NSAttributedString(string: dirName, attributes: dirAttrs)
        dirStr.draw(at: NSPoint(x: textX + nameWidth + 8, y: y + 9))

        // Elapsed time (far right)
        let elapsed = elapsedString(since: session.startedAt)
        let timeAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular),
            .foregroundColor: NSColor(white: 1, alpha: 0.35)
        ]
        let timeStr = NSAttributedString(string: elapsed, attributes: timeAttrs)
        let timeWidth = timeStr.size().width
        timeStr.draw(at: NSPoint(x: bounds.width - padding - timeWidth, y: y + 9))

        // Status label (before elapsed time)
        let statusAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: info.labelColor
        ]
        let statusStr = NSAttributedString(string: info.label, attributes: statusAttrs)
        let statusWidth = statusStr.size().width
        statusStr.draw(at: NSPoint(x: bounds.width - padding - timeWidth - 8 - statusWidth, y: y + 9))

        // Full path on second line
        let displayPath = abbreviatePath(session.cwd)
        let pathAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .regular),
            .foregroundColor: NSColor(white: 1, alpha: 0.3)
        ]
        let pathStr = NSAttributedString(string: displayPath, attributes: pathAttrs)
        pathStr.draw(at: NSPoint(x: textX, y: y + 30))
    }
}

// MARK: - App Delegate

class ClaudeObserverDelegate: NSObject, NSApplicationDelegate {
    private var panel: IslandPanel!
    private var glowView: NSView!
    private var visualEffectView: NSVisualEffectView!
    private var islandView: IslandView!
    private var sessions: [String: CrabSession] = [:]
    private var notifiedSessions: Set<String> = []
    private var animFrame = 0
    private var animTimer: Timer?
    private var pollTimer: Timer?
    private var isExpanded = false
    private var isAnimating = false
    private var clickMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if isDuplicate() {
            print("Claude Observer is already running.")
            NSApp.terminate(nil)
            return
        }

        try? FileManager.default.createDirectory(at: kStateDir, withIntermediateDirectories: true)

        setupPanel()
        pollSessions()

        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.pollSessions()
        }

        animTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.animFrame += 1
            self.updateDisplay()
        }

        updateDisplay()
    }

    // MARK: - Panel Setup

    private func setupPanel() {
        let frame = compactFrame()
        panel = IslandPanel(contentRect: frame)

        // Glow container (draws shadow, doesn't clip)
        glowView = NSView(frame: NSRect(origin: .zero, size: frame.size))
        glowView.wantsLayer = true
        glowView.autoresizingMask = [.width, .height]
        glowView.layer?.cornerRadius = IslandView.compactHeight / 2
        glowView.layer?.backgroundColor = NSColor(white: 0.08, alpha: 1).cgColor
        glowView.layer?.shadowOffset = .zero
        glowView.layer?.shadowOpacity = 0

        // Visual effect background (rounded, clips content)
        visualEffectView = NSVisualEffectView(frame: NSRect(origin: .zero, size: frame.size))
        visualEffectView.material = .hudWindow
        visualEffectView.state = .active
        visualEffectView.appearance = NSAppearance(named: .darkAqua)
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.wantsLayer = true
        visualEffectView.autoresizingMask = [.width, .height]
        visualEffectView.layer?.cornerRadius = IslandView.compactHeight / 2
        visualEffectView.layer?.masksToBounds = true

        // Island content view
        islandView = IslandView(frame: NSRect(origin: .zero, size: frame.size))
        islandView.wantsLayer = true
        islandView.layerContentsRedrawPolicy = .duringViewResize
        islandView.autoresizingMask = [.width, .height]
        islandView.onToggle = { [weak self] in self?.toggle() }
        islandView.onSessionClick = { [weak self] session in
            guard let tmux = session.tmuxPane, !tmux.isEmpty else { return }
            self?.focusTmuxPane(tmux)
        }

        // View hierarchy
        visualEffectView.addSubview(islandView)
        glowView.addSubview(visualEffectView)
        panel.contentView?.addSubview(glowView)

        panel.orderFrontRegardless()
    }

    // MARK: - Frame Calculations

    private func compactFrame() -> NSRect {
        guard let screen = NSScreen.main else {
            return NSRect(x: 100, y: 100, width: IslandView.compactWidthWithSessions, height: IslandView.compactHeight)
        }
        let w = sessions.isEmpty ? IslandView.compactWidthEmpty : IslandView.compactWidthWithSessions
        let h = IslandView.compactHeight
        let x = screen.frame.midX - w / 2
        let y = screen.visibleFrame.maxY - h - 6
        return NSRect(x: x, y: y, width: w, height: h)
    }

    private func expandedFrame() -> NSRect {
        guard let screen = NSScreen.main else {
            return NSRect(x: 100, y: 100, width: IslandView.expandedWidth, height: 200)
        }
        let w = IslandView.expandedWidth
        let rowCount = CGFloat(max(1, sessions.count))
        let h = IslandView.compactHeight + 8 + rowCount * IslandView.sessionRowHeight + 8
        let x = screen.frame.midX - w / 2
        let y = screen.visibleFrame.maxY - h - 6
        return NSRect(x: x, y: y, width: w, height: h)
    }

    // MARK: - Expand / Collapse

    private func toggle() {
        if isExpanded { collapse() } else { expand() }
    }

    private func expand() {
        guard !isAnimating, !sessions.isEmpty else { return }
        isAnimating = true
        isExpanded = true
        islandView.isExpanded = true
        islandView.needsDisplay = true

        let newFrame = expandedFrame()
        let cornerRadius: CGFloat = 16

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.3
            ctx.allowsImplicitAnimation = true
            self.panel.animator().setFrame(newFrame, display: true)
            self.glowView.layer?.cornerRadius = cornerRadius
            self.visualEffectView.layer?.cornerRadius = cornerRadius
        }, completionHandler: { [weak self] in
            self?.isAnimating = false
        })

        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.collapse()
        }
    }

    private func collapse() {
        guard !isAnimating || isExpanded else { return }
        isAnimating = true
        isExpanded = false
        islandView.isExpanded = false
        islandView.hoveredRowIndex = -1
        islandView.needsDisplay = true

        let newFrame = compactFrame()
        let cornerRadius = IslandView.compactHeight / 2

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.25
            ctx.allowsImplicitAnimation = true
            self.panel.animator().setFrame(newFrame, display: true)
            self.glowView.layer?.cornerRadius = cornerRadius
            self.visualEffectView.layer?.cornerRadius = cornerRadius
        }, completionHandler: { [weak self] in
            self?.isAnimating = false
        })

        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
        }
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
        islandView.sessions = Array(sessions.values)
        islandView.animFrame = animFrame
        islandView.needsDisplay = true

        updateGlow()

        // Auto-collapse if no sessions
        if isExpanded && sessions.isEmpty {
            collapse()
            return
        }

        // Update compact frame (smooth resize)
        if !isExpanded && !isAnimating {
            let newFrame = compactFrame()
            if panel.frame != newFrame {
                NSAnimationContext.runAnimationGroup { ctx in
                    ctx.duration = 0.2
                    ctx.allowsImplicitAnimation = true
                    self.panel.animator().setFrame(newFrame, display: true)
                }
            }
        }

        // Update expanded frame if session count changed while expanded
        if isExpanded && !isAnimating {
            let newFrame = expandedFrame()
            if panel.frame != newFrame {
                NSAnimationContext.runAnimationGroup { ctx in
                    ctx.duration = 0.2
                    ctx.allowsImplicitAnimation = true
                    self.panel.animator().setFrame(newFrame, display: true)
                }
            }
        }
    }

    private func updateGlow() {
        let state = islandView.aggregateState()
        let layer = glowView.layer

        switch state {
        case .working:
            layer?.shadowColor = NSColor.systemGreen.cgColor
            layer?.shadowRadius = 8
            layer?.shadowOpacity = 0.25
        case .needsInput:
            let pulse: Float = (animFrame % 4 < 2) ? 0.3 : 0.55
            layer?.shadowColor = NSColor.systemOrange.cgColor
            layer?.shadowRadius = 12
            layer?.shadowOpacity = pulse
        case .error:
            let pulse: Float = (animFrame % 4 < 2) ? 0.3 : 0.55
            layer?.shadowColor = NSColor.systemPink.cgColor
            layer?.shadowRadius = 12
            layer?.shadowOpacity = pulse
        default:
            layer?.shadowOpacity = 0
        }
        layer?.shadowOffset = .zero
    }

    // MARK: - Duplicate Detection

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

    // MARK: - Focus Session

    private func focusTmuxPane(_ paneId: String) {
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

        let switchClient = Process()
        switchClient.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        switchClient.arguments = ["tmux", "switch-client", "-t", paneId]
        switchClient.standardOutput = FileHandle.nullDevice
        switchClient.standardError = FileHandle.nullDevice
        try? switchClient.run()
        switchClient.waitUntilExit()

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
app.setActivationPolicy(.accessory)

let delegate = ClaudeObserverDelegate()
app.delegate = delegate
app.run()
