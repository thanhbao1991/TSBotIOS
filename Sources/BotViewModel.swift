import Foundation

/// State dùng chung cho các tab (Trạng thái/AI Tìm/Discord/Log) — 1 instance duy nhất tạo ở
/// ContentView, truyền xuống qua @EnvironmentObject để mọi tab thấy cùng dữ liệu, tránh mỗi tab
/// tự poll /status riêng.
@MainActor
final class BotViewModel: ObservableObject {
    @Published var statuses: [BotStatus] = []
    @Published var errorMessage: String?
    @Published var busy = false
    @Published var aiTimOn = false
    @Published var moveMode = 0
    @Published var forwardLoa = false

    var idx: Int { Prefs.idx }
    var current: BotStatus? { statuses.first(where: { $0.idx == idx }) }

    func refresh() async {
        do {
            statuses = try await APIClient.fetchStatus()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func runAction(_ action: @escaping () async throws -> Void) {
        busy = true
        Task {
            do {
                try await action()
                try? await Task.sleep(nanoseconds: 500_000_000)
                await refresh()
            } catch {
                errorMessage = error.localizedDescription
            }
            busy = false
        }
    }
}
