import Foundation

/// Lựa chọn skill Char theo TỪNG account — lưu trên BotViewModel (không phải @State cục bộ trên
/// SettingsView) vì server không có endpoint trả lại giá trị đang set, nên UI phải tự nhớ; để ở
/// đây thay vì @State tránh mất lựa chọn khi rời tab Cài đặt rồi quay lại (SwiftUI có thể tái tạo
/// view state cục bộ, @Published trên ObservableObject dùng chung thì không bị mất).
struct CharSkillConfig {
    var attackSkillId: Int?
    var aoeSkillId: Int?
    var aoeCount = 5
    var thuySkillId: Int?
    var fleeLevelDiffText = ""
}

struct PetSkillConfig {
    var attackSkillId: Int?
    var aoeSkillId: Int?
    var aoeCount = 5
    var fleeLevelDiffText = ""
}

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
    /// Member đang chọn trong Picker "Phó nhóm" trên tab Leader — chỉ là lựa chọn UI trước khi
    /// gửi promotemember, server không trả lại ai đang là phó qua /status.
    @Published var viceMemberIdxByIdx: [Int: Int] = [:]
    /// Pet đang chọn trong Picker "Pet xuất chiến" theo TỪNG account — lưu ở đây (thay vì @State
    /// cục bộ trên StatusTabView) để không mất lựa chọn khi chuyển qua tab khác rồi quay lại.
    @Published var selectedPetIdByIdx: [Int: Int] = [:]
    @Published var charSkillConfigByIdx: [Int: CharSkillConfig] = [:]
    @Published var petSkillConfigByIdx: [Int: PetSkillConfig] = [:]
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
