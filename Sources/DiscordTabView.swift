import SwiftUI

struct DiscordTabView: View {
    @EnvironmentObject private var vm: BotViewModel

    var body: some View {
        NavigationStack {
            List {
                Section("Discord") {
                    Toggle("Forward chat World (loa)", isOn: $vm.forwardLoa)
                        .onChange(of: vm.forwardLoa) { newValue in
                            vm.runAction { try await APIClient.setForwardLoa(idx: vm.idx, value: newValue) }
                        }
                }
            }
            .navigationTitle("Discord")
            .overlay { if vm.busy { ProgressView().controlSize(.large) } }
        }
        .settingsToolbar()
    }
}
