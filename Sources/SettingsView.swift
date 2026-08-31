import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var vm: BotViewModel
    @State private var baseURL = Prefs.baseURL
    @State private var apiKey = Prefs.apiKey
    @State private var skills: [SkillRow] = []
    @State private var selectedSkillId: Int?
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
                    AccountPickerBar()
                        .listRowInsets(EdgeInsets())

                    if let err = skillError {
                        Text(err).foregroundStyle(.red).font(.footnote)
                    } else if skills.isEmpty {
                        Text("Chưa có dữ liệu skill — cần đăng nhập account này trước").foregroundStyle(.secondary)
                    } else {
                        Picker("Skill đánh", selection: $selectedSkillId) {
                            ForEach(skills) { sk in
                                Text("\(sk.Name) (Lv \(sk.Lv)/\(sk.Max))").tag(sk.Id as Int?)
                            }
                        }
                        .onChange(of: selectedSkillId) { newValue in
                            guard let skillId = newValue else { return }
                            let idx = vm.selectedIdx
                            vm.runAction { try await APIClient.setSetting(idx: idx, name: "SelectedCharSkillId", value: "\(skillId)") }
                        }
                    }
                } header: {
                    Text("Skill đánh")
                } footer: {
                    Text("Danh sách skill lấy trực tiếp từ nhân vật account đang chọn — chọn xong áp dụng ngay.")
                }
            }
            .task(id: vm.selectedIdx) { await loadSkills() }
        }
    }

    private func loadSkills() async {
        skillError = nil
        do {
            skills = try await APIClient.fetchSkills(idx: vm.selectedIdx)
            selectedSkillId = nil
        } catch {
            skills = []
            skillError = error.localizedDescription
        }
    }
}
