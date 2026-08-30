import SwiftUI

struct LogView: View {
    @EnvironmentObject private var vm: BotViewModel
    @State private var text = "Đang tải..."

    private let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(text)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .task { await load() }
            .onReceive(timer) { _ in Task { await load() } }
        }
        .settingsToolbar()
    }

    private func load() async {
        do {
            text = try await APIClient.fetchLog(idx: vm.idx)
        } catch {
            text = "Lỗi: \(error.localizedDescription)"
        }
    }
}
