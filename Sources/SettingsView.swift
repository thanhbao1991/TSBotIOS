import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var vm: BotViewModel
    @State private var baseURL = Prefs.baseURL
    @State private var apiKey = Prefs.apiKey
    @State private var attackSkillId = ""
    @State private var skillError: String?

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

                Section {
                    HStack {
                        TextField("Skill ID (vd: 10000)", text: $attackSkillId)
                            .keyboardType(.numberPad)
                        Button("Áp dụng") {
                            guard let skillId = Int(attackSkillId) else {
                                skillError = "Skill ID phải là số"
                                return
                            }
                            skillError = nil
                            let idx = vm.selectedIdx
                            vm.runAction { try await APIClient.setSetting(idx: idx, name: "SelectedCharSkillId", value: "\(skillId)") }
                        }
                        .disabled(attackSkillId.isEmpty)
                    }
                    if let err = skillError {
                        Text(err).foregroundStyle(.red).font(.footnote)
                    }
                } header: {
                    Text("Skill đánh (account đang chọn)")
                } footer: {
                    Text("Skill dùng để tự động tấn công mục tiêu đơn — nhập đúng skillId trong game.")
                }
            }
        }
    }
}
