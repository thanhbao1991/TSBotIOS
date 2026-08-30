import SwiftUI

struct StatusTabView: View {
    @EnvironmentObject private var vm: BotViewModel

    var body: some View {
        NavigationStack {
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

                Section("Điều khiển") {
                    HStack {
                        Button("Đăng nhập") { vm.runAction { try await APIClient.login(idx: vm.idx) } }
                            .disabled(vm.busy || vm.current?.loggedIn == true)
                        Spacer()
                        Button("Đăng xuất", role: .destructive) { vm.runAction { try await APIClient.logout(idx: vm.idx) } }
                            .disabled(vm.busy || vm.current?.loggedIn != true)
                    }
                }
            }
            .navigationTitle("Trạng thái")
            .refreshable { await vm.refresh() }
            .overlay { if vm.busy { ProgressView().controlSize(.large) } }
        }
        .settingsToolbar()
    }
}
