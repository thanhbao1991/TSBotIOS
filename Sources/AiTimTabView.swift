import SwiftUI

struct AiTimTabView: View {
    @EnvironmentObject private var vm: BotViewModel

    var body: some View {
        NavigationStack {
            List {
                Section("AI Tìm (tự đi lại)") {
                    Toggle("Bật AI Tìm", isOn: $vm.aiTimOn)
                        .onChange(of: vm.aiTimOn) { newValue in
                            vm.runAction { try await APIClient.setSetting(idx: vm.idx, name: "AiTimActive", value: newValue ? "true" : "false") }
                        }
                    Picker("Chế độ", selection: $vm.moveMode) {
                        Text("Ngẫu nhiên").tag(0)
                        Text("Truy kích").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: vm.moveMode) { newValue in
                        vm.runAction { try await APIClient.setSetting(idx: vm.idx, name: "MoveMode", value: "\(newValue)") }
                    }
                }
            }
            .overlay { if vm.busy { ProgressView().controlSize(.large) } }
        }
        .settingsToolbar()
    }
}
