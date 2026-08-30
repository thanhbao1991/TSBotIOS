import SwiftUI

struct SettingsView: View {
    @State private var baseURL = Prefs.baseURL
    @State private var apiKey = Prefs.apiKey

    var body: some View {
        NavigationStack {
            Form {
                Section("Kết nối") {
                    TextField("Base URL", text: $baseURL)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                        .onChange(of: baseURL) { newValue in
                            Prefs.baseURL = newValue.trimmingCharacters(in: .whitespaces)
                        }
                    SecureField("API Key", text: $apiKey)
                        .onChange(of: apiKey) { newValue in
                            Prefs.apiKey = newValue.trimmingCharacters(in: .whitespaces)
                        }
                }
            }
        }
    }
}
