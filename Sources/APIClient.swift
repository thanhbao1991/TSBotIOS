import Foundation

struct BotStatus: Decodable, Identifiable {
    var id: Int { idx }
    let idx: Int
    let username: String
    let loggedIn: Bool
    let charName: String
    let mapId: Int
    let x: Int
    let y: Int
    let level: Int
    let hp: Int
    let hpMax: Int
    let sp: Int
    let spMax: Int
    let partyRole: String
}

struct APIError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

/// Gọi thẳng control API của TSBotHeadless (xem D:\Source-game\Bot_TSBotUI\TSBotHeadless\
/// ControlApiServer.cs) qua domain public tsbot.denncoffee.uk — header X-Api-Key bắt buộc.
enum APIClient {
    private static func makeURL(_ path: String, _ query: [String: String] = [:]) -> URL? {
        var comps = URLComponents(string: Prefs.baseURL + path)
        var items = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        if !items.isEmpty { comps?.queryItems = items }
        items.removeAll()
        return comps?.url
    }

    private static func request(_ path: String, method: String, query: [String: String] = [:]) async throws -> Data {
        guard let url = makeURL(path, query) else { throw APIError(message: "URL không hợp lệ") }
        var req = URLRequest(url: url)
        req.httpMethod = method
        if !Prefs.apiKey.isEmpty { req.setValue(Prefs.apiKey, forHTTPHeaderField: "X-Api-Key") }
        if method == "POST" { req.setValue("0", forHTTPHeaderField: "Content-Length") }
        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode == 401 {
            throw APIError(message: "Sai API key (401)")
        }
        if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw APIError(message: "HTTP \(http.statusCode): \(body)")
        }
        return data
    }

    static func fetchStatus() async throws -> [BotStatus] {
        let data = try await request("/status", method: "GET")
        return try JSONDecoder().decode([BotStatus].self, from: data)
    }

    static func fetchLog(idx: Int, lines: Int = 150) async throws -> String {
        let data = try await request("/log", method: "GET", query: ["idx": "\(idx)", "lines": "\(lines)"])
        return String(data: data, encoding: .utf8) ?? ""
    }

    @discardableResult
    static func login(idx: Int) async throws -> Data {
        try await request("/login", method: "POST", query: ["idx": "\(idx)"])
    }

    @discardableResult
    static func logout(idx: Int) async throws -> Data {
        try await request("/logout", method: "POST", query: ["idx": "\(idx)"])
    }

    @discardableResult
    static func enterOtherworld(idx: Int) async throws -> Data {
        try await request("/otherworld", method: "POST", query: ["idx": "\(idx)"])
    }

    @discardableResult
    static func setSetting(idx: Int, name: String, value: String) async throws -> Data {
        try await request("/setting", method: "POST", query: ["idx": "\(idx)", "name": name, "value": value])
    }

    @discardableResult
    static func setForwardLoa(idx: Int, value: Bool) async throws -> Data {
        try await request("/forwardloa", method: "POST", query: ["idx": "\(idx)", "value": value ? "true" : "false"])
    }
}
