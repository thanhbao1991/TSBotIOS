import SwiftUI

struct DiscordTabView: View {
    @EnvironmentObject private var vm: BotViewModel

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
                    Section("Discord") {
                        Toggle("Forward chat World (loa)", isOn: forwardLoaBinding)
                    }
                }
            }
            .overlay { if vm.busy { ProgressView().controlSize(.large) } }
        }
        .settingsToolbar()
    }
}
