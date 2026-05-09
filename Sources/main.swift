import Cocoa
import Network
import CryptoKit

// MARK: - Constants

let kStateDir = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".claude-observer/sessions")

let kSettingsFile = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".claude-observer/settings.json")

let kWebDir = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".claude-observer/web")

let kSystemSounds: [String] = {
    let soundsDir = "/System/Library/Sounds"
    let fm = FileManager.default
    guard let files = try? fm.contentsOfDirectory(atPath: soundsDir) else { return [] }
    return files
        .filter { $0.hasSuffix(".aiff") }
        .map { ($0 as NSString).deletingPathExtension }
        .sorted()
}()

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

// MARK: - Settings

struct ObserverSettings: Codable {
    var permissionSound: String
    var errorSound: String
    var webDashboardEnabled: Bool
    var webDashboardPort: Int

    enum CodingKeys: String, CodingKey {
        case permissionSound = "permission_sound"
        case errorSound = "error_sound"
        case webDashboardEnabled = "web_dashboard_enabled"
        case webDashboardPort = "web_dashboard_port"
    }

    static let defaults = ObserverSettings(
        permissionSound: "Ping", errorSound: "Basso",
        webDashboardEnabled: false, webDashboardPort: 9321
    )

    init(permissionSound: String, errorSound: String, webDashboardEnabled: Bool, webDashboardPort: Int) {
        self.permissionSound = permissionSound
        self.errorSound = errorSound
        self.webDashboardEnabled = webDashboardEnabled
        self.webDashboardPort = webDashboardPort
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        permissionSound = (try? c.decode(String.self, forKey: .permissionSound)) ?? Self.defaults.permissionSound
        errorSound = (try? c.decode(String.self, forKey: .errorSound)) ?? Self.defaults.errorSound
        webDashboardEnabled = (try? c.decode(Bool.self, forKey: .webDashboardEnabled)) ?? Self.defaults.webDashboardEnabled
        webDashboardPort = (try? c.decode(Int.self, forKey: .webDashboardPort)) ?? Self.defaults.webDashboardPort
    }

    static func load() -> ObserverSettings {
        guard let data = try? Data(contentsOf: kSettingsFile),
              let settings = try? JSONDecoder().decode(ObserverSettings.self, from: data)
        else { return .defaults }
        return settings
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(self) else { return }
        try? data.write(to: kSettingsFile, options: .atomic)
    }
}

// MARK: - Settings Window

class SettingsWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private var settings: ObserverSettings
    private var permissionPopUp: NSPopUpButton!
    private var errorPopUp: NSPopUpButton!
    private var dashCheckbox: NSButton!
    private var dashPortField: NSTextField!
    private var dashUrlLabel: NSTextField!
    private var dashPortLabel: NSTextField!
    var onDashboardSettingsChanged: (() -> Void)?

    override init() {
        self.settings = ObserverSettings.load()
        super.init()
    }

    func showWindow() {
        if let w = window {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        settings = ObserverSettings.load()

        let windowHeight: CGFloat = 310
        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: windowHeight),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        w.title = "Claude Observer Settings"
        w.center()
        w.delegate = self
        w.isReleasedWhenClosed = false

        let contentView = NSView(frame: w.contentView!.bounds)
        contentView.autoresizingMask = [.width, .height]

        var y = windowHeight - 40

        // --- Sound Settings ---
        let soundHeader = NSTextField(labelWithString: "Sound Alerts")
        soundHeader.frame = NSRect(x: 20, y: y, width: 200, height: 18)
        soundHeader.font = NSFont.boldSystemFont(ofSize: 13)
        contentView.addSubview(soundHeader)
        y -= 34

        let soundOptions = ["None (disabled)"] + kSystemSounds

        let permLabel = NSTextField(labelWithString: "Permission sound:")
        permLabel.frame = NSRect(x: 20, y: y, width: 140, height: 20)
        permLabel.alignment = .right
        contentView.addSubview(permLabel)

        permissionPopUp = NSPopUpButton(frame: NSRect(x: 170, y: y - 3, width: 180, height: 26))
        permissionPopUp.addItems(withTitles: soundOptions)
        selectSound(settings.permissionSound, in: permissionPopUp)
        permissionPopUp.target = self
        permissionPopUp.action = #selector(permissionSoundChanged(_:))
        contentView.addSubview(permissionPopUp)
        y -= 34

        let errorLabel = NSTextField(labelWithString: "Error sound:")
        errorLabel.frame = NSRect(x: 20, y: y, width: 140, height: 20)
        errorLabel.alignment = .right
        contentView.addSubview(errorLabel)

        errorPopUp = NSPopUpButton(frame: NSRect(x: 170, y: y - 3, width: 180, height: 26))
        errorPopUp.addItems(withTitles: soundOptions)
        selectSound(settings.errorSound, in: errorPopUp)
        errorPopUp.target = self
        errorPopUp.action = #selector(errorSoundChanged(_:))
        contentView.addSubview(errorPopUp)

        let previewBtn = NSButton(title: "Preview", target: self, action: #selector(previewSound(_:)))
        previewBtn.bezelStyle = .rounded
        previewBtn.frame = NSRect(x: 360, y: y - 3, width: 40, height: 26)
        previewBtn.font = NSFont.systemFont(ofSize: 10)
        contentView.addSubview(previewBtn)
        y -= 30

        // --- Separator ---
        let sep = NSBox(frame: NSRect(x: 20, y: y, width: 380, height: 1))
        sep.boxType = .separator
        contentView.addSubview(sep)
        y -= 24

        // --- Web Dashboard ---
        let dashHeader = NSTextField(labelWithString: "Phone Dashboard (PWA)")
        dashHeader.frame = NSRect(x: 20, y: y, width: 250, height: 18)
        dashHeader.font = NSFont.boldSystemFont(ofSize: 13)
        contentView.addSubview(dashHeader)
        y -= 30

        dashCheckbox = NSButton(checkboxWithTitle: "Enable web dashboard", target: self, action: #selector(dashEnabledChanged(_:)))
        dashCheckbox.frame = NSRect(x: 20, y: y, width: 250, height: 20)
        dashCheckbox.state = settings.webDashboardEnabled ? .on : .off
        contentView.addSubview(dashCheckbox)
        y -= 30

        dashPortLabel = NSTextField(labelWithString: "Port:")
        dashPortLabel.frame = NSRect(x: 20, y: y, width: 100, height: 20)
        dashPortLabel.alignment = .right
        contentView.addSubview(dashPortLabel)

        dashPortField = NSTextField(frame: NSRect(x: 130, y: y - 2, width: 80, height: 24))
        dashPortField.stringValue = "\(settings.webDashboardPort)"
        dashPortField.placeholderString = "9321"
        dashPortField.target = self
        dashPortField.action = #selector(dashPortChanged(_:))
        contentView.addSubview(dashPortField)

        let lanIP = localIPAddress() ?? "<your-mac-ip>"
        let port = settings.webDashboardPort
        dashUrlLabel = NSTextField(labelWithString: "Open on phone: http://\(lanIP):\(port)")
        dashUrlLabel.frame = NSRect(x: 130, y: y - 24, width: 280, height: 16)
        dashUrlLabel.font = NSFont.systemFont(ofSize: 11)
        dashUrlLabel.textColor = .secondaryLabelColor
        contentView.addSubview(dashUrlLabel)

        updateDashFieldVisibility()

        w.contentView = contentView
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = w
    }

    private func updateDashFieldVisibility() {
        let on = dashCheckbox.state == .on
        dashPortLabel.isHidden = !on
        dashPortField.isHidden = !on
        dashUrlLabel.isHidden = !on
    }

    private func selectSound(_ name: String, in popUp: NSPopUpButton) {
        if name.isEmpty {
            popUp.selectItem(at: 0) // "None (disabled)"
        } else if let idx = kSystemSounds.firstIndex(of: name) {
            popUp.selectItem(at: idx + 1) // offset by 1 for "None" entry
        } else {
            popUp.selectItem(at: 0)
        }
    }

    private func soundName(from popUp: NSPopUpButton) -> String {
        let idx = popUp.indexOfSelectedItem
        return idx == 0 ? "" : kSystemSounds[idx - 1]
    }

    @objc private func permissionSoundChanged(_ sender: NSPopUpButton) {
        settings.permissionSound = soundName(from: sender)
        settings.save()
    }

    @objc private func errorSoundChanged(_ sender: NSPopUpButton) {
        settings.errorSound = soundName(from: sender)
        settings.save()
    }

    @objc private func previewSound(_ sender: NSButton) {
        // Preview whichever popup was last changed, or permission sound by default
        let sound = soundName(from: permissionPopUp)
        guard !sound.isEmpty else { return }
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/afplay")
        task.arguments = ["/System/Library/Sounds/\(sound).aiff"]
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice
        try? task.run()
    }

    @objc private func dashEnabledChanged(_ sender: NSButton) {
        settings.webDashboardEnabled = sender.state == .on
        settings.save()
        updateDashFieldVisibility()
        onDashboardSettingsChanged?()
    }

    @objc private func dashPortChanged(_ sender: NSTextField) {
        settings.webDashboardPort = Int(dashPortField.stringValue) ?? ObserverSettings.defaults.webDashboardPort
        settings.save()
        onDashboardSettingsChanged?()
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
    }
}

// MARK: - LAN IP Detection

private func localIPAddress() -> String? {
    var ifaddr: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return nil }
    defer { freeifaddrs(ifaddr) }
    for ptr in sequence(first: first, next: { $0.pointee.ifa_next }) {
        let addr = ptr.pointee
        guard addr.ifa_addr.pointee.sa_family == UInt8(AF_INET) else { continue }
        let name = String(cString: addr.ifa_name)
        guard name.hasPrefix("en") else { continue }
        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        if getnameinfo(addr.ifa_addr, socklen_t(addr.ifa_addr.pointee.sa_len),
                       &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
            let ip = String(cString: hostname)
            if ip != "127.0.0.1" { return ip }
        }
    }
    return nil
}

// MARK: - Web Dashboard Server

class WebDashboardServer {
    private var listener: NWListener?
    private var wsClients: [ObjectIdentifier: NWConnection] = [:]
    private let queue = DispatchQueue(label: "web-dashboard")
    private let port: UInt16
    private var lastBroadcast: String = "{\"type\":\"sessions\",\"sessions\":[]}"
    var onPermissionResponse: ((String, String) -> Void)?

    init(port: UInt16) {
        self.port = port
    }

