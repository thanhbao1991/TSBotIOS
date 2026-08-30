import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var baseURL = Prefs.baseURL
    @State private var apiKey = Prefs.apiKey
    @State private var idxText = "\(Prefs.idx)"

    var body: some View {
        NavigationStack {
            Form {
                Section("Kết nối") {
                    TextField("Base URL", text: $baseURL)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                    SecureField("API Key", text: $apiKey)
                    TextField("Account index", text: $idxText)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Cài đặt")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Xong") {
                        Prefs.baseURL = baseURL.trimmingCharacters(in: .whitespaces)
                        Prefs.apiKey = apiKey.trimmingCharacters(in: .whitespaces)
                        Prefs.idx = Int(idxText) ?? 0
                        dismiss()
                    }
                }
            }
        }
    }
}
