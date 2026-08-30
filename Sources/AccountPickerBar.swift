import SwiftUI

/// Thanh chọn account — hiện segmented picker khi có từ 2 account trở lên (ẩn khi chỉ 1, đỡ rối).
/// Đặt trên đầu cả 4 tab, đọc/ghi vm.selectedIdx nên chọn 1 lần dùng chung mọi tab.
struct AccountPickerBar: View {
    @EnvironmentObject private var vm: BotViewModel

    var body: some View {
        if vm.statuses.count > 1 {
            Picker("Tài khoản", selection: $vm.selectedIdx) {
                ForEach(vm.statuses) { s in
                    Text("\(s.username)\(s.loggedIn ? " ✅" : "")").tag(s.idx)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
}
