import SwiftUI

struct ControlTabView: View {
    @EnvironmentObject private var vm: BotViewModel

    private var aiTimOnBinding: Binding<Bool> {
        Binding(
            get: { vm.aiTimOnByIdx[vm.selectedIdx] ?? false },
            set: { newValue in
                let idx = vm.selectedIdx
                vm.aiTimOnByIdx[idx] = newValue
                vm.runAction { try await APIClient.setSetting(idx: idx, name: "AiTimActive", value: newValue ? "true" : "false") }
            }
        )
    }

    private var moveModeBinding: Binding<Int> {
        Binding(
            get: { vm.moveModeByIdx[vm.selectedIdx] ?? 0 },
            set: { newValue in
                let idx = vm.selectedIdx
                vm.moveModeByIdx[idx] = newValue
                vm.runAction { try await APIClient.setSetting(idx: idx, name: "MoveMode", value: "\(newValue)") }
            }
        )
    }

    private var forwardLoaBinding: Binding<Bool> {
        Binding(
            get: { vm.forwardLoaByIdx[vm.selectedIdx] ?? false },
            set: { newValue in
                let idx = vm.selectedIdx
                vm.forwardLoaByIdx[idx] = newValue
                vm.runAction { try await APIClient.setForwardLoa(idx: idx, value: newValue) }
            }
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AccountPickerBar()
                List {
                    Section("Đăng nhập") {
                        HStack {
                            Button("Đăng nhập") { vm.runAction { try await APIClient.login(idx: vm.idx) } }
                                .disabled(vm.busy || vm.current?.loggedIn == true)
                            Spacer()
                            Button("Đăng xuất", role: .destructive) { vm.runAction { try await APIClient.logout(idx: vm.idx) } }
                                .disabled(vm.busy || vm.current?.loggedIn != true)
                        }
                    }

                    Section {
                        Button("Vào Dị Giới") { vm.runAction { try await APIClient.enterOtherworld(idx: vm.idx) } }
                            .disabled(vm.busy || vm.current?.loggedIn != true)
                    } header: {
                        Text("Dị Giới")
                    } footer: {
                        // Map Dị Giới cố định = 49942 (xem GameBot.EnterOtherworld) — so mapId hiện
                        // tại để biết ngay đã vào chưa mà không cần qua tab Trạng thái/Log.
                        if let s = vm.current, s.loggedIn {
                            Text(s.mapId == 49942 ? "✅ Đang ở Dị Giới" : "Chưa ở Dị Giới (map hiện tại: \(s.mapId))")
                        } else {
                            Text("Chưa đăng nhập")
                        }
                    }

                    Section("AI Tìm (tự đi lại)") {
                        Toggle("Bật AI Tìm", isOn: aiTimOnBinding)
                        Picker("Chế độ", selection: moveModeBinding) {
                            Text("Ngẫu nhiên").tag(0)
                            Text("Truy kích").tag(1)
                        }
                        .pickerStyle(.segmented)
                    }

                    Section("Discord") {
                        Toggle("Forward chat World (loa)", isOn: forwardLoaBinding)
                    }
                }
            }
            .overlay { if vm.busy { ProgressView().controlSize(.large) } }
        }
    }
}
