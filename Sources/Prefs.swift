import Foundation

/// Lưu cấu hình kết nối control API (base URL + API key) qua UserDefaults — nhập 1 lần trong
/// SettingsView, không hardcode trong code vì API key là secret (repo Public).
enum Prefs {
    private static let defaults = UserDefaults.standard

    static var baseURL: String {
        get { defaults.string(forKey: "baseURL") ?? "https://tsbot.denncoffee.uk" }
        set { defaults.set(newValue, forKey: "baseURL") }
    }

    static var apiKey: String {
        get { defaults.string(forKey: "apiKey") ?? "" }
        set { defaults.set(newValue, forKey: "apiKey") }
    }

    static var idx: Int {
        get { defaults.integer(forKey: "idx") }
        set { defaults.set(newValue, forKey: "idx") }
    }
}
