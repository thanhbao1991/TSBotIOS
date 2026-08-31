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

/// Dòng "Quái N" — Picker số quái (2-10) + Picker skill CHUNG 1 HÀNG, không tách dòng.
private struct AoeRow: View {
    let skills: [SkillRow]
    @Binding var skillSelection: Int?
    @Binding var countSelection: Int
    let onPickSkill: (Int) -> Void
    let onPickCount: (Int) -> Void

    var body: some View {
        HStack {
            Picker("Quái N", selection: $countSelection) {
                ForEach(2...10, id: \.self) { n in
                    Text("\(n)").tag(n)
                }
            }
            .onChange(of: countSelection) { newValue in
                onPickCount(newValue)
            }
            Spacer()
            Picker("Skill", selection: $skillSelection) {
                Text("—").tag(nil as Int?)
                ForEach(skills) { sk in
                    Text(sk.Name).tag(sk.Id as Int?)
                }
            }
            .onChange(of: skillSelection) { newValue in
                if let v = newValue { onPickSkill(v) }
            }
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

    /// Hệ Thủy cố định = 2 (xem GameBot: 1 Địa 2 Thủy 3 Hỏa 4 Phong) — user chỉ cần đúng hệ này.
    private static let thuyElement = 2

    @State private var attackSkillId: Int?
    @State private var aoeSkillId: Int?
    @State private var aoeCount = 5
    @State private var thuySkillId: Int?
    @State private var fleeLevelDiffText = ""

    @State private var petSkillId: Int?
    @State private var petAoeSkillId: Int?
    @State private var petAoeCount = 5
    @State private var petFleeLevelDiffText = ""

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
                        SkillPicker(title: "Quái 1", skills: charSkills, selection: $attackSkillId) { skillId in
                            vm.runAction { try await APIClient.setSetting(idx: vm.selectedIdx, name: "SelectedCharSkillId", value: "\(skillId)") }
                        }
                        AoeRow(
                            skills: charSkills,
                            skillSelection: $aoeSkillId,
                            countSelection: $aoeCount,
                            onPickSkill: { skillId in
                                vm.runAction { try await APIClient.setSetting(idx: vm.selectedIdx, name: "AoeSkillId", value: "\(skillId)") }
                            },
                            onPickCount: { count in
                                vm.runAction { try await APIClient.setSetting(idx: vm.selectedIdx, name: "AoeThresholdCount", value: "\(count)") }
                            }
                        )
                        SkillPicker(title: "Quái Thủy", skills: charSkills, selection: $thuySkillId) { skillId in
                            vm.runAction { try await APIClient.setElementSkill(idx: vm.selectedIdx, element: Self.thuyElement, skillId: skillId) }
                        }
                        TextField("Địch hơn X level thì chạy", text: $fleeLevelDiffText)
                            .keyboardType(.numberPad)
                            .onChange(of: fleeLevelDiffText) { newValue in
                                guard let v = Int(newValue) else { return }
                                vm.runAction { try await APIClient.setSetting(idx: vm.selectedIdx, name: "FleeLevelDiff", value: "\(v)") }
                            }
                    }
                } header: {
                    Text("Char")
                }

                Section {
                    if let err = petSkillsError {
                        Text(err).foregroundStyle(.red).font(.footnote)
                    } else if petSkills.isEmpty {
                        Text("Chưa có pet xuất chiến / chưa có dữ liệu skill pet").foregroundStyle(.secondary)
                    } else {
                        SkillPicker(title: "Quái 1", skills: petSkills, selection: $petSkillId) { skillId in
                            vm.runAction { try await APIClient.setSetting(idx: vm.selectedIdx, name: "SelectedPetSkillId", value: "\(skillId)") }
                        }
                        AoeRow(
                            skills: petSkills,
                            skillSelection: $petAoeSkillId,
                            countSelection: $petAoeCount,
                            onPickSkill: { skillId in
                                vm.runAction { try await APIClient.setSetting(idx: vm.selectedIdx, name: "PetAoeSkillId", value: "\(skillId)") }
                            },
                            onPickCount: { count in
                                vm.runAction { try await APIClient.setSetting(idx: vm.selectedIdx, name: "PetAoeThresholdCount", value: "\(count)") }
                            }
                        )
                        TextField("Địch hơn X level thì chạy", text: $petFleeLevelDiffText)
                            .keyboardType(.numberPad)
                            .onChange(of: petFleeLevelDiffText) { newValue in
                                guard let v = Int(newValue) else { return }
                                vm.runAction { try await APIClient.setSetting(idx: vm.selectedIdx, name: "PetFleeLevelDiff", value: "\(v)") }
                            }
                    }
                } header: {
                    Text("Pet xuất chiến")
                }
            }
            .task(id: vm.selectedIdx) { await loadAll() }
        }
    }

    private func loadAll() async {
        attackSkillId = nil
        aoeSkillId = nil
        thuySkillId = nil
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