    func start() {
        guard let nwPort = NWEndpoint.Port(rawValue: port) else { return }
        do {
            listener = try NWListener(using: .tcp, on: nwPort)
        } catch { return }

        listener?.newConnectionHandler = { [weak self] conn in
            conn.start(queue: self?.queue ?? .main)
            self?.receiveHTTPRequest(on: conn)
        }
        listener?.stateUpdateHandler = { state in
            if case .ready = state {
                print("Web dashboard listening on port \(self.port)")
            }
        }
        listener?.start(queue: queue)
    }

    func stop() {
        listener?.cancel()
        listener = nil
        for (_, conn) in wsClients { conn.cancel() }
        wsClients.removeAll()
    }

    var isRunning: Bool { listener?.state == .ready }

    func broadcastSessions(_ sessions: [CrabSession]) {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(sessions),
              let json = String(data: data, encoding: .utf8) else { return }
        let message = "{\"type\":\"sessions\",\"sessions\":\(json)}"
        lastBroadcast = message
        queue.async {
            for (_, conn) in self.wsClients {
                self.sendWSText(message, on: conn)
            }
        }
    }

    // MARK: HTTP

    private func receiveHTTPRequest(on conn: NWConnection) {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, error in
            guard let self = self, let data = data, error == nil else {
                conn.cancel()
                return
            }
            let request = String(data: data, encoding: .utf8) ?? ""
            if request.lowercased().contains("upgrade: websocket") {
                self.handleWSUpgrade(request, on: conn)
            } else {
                self.handleHTTP(request, on: conn)
            }
        }
    }

    private func handleHTTP(_ request: String, on conn: NWConnection) {
        let firstLine = request.split(separator: "\r\n").first.map(String.init) ?? ""
        let parts = firstLine.split(separator: " ")
        let method = parts.count > 0 ? String(parts[0]) : ""
        let path = parts.count > 1 ? String(parts[1]) : "/"

        if method == "GET" && (path == "/" || path == "/index.html") {
            serveFile("index.html", contentType: "text/html; charset=utf-8", on: conn)
        } else if method == "GET" && path == "/manifest.json" {
            serveFile("manifest.json", contentType: "application/json", on: conn)
        } else if method == "GET" && path == "/api/sessions" {
            sendHTTP(conn, status: "200 OK", contentType: "application/json", body: lastBroadcast)
        } else if method == "POST" && path == "/api/permission-response" {
            // Extract body after \r\n\r\n
            if let bodyRange = request.range(of: "\r\n\r\n") {
                let body = String(request[bodyRange.upperBound...])
                handlePermissionPost(body)
            }
            sendHTTP(conn, status: "200 OK", contentType: "application/json", body: "{\"ok\":true}")
        } else if method == "OPTIONS" {
            sendHTTP(conn, status: "204 No Content", contentType: "text/plain", body: "")
        } else {
            sendHTTP(conn, status: "404 Not Found", contentType: "text/plain", body: "Not Found")
        }
    }

    private func serveFile(_ name: String, contentType: String, on conn: NWConnection) {
        let filePath = kWebDir.appendingPathComponent(name)
        if let content = try? String(contentsOf: filePath, encoding: .utf8) {
            sendHTTP(conn, status: "200 OK", contentType: contentType, body: content)
        } else {
            sendHTTP(conn, status: "404 Not Found", contentType: "text/plain", body: "File not found")
        }
    }

    private func sendHTTP(_ conn: NWConnection, status: String, contentType: String, body: String) {
        let bodyData = Data(body.utf8)
        let header = "HTTP/1.1 \(status)\r\nContent-Type: \(contentType)\r\nContent-Length: \(bodyData.count)\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\n\r\n"
        var response = Data(header.utf8)
        response.append(bodyData)
        conn.send(content: response, completion: .contentProcessed { _ in conn.cancel() })
    }

    private func handlePermissionPost(_ body: String) {
        guard let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let sessionId = json["session_id"] as? String,
              let decision = json["decision"] as? String else { return }
        DispatchQueue.main.async { self.onPermissionResponse?(sessionId, decision) }
    }

    // MARK: WebSocket

    private func handleWSUpgrade(_ request: String, on conn: NWConnection) {
        let lines = request.split(separator: "\r\n")
        var wsKey = ""
        for line in lines {
            let lower = line.lowercased()
            if lower.hasPrefix("sec-websocket-key:") {
                wsKey = String(line.split(separator: ":", maxSplits: 1).last ?? "").trimmingCharacters(in: .whitespaces)
            }
        }
        guard !wsKey.isEmpty else { conn.cancel(); return }

        let magic = "258EAFA5-E914-47DA-95CA-5AB5DF8F8E13"
        let digest = Insecure.SHA1.hash(data: Data((wsKey + magic).utf8))
        let acceptKey = Data(digest.withUnsafeBytes { Data($0) }).base64EncodedString()

        let response = "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: \(acceptKey)\r\n\r\n"
        conn.send(content: Data(response.utf8), completion: .contentProcessed { [weak self] _ in
            guard let self = self else { return }
            let oid = ObjectIdentifier(conn)
            self.wsClients[oid] = conn
            // Start reading first, then send initial state after a brief delay
            self.readWSFrame(on: conn)
            let initialData = self.lastBroadcast
            self.queue.asyncAfter(deadline: .now() + 0.1) {
                self.sendWSText(initialData, on: conn)
            }
        })
    }

    private func sendWSText(_ text: String, on conn: NWConnection) {
        let payload = Data(text.utf8)
        var frame = Data()
        frame.append(0x81)
        let len = payload.count
        if len < 126 {
            frame.append(UInt8(len))
        } else if len < 65536 {
            frame.append(126)
            frame.append(UInt8((len >> 8) & 0xFF))
            frame.append(UInt8(len & 0xFF))
        } else {
            frame.append(127)
            for i in stride(from: 56, through: 0, by: -8) {
                frame.append(UInt8((len >> i) & 0xFF))
            }
        }
        frame.append(payload)
        conn.send(content: frame, completion: .contentProcessed { _ in })
    }

    private func readWSFrame(on conn: NWConnection) {
        conn.receive(minimumIncompleteLength: 2, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            if isComplete || error != nil || data == nil || data!.isEmpty {
                self.removeClient(conn)
                return
            }
            let bytes = [UInt8](data!)
            guard bytes.count >= 2 else { self.readWSFrame(on: conn); return }

            let opcode = bytes[0] & 0x0F
            let masked = (bytes[1] & 0x80) != 0
            var payloadLen = Int(bytes[1] & 0x7F)
            var offset = 2

            if payloadLen == 126 {
                guard bytes.count >= 4 else { self.readWSFrame(on: conn); return }
                payloadLen = Int(bytes[2]) << 8 | Int(bytes[3])
                offset = 4
            } else if payloadLen == 127 {
                guard bytes.count >= 10 else { self.readWSFrame(on: conn); return }
                payloadLen = 0
                for i in 0..<8 { payloadLen = (payloadLen << 8) | Int(bytes[2 + i]) }
                offset = 10
            }

            if masked {
                guard bytes.count >= offset + 4 + payloadLen else { self.readWSFrame(on: conn); return }
                let maskKey = Array(bytes[offset..<offset+4])
                offset += 4
                var payload = Array(bytes[offset..<offset+payloadLen])
                for i in 0..<payload.count { payload[i] ^= maskKey[i % 4] }

                switch opcode {
                case 0x1: // text
                    if let text = String(bytes: payload, encoding: .utf8) {
                        self.handleWSMessage(text, from: conn)
                    }
                case 0x8: // close
                    self.removeClient(conn); return
                case 0x9: // ping → pong
                    var pong = Data([0x8A, UInt8(payload.count)])
                    pong.append(contentsOf: payload)
                    conn.send(content: pong, completion: .contentProcessed { _ in })
                default: break
                }
            } else if opcode == 0x8 {
                self.removeClient(conn); return
            }

            self.readWSFrame(on: conn)
        }
    }

    private func handleWSMessage(_ text: String, from conn: NWConnection) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }
        if type == "permission_response",
           let sessionId = json["session_id"] as? String,
           let decision = json["decision"] as? String {
            DispatchQueue.main.async { self.onPermissionResponse?(sessionId, decision) }
        }
    }

    private func removeClient(_ conn: NWConnection) {
        let oid = ObjectIdentifier(conn)
        wsClients.removeValue(forKey: oid)
        conn.cancel()
    }
}

