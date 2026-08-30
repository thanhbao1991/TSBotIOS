import SwiftUI

struct AiTimTabView: View {
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

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AccountPickerBar()
                List {
                    Section("AI Tìm (tự đi lại)") {
                        Toggle("Bật AI Tìm", isOn: aiTimOnBinding)
                        Picker("Chế độ", selection: moveModeBinding) {
                            Text("Ngẫu nhiên").tag(0)
                            Text("Truy kích").tag(1)
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }
            .overlay { if vm.busy { ProgressView().controlSize(.large) } }
        }
        .settingsToolbar()
    }
}
