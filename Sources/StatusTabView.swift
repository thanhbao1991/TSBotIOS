import SwiftUI

struct StatusTabView: View {
    @EnvironmentObject private var vm: BotViewModel
    @State private var pets: [PetInfo] = []
    @State private var petsError: String?
    @State private var prefillError: String?

    private var selectedPetIdBinding: Binding<Int?> {
        Binding(
            get: { vm.selectedPetIdByIdx[vm.selectedIdx] ?? nil },
            set: { newValue in
                vm.selectedPetIdByIdx[vm.selectedIdx] = newValue
                guard let petId = newValue else { return }
                let idx = vm.selectedIdx
                vm.runAction { try await APIClient.summonPet(idx: idx, petId: petId) }
            }
        )
    }

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
                            Picker("Pet xuất chiến", selection: selectedPetIdBinding) {
                                Text("—").tag(nil as Int?)
                                ForEach(pets) { p in
                                    Text(p.Name).tag(p.Id as Int?)
                                }
                            }
                            if let err = prefillError {
                                Text(err).foregroundStyle(.red).font(.footnote)
                            }
                        }
                    } header: {
                        Text("Pet")
                    }
                }
                .refreshable { await vm.refresh() }
            }
            .overlay { if vm.busy { ProgressView().controlSize(.large) } }
            // id gồm cả loggedIn — /pets và /charconfig đòi hỏi đã login (409 nếu chưa), mà
            // refresh() poll nền không đổi selectedIdx nên riêng .task(id: selectedIdx) không tự
            // refire khi login xong SAU khi tab đã mở sẵn; ghép thêm loggedIn để tự tải lại đúng
            // lúc chuyển false→true thay vì kẹt lỗi cũ vĩnh viễn.
            .task(id: "\(vm.selectedIdx)-\(vm.current?.loggedIn ?? false)") { await loadPets() }
        }
    }

    private func loadPets() async {
        petsError = nil
        prefillError = nil
        do {
            pets = try await APIClient.fetchPets(idx: vm.selectedIdx)
        } catch {
            pets = []
            petsError = error.localizedDescription
            return
        }
        // Prefill pet đang chọn từ giá trị server thật sự lưu (LastActivePetId) — chỉ khi app
        // CHƯA có lựa chọn nào cho account này, tránh ghi đè lựa chọn user vừa bấm.
        if vm.selectedPetIdByIdx[vm.selectedIdx] == nil {
            do {
                let cfg = try await APIClient.fetchCharConfig(idx: vm.selectedIdx)
                if cfg.lastActivePetId > 0 { vm.selectedPetIdByIdx[vm.selectedIdx] = cfg.lastActivePetId }
            } catch {
                prefillError = "Không tải được pet đã chọn trước đó: \(error.localizedDescription)"
            }
        }
    }
}