// MARK: - Session Model

struct PermissionRequestInfo: Codable {
    let toolName: String
    let toolSummary: String
    let toolContent: String?
    let toolCategory: String?

    enum CodingKeys: String, CodingKey {
        case toolName = "tool_name"
        case toolSummary = "tool_summary"
        case toolContent = "tool_content"
        case toolCategory = "tool_category"
    }
}

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
    var terminalApp: String?
    var permissionRequest: PermissionRequestInfo?

    enum CodingKeys: String, CodingKey {
        case id, name, cwd, status, pid
        case startedAt = "started_at"
        case lastActivity = "last_activity"
        case notificationType = "notification_type"
        case tmuxPane = "tmux_pane"
        case terminalApp = "terminal_app"
        case permissionRequest = "permission_request"
    }

    var isClickable: Bool {
        let hasTmux = tmuxPane != nil && !(tmuxPane?.isEmpty ?? true)
        let hasTerminal = terminalApp != nil && !(terminalApp?.isEmpty ?? true)
        return hasTmux || hasTerminal
    }

    var badgeLabel: String {
        let hasTmux = tmuxPane != nil && !(tmuxPane?.isEmpty ?? true)
        if hasTmux { return "tmux" }
        guard let app = terminalApp, !app.isEmpty else { return "" }
        switch app {
        case "Ghostty": return "ghostty"
        case "Terminal": return "term"
        case "iTerm2": return "iterm"
        case "WezTerm": return "wez"
        case "Alacritty": return "alac"
        case "kitty": return "kitty"
        default: return app.lowercased().prefix(6).description
        }
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
    var codeScrollOffset: Int = 0
    private var codePreviewSessionId: String?
    var onToggle: (() -> Void)?
    var onSessionClick: ((CrabSession) -> Void)?
    var onPermissionResponse: ((CrabSession, String) -> Void)?

    static let compactHeight: CGFloat = 36
    static let sessionRowHeight: CGFloat = 52
    static let expandedWidth: CGFloat = 440
    static let compactWidthWithSessions: CGFloat = 270
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

    override func scrollWheel(with event: NSEvent) {
        guard isExpanded else { super.scrollWheel(with: event); return }
        let point = convert(event.locationInWindow, from: nil)
        let sorted = sortedSessions
        var y = Self.compactHeight + 8
        for session in sorted {
            let rh = rowHeight(for: session)
            if point.y >= y && point.y < y + rh {
                if session.status == "needs_permission",
                   let perm = session.permissionRequest,
                   let content = perm.toolContent, !content.isEmpty {
                    let totalLines = content.components(separatedBy: "\n").count
                    let maxOffset = max(0, totalLines - Self.codeMaxVisibleLines)
                    let delta = event.scrollingDeltaY
                    if event.hasPreciseScrollingDeltas {
                        codeScrollOffset -= Int(round(delta / Self.codeLineHeight))
                    } else {
                        codeScrollOffset -= Int(delta)
                    }
                    codeScrollOffset = max(0, min(maxOffset, codeScrollOffset))
                    needsDisplay = true
                    return
                }
            }
            y += rh
        }
        super.scrollWheel(with: event)
    }

    // Button layout constants for permission rows
    private static let buttonH: CGFloat = 22
    private static func buttonSpecs(for perm: PermissionRequestInfo) -> [(label: String, width: CGFloat)] {
        let category = perm.toolCategory ?? perm.toolName.lowercased()
        let allowAllLabel = "Allow all \(category)"
        let font = NSFont.systemFont(ofSize: 11, weight: .medium)
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let textWidth = NSAttributedString(string: allowAllLabel, attributes: attrs).size().width
        let allowAllWidth = ceil(textWidth) + 16
        return [("Yes", 40), ("No", 36), (allowAllLabel, allowAllWidth)]
    }
    private static let buttonGap: CGFloat = 8
    private static let permissionLineHeight: CGFloat = 14
    private static let maxPermissionLines = 5
    private static let maxPermissionLineChars = 55

    // Code preview constants
    private static let codeLineHeight: CGFloat = 13
    private static let codeFontSize: CGFloat = 9.5
    private static let codeMaxVisibleLines = 15
    private static let codePreviewPadV: CGFloat = 6
    private static let codeLineNumWidth: CGFloat = 28

    static func permissionDisplayLines(for perm: PermissionRequestInfo) -> [String] {
        let fullText = "\(perm.toolName): \(perm.toolSummary)"
        let allLines = fullText.components(separatedBy: .newlines)
        let limited = Array(allLines.prefix(maxPermissionLines))
        var result = limited.map { line in
            if line.count > maxPermissionLineChars {
                return String(line.prefix(maxPermissionLineChars - 3)) + "..."
            }
            return line
        }
        if allLines.count > maxPermissionLines {
            let last = result[result.count - 1]
            if !last.hasSuffix("...") {
                result[result.count - 1] = last + "..."
            }
        }
        return result
    }

    private static func permissionButtonYOffset(lineCount: Int) -> CGFloat {
        30 + CGFloat(lineCount) * permissionLineHeight + 9
    }

    private static func codePreviewHeight(for content: String) -> CGFloat {
        let lineCount = content.components(separatedBy: "\n").count
        let visible = min(lineCount, codeMaxVisibleLines)
        return CGFloat(visible) * codeLineHeight + codePreviewPadV * 2
    }

    private static func permissionButtonY(for perm: PermissionRequestInfo) -> CGFloat {
        if let content = perm.toolContent, !content.isEmpty {
            return 48 + codePreviewHeight(for: content) + 8
        }
        return permissionButtonYOffset(lineCount: permissionDisplayLines(for: perm).count)
    }

    static func permissionRowHeight(for perm: PermissionRequestInfo) -> CGFloat {
        return permissionButtonY(for: perm) + buttonH + 10
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        if isExpanded {
            if point.y < Self.compactHeight {
                onToggle?()
                return
            }
            let sorted = sortedSessions
            var y = Self.compactHeight + 8
            for (i, session) in sorted.enumerated() {
                let rh = rowHeight(for: session)
                if point.y >= y && point.y < y + rh {
                    // Check permission button clicks
                    if session.status == "needs_permission", let perm = session.permissionRequest {
                        let textX: CGFloat = 14 + 16 + 6 + 7 + 8
                        let btnY = y + Self.permissionButtonY(for: perm)
                        if point.y >= btnY && point.y < btnY + Self.buttonH {
                            let decisions = ["allow", "deny", "always_allow"]
                            var bx = textX
                            for (bi, spec) in Self.buttonSpecs(for: perm).enumerated() {
                                if point.x >= bx && point.x < bx + spec.width {
                                    onPermissionResponse?(session, decisions[bi])
                                    return
                                }
                                bx += spec.width + Self.buttonGap
                            }
                        }
                    }
                    onSessionClick?(sorted[i])
                    return
                }
                y += rh
            }
        } else {
            onToggle?()
        }
    }

    var onOpenSettings: (() -> Void)?

    override func rightMouseDown(with event: NSEvent) {
        let menu = NSMenu()
        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(settingsMenuClicked(_:)),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(
            title: "Quit Claude Observer",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }

    @objc private func settingsMenuClicked(_ sender: NSMenuItem) {
        onOpenSettings?()
    }

    func rowHeight(for session: CrabSession) -> CGFloat {
        if session.status == "needs_permission", let perm = session.permissionRequest {
            return Self.permissionRowHeight(for: perm)
        }
        return Self.sessionRowHeight
    }

    var totalRowHeight: CGFloat {
        sortedSessions.reduce(0) { $0 + rowHeight(for: $1) }
    }

    private func rowIndex(at point: NSPoint) -> Int {
        guard isExpanded else { return -1 }
        let sorted = sortedSessions
        var y = Self.compactHeight + 8
        for (i, session) in sorted.enumerated() {
            let rh = rowHeight(for: session)
            if point.y >= y && point.y < y + rh {
                return i
            }
            y += rh
        }
        return -1
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
            var y = Self.compactHeight + 8
            for (i, session) in sorted.enumerated() {
                drawSessionRow(session, at: y, index: i)
                y += rowHeight(for: session)
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
        let rh = rowHeight(for: session)

        // Hover highlight
        if hoveredRowIndex == index && session.isClickable {
            let rowRect = NSRect(x: 6, y: y + 1, width: bounds.width - 12, height: rh - 2)
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
        var afterNameX = textX + nameStr.size().width + 6

        // Terminal badge
        let badge = session.badgeLabel
        if !badge.isEmpty {
            let badgeAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 9, weight: .medium),
                .foregroundColor: NSColor(white: 1, alpha: 0.55)
            ]
            let badgeStr = NSAttributedString(string: badge, attributes: badgeAttrs)
            let badgeSize = badgeStr.size()
            let badgePadH: CGFloat = 5
            let badgePadV: CGFloat = 1.5
            let badgeRect = NSRect(
                x: afterNameX,
                y: y + 9,
                width: badgeSize.width + badgePadH * 2,
                height: badgeSize.height + badgePadV * 2
            )
            let badgePath = NSBezierPath(roundedRect: badgeRect, xRadius: 4, yRadius: 4)
            NSColor(white: 1, alpha: 0.1).setFill()
            badgePath.fill()
            badgeStr.draw(at: NSPoint(x: afterNameX + badgePadH, y: y + 9 + badgePadV))
            afterNameX += badgeRect.width + 6
        }

        // Directory name
        let dirName = (session.cwd as NSString).lastPathComponent
        let dirAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: NSColor(white: 1, alpha: 0.35)
        ]
        let dirStr = NSAttributedString(string: dirName, attributes: dirAttrs)
        dirStr.draw(at: NSPoint(x: afterNameX, y: y + 9))

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

        // Permission request: tool summary + action buttons
        if session.status == "needs_permission", let perm = session.permissionRequest {
            if let content = perm.toolContent, !content.isEmpty {
                // Tool header line
                let headerAttrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .regular),
                    .foregroundColor: NSColor(white: 1, alpha: 0.7)
                ]
                let headerText = "\(perm.toolName): \(perm.toolSummary)"
                let truncated = headerText.count > Self.maxPermissionLineChars
                    ? String(headerText.prefix(Self.maxPermissionLineChars - 3)) + "..."
                    : headerText
                NSAttributedString(string: truncated, attributes: headerAttrs)
                    .draw(at: NSPoint(x: textX, y: y + 30))

                // Code preview
                let codeY = y + 48
                let codeH = Self.codePreviewHeight(for: content)
                let codeRect = NSRect(x: textX, y: codeY,
                                      width: bounds.width - textX - padding,
                                      height: codeH)
                if codePreviewSessionId != session.id {
                    codeScrollOffset = 0
                    codePreviewSessionId = session.id
                }
                drawCodePreview(content: content, filePath: perm.toolSummary, at: codeRect)
            } else {
                // Text-only permission display
                let lines = Self.permissionDisplayLines(for: perm)
                let summaryAttrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .regular),
                    .foregroundColor: NSColor(white: 1, alpha: 0.7)
                ]
                for (i, line) in lines.enumerated() {
                    NSAttributedString(string: line, attributes: summaryAttrs)
                        .draw(at: NSPoint(x: textX, y: y + 30 + CGFloat(i) * Self.permissionLineHeight))
                }
            }

            // Action buttons
            let btnY = y + Self.permissionButtonY(for: perm)
            let colors: [NSColor] = [.systemGreen, .systemRed, .systemBlue]
            var bx = textX
            for (bi, spec) in Self.buttonSpecs(for: perm).enumerated() {
                drawButton(spec.label, at: NSPoint(x: bx, y: btnY),
                           size: NSSize(width: spec.width, height: Self.buttonH),
                           color: colors[bi])
                bx += spec.width + Self.buttonGap
            }
        } else {
            // Full path on second line (non-permission rows)
            let displayPath = abbreviatePath(session.cwd)
            let pathAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .regular),
                .foregroundColor: NSColor(white: 1, alpha: 0.3)
            ]
            NSAttributedString(string: displayPath, attributes: pathAttrs)
                .draw(at: NSPoint(x: textX, y: y + 30))
        }
    }

    // MARK: - Code Preview

    private static let codeBaseColor = NSColor(white: 1, alpha: 0.85)
    private static let codeKeyColor = NSColor(red: 0.55, green: 0.82, blue: 0.96, alpha: 1)
    private static let codeStringColor = NSColor(red: 0.81, green: 0.58, blue: 0.40, alpha: 1)
    private static let codeNumberColor = NSColor(red: 0.71, green: 0.84, blue: 0.59, alpha: 1)
    private static let codeBoolColor = NSColor(red: 0.78, green: 0.57, blue: 0.86, alpha: 1)
    private static let codeCommentColor = NSColor(white: 1, alpha: 0.4)
    private static let codeFont = NSFont.monospacedSystemFont(ofSize: 9.5, weight: .regular)

    private func drawCodePreview(content: String, filePath: String, at rect: NSRect) {
        let bgPath = NSBezierPath(roundedRect: rect, xRadius: 6, yRadius: 6)
        NSColor(white: 0, alpha: 0.3).setFill()
        bgPath.fill()

        let ctx = NSGraphicsContext.current!.cgContext
        ctx.saveGState()
        bgPath.addClip()

        let lines = content.components(separatedBy: "\n")
        let totalLines = lines.count
        let visibleCount = min(totalLines, Self.codeMaxVisibleLines)
        let fileExt = (filePath as NSString).pathExtension.lowercased()

        let startLine = codeScrollOffset
        let endLine = min(startLine + visibleCount, totalLines)

        let lineNumColor = NSColor(white: 1, alpha: 0.3)

        // Line number / code separator
        NSColor(white: 1, alpha: 0.08).setFill()
        NSBezierPath(rect: NSRect(
            x: rect.origin.x + Self.codeLineNumWidth,
            y: rect.origin.y,
            width: 0.5,
            height: rect.height
        )).fill()

        for i in startLine..<endLine {
            let drawY = rect.origin.y + Self.codePreviewPadV + CGFloat(i - startLine) * Self.codeLineHeight

            // Line number
            let numStr = NSAttributedString(string: "\(i + 1)", attributes: [
                .font: Self.codeFont, .foregroundColor: lineNumColor
            ])
            let numW = numStr.size().width
            numStr.draw(at: NSPoint(x: rect.origin.x + Self.codeLineNumWidth - numW - 4, y: drawY))

            // Syntax-highlighted code text
            let highlighted = Self.highlightLine(lines[i], fileExtension: fileExt)
            highlighted.draw(at: NSPoint(x: rect.origin.x + Self.codeLineNumWidth + 6, y: drawY))
        }

        // Scroll indicator
        if totalLines > Self.codeMaxVisibleLines {
            let trackH = rect.height - 4
            let thumbH = max(16, trackH * CGFloat(visibleCount) / CGFloat(totalLines))
            let maxScroll = max(1, CGFloat(totalLines - visibleCount))
            let thumbY = rect.origin.y + 2 + (trackH - thumbH) * CGFloat(codeScrollOffset) / maxScroll
            NSColor(white: 1, alpha: 0.2).setFill()
            NSBezierPath(roundedRect: NSRect(x: rect.maxX - 5, y: thumbY, width: 3, height: thumbH),
                         xRadius: 1.5, yRadius: 1.5).fill()
        }

        ctx.restoreGState()
    }

    private static func highlightLine(_ line: String, fileExtension: String) -> NSAttributedString {
        let baseAttrs: [NSAttributedString.Key: Any] = [.font: codeFont, .foregroundColor: codeBaseColor]
        let result = NSMutableAttributedString(string: line, attributes: baseAttrs)
        let range = NSRange(location: 0, length: (line as NSString).length)
        guard range.length > 0 else { return result }

        switch fileExtension {
        case "json":
            applyJSONHighlighting(to: result, in: range)
        default:
            applyGenericHighlighting(to: result, in: range)
        }
        return result
    }

    private static func applyJSONHighlighting(to s: NSMutableAttributedString, in range: NSRange) {
        let text = s.string as NSString

        if let regex = try? NSRegularExpression(pattern: "\"(?:[^\"\\\\]|\\\\.)*\"") {
            for match in regex.matches(in: s.string, range: range) {
                let r = match.range
                let after = r.location + r.length
                var isKey = false
                if after < text.length {
                    let rest = text.substring(from: after)
                    isKey = rest.trimmingCharacters(in: .whitespaces).hasPrefix(":")
                }
                s.addAttribute(.foregroundColor, value: isKey ? codeKeyColor : codeStringColor, range: r)
            }
        }

        if let regex = try? NSRegularExpression(pattern: "\\b(?:true|false|null)\\b") {
            for match in regex.matches(in: s.string, range: range) {
                s.addAttribute(.foregroundColor, value: codeBoolColor, range: match.range)
            }
        }

        if let regex = try? NSRegularExpression(pattern: "(?<=[:\\[,\\s])-?\\d+(?:\\.\\d+)?(?:[eE][+-]?\\d+)?\\b") {
            for match in regex.matches(in: s.string, range: range) {
                let existing = s.attribute(.foregroundColor, at: match.range.location, effectiveRange: nil) as? NSColor
                if existing == codeBaseColor {
                    s.addAttribute(.foregroundColor, value: codeNumberColor, range: match.range)
                }
            }
        }
    }

    private static func applyGenericHighlighting(to s: NSMutableAttributedString, in range: NSRange) {
        if let regex = try? NSRegularExpression(pattern: "(?://|#).*$", options: .anchorsMatchLines) {
            for match in regex.matches(in: s.string, range: range) {
                s.addAttribute(.foregroundColor, value: codeCommentColor, range: match.range)
            }
        }

        if let regex = try? NSRegularExpression(pattern: "\"(?:[^\"\\\\]|\\\\.)*\"|'(?:[^'\\\\]|\\\\.)*'") {
            for match in regex.matches(in: s.string, range: range) {
                s.addAttribute(.foregroundColor, value: codeStringColor, range: match.range)
            }
        }

        if let regex = try? NSRegularExpression(pattern: "\\b-?\\d+(?:\\.\\d+)?\\b") {
            for match in regex.matches(in: s.string, range: range) {
                let existing = s.attribute(.foregroundColor, at: match.range.location, effectiveRange: nil) as? NSColor
                if existing == codeBaseColor {
                    s.addAttribute(.foregroundColor, value: codeNumberColor, range: match.range)
                }
            }
        }
    }

    private func drawButton(_ title: String, at point: NSPoint, size: NSSize, color: NSColor) {
        let rect = NSRect(origin: point, size: size)
        let path = NSBezierPath(roundedRect: rect, xRadius: 6, yRadius: 6)
        color.withAlphaComponent(0.2).setFill()
        path.fill()
        color.withAlphaComponent(0.5).setStroke()
        path.lineWidth = 0.5
        path.stroke()

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: color
        ]
        let str = NSAttributedString(string: title, attributes: attrs)
        let textSize = str.size()
        str.draw(at: NSPoint(
            x: point.x + (size.width - textSize.width) / 2,
            y: point.y + (size.height - textSize.height) / 2
        ))
    }
}

