import SwiftUI

struct StatusTabView: View {
    @EnvironmentObject private var vm: BotViewModel

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
                }
                .refreshable { await vm.refresh() }
            }
            .overlay { if vm.busy { ProgressView().controlSize(.large) } }
        }
    }
}
