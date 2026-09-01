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

    @State private var charSkills: [SkillRow] = []
    @State private var petSkills: [SkillRow] = []
    @State private var charSkillsError: String?
    @State private var petSkillsError: String?

    /// Hệ Thủy cố định = 2 (xem GameBot: 1 Địa 2 Thủy 3 Hỏa 4 Phong) — user chỉ cần đúng hệ này.
    private static let thuyElement = 2

    private var charConfig: Binding<CharSkillConfig> {
        Binding(
            get: { vm.charSkillConfigByIdx[vm.selectedIdx] ?? CharSkillConfig() },
            set: { vm.charSkillConfigByIdx[vm.selectedIdx] = $0 }
        )
    }

    private var petConfig: Binding<PetSkillConfig> {
        Binding(
            get: { vm.petSkillConfigByIdx[vm.selectedIdx] ?? PetSkillConfig() },
            set: { vm.petSkillConfigByIdx[vm.selectedIdx] = $0 }
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AccountPickerBar()
                List {
                Section {
                    if let err = charSkillsError {
                        Text(err).foregroundStyle(.red).font(.footnote)
                    } else if charSkills.isEmpty {
                        Text("Chưa có dữ liệu — cần đăng nhập account này trước").foregroundStyle(.secondary)
                    } else {
                        SkillPicker(title: "Quái 1", skills: charSkills, selection: charConfig.attackSkillId) { skillId in
                            vm.runAction { try await APIClient.setSetting(idx: vm.selectedIdx, name: "SelectedCharSkillId", value: "\(skillId)") }
                        }
                        AoeRow(
                            skills: charSkills,
                            skillSelection: charConfig.aoeSkillId,
                            countSelection: charConfig.aoeCount,
                            onPickSkill: { skillId in
                                vm.runAction { try await APIClient.setSetting(idx: vm.selectedIdx, name: "AoeSkillId", value: "\(skillId)") }
                            },
                            onPickCount: { count in
                                vm.runAction { try await APIClient.setSetting(idx: vm.selectedIdx, name: "AoeThresholdCount", value: "\(count)") }
                            }
                        )
                        SkillPicker(title: "Quái Thủy", skills: charSkills, selection: charConfig.thuySkillId) { skillId in
                            vm.runAction { try await APIClient.setElementSkill(idx: vm.selectedIdx, element: Self.thuyElement, skillId: skillId) }
                        }
                        TextField("Địch hơn X level thì chạy", text: charConfig.fleeLevelDiffText)
                            .keyboardType(.numberPad)
                            .onChange(of: charConfig.fleeLevelDiffText.wrappedValue) { newValue in
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
                        SkillPicker(title: "Quái 1", skills: petSkills, selection: petConfig.attackSkillId) { skillId in
                            vm.runAction { try await APIClient.setSetting(idx: vm.selectedIdx, name: "SelectedPetSkillId", value: "\(skillId)") }
                        }
                        AoeRow(
                            skills: petSkills,
                            skillSelection: petConfig.aoeSkillId,
                            countSelection: petConfig.aoeCount,
                            onPickSkill: { skillId in
                                vm.runAction { try await APIClient.setSetting(idx: vm.selectedIdx, name: "PetAoeSkillId", value: "\(skillId)") }
                            },
                            onPickCount: { count in
                                vm.runAction { try await APIClient.setSetting(idx: vm.selectedIdx, name: "PetAoeThresholdCount", value: "\(count)") }
                            }
                        )
                        TextField("Địch hơn X level thì chạy", text: petConfig.fleeLevelDiffText)
                            .keyboardType(.numberPad)
                            .onChange(of: petConfig.fleeLevelDiffText.wrappedValue) { newValue in
                                guard let v = Int(newValue) else { return }
                                vm.runAction { try await APIClient.setSetting(idx: vm.selectedIdx, name: "PetFleeLevelDiff", value: "\(v)") }
                            }
                    }
                } header: {
                    Text("Pet xuất chiến")
                }
                }
            }
            .task(id: vm.selectedIdx) { await loadAll() }
        }
    }

    private func loadAll() async {
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
        // Prefill từ giá trị server ĐANG THẬT SỰ lưu — chỉ prefill nếu app CHƯA có lựa chọn nào
        // cho account này (tránh ghi đè lựa chọn user vừa bấm trong phiên hiện tại bằng dữ liệu
        // cũ hơn nếu load lại xảy ra sau khi user đã đổi tay).
        if vm.charSkillConfigByIdx[vm.selectedIdx] == nil || vm.petSkillConfigByIdx[vm.selectedIdx] == nil {
            if let cfg = try? await APIClient.fetchCharConfig(idx: vm.selectedIdx) {
                if vm.charSkillConfigByIdx[vm.selectedIdx] == nil {
                    vm.charSkillConfigByIdx[vm.selectedIdx] = CharSkillConfig(
                        attackSkillId: cfg.selectedCharSkillId,
                        aoeSkillId: cfg.aoeSkillId,
                        aoeCount: cfg.aoeThresholdCount,
                        thuySkillId: cfg.thuySkillId >= 0 ? cfg.thuySkillId : nil,
                        fleeLevelDiffText: "\(cfg.fleeLevelDiff)"
                    )
                }
                if vm.petSkillConfigByIdx[vm.selectedIdx] == nil {
                    vm.petSkillConfigByIdx[vm.selectedIdx] = PetSkillConfig(
                        attackSkillId: cfg.selectedPetSkillId,
                        aoeSkillId: cfg.petAoeSkillId,
                        aoeCount: cfg.petAoeThresholdCount,
                        fleeLevelDiffText: "\(cfg.petFleeLevelDiff)"
                    )
                }
            }
        }
    }
}
