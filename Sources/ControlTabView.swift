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

    private var partyRoleBinding: Binding<String> {
        Binding(
            get: { vm.current?.partyRole ?? "Leader" },
            set: { newValue in
                let idx = vm.selectedIdx
                vm.runAction { try await APIClient.setSetting(idx: idx, name: "PartyRole", value: newValue) }
            }
        )
    }

    private var otherAccounts: [BotStatus] {
        vm.statuses.filter { $0.idx != vm.selectedIdx }
    }

    private var followLeaderIdxBinding: Binding<Int> {
        Binding(
            get: { vm.followLeaderIdxByIdx[vm.selectedIdx] ?? otherAccounts.first?.idx ?? 0 },
            set: { newValue in
                let idx = vm.selectedIdx
                vm.followLeaderIdxByIdx[idx] = newValue
                vm.runAction { try await APIClient.setSetting(idx: idx, name: "FollowLeaderIdx", value: "\(newValue)") }
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
                        HStack {
                            Button("Vào map") {
                                let idx = vm.idx
                                vm.enteringOtherworldByIdx.insert(idx)
                                vm.runAction { try await APIClient.enterOtherworld(idx: idx) }
                            }
                            .disabled(vm.busy || vm.current?.loggedIn != true || vm.current?.mapId == BotViewModel.otherworldMapId)
                            Spacer()
                            Button("Ra map", role: .destructive) {
                                let idx = vm.idx
                                vm.leavingOtherworldByIdx.insert(idx)
                                vm.runAction { try await APIClient.leaveOtherworld(idx: idx) }
                            }
                            .disabled(vm.busy || vm.current?.loggedIn != true || vm.current?.mapId != BotViewModel.otherworldMapId)
                        }
                    } header: {
                        Text("Dị Giới")
                    } footer: {
                        // Map Dị Giới cố định = 49942 (xem GameBot.EnterOtherworld) — so mapId hiện
                        // tại để biết ngay đã vào/ra chưa mà không cần qua tab Trạng thái/Log. Cờ
                        // leaving/enteringOtherworldByIdx cho biết đang trong lúc di chuyển (đã bấm
                        // nút, chưa thấy map đổi) để phân biệt với 2 trạng thái tĩnh Đang/Chưa ở.
                        if let s = vm.current, s.loggedIn {
                            if vm.leavingOtherworldByIdx.contains(s.idx) {
                                Text("⏳ Đang ra Dị Giới...")
                            } else if vm.enteringOtherworldByIdx.contains(s.idx) {
                                Text("⏳ Đang vào Dị Giới...")
                            } else {
                                Text(s.mapId == BotViewModel.otherworldMapId ? "✅ Đang ở Dị Giới" : "Chưa ở Dị Giới")
                            }
                        } else {
                            Text("Chưa đăng nhập")
                        }
                    }

                    Section {
                        Picker("Vai trò", selection: partyRoleBinding) {
                            Text("Leader").tag("Leader")
                            Text("Member").tag("Member")
                        }
                        .pickerStyle(.segmented)

                        if vm.current?.partyRole == "Member" {
                            if !otherAccounts.isEmpty {
                                Picker("Theo leader", selection: followLeaderIdxBinding) {
                                    ForEach(otherAccounts) { o in
                                        Text(o.username).tag(o.idx)
                                    }
                                }
                            } else {
                                Text("Chưa có account khác để theo").foregroundStyle(.secondary)
                            }
                        } else {
                            Button("Giải tán nhóm", role: .destructive) {
                                vm.runAction { try await APIClient.disbandParty(idx: vm.idx) }
                            }
                            .disabled(vm.busy || vm.current?.loggedIn != true)
                        }
                    } header: {
                        Text("Tổ đội")
                    } footer: {
                        // partied ở Leader LUÔN false theo thiết kế server/GameBot.IsPartied — chỉ
                        // có ý nghĩa hiển thị cho Member.
                        if vm.current?.partyRole == "Member" {
                            Text(vm.current?.partied == true ? "✅ Đã vào nhóm" : "Chưa vào nhóm — tự thử lại mỗi vài giây khi cùng map với leader")
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
