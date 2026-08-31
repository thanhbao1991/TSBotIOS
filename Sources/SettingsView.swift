import SwiftUI

private struct SkillPicker: View {
    let title: String
    let skills: [SkillRow]
    @Binding var selection: Int?
    let onPick: (Int) -> Void

    var body: some View {
        Picker(title, selection: $selection) {
            Text("—").tag(nil as Int?)
            ForEach(skills) { sk in
                Text("\(sk.Name) (Lv \(sk.Lv)/\(sk.Max))").tag(sk.Id as Int?)
            }
        }
        .onChange(of: selection) { newValue in
            if let v = newValue { onPick(v) }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var vm: BotViewModel
    @State private var baseURL = Prefs.baseURL
    @State private var apiKey = Prefs.apiKey

    @State private var charSkills: [SkillRow] = []
    @State private var petSkills: [SkillRow] = []
    @State private var charSkillsError: String?
    @State private var petSkillsError: String?

    @State private var attackSkillId: Int?
    @State private var aoeSkillId: Int?
    @State private var elementSkillId: [Int: Int?] = [1: nil, 2: nil, 3: nil, 4: nil]
    @State private var petSkillId: Int?
    @State private var petAoeSkillId: Int?

    @State private var fleeLevelDiffText = ""
    @State private var aoeThresholdCountText = ""

    private static let elementNames: [Int: String] = [1: "Địa", 2: "Thủy", 3: "Hỏa", 4: "Phong"]

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
                } header: {
                    Text("Account đang chỉnh")
                }

                Section {
                    if let err = charSkillsError {
                        Text(err).foregroundStyle(.red).font(.footnote)
                    } else if charSkills.isEmpty {
                        Text("Chưa có dữ liệu — cần đăng nhập account này trước").foregroundStyle(.secondary)
                    } else {
                        SkillPicker(title: "Skill đánh", skills: charSkills, selection: $attackSkillId) { skillId in
                            vm.runAction { try await APIClient.setSetting(idx: vm.selectedIdx, name: "SelectedCharSkillId", value: "\(skillId)") }
                        }
                        SkillPicker(title: "Skill AOE", skills: charSkills, selection: $aoeSkillId) { skillId in
                            vm.runAction { try await APIClient.setSetting(idx: vm.selectedIdx, name: "AoeSkillId", value: "\(skillId)") }
                        }
                        TextField("Ngưỡng AOE: số quái tối thiểu", text: $aoeThresholdCountText)
                            .keyboardType(.numberPad)
                            .onChange(of: aoeThresholdCountText) { newValue in
                                guard let v = Int(newValue) else { return }
                                vm.runAction { try await APIClient.setSetting(idx: vm.selectedIdx, name: "AoeThresholdCount", value: "\(v)") }
                            }
                        ForEach([1, 2, 3, 4], id: \.self) { element in
                            SkillPicker(
                                title: "Skill đánh quái hệ \(Self.elementNames[element] ?? "")",
                                skills: charSkills,
                                selection: Binding(
                                    get: { elementSkillId[element] ?? nil },
                                    set: { elementSkillId[element] = $0 }
                                )
                            ) { skillId in
                                vm.runAction { try await APIClient.setElementSkill(idx: vm.selectedIdx, element: element, skillId: skillId) }
                            }
                        }
                    }
                } header: {
                    Text("Skill nhân vật")
                } footer: {
                    // Đúng thứ tự ưu tiên thật trong AutomationEngine.TryAutoAttack: bắt đầu từ
                    // Skill đánh → nếu đủ ngưỡng AOE thì ĐÈ thành Skill AOE → cuối cùng nếu quái
                    // đúng hệ có cấu hình Skill hệ thì ĐÈ LÊN CẢ 2 (luôn thắng, bất kể AOE hay
                    // không) — mỗi lượt đánh chỉ dùng ĐÚNG 1 skill duy nhất theo thứ tự này.
                    Text("""
                    Mỗi lượt đánh chỉ dùng 1 skill, chọn theo thứ tự ưu tiên sau (dưới đè lên trên):
                    1. Skill đánh — mặc định, dùng khi đánh 1 quái thường.
                    2. Skill AOE — tự thay Skill đánh khi số quái quanh > Ngưỡng AOE (dòng bên dưới).
                    3. Skill hệ — nếu quái đang đánh ĐÚNG hệ có cấu hình, LUÔN thắng cả Skill đánh lẫn Skill AOE (kể cả khi đang đủ ngưỡng AOE).
                    Bỏ trống (—) = không set skill đó, bot bỏ qua bước tương ứng.
                    """)
                }

                Section {
                    TextField("Số level quái chênh lệch để né", text: $fleeLevelDiffText)
                        .keyboardType(.numberPad)
                        .onChange(of: fleeLevelDiffText) { newValue in
                            guard let v = Int(newValue) else { return }
                            vm.runAction { try await APIClient.setSetting(idx: vm.selectedIdx, name: "FleeLevelDiff", value: "\(v)") }
                        }
                } header: {
                    Text("Né trận")
                } footer: {
                    Text("Kiểm tra TRƯỚC TIÊN, trước cả việc chọn skill nào ở mục Skill nhân vật: nếu quái đang đánh mạnh hơn nhân vật quá X level thì bot Chạy Trốn ngay, không đánh nữa (bỏ qua Skill đánh/AOE/hệ).")
                }

                Section {
                    if let err = petSkillsError {
                        Text(err).foregroundStyle(.red).font(.footnote)
                    } else if petSkills.isEmpty {
                        Text("Chưa có pet xuất chiến / chưa có dữ liệu skill pet").foregroundStyle(.secondary)
                    } else {
                        SkillPicker(title: "Skill đánh (pet)", skills: petSkills, selection: $petSkillId) { skillId in
                            vm.runAction { try await APIClient.setSetting(idx: vm.selectedIdx, name: "SelectedPetSkillId", value: "\(skillId)") }
                        }
                        SkillPicker(title: "Skill AOE (pet)", skills: petSkills, selection: $petAoeSkillId) { skillId in
                            vm.runAction { try await APIClient.setSetting(idx: vm.selectedIdx, name: "PetAoeSkillId", value: "\(skillId)") }
                        }
                    }
                } header: {
                    Text("Skill pet")
                } footer: {
                    Text("Cùng logic ưu tiên như Skill nhân vật ở trên (đánh → AOE → hệ, hệ luôn thắng), tính riêng cho pet — pet có thể đang đánh skill hệ trong khi nhân vật đánh skill AOE cùng lúc. Áp dụng cho pet ĐANG xuất chiến — triệu hồi pet khác thì phải chọn lại vì pet mới có bộ skill riêng.")
                }
            }
            .task(id: vm.selectedIdx) { await loadAll() }
        }
    }

    private func loadAll() async {
        attackSkillId = nil
        aoeSkillId = nil
        elementSkillId = [1: nil, 2: nil, 3: nil, 4: nil]
        petSkillId = nil
        petAoeSkillId = nil
        charSkillsError = nil
        petSkillsError = nil
        do {
            charSkills = try await APIClient.fetchSkills(idx: vm.selectedIdx, target: "char")
        } catch {
            charSkills = []
            charSkillsError = error.localizedDescription
        }
        do {
            petSkills = try await APIClient.fetchSkills(idx: vm.selectedIdx, target: "pet")
        } catch {
            petSkills = []
            petSkillsError = error.localizedDescription
        }
    }
}
