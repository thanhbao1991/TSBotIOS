import SwiftUI

struct LogView: View {
    @EnvironmentObject private var vm: BotViewModel
    @State private var text = "Đang tải..."

    private let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    private let bottomAnchorId = "bottom"

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AccountPickerBar()
                ScrollViewReader { proxy in
                    ScrollView {
                        Text(text)
                            .font(.system(size: 12, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                        Color.clear.frame(height: 1).id(bottomAnchorId)
                    }
                    .onChange(of: text) { _ in
                        proxy.scrollTo(bottomAnchorId, anchor: .bottom)
                    }
                    .task {
                        await load()
                        proxy.scrollTo(bottomAnchorId, anchor: .bottom)
                    }
                }
            }
            .onReceive(timer) { _ in Task { await load() } }
            .onChange(of: vm.selectedIdx) { _ in Task { await load() } }
        }
    }

    private func load() async {
        do {
            text = try await APIClient.fetchLog(idx: vm.idx)
        } catch {
            text = "Lỗi: \(error.localizedDescription)"
        }
    }
}
