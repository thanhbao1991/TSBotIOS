import SwiftUI

struct LogView: View {
    let idx: Int
    @Environment(\.dismiss) private var dismiss
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
            .navigationTitle("Log")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") { dismiss() }
                }
            }
            .task { await load() }
            .onReceive(timer) { _ in Task { await load() } }
        }
    }

    private func load() async {
        do {
            text = try await APIClient.fetchLog(idx: idx)
        } catch {
            text = "Lỗi: \(error.localizedDescription)"
        }
    }
}
