import SwiftUI

struct StatusTabView: View {
    @EnvironmentObject private var vm: BotViewModel
    @State private var pets: [PetInfo] = []
    @State private var petsError: String?
    @State private var selectedPetId: Int?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AccountPickerBar()
                List {
                    if let err = vm.errorMessage {
                        Section {
                            Text(err).foregroundStyle(.red).font(.footnote)
                        }
                    }

                    Section("Trạng thái") {
                        if let s = vm.current {
                            LabeledContent("Tài khoản", value: s.username)
                            LabeledContent("Online", value: s.loggedIn ? "✅ \(s.charName)" : "❌ offline")
                            if s.loggedIn {
                                LabeledContent("Map", value: "\(s.mapId) (\(s.x), \(s.y))")
                                LabeledContent("Level", value: "\(s.level)")
                                LabeledContent("HP", value: "\(s.hp)/\(s.hpMax)")
                                LabeledContent("SP", value: "\(s.sp)/\(s.spMax)")
                            }
                        } else {
                            Text("Chưa có dữ liệu — kéo để làm mới").foregroundStyle(.secondary)
                        }
                    }

                    Section {
                        if let err = petsError {
                            Text(err).foregroundStyle(.red).font(.footnote)
                        } else if pets.isEmpty {
                            Text("Chưa có pet nào (cần đăng nhập trước)").foregroundStyle(.secondary)
                        } else {
                            Picker("Pet xuất chiến", selection: $selectedPetId) {
                                Text("—").tag(nil as Int?)
                                ForEach(pets) { p in
                                    Text(p.Name).tag(p.Id as Int?)
                                }
                            }
                            .onChange(of: selectedPetId) { newValue in
                                guard let petId = newValue else { return }
                                vm.runAction { try await APIClient.summonPet(idx: vm.selectedIdx, petId: petId) }
                            }
                        }
                    } header: {
                        Text("Pet")
                    }
                }
                .refreshable { await vm.refresh() }
            }
            .overlay { if vm.busy { ProgressView().controlSize(.large) } }
            .task(id: vm.selectedIdx) { await loadPets() }
        }
    }

    private func loadPets() async {
        selectedPetId = nil
        petsError = nil
        do {
            pets = try await APIClient.fetchPets(idx: vm.selectedIdx)
        } catch {
            pets = []
            petsError = error.localizedDescription
        }
    }
}