// MARK: - App Delegate

class ClaudeObserverDelegate: NSObject, NSApplicationDelegate {
    private var panel: IslandPanel!
    private var glowView: NSView!
    private var visualEffectView: NSVisualEffectView!
    private var islandView: IslandView!
    private var sessions: [String: CrabSession] = [:]
    private var animFrame = 0
    private var animTimer: Timer?
    private var pollTimer: Timer?
    private var isExpanded = false
    private var isAnimating = false
    private var clickMonitor: Any?
    private let settingsController = SettingsWindowController()
    private var dashboardServer: WebDashboardServer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if isDuplicate() {
            print("Claude Observer is already running.")
            NSApp.terminate(nil)
            return
        }

        try? FileManager.default.createDirectory(at: kStateDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: kWebDir, withIntermediateDirectories: true)

        settingsController.onDashboardSettingsChanged = { [weak self] in
            self?.restartDashboardServer()
        }
        startDashboardServerIfEnabled()

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
            guard session.isClickable else { return }
            let hasTmux = session.tmuxPane != nil && !(session.tmuxPane?.isEmpty ?? true)
            if hasTmux {
                self?.focusTmuxPane(session.tmuxPane!, terminalApp: session.terminalApp)
            } else if let app = session.terminalApp, !app.isEmpty {
                self?.focusTerminalApp(app, pid: session.pid)
            }
        }
        islandView.onPermissionResponse = { [weak self] session, decision in
            self?.respondToPermission(session: session, decision: decision)
        }
        islandView.onOpenSettings = { [weak self] in
            self?.settingsController.showWindow()
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
        let totalRowH = sessions.values.reduce(CGFloat(0)) { sum, session in
            if session.status == "needs_permission", let perm = session.permissionRequest {
                return sum + IslandView.permissionRowHeight(for: perm)
            }
            return sum + IslandView.sessionRowHeight
        }
        let h = IslandView.compactHeight + 8 + max(totalRowH, IslandView.sessionRowHeight) + 8
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

        sessions = updated
        updateDisplay()
        dashboardServer?.broadcastSessions(Array(sessions.values))
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

    private func focusTmuxPane(_ paneId: String, terminalApp: String? = nil) {
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

        // Activate the terminal app hosting the tmux client
        let appName = (terminalApp != nil && !terminalApp!.isEmpty) ? terminalApp! : "Ghostty"
        activateApp(appName)
    }

    private func focusTerminalApp(_ appName: String, pid: Int?) {
        if let pid = pid {
            // Try to bring the window containing this PID to front via AppleScript
            let script = """
            tell application "System Events"
                set frontmost of (first process whose unix id is \(pid)) to true
            end tell
            """
            let activate = Process()
            activate.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            activate.arguments = ["-e", script]
            activate.standardOutput = FileHandle.nullDevice
            activate.standardError = FileHandle.nullDevice
            try? activate.run()
            activate.waitUntilExit()
            // If the PID-based approach didn't work (pid is the claude process, not the terminal),
            // fall back to activating the app by name
        }
        activateApp(appName)
    }

    private func activateApp(_ appName: String) {
        let activate = Process()
        activate.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        activate.arguments = ["-e", "tell application \"\(appName)\" to activate"]
        activate.standardOutput = FileHandle.nullDevice
        activate.standardError = FileHandle.nullDevice
        try? activate.run()
    }

    // MARK: - Permission Response

    private func respondToPermission(session: CrabSession, decision: String) {
        respondToPermission(sessionId: session.id, decision: decision)
    }

    private func respondToPermission(sessionId: String, decision: String) {
        let responseFile = kStateDir.appendingPathComponent("\(sessionId).response.json")
        let response: [String: String] = ["decision": decision]
        guard let data = try? JSONSerialization.data(withJSONObject: response) else { return }
        try? data.write(to: responseFile, options: .atomic)

        // Immediate local feedback
        if var s = sessions[sessionId] {
            s.permissionRequest = nil
            s.status = "working"
            sessions[sessionId] = s
            updateDisplay()
            dashboardServer?.broadcastSessions(Array(sessions.values))
        }
    }

    // MARK: - Web Dashboard Server

    private func startDashboardServerIfEnabled() {
        let settings = ObserverSettings.load()
        guard settings.webDashboardEnabled else { return }
        let server = WebDashboardServer(port: UInt16(settings.webDashboardPort))
        server.onPermissionResponse = { [weak self] sessionId, decision in
            self?.respondToPermission(sessionId: sessionId, decision: decision)
        }
        server.start()
        dashboardServer = server
    }

    private func restartDashboardServer() {
        dashboardServer?.stop()
        dashboardServer = nil
        startDashboardServerIfEnabled()
    }

}

// MARK: - Entry Point

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let delegate = ClaudeObserverDelegate()
app.delegate = delegate
app.run()
