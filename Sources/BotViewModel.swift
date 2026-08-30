import Foundation

/// State dùng chung cho các tab (Trạng thái/AI Tìm/Discord/Log) — 1 instance duy nhất tạo ở
/// ContentView, truyền xuống qua @EnvironmentObject để mọi tab thấy cùng dữ liệu, tránh mỗi tab
/// tự poll /status riêng. `selectedIdx` chọn account đang điều khiển (2+ account) — lưu lại qua
/// Prefs.idx để mở app lần sau vẫn nhớ account vừa chọn.
@MainActor
final class BotViewModel: ObservableObject {
    @Published var statuses: [BotStatus] = []
    @Published var errorMessage: String?
    @Published var busy = false
    /// State UI của AI Tìm/Discord theo TỪNG account (key = idx) — vì mỗi account bật/tắt độc
    /// lập, không dùng chung 1 biến kẻo chuyển tab account lại hiện nhầm trạng thái account khác.
    @Published var aiTimOnByIdx: [Int: Bool] = [:]
    @Published var moveModeByIdx: [Int: Int] = [:]
    @Published var forwardLoaByIdx: [Int: Bool] = [:]
    @Published var selectedIdx: Int = Prefs.idx {
        didSet { Prefs.idx = selectedIdx }
    }

    var idx: Int { selectedIdx }
    var current: BotStatus? { statuses.first(where: { $0.idx == selectedIdx }) }

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
