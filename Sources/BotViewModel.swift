import Foundation

/// State dùng chung cho các tab (Trạng thái/AI Tìm/Discord/Log) — 1 instance duy nhất tạo ở
/// ContentView, truyền xuống qua @EnvironmentObject để mọi tab thấy cùng dữ liệu, tránh mỗi tab
/// tự poll /status riêng. `selectedIdx` chọn account đang điều khiển (2+ account) — lưu lại qua
/// Prefs.idx để mở app lần sau vẫn nhớ account vừa chọn.
@MainActor
final class BotViewModel: ObservableObject {
    /// Map Dị Giới cố định (xem GameBot.EnterOtherworld phía backend) — dùng để suy ra đã
    /// vào/ra chưa từ mapId trong /status, không cần thêm field riêng ở server.
    static let otherworldMapId = 49942

    @Published var statuses: [BotStatus] = []
    @Published var errorMessage: String?
    @Published var busy = false
    /// State UI của AI Tìm/Discord theo TỪNG account (key = idx) — vì mỗi account bật/tắt độc
    /// lập, không dùng chung 1 biến kẻo chuyển tab account lại hiện nhầm trạng thái account khác.
    @Published var aiTimOnByIdx: [Int: Bool] = [:]
    @Published var moveModeByIdx: [Int: Int] = [:]
    @Published var forwardLoaByIdx: [Int: Bool] = [:]
    /// Đang chờ vào/ra Dị Giới (bấm nút xong, chưa thấy mapId đổi) — hiện "Đang ra/vào Dị Giới..."
    /// ở tab Điều khiển cho dễ theo dõi thay vì chỉ 2 trạng thái tĩnh Có/Chưa. Tự xoá khi refresh()
    /// thấy mapId đã đổi đúng hướng.
    @Published var leavingOtherworldByIdx: Set<Int> = []
    @Published var enteringOtherworldByIdx: Set<Int> = []
    /// Leader đã chọn để "theo" khi account này là Member — chỉ là lựa chọn UI trước khi gửi
    /// FollowLeaderIdx, server không trả lại giá trị này qua /status nên phải tự nhớ.
    @Published var followLeaderIdxByIdx: [Int: Int] = [:]
    @Published var selectedIdx: Int = Prefs.idx {
        didSet { Prefs.idx = selectedIdx }
    }

    var idx: Int { selectedIdx }
    var current: BotStatus? { statuses.first(where: { $0.idx == selectedIdx }) }

    func refresh() async {
        do {
            statuses = try await APIClient.fetchStatus()
            errorMessage = nil
            for s in statuses {
                if s.mapId != Self.otherworldMapId { leavingOtherworldByIdx.remove(s.idx) }
                if s.mapId == Self.otherworldMapId { enteringOtherworldByIdx.remove(s.idx) }
            }
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
